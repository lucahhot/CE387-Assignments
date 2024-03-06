// macro functions for use in other files

package macros;

int BITS = 10;
logic [31:0] QUANT_VAL = (1 << BITS);
// logic [31:0] QUANT_VAL_FLOAT = 32'h44800000;

// function logic[31:0] QUANTIZE_F; 
// input shortreal f;
//     begin
//         return int'(shortreal'(f) * shortreal'($signed(QUANT_VAL)));
//     end
// endfunction

function logic[31:0] QUANTIZE_I; 
input logic[31:0] i;
    begin
        return int'($signed(i) * $signed(QUANT_VAL));
    end
endfunction

function logic[31:0] DEQUANTIZE; 
input logic[31:0] i;
    begin
        return int'($signed(i) / $signed(QUANT_VAL));
    end
endfunction

// shortreal PI = 3.1415926535897932384626433832795;
// PI in float format
// INEXACT
// logic [31:0] PI = QUANTIZE_F(3.1415926) - 32'h00000001;

int ADC_RATE = 64000000;
int USRP_DECIM = 250;
int QUAD_RATE = int'(ADC_RATE / USRP_DECIM);
int AUDIO_DECIM = 8;
int AUDIO_RATE = int'(QUAD_RATE / AUDIO_DECIM);
// int VOLUME_LEVEL = QUANTIZE_F(1.0);
int SAMPLES = 65536*4;
int AUDIO_SAMPLES = int'(SAMPLES / AUDIO_DECIM);
int MAX_TAPS = 32;

// shortreal MAX_DEV = 55000.0;
// MAX_DEV in float format
// EXACT
// logic [31:0] MAX_DEV = QUANTIZE_F(55000.0);

// int FM_DEMOD_GAIN = QUANTIZE_F(QUAD_RATE / (2.0 * PI * MAX_DEV));

// shortreal TAU = 0.000075;
// TAU in float format
// logic [31:0] TAU = QUANTIZE_F(0.000075);

// shortreal W_PP = 0.21150067;
// W_PP in float format
// logic [31:0] W_PP = QUANTIZE_F(0.21150067) - 32'h00000001;

endpackage