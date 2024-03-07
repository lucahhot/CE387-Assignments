`include "globals.sv" 

module demod_top #(
    FIFO_BUFFER_SIZE = 16
) (
    input   logic                   clk,
    input   logic                   reset,
    input   logic [DATA_SIZE-1:0]   real_in,
    input   logic                   real_wr_en,
    output  logic                   real_full,
    input   logic [DATA_SIZE-1:0]   imag_in,
    input   logic                   imag_wr_en,
    output  logic                   imag_full,
    output  logic [DATA_SIZE-1:0]   data_out,
    input   logic                   data_out_rd_en,
    output  logic                   data_out_empty
);

// Wires from FIFOs to demod
logic real_rd_en;
logic real_empty;
logic [DATA_SIZE-1:0] real_dout;

logic imag_rd_en;
logic imag_empty;
logic [DATA_SIZE-1:0] imag_dout;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) real_input_fifo (
    .reset(reset),
    .wr_clk(clk),
    .wr_en(real_wr_en),
    .din(real_in),
    .full(real_full),
    .rd_clk(clk),
    .rd_en(real_rd_en),
    .dout(real_dout),
    .empty(real_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) imag_input_fifo (
    .reset(reset),
    .wr_clk(clk),
    .wr_en(imag_wr_en),
    .din(imag_in),
    .full(imag_full),
    .rd_clk(clk),
    .rd_en(imag_rd_en),
    .dout(imag_dout),
    .empty(imag_empty)
);

// Wires from demod to output FIFO
logic [DATA_SIZE-1:0] demod_out;
logic demod_wr_en;
logic demod_full;

demodulate demod_inst (
    .clk(clk),
    .reset(reset),
    .real_rd_en(real_rd_en),
    .real_empty(real_empty),
    .real_in(real_dout),
    .imag_rd_en(imag_rd_en),
    .imag_empty(imag_empty),
    .imag_in(imag_dout),
    .demod_out(demod_out),
    .wr_en_out(demod_wr_en),
    .out_fifo_full(demod_full)
);

fifo #(
    .FIFO_DATA_WIDTH (DATA_SIZE),
    .FIFO_BUFFER_SIZE (FIFO_BUFFER_SIZE)
) output_fifo (
    .reset(reset),
    .wr_clk(clk),
    .wr_en(demod_wr_en),
    .din(demod_out),
    .full(demod_full),
    .rd_clk(clk),
    .rd_en(data_out_rd_en),
    .dout(data_out),
    .empty(data_out_empty)
);

    
endmodule