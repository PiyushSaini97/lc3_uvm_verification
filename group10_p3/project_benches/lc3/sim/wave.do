# wave.do - LC3 top-level bench
# Groups are ordered the way an instruction flows: memory -> fetch -> decode ->
# execute -> memaccess -> writeback, with the controller and register file beside.
# Each stage group shows that stage's interface, i.e. exactly what its agent sees.
# onerror: a signal that is not visible (e.g. inside encrypted RTL) must not stop
# the rest of the script.
onerror {resume}

add wave -noupdate /hdl_top/clock /hdl_top/reset

add wave -noupdate -expand -group {LC3 ports} -radix hex \
    /hdl_top/pc /hdl_top/instrmem_rd /hdl_top/Instr_dout /hdl_top/complete_instr \
    /hdl_top/Data_addr /hdl_top/Data_rd /hdl_top/Data_din /hdl_top/Data_dout \
    /hdl_top/complete_data /hdl_top/dmem_request

add wave -noupdate -expand -group {Pipeline} -radix hex \
    /hdl_top/DUT/enable_updatePC /hdl_top/DUT/enable_fetch /hdl_top/DUT/enable_decode \
    /hdl_top/DUT/enable_execute /hdl_top/DUT/enable_writeback \
    /hdl_top/DUT/IR /hdl_top/DUT/IR_Exec /hdl_top/DUT/npc_out_fetch /hdl_top/DUT/npc_out_dec \
    /hdl_top/DUT/aluout /hdl_top/DUT/pcout /hdl_top/DUT/memout \
    /hdl_top/DUT/br_taken /hdl_top/DUT/NZP /hdl_top/DUT/psr /hdl_top/DUT/mem_state

add wave -noupdate -group {Bypass} \
    /hdl_top/DUT/bypass_alu_1 /hdl_top/DUT/bypass_alu_2 \
    /hdl_top/DUT/bypass_mem_1 /hdl_top/DUT/bypass_mem_2

add wave -noupdate -group {Register file} -radix hex \
    /hdl_top/DUT/WB/RF/R0 /hdl_top/DUT/WB/RF/R1 /hdl_top/DUT/WB/RF/R2 /hdl_top/DUT/WB/RF/R3 \
    /hdl_top/DUT/WB/RF/R4 /hdl_top/DUT/WB/RF/R5 /hdl_top/DUT/WB/RF/R6 /hdl_top/DUT/WB/RF/R7

add wave -noupdate -group {imem_if}       -radix hex /hdl_top/imem_if_i/*
add wave -noupdate -group {dmem_if}       -radix hex /hdl_top/dmem_if_i/*
add wave -noupdate -group {fetch_in_if}   -radix hex /hdl_top/fetch_in_if_i/*
add wave -noupdate -group {fetch_out_if}  -radix hex /hdl_top/fetch_out_if_i/*
add wave -noupdate -group {decode_in_if}  -radix hex /hdl_top/decode_in_if_i/*
add wave -noupdate -group {decode_out_if} -radix hex /hdl_top/decode_out_if_i/*
add wave -noupdate -group {execute_in_if}  -radix hex /hdl_top/execute_in_if_i/*
add wave -noupdate -group {execute_out_if} -radix hex /hdl_top/execute_out_if_i/*
add wave -noupdate -group {memaccess_in_if}  -radix hex /hdl_top/memaccess_in_if_i/*
add wave -noupdate -group {memaccess_out_if} -radix hex /hdl_top/memaccess_out_if_i/*
add wave -noupdate -group {control_in_if}  -radix hex /hdl_top/control_in_if_i/*
add wave -noupdate -group {control_out_if}            /hdl_top/control_out_if_i/*
add wave -noupdate -group {writeback_in_if}  -radix hex /hdl_top/writeback_in_if_i/*
add wave -noupdate -group {writeback_out_if} -radix hex /hdl_top/writeback_out_if_i/*

configure wave -namecolwidth 260
configure wave -valuecolwidth 110
configure wave -justifyvalue left
configure wave -timelineunits ns
update
wave zoom range 0ns 400ns
