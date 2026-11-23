class imem_transaction extends uvm_sequence_item;
 logic[15:0] address,write_data;logic read;bit aborted;
 rand bit[15:0] data;rand bit[3:0] opcode;rand bit immediate_mode;rand int unsigned latency;
 `uvm_object_utils_begin(imem_transaction)
 `uvm_field_int(address,UVM_DEFAULT) `uvm_field_int(read,UVM_DEFAULT)
 `uvm_field_int(data,UVM_DEFAULT) `uvm_field_int(latency,UVM_DEFAULT)
 `uvm_object_utils_end
 constraint delay_c {latency==0;}
 constraint opcode_c {opcode inside {0,1,2,3,5,6,7,9,10,11,12,14}; data[15:12]==opcode; solve opcode before data;solve immediate_mode before data;}
 constraint legal_c { if(opcode inside {1,5}) data[5]==immediate_mode; if(opcode inside {1,5} && !immediate_mode) data[4:3]==0; if(opcode==9) data[5:0]==63; if(opcode==12) {data[11:9]==0;data[5:0]==0;} }
 constraint known_dut_bug_c {data!=16'h0000;}
 function new(string name="imem_transaction");super.new(name);endfunction
endclass
