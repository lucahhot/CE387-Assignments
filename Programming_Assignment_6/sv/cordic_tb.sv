`timescale 1 ns / 1 ns

module cordic_tb;

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

localparam CORDIC_DATA_WIDTH = 16;
localparam BITS = 14;
localparam QUANT_VAL = (1 << BITS);
localparam M_PI = 3.14159265358979323846;
localparam string FILE_OUT_NAME = "../source/test_output.txt";
localparam string SIN_OUT_NAME = "../source/sin_output.txt";
localparam string COS_OUT_NAME = "../source/cos_output.txt";

// QUANTIZE_F function
function int QUANTIZE_F(shortreal i);
    QUANTIZE_F = int'(shortreal'(i) * shortreal'(QUANT_VAL));
endfunction

// DEQUANTIZE_F function
function shortreal DEQUANTIZE_F(int i);
    DEQUANTIZE_F = shortreal'(shortreal'(i) / shortreal'(QUANT_VAL));
endfunction

localparam K = 1.646760258121066;
localparam logic signed [31:0] CORDIC_1K = QUANTIZE_F(1/K);
localparam logic signed [31:0] PI = QUANTIZE_F(M_PI);
localparam logic signed [31:0] HALF_PI = QUANTIZE_F(M_PI/2);
localparam logic signed [31:0] TWO_PI = QUANTIZE_F(M_PI*2);

logic                           radians_full;
logic                           radians_wr_en = '0;
logic signed [2*CORDIC_DATA_WIDTH-1:0] radians_din = '0;
logic                           sin_empty;
logic                           sin_rd_en = '0;
logic signed [CORDIC_DATA_WIDTH-1:0]   sin_dout;
logic                           cos_empty;
logic                           cos_rd_en = '0;
logic signed [CORDIC_DATA_WIDTH-1:0]   cos_dout;

logic   hold_clock    = '0;
logic   in_write_done = '0;
logic   out_read_done = '0;
integer out_errors    = '0;

cordic_top #(
    .CORDIC_DATA_WIDTH(CORDIC_DATA_WIDTH)
) cordic_top_inst (
    .clock(clock),
    .reset(reset),
    .radians_full(radians_full),
    .radians_wr_en(radians_wr_en),
    .radians_din(radians_din),
    .sin_empty(sin_empty),
    .sin_rd_en(sin_rd_en),
    .sin_dout(sin_dout),
    .cos_empty(cos_empty),
    .cos_rd_en(cos_rd_en),
    .cos_dout(cos_dout)
);

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
    $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

initial begin : generate_angles
    shortreal p;
    logic signed [2*CORDIC_DATA_WIDTH-1:0] p_fixed;

    // $display("CORDIC_1K = %0h\nPI = %0h\nHALF_PI = %0h\nTWO_PI = %0h\n", CORDIC_1K,PI,HALF_PI,TWO_PI);

    @(negedge reset);
    @(negedge clock);
    radians_wr_en = 1'b0;

    for (int i = -360; i <= 360; i++) begin
        p = i * M_PI / 180;
        p_fixed = QUANTIZE_F(p);
        // $display("radians: %f quantized value: %0d",p,p_fixed);        
        @(negedge clock);
        if (radians_full == 1'b0) begin
            radians_wr_en = 1'b1;
            radians_din = p_fixed;
        end else
            radians_wr_en = 1'b0;
    end

    @(negedge clock);
    radians_wr_en = 1'b0;
    in_write_done = 1'b1;
end


initial begin : data_write_process
    int i;
    int out_file1, out_file2, out_file3;
    logic signed [2*CORDIC_DATA_WIDTH-1:0] sin_32, cos_32;
    shortreal p;
    real sum_sin_diff, sum_cos_diff, sin_diff, cos_diff;

    @(negedge reset);
    @(negedge clock);

    sin_rd_en = 1'b0;
    cos_rd_en = 1'b0;

    out_file1 = $fopen(FILE_OUT_NAME, "wb");
    out_file2 = $fopen(SIN_OUT_NAME, "wb");
    out_file3 = $fopen(COS_OUT_NAME, "wb");


    sum_sin_diff = 0;
    sum_cos_diff = 0;
    i = (-360-16); 
    while (i <= 360) begin
        @(negedge clock);
        sin_rd_en = 1'b0;
        cos_rd_en = 1'b0;
        if (sin_empty == 1'b0 && cos_empty == 1'b0) begin
            // Don't read cordic FIFO output for the first 16 cycles
            if (i >= -360) begin 
                sin_rd_en = 1'b1;
                cos_rd_en = 1'b1;
                sin_32 = 32'(sin_dout);
                cos_32 = 32'(cos_dout);
                p = i * M_PI / 180;
                $fwrite(out_file1, "Angle: %0d Cordic sin: %8.4f Real sin: %8.4f Difference: %8.4f   Cordic cos: %8.4f Real cos: %8.4f Difference: %8.4f\n", i, DEQUANTIZE_F(sin_32), $sin(p), DEQUANTIZE_F(sin_32) - $sin(p), DEQUANTIZE_F(cos_32), $cos(p), DEQUANTIZE_F(cos_32) - $cos(p));
                
                $fwrite(out_file2, "%8.4f\n",  DEQUANTIZE_F(sin_32));
                $fwrite(out_file3, "%8.5f\n",  DEQUANTIZE_F(cos_32));

                sin_diff = DEQUANTIZE_F(sin_32) - $sin(p);
                cos_diff = DEQUANTIZE_F(cos_32) - $cos(p);

                if (sin_diff < 0)
                    sum_sin_diff += -sin_diff;
                else
                    sum_sin_diff += sin_diff;

                if (cos_diff < 0)
                    sum_cos_diff += -cos_diff;
                else
                    sum_cos_diff += cos_diff;
                
            end
            i++;
        end
    end

    $display("Total sum of sin error = %8.16f\n", sum_sin_diff);
    $display("Total sum of cos error = %8.16f\n", sum_cos_diff);

    @(negedge clock);
    sin_rd_en = 1'b0;
    cos_rd_en = 1'b0;
    $fclose(out_file1);
    $fclose(out_file2);
    $fclose(out_file3);
    out_read_done = 1'b1;
end

endmodule
