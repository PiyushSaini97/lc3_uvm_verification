// execute_in_monitor
// Class-side proxy for execute_in_monitor_bfm. The BFM calls notify_transaction() for
// every enabled cycle; this class turns the pin values into a transaction, shows it in
// the wave window and broadcasts it on monitored_ap.
class execute_in_monitor extends uvm_monitor;
  `uvm_component_utils(execute_in_monitor)

  execute_in_configuration       configuration;
  virtual execute_in_monitor_bfm bfm;
  uvm_analysis_port #(execute_in_transaction) monitored_ap;

  int          transaction_viewing_stream;
  time         last_sample_time;
  int unsigned txn_count;

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

  virtual function void notify_transaction(input logic [5:0] e_control, input logic [15:0] ir,
                                           input logic [15:0] npc_in,
                                           input logic bypass_alu_1, input logic bypass_alu_2,
                                           input logic bypass_mem_1, input logic bypass_mem_2,
                                           input logic [15:0] vsr1, input logic [15:0] vsr2,
                                           input logic [15:0] mem_bypass_val,
                                           input logic [1:0] w_control_in, input logic mem_control_in);
    execute_in_transaction t = execute_in_transaction::type_id::create("t");
    t.e_control      = e_control;
    t.ir             = ir;
    t.npc_in         = npc_in;
    t.bypass_alu_1   = bypass_alu_1;
    t.bypass_alu_2   = bypass_alu_2;
    t.bypass_mem_1   = bypass_mem_1;
    t.bypass_mem_2   = bypass_mem_2;
    t.vsr1           = vsr1;
    t.vsr2           = vsr2;
    t.mem_bypass_val = mem_bypass_val;
    t.w_control_in   = w_control_in;
    t.mem_control_in = mem_control_in;
    t.index          = txn_count++;
    t.start_time     = last_sample_time;
    t.end_time       = $time;
    last_sample_time = $time;
    `uvm_info(get_type_name(), t.convert2string(), UVM_HIGH)
    if (configuration.enable_transaction_viewing)
      t.wave_view(transaction_viewing_stream);
    monitored_ap.write(t);
  endfunction
endclass : execute_in_monitor
