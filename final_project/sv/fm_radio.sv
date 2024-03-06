`include "globals.sv"

module fm_radio #(
    parameter DATA_SIZE = 32,
    parameter CHAR_SIZE = 16,
    parameter BYTE_SIZE = 8,
    parameter BITS = 10

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
    .FIFO_BUFFER_SIZE()
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
    .FIFO_BUFFER_SIZE()
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
    .FIFO_BUFFER_SIZE()
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




endmodule