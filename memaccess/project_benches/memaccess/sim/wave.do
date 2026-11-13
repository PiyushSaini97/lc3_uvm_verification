onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider "memaccess_in transactions"
add wave -noupdate /uvm_root/uvm_test_top/environment/memaccess_in_agent/monitor/txn_stream

add wave -noupdate -divider "memaccess_out transactions"
add wave -noupdate /uvm_root/uvm_test_top/environment/memaccess_out_agent/monitor/txn_stream

add wave -noupdate -divider "clock / reset"
add wave -noupdate                    /hdl_top/clock
add wave -noupdate                    /hdl_top/reset

add wave -noupdate -divider "MemAccess inputs"
add wave -noupdate -radix unsigned    /hdl_top/mem_state
add wave -noupdate -radix binary      /hdl_top/M_Control
add wave -noupdate -radix hexadecimal /hdl_top/M_Data
add wave -noupdate -radix hexadecimal /hdl_top/M_Addr
add wave -noupdate -radix hexadecimal /hdl_top/Data_dout

add wave -noupdate -divider "MemAccess outputs"
add wave -noupdate -radix hexadecimal /hdl_top/Data_addr
add wave -noupdate -radix hexadecimal /hdl_top/Data_din
add wave -noupdate -radix binary      /hdl_top/Data_rd
add wave -noupdate -radix hexadecimal /hdl_top/memout

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 280
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
