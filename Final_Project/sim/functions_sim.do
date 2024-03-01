
setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# udp_reader architecture
vlog -work work "../sv/globals.sv"
vlog -work work "../sv/functions_tb.sv"

# start basic simulation
vsim -classdebug -voptargs=+acc +notimingchecks -L work work.functions_tb -wlf functions.wlf

run -all
#quit;