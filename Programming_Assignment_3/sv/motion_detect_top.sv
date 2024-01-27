module motion_detect_top #(
    parameter WIDTH = 720,
    parameter HEIGHT = 540
) (
    input logic         clock,
    input logic         reset,
    output logic        base_full,
    input logic         base_wr_en,
    input logic [23:0]  base_din,

    output logic        img_in_full,
    input logic         img_in_wr_en,
    input logic [23:0]  img_in_din,

    output logic        img_out_empty,
    input logic         img_out_rd_en,
    output logic [23:0] img_out_dout
);

logic [23:0]    base_dout;
logic           base_empty;
logic           base_rd_en;

logic [23:0]    img_in_dout;
logic           img_in_empty;
logic           img_in_rd_en;

logic [23:0]    img_out_din;
logic           img_out_full;
logic           img_out_wr_en;

motion_detect motion_detect_inst (
    .clock(clock),
    .reset(reset),
    .base_rd_en(base_rd_en),
    .base_empty(base_empty),
    .base_dout(base_dout),
    .img_in_rd_en(img_in_rd_en),
    .img_in_empty(img_in_empty),
    .img_in_dout(img_in_dout),
    .img_out_wr_en(img_out_wr_en),
    .img_out_full(img_out_full),
    .img_out_din(img_out_din)
);

fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(24)
) fifo_base_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(base_wr_en),
    .din(base_din),
    .full(base_full),
    .rd_clk(clock),
    .rd_en(base_rd_en),
    .dout(base_dout),
    .empty(base_empty)
);

fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(24)
) fifo_img_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(img_in_wr_en),
    .din(img_in_din),
    .full(img_in_full),
    .rd_clk(clock),
    .rd_en(img_in_rd_en),
    .dout(img_in_dout),
    .empty(img_in_empty)
);

fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(24)
) fifo_img_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(img_out_wr_en),
    .din(img_out_din),
    .full(img_out_full),
    .rd_clk(clock),
    .rd_en(img_out_rd_en),
    .dout(img_out_dout),
    .empty(img_out_empty)
);

endmodule

