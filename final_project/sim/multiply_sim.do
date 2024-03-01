setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/multiply.sv"
vlog -work work "../sv/multiply_top.sv"
vlog -work work "../sv/multiply_tb.sv"

vsim -classdebug -voptargs=+acc +notimingchecks -L work work.matmul_tb -wlf matmul.wlf

run -all