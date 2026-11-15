// hdl_top - execute block bench
// Same layout as the control and decode benches: clock/reset, tri nets, interfaces + BFMs,
// the DUT, and uvm_config_db registration of the BFM handles.
// DUT = Execute from LC3_veloce_encrypted. Its port is called npc; the model calls it npc_in.
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

  // Execute inputs
  tri        enable_execute;
  tri [5:0]  E_Control;
  tri [15:0] IR;
  tri [15:0] npc_in;
  tri        bypass_alu_1;
  tri        bypass_alu_2;
  tri        bypass_mem_1;
  tri        bypass_mem_2;
  tri [15:0] VSR1;
  tri [15:0] VSR2;
  tri [15:0] Mem_Bypass_Val;
  tri [1:0]  W_Control_in;
  tri        Mem_Control_in;
  // Execute outputs
  tri [15:0] aluout;
  tri [15:0] pcout;
  tri [1:0]  W_Control_out;
  tri        Mem_Control_out;
  tri [2:0]  dr;
  tri [2:0]  sr1;
  tri [2:0]  sr2;
  tri [15:0] IR_Exec;
  tri [2:0]  NZP;
  tri [15:0] M_Data;

  execute_in_if execute_in_if_i (
    .clock(clock), .reset(reset),
    .enable_execute(enable_execute), .E_Control(E_Control), .IR(IR), .npc_in(npc_in),
    .bypass_alu_1(bypass_alu_1), .bypass_alu_2(bypass_alu_2),
    .bypass_mem_1(bypass_mem_1), .bypass_mem_2(bypass_mem_2),
    .VSR1(VSR1), .VSR2(VSR2), .Mem_Bypass_Val(Mem_Bypass_Val),
    .W_Control_in(W_Control_in), .Mem_Control_in(Mem_Control_in));

  execute_out_if execute_out_if_i (
    .clock(clock), .reset(reset),
    .enable_execute(enable_execute),
    .aluout(aluout), .pcout(pcout), .W_Control_out(W_Control_out), .Mem_Control_out(Mem_Control_out),
    .dr(dr), .sr1(sr1), .sr2(sr2), .IR_Exec(IR_Exec), .NZP(NZP), .M_Data(M_Data));

  execute_in_driver_bfm   execute_in_driver_bfm_i   (execute_in_if_i);
  execute_in_monitor_bfm  execute_in_monitor_bfm_i  (execute_in_if_i);
  execute_out_monitor_bfm execute_out_monitor_bfm_i (execute_out_if_i);

  Execute DUT (
    .clock           (clock),
    .reset           (reset),
    .E_Control       (E_Control),
    .bypass_alu_1    (bypass_alu_1),
    .bypass_alu_2    (bypass_alu_2),
    .IR              (IR),
    .npc             (npc_in),
    .W_Control_in    (W_Control_in),
    .Mem_Control_in  (Mem_Control_in),
    .VSR1            (VSR1),
    .VSR2            (VSR2),
    .enable_execute  (enable_execute),
    .Mem_Bypass_Val  (Mem_Bypass_Val),
    .bypass_mem_1    (bypass_mem_1),
    .bypass_mem_2    (bypass_mem_2),
    .W_Control_out   (W_Control_out),
    .Mem_Control_out (Mem_Control_out),
    .NZP             (NZP),
    .IR_Exec         (IR_Exec),
    .aluout          (aluout),
    .pcout           (pcout),
    .sr1             (sr1),
    .sr2             (sr2),
    .dr              (dr),
    .M_Data          (M_Data)
  );

  initial begin
    uvm_config_db #(virtual execute_in_driver_bfm  )::set(null, "*", "execute_in_if",  execute_in_driver_bfm_i);
    uvm_config_db #(virtual execute_in_monitor_bfm )::set(null, "*", "execute_in_if",  execute_in_monitor_bfm_i);
    uvm_config_db #(virtual execute_out_monitor_bfm)::set(null, "*", "execute_out_if", execute_out_monitor_bfm_i);
  end
endmodule : hdl_top
