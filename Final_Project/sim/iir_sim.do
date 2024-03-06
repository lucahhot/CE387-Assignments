
setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# udp_reader architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/iir.sv"
vlog -work work "../sv/iir_top.sv"
vlog -work work "../sv/iir_tb.sv"

# uvm library
vlog -work work +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm.sv
vlog -work work +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm_macros.svh
vlog -work work +incdir+$env(UVM_HOME)/src $env(MTI_HOME)/verilog_src/questa_uvm_pkg-1.2/src/questa_uvm_pkg.sv

# uvm package
# vlog -work work +incdir+$env(UVM_HOME)/src "../uvm/iir_uvm_pkg.sv"
# vlog -work work +incdir+$env(UVM_HOME)/src "../uvm/iir_uvm_tb.sv"

# start uvm simulation
# vsim -classdebug -voptargs=+acc +notimingchecks -L work work.iir_uvm_tb -wlf iir_uvm_tb.wlf -sv_lib lib/uvm_dpi -dpicpppath /usr/bin/gcc +incdir+$env(MTI_HOME)/verilog_src/questa_uvm_pkg-1.2/src/

# start basic simulation
vsim -classdebug -voptargs=+acc +notimingchecks -L work work.iir_tb -wlf iir.wlf

# do iir_wave.do

do iir_wave_normal.do

run -all
#quit;