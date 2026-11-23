interface dmem_if (
    input wire        clock,
    input wire        reset,
    inout tri         request,
    inout tri         read,
    inout tri  [15:0] address,
    inout tri  [15:0] write_data,
    inout tri  [15:0] read_data,
    inout tri         complete
);
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input reset, request, read, address, write_data, read_data, complete;
  endclocking
  clocking request_cb @(negedge clock);
    default input #1step;
    input reset, request, read, address, write_data;
  endclocking
endinterface
