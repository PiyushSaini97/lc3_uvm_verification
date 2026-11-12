class decode_in_monitor extends uvm_monitor;
  `uvm_component_utils(decode_in_monitor)

  decode_in_configuration       configuration;
  virtual decode_in_monitor_bfm bfm;
  uvm_analysis_port #(decode_in_transaction) monitored_ap;

  int transaction_viewing_stream;
  time last_sample_time;

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

  virtual function void notify_transaction(input bit [15:0] dout, input bit [15:0] npc_in);
    decode_in_transaction t = decode_in_transaction::type_id::create("t");
    t.dout       = dout;
    t.npc_in     = npc_in;
    t.start_time = last_sample_time;
    t.end_time   = $time;
    last_sample_time = $time;
    `uvm_info(get_type_name(), t.convert2string(), UVM_MEDIUM)
    if (configuration.enable_transaction_viewing)
      t.add_to_wave(transaction_viewing_stream);
    monitored_ap.write(t);
  endfunction
endclass : decode_in_monitor
