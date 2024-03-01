`timescale 1 ns / 1 ns

module multiply_tb;

localparam string IN_FILE = "../fm_radio/src/txt_files/bp_pilot_out.txt";
localparam string OUT_FILE = "../sim/multiply_sim_out.txt";

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

localparam DATA_SIZE = 32;
localparam DATA_SIZE_2 = 64;
localparam FIFO_BUFFER_SIZE = 1024;

logic x_in_full;
logic x_in_wr_en = '0;

logic z_out_empty;
logic z_out_rd_en = '0;

logic out_read_done = 1'b0;

logic x_write_done = 1'b0;

logic signed [DATA_SIZE-1:0] x_in_din;
logic signed [DATA_SIZE-1:0] z_out_dout;


multiply_top #(
    .DATA_SIZE(DATA_SIZE),
    .DATA_SIZE_2(DATA_SIZE_2),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) multiply_top_inst (
    .clock(clock),
    .reset(reset),
    .x_in_full(x_in_full),
    .x_in_wr_en(x_in_wr_en),
    .x_in(x_in_din),
    .z_out(z_out_dout),
    .z_out_rd_en(z_out_rd_en),
    .z_out_empty(z_out_empty)
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
    // $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

initial begin : x_write
    logic signed [DATA_SIZE-1:0] in;
    int i = 0;
    int j = 0;
    int fd;
    x_in_wr_en = 1'b0;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, IN_FILE);
    
    fd = $fopen(IN_FILE, "rb");

    while( j < 72 ) begin
        if (x_in_full == 1'b0) begin
            i += $fread(x_in_din, fd, i, 4);
            x_in_wr_en = 1'b1;
            j++;
        end
    end

    @(posedge clock);
    x_in_wr_en = 1'b0;
    $fclose(fd);
    x_write_done = 1'b1;
end

initial begin : data_write_process
    
    logic signed [DATA_SIZE-1:0] out;
    int i;
    int result_fd;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, OUT_FILE);
    
    result_fd = $fopen(OUT_FILE, "w");
    @(negedge clock);

    z_out_rd_en = 1'b0;

    i = 0;
    while (i < 72) begin
        @(negedge clock);
        z_out_rd_en = 1'b0;
        if (z_out_empty == 1'b0) begin
            z_out_rd_en = 1'b1;
            $display("z_out = %04x\n", z_out_dout);
            $fwrite(result_fd, "%04x\n", z_out_dout);
            i++;
        end
    end

    @(negedge clock);
    z_out_rd_en = 1'b0;
    out_read_done = 1'b1;
end

endmodule