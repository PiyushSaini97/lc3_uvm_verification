// control_out_if
// Signal bundle for the controller's outputs (LC3 Design Spec, CONTROLLER section).
// `input` ports for the same reason as control_in_if: passive, hierarchically wired.
interface control_out_if (
    input wire       clock,
    input wire       reset,
    input tri        enable_updatePC,
    input tri        enable_fetch,
    input tri        enable_decode,
    input tri        enable_execute,
    input tri        enable_writeback,
    input tri        bypass_alu_1,
    input tri        bypass_alu_2,
    input tri        bypass_mem_1,
    input tri        bypass_mem_2,
    input tri  [1:0] mem_state,
    input tri        br_taken
);
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input reset;
    input enable_updatePC;
    input enable_fetch;
    input enable_decode;
    input enable_execute;
    input enable_writeback;
    input bypass_alu_1;
    input bypass_alu_2;
    input bypass_mem_1;
    input bypass_mem_2;
    input mem_state;
    input br_taken;
  endclocking
endinterface
