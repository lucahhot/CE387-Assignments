`ifndef __GLOBALS__
`define __GLOBALS__

localparam BITS = 10;
localparam QUANT_VAL = (1 << BITS);
localparam BYTE_SIZE = 8;
localparam CHAR_SIZE = 16;
localparam DATA_SIZE = 32;
localparam DATA_SIZE_2 = 64;
localparam MAX_VALUE = '1 >> 1;
localparam MIN_VALUE = 1 << (DATA_SIZE-1);
localparam GAIN = 1;

// DEQUANTIZE function
function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] i);
    // Arithmetic right shift doesn't work well with negative number rounding so switch the sign 
    // to perform the right shift then apply the negative sign to the results
    if (i < 0) 
        DEQUANTIZE = DATA_SIZE'(-(-i >>> BITS));
    else 
        DEQUANTIZE = DATA_SIZE'(i >>> BITS);
endfunction

// QUANTIZE function
function logic signed [DATA_SIZE-1:0] QUANTIZE(logic signed [DATA_SIZE-1:0] i);
    QUANTIZE = DATA_SIZE'(i << BITS);
endfunction

`endif

