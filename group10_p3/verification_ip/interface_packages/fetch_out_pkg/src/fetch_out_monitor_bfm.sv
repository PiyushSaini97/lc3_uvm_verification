interface fetch_out_monitor_bfm (
    fetch_out_if bus
);
  fetch_out_pkg::fetch_out_monitor proxy;
  bit                              started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "fetch BFM invalid startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      proxy.notify_transaction(bus.monitor_cb.reset, bus.monitor_cb.pc, bus.monitor_cb.npc,
                               bus.monitor_cb.instrmem_rd);
    end
  endtask
endinterface
