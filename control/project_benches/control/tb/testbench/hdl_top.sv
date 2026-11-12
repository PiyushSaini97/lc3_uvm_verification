// hdl_top - control block bench
// Same layout as the P2 decoder bench: clock/reset, tri nets, interfaces + BFMs,
// the DUT, and uvm_config_db registration of the BFM handles.
// DUT = Controller_Pipeline from LC3_veloce_encrypted (ports from its plaintext header).
module hdl_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  bit clock;
  bit reset;
  initial clock = 1'b0;
  always #5 clock = ~clock;
  initial begin
    reset = 1'b1;
    #22 reset = 1'b0;
  end

  // Controller inputs
  tri        complete_data;
  tri        complete_instr;
  tri [15:0] IR;
  tri [2:0]  psr;
  tri [15:0] IR_Exec;
  tri [15:0] Instr_dout;
  tri [2:0]  NZP;
  // Controller outputs
  tri        enable_updatePC;
  tri        enable_fetch;
  tri        enable_decode;
  tri        enable_execute;
  tri        enable_writeback;
  tri        bypass_alu_1;
  tri        bypass_alu_2;
  tri        bypass_mem_1;
  tri        bypass_mem_2;
  tri [1:0]  mem_state;
  tri        br_taken;

  control_in_if control_in_if_i (
    .clock(clock), .reset(reset),
    .complete_data(complete_data), .complete_instr(complete_instr),
    .IR(IR), .psr(psr), .IR_Exec(IR_Exec), .IMem_dout(Instr_dout), .NZP(NZP));

  control_out_if control_out_if_i (
    .clock(clock), .reset(reset),
    .enable_updatePC(enable_updatePC), .enable_fetch(enable_fetch),
    .enable_decode(enable_decode), .enable_execute(enable_execute),
    .enable_writeback(enable_writeback),
    .bypass_alu_1(bypass_alu_1), .bypass_alu_2(bypass_alu_2),
    .bypass_mem_1(bypass_mem_1), .bypass_mem_2(bypass_mem_2),
    .mem_state(mem_state), .br_taken(br_taken));

  // The driver BFM also gets the output bundle: it reacts to the controller's enables
  // the way Decode/Execute/Writeback and the memories would.
  control_in_driver_bfm   control_in_driver_bfm_i   (control_in_if_i, control_out_if_i);
  control_in_monitor_bfm  control_in_monitor_bfm_i  (control_in_if_i);
  control_out_monitor_bfm control_out_monitor_bfm_i (control_out_if_i);

  Controller_Pipeline DUT (
    .clock            (clock),
    .reset            (reset),
    .IR               (IR),
    .bypass_alu_1     (bypass_alu_1),
    .bypass_alu_2     (bypass_alu_2),
    .bypass_mem_1     (bypass_mem_1),
    .bypass_mem_2     (bypass_mem_2),
    .complete_data    (complete_data),
    .complete_instr   (complete_instr),
    .Instr_dout       (Instr_dout),
    .NZP              (NZP),
    .psr              (psr),
    .IR_Exec          (IR_Exec),
    .enable_fetch     (enable_fetch),
    .enable_decode    (enable_decode),
    .enable_execute   (enable_execute),
    .enable_writeback (enable_writeback),
    .enable_updatePC  (enable_updatePC),
    .br_taken         (br_taken),
    .mem_state        (mem_state)
  );

  initial begin
    uvm_config_db #(virtual control_in_driver_bfm  )::set(null, "*", "control_in_if",  control_in_driver_bfm_i);
    uvm_config_db #(virtual control_in_monitor_bfm )::set(null, "*", "control_in_if",  control_in_monitor_bfm_i);
    uvm_config_db #(virtual control_out_monitor_bfm)::set(null, "*", "control_out_if", control_out_monitor_bfm_i);
  end
endmodule : hdl_top
