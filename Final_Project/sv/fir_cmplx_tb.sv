`timescale 1 ns / 1 ns
`include "globals.sv" 

module fir_cmplx_tb;

localparam string FILE_IN_REAL_NAME = "../source/text_files/read_iq_i.txt";
localparam string FILE_IN_IMAG_NAME = "../source/text_files/read_iq_q.txt";
localparam string FILE_OUT_REAL_NAME = "../source/output_files/fir_cmplx_real_sim_out.txt";
localparam string FILE_OUT_IMAG_NAME = "../source/output_files/fir_cmplx_imag_sim_out.txt";
localparam string FILE_CMP_REAL_NAME = "../source/text_files/fir_cmplx_real_out.txt";
localparam string FILE_CMP_IMAG_NAME = "../source/text_files/fir_cmplx_imag_out.txt";

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

localparam NUM_TAPS = 20;
localparam FIFO_BUFFER_SIZE = 1024;
localparam DECIMATION = 1;
localparam UNROLL_FACTOR = 1;

parameter logic signed [DATA_SIZE-1:0] [0:NUM_TAPS-1] CHANNEL_COEFFS_REAL = '{
	32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
	32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
	32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001
};

parameter logic signed [DATA_SIZE-1:0] [0:NUM_TAPS-1] CHANNEL_COEFFS_IMAG = '{
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000
};

logic [DATA_SIZE-1:0] xreal_in_dout,   
logic xreal_in_empty,
logic xreal_in_rd_en,
logic [DATA_SIZE-1:0] ximag_in_dout,
logic ximag_in_empty,
logic ximag_in_rd_en,
logic yreal_out_wr_en,
logic yreal_out_full,
logic [DATA_SIZE-1:0] yreal_out_din,  
logic yimag_out_wr_en,
logic yimag_out_full,
logic [DATA_SIZE-1:0] yimag_out_din

logic   hold_clock    = '0;
logic   in_write_done = '0;
logic   out_read_done = '0;
integer out_errors    = '0;

fir_top #(
    .NUM_TAPS(NUM_TAPS),
    .DECIMATION(DECIMATION),
    .COEFFICIENTS(AUDIO_LPR_COEFFS),
    .UNROLL_FACTOR(UNROLL_FACTOR),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) fir_top_inst (
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

    // Only read the first 100 values of data
    for (int i = 0; i < 100; i++) begin
 
        @(negedge clock);
        if (x_in_full == 1'b0) begin
            x_in_wr_en = 1'b1;
            j = $fscanf(in_file, "%h", x_in_din);
            // $display("(%0d) Input value %x",i,x_in_din);
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
    while (i < 100/DECIMATION) begin
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