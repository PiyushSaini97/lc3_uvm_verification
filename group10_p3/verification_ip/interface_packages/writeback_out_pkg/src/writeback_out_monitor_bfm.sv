interface writeback_out_monitor_bfm (
    writeback_out_if bus
);
  timeunit 1ns; timeprecision 1ps;
  writeback_out_pkg::writeback_out_monitor proxy;
  bit                                      started = 0;
  longint unsigned                         cycle_id = 0;

  task start_monitoring();
    if (started) $fatal(1, "writeback_out: monitor started twice");
    if (proxy == null) $fatal(1, "writeback_out: null monitor proxy");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      // Publish every edge, including reset and disabled cycles.
      proxy.notify_transaction(cycle_id, $time, bus.monitor_cb.reset, bus.monitor_cb.vsr1,
                               bus.monitor_cb.vsr2, bus.monitor_cb.psr);
      cycle_id++;
    end
  endtask
endinterface
