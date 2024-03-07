`timescale 1 ns / 1 ns
`include "globals.sv" 

module gain_tb;

localparam string FILE_IN_NAME = "../fm_radio/src/txt_files/iir_left.txt";
localparam string FILE_OUT_NAME = "../fm_radio/src/out_files/gain_left_test.txt";
localparam string FILE_CMP_NAME = "../fm_radio/src/txt_files/gain_left.txt";

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic out_read_done = '0;
logic in_write_done = '0;
integer out_errors = '0;

// read_iq_top signals
logic in_full;
logic in_wr_en;
logic signed [DATA_SIZE-1:0] in_din;
logic signed [DATA_SIZE-1:0] out_dout;

logic out_empty;
logic out_rd_en;

gain_top #(
    .DATA_SIZE(DATA_SIZE),
    .BITS(BITS)
) gain_top (
    .clock(clock),
    .reset(reset),
    .in_full(in_full),
    .in_wr_en(in_wr_en),
    .in_din(in_din),
    .out_dout(out_dout),
    .out_empty(out_empty),
    .out_rd_en(out_rd_en)
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

    in_wr_en = 1'b0;
    @(negedge clock);

    // Only read the first 100 values of data
    for (int i = 0; i < 100; i++) begin
 
        @(negedge clock);
        if (in_full == 1'b0) begin
            in_wr_en = 1'b1;
            j = $fscanf(in_file, "%h", in_din);
            // $display("(%0d) Input value %x",i,x_in_din);
        end else
            in_wr_en = 1'b0;
    end

    @(negedge clock);
    in_wr_en = 1'b0;
    $fclose(in_file);
    in_write_done = 1'b1;
end

initial begin : data_write_process
    
    logic signed [DATA_SIZE-1:0] cmp_out;
    int i, j;
    int out_file, cmp_file;

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing I %s...", $time, FILE_OUT_NAME);
    out_file = $fopen(FILE_OUT_NAME, "wb");
    cmp_file = $fopen(FILE_CMP_NAME, "rb");
    out_rd_en = 1'b0;
    i = 0;
    while (i < 100) begin
        @(negedge clock);
        out_rd_en = 1'b0;
        if (out_empty == 1'b0) begin
            out_rd_en = 1'b1;
            j = $fscanf(cmp_file, "%h", cmp_out);
            $fwrite(out_file, "%08x\n", out_dout);

            if (cmp_out != out_dout) begin
                out_errors += 1;
                $write("@ %0t: (%0d): ERROR: %x != %x.\n", $time, i+1, out_dout, cmp_out);
            end
            i++;
        end
    end

    @(negedge clock);
    out_rd_en = 1'b0;
    $fclose(out_file);
    $fclose(cmp_file);
    out_read_done = 1'b1;
end

endmodule