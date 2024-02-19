
module fifo_ctrl #(
    parameter FIFO_DATA_WIDTH = 8,
    parameter FIFO_BUFFER_SIZE = 8) 
(
    input  logic reset,
    input  logic wr_clk,
    input  logic wr_en,
    input logic wr_sof,
    input logic wr_eof,
    input  logic [FIFO_DATA_WIDTH-1:0] din,
    output logic full,
    input  logic rd_clk,
    input  logic rd_en,
    output logic rd_sof,
    output logic rd_eof,
    output logic [FIFO_DATA_WIDTH-1:0] dout,
    output logic empty
);

// OR signals for empty and full
logic data_empty, ctrl_empty, data_full, ctrl_full;
assign full = data_full | ctrl_full;
assign empty = data_empty | ctrl_empty; 

// Data FIFO 
fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH)
) fifo_data_inst (
    .reset(reset),
    .wr_clk(wr_clk),
    .wr_en(wr_en),
    .din(din),
    .full(data_full),
    .rd_clk(rd_clk),
    .rd_en(rd_en),
    .dout(dout),
    .empty(data_empty)
);

logic [1:0] ctrl_din;
logic [1:0] ctrl_dout;
assign ctrl_din = {wr_sof,wr_eof};
assign rd_sof = ctrl_dout[1];
assign rd_eof = ctrl_dout[0];

// Control FIFO
fifo #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .FIFO_DATA_WIDTH(2)
) fifo_ctrl_inst (
    .reset(reset),
    .wr_clk(wr_clk),
    .wr_en(wr_en),
    .din(ctrl_din),
    .full(ctrl_full),
    .rd_clk(rd_clk),
    .rd_en(rd_en),
    .dout(ctrl_dout),
    .empty(ctrl_empty)
);

endmodule