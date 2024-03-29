setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "../sv/bram.sv"
vlog -work work "../sv/matmul.sv"
vlog -work work "../sv/matmul_top.sv"
vlog -work work "../sv/matmul_tb.sv"

vsim -classdebug -voptargs=+acc +notimingchecks -L work work.matmul_tb -wlf matmul.wlf

add wave -noupdate -group matmul_tb
add wave -noupdate -group matmul_tb -radix hexadecimal /matmul_tb/*

add wave -noupdate -group matmul_tb/matmul_top_inst
add wave -noupdate -group matmul_tb/matmul_top_inst -radix hexadecimal /matmul_tb/matmul_top_inst/*

add wave -noupdate -group matmul_tb/matmul_top_inst/matmul_inst
add wave -noupdate -group matmul_tb/matmul_top_inst/matmul_inst -radix hexadecimal /matmul_tb/matmul_top_inst/matmul_inst/*

add wave -noupdate -group matmul_tb/matmul_top_inst/x_inst
add wave -noupdate -group matmul_tb/matmul_top_inst/x_inst -radix hexadecimal /matmul_tb/matmul_top_inst/x_inst/*

add wave -noupdate -group matmul_tb/matmul_top_inst/y_inst
add wave -noupdate -group matmul_tb/matmul_top_inst/y_inst -radix hexadecimal /matmul_tb/matmul_top_inst/y_inst/*

add wave -noupdate -group matmul_tb/matmul_top_inst/z_inst
add wave -noupdate -group matmul_tb/matmul_top_inst/z_inst -radix hexadecimal /matmul_tb/matmul_top_inst/z_inst/*

run -all