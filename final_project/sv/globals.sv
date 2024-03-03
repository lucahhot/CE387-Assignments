`ifndef __GLOBALS__
`define __GLOBALS__

localparam BITS = 10;
localparam QUANT_VAL = (1 << BITS);
localparam DATA_SIZE = 32;
localparam DATA_SIZE_2 = 64;
localparam MAX_VALUE = '1 >> 1;
localparam MIN_VALUE = 1 << (DATA_SIZE-1);

// DEQUANTIZE function
function logic signed [DATA_SIZE_2-1:0] DEQUANTIZE(logic signed [DATA_SIZE_2-1:0] i);
    DEQUANTIZE = i >>> BITS;
endfunction

// Multiply function using trucation (assumed quantized inputs)
function logic signed [DATA_SIZE-1:0] MULTIPLY_TRUNCATION(logic signed [DATA_SIZE-1:0] x, logic signed [DATA_SIZE-1:0] y);

    // Perform truncation multiplication
    logic signed [DATA_SIZE_2-1:0] temp;
    temp = DATA_SIZE_2'(x) * DATA_SIZE_2'(y);
    // Shift the fixed point back and truncate the output
    MULTIPLY_TRUNCATION = DATA_SIZE'(DEQUANTIZE(temp));   

endfunction

// Multiply function using rounding & saturation (assumed quantized inputs)
function logic signed [DATA_SIZE-1:0] MULTIPLY_ROUNDING(logic signed [DATA_SIZE-1:0] x, logic signed [DATA_SIZE-1:0] y);

    logic signed [DATA_SIZE_2-1:0] temp;
    temp = DATA_SIZE_2'(x) * y;
    // Add 1/2 to give correct rounding 
    temp = temp + (1 << BITS - 1);
    // Dequantize
    temp = DEQUANTIZE(temp);
    // Saturate result
    if (temp > $signed(MAX_VALUE))
        MULTIPLY_ROUNDING = MAX_VALUE;
    else if (temp < $signed(MIN_VALUE))
        MULTIPLY_ROUNDING = MIN_VALUE;
    // Shift the fixed point back and truncate the output
    MULTIPLY_ROUNDING = DATA_SIZE'(temp);   

endfunction

`endif