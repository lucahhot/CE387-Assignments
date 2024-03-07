`timescale 1 ns / 1 ns
`include "globals.sv" 

module fm_radio_tb;
// THIS IS THE TB USED FOR DEBUGGING, THIS IS NOT THE REAL TOP LEVEL TESTBENCH
// localparam string FILE_IN_NAME = "../fm_radio/test/usrp.dat";
localparam string FILE_MULT_DEMOD_IN_NAME = "../fm_radio/src/txt_files/hp_pilot_mult_out.txt";
localparam string FILE_DEMOD_IN_NAME = "../fm_radio/src/txt_files/demodulate_out.txt";
localparam string FILE_LEFT_OUT_NAME = "../fm_radio/src/out_files/lmr_fir_out.txt";
localparam string FILE_RIGHT_OUT_NAME = "../fm_radio/src/out_files/lpr_fir_out.txt";
localparam string FILE_LEFT_CMP_NAME = "../fm_radio/src/txt_files/audio_lmr_out.txt";
localparam string FILE_RIGHT_CMP_NAME = "../fm_radio/src/txt_files/audio_lpr_out.txt";

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic out_read_done = '0;
logic in_write_done = '0;
integer out_errors = '0;


logic right_audio_empty, left_audio_empty;
logic right_audio_rd_en, left_audio_rd_en;
logic signed [DATA_SIZE-1:0] right_audio_out, left_audio_out;

// fm_radio_test signals
logic mult_demod_lmr_full, demod_out_full;
logic mult_demod_lmr_wr_en, demod_out_wr_en;
logic [DATA_SIZE-1:0] mult_demod_lmr_out_din, demod_out_din;

fm_radio_test #(
    .DATA_SIZE(DATA_SIZE),
    .CHAR_SIZE(CHAR_SIZE),
    .BYTE_SIZE(BYTE_SIZE),
    .BITS(BITS),
    .GAIN(GAIN),
    .CHANNEL_COEFF_TAPS(CHANNEL_COEFF_TAPS),
    .CHANNEL_COEFFICIENTS_REAL(CHANNEL_COEFFICIENTS_REAL),
    .CHANNEL_COEFFICIENTS_IMAG(CHANNEL_COEFFICIENTS_IMAG),
    .AUDIO_LPR_COEFF_TAPS(AUDIO_LPR_COEFF_TAPS),
    .AUDIO_LPR_COEFFS(AUDIO_LPR_COEFFS),
    .AUDIO_LMR_COEFF_TAPS(AUDIO_LMR_COEFF_TAPS),
    .AUDIO_LMR_COEFFS(AUDIO_LMR_COEFFS),
    .BP_LMR_COEFF_TAPS(BP_LMR_COEFF_TAPS),
    .BP_LMR_COEFFS(BP_LMR_COEFFS),
    .BP_PILOT_COEFF_TAPS(BP_PILOT_COEFF_TAPS),
    .BP_PILOT_COEFFS(BP_PILOT_COEFFS),
    .HP_COEFF_TAPS(HP_COEFF_TAPS),
    .HP_COEFFS(HP_COEFFS),
    .IIR_COEFF_TAPS(IIR_COEFF_TAPS),
    .IIR_X_COEFFS(IIR_X_COEFFS),
    .IIR_Y_COEFFS(IIR_Y_COEFFS),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .AUDIO_DECIMATION(AUDIO_DECIMATION)
) fm_radio_inst (
    .clock(clock),
    .reset(reset),
    .mult_demod_lmr_full(mult_demod_lmr_full),
    .mult_demod_lmr_wr_en(mult_demod_lmr_wr_en),
    .mult_demod_lmr_out_din(mult_demod_lmr_out_din),
    .demod_out_full(demod_out_full),
    .demod_out_wr_en(demod_out_wr_en),
    .demod_out_din(demod_out_din),
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
    $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

initial begin : mult_demod_read_process

    int mult_demod_in_file;
    int i, j;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, FILE_MULT_DEMOD_IN_NAME);
    mult_demod_in_file = $fopen(FILE_MULT_DEMOD_IN_NAME, "rb");

    mult_demod_lmr_wr_en = 1'b0;
    @(negedge clock);

    // Only read the first 100 values of data
    for (int i = 0; i < 100; i++) begin
 
        @(negedge clock);
        if (mult_demod_lmr_full == 1'b0) begin
            mult_demod_lmr_wr_en = 1'b1;
            j = $fscanf(mult_demod_in_file, "%h", mult_demod_lmr_out_din);
            // $display("(%0d) Input value %x",i,x_in_din);
        end else
            mult_demod_lmr_wr_en = 1'b0;
    end

    @(negedge clock);
    mult_demod_lmr_wr_en = 1'b0;
    $fclose(mult_demod_in_file);
    in_write_done = 1'b1;
end

initial begin : demod_read_process

    int demod_in_file;
    int i, j;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, FILE_DEMOD_IN_NAME);
    demod_in_file = $fopen(FILE_DEMOD_IN_NAME, "rb");


    demod_out_wr_en = 1'b0;
    @(negedge clock);

    // Only read the first 100 values of data
    for (int i = 0; i < 100; i++) begin
 
        @(negedge clock);
        if (demod_out_full == 1'b0) begin
            demod_out_wr_en = 1'b1;
            j = $fscanf(demod_in_file, "%h", demod_out_din);

            // $display("(%0d) Input value %x",i,x_in_din);
        end else
            demod_out_wr_en = 1'b0;
    end

    @(negedge clock);
    demod_out_wr_en = 1'b0;
    $fclose(demod_in_file);
    in_write_done = 1'b1;
end




initial begin : data_write_process
    
    logic signed [DATA_SIZE-1:0] right_cmp_out, left_cmp_out;
    int i, j, k;
    int right_out_file, left_out_file;
    int right_cmp_file, left_cmp_file;

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing I %s...", $time, FILE_RIGHT_OUT_NAME);
    $display("@ %0t: Comparing Q %s...", $time, FILE_LEFT_OUT_NAME);
    right_out_file = $fopen(FILE_RIGHT_OUT_NAME, "wb");
    left_out_file = $fopen(FILE_LEFT_OUT_NAME, "wb");
    right_cmp_file = $fopen(FILE_RIGHT_CMP_NAME, "rb");
    left_cmp_file = $fopen(FILE_LEFT_CMP_NAME, "rb");
    right_audio_rd_en = 1'b0;
    left_audio_rd_en = 1'b0;

    i = 0;
    while (i < 100) begin
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
    $fclose(right_out_file);
    $fclose(left_out_file);
    $fclose(right_cmp_file);
    $fclose(left_cmp_file);
    out_read_done = 1'b1;
end

endmodule