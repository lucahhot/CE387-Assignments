
import uvm_pkg::*;
import cordic_uvm_package::*;

`include "cordic_uvm_if.sv"

`timescale 1 ns / 1 ns

module cordic_uvm_tb;

    cordic_uvm_if vif();

    cordic_top #(
    .CORDIC_DATA_WIDTH(CORDIC_DATA_WIDTH)
    ) cordic_top_inst (
        .clock(vif.clock),
        .reset(vif.reset),
        .radians_full(vif.radians_full),
        .radians_wr_en(vif.radians_wr_en),
        .radians_din(vif.radians_din),
        .sin_empty(vif.sin_empty),
        .sin_rd_en(vif.sin_rd_en),
        .sin_dout(vif.sin_dout),
        .cos_empty(vif.cos_empty),
        .cos_rd_en(vif.cos_rd_en),
        .cos_dout(vif.cos_dout)
    );

    initial begin
        // store the vif so it can be retrieved by the driver & monitor
        uvm_resource_db#(virtual cordic_uvm_if)::set
            (.scope("ifs"), .name("vif"), .val(vif));

        // run the test
        run_test("cordic_uvm_test");        
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






