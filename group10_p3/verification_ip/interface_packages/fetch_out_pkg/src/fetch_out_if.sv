interface fetch_out_if (
    input wire        clock,
    input wire        reset,
    inout tri  [15:0] pc,
    inout tri  [15:0] npc,
    inout tri         instrmem_rd
);
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input reset;
    input #0 pc;
    input #0 npc;
    input instrmem_rd;
  endclocking
endinterface
