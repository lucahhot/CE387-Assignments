`ifndef __GLOBALS__
`define __GLOBALS__

// UVM Globals
localparam CLOCK_PERIOD = 10;
localparam BITS = 10;
localparam QUANT_VAL = (1 << BITS);
localparam M_PI = 3.14159265358979323846;
localparam DATA_SIZE = 32;
localparam DATA_SIZE_2 = 64;
localparam string FILE_OUT_NAME = "../source/uvm_test_output.txt";

// NOT SYNTHESIZABLE! FIXED POINTS ARE JUST REPRESENTED WITH INTS
// // QUANTIZE_F function
// function int QUANTIZE_F(shortreal i);
//     QUANTIZE_F = int'(shortreal'(i) * shortreal'(QUANT_VAL));
// endfunction

// // DEQUANTIZE_F function
// function shortreal DEQUANTIZE_F(int i);
//     DEQUANTIZE_F = shortreal'(shortreal'(i) / shortreal'(QUANT_VAL));
// endfunction

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

localparam K = 1.646760258121066;
localparam logic signed [31:0] CORDIC_1K = QUANTIZE_F(1/K);
localparam logic signed [31:0] PI = QUANTIZE_F(M_PI);
localparam logic signed [31:0] HALF_PI = QUANTIZE_F(M_PI/2);
localparam logic signed [31:0] TWO_PI = QUANTIZE_F(M_PI*2);


`endif
                        