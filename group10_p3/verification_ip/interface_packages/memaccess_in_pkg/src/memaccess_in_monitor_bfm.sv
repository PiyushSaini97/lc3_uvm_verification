interface memaccess_in_monitor_bfm (
    memaccess_in_if bus
);
  memaccess_in_pkg::memaccess_in_monitor proxy;
  bit                                    started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "LC3 invalid monitor startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      if (bus.monitor_cb.reset === 1'b0)
        proxy.notify_transaction(bus.monitor_cb.mem_state, bus.monitor_cb.M_Control, bus.monitor_cb.M_Data,
                                 bus.monitor_cb.M_Addr, bus.monitor_cb.Data_dout);
      else proxy.notify_reset();  // restart cycle numbering; nothing sampled or checked
    end
  endtask
endinterface
