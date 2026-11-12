// control_in_monitor
// Class-side proxy for control_in_monitor_bfm. The BFM calls notify_transaction()
// once per post-reset clock; this class turns the pin values into a transaction,
// numbers it, shows it in the wave window and broadcasts it.
//
// PRIMING: the BFM also calls notify_reset() on every reset edge. Only the most
// recent reset sample is kept. On the first post-reset edge it is broadcast ONCE,
// marked prime=1, just before cycle 0. The predictor uses it to take the model's
// start-up step (controller_model's first call) during the last reset cycle, which
// is where the spec's startup timing diagram puts it. Prime transactions are never
// predicted against or compared.
class control_in_monitor extends uvm_monitor;
  `uvm_component_utils(control_in_monitor)

  control_in_configuration       configuration;
  virtual control_in_monitor_bfm bfm;
  uvm_analysis_port #(control_in_transaction) monitored_ap;

  int          transaction_viewing_stream;
  time         last_sample_time;
  int unsigned cycle_count;
  control_in_transaction pending_prime;   // last reset-cycle sample, not yet sent

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

  protected function control_in_transaction make_txn(input logic        complete_data,
                                                    input logic        complete_instr,
                                                    input logic [15:0] IR,
                                                    input logic [2:0]  psr,
                                                    input logic [15:0] IR_Exec,
                                                    input logic [15:0] IMem_dout,
                                                    input logic [2:0]  NZP);
    control_in_transaction t = control_in_transaction::type_id::create("t");
    t.complete_data  = complete_data;
    t.complete_instr = complete_instr;
    t.IR             = IR;
    t.psr            = psr;
    t.IR_Exec        = IR_Exec;
    t.IMem_dout      = IMem_dout;
    t.NZP            = NZP;
    t.start_time     = last_sample_time;
    t.end_time       = $time;
    last_sample_time = $time;
    return t;
  endfunction

  // Called by the BFM on every edge where reset is high. Keeps the latest sample for
  // priming and restarts cycle numbering (in step with control_out_monitor).
  virtual function void notify_reset(input logic        complete_data,
                                     input logic        complete_instr,
                                     input logic [15:0] IR,
                                     input logic [2:0]  psr,
                                     input logic [15:0] IR_Exec,
                                     input logic [15:0] IMem_dout,
                                     input logic [2:0]  NZP);
    pending_prime       = make_txn(complete_data, complete_instr, IR, psr, IR_Exec, IMem_dout, NZP);
    pending_prime.prime = 1'b1;
    cycle_count         = 0;
  endfunction

  virtual function void notify_transaction(input logic        complete_data,
                                           input logic        complete_instr,
                                           input logic [15:0] IR,
                                           input logic [2:0]  psr,
                                           input logic [15:0] IR_Exec,
                                           input logic [15:0] IMem_dout,
                                           input logic [2:0]  NZP);
    control_in_transaction t;
    // First post-reset edge: send the last reset-cycle sample first (priming only).
    if (pending_prime != null) begin
      `uvm_info(get_type_name(), {"prime (last reset cycle): ", pending_prime.convert2string()}, UVM_HIGH)
      monitored_ap.write(pending_prime);
      pending_prime = null;
    end
    t       = make_txn(complete_data, complete_instr, IR, psr, IR_Exec, IMem_dout, NZP);
    t.cycle = cycle_count++;
    `uvm_info(get_type_name(), t.convert2string(), UVM_HIGH)
    if (configuration.enable_transaction_viewing)
      t.add_to_wave(transaction_viewing_stream);
    monitored_ap.write(t);
  endfunction
endclass : control_in_monitor
