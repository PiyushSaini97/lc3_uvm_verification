interface execute_out_monitor_bfm (
    execute_out_if bus
);
  execute_out_pkg::execute_out_monitor proxy;
  bit                                  started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "LC3 invalid monitor startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      if (bus.monitor_cb.reset === 0 && bus.monitor_cb.enable_execute === 1)
        proxy.notify_transaction(bus.monitor_cb.aluout, bus.monitor_cb.pcout, bus.monitor_cb.W_Control_out,
                                 bus.monitor_cb.Mem_Control_out, bus.monitor_cb.dr, bus.monitor_cb.sr1,
                                 bus.monitor_cb.sr2, bus.monitor_cb.IR_Exec, bus.monitor_cb.NZP,
                                 bus.monitor_cb.M_Data);
    end
  endtask
endinterface
