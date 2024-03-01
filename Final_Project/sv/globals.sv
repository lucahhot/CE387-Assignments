localparam BITS = 10;
localparam QUANT_VAL = (1 << BITS);
localparam DATA_SIZE = 32;
localparam DATA_SIZE_2 = 64;

// QUANTIZE_F function
function int QUANTIZE_F(shortreal i);
    QUANTIZE_F = int'(shortreal'(i) * shortreal'(QUANT_VAL));
endfunction

// DEQUANTIZE_F function
function shortreal DEQUANTIZE_F(int i);
    DEQUANTIZE_F = shortreal'(shortreal'(i) / shortreal'(QUANT_VAL));
endfunction

// DEQUANTIZE function
function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] i);
    DEQUANTIZE = i >>> BITS;
endfunction

// MULTIPLY_FIXED function (assumed quantized inputs)
function logic signed [DATA_SIZE - 1:0] MULTIPLY_FIXED(logic signed [DATA_SIZE - 1:0] x, logic signed [DATA_SIZE - 1:0] y);

    // Perform truncation multiplication
    logic signed [DATA_SIZE_2 - 1:0] intermediate;
    intermediate = DATA_SIZE_2'(x) * DATA_SIZE_2'(y);
    // Shift the fixed point back and truncate the output
    MULTIPLY_FIXED = DATA_SIZE'(DEQUANTIZE(intermediate));   

endfunction