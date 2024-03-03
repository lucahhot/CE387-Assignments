
setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# udp_reader architecture
vlog -work work "../sv/comparator.sv"
vlog -work work "../sv/divide.sv"
vlog -work work "../sv/divide_tb.sv"

vsim -classdebug -voptargs=+acc +notimingchecks -L work work.divide_tb -wlf divide.wlf

run -all 