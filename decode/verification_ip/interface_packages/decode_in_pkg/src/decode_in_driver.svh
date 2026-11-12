class decode_in_driver extends uvm_driver #(decode_in_transaction);
  `uvm_component_utils(decode_in_driver)

  decode_in_configuration      configuration;
  virtual decode_in_driver_bfm bfm;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    bfm = configuration.driver_bfm;
  endfunction

  virtual task run_phase(uvm_phase phase);
    bfm.wait_for_reset();
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), {"driving: ", req.convert2string()}, UVM_HIGH)
      bfm.drive(req.dout, req.npc_in);
      seq_item_port.item_done();
    end
  endtask
endclass : decode_in_driver
