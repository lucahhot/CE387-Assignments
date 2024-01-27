setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/motion_detect.sv"
vlog -work work "../sv/motion_detect_top.sv"
vlog -work work "../sv/motion_detect_tb.sv"

vsim -classdebug -voptargs=+acc +notimingchecks -L work work.motion_detect_tb -wlf motion_detect.wlf

add wave -noupdate -group motion_detect_tb
add wave -noupdate -group motion_detect_tb -radix hexadecimal /motion_detect_tb/*

add wave -noupdate -group motion_detect_tb/motion_detect_top_inst
add wave -noupdate -group motion_detect_tb/motion_detect_top_inst -radix hexadecimal /motion_detect_tb/motion_detect_top_inst/*

add wave -noupdate -group motion_detect_tb/motion_detect_top_inst/motion_detect_inst
add wave -noupdate -group motion_detect_tb/motion_detect_top_inst/motion_detect_inst -radix hexadecimal /motion_detect_tb/motion_detect_top_inst/motion_detect_inst/*

add wave -noupdate -group motion_detect_tb/motion_detect_top_inst/fifo_base_inst
add wave -noupdate -group motion_detect_tb/motion_detect_top_inst/fifo_base_inst -radix hexadecimal /motion_detect_tb/motion_detect_top_inst/fifo_base_inst/*

add wave -noupdate -group motion_detect_tb/motion_detect_top_inst/fifo_img_in_inst
add wave -noupdate -group motion_detect_tb/motion_detect_top_inst/fifo_img_in_inst -radix hexadecimal /motion_detect_tb/motion_detect_top_inst/fifo_img_in_inst/*

add wave -noupdate -group motion_detect_tb/motion_detect_top_inst/fifo_img_out_inst
add wave -noupdate -group motion_detect_tb/motion_detect_top_inst/fifo_img_out_inst -radix hexadecimal /motion_detect_tb/motion_detect_top_inst/fifo_img_out_inst/*

run -all
