# add wave -noupdate -group cordic_uvm_tb
# add wave -noupdate -group cordic_uvm_tb -radix hexadecimal /cordic_uvm_tb/*

add wave -noupdate -group cordic_uvm_tb/cordic_top_inst
add wave -noupdate -group cordic_uvm_tb/cordic_top_inst -radix hexadecimal /cordic_uvm_tb/cordic_top_inst/*

add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/cordic_inst
add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/cordic_inst -radix hexadecimal /cordic_uvm_tb/cordic_top_inst/cordic_inst/*

add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/cordic_inst/genblk1[0]/cordic_state_inst
add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/cordic_inst/genblk1[0]/cordic_state_inst -radix hexadecimal /cordic_uvm_tb/cordic_top_inst/cordic_inst/genblk1[0]/cordic_state_inst/*

add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/fifo_radians_inst
add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/fifo_radians_inst -radix hexadecimal /cordic_uvm_tb/cordic_top_inst/fifo_radians_inst/*

add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/fifo_sin_inst
add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/fifo_sin_inst -radix hexadecimal /cordic_uvm_tb/cordic_top_inst/fifo_sin_inst/*

add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/fifo_cos_inst
add wave -noupdate -group cordic_uvm_tb/cordic_top_inst/fifo_cos_inst -radix hexadecimal /cordic_uvm_tb/cordic_top_inst/fifo_cos_inst/*

