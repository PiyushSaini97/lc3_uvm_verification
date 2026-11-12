// control_in_monitor_bfm
// Emulation-friendly monitor BFM (same split-transaction style as P2):
// the BFM is synthesizable-style HDL that waits on the clock and samples pins,
// then calls back into the class-based proxy (control_in_monitor).
//
// SAMPLING POLICY: one sample per rising clock edge.
//   * Reset edges: the inputs are handed to the monitor, which keeps only the most
//     recent one (the LAST reset cycle) to prime the predictor. Nothing sampled
//     during reset is ever compared.
//   * Post-reset edges: one transaction per edge, all compared.
//   * The controller's outputs are combinational functions of these inputs plus its
//     internal state (spec: "enables and bypass values are sensitive to the changing
//     values of IR, ..., completes, Instr_dout, prev_enables, psr, NZP").
//   * controller_model() is written the same way: called once per cycle, it takes
//     this cycle's inputs and returns this cycle's outputs.
//   * Reading at @(posedge) in the active region returns the values that were stable
//     during the cycle that just ended (registered DUT signals update via NBAs later
//     in the same time step). control_out_monitor_bfm samples on the SAME edge, so
//     input sample N and output sample N describe the same clock cycle.
interface control_in_monitor_bfm (control_in_if bus);

  control_in_pkg::control_in_monitor proxy;

  tri        clock_i;
  tri        reset_i;
  tri        complete_data_i;
  tri        complete_instr_i;
  tri [15:0] IR_i;
  tri [2:0]  psr_i;
  tri [15:0] IR_Exec_i;
  tri [15:0] IMem_dout_i;
  tri [2:0]  NZP_i;
  assign clock_i          = bus.clock;
  assign reset_i          = bus.reset;
  assign complete_data_i  = bus.complete_data;
  assign complete_instr_i = bus.complete_instr;
  assign IR_i             = bus.IR;
  assign psr_i            = bus.psr;
  assign IR_Exec_i        = bus.IR_Exec;
  assign IMem_dout_i      = bus.IMem_dout;
  assign NZP_i            = bus.NZP;

  task start_monitoring();
    forever begin
      @(posedge clock_i);
      if (reset_i !== 1'b1)
        proxy.notify_transaction(complete_data_i, complete_instr_i, IR_i, psr_i,
                                 IR_Exec_i, IMem_dout_i, NZP_i);
      else
        proxy.notify_reset(complete_data_i, complete_instr_i, IR_i, psr_i,
                           IR_Exec_i, IMem_dout_i, NZP_i);
    end
  endtask

endinterface : control_in_monitor_bfm
