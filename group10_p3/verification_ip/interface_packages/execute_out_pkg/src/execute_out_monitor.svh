// execute_out_monitor
// Class-side proxy for execute_out_monitor_bfm.
class execute_out_monitor extends uvm_monitor;
  `uvm_component_utils(execute_out_monitor)

  execute_out_configuration                    configuration;
  virtual execute_out_monitor_bfm              bfm;
  uvm_analysis_port #(execute_out_transaction) monitored_ap;

  int                                          transaction_viewing_stream;
  time                                         last_sample_time;
  int unsigned                                 txn_count;

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

  virtual function void notify_transaction(
      input logic [15:0] aluout, input logic [15:0] pcout, input logic [1:0] w_control_out,
      input logic mem_control_out, input logic [2:0] dr, input logic [2:0] sr1, input logic [2:0] sr2,
      input logic [15:0] ir_exec, input logic [2:0] nzp, input logic [15:0] m_data);
    execute_out_transaction t = execute_out_transaction::type_id::create("t");
    t.aluout          = aluout;
    t.pcout           = pcout;
    t.w_control_out   = w_control_out;
    t.mem_control_out = mem_control_out;
    t.dr              = dr;
    t.sr1             = sr1;
    t.sr2             = sr2;
    t.ir_exec         = ir_exec;
    t.nzp             = nzp;
    t.m_data          = m_data;
    t.index           = txn_count++;
    t.start_time      = last_sample_time;
    t.end_time        = $time;
    last_sample_time  = $time;
    `uvm_info(get_type_name(), t.convert2string(), UVM_HIGH);
`ifdef QUESTA_TRANSACTIONS
    if (configuration.enable_transaction_viewing) t.wave_view(transaction_viewing_stream);
`endif
    monitored_ap.write(t);
  endfunction
endclass : execute_out_monitor
