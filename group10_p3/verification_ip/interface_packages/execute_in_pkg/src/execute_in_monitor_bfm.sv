interface execute_in_monitor_bfm (
    execute_in_if bus
);
  execute_in_pkg::execute_in_monitor proxy;
  bit                                started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "LC3 invalid monitor startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      if ((bus.monitor_cb.enable_execute === 1'b1) && (bus.monitor_cb.reset === 1'b0))
        proxy.notify_transaction(bus.monitor_cb.E_Control, bus.monitor_cb.IR, bus.monitor_cb.npc_in,
                                 bus.monitor_cb.bypass_alu_1, bus.monitor_cb.bypass_alu_2,
                                 bus.monitor_cb.bypass_mem_1, bus.monitor_cb.bypass_mem_2,
                                 bus.monitor_cb.VSR1, bus.monitor_cb.VSR2, bus.monitor_cb.Mem_Bypass_Val,
                                 bus.monitor_cb.W_Control_in, bus.monitor_cb.Mem_Control_in);
    end
  endtask
endinterface
