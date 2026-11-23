interface dmem_monitor_bfm (
    dmem_if bus
);
  dmem_pkg::dmem_monitor proxy;
  bit started = 0, pending = 0;
  logic [15:0] saved_address, saved_write_data;
  logic saved_read;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "Memory monitor invalid startup");
    started = 1;
    fork
      forever begin
        @(bus.request_cb);
        if (bus.request_cb.reset !== 0) pending = 0;
        else if (!pending && bus.request_cb.request === 1) begin
          saved_address    = bus.request_cb.address;
          saved_read       = bus.request_cb.read;
          saved_write_data = bus.request_cb.write_data;
          pending          = 1;
        end
      end
      forever begin
        @(bus.monitor_cb);
        if (bus.monitor_cb.reset !== 0) pending = 0;
        else if (bus.monitor_cb.complete === 1) begin
          if (!pending)
            $fatal(
                1,
                "DMEM completion without pending request: request=%b saved_addr=%h current_addr=%h complete=%b",
                bus.monitor_cb.request,
                saved_address,
                bus.monitor_cb.address,
                bus.monitor_cb.complete
            );
          if ($isunknown(saved_read ? bus.monitor_cb.read_data : saved_write_data))
            $fatal(1, "Unknown completed memory data");
          proxy.notify_transaction(saved_address, saved_read,
                                   saved_read ? bus.monitor_cb.read_data : saved_write_data);
          pending = 0;
        end
      end
    join
  endtask
endinterface
