`timescale 1 ns / 1 ns
`include "globlas.sv"

module divide_tb;

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic busy;
logic fin;

logic [DATA_SIZE-1:0] dividend, divisor, quotient;

divide #(
    .DATA_SIZE(DATA_SIZE),
    .DATA_SIZE_2(DATA_SIZE_2),
    .BITS(BITS)
) divide_inst (
    .clock(clock),
    .reset(reset),
    .start(start),
    .busy(busy),
    .fin(fin),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient)
);

always begin
    clock = 1'b1;
    #(CLOCK_PERIOD/2);
    clock = 1'b0;
    #(CLOCK_PERIOD/2);
end

initial begin
    #0 reset = 0;
    #10 reset = 1;
    #10 reset = 0;

    #10;
    dividend = 32'd4 << 10;         // 4 in fixed point
    divisor = 32'd2 << 10;          // 2 in fixed point
    #10 start = 1'b1;               // start signal
    #10 wait (fin == 1'b1)          // wait for division to finish

    $display ("Dividend: %08x\n Divisor: %08x\n", dividend, divisor);
    $display ("Result: %08x\n", quoteint);

    $stop;
end



endmodule