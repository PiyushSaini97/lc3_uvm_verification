class decode_out_monitor extends uvm_monitor;
  `uvm_component_utils(decode_out_monitor)

  decode_out_configuration                    configuration;
  virtual decode_out_monitor_bfm              bfm;
  uvm_analysis_port #(decode_out_transaction) monitored_ap;

  int                                         transaction_viewing_stream;
  time                                        last_sample_time;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitored_ap = new("monitored_ap", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (configuration == null) `uvm_fatal("LC3_NULL_CFG", "Monitor configuration missing");
    bfm = configuration.monitor_bfm;
    if (bfm == null) `uvm_fatal("LC3_NULL_BFM", "Monitor BFM is null");
    bfm.proxy = this;
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
`ifdef QUESTA_TRANSACTIONS
    if (configuration.enable_transaction_viewing)
      transaction_viewing_stream = $create_transaction_stream({"..", get_full_name(), ".", "txn_stream"});
`endif
  endfunction

  virtual task run_phase(uvm_phase phase);
    bfm.start_monitoring();
  endtask

  virtual function void notify_transaction(input logic [15:0] IR, input logic [15:0] npc_out,
                                           input logic [5:0] E_Control, input logic [1:0] W_Control,
                                           input logic Mem_Control);
    decode_out_transaction t = decode_out_transaction::type_id::create("t");
    t.IR             = IR;
    t.npc_out        = npc_out;
    t.E_Control      = E_Control;
    t.W_Control      = W_Control;
    t.Mem_Control    = Mem_Control;
    t.start_time     = last_sample_time;
    t.end_time       = $time;
    last_sample_time = $time;
`ifdef QUESTA_TRANSACTIONS
    if (configuration.enable_transaction_viewing) t.add_to_wave(transaction_viewing_stream);
`endif
    monitored_ap.write(t);
  endfunction
endclass : decode_out_monitor
