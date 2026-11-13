// memaccess_in_monitor_bfm
// Emulation-friendly monitor BFM (same split-transaction style as P2 and
// control_in_monitor_bfm): synthesizable-style HDL that waits on the clock and
// samples pins, then calls back into the class-based proxy (memaccess_in_monitor).
//
// SAMPLING POLICY: one sample per rising clock edge while reset is low.
//   * MemAccess is purely combinational - no clock, no reset, no state. Its outputs
//     are a function of the inputs sampled here and nothing else.
//   * memaccess_out_monitor_bfm samples on the SAME edge, so input sample N and
//     output sample N describe the same clock cycle. No delay, and no qualifying
//     enable: every post-reset cycle is a transaction, including IDLE cycles.
//   * Reading at @(posedge) in the active region returns the values that were stable
//     during the cycle that just ended, because the registers feeding MemAccess
//     (Execute's pcout/M_Data, the Controller's mem_state) update via non-blocking
//     assignments later in the same time step.
//   * Reset cycles are not sampled at all. MemAccess has no reset of its own; during
//     LC3 reset the blocks feeding it hold X, which says nothing about this block.
//     The monitor only restarts its cycle numbering, in step with
//     memaccess_out_monitor.
interface memaccess_in_monitor_bfm (memaccess_in_if bus);

  memaccess_in_pkg::memaccess_in_monitor proxy;

  tri        clock_i;
  tri        reset_i;
  tri [1:0]  mem_state_i;
  tri        M_Control_i;
  tri [15:0] M_Data_i;
  tri [15:0] M_Addr_i;
  tri [15:0] Data_dout_i;
  assign clock_i     = bus.clock;
  assign reset_i     = bus.reset;
  assign mem_state_i = bus.mem_state;
  assign M_Control_i = bus.M_Control;
  assign M_Data_i    = bus.M_Data;
  assign M_Addr_i    = bus.M_Addr;
  assign Data_dout_i = bus.Data_dout;

  task start_monitoring();
    forever begin
      @(posedge clock_i);
      if (reset_i !== 1'b1)
        proxy.notify_transaction(mem_state_i, M_Control_i, M_Data_i, M_Addr_i, Data_dout_i);
      else
        proxy.notify_reset();   // restart cycle numbering; nothing sampled or checked
    end
  endtask

endinterface : memaccess_in_monitor_bfm
