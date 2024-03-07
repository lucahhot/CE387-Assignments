setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# udp_reader architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/gain.sv"
vlog -work work "../sv/gain_top.sv"
vlog -work work "../sv/gain_tb.sv"

vsim -classdebug -voptargs=+acc +notimingchecks -L work work.gain_tb -wlf gain.wlf

add wave -noupdate -group gain_tb
add wave -noupdate -group gain_tb -radix hexadecimal /gain_tb/*
add wave -noupdate -group gain_tb/gain_top
add wave -noupdate -group gain_tb/gain_top -radix hexadecimal /gain_top/*

add wave -noupdate -group gain_tb/gain_top/gain_inst
add wave -noupdate -group gain_tb/gain_top/gain_inst -radix hexadecimal /gain_top/gain_inst/*

add wave -noupdate -group gain_tb/gain_top/fifo_in_inst
add wave -noupdate -group gain_tb/gain_top/fifo_in_inst -radix hexadecimal /gain_top/fifo_in_inst/*

run -all 