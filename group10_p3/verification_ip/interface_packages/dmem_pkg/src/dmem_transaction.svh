class dmem_transaction extends uvm_sequence_item;
 logic[15:0] address,write_data;logic read;bit aborted;
 rand bit[15:0] data;rand int unsigned latency;
 `uvm_object_utils_begin(dmem_transaction)
 `uvm_field_int(address,UVM_DEFAULT) `uvm_field_int(read,UVM_DEFAULT)
 `uvm_field_int(data,UVM_DEFAULT) `uvm_field_int(latency,UVM_DEFAULT)
 `uvm_object_utils_end
 constraint delay_c {latency inside {[1:3]};}
 
 function new(string name="dmem_transaction");super.new(name);endfunction
endclass
