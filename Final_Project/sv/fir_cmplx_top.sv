`include "globals.sv" 

module fir_cmplx_top #(
    parameter NUM_TAPS = 20,
    parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0] COEFFICIENTS_REAL = '{
	32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
	32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
	32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001},
    parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0]  COEFFICIENTS_IMAG = '{
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000},
    parameter FIFO_BUFFER_SIZE = 1024
) (
    input   logic                   clock,
    input   logic                   reset,
    output  logic                   xreal_in_full,
    input   logic                   xreal_in_wr_en,
    input   logic [DATA_SIZE-1:0]   xreal_in_din,
    output  logic                   ximag_in_full,
    input   logic                   ximag_in_wr_en,
    input   logic [DATA_SIZE-1:0]   ximag_in_din,

    output  logic                   yreal_out_empty,
    input   logic                   yreal_out_rd_en,
    output  logic [DATA_SIZE-1:0]   yreal_out_dout,
    output  logic                   yimag_out_empty,
    input   logic                   yimag_out_rd_en,
    output  logic [DATA_SIZE-1:0]   yimag_out_dout
);

// Wires from input FIFOs to fir_cmplx module
logic xreal_in_rd_en;
logic xreal_in_empty;
logic [DATA_SIZE-1:0] xreal_in_dout;
logic ximag_in_rd_en;
logic ximag_in_empty;
logic [DATA_SIZE-1:0] ximag_in_dout;

// xreal_in FIFO
fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_xreal_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(xreal_in_wr_en),
    .din(xreal_in_din),
    .full(xreal_in_full),
    .rd_clk(clock),
    .rd_en(xreal_in_rd_en),
    .dout(xreal_in_dout),
    .empty(xreal_in_empty)
);

// ximag_in FIFO
fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_ximag_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(ximag_in_wr_en),
    .din(ximag_in_din),
    .full(ximag_in_full),
    .rd_clk(clock),
    .rd_en(ximag_in_rd_en),
    .dout(ximag_in_dout),
    .empty(ximag_in_empty)
);

// Wires from fir_cmplx module to output FIFOs
logic yreal_out_wr_en;
logic yreal_out_full;
logic [DATA_SIZE-1:0] yreal_out_din;
logic yimag_out_wr_en;
logic yimag_out_full;
logic [DATA_SIZE-1:0] yimag_out_din;

// fir module
fir_cmplx #(
    .NUM_TAPS(NUM_TAPS),
    .COEFFICIENTS_REAL(COEFFICIENTS_REAL),
    .COEFFICIENTS_IMAG(COEFFICIENTS_IMAG)
) fir_cmplx_inst (
    .clock(clock),
    .reset(reset),
    .xreal_in_dout(xreal_in_dout),
    .xreal_in_empty(xreal_in_empty),
    .xreal_in_rd_en(xreal_in_rd_en),
    .ximag_in_dout(ximag_in_dout),
    .ximag_in_empty(ximag_in_empty),
    .ximag_in_rd_en(ximag_in_rd_en),
    .yreal_out_wr_en(yreal_out_wr_en),
    .yreal_out_full(yreal_out_full),
    .yreal_out_din(yreal_out_din),
    .yimag_out_wr_en(yimag_out_wr_en),
    .yimag_out_full(yimag_out_full),
    .yimag_out_din(yimag_out_din)
);

// yreal_out FIFO
fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_yreal_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(yreal_out_wr_en),
    .din(yreal_out_din),
    .full(yreal_out_full),
    .rd_clk(clock),
    .rd_en(yreal_out_rd_en),
    .dout(yreal_out_dout),
    .empty(yreal_out_empty)
);

// yimag_out FIFO
fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_yimag_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(yimag_out_wr_en),
    .din(yimag_out_din),
    .full(yimag_out_full),
    .rd_clk(clock),
    .rd_en(yimag_out_rd_en),
    .dout(yimag_out_dout),
    .empty(yimag_out_empty)
);

endmodule