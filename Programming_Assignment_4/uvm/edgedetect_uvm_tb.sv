
import uvm_pkg::*;
import edgedetect_uvm_package::*;

`include "edgedetect_uvm_if.sv"

`timescale 1 ns / 1 ns

module edgedetect_uvm_tb;

    edgedetect_uvm_if vif();

    edgedetect_top #(
        .WIDTH(IMG_WIDTH),
        .HEIGHT(IMG_HEIGHT)
    ) edgedetect_inst (
        .clock(vif.clock),
        .reset(vif.reset),
        .image_full(vif.in_full),
        .image_wr_en(vif.in_wr_en),
        .image_din(vif.in_din),
        .img_out_empty(vif.out_empty),
        .img_out_rd_en(vif.out_rd_en),
        .img_out_dout(vif.out_dout)
    );

    initial begin
        // store the vif so it can be retrieved by the driver & monitor
        uvm_resource_db#(virtual edgedetect_uvm_if)::set
            (.scope("ifs"), .name("vif"), .val(vif));

        // run the test
        run_test("edgedetect_uvm_test");        
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






