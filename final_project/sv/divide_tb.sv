`timescale 1 ns / 1 ns
`include "globals.sv"

module divide_tb;

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic busy;
logic div_done;

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
    .done(div_done),
    .dividend(dividend),
    .divisor(divisor),
    .d_out(quotient)
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
    #10 wait (div_done == 1'b1)          // wait for division to doneish

    $display ("Dividend: %08x\nDivisor: %08x\n", dividend, divisor);
    $display ("Result: %08x\n", quotient);

    #10;
    dividend = 32'h000076c0;         // 29.6875
    divisor = 32'h00001300;          // 4.75
    #10 start = 1'b1;               // start signal
    #10 wait (div_done == 1'b1)          // wait for division to doneish

    $display ("Dividend: %08x\nDivisor: %08x\n", dividend, divisor);
    $display ("Result: %08x\n", quotient);

    #10;
    dividend = 32'hffff8940;         // -29.6875
    divisor = 32'h00001300;          // 4.75
    #10 start = 1'b1;               // start signal
    #10 wait (div_done == 1'b1)          // wait for division to doneish

    $display ("Dividend: %08x\nDivisor: %08x\n", dividend, divisor);
    $display ("Result: %08x\n", quotient);

    $stop;
end



endmodule