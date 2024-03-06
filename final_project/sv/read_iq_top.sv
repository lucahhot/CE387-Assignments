`include "globals.sv"

module read_iq_top #(
    parameter DATA_SIZE = 32,
    parameter CHAR_SIZE = 16,
    parameter BYTE_SIZE = 8,
    parameter BITS = 10
) (
    input   logic                   clock,
    input   logic                   reset,
    output  logic                   in_full,
    input   logic                   in_wr_en,
    input   logic [BYTE_SIZE-1:0]   in_din,

    output  logic [DATA_SIZE-1:0]   i_out_dout,
    output  logic                   i_out_empty,
    input   logic                   i_out_rd_en,

    output  logic [DATA_SIZE-1:0]   q_out_dout,
    output  logic                   q_out_empty,
    input   logic                   q_out_rd_en

);

// Wires from input FIFO to read_iq module
logic in_rd_en;
logic [BYTE_SIZE-1:0] read_in;
logic in_empty;

localparam int FIFO_BUFFER_SIZE = 32;

fifo #(
    .FIFO_DATA_WIDTH(BYTE_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(in_wr_en),
    .din(in_din),
    .full(in_full),
    .rd_clk(clock),
    .rd_en(in_rd_en),
    .dout(read_in),
    .empty(in_empty)
);

// Wires from read_iq module to output FIFOs
logic i_out_full, q_out_full;
logic out_wr_en;
logic [DATA_SIZE-1:0] i_out, q_out;

read_iq #(
    .DATA_SIZE(DATA_SIZE),
    .CHAR_SIZE(CHAR_SIZE),
    .BYTE(BYTE_SIZE),
    .BITS(BITS)
) read_iq_inst(
    .clock(clock),
    .reset(reset),
    .in_empty(in_empty),
    .in_rd_en(in_rd_en),
    .i_out_full(i_out_full),
    .q_out_full(q_out_full),
    .out_wr_en(out_wr_en),
    .data_in(read_in),
    .i_out(i_out),
    .q_out(q_out)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_q_out_inst(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(out_wr_en),
    .din(q_out),
    .full(q_out_full),
    .rd_clk(clock),
    .rd_en(q_out_rd_en),
    .dout(q_out_dout),
    .empty(q_out_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_i_out_inst(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(out_wr_en),
    .din(i_out),
    .full(i_out_full),
    .rd_clk(clock),
    .rd_en(i_out_rd_en),
    .dout(i_out_dout),
    .empty(i_out_empty)
);

endmodule