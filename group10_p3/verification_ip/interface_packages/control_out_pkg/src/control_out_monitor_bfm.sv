interface control_out_monitor_bfm (
    control_out_if bus
);
  control_out_pkg::control_out_monitor proxy;
  bit                                  started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "LC3 invalid monitor startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      if (bus.monitor_cb.reset === 1'b0)
        proxy.notify_transaction(
            bus.monitor_cb.enable_updatePC, bus.monitor_cb.enable_fetch, bus.monitor_cb.enable_decode,
            bus.monitor_cb.enable_execute, bus.monitor_cb.enable_writeback, bus.monitor_cb.bypass_alu_1,
            bus.monitor_cb.bypass_alu_2, bus.monitor_cb.bypass_mem_1, bus.monitor_cb.bypass_mem_2,
            bus.monitor_cb.mem_state, bus.monitor_cb.br_taken);
      else proxy.notify_reset();  // restart cycle numbering; no check
    end
  endtask
endinterface
