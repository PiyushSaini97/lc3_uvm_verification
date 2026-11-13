// memaccess_in_monitor
// Class-side proxy for memaccess_in_monitor_bfm. The BFM calls notify_transaction()
// once per post-reset clock; this class turns the pin values into a transaction,
// numbers it, shows it in the wave window and broadcasts it.
//
// This is the UVMF proxy (push) pattern: the monitor hands a handle to itself to the
// BFM in connect_phase, and the BFM calls back into it. P2's monitors used the
// pull-style bfm.monitor() task instead.
class memaccess_in_monitor extends uvm_monitor;
  `uvm_component_utils(memaccess_in_monitor)

  memaccess_in_configuration       configuration;
  virtual memaccess_in_monitor_bfm bfm;
  uvm_analysis_port #(memaccess_in_transaction) monitored_ap;

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

  // Called by the BFM on every edge where reset is high: restart cycle numbering so
  // the input and output streams stay in step. Nothing is sampled or compared.
  virtual function void notify_reset();
    cycle_count      = 0;
    last_sample_time = $time;
  endfunction

  virtual function void notify_transaction(input logic [1:0]  mem_state,
                                           input logic        M_Control,
                                           input logic [15:0] M_Data,
                                           input logic [15:0] M_Addr,
                                           input logic [15:0] Data_dout);
    memaccess_in_transaction t;
    t = memaccess_in_transaction::type_id::create("t");
    t.mem_state  = mem_state;
    t.M_Control  = M_Control;
    t.M_Data     = M_Data;
    t.M_Addr     = M_Addr;
    t.Data_dout  = Data_dout;
    t.start_time = last_sample_time;
    t.end_time   = $time;
    t.cycle      = cycle_count++;
    last_sample_time = $time;

    `uvm_info(get_type_name(), t.convert2string(), UVM_HIGH)
    if (configuration.enable_transaction_viewing)
      t.add_to_wave(transaction_viewing_stream);
    monitored_ap.write(t);
  endfunction
endclass : memaccess_in_monitor
