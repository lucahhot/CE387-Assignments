`timescale 1 ns / 1 ns
`include "globals.sv" 

module fm_radio_tb;
// THIS IS THE TB USED FOR DEBUGGING, THIS IS NOT THE REAL TOP LEVEL TESTBENCH
localparam string FILE_IN_NAME = "../test/usrp.dat";
// localparam string FILE_IN_NAME = "../fm_radio/src/txt_files/read_iq_i.txt";
localparam string FILE_Q_IN_NAME = "../source/text_files/read_iq_q.txt";
localparam string FILE_LEFT_OUT_NAME = "../source/output_files/fm_radio_left_out.txt";
localparam string FILE_RIGHT_OUT_NAME = "../source/output_files/fm_radio_right_out.txt";
localparam string FILE_LEFT_CMP_NAME = "../source/text_files/gain_left.txt";
localparam string FILE_RIGHT_CMP_NAME = "../source/text_files/gain_right.txt";

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic out_read_done = '0;
logic in_write_done = '0;
integer out_errors = '0;

// CHANGE THIS PARAMETER TO CHANGE NUMBER TEST INPUT DATA IN
localparam NUMBER_OF_INPUTS = 32000;

logic right_audio_empty, left_audio_empty;
logic right_audio_rd_en, left_audio_rd_en;
logic signed [DATA_SIZE-1:0] right_audio_out, left_audio_out;

// fm_radio_test signals
logic in_full;
logic in_wr_en;
logic signed [BYTE_SIZE-1:0] data_in;

fm_radio fm_radio_inst (
    .clock(clock),
    .reset(reset),
    .in_full(in_full),
    .in_wr_en(in_wr_en),
    .data_in(data_in),
    .left_audio_out(left_audio_out),
    .left_audio_empty(left_audio_empty),
    .left_audio_rd_en(left_audio_rd_en),
    .right_audio_out(right_audio_out),
    .right_audio_empty(right_audio_empty),
    .right_audio_rd_en(right_audio_rd_en)
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
    $display("Inputs read in: %0d", NUMBER_OF_INPUTS);
    $display("Outputs out: %0d", NUMBER_OF_INPUTS/32);
    $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

initial begin : read_data_proces

    int in_file;
    int i, j;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, FILE_IN_NAME);
    in_file = $fopen(FILE_IN_NAME, "rb");

    if (!in_file) begin
        $display("@ %0t: FAILED TO LOAD FILE %s...", $time, FILE_IN_NAME);
    end

    in_wr_en = 1'b0;
    @(negedge clock);

    i = 0;
    // Only read the first NUMBER_OF_INPUTS values of data
    while (i < NUMBER_OF_INPUTS) begin
 
        @(negedge clock);
        if (in_full == 1'b0) begin
            in_wr_en = 1'b1;
            j = $fscanf(in_file, "%c", data_in);
            // $display("(%0d) Input value %x",i,x_in_din);
            i++;
        end else
            in_wr_en = 1'b0;
    end

    @(negedge clock);
    in_wr_en = 1'b0;
    $fclose(in_file);
    in_write_done = 1'b1;
end

// initial begin : q_read_process

//     int q_in_file;
//     int i, j;

//     @(negedge reset);
//     $display("@ %0t: Loading file %s...", $time, FILE_Q_IN_NAME);
//     q_in_file = $fopen(FILE_Q_IN_NAME, "rb");

//     if (!q_in_file) begin
//         $display("@ %0t: FAILED TO LOAD FILE %s...", $time, FILE_Q_IN_NAME);
//     end


//     in_wr_en = 1'b0;
//     @(negedge clock);

//     i = 0;
//     // Only read the first 100 values of data
//     while (i < 100) begin
 
//         @(negedge clock);
//         if (q_out_full == 1'b0) begin
//             in_wr_en = 1'b1;
//             j = $fscanf(q_in_file, "%h", q_out_din);
//             // $display("(%0d) Input value %x",i,x_in_din);
//         end else
//             in_wr_en = 1'b0;
//     end

//     @(negedge clock);
//     $display("@ %0t: Finished reading file %s...", $time, FILE_Q_IN_NAME);
//     in_wr_en = 1'b0;
//     $fclose(q_in_file);
//     in_write_done = 1'b1;
// end




initial begin : data_write_process
    
    logic signed [DATA_SIZE-1:0] right_cmp_out, left_cmp_out;
    int i, j, k;
    int right_out_file, left_out_file;
    int right_cmp_file, left_cmp_file;

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing RIGHT_AUDIO %s...", $time, FILE_RIGHT_OUT_NAME);
    $display("@ %0t: Comparing LEFT_AUDIO %s...", $time, FILE_LEFT_OUT_NAME);
    right_out_file = $fopen(FILE_RIGHT_OUT_NAME, "wb");
    left_out_file = $fopen(FILE_LEFT_OUT_NAME, "wb");
    right_cmp_file = $fopen(FILE_RIGHT_CMP_NAME, "rb");
    left_cmp_file = $fopen(FILE_LEFT_CMP_NAME, "rb");
    right_audio_rd_en = 1'b0;
    left_audio_rd_en = 1'b0;

    i = 0;
    while ( i < NUMBER_OF_INPUTS/32 ) begin     // DIVIDE BY 8 FOR DECIMATION
        @(negedge clock);
        right_audio_rd_en = 1'b0;
        left_audio_rd_en = 1'b0;
        if (right_audio_empty == 1'b0 && left_audio_empty == 1'b0) begin
            right_audio_rd_en = 1'b1;
            left_audio_rd_en = 1'b1;
            j = $fscanf(right_cmp_file, "%h", right_cmp_out);
            k = $fscanf(left_cmp_file, "%h", left_cmp_out);
            $fwrite(right_out_file, "%08x\n", right_audio_out);
            $fwrite(left_out_file, "%08x\n", left_audio_out);

            if (right_cmp_out != right_audio_out) begin
                out_errors += 1;
                $write("@ %0t: (%0d): RIGHT AUDIO ERROR: %x != %x.\n", $time, i+1, right_audio_out, right_cmp_out);
            end 

            if (left_cmp_out != left_audio_out) begin
                out_errors += 1;
                $write("@ %0t: (%0d): LEFT AUDIO ERROR: %x != %x.\n", $time, i+1, left_audio_out, left_cmp_out);
            end 
            i++;
        end
    end

    @(negedge clock);
    right_audio_rd_en = 1'b0;
    left_audio_rd_en = 1'b0;

    $display("@ %0t: Closing RIGHT_AUDIO %s...", $time, FILE_RIGHT_OUT_NAME);
    $display("@ %0t: Closing LEFT_AUDIO %s...", $time, FILE_LEFT_OUT_NAME);
    $fclose(right_out_file);
    $fclose(left_out_file);
    $fclose(right_cmp_file);
    $fclose(left_cmp_file);
    out_read_done = 1'b1;
end

// initial begin : left_audio_cmp
    
//     logic signed [DATA_SIZE-1:0] left_cmp_out;
//     int i, j;
//     int left_out_file;
//     int left_cmp_file;

//     @(negedge reset);
//     @(negedge clock);

//     $display("@ %0t: Comparing LEFT %s...", $time, FILE_LEFT_OUT_NAME);
//     left_out_file = $fopen(FILE_LEFT_OUT_NAME, "wb");
//     left_cmp_file = $fopen(FILE_LEFT_CMP_NAME, "rb");
//     left_audio_rd_en = 1'b0;

//     i = 0;
//     while (i < 100/8) begin     // DIVIDE BY 8 FOR DECIMATION
//         @(negedge clock);
//         left_audio_rd_en = 1'b0;
//         if (left_audio_empty == 1'b0) begin
//             left_audio_rd_en = 1'b1;
//             j = $fscanf(left_cmp_file, "%h", left_cmp_out);
//             $fwrite(left_out_file, "%08x\n", left_audio_out);

//             if (left_cmp_out != left_audio_out) begin
//                 out_errors += 1;
//                 $write("@ %0t: (%0d): LEFT AUDIO ERROR: %x != %x.\n", $time, i+1, left_audio_out, left_cmp_out);
//             end 
//             i++;
//         end
//     end

//     @(negedge clock);
//     left_audio_rd_en = 1'b0;
//     $fclose(left_out_file);
//     $fclose(left_cmp_file);
//     out_read_done = 1'b1;
// end
endmodule