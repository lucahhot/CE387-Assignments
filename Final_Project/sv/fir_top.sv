module fir_top #(
    NUM_TAPS = 32,
    QUANTIZATION_BITS = 32,
    FIFO_BUFFER_SIZE = 1024
) (
    input   logic                           clock,
    input   logic                           reset,
    output  logic                           x_in_full,
    input   logic                           x_in_wr_en,
    input   logic [QUANTIZATION_BITS-1:0]   x_in_din,

    output  logic                           y_out_empty,
    input   logic                           y_out_rd_en,
    output  logic [QUANTIZATION_BITS-1:0]   y_out_dout
);

// Test 32-bit paramater values
parameter logic signed [QUANTIZATION_BITS-1:0] [0:NUM_TAPS-1] COEFFICIENTS = '{
    'hfffffffd, 'hfffffffa, 'hfffffff4, 'hffffffed, 'hffffffe5, 'hffffffdf, 'hffffffe2, 'hfffffff3, 
    'h00000015, 'h0000004e, 'h0000009b, 'h000000f9, 'h0000015d, 'h000001be, 'h0000020e, 'h00000243, 
    'h00000243, 'h0000020e, 'h000001be, 'h0000015d, 'h000000f9, 'h0000009b, 'h0000004e, 'h00000015, 
    'hfffffff3, 'hffffffe2, 'hffffffdf, 'hffffffe5, 'hffffffed, 'hfffffff4, 'hfffffffa, 'hfffffffd
};

// Wires from input FIFO to fir module
logic x_in_rd_en;
logic x_in_empty;
logic [QUANTIZATION_BITS-1:0] x_in_dout;

// x_in FIFO
fifo #(
    .FIFO_DATA_WIDTH(QUANTIZATION_BITS),
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

// Wires from fir module to output FIFO
logic y_out_wr_en;
logic y_out_full;
logic [QUANTIZATION_BITS-1:0] y_out_din;

// fir module
fir #(
    .NUM_TAPS(NUM_TAPS),
    .DECIMATION(10),
    .QUANTIZATION_BITS(QUANTIZATION_BITS),
    .COEFFICIENTS(COEFFICIENTS),
    .UNROLL_FACTOR(1)
) fir_inst (
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
    .FIFO_DATA_WIDTH(QUANTIZATION_BITS),
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