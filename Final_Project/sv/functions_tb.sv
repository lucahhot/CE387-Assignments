`timescale 1 ns / 1 ns

`include "globals.sv" 

module functions_tb;

localparam string IN_FILE = "../sourcetxt_files/bp_pilot_out.txt";
localparam string OUT_FILE = "../source/multiply_sim_out.txt";

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic   hold_clock    = '0;
logic   in_write_done = '0;
logic   out_read_done = '0;
integer out_errors    = '0;

always begin
    clock = 1'b1;
    #(CLOCK_PERIOD/2);
    clock = 1'b0;
    #(CLOCK_PERIOD/2);
end

initial begin
    @(posedge clock);
    reset = 1'b1;
    @(posedge clock);
    reset = 1'b0;
end

initial begin : tb_process
    longint unsigned start_time, end_time;

    @(negedge reset);
    @(posedge clock);
    start_time = $time;

    // start
    $display("@ %0t: Beginning simulation...", start_time);
    start = 1'b1;
    @(posedge clock);
    start = 1'b0;

    wait(out_read_done);
    end_time = $time;

    // report metrics
    $display("@ %0t: Simulation completed.", end_time);
    $display("Total simulation cycle count: %0d", (end_time-start_time)/CLOCK_PERIOD);
    // $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

initial begin : x_write

    @(negedge reset);
    // $display("@ %0t: Loading file %s...", $time, IN_FILE);
    
    // fd = $fopen(IN_FILE, "rb");

    // Testing the quantize function with example from Lecture 11 slides
    
    @(posedge clock);
    in_write_done = 1'b1;
end

initial begin : data_write_process
    shortreal x, y;
    logic signed [DATA_SIZE-1:0] x_fixed; 
    logic signed [DATA_SIZE-1:0] y_fixed;
    logic signed [DATA_SIZE-1:0] product;
    
    @(negedge reset);
    @(negedge clock);

    
    x = 6.25;
    y= 4.75;

    $display("x = %8.4f", x);
    $display("y = %8.4f", y);

    x_fixed = QUANTIZE_F(x);
    y_fixed = QUANTIZE_F(y);

    $display("x_fixed = %0d", x_fixed);
    $display("y_fixed = %0d", y_fixed);
    // $display("x_fixed = %b", x_fixed);
    // $display("y_fixed = %b", y_fixed);

    // Multiply and print the results
    product = MULTIPLY_FIXED(x_fixed,y_fixed);
    $display("Product (fixed-point) = %0d", product);

    // Print multiply results in floating-point
    $display("Product (fixed-point) = %8.4f", DEQUANTIZE_F(product));

    @(negedge clock);
    out_read_done = 1'b1;
end

endmodule