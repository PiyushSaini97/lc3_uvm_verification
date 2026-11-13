// memaccess_out_monitor_bfm
// Samples the MemAccess outputs on the SAME rising edge as memaccess_in_monitor_bfm,
// so output sample N belongs to the same clock cycle as input sample N.
//
// Note the difference from P2's decode_out_monitor_bfm: there the Decode outputs were
// registered and appeared one cycle after enable_decode, so that BFM delayed by one
// cycle. MemAccess is purely combinational, so there is no delay and no qualifying
// enable: every post-reset cycle is a transaction, IDLE cycles included.
//
// Reset cycles are NOT checked. MemAccess has no reset; while reset is high the BFM
// only tells the monitor to restart its cycle numbering, in step with
// memaccess_in_monitor.
interface memaccess_out_monitor_bfm (memaccess_out_if bus);

  memaccess_out_pkg::memaccess_out_monitor proxy;

  tri        clock_i;
  tri        reset_i;
  tri [15:0] Data_addr_i;
  tri [15:0] Data_din_i;
  tri        Data_rd_i;
  tri [15:0] memout_i;
  assign clock_i     = bus.clock;
  assign reset_i     = bus.reset;
  assign Data_addr_i = bus.Data_addr;
  assign Data_din_i  = bus.Data_din;
  assign Data_rd_i   = bus.Data_rd;
  assign memout_i    = bus.memout;

  task start_monitoring();
    forever begin
      @(posedge clock_i);
      if (reset_i !== 1'b1)
        proxy.notify_transaction(Data_addr_i, Data_din_i, Data_rd_i, memout_i);
      else
        proxy.notify_reset();   // restart cycle numbering; no check
    end
  endtask

endinterface : memaccess_out_monitor_bfm
