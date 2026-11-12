add wave -noupdate -group decode_in_if  /hdl_top/decode_in_if_i/*
add wave -noupdate -group decode_out_if /hdl_top/decode_out_if_i/*
add wave -noupdate -group DUT /hdl_top/DUT/*
configure wave -namecolwidth 260
configure wave -valuecolwidth 150
configure wave -justifyvalue left
wave zoom full
