`timescale 1 ns / 1 ns
`include "globals.sv" 

module iir_tb;

localparam string FILE_IN_NAME = "../source/text_files/add_out.txt";
localparam string FILE_OUT_NAME = "../source/output_files/iir_sim_out.txt";
localparam string FILE_CMP_NAME = "../source/text_files/iir_left.txt";

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

localparam NUM_TAPS = 2;
localparam FIFO_BUFFER_SIZE = 16;

parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0] IIR_Y_COEFFS = '{32'h00000000, 32'hfffffd66};
parameter logic signed [0:NUM_TAPS-1] [DATA_SIZE-1:0] IIR_X_COEFFS = '{32'h000000b2, 32'h000000b2};

logic x_in_full;
logic x_in_wr_en = '0;
logic signed [DATA_SIZE-1:0] x_in_din = '0;
logic y_out_empty;
logic y_out_rd_en = '0;
logic signed [DATA_SIZE-1:0] y_out_dout;

logic   hold_clock    = '0;
logic   in_write_done = '0;
logic   out_read_done = '0;
integer out_errors    = '0;

iir_top #(
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) iir_top_inst (
    .clock(clock),
    .reset(reset),
    .x_in_full(x_in_full),
    .x_in_wr_en(x_in_wr_en),
    .x_in_din(x_in_din),
    .y_out_empty(y_out_empty),
    .y_out_rd_en(y_out_rd_en),
    .y_out_dout(y_out_dout)
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

initial begin : data_read_process

    int in_file;
    int i, j;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, FILE_IN_NAME);
    in_file = $fopen(FILE_IN_NAME, "rb");

    x_in_wr_en = 1'b0;
    @(negedge clock);

    i = 0;
    // Only read the first 200 values of data
    while (i < 200) begin
 
        @(negedge clock);
        if (x_in_full == 1'b0) begin
            x_in_wr_en = 1'b1;
            j = $fscanf(in_file, "%h", x_in_din);
            // $display("(%0d) Input value %x",i,x_in_din);
            i++;
        end else
            x_in_wr_en = 1'b0;
    end

    @(negedge clock);
    x_in_wr_en = 1'b0;
    $fclose(in_file);
    in_write_done = 1'b1;
end

initial begin : data_write_process
    
    logic signed [DATA_SIZE-1:0] cmp_out;
    int i, j;
    int out_file;
    int cmp_file;

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing file %s...", $time, FILE_OUT_NAME);
    out_file = $fopen(FILE_OUT_NAME, "wb");
    cmp_file = $fopen(FILE_CMP_NAME, "rb");
    y_out_rd_en = 1'b0;

    i = 0;
    while (i < 200) begin
        @(negedge clock);
        y_out_rd_en = 1'b0;
        if (y_out_empty == 1'b0) begin
            y_out_rd_en = 1'b1;
            j = $fscanf(cmp_file, "%h", cmp_out);
            $fwrite(out_file, "%08x\n", y_out_dout);
            if (cmp_out != y_out_dout) begin
                out_errors += 1;
                $write("@ %0t: (%0d): ERROR: %x != %x.\n", $time, i+1, y_out_dout, cmp_out);
            end 
            else begin
                $write("@ %0t: (%0d): CORRECT: %x == %x.\n", $time, i+1, y_out_dout, cmp_out);
            end
            i++;
        end
    end

    @(negedge clock);
    y_out_rd_en = 1'b0;
    $fclose(out_file);
    $fclose(cmp_file);
    out_read_done = 1'b1;
end

endmodule