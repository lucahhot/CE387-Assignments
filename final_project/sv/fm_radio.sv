`include "globals.sv"

module fm_radio #(
    parameter DATA_SIZE = 32,
    parameter CHAR_SIZE = 16,
    parameter BYTE_SIZE = 8,
    parameter BITS = 10, 
    parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0] COEFFICIENTS_REAL = '{
	32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
	32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
	32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001},
    parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0]  COEFFICIENTS_IMAG = '{
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
    parameter logic signed [0:AUDIO_LMR_COEFF_TAPS] [DATA_SIZE-1:0] AUDIO_LMR_COEFFS = '{
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

    parameter FIFO_BUFFER_SIZE = 1024,
    parameter AUDIO_DECIMATION = 8

) (
    input   logic                   clock,
    input   logic                   reset,
    
    output  logic                   in_full,
    input   logic                   in_wr_en,
    input   logic [BYTE_SIZE-1:0]   data_in,

    output  logic [DATA_SIZE-1:0]   left_audio_out,
    output  logic                   left_audio_empty,
    input   logic                   left_radio_rd_en,

    output  logic [DATA_SIZE-1:0]   right_audio_out,
    output  logic                   right_audio_empty,
    input   logic                   right_audio_rd_en
);

// Wires from input FIFO to read_iq module
logic read_iq_in_rd_en;
logic [BYTE_SIZE-1:0] read_iq_in;
logic read_iq_in_empty;

fifo #(
    .FIFO_DATA_WIDTH(BYTE_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) read_iq_fifo_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(in_wr_en),
    .din(data_in),
    .full(in_full),
    .rd_clk(clock),
    .rd_en(read_iq_in_rd_en),
    .dout(read_iq_in),
    .empty(read_iq_in_empty)
);

// Wires from read_iq module to I FIFO
logic i_out_full;
logic [DATA_SIZE-1:0] i_out;

// Wires from read_iq module to Q FIFO
logic q_out_full;
logic [DATA_SIZE-1:0] q_out;

logic read_iq_out_wr_en;

read_iq #(
    .DATA_SIZE(DATA_SIZE),
    .CHAR_SIZE(CHAR_SIZE),
    .BYTE(BYTE_SIZE),
    .BITS(BITS)
) read_iq_inst (
    .clock(clock),
    .reset(reset),
    .in_empty(read_iq_in_empty),
    .in_rd_en(read_iq_in_rd_en),
    .i_out_full(i_out_full),
    .q_out_full(q_out_full),
    .out_wr_en(read_iq_out_wr_en),
    .data_in(read_iq_in),
    .i_out(i_out),
    .q_out(q_out)
);

// Wires from I FIFO to FIR CMPLX
logic [DATA_SIZE-1:0] i_fifo_out;
logic i_fifo_rd_en;
logic i_fifo_empty;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) i_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(read_iq_out_wr_en),
    .din(i_out),
    .full(i_out_full),
    .rd_clk(clock),
    .rd_en(i_fifo_rd_en),
    .dout(i_fifo_out),
    .empty(i_fifo_empty)
);

// Wires from Q FIFO to FIR CMPLX
logic [DATA_SIZE-1:0] q_fifo_out;
logic q_fifo_rd_en;
logic q_fifo_empty;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(.FIFO_BUFFER_SIZE)
) q_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(read_iq_out_wr_en),
    .din(q_out),
    .full(q_out_full),
    .rd_clk(clock),
    .rd_en(q_fifo_rd_en),
    .dout(q_fifo_out),
    .empty(q_fifo_empty)
);

// REAL == I, IMAG == Q
// Wires from FIR_CMPLX to REAL_FIFO
logic real_out_wr_en;
logic real_out_full;
logic [DATA_SIZE-1:0] real_out_din;

// WIRES FROM FIR_CMPLX TO IMAG_FIFO
logic imag_out_wr_en;
logic imag_out_full;
logic [DATA_SIZE-1:0] imag_out_din;

fir_cmplx #(
    .NUM_TAPS(NUM_TAPS),
    .DECIMATION(DECIMATION),
    .COEFFICIENTS_REAL(COEFFICIENTS_REAL),
    .COEFFICIENTS_IMAG(COEFFICIENTS_IMAG)
) fir_cmplx_inst (
    .clock(clock),
    .reset(reset),
    .xreal_in_dout(i_fifo_out),
    .xreal_in_empty(i_fifo_empty),
    .xreal_in_rd_en(i_fifo_rd_en),
    .ximag_in_dout(q_fifo_out),
    .ximag_in_empty(q_fifo_empty),
    .ximag_in_rd_en(q_fifo_rd_en),
    .yreal_out_wr_en(real_out_wr_en),
    .yreal_out_full(real_out_full),
    .yreal_out_din(real_out_din),
    .yimag_out_wr_en(imag_out_wr_en),
    .yimag_out_full(imag_out_full),
    .yimag_out_din(imag_out_din)
);

// Wires from REAL_FIFO to DEMODULATE
logic [DATA_SIZE-1:0] real_out_dout;
logic real_empty;

logic real_imag_rd_en;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) real_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(real_out_wr_en),
    .din(real_out_din),
    .full(real_out_full),
    .rd_clk(clock),
    .rd_en(real_imag_rd_en),
    .dout(real_out_dout),
    .empty(real_empty)
);

// Wires from IMAG_FIFO to DEMODULATE
logic [DATA_SIZE-1:0] imag_out_dout;
logic imag_empty;


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) imag_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(imag_out_wr_en),
    .din(imag_out_din),
    .full(imag_out_full),
    .rd_clk(clock),
    .rd_en(real_imag_rd_en),
    .dout(imag_out_dout),
    .empty(imag_empty)
);

// INTERMEDIATE SIGNALS
logic demod_input_fifos_empty;
assign demod_input_fifos_empty = real_empty || imag_empty;

// Wires from DEMODULATE to DEMOD_FIFO
logic [DATA_SIZE-1:0] demod_out_din;
logic demod_wr_en_out;
logic demod_out_full;

demodulate #(

) demodulate_inst (
    .clk(clock),
    .reset(reset),
    .input_fifos_empty(demod_input_fifos_empty),
    .input_rd_en(real_imag_rd_en),
    .real_in(real_out_dout),
    .imag_in(imag_out_dout),
    .demod_out(demod_out_din),
    .wr_en_out(demod_wr_en_out),
    .out_fifo_full(demod_out_full)
);

// Wires from DEMOD_FIFO to FIRs
logic demod_rd_en;
logic [DATA_SIZE-1:0] demod_out_dout;
logic demod_empty;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) demod_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(demod_wr_en_out),
    .din(demod_out_din),
    .full(demod_out_full),
    .rd_clk(clock),
    .rd_en(demod_rd_en),
    .dout(demod_out_dout),
    .empty(demod_empty)
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
    .x_in_rd_en(demod_rd_en),
    .y_out_wr_en(lpr_out_wr_en),
    .y_out_full(lpr_out_full),
    .y_out_din(lpr_out_din)
);

// Wires from LPR_FIFO to ADD or SUB
logic lpr_rd_en;
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
    .x_in_rd_en(demod_rd_en),
    .y_out_wr_en(bp_lmr_out_wr_en),
    .y_out_full(bp_lmr_out_full),
    .y_out_din(bp_lmr_out_din)
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

// Wires from BP_PILOT_FIR to BP_PILOT_FIFO
logic bp_pilot_wr_en;
logic bp_pilot_out_full;
logic [DATA_SIZE-1:0] bp_pilot_out_din;


fir #(
    .NUM_TAPS(BP_PILOT_COEFF_TAPS),
    .DECIMATION(1),
    .COEFFICIENTS(BP_PILOT_COEFFS)
) bp_pilot_fir_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(demod_out_dout),
    .x_in_empty(demod_empty),
    .x_in_rd_en(demod_rd_en),
    .y_out_wr_en(bp_pilot_wr_en),
    .y_out_full(bp_pilot_out_full),
    .y_out_din(bp_pilot_out_din)
);

// Wires from BP_PILOT_FIFO to MULTIPLY
logic bp_pilot_rd_en;
logic bp_pilot_empty;
logic [DATA_SIZE-1:0] bp_pilot_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) bp_pilot_fifo_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(bp_pilot_wr_en),
    .din(bp_pilot_out_din),
    .full(bp_pilot_out_full),
    .rd_clk(clock),
    .rd_en(bp_pilot_rd_en),
    .dout(bp_pilot_out_dout),
    .empty(bp_pilot_empty)
);

// Wires from SQUARE_BP_PILOT to SQUARE_BP_PILOT_FIFO
logic square_bp_pilot_wr_en;
logic square_bp_pilot_full;
logic [DATA_SIZE-1:0] square_bp_pilot_out_din;

multiply #(
    .DATA_SIZE(DATA_SIZE)
) square_bp_pilot_inst (
    .clock(clock),
    .reset(reset),
    .x_in_rd_en(bp_pilot_rd_en),
    .y_in_rd_en(bp_pilot_rd_en),
    .x_in_empty(bp_pilot_empty),
    .y_in_empty(bp_pilot_empty),
    .out_wr_en(square_bp_pilot_wr_en),
    .out_full(square_bp_pilot_full),
    .x(bp_pilot_out_dout),
    .y(bp_pilot_out_dout),
    .dout(square_bp_pilot_out_din)
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
    .wr_en(square_bp_pilot_wr_en),
    .din(square_bp_pilot_out_din),
    .full(square_bp_pilot_full),
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

// Wires from MULT_DEMOD_FIFO to LMR_FIR
logic mult_demod_lmr_rd_en;
logic mult_demod_lmr_empty;
logic [DATA_SIZE-1:0] mult_demod_lmr_out_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) mult_demod_lmr_fifo (
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
    .x_in_rd_en(mult_demod_lmr_empty),
    .y_out_wr_en(lmr_out_wr_en),
    .y_out_full(lmr_out_full),
    .y_out_din(lmr_out_din)
);

// Wires from LMR_FIFO to ADD_INST
logic lmr_rd_en;
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





endmodule