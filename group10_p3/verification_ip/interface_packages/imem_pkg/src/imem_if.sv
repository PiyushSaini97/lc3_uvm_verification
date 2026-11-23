interface imem_if (
    input wire        clock,
    input wire        reset,
    inout tri         request,
    inout tri         read,
    inout tri  [15:0] address,
    inout tri  [15:0] write_data,
    inout tri  [15:0] read_data,
    inout tri         complete
);
  // Capture the address BEFORE the CPU advances PC at this rising edge.
  clocking request_cb @(posedge clock);
    default input #1step;
    input reset, request, read, address, write_data;
  endclocking
  // The driver makes the response stable at the falling edge. Observe after
  // its update, so it is ready for consumption at the next rising edge.
  clocking monitor_cb @(negedge clock);
    default input #0;
    input reset, request, read, address, write_data, read_data, complete;
  endclocking
endinterface
