setenv LMC_TIMEUNIT -9
vlib work
vmap work work

vcom -work work "tank_const.vhd"
vcom -work work "tank.vhd"
vcom -work work "bullet_position.vhd"
vcom -work work "clock_counter_testing.vhd"
vcom -work work "game_state.vhd"
vcom -work work "tank_game_sim.vhd"
vcom -work work "tank_game_sim_tb.vhd"

vsim +notimingchecks -L work work.tank_game_sim_tb -wlf tank_game_sim_tb.wlf

add wave -noupdate -group tank_game_sim_tb
add wave -noupdate -group tank_game_sim_tb -radix unsigned /tank_game_sim_tb/*

add wave -noupdate -group tank_game_sim_tb/tank_game_dut
add wave -noupdate -group tank_game_sim_tb/tank_game_dut -radix unsigned /tank_game_sim_tb/tank_game_dut/*

add wave -noupdate -group tank_game_sim_tb/tank_game_dut/clock_counter_dut
add wave -noupdate -group tank_game_sim_tb/tank_game_dut/clock_counter_dut -radix unsigned /tank_game_sim_tb/tank_game_dut/clock_counter_dut/*

add wave -noupdate -group tank_game_sim_tb/tank_game_dut/game_state_unit
add wave -noupdate -group tank_game_sim_tb/tank_game_dut/game_state_unit -radix unsigned /tank_game_sim_tb/tank_game_dut/game_state_unit/*

add wave -noupdate -group tank_game_sim_tb/tank_game_dut/toptank
add wave -noupdate -group tank_game_sim_tb/tank_game_dut/toptank -radix unsigned /tank_game_sim_tb/tank_game_dut/toptank/*

add wave -noupdate -group tank_game_sim_tb/tank_game_dut/bottomtank
add wave -noupdate -group tank_game_sim_tb/tank_game_dut/bottomtank -radix unsigned /tank_game_sim_tb/tank_game_dut/bottomtank/*

add wave -noupdate -group tank_game_sim_tb/tank_game_dut/topbullet
add wave -noupdate -group tank_game_sim_tb/tank_game_dut/topbullet -radix unsigned /tank_game_sim_tb/tank_game_dut/topbullet/*

add wave -noupdate -group tank_game_sim_tb/tank_game_dut/bottombullet
add wave -noupdate -group tank_game_sim_tb/tank_game_dut/bottombullet -radix unsigned /tank_game_sim_tb/tank_game_dut/bottombullet/*

run -all
