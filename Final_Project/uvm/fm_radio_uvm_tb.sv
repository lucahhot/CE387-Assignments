
import uvm_pkg::*;
import fm_radio_uvm_package::*;

`include "fm_radio_uvm_if.sv"

`timescale 1 ns / 1 ns

module fm_radio_uvm_tb;

    fm_radio_uvm_if vif();

    fm_radio #(
    .DATA_SIZE(DATA_SIZE),
    .CHAR_SIZE(CHAR_SIZE),
    .BYTE_SIZE(BYTE_SIZE),
    .BITS(BITS),
    .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE),
    .AUDIO_DECIMATION(AUDIO_DECIMATION),
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
    .GAIN(GAIN)
    ) fm_radio_inst (
        .clock(vif.clock),
        .reset(vif.reset),
        .in_full(vif.in_full),
        .in_wr_en(vif.in_wr_en),
        .data_din(vif.data_din),
        .left_audio_empty(vif.left_audio_empty),
        .left_audio_rd_en(vif.left_audio_rd_en),
        .left_audio_dout(vif.left_audio_dout),
        .right_audio_empty(vif.right_audio_empty),
        .right_audio_rd_en(vif.right_audio_rd_en),
        .right_audio_dout(vif.right_audio_dout)
    );

    initial begin
        // store the vif so it can be retrieved by the driver & monitor
        uvm_resource_db#(virtual fm_radio_uvm_if)::set
            (.scope("ifs"), .name("vif"), .val(vif));

        // run the test
        run_test("fm_radio_uvm_test");        
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






