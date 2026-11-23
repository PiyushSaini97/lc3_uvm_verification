interface control_in_monitor_bfm (
    control_in_if bus
);
  control_in_pkg::control_in_monitor proxy;
  bit                                started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "LC3 invalid monitor startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      if (bus.monitor_cb.reset === 1'b0)
        proxy.notify_transaction(bus.monitor_cb.complete_data, bus.monitor_cb.complete_instr,
                                 bus.monitor_cb.IR, bus.monitor_cb.psr, bus.monitor_cb.IR_Exec,
                                 bus.monitor_cb.IMem_dout, bus.monitor_cb.NZP);
      else
        proxy.notify_reset(bus.monitor_cb.complete_data, bus.monitor_cb.complete_instr, bus.monitor_cb.IR,
                           bus.monitor_cb.psr, bus.monitor_cb.IR_Exec, bus.monitor_cb.IMem_dout,
                           bus.monitor_cb.NZP);
    end
  endtask
endinterface
