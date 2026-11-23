interface writeback_in_monitor_bfm (
    writeback_in_if bus
);
  timeunit 1ns; timeprecision 1ps;
  writeback_in_pkg::writeback_in_monitor proxy;
  bit                                    started = 0;
  longint unsigned                       cycle_id = 0;

  task start_monitoring();
    if (started) $fatal(1, "writeback_in: monitor started twice");
    if (proxy == null) $fatal(1, "writeback_in: null monitor proxy");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      // Publish every edge, including reset and disabled cycles.
      proxy.notify_transaction(cycle_id, $time, bus.monitor_cb.reset, bus.monitor_cb.enable_writeback,
                               bus.monitor_cb.W_Control, bus.monitor_cb.aluout, bus.monitor_cb.npc,
                               bus.monitor_cb.pcout, bus.monitor_cb.memout, bus.monitor_cb.sr1,
                               bus.monitor_cb.sr2, bus.monitor_cb.dr);
      cycle_id++;
    end
  endtask
endinterface
