interface memaccess_out_monitor_bfm (
    memaccess_out_if bus
);
  memaccess_out_pkg::memaccess_out_monitor proxy;
  bit                                      started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "LC3 invalid monitor startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      if (bus.monitor_cb.reset === 1'b0)
        proxy.notify_transaction(bus.monitor_cb.Data_addr, bus.monitor_cb.Data_din, bus.monitor_cb.Data_rd,
                                 bus.monitor_cb.memout);
      else proxy.notify_reset();  // restart cycle numbering; no check
    end
  endtask
endinterface
