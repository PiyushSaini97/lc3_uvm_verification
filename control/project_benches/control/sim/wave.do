add wave -noupdate /hdl_top/clock /hdl_top/reset
add wave -noupdate -group control_in_if  -radix hex /hdl_top/control_in_if_i/*
add wave -noupdate -group control_out_if /hdl_top/control_out_if_i/*
add wave -noupdate -group driver_bfm     -radix hex /hdl_top/control_in_driver_bfm_i/*
add wave -noupdate -group DUT /hdl_top/DUT/*
configure wave -namecolwidth 260
configure wave -valuecolwidth 150
configure wave -justifyvalue left
wave zoom full
