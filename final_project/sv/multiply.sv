module multiply #(
    parameter DATA_SIZE,
    parameter DATA_SIZE_2
)(
    input logic clock,
    input logic reset,
    output logic x_in_rd_en,
    output logic y_in_rd_en,
    input logic x_in_empty,
    input logic y_in_empty,
    output logic out_wr_en,
    input logic out_full,
    input logic [DATA_SIZE - 1:0] x,
    input logic [DATA_SIZE - 1:0] y,
    output logic [DATA_SIZE - 1:0] dout
);

typedef enum logic [0:0] {S0, S1} state_types;
state_types state, next_state;

logic [DATA_SIZE - 1:0] mult_out, mult_out_c;
logic [DATA_SIZE - 1:0] q_x, q_y;
logic [DATA_SIZE_2 - 1:0] temp;

localparam BITS = 10;

function int QUANTIZE(int i);
    QUANTIZE = i <<< BITS;
endfunction

function int DEQUANTIZE(int i);
    DEQUANTIZE = i >>> BITS;
endfunction

// ASSUME QUANTIZED VALUES, IF NOT QUANTIZED THEN ADD QUANTIZE FUNCTION INTO IT
function int MULTIPLY_FIXED(int x, int y);
    logic signed [DATA_SIZE_2 - 1:0] intermediate;

    intermediate = x * y;

    MULTIPLY_FIXED = DATA_SIZE'(DEQUANTIZE(intermediate));   
endfunction

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        mult_out <= '0;
    end else begin
        mult_out <= mult_out_c;
    end
end

always_comb begin

    if (x_in_empty == 1'b0 && y_in_empty == 1'b0 && out_full == 1'b0) begin
        q_x = QUANTIZE(x);
        q_y = QUANTIZE(y);
        mult_out_c = MULTIPLY_FIXED(q_x, q_y);
        out_wr_en = 1'b1;
        x_in_rd_en = 1'b1;
        y_in_rd_en = 1'b1;
        dout = mult_out;
    end else begin
        out_wr_en = 1'b0;
        x_in_rd_en = 1'b0;
        y_in_rd_en = 1'b0;
        mult_out_c = '0;
        dout = '0;
    end

end

endmodule