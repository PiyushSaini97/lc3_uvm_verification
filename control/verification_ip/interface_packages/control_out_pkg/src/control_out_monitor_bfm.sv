// control_out_monitor_bfm
// Samples the controller outputs on the SAME rising edge as control_in_monitor_bfm,
// so output sample N belongs to the same clock cycle as input sample N.
//
// Note the difference from P2's decode_out_monitor_bfm: there the outputs were
// registered and appeared one cycle after enable_decode, so the BFM delayed by one
// cycle. The controller is a per-cycle (combinational + state) block, so there is no
// delay and no qualifying enable: every post-reset cycle is a transaction.
//
// Reset cycles are NOT checked. While reset is high the BFM only tells the monitor
// to restart its cycle numbering (in step with control_in_monitor). Every cycle
// after reset is compared on all outputs by the scoreboard.
interface control_out_monitor_bfm (control_out_if bus);

  control_out_pkg::control_out_monitor proxy;

  tri       clock_i;
  tri       reset_i;
  tri       enable_updatePC_i;
  tri       enable_fetch_i;
  tri       enable_decode_i;
  tri       enable_execute_i;
  tri       enable_writeback_i;
  tri       bypass_alu_1_i;
  tri       bypass_alu_2_i;
  tri       bypass_mem_1_i;
  tri       bypass_mem_2_i;
  tri [1:0] mem_state_i;
  tri       br_taken_i;
  assign clock_i            = bus.clock;
  assign reset_i            = bus.reset;
  assign enable_updatePC_i  = bus.enable_updatePC;
  assign enable_fetch_i     = bus.enable_fetch;
  assign enable_decode_i    = bus.enable_decode;
  assign enable_execute_i   = bus.enable_execute;
  assign enable_writeback_i = bus.enable_writeback;
  assign bypass_alu_1_i     = bus.bypass_alu_1;
  assign bypass_alu_2_i     = bus.bypass_alu_2;
  assign bypass_mem_1_i     = bus.bypass_mem_1;
  assign bypass_mem_2_i     = bus.bypass_mem_2;
  assign mem_state_i        = bus.mem_state;
  assign br_taken_i         = bus.br_taken;

  task start_monitoring();
    forever begin
      @(posedge clock_i);
      if (reset_i !== 1'b1)
        proxy.notify_transaction(enable_updatePC_i, enable_fetch_i, enable_decode_i,
                                 enable_execute_i, enable_writeback_i,
                                 bypass_alu_1_i, bypass_alu_2_i, bypass_mem_1_i, bypass_mem_2_i,
                                 mem_state_i, br_taken_i);
      else
        proxy.notify_reset();   // restart cycle numbering; no check
    end
  endtask

endinterface : control_out_monitor_bfm
