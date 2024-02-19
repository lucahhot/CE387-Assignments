`timescale 1 ns / 1 ns

module udp_reader_tb;

localparam string FILE_IN_NAME = "../source/test.pcap";
localparam string FILE_OUT_NAME = "../source/test_output.txt";
localparam string FILE_CMP_NAME = "../source/test.txt";
localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic        in_full;
logic        in_wr_en  = '0;
logic [7:0]  in_din    = '0;
logic        in_sof;
logic        in_eof;
logic        out_rd_en;
logic        out_empty;
logic  [7:0] out_dout;

logic   hold_clock    = '0;
logic   in_write_done = '0;
logic   out_read_done = '0;
integer out_errors    = '0;

localparam PCAP_FILE_HEADER_BYTES = 24;
localparam PCAP_PACKET_HEADER_BYTES = 16;
localparam FIFO_DATA_WIDTH = 8;
localparam FIFO_BUFFER_SIZE = 1024;
localparam UDP_DATA_BYTES = (FIFO_BUFFER_SIZE*3 + 907); // Total amount of data bytes across all 4 data packets

udp_reader_top #(
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
) udp_reader_top_inst (
    .clock(clock),
    .reset(reset),
    .in_full(in_full),
    .in_wr_en(in_wr_en),
    .in_sof(in_sof),
    .in_eof(in_eof),
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

initial begin : pcap_read_process
    int i, j;
    int packet_size;
    int in_file;
    logic [0:PCAP_FILE_HEADER_BYTES-1] [7:0] file_header;
    logic [0:PCAP_PACKET_HEADER_BYTES-1] [7:0] packet_header;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, FILE_IN_NAME);

    in_file = $fopen(FILE_IN_NAME, "rb");
    in_wr_en = 1'b0;
    in_sof = 1'b0;
    in_eof = 1'b0;

    // Skip PCAP Global header
    i = $fread(file_header, in_file, 0, PCAP_FILE_HEADER_BYTES);

    // Read data from pcap file
    while ( !$feof(in_file) ) begin
        packet_header = {(PCAP_PACKET_HEADER_BYTES){8'h00}};
        i += $fread(packet_header, in_file, i, PCAP_PACKET_HEADER_BYTES);
        packet_size = {<<8{packet_header[8:11]}};
        $display("Packet size: %d", packet_size);

        j = 0;
        while (j < packet_size) begin
            @(negedge clock);
            if (in_full == 1'b0) begin
                i += $fread(in_din, in_file, i , 1);
                in_wr_en = 1'b1;
                in_sof = j == 0 ? 1'b1 : 1'b0;
                in_eof = j == packet_size - 1 ? 1'b1 : 1'b0;
                j++;
            end else begin
                in_wr_en = 1'b0;
                in_sof = 1'b0;
                in_eof = 1'b0;
            end
        end
    end

    @(negedge clock);
    in_wr_en = 1'b0;
    in_sof = 1'b0;
    in_eof = 1'b0;
    $fclose(in_file);
    in_write_done = 1'b1;
end


initial begin : data_write_process
    int i, r;
    int out_file;
    int cmp_file;
    logic [7:0] cmp_dout;

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing file %s...", $time, FILE_OUT_NAME);
    
    out_file = $fopen(FILE_OUT_NAME, "wb");
    cmp_file = $fopen(FILE_CMP_NAME, "rb");
    out_rd_en = 1'b0;

    i = 0;
    while (i < UDP_DATA_BYTES) begin
        @(negedge clock);
        out_rd_en = 1'b0;
        if (out_empty == 1'b0) begin
            r = $fread(cmp_dout, cmp_file, i, 1);
            $fwrite(out_file, "%c", out_dout);

            if (cmp_dout != out_dout) begin
                out_errors += 1;
                $write("@ %0t: %s(%0d): ERROR: %x != %x at address 0x%x.\n", $time, FILE_OUT_NAME, i+1, out_dout, cmp_dout, i);
            end
            out_rd_en = 1'b1;
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
