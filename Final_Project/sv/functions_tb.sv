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
    // shortreal x, y;
    // logic signed [0:7] [DATA_SIZE-1:0]  x_fixed; 
    // logic signed [0:7] [DATA_SIZE-1:0]  y_fixed;
    // logic signed [0:7] [DATA_SIZE-1:0]  product;
    // logic signed [DATA_SIZE-1:0] sum;
    // logic signed [DATA_SIZE-1:0] intmax;
    // logic signed [DATA_SIZE-1:0] intmin;

    // int x_fixed_int [0:7];
    // int y_fixed_int [0:7];
    // logic signed [0:7] [DATA_SIZE-1:0] x_fixed; 
    // logic signed [0:7] [DATA_SIZE-1:0] y_fixed; 
    // logic signed [0:7] [DATA_SIZE-1:0] product;
    // int sum_int;
    // logic signed [DATA_SIZE-1:0] sum;

    shortreal W_PP;
    logic signed [0:1] [DATA_SIZE-1:0] IIR_Y_COEFFS;
    logic signed [0:1] [DATA_SIZE-1:0] IIR_X_COEFFS;
    logic signed [0:2] [DATA_SIZE-1:0] x_in;
    logic signed [DATA_SIZE-1:0] y1;
    logic signed [DATA_SIZE-1:0] y2;
    logic signed [0:2] [DATA_SIZE-1:0] y_shift;

    int x_coeffs [0:1];
    int y_coeffs [0:1];
    
    @(negedge reset);
    @(negedge clock);

    
    // x = 6.25;
    // y= 4.75;

    // $display("x = %8.4f", x);
    // $display("y = %8.4f", y);

    // x_fixed = QUANTIZE_F(x);
    // y_fixed = QUANTIZE_F(y);

    // $display("x_fixed = %0d", x_fixed);
    // $display("y_fixed = %0d", y_fixed);
    // // $display("x_fixed = %b", x_fixed);
    // // $display("y_fixed = %b", y_fixed);

    // // Multiply and print the results
    // product = MULTIPLY_ROUNDING(x_fixed,y_fixed);
    // $display("Product (quantized/fixed-point) = %0d", product);

    // // Print multiply results in floating-point
    // $display("Product (floating-point) = %8.4f", DEQUANTIZE_F(product));

    // Testing multiplication for fir.sv
    // x_fixed_int = '{32'h0000073e,32'h00000900,32'h000007d8,32'hfffffc84,32'hfffffb5a,32'h00000696,32'h000004a6, 32'h000004a6};
    // y_fixed_int = '{32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3};
    // x_fixed = '{32'h0000073e,32'h00000900,32'h000007d8,32'hfffffc84,32'hfffffb5a,32'h00000696,32'h000004a6, 32'h000004a6};
    // y_fixed = '{32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3};
    // sum = 0;
    // sum_int = 0;

    // for (int i = 0; i < 8; i++) begin
    //     product[i] = MULTIPLY_ROUNDING(x_fixed[i],y_fixed[i]);
    //     // $display("Product (fixed-point) = %b", product[i]);
    //     // $display("Product (fixed-point) = %d", product[i]);
    //     $display("Product (fixed-point) = %x", product[i]);
    //     $display("Real product (fixed-point) = %x", $signed(x_fixed_int[i] * y_fixed_int[i]) / 1024);
    //     sum += (product[i]);
    //     sum_int += $signed(x_fixed_int[i] * y_fixed_int[i]) / 1024;
    // end

    // $display("Sum (fixed-point) = %x",sum);
    // $display("Real sum (fixed-point) = %x",sum_int);

    // QUANTIZED:
    // # Product (fixed-point) = ffffea46
    // # Product (fixed-point) = ffffca00
    // # Product (fixed-point) = ffffa1e0
    // # Product (fixed-point) = 00004234
    // # Product (fixed-point) = 00007d82
    // # Product (fixed-point) = ffff26aa
    // # Product (fixed-point) = ffff748c
    // # Product (fixed-point) = ffffc392

    // DEQUANTIZED:
    // # Product (fixed-point) = fffffffb
    // # Product (fixed-point) = fffffff3
    // # Product (fixed-point) = ffffffe9
    // # Product (fixed-point) = 00000010
    // # Product (fixed-point) = 0000001f
    // # Product (fixed-point) = ffffffca
    // # Product (fixed-point) = ffffffde
    // # Product (fixed-point) = fffffff1

    y1 = '0;
    y2 = '0;
    x_in = '0;
    y_shift = '0;
    x_in[0] = 32'hffffff9f;
    y1 += ($signed(IIR_X_COEFFS[0]) * $signed(x_in[0])) / 1024;

    $display("y1 after 1st cycle = %x", y1); // ffffffef should be fffffff0

    x_in = {32'h0000070b,32'hfffffff9f};
    y_shift = {y1,y1};

    y1 = $signed(($signed(IIR_X_COEFFS[0]) * $signed(x_in[0])) / 1024) + $signed(($signed(IIR_X_COEFFS[1]) * $signed(x_in[1])) / 1024);
    y2 = $signed(($signed(IIR_Y_COEFFS[0]) * $signed(y_shift[0])) / 1024) + $signed(($signed(IIR_Y_COEFFS[1]) * $signed(y_shift[1])) / 1024);

    $display("y1 after 2nd cycle = %x",y1); 
    $display("y2 after 2nd cycle = %x",y2); 

    y_shift[0] = $signed(y1) + $signed(y2);

    $display("y_shift[1] after 2nd cycle = %x", y_shift[1]);
    $display("y_shift[0] after 2nd cycle = %x", y_shift[0]);

    // 0000070b
    // 0000131b

    @(negedge clock);
    out_read_done = 1'b1;
end

endmodule