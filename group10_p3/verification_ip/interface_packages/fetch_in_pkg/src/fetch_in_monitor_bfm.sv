interface fetch_in_monitor_bfm (
    fetch_in_if bus
);
  fetch_in_pkg::fetch_in_monitor proxy;
  bit                            started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "fetch BFM invalid startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      proxy.notify_transaction(bus.monitor_cb.reset, bus.monitor_cb.enable_updatePC,
                               bus.monitor_cb.enable_fetch, bus.monitor_cb.br_taken, bus.monitor_cb.taddr);
    end
  endtask
endinterface
