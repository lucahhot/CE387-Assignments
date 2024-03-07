`include "globals.sv"

module qarctan
(
    input   logic                   clk,
    input   logic                   reset,
    input   logic                   demod_data_valid,
    output  logic                   divider_ready,
    input   logic [DATA_SIZE-1:0]   x,
    input   logic [DATA_SIZE-1:0]   y,
    output  logic [DATA_SIZE-1:0]   data_out,
    output  logic                   qarctan_done   
);

    
const logic [DATA_SIZE-1:0] QUAD_ONE = 32'h00000324;
const logic [DATA_SIZE-1:0] QUAD_THREE = 32'h0000096c;

typedef enum logic [1:0] {READY, MULTIPLY, ANGLE} state_t;
state_t state, next_state;

// Signals to and from the divider
logic start_div, div_overflow_out, div_valid_out;
logic [DATA_SIZE-1:0] dividend;
logic [DATA_SIZE-1:0] divisor;
logic [DATA_SIZE-1:0] div_quotient_out;
logic [DATA_SIZE-1:0] div_remainder_out;

// internal signals
logic [DATA_SIZE-1:0] angle;
logic [DATA_SIZE-1:0] abs_y, pseudo_abs_y;
logic [DATA_SIZE-1:0] x_minus_abs_y;
logic [DATA_SIZE-1:0] x_plus_abs_y;
logic [DATA_SIZE-1:0] abs_y_minus_x;
logic [DATA_SIZE-1:0] quant_x_minus_abs_y;
logic [DATA_SIZE-1:0] quant_x_plus_abs_y;

// quad_product register
logic [DATA_SIZE-1:0] quad_product, quad_product_c;

div #(
    .DIVIDEND_WIDTH(DATA_SIZE),
    .DIVISOR_WIDTH(DATA_SIZE)
) divider_inst (
    .clk(clk),
    .reset(reset),
    .valid_in(start_div),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(div_quotient_out),
    .remainder(div_remainder_out),
    .overflow(div_overflow_out),
    .valid_out(div_valid_out)
);

always_ff @(posedge clk or posedge reset) begin
    if (reset == 1'b1) begin
        state <= READY;
        quad_product <= '0;
    end else begin
        state <= next_state;
        quad_product <= quad_product_c;
    end
end

always_comb begin
    // Output the current readiness of the divider
    qarctan_done = 1'b0;;
    data_out = '0;
    divider_ready = (state == READY);

    quad_product_c = quad_product;

    // Default start_div assignment
    start_div = 1'b0;

    case(state)

        // the divider is not doing anything
        READY: begin
            // there is valid data from demod
            if (demod_data_valid == 1'b1) begin
                start_div = 1'b1;

                // Combinational logic calculations for dividend and divisor inputs
                pseudo_abs_y = ($signed(y) >= 0) ? y : -$signed(y);
                abs_y = $signed(pseudo_abs_y) + 32'h00000001;
                x_minus_abs_y = $signed(x) - $signed(abs_y);
                x_plus_abs_y = $signed(x) + $signed(abs_y);
                abs_y_minus_x = $signed(abs_y) - $signed(x);
                quant_x_minus_abs_y = QUANTIZE(x_minus_abs_y);
                quant_x_plus_abs_y = QUANTIZE(x_plus_abs_y);

                // Assign dividends and divisors directly into divider
                if ($signed(x) >= 0) begin
                    dividend = ($signed(quant_x_minus_abs_y) >= 0) ? {32'h0, quant_x_minus_abs_y} : {32'hffffffff, quant_x_minus_abs_y};
                    divisor = x_plus_abs_y;
                end else begin
                    dividend = ($signed(quant_x_plus_abs_y) >= 0) ? {32'h0, quant_x_plus_abs_y} : {32'hffffffff, quant_x_plus_abs_y};
                    divisor = abs_y_minus_x;
                end
                next_state = MULTIPLY;
            end
            else 
                next_state = READY;
        end

        // the divider is doing a computation
        MULTIPLY: begin
            // Division complete
            if (div_valid_out == 1'b1) begin

                quad_product_c = $signed(QUAD_ONE) * $signed(div_quotient_out);
                next_state = ANGLE;
                
            // Keep looping till division has been completed
            end else 
                next_state = MULTIPLY;
        end

        // State to compute angle
        ANGLE: begin

            // x and y values have not changed since the start of the calculation
            if (x == '0 && y == '0) 
                angle = 32'h648;
            else if ($signed(x) >= 0) 
                angle = ($signed(QUAD_ONE) - $signed(DEQUANTIZE(quad_product)));
            else 
                angle = ($signed(QUAD_THREE) - $signed(DEQUANTIZE(quad_product)));

            // Assign output
            data_out = ($signed(y) < 0) ? -$signed(angle) : angle;
            qarctan_done = 1'b1;
            next_state = READY;
        end

    endcase
end

endmodule