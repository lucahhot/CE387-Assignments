`include "globals.sv"

module gain_top #(
    parameter DATA_SIZE = 32,
    parameter BITS = 10
) (
    input   logic   clock,
    input   logic   reset,
    output  logic   in_full,
    input   logic   in_wr_en,
    input   logic   [DATA_SIZE-1:0] in_din,

    output  logic   [DATA_SIZE-1:0] out_dout,
    output  logic   out_empty,
    input   logic   out_rd_en
);  

localparam int GAIN = 1;
logic [31:0] quant_gain = QUANTIZE_I(GAIN);

// Wires from input FIFO to gain module
logic in_rd_en;
logic [DATA_SIZE-1:0] in_dout;
logic in_empty;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(1024)
) fifo_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(in_wr_en),
    .din(in_din),
    .full(in_full),
    .rd_clk(clock),
    .rd_en(in_rd_en),
    .dout(in_dout),
    .empty(in_empty)
);

// Wires from gain modeul to output FIFO
logic out_full;
logic out_wr_en;
logic [DATA_SIZE-1:0] gain_out;

gain #(
    .DATA_SIZE(DATA_SIZE),
    .BITS(BITS)
) gain_inst (
    .clock(clock),
    .reset(reset),
    .in_rd_en(in_rd_en),
    .in_empty(in_empty),
    .out_full(out_full),
    .out_wr_en(out_wr_en),
    .dout(gain_out),
    .din(in_dout),
    .volume(quant_gain)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(1024)
) fifo_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(out_wr_en),
    .din(gain_out),
    .full(out_full),
    .rd_clk(clock),
    .rd_en(out_rd_en),
    .dout(out_dout),
    .empty(out_empty)
);

endmodule
