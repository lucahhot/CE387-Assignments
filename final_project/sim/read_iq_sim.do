setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# udp_reader architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/read_iq.sv"
vlog -work work "../sv/read_iq_top.sv"
vlog -work work "../sv/read_iq_tb.sv"

vsim -classdebug -voptargs=+acc +notimingchecks -L work work.read_iq_tb -wlf read_iq.wlf

add wave -noupdate -group read_iq_tb
add wave -noupdate -group read_iq_tb -radix hexadecimal /read_iq_tb/*
add wave -noupdate -group read_iq_tb/read_iq_top
add wave -noupdate -group divide_tb/read_iq_top -radix hexadecimal /read_iq_top/*

add wave -noupdate -group read_iq_tb/read_iq_top/read_iq_inst
add wave -noupdate -group read_iq_tb/read_iq_top/read_iq_inst -radix hexadecimal /read_iq_top/read_iq_inst/*

run -all 