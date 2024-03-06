`include "globals.sv" 

module iir #(
    parameter NUM_TAPS = 2,
    parameter DECIMATION = 1,
    parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0] IIR_Y_COEFFS = '{default: '{default: 0}},
    parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0] IIR_X_COEFFS = '{default: '{default: 0}}
) (
    input   logic clock,
    input   logic reset,
    input   logic [DATA_SIZE-1:0] x_in_dout,   // Quantized input 
    input   logic x_in_empty,
    output  logic x_in_rd_en,
    output  logic y_out_wr_en,
    input   logic y_out_full,
    output  logic [DATA_SIZE-1:0] y_out_din  // Quantized output
);

typedef enum logic [1:0] {S0, S1, S2, S3} state_types;
state_types state, next_state;

logic [0:NUM_TAPS-1] [DATA_SIZE-1:0] xshift_reg ;
logic [0:NUM_TAPS-1][DATA_SIZE-1:0] xshift_reg_c ;
logic [0:NUM_TAPS-1] [DATA_SIZE-1:0] yshift_reg ;
logic [0:NUM_TAPS-1][DATA_SIZE-1:0] yshift_reg_c ;
logic [$clog2(DECIMATION)-1:0] decimation_counter, decimation_counter_c;
logic [$clog2(NUM_TAPS)-1:0] taps_counter, taps_counter_c;
logic [DATA_SIZE-1:0] y1_sum, y1_sum_c; 
logic [DATA_SIZE-1:0] y2_sum, y2_sum_c;
logic [$clog2(NUM_TAPS)-1:0] yshift_counter, yshift_counter_c;

// Register to hold shift_reg value to be used in MAC since reading from shift_reg takes forever
logic [DATA_SIZE-1:0] xtap_value, xtap_value_c;
logic [DATA_SIZE-1:0] ytap_value, ytap_value_c;

// Wires for more readable code in MAC operation
logic [DATA_SIZE_2-1:0] y1_product;
logic [DATA_SIZE_2-1:0] y2_product;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= S0; 
        xshift_reg <= '{default: '{default: 0}};
        yshift_reg <= '{default: '{default: 0}};
        decimation_counter <= '0;
        taps_counter <= '0;
        y1_sum <= '0;
        y2_sum <= '0;
        xtap_value <= '0;
        ytap_value <= '0;
        yshift_counter <= '0;
    end else begin
        state <= next_state;
        xshift_reg <= xshift_reg_c;
        yshift_reg <= yshift_reg_c;
        decimation_counter <= decimation_counter_c;
        taps_counter <= taps_counter_c;
        y1_sum <= y1_sum_c;
        y2_sum <= y2_sum_c;
        xtap_value <= xtap_value_c;
        ytap_value <= ytap_value_c;
        yshift_counter <= yshift_counter_c;
    end
end

always_comb begin
    next_state = state;
    x_in_rd_en = 1'b0;
    y_out_wr_en = 1'b0;
    decimation_counter_c = decimation_counter;
    xshift_reg_c = xshift_reg;
    yshift_reg_c = yshift_reg;
    taps_counter_c = taps_counter;
    y1_sum_c = y1_sum;
    y2_sum_c = y2_sum;
    xtap_value_c = xtap_value;
    ytap_value_c = ytap_value;
    yshift_counter_c = yshift_counter;

    case(state)

        S0: begin
            if (x_in_empty == 1'b0) begin
                // Shift in data into shift register and downsample according to DECIMATION constant
                x_in_rd_en = 1'b1;
                xshift_reg_c[1:NUM_TAPS-1] = xshift_reg[0:NUM_TAPS-2];
                xshift_reg_c[0] = x_in_dout;
                decimation_counter_c = decimation_counter + 1'b1;

                if (decimation_counter == DECIMATION - 1) begin
                    next_state = S1;
                    // Assign first tap value to pipeline fetching of shift_reg value and MAC operation
                    xtap_value_c = x_in_dout;
                    // Increment taps_counter_c starting here so we always get the right value in S1
                    taps_counter_c = taps_counter + 1'b1;
                end else
                    next_state = S0;
            end
            
        end

        S1: begin
            // Shift y register NUM_TAPs times NOT DECIMATION times but do not shift in new value
            if (yshift_counter < NUM_TAPS - 1) begin 
                yshift_reg_c[1:NUM_TAPS-1] = yshift_reg[0:NUM_TAPS-2];
                yshift_counter_c = yshift_counter + 1'b1;
                next_state = S1;
            end else begin
                next_state = S2;
                // Assign first tap value for y too
                ytap_value_c = yshift_reg[0];
            end
        end

        S2: begin
            // Acounting for if taps_value overflows depending on NUM_TAPs and the bits required to represent it
            if (taps_counter == 0) begin
                y1_sum_c = $signed(y1_sum) + MULTIPLY_ROUNDING(xtap_value,IIR_X_COEFFS[NUM_TAPS-1]);
                y2_sum_c = $signed(y2_sum) + MULTIPLY_ROUNDING(ytap_value, IIR_Y_COEFFS[NUM_TAPS-1]);
                // y1_sum_c = $signed(y1_sum) + DEQUANTIZE($signed(xtap_value) * $signed(IIR_X_COEFFS[NUM_TAPS-1]));
                // y2_sum_c = $signed(y2_sum) + DEQUANTIZE($signed(ytap_value) * $signed(IIR_Y_COEFFS[NUM_TAPS-1]));
            end else begin
                y1_sum_c = $signed(y1_sum) + MULTIPLY_ROUNDING(xtap_value,IIR_X_COEFFS[taps_counter-1]);
                y2_sum_c = $signed(y2_sum) + MULTIPLY_ROUNDING(ytap_value, IIR_Y_COEFFS[taps_counter-1]);
                // y1_sum_c = $signed(y1_sum) + DEQUANTIZE($signed(xtap_value) * $signed(IIR_X_COEFFS[taps_counter-1]));
                // y2_sum_c = $signed(y2_sum) + DEQUANTIZE($signed(ytap_value) * $signed(IIR_Y_COEFFS[taps_counter-1]));
            end
            // y1_sum_c = $signed(y1_sum) + DEQUANTIZE(y1_product);
            // y2_sum_c = $signed(y2_sum) + DEQUANTIZE(y2_product);
            taps_counter_c = taps_counter + 1'b1;
            xtap_value_c = xshift_reg[taps_counter];
            ytap_value_c = yshift_reg[taps_counter];
            if (taps_counter == NUM_TAPS || taps_counter == 0)
                next_state = S3;
            else
                next_state = S2;
        end

        S3: begin
            if (y_out_full == 1'b0) begin
                // Write last value in yshift_reg to y_out
                y_out_wr_en = 1'b1;
                y_out_din = yshift_reg[NUM_TAPS-1];
                // Shift in sum of y1 and y2 into yshift_reg_c[0]
                yshift_reg_c[0] = $signed(y1_sum) + $signed(y2_sum);
                // Reset all the values for the next set of data
                taps_counter_c = '0;
                decimation_counter_c = '0;
                y1_sum_c = '0;
                y2_sum_c = '0;
                yshift_counter_c = '0;
                next_state = S0;
            end
        end

        default: begin
            next_state = S0;
            x_in_rd_en = 1'b0;
            y_out_wr_en = 1'b0;
            y_out_din = '0;
            decimation_counter_c = 'X;
            taps_counter_c = 'X;
            y1_sum_c = 'X;
            y2_sum_c = 'X;
            xshift_reg_c = '{default: '{default: 0}};
            yshift_reg_c = '{default: '{default: 0}};
            yshift_counter_c = 'X;
        end
    endcase
end


endmodule