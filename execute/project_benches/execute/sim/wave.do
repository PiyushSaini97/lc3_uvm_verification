add wave -noupdate /hdl_top/clock /hdl_top/reset
add wave -noupdate -group execute_in_if  -radix hex /hdl_top/execute_in_if_i/*
add wave -noupdate -group execute_out_if -radix hex /hdl_top/execute_out_if_i/*
add wave -noupdate -group driver_bfm     -radix hex /hdl_top/execute_in_driver_bfm_i/*
add wave -noupdate -group DUT -radix hex /hdl_top/DUT/*
