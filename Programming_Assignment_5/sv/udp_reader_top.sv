module udp_reader_top #(
    parameter FIFO_DATA_WIDTH = 8,
    parameter FIFO_BUFFER_SIZE = 1024
) (
    input   logic         clock,
    input   logic         reset,
    output  logic         in_full,
    input   logic         in_wr_en,
    input   logic [7:0]   in_din,
    input   logic         in_sof,
    input   logic         in_eof,

    output  logic         out_empty,
    input   logic         out_rd_en,
    output  logic [7:0]   out_dout
);

// Logic wires from input FIFO to udp_reader module
logic udp_rd_en;
logic udp_empty;
logic [7:0] udp_dout;
logic udp_in_sof;
logic udp_in_eof;

// Input FIFO control module that takes in data from the TB
fifo_ctrl #(
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_BUFFER_SIZE(16) 
) fifo_ctrl_input_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(in_wr_en),
    .wr_sof(in_sof),
    .wr_eof(in_eof),
    .din(in_din),
    .full(in_full),
    .rd_clk(clock),
    .rd_en(udp_rd_en),
    .rd_sof(udp_in_sof),
    .rd_eof(udp_in_eof),
    .dout(udp_dout),
    .empty(udp_empty)
);

// Logic wires from udp_reader module to output FIFO
logic udp_wr_en;
logic udp_full;
logic [7:0] udp_din;
logic error;
logic checksum_valid;

udp_reader udp_reader_inst (
    .clock(clock),
    .reset(reset),
    .in_rd_en(udp_rd_en),
    .in_empty(udp_empty),
    .in_dout(udp_dout), 
    .in_rd_sof(udp_in_sof),
    .in_rd_eof(udp_in_eof),
    .out_wr_en(udp_wr_en),
    .out_full(udp_full),
    .out_din(udp_din),
    .error(error),
    .checksum_valid(checksum_valid)
);

// Gated signal to reset output FIFO is error is asserted (to clear the FIFO if UDP data is wrong or checksum isn't correct)
logic reset_error;
assign reset_error = reset | error;

// Signal for output FIFO's empty signal to gate with checksum_valid (output FIFO will be empty until checksum_valid is high)
logic output_fifo_empty;
assign out_empty = (checksum_valid) ? output_fifo_empty : 1'b1;

fifo #(
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) output_fifo_buffer (
    .reset(reset_error),
    .wr_clk(clock),
    .wr_en(udp_wr_en),
    .din(udp_din),
    .full(udp_full),
    .rd_clk(clock),
    .rd_en(out_rd_en),
    .dout(out_dout),
    .empty(output_fifo_empty)
);

endmodule