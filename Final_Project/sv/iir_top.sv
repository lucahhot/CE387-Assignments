`include "globals.sv" 

module iir_top #(
    parameter FIFO_BUFFER_SIZE = 16
) (
    input   logic                   clock,
    input   logic                   reset,
    output  logic                   x_in_full,
    input   logic                   x_in_wr_en,
    input   logic [DATA_SIZE-1:0]   x_in_din,

    output  logic                   y_out_empty,
    input   logic                   y_out_rd_en,
    output  logic [DATA_SIZE-1:0]   y_out_dout
);

// Wires from input FIFO to iir module
logic x_in_rd_en;
logic x_in_empty;
logic [DATA_SIZE-1:0] x_in_dout;

// x_in FIFO
fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_x_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(x_in_wr_en),
    .din(x_in_din),
    .full(x_in_full),
    .rd_clk(clock),
    .rd_en(x_in_rd_en),
    .dout(x_in_dout),
    .empty(x_in_empty)
);

// Wires from iir module to output FIFO
logic y_out_wr_en;
logic y_out_full;
logic [DATA_SIZE-1:0] y_out_din;

// iir module
iir iir_inst (
    .clock(clock),
    .reset(reset),
    .x_in_dout(x_in_dout),
    .x_in_empty(x_in_empty),
    .x_in_rd_en(x_in_rd_en),
    .y_out_wr_en(y_out_wr_en),
    .y_out_full(y_out_full),
    .y_out_din(y_out_din)
);

// y_out FIFO
fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_y_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(y_out_wr_en),
    .din(y_out_din),
    .full(y_out_full),
    .rd_clk(clock),
    .rd_en(y_out_rd_en),
    .dout(y_out_dout),
    .empty(y_out_empty)
);

endmodule