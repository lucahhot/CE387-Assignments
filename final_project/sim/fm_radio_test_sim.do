setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# udp_reader architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/globals.sv"
vlog -work work "../sv/add.sv"
vlog -work work "../sv/sub.sv"
vlog -work work "../sv/div.sv"
vlog -work work "../sv/qarctan.sv"
vlog -work work "../sv/multiply.sv"
vlog -work work "../sv/fir.sv"
vlog -work work "../sv/fir_cmplx.sv"
vlog -work work "../sv/iir.sv"
vlog -work work "../sv/gain.sv"
vlog -work work "../sv/read_iq.sv"
vlog -work work "../sv/demodulate.sv"
vlog -work work "../sv/fm_radio_test.sv"
vlog -work work "../sv/fm_radio_tb.sv"

vsim -classdebug -voptargs=+acc +notimingchecks -L work work.fm_radio_tb -wlf fm_radio.wlf

add wave -noupdate -group fm_radio_tb
add wave -noupdate -group fm_radio_tb -radix hexadecimal /fm_radio_tb/*


add wave -noupdate -group fm_radio_tb/fm_radio_inst/demod_fifo_inst
add wave -noupdate -group fm_radio_tb/fm_radio_inst/demod_fifo_inst -radix hexadecimal /fm_radio_inst/demod_fifo_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_inst/bp_lmr_fifo_inst
add wave -noupdate -group fm_radio_tb/fm_radio_inst/bp_lmr_fifo_inst -radix hexadecimal /fm_radio_inst/bp_lmr_fifo_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_inst/square_bp_pilot_fifo_inst
add wave -noupdate -group fm_radio_tb/fm_radio_inst/square_bp_pilot_fifo_inst -radix hexadecimal /fm_radio_inst/square_bp_pilot_fifo_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_inst/hp_pilot_fifo_inst
add wave -noupdate -group fm_radio_tb/fm_radio_inst/hp_pilot_fifo_inst -radix hexadecimal /fm_radio_inst/hp_pilot_fifo_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_inst/mult_demod_lmr_fifo_inst
add wave -noupdate -group fm_radio_tb/fm_radio_inst/mult_demod_lmr_fifo_inst -radix hexadecimal /fm_radio_inst/mult_demod_lmr_fifo_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_inst/left_gain_fifo_inst
add wave -noupdate -group fm_radio_tb/fm_radio_inst/left_gain_fifo_inst -radix hexadecimal /fm_radio_inst/left_gain_fifo_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_inst/right_gain_fifo_inst
add wave -noupdate -group fm_radio_tb/fm_radio_inst/right_gain_fifo_inst -radix hexadecimal /fm_radio_inst/right_gain_fifo_inst/*


run -all 