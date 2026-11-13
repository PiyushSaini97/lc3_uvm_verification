// memaccess_in_driver
// Used only when the agent is ACTIVE (memaccess block bench). Pulls one
// memaccess_in_stimulus per clock from the sequencer and hands its plain data fields
// to the BFM.
class memaccess_in_driver extends uvm_driver #(memaccess_in_stimulus);
  `uvm_component_utils(memaccess_in_driver)

  memaccess_in_configuration configuration;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), {"driving: ", req.convert2string()}, UVM_HIGH)
      configuration.driver_bfm.drive(req.mem_state, req.M_Control,
                                     req.M_Data, req.M_Addr, req.Data_dout);
      seq_item_port.item_done();
    end
  endtask
endclass : memaccess_in_driver
