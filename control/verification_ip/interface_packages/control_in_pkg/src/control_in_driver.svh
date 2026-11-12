// control_in_driver
// Same shape as P2's decode_in_driver, with one addition: the first instruction is
// fetched before reset ends. The spec's startup diagram shows Imem[PC] = IMEM[3000]
// already on Instr_dout during reset, so the driver gets the first item, preloads it,
// and only then waits for reset.
// drive() returns when the controller moves the PC past the instruction, so the
// sequence runs at the pace the controller sets (stalls included).
class control_in_driver extends uvm_driver #(control_in_stimulus);
  `uvm_component_utils(control_in_driver)

  control_in_configuration      configuration;
  virtual control_in_driver_bfm bfm;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    bfm = configuration.driver_bfm;
  endfunction

  virtual task run_phase(uvm_phase phase);
    seq_item_port.get_next_item(req);
    bfm.preload(req.instr);
    bfm.wait_for_reset();
    forever begin
      `uvm_info(get_type_name(), {"driving: ", req.convert2string()}, UVM_HIGH)
      bfm.drive(req.instr, req.instr_wait, req.data_wait, req.wb_psr);
      seq_item_port.item_done();
      seq_item_port.get_next_item(req);
    end
  endtask
endclass : control_in_driver
