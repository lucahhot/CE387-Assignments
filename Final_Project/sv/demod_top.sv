
module demod_top (
    input   logic           clk,
    input   logic           reset,
    input   logic [31:0]    real_in,
    input   logic [31:0]    imag_in,
    input   logic           in_fifo_wr_en,
    input   logic           out_fifo_rd_en,
    output  logic [31:0]    data_out,
    output  logic           in_fifos_full,
    output  logic           out_fifo_empty
);

// input fifo internals
logic real_fifo_rd_en, real_fifo_full, real_fifo_empty;
logic imag_fifo_rd_en, imag_fifo_full, imag_fifo_empty;
logic input_fifos_empty;

assign in_fifos_full = real_fifo_full || imag_fifo_full;
assign input_fifos_empty = real_fifo_empty || imag_fifo_empty;

logic [31:0] real_fifo_dout, imag_fifo_dout, demod_out;

// output fifo internals
logic out_fifo_wr_en, out_fifo_full;

fifo #(
    .FIFO_DATA_WIDTH(32),
    .FIFO_BUFFER_SIZE(1024)
) real_input_fifo (
    .rst_n(~reset),
    .wr_clk(clk),
    .wr_en(in_fifo_wr_en),
    .din(real_in),
    .full(real_fifo_full),
    .rd_clk(clk),
    .rd_en(in_fifo_rd_en),
    .dout(real_fifo_dout),
    .empty(real_fifo_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(32),
    .FIFO_BUFFER_SIZE(1024)
) imag_input_fifo (
    .rst_n(~reset),
    .wr_clk(clk),
    .wr_en(in_fifo_wr_en),
    .din(imag_in),
    .full(imag_fifo_full),
    .rd_clk(clk),
    .rd_en(in_fifo_rd_en),
    .dout(imag_fifo_dout),
    .empty(imag_fifo_empty)
);

demodulate demod_inst (
    .clk(clk),
    .reset(reset),
    .input_fifos_empty(input_fifos_empty),
    .input_rd_en(in_fifo_rd_en),
    .real_in(real_fifo_dout),
    .imag_in(imag_fifo_dout),
    .demod_out(demod_out),
    .wr_en_out(out_fifo_wr_en),
    .out_fifo_full(out_fifo_full)
);

fifo #(
    .FIFO_DATA_WIDTH (32),
    .FIFO_BUFFER_SIZE (1024)
) output_fifo (
    .rst_n(~reset),
    .wr_clk(clk),
    .wr_en(out_fifo_wr_en),
    .din(demod_out),
    .full(out_fifo_full),
    .rd_clk(clk),
    .rd_en(out_fifo_rd_en),
    .dout(data_out),
    .empty(out_fifo_empty)
);

    
endmodule