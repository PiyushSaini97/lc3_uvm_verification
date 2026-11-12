// control_out_monitor
class control_out_monitor extends uvm_monitor;
  `uvm_component_utils(control_out_monitor)

  control_out_configuration       configuration;
  virtual control_out_monitor_bfm bfm;
  uvm_analysis_port #(control_out_transaction) monitored_ap;

  int          transaction_viewing_stream;
  time         last_sample_time;
  int unsigned cycle_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitored_ap = new("monitored_ap", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    bfm       = configuration.monitor_bfm;
    bfm.proxy = this;
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    if (configuration.enable_transaction_viewing)
      transaction_viewing_stream = $create_transaction_stream({"..", get_full_name(), ".", "txn_stream"});
  endfunction

  virtual task run_phase(uvm_phase phase);
    bfm.start_monitoring();
  endtask

  protected function control_out_transaction make_txn(input logic       enable_updatePC,
                                                   input logic       enable_fetch,
                                                   input logic       enable_decode,
                                                   input logic       enable_execute,
                                                   input logic       enable_writeback,
                                                   input logic       bypass_alu_1,
                                                   input logic       bypass_alu_2,
                                                   input logic       bypass_mem_1,
                                                   input logic       bypass_mem_2,
                                                   input logic [1:0] mem_state,
                                                   input logic       br_taken);
    control_out_transaction t = control_out_transaction::type_id::create("t");
    t.enable_updatePC  = enable_updatePC;
    t.enable_fetch     = enable_fetch;
    t.enable_decode    = enable_decode;
    t.enable_execute   = enable_execute;
    t.enable_writeback = enable_writeback;
    t.bypass_alu_1     = bypass_alu_1;
    t.bypass_alu_2     = bypass_alu_2;
    t.bypass_mem_1     = bypass_mem_1;
    t.bypass_mem_2     = bypass_mem_2;
    t.mem_state        = mem_state;
    t.br_taken         = br_taken;
    return t;
  endfunction

  virtual function void notify_transaction(input logic       enable_updatePC,
                                           input logic       enable_fetch,
                                           input logic       enable_decode,
                                           input logic       enable_execute,
                                           input logic       enable_writeback,
                                           input logic       bypass_alu_1,
                                           input logic       bypass_alu_2,
                                           input logic       bypass_mem_1,
                                           input logic       bypass_mem_2,
                                           input logic [1:0] mem_state,
                                           input logic       br_taken);
    control_out_transaction t = make_txn(enable_updatePC, enable_fetch, enable_decode, enable_execute,
                                      enable_writeback, bypass_alu_1, bypass_alu_2, bypass_mem_1,
                                      bypass_mem_2, mem_state, br_taken);
    t.cycle          = cycle_count++;
    t.start_time     = last_sample_time;
    t.end_time       = $time;
    last_sample_time = $time;
    `uvm_info(get_type_name(), t.convert2string(), UVM_HIGH)
    if (configuration.enable_transaction_viewing)
      t.add_to_wave(transaction_viewing_stream);
    monitored_ap.write(t);
  endfunction

  // Called by the BFM on every edge where reset is high. Reset cycles are not
  // checked; restarting the count keeps numbering in step with control_in_monitor
  // (and lets the predictor detect a reset in the middle of a test).
  virtual function void notify_reset();
    cycle_count      = 0;
    last_sample_time = $time;
  endfunction
endclass : control_out_monitor
