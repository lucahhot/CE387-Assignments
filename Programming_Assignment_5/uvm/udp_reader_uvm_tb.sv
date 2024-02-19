
import uvm_pkg::*;
import udp_reader_uvm_package::*;

`include "udp_reader_uvm_if.sv"

`timescale 1 ns / 1 ns

module udp_reader_uvm_tb;

    udp_reader_uvm_if vif();

    udp_reader_top #(
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
    ) udp_reader_top_inst (
        .clock(vif.clock),
        .reset(vif.reset),
        .in_full(vif.in_full),
        .in_wr_en(vif.in_wr_en),
        .in_sof(vif.in_sof),
        .in_eof(vif.in_eof),
        .in_din(vif.in_din),
        .out_dout(vif.out_dout),
        .out_empty(vif.out_empty),
        .out_rd_en(vif.out_rd_en)
    );

    initial begin
        // store the vif so it can be retrieved by the driver & monitor
        uvm_resource_db#(virtual udp_reader_uvm_if)::set
            (.scope("ifs"), .name("vif"), .val(vif));

        // run the test
        run_test("udp_reader_uvm_test");        
    end

    // reset
    initial begin
        vif.clock <= 1'b1;
        vif.reset <= 1'b0;
        @(posedge vif.clock);
        vif.reset <= 1'b1;
        @(posedge vif.clock);
        vif.reset <= 1'b0;
    end

    // 10ns clock
    always
        #(CLOCK_PERIOD/2) vif.clock = ~vif.clock;
endmodule






