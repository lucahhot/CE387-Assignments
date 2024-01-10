setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vlog -work work "fibonacci.sv"
vlog -work work "fibonacci_tb.sv"

vsim -classdebug -voptargs=+acc +notimingchecks -L work work.fibonacci_tb -wlf fibonacci.wlf

add wave -noupdate -group fibonacci_tb
add wave -noupdate -group fibonacci_tb -radix unsigned /fibonacci_tb/*
add wave -noupdate -group fibonacci_tb/fibonacci
add wave -noupdate -group fibonacci_tb/fib -radix unsigned /fibonacci_tb/fib/*
run -all
