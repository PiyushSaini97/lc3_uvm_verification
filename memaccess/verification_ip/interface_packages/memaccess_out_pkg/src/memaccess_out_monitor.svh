// memaccess_out_monitor
// Class-side proxy for memaccess_out_monitor_bfm. The BFM calls notify_transaction()
// once per post-reset clock; this class turns the pin values into a transaction,
// numbers it, shows it in the wave window and broadcasts it to the scoreboard and
// the coverage collector.
class memaccess_out_monitor extends uvm_monitor;
  `uvm_component_utils(memaccess_out_monitor)

  memaccess_out_configuration       configuration;
  virtual memaccess_out_monitor_bfm bfm;
  uvm_analysis_port #(memaccess_out_transaction) monitored_ap;

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

  virtual function void notify_reset();
    cycle_count      = 0;
    last_sample_time = $time;
  endfunction

  virtual function void notify_transaction(input logic [15:0] Data_addr,
                                           input logic [15:0] Data_din,
                                           input logic        Data_rd,
                                           input logic [15:0] memout);
    memaccess_out_transaction t;
    t = memaccess_out_transaction::type_id::create("t");
    t.Data_addr  = Data_addr;
    t.Data_din   = Data_din;
    t.Data_rd    = Data_rd;
    t.memout     = memout;
    t.start_time = last_sample_time;
    t.end_time   = $time;
    t.cycle      = cycle_count++;
    last_sample_time = $time;

    `uvm_info(get_type_name(), t.convert2string(), UVM_HIGH)
    if (configuration.enable_transaction_viewing)
      t.add_to_wave(transaction_viewing_stream);
    monitored_ap.write(t);
  endfunction
endclass : memaccess_out_monitor
