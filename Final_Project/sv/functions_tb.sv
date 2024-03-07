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

logic start_div = '0;
logic signed [DATA_SIZE-1:0] dividend;
logic signed [DATA_SIZE-1:0] divisor;
logic signed [DATA_SIZE-1:0] div_quotient_out;
logic signed [DATA_SIZE-1:0] div_remainder_out;
logic div_overflow_out;
logic div_valid_out;

div #(
    .DIVIDEND_WIDTH(DATA_SIZE),
    .DIVISOR_WIDTH(DATA_SIZE)
) divider_inst (
    .clk(clock),
    .reset(reset),
    .valid_in(start_div),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(div_quotient_out),
    .remainder(div_remainder_out),
    .overflow(div_overflow_out),
    .valid_out(div_valid_out)
);

////////////////////////////////////////////////////////
// The following functions are NOT synthesizable      //
////////////////////////////////////////////////////////
  
// QUANTIZE_F function
function int QUANTIZE_F(shortreal i);
    QUANTIZE_F = int'(shortreal'(i) * shortreal'(QUANT_VAL));
endfunction

// DEQUANTIZE_F function
function shortreal DEQUANTIZE_F(int i);
    DEQUANTIZE_F = shortreal'(shortreal'(i) / shortreal'(QUANT_VAL));
endfunction

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
    
    @(negedge reset);
    @(negedge clock);

    start_div = 1'b1;
    dividend = -9170000;
    divisor = 10;
    wait(div_valid_out);

    $display("Dividend = %0d", dividend);
    $display("Divisor = %0d", divisor);

    $display("Quotient = %0d", div_quotient_out);
    $display("Remainder = %0d", div_remainder_out);
    $display("Overflow = %b", div_overflow_out);

    @(negedge clock);
    out_read_done = 1'b1;
end

endmodule