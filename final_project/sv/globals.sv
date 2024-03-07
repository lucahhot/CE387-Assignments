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
// localparam string FILE_IN_FILE = "../test/usrp.dat";
// localparam string FILE_LEFT_OUT_FILE = "../source/output_files/fm_radio_left_sim_out.txt";
// localparam string FILE_RIGHT_OUT_FILE = "../source/output_files/fm_radio_right_sim_out.txt";
// localparam string FILE_LEFT_CMP_FILE = "../source/text_files/gain_left.txt";
// localparam string FILE_RIGHT_OUT_FILE = "../source/text_files/gain_right.txt";
localparam GAIN = 1;

parameter CHANNEL_COEFF_TAPS = 20;

parameter logic signed [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0] CHANNEL_COEFFICIENTS_REAL = '{
    32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
    32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
    32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001};

parameter logic signed [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0]  CHANNEL_COEFFICIENTS_IMAG = '{
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};

parameter  AUDIO_LPR_COEFF_TAPS = 32;

parameter logic signed [0:AUDIO_LPR_COEFF_TAPS-1] [DATA_SIZE-1:0] AUDIO_LPR_COEFFS = '{
    32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3, 
    32'h00000015, 32'h00000043, 32'h0000009b, 32'h000000f9, 32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243, 
    32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d, 32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015, 
    32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5, 32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
};

parameter AUDIO_LMR_COEFF_TAPS = 32;

parameter logic signed [0:AUDIO_LMR_COEFF_TAPS-1] [DATA_SIZE-1:0] AUDIO_LMR_COEFFS = '{
    32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3, 
    32'h00000015, 32'h0000004e, 32'h0000009b, 32'h000000f9, 32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243, 
    32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d, 32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015, 
    32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5, 32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
};

parameter BP_LMR_COEFF_TAPS = 32;

parameter logic signed [0:BP_LMR_COEFF_TAPS-1] [DATA_SIZE-1:0] BP_LMR_COEFFS = '{
    32'h00000000, 32'h00000000, 32'hfffffffc, 32'hfffffff9, 32'hfffffffe, 32'h00000008, 32'h0000000c, 32'h00000002, 
    32'h00000003, 32'h0000001e, 32'h00000030, 32'hfffffffc, 32'hffffff8c, 32'hffffff58, 32'hffffffc3, 32'h0000008a, 
    32'h0000008a, 32'hffffffc3, 32'hffffff58, 32'hffffff8c, 32'hfffffffc, 32'h00000030, 32'h0000001e, 32'h00000003, 
    32'h00000002, 32'h0000000c, 32'h00000008, 32'hfffffffe, 32'hfffffff9, 32'hfffffffc, 32'h00000000, 32'h00000000
};

parameter BP_PILOT_COEFF_TAPS = 32;

parameter logic signed [0:BP_PILOT_COEFF_TAPS-1] [DATA_SIZE-1:0] BP_PILOT_COEFFS = '{
    32'h0000000e, 32'h0000001f, 32'h00000034, 32'h00000048, 32'h0000004e, 32'h00000036, 32'hfffffff8, 32'hffffff98, 
    32'hffffff2d, 32'hfffffeda, 32'hfffffec3, 32'hfffffefe, 32'hffffff8a, 32'h0000004a, 32'h0000010f, 32'h000001a1, 
    32'h000001a1, 32'h0000010f, 32'h0000004a, 32'hffffff8a, 32'hfffffefe, 32'hfffffec3, 32'hfffffeda, 32'hffffff2d, 
    32'hffffff98, 32'hfffffff8, 32'h00000036, 32'h0000004e, 32'h00000048, 32'h00000034, 32'h0000001f, 32'h0000000e
};

parameter HP_COEFF_TAPS = 32;

parameter logic signed [0:HP_COEFF_TAPS-1] [DATA_SIZE-1:0] HP_COEFFS = '{
    32'hffffffff, 32'h00000000, 32'h00000000, 32'h00000002, 32'h00000004, 32'h00000008, 32'h0000000b, 32'h0000000c, 
    32'h00000008, 32'hffffffff, 32'hffffffee, 32'hffffffd7, 32'hffffffbb, 32'hffffff9f, 32'hffffff87, 32'hffffff76, 
    32'hffffff76, 32'hffffff87, 32'hffffff9f, 32'hffffffbb, 32'hffffffd7, 32'hffffffee, 32'hffffffff, 32'h00000008, 
    32'h0000000c, 32'h0000000b, 32'h00000008, 32'h00000004, 32'h00000002, 32'h00000000, 32'h00000000, 32'hffffffff
};

parameter FIFO_BUFFER_SIZE = 1024;
parameter AUDIO_DECIMATION = 8;

parameter IIR_COEFF_TAPS = 2;

parameter logic signed [0:IIR_COEFF_TAPS-1] [DATA_SIZE-1:0] IIR_Y_COEFFS = '{32'h00000000, 32'hfffffd66};
parameter logic signed [0:IIR_COEFF_TAPS-1] [DATA_SIZE-1:0] IIR_X_COEFFS = '{32'h000000b2, 32'h000000b2};

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
function logic signed [DATA_SIZE_2-1:0] QUANTIZE(logic signed [DATA_SIZE_2-1:0] i);
    QUANTIZE = i << BITS;
endfunction

// QUANTIZE_I function
function logic signed [DATA_SIZE-1:0] QUANTIZE_I(logic signed [DATA_SIZE-1:0] i);
    QUANTIZE_I = i << BITS;
endfunction

`endif