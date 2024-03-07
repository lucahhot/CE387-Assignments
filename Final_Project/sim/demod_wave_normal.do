
add wave -noupdate -group demod_tb
add wave -noupdate -group demod_tb -radix hexadecimal /demod_tb/*

add wave -noupdate -group demod_tb/demod_top_inst
add wave -noupdate -group demod_tb/demod_top_inst -radix hexadecimal /demod_tb/demod_top_inst/*

add wave -noupdate -group demod_tb/demod_top_inst/demod_inst
add wave -noupdate -group demod_tb/demod_top_inst/demod_inst -radix hexadecimal /demod_tb/demod_top_inst/demod_inst/*

add wave -noupdate -group demod_tb/demod_top_inst/real_input_fifo
add wave -noupdate -group demod_tb/demod_top_inst/real_input_fifo -radix hexadecimal /demod_tb/demod_top_inst/real_input_fifo/*

add wave -noupdate -group demod_tb/demod_top_inst/imag_input_fifo
add wave -noupdate -group demod_tb/demod_top_inst/imag_input_fifo -radix hexadecimal /demod_tb/demod_top_inst/imag_input_fifo/*

add wave -noupdate -group demod_tb/demod_top_inst/output_fifo
add wave -noupdate -group demod_tb/demod_top_inst/output_fifo -radix hexadecimal /demod_tb/demod_top_inst/output_fifo/*

