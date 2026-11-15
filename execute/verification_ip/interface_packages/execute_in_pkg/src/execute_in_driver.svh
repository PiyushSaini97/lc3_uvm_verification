// execute_in_driver
// ACTIVE agent only. Takes one transaction per clock from the sequencer and drives it
// through the driver BFM. enable_execute stays high from the first item to the end.
class execute_in_driver extends uvm_driver #(execute_in_transaction);
  `uvm_component_utils(execute_in_driver)

  execute_in_configuration configuration;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    execute_in_transaction tr;
    int unsigned count = 0;
    configuration.driver_bfm.assert_enable();
    forever begin
      seq_item_port.get_next_item(tr);
      count++;
      `uvm_info(get_type_name(), $sformatf("Transaction #%0d: %s", count, tr.convert2string()), UVM_HIGH)
      configuration.driver_bfm.drive(tr.e_control, tr.ir, tr.npc_in,
                                     tr.bypass_alu_1, tr.bypass_alu_2,
                                     tr.bypass_mem_1, tr.bypass_mem_2,
                                     tr.vsr1, tr.vsr2, tr.mem_bypass_val,
                                     tr.w_control_in, tr.mem_control_in);
      seq_item_port.item_done();
    end
  endtask
endclass : execute_in_driver
