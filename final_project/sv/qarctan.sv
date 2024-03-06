//`include "coeffs.svh"
// `include "macros.svh"
`include "globals.sv"
module qarctan
(
    input   logic           clk,
    input   logic           reset,
    input   logic           demod_data_valid,
    output  logic           divider_ready,
    input   logic [31:0]    x,
    input   logic [31:0]    y,
    output  logic [31:0]    data_out,
    output  logic           qarctan_done   
);

    
const logic [31:0] QUAD_ONE = 32'h00000324;
const logic [31:0] QUAD_THREE = 32'h0000096c;

import macros::*;

typedef enum logic {READY, WORKING} state_t;
state_t state, state_c;

// divider signals
logic start_div, div_overflow_out, div_valid_out;
logic [63:0] dividend, dividend_c;
logic [31:0] divisor, divisor_c;
logic [63:0] div_quotient_out;
logic [31:0] div_remainder_out;

// internal signals
logic [31:0] angle;
logic [31:0] abs_y, pseudo_abs_y;
logic [31:0] x_minus_abs_y;
logic [31:0] x_plus_abs_y;
logic [31:0] abs_y_minus_x;
logic [31:0] quant_x_minus_abs_y;
logic [31:0] quant_x_plus_abs_y;
logic [63:0] quad_one_times_r;
logic [31:0] lower_quad_one_times_r;

div #(
    .DIVIDEND_WIDTH(64),
    .DIVISOR_WIDTH(32)
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
        dividend <= '0;
        divisor <= '0;
    end else begin
        state <= state_c;
        dividend <= dividend_c;
        divisor <= divisor_c;
    end
end

always_comb begin
    // output the current readiness of the divider
    qarctan_done = div_valid_out;
    data_out = '0;
    divider_ready = (state == READY);

    // keep signals in the flops
    dividend_c = dividend;
    divisor_c = divisor;

    // drive other signals to 0
    quad_one_times_r = '0;
    lower_quad_one_times_r = '0;
    angle = '0;

    case(state)
        // the divider is not doing anything
        READY: begin
            // there is valid data from demod
            if (demod_data_valid == 1'b1) begin
                start_div = 1'b1;
                state_c = WORKING;
                if ($signed(x) >= 0) begin
                    dividend_c = ($signed(quant_x_minus_abs_y) >= 0) ? {32'h0, quant_x_minus_abs_y} : {32'hffffffff, quant_x_minus_abs_y};
                    divisor_c = x_plus_abs_y;
                end else begin
                    dividend_c = ($signed(quant_x_plus_abs_y) >= 0) ? {32'h0, quant_x_plus_abs_y} : {32'hffffffff, quant_x_plus_abs_y};
                    divisor_c = abs_y_minus_x;
                end
            end
            else begin
                start_div = 1'b0;
                state_c = READY;
            end
        end
        // the divider is doing a computation
        WORKING: begin
            start_div = 1'b0;
            // if the divider has completed
            if (div_valid_out == 1'b1) begin
                state_c = READY;
                quad_one_times_r = $signed(QUAD_ONE) * $signed(div_quotient_out);
                lower_quad_one_times_r = quad_one_times_r[31:0];
                if (x == '0 && y == '0) begin
                    angle = 32'h648;
                end else if ($signed(x) >= 0) begin
                    angle = ($signed(QUAD_ONE) - $signed(DEQUANTIZE(lower_quad_one_times_r)));
                end else begin
                    angle = ($signed(QUAD_THREE) - $signed(DEQUANTIZE(lower_quad_one_times_r))); 
                end
                data_out = ($signed(y) < 0) ? -$signed(angle) : angle;
            // otherwise keep working
            end else begin
                state_c = WORKING;
            end
        end
    endcase
end

always_comb begin
    pseudo_abs_y = ($signed(y) >= 0) ? y : -$signed(y);
    abs_y = $signed(pseudo_abs_y) + 32'h00000001;
    x_minus_abs_y = $signed(x) - $signed(abs_y);
    x_plus_abs_y = $signed(x) + $signed(abs_y);
    abs_y_minus_x = $signed(abs_y) - $signed(x);
    quant_x_minus_abs_y = QUANTIZE_I(x_minus_abs_y);
    quant_x_plus_abs_y = QUANTIZE_I(x_plus_abs_y);
end

endmodule
