`include "globals.sv"

module fm_radio_test #(
    parameter DATA_SIZE = 32,
    parameter CHAR_SIZE = 16,
    parameter BYTE_SIZE = 8,
    parameter BITS = 10,
    parameter GAIN = 1,

    parameter CHANNEL_COEFF_TAPS = 20,
    parameter logic signed [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0] CHANNEL_COEFFICIENTS_REAL = '{
	32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
	32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
	32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001},
    parameter logic signed [0:CHANNEL_COEFF_TAPS-1] [DATA_SIZE-1:0]  CHANNEL_COEFFICIENTS_IMAG = '{
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
    
    parameter  AUDIO_LPR_COEFF_TAPS = 32,
    parameter logic signed [0:AUDIO_LPR_COEFF_TAPS-1] [DATA_SIZE-1:0] AUDIO_LPR_COEFFS = '{
        32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3, 
        32'h00000015, 32'h00000043, 32'h0000009b, 32'h000000f9, 32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243, 
	    32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d, 32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015, 
	    32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5, 32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
    }, 

    parameter AUDIO_LMR_COEFF_TAPS = 32,
    parameter logic signed [0:AUDIO_LMR_COEFF_TAPS-1] [DATA_SIZE-1:0] AUDIO_LMR_COEFFS = '{
        32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3, 
        32'h00000015, 32'h0000004e, 32'h0000009b, 32'h000000f9, 32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243, 
        32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d, 32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015, 
        32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5, 32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
    },

    parameter BP_LMR_COEFF_TAPS = 32,
    parameter logic signed [0:BP_LMR_COEFF_TAPS-1] [DATA_SIZE-1:0] BP_LMR_COEFFS = '{
        32'h00000000, 32'h00000000, 32'hfffffffc, 32'hfffffff9, 32'hfffffffe, 32'h00000008, 32'h0000000c, 32'h00000002, 
        32'h00000003, 32'h0000001e, 32'h00000030, 32'hfffffffc, 32'hffffff8c, 32'hffffff58, 32'hffffffc3, 32'h0000008a, 
        32'h0000008a, 32'hffffffc3, 32'hffffff58, 32'hffffff8c, 32'hfffffffc, 32'h00000030, 32'h0000001e, 32'h00000003, 
        32'h00000002, 32'h0000000c, 32'h00000008, 32'hfffffffe, 32'hfffffff9, 32'hfffffffc, 32'h00000000, 32'h00000000
    },

    parameter BP_PILOT_COEFF_TAPS = 32,
    parameter logic signed [0:BP_PILOT_COEFF_TAPS-1] [DATA_SIZE-1:0] BP_PILOT_COEFFS = '{
        32'h0000000e, 32'h0000001f, 32'h00000034, 32'h00000048, 32'h0000004e, 32'h00000036, 32'hfffffff8, 32'hffffff98, 
        32'hffffff2d, 32'hfffffeda, 32'hfffffec3, 32'hfffffefe, 32'hffffff8a, 32'h0000004a, 32'h0000010f, 32'h000001a1, 
        32'h000001a1, 32'h0000010f, 32'h0000004a, 32'hffffff8a, 32'hfffffefe, 32'hfffffec3, 32'hfffffeda, 32'hffffff2d, 
        32'hffffff98, 32'hfffffff8, 32'h00000036, 32'h0000004e, 32'h00000048, 32'h00000034, 32'h0000001f, 32'h0000000e
    },

    parameter HP_COEFF_TAPS = 32,
    parameter logic signed [0:HP_COEFF_TAPS-1] [DATA_SIZE-1:0] HP_COEFFS = '{
        32'hffffffff, 32'h00000000, 32'h00000000, 32'h00000002, 32'h00000004, 32'h00000008, 32'h0000000b, 32'h0000000c, 
        32'h00000008, 32'hffffffff, 32'hffffffee, 32'hffffffd7, 32'hffffffbb, 32'hffffff9f, 32'hffffff87, 32'hffffff76, 
        32'hffffff76, 32'hffffff87, 32'hffffff9f, 32'hffffffbb, 32'hffffffd7, 32'hffffffee, 32'hffffffff, 32'h00000008, 
        32'h0000000c, 32'h0000000b, 32'h00000008, 32'h00000004, 32'h00000002, 32'h00000000, 32'h00000000, 32'hffffffff
    },

    parameter IIR_COEFF_TAPS = 2,
    parameter logic signed [0:IIR_COEFF_TAPS-1] [DATA_SIZE-1:0] IIR_X_COEFFS = '{32'h000000b2, 32'h000000b2},
    parameter logic signed [0:IIR_COEFF_TAPS-1] [DATA_SIZE-1:0] IIR_Y_COEFFS = '{32'h00000000, 32'hfffffd66},
    
    parameter FIFO_BUFFER_SIZE = 1024,
    parameter AUDIO_DECIMATION = 8

) (
    input   logic                   clock,
    input   logic                   reset,
    
    output  logic                   square_bp_pilot_out_full,
    input   logic                   square_bp_pilot_out_wr_en,
    input   logic [DATA_SIZE-1:0]   square_bp_pilot_out_din,

    output  logic                   demod_out_full,
    input   logic                   demod_out_wr_en,
    input   logic [DATA_SIZE-1:0]   demod_out_din,

    output  logic [DATA_SIZE-1:0]   left_audio_out,
    output  logic                   left_audio_empty,
    input   logic                   left_audio_rd_en,

    output  logic [DATA_SIZE-1:0]   right_audio_out,
    output  logic                   right_audio_empty,
    input   logic                   right_audio_rd_en
);

// Wires from DEMOD_FIFO to FIRs
logic demod_rd_en;
logic bp_lmr_fir_rd_en;
logic lpr_fir_rd_en;
// logic bp_pilot_demod_rd_en;
// assign demod_rd_en = lpr_fir_demod_rd_en && bp_lmr_fir_demod_rd_en && bp_pilot_demod_rd_en;
assign demod_rd_en = bp_lmr_fir_rd_en && lpr_fir_rd_en;

logic [DATA_SIZE-1:0] demod_out_dout;
logic demod_empty;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) demod_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(demod_out_wr_en),
    .din(demod_out_din),
    .full(demod_out_full),
    .rd_clk(clock),
    .rd_en(demod_rd_en),
    .dout(demod_out_dout),
    .empty(demod_empty)
);

// Wires from BP_LMR_INST to BP_LMR_FIFO
logic bp_lmr_out_wr_en;
logic bp_lmr_out_full;
logic [DATA_SIZE-1:0] bp_lmr_out_din;

fir #(
    .NUM_TAPS(BP_LMR_COEFF_TAPS),
    .DECIMATION(1),
    .COEFFICIENTS(BP_LMR_COEFFS)
) bp_lmr_fir_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(demod_out_dout),
    .x_in_empty(demod_empty),
    .x_in_rd_en(bp_lmr_fir_rd_en),
    .y_out_wr_en(bp_lmr_out_wr_en),
    .y_out_full(bp_lmr_out_full),
    .y_out_din(bp_lmr_out_din)
);

// Wires from SQUARE_BP_PILOT_FIFO to HP_FIR (high-pass FIR)
logic square_bp_pilot_rd_en;
logic square_bp_pilot_empty;
logic [DATA_SIZE-1:0] square_bp_pilot_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) square_bp_pilot_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(square_bp_pilot_out_wr_en),
    .din(square_bp_pilot_out_din),
    .full(square_bp_pilot_out_full),
    .rd_clk(clock),
    .rd_en(square_bp_pilot_rd_en),
    .dout(square_bp_pilot_out_dout),
    .empty(square_bp_pilot_empty)
);

// Wires from HP_PILOT_FIR to HP_PILOT_FIFO
logic hp_pilot_out_wr_en;
logic hp_pilot_out_full;
logic [DATA_SIZE-1:0] hp_pilot_out_din;

fir #(
    .NUM_TAPS(HP_COEFF_TAPS),
    .DECIMATION(1),
    .COEFFICIENTS(HP_COEFFS)
) hp_pilot_fir_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(square_bp_pilot_out_dout),
    .x_in_empty(square_bp_pilot_empty),
    .x_in_rd_en(square_bp_pilot_rd_en),
    .y_out_wr_en(hp_pilot_out_wr_en),
    .y_out_full(hp_pilot_out_full),
    .y_out_din(hp_pilot_out_din)
);

// Wires from HP_PILOT_FIFO to MULT_DEMOD_LMR
logic hp_pilot_rd_en;
logic hp_pilot_empty;
logic [DATA_SIZE-1:0] hp_pilot_out_dout;


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) hp_pilot_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(hp_pilot_out_wr_en),
    .din(hp_pilot_out_din),
    .full(hp_pilot_out_full),
    .rd_clk(clock),
    .rd_en(hp_pilot_rd_en),
    .dout(hp_pilot_out_dout),
    .empty(hp_pilot_empty)
);


// Wires from BP_LMR_FIFO to MULT_DEMOD_LMR_INST
logic bp_lmr_rd_en;
logic bp_lmr_empty;
logic [DATA_SIZE-1:0] bp_lmr_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) bp_lmr_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(bp_lmr_out_wr_en),
    .din(bp_lmr_out_din),
    .full(bp_lmr_out_full),
    .rd_clk(clock),
    .rd_en(bp_lmr_rd_en),
    .dout(bp_lmr_out_dout),
    .empty(bp_lmr_empty)
);

// Wires from MULT_DEMOD_LMR_INST to MULT_DEMOD_LMR_FIFO
logic mult_demod_lmr_wr_en;
logic mult_demod_lmr_full;
logic [DATA_SIZE-1:0] mult_demod_lmr_out_din;

multiply #(
    .DATA_SIZE(DATA_SIZE)
) mult_demod_lmr_inst (
    .clock(clock),
    .reset(reset),
    .x_in_rd_en(hp_pilot_rd_en),
    .y_in_rd_en(bp_lmr_rd_en),
    .x_in_empty(hp_pilot_empty),
    .y_in_empty(bp_lmr_empty),
    .out_wr_en(mult_demod_lmr_wr_en),
    .out_full(mult_demod_lmr_full),
    .x(hp_pilot_out_dout),
    .y(bp_lmr_out_dout),
    .dout(mult_demod_lmr_out_din)
);

// Wires from LPR_INST to LPR_FIFO
logic lpr_out_wr_en;
logic lpr_out_full;
logic [DATA_SIZE-1:0] lpr_out_din;

fir #(
    .NUM_TAPS(AUDIO_LPR_COEFF_TAPS),
    .DECIMATION(AUDIO_DECIMATION),
    .COEFFICIENTS(AUDIO_LPR_COEFFS)
) lpr_fir_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(demod_out_dout),
    .x_in_empty(demod_empty),
    .x_in_rd_en(lpr_fir_rd_en),   // CHANGE LATER
    .y_out_wr_en(lpr_out_wr_en),
    .y_out_full(lpr_out_full),
    .y_out_din(lpr_out_din)
);

// Wires from LPR_FIFO to ADD or SUB
logic add_lpr_rd_en;
logic sub_lpr_rd_en;
logic lpr_rd_en;
assign lpr_rd_en = add_lpr_rd_en && sub_lpr_rd_en;
logic lpr_empty;
logic [DATA_SIZE-1:0] lpr_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) lpr_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(lpr_out_wr_en),
    .din(lpr_out_din),
    .full(lpr_out_full),
    .rd_clk(clock),
    .rd_en(lpr_rd_en),
    .dout(lpr_out_dout),
    .empty(lpr_empty)
);

// Wires from MULT_DEMOD_FIFO to LMR_FIR
logic mult_demod_lmr_rd_en;
logic mult_demod_lmr_empty;
logic [DATA_SIZE-1:0] mult_demod_lmr_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) mult_demod_lmr_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(mult_demod_lmr_wr_en),
    .din(mult_demod_lmr_out_din),
    .full(mult_demod_lmr_full),
    .rd_clk(clock),
    .rd_en(mult_demod_lmr_rd_en),
    .dout(mult_demod_lmr_out_dout),
    .empty(mult_demod_lmr_empty)
);

// Wires from LMR_FIR_INST to LMR_FIFO
logic lmr_out_wr_en;
logic lmr_out_full;
logic [DATA_SIZE-1:0] lmr_out_din;

fir #(
    .NUM_TAPS(AUDIO_LMR_COEFF_TAPS),
    .DECIMATION(AUDIO_DECIMATION),
    .COEFFICIENTS(AUDIO_LMR_COEFFS)
) lmr_fir_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(mult_demod_lmr_out_dout),
    .x_in_empty(mult_demod_lmr_empty),
    .x_in_rd_en(mult_demod_lmr_rd_en),
    .y_out_wr_en(lmr_out_wr_en),
    .y_out_full(lmr_out_full),
    .y_out_din(lmr_out_din)
);

// Wires from LMR_FIFO to ADD_INST
logic add_lmr_rd_en;
logic sub_lmr_rd_en;

logic lmr_rd_en;
assign lmr_rd_en = add_lmr_rd_en && sub_lmr_rd_en;

logic lmr_empty;
logic [DATA_SIZE-1:0] lmr_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) lmr_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(lmr_out_wr_en),
    .din(lmr_out_din),
    .full(lmr_out_full),
    .rd_clk(clock),
    .rd_en(lmr_rd_en),
    .dout(lmr_out_dout),
    .empty(lmr_empty)
);


// Wires from ADD_INST to ADD_FIFO
logic left_wr_en;
logic left_full;
logic [DATA_SIZE-1:0] left_out_din;

add #() add_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(lpr_out_dout),
    .x_in_empty(lpr_empty),
    .x_in_rd_en(add_lpr_rd_en),
    .y_in_dout(lmr_out_dout),
    .y_in_empty(lmr_empty),
    .y_in_rd_en(add_lmr_rd_en),
    .out_wr_en(left_wr_en),
    .out_full(left_full),
    .out_din(left_out_din)
);

// Wires from LEFT_FIFO to LEFT_DEEMPH
logic left_rd_en;
logic left_empty;
logic [DATA_SIZE-1:0] left_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) left_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(left_wr_en),
    .din(left_out_din),
    .full(left_full),
    .rd_clk(clock),
    .rd_en(left_rd_en),
    .dout(left_out_dout),
    .empty(left_empty)
);

// Wires from SUB_INST to RIGHT_FIFO
logic right_wr_en;
logic right_full;
logic [DATA_SIZE-1:0] right_out_din;

sub #() sub_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(lpr_out_dout),
    .x_in_empty(lpr_empty),
    .x_in_rd_en(sub_lpr_rd_en),
    .y_in_dout(lmr_out_dout),
    .y_in_empty(lmr_empty),
    .y_in_rd_en(sub_lmr_rd_en),
    .out_wr_en(right_wr_en),
    .out_full(right_full),
    .out_din(right_out_din)
);

// Wires from RIGHT_FIFO to RIGHT_DEEMPH
logic right_rd_en;
logic right_empty;
logic [DATA_SIZE-1:0] right_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) right_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(right_wr_en),
    .din(right_out_din),
    .full(right_full),
    .rd_clk(clock),
    .rd_en(right_rd_en),
    .dout(right_out_dout),
    .empty(right_empty)
);

// Wires from LEFT_DEEMPH to LEFT_DEEMPH_FIFO
logic left_deemph_wr_en;
logic left_deemph_full;
logic [DATA_SIZE-1:0] left_deemph_out_din;

iir #(
    .NUM_TAPS(IIR_COEFF_TAPS),
    .IIR_X_COEFFS(IIR_X_COEFFS),
    .IIR_Y_COEFFS(IIR_Y_COEFFS)
) left_deemph_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(left_out_dout),
    .x_in_empty(left_empty),
    .x_in_rd_en(left_rd_en),
    .y_out_wr_en(left_deemph_wr_en),
    .y_out_full(left_deemph_full),
    .y_out_din(left_deemph_out_din)
);

// Wires from LEFT_DEEMPH_FIFO to LEFT_GAIN
logic left_deemph_rd_en;
logic left_deemph_empty;
logic [DATA_SIZE-1:0] left_deemph_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) left_deemph_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(left_deemph_wr_en),
    .din(left_deemph_out_din),
    .full(left_deemph_full),
    .rd_clk(clock),
    .rd_en(left_deemph_rd_en),
    .dout(left_deemph_out_dout),
    .empty(left_deemph_empty)
);

// Wires from RIGHT_DEEMPH to RIGHT_DEEMPH_FIFO
logic right_deemph_wr_en;
logic right_deemph_full;
logic [DATA_SIZE-1:0] right_deemph_out_din;

iir #(
    .NUM_TAPS(IIR_COEFF_TAPS),
    .IIR_X_COEFFS(IIR_X_COEFFS),
    .IIR_Y_COEFFS(IIR_Y_COEFFS)
) right_deemph_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(right_out_dout),
    .x_in_empty(right_empty),
    .x_in_rd_en(right_rd_en),
    .y_out_wr_en(right_deemph_wr_en),
    .y_out_full(right_deemph_full),
    .y_out_din(right_deemph_out_din)
);

// Wires from LEFT_DEEMPH_FIFO to LEFT_GAIN
logic right_deemph_rd_en;
logic right_deemph_empty;
logic [DATA_SIZE-1:0] right_deemph_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) right_deemph_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(right_deemph_wr_en),
    .din(right_deemph_out_din),
    .full(right_deemph_full),
    .rd_clk(clock),
    .rd_en(right_deemph_rd_en),
    .dout(right_deemph_out_dout),
    .empty(right_deemph_empty)
);

logic [31:0] quant_gain = QUANTIZE_I(GAIN);

// Wires from LEFT_GAIN to LEFT_GAIN_FIFO
logic left_gain_full;
logic left_gain_wr_en;
logic [DATA_SIZE-1:0] left_gain_out_din;

gain #(
    .DATA_SIZE(DATA_SIZE),
    .BITS(BITS)
) left_gain_inst (
    .clock(clock),
    .reset(reset),
    .in_rd_en(left_deemph_rd_en), 
    .in_empty(left_deemph_empty),
    .din(left_deemph_out_din),
    .out_full(left_gain_full),
    .out_wr_en(left_gain_wr_en),
    .dout(left_gain_out_din),
    .volume(quant_gain)
);

// Wires from RIGHT_GAIN to RIGHT_GAIN_FIFO
logic right_gain_full;
logic right_gain_wr_en;
logic [DATA_SIZE-1:0] right_gain_out_din;

gain #(
    .DATA_SIZE(DATA_SIZE),
    .BITS(BITS)
) right_gain_inst (
    .clock(clock),
    .reset(reset),
    .in_rd_en(right_deemph_rd_en), 
    .in_empty(right_deemph_empty),
    .din(right_deemph_out_dout),
    .out_full(right_gain_full),
    .out_wr_en(right_gain_wr_en),
    .dout(right_gain_out_din),
    .volume(quant_gain)
);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) left_gain_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(left_gain_wr_en),
    .din(left_gain_out_din),
    .full(left_gain_full),
    .rd_clk(clock),
    .rd_en(left_audio_rd_en),
    .dout(left_audio_out),
    .empty(left_audio_empty)
);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) right_gain_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(right_gain_wr_en),
    .din(right_gain_out_din),
    .full(right_gain_full),
    .rd_clk(clock),
    .rd_en(right_audio_rd_en),
    .dout(right_audio_out),
    .empty(right_audio_empty)
);

endmodule