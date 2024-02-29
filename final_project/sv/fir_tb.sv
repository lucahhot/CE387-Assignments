`timescale 1 ns / 1 ns

module fir_tb;

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

localparam QUANTIZATION_BITS = 32;
localparam NUM_TAPS = 32;
localparam FIFO_BUFFER_SIZE = 1024;

logic x_in_full;
logic x_in_wr_en = '0;
logic signed [QUANTIZATION_BITS-1:0] x_in_din = '0;
logic y_out_empty;
logic y_out_rd_en = '0;
logic signed [QUANTIZATION_BITS-1:0] y_out_dout;

logic   hold_clock    = '0;
logic   in_write_done = '0;
logic   out_read_done = '0;
integer out_errors    = '0;

fir_top #(
    .NUM_TAPS(NUM_TAPS),
    .QUANTIZATION_BITS(QUANTIZATION_BITS),
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

initial begin : generate_random_input

    logic signed [QUANTIZATION_BITS-1:0] in;

    @(negedge reset);
    @(negedge clock);
    x_in_wr_en = 1'b0;

    for (int i = -360; i <= 360; i++) begin
 
        @(negedge clock);
        if (x_in_full == 1'b0) begin
            x_in_wr_en = 1'b1;
            x_in_din = i;
        end else
            x_in_wr_en = 1'b0;
    end

    @(negedge clock);
    x_in_wr_en = 1'b0;
    in_write_done = 1'b1;
end

initial begin : data_write_process
    
    logic signed [QUANTIZATION_BITS-1:0] out;
    int i;

    @(negedge reset);
    @(negedge clock);

    y_out_rd_en = 1'b0;

    i = 0;
    while (i < 72) begin
        @(negedge clock);
        y_out_rd_en = 1'b0;
        if (y_out_empty == 1'b0) begin
            y_out_rd_en = 1'b1;
            $display("y_out value = %8.4f", y_out_dout);
            $display("i index = %0d\n", i);
            i++;
        end
    end

    @(negedge clock);
    y_out_rd_en = 1'b0;
    out_read_done = 1'b1;
end

endmodule