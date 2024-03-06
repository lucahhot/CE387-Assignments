`timescale 1 ns / 1 ns
`include "globals.sv" 

module read_iq_tb;

localparam string FILE_IN_NAME = "../fm_radio/test/usrp.dat";
localparam string FILE_LEFT_OUT_NAME = "../fm_radio/src/out_files/fm_radio_left_out.txt";
localparam string FILE_RIGHT_OUT_NAME = "../fm_radio/src/out_files/fm_radio_right_out.txt";
localparam string FILE_LEFT_CMP_NAME = "../fm_radio/src/txt_files/gain_left.txt";
localparam string FILE_RIGHT_CMP_NAME = "../fm_radio/src/txt_files/gain_right.txt";

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
logic [BYTE_SIZE-1:0] in_din;
logic signed [DATA_SIZE-1:0] i_out_dout, q_out_dout;

logic i_out_empty, q_out_empty;
logic i_out_rd_en, q_out_rd_en;

fm_radio #(
    .DATA_SIZE(DATA_SIZE),
    .CHAR_SIZE(CHAR_SIZE),
    .BYTE_SIZE(BYTE_SIZE),
    .BITS(BITS)
) fm_radio_inst (

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
            j = $fscanf(in_file, "%c", in_din);
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
    
    logic signed [DATA_SIZE-1:0] i_cmp_out, q_cmp_out;
    int i, j, k;
    int i_out_file, q_out_file;
    int i_cmp_file, q_cmp_file;

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing I %s...", $time, FILE_I_OUT_NAME);
    $display("@ %0t: Comparing Q %s...", $time, FILE_Q_OUT_NAME);
    i_out_file = $fopen(FILE_I_OUT_NAME, "wb");
    q_out_file = $fopen(FILE_Q_OUT_NAME, "wb");
    i_cmp_file = $fopen(FILE_I_CMP_NAME, "rb");
    q_cmp_file = $fopen(FILE_Q_CMP_NAME, "rb");
    i_out_rd_en = 1'b0;
    q_out_rd_en = 1'b0;

    i = 0;
    while (i < 100/4) begin
        @(negedge clock);
        i_out_rd_en = 1'b0;
        q_out_rd_en = 1'b0;
        if (i_out_empty == 1'b0 && q_out_empty == 1'b0) begin
            i_out_rd_en = 1'b1;
            q_out_rd_en = 1'b1;
            j = $fscanf(i_cmp_file, "%h", i_cmp_out);
            k = $fscanf(q_cmp_file, "%h", q_cmp_out);
            $fwrite(i_out_file, "%08x\n", i_out_dout);
            $fwrite(q_out_file, "%08x\n", q_out_dout);

            if (i_cmp_out != i_out_dout) begin
                out_errors += 1;
                $write("@ %0t: (%0d): ERROR: %x != %x.\n", $time, i+1, i_out_dout, i_cmp_out);
            end

            if (q_cmp_out != q_out_dout) begin
                out_errors += 1;
                $write("@ %0t: (%0d): ERROR: %x != %x.\n", $time, i+1, q_out_dout, q_cmp_out);
            end
            i++;
        end
    end

    @(negedge clock);
    i_out_rd_en = 1'b0;
    q_out_rd_en = 1'b0;
    $fclose(i_out_file);
    $fclose(q_out_file);
    $fclose(i_cmp_file);
    $fclose(q_cmp_file);
    out_read_done = 1'b1;
end

endmodule