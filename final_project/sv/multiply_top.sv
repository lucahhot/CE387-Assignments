module multiply_top #(
    parameter DATA_SIZE,
    parameter DATA_SIZE_2,
    parameter FIFO_BUFFER_SIZE
) (
    input   logic                   clock,
    input   logic                   reset,
    output  logic                   x_in_full,
    input   logic                   x_in_wr_en,
    input   logic [DATA_SIZE - 1:0] x_in,

    output  logic [DATA_SIZE - 1:0] z_out,
    input   logic                   z_out_rd_en,
    output  logic                   z_out_empty
);

// Wires from input fifo to multiply module
logic x_in_rd_en, y_in_rd_en;
logic x_in_empty;
logic [DATA_SIZE-1:0] x_in_dout;

// Wires from MULTIPLY to OUT_FIFO
logic mult_out_wr_en;
logic [DATA_SIZE-1:0] mult_out;

// Wires from OUT_FIFO to Mul
logic fifo_out_full;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_x_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(x_in_wr_en),
    .din(x_in),
    .full(x_in_full),
    .rd_clk(clock),
    .rd_en(x_in_rd_en),
    .dout(x_in_dout),
    .empty(x_in_empty)
);

multiply #(
    .DATA_SIZE(DATA_SIZE),
    .DATA_SIZE_2(DATA_SIZE_2)
) multiply_inst (
    .clock(clock),
    .reset(reset),
    .x_in_rd_en(x_in_rd_en),
    .y_in_rd_en(y_in_rd_en),
    .x_in_empty(x_in_empty),
    .y_in_empty(x_in_empty),
    .out_wr_en(mult_out_wr_en),
    .out_full(fifo_out_full),
    .x(x_in_dout),
    .y(x_in_dout),
    .dout(mult_out)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fifo_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(mult_out_wr_en),
    .din(mult_out),
    .full(fifo_out_full),
    .rd_clk(clock),
    .rd_en(z_out_rd_en),
    .dout(z_out),
    .empty(z_out_empty)
);

endmodule