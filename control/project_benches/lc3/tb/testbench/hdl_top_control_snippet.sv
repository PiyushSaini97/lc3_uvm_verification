// ============================================================================
// Paste into project_benches/lc3/tb/testbench/hdl_top.sv  (inside module hdl_top)
// ============================================================================
// Wiring matches the provided RTL (LC3_veloce_encrypted/TopLevelLC3.v):
//   module LC3 ... Controller_Pipeline Ctrl ( ... )
//
// The interfaces connect to the nets of the LC3 TOP module, not to ports of the Ctrl
// instance. TopLevelLC3.v is the only unencrypted file; Controller_Pipeline.v is
// protected, and the simulator may refuse hierarchical access into a protected module.
// Every controller pin is a plain wire (or top-level port) in LC3, connected 1:1 to
// the same-named Ctrl port, so these are exactly the controller's inputs/outputs:
//
//   Ctrl port        LC3 net            source/sink
//   ---------------  -----------------  ---------------------------------
//   IR               IR                 Dec.IR
//   IR_Exec          IR_Exec            Ex.IR_Exec
//   NZP              NZP                Ex.NZP
//   psr              psr                WB.psr
//   Instr_dout       Instr_dout  (port) instruction memory -> LC3
//   complete_instr   complete_instr     (port)
//   complete_data    complete_data      (port)
//   enable_* / bypass_* / mem_state / br_taken : same-named LC3 wires
//
// LC3_TOP_PATH must be the instance name of LC3 in this hdl_top (e.g. "LC3 DUT(...)").
`define LC3_TOP_PATH DUT

  control_in_if control_in_if_i (
    .clock          (clock),
    .reset          (reset),
    .complete_data  (`LC3_TOP_PATH.complete_data),
    .complete_instr (`LC3_TOP_PATH.complete_instr),
    .IR             (`LC3_TOP_PATH.IR),
    .psr            (`LC3_TOP_PATH.psr),
    .IR_Exec        (`LC3_TOP_PATH.IR_Exec),
    .IMem_dout      (`LC3_TOP_PATH.Instr_dout),   // RTL name is Instr_dout; model calls it IMem_dout
    .NZP            (`LC3_TOP_PATH.NZP)
  );
  control_in_monitor_bfm control_in_monitor_bfm_i (control_in_if_i);

  control_out_if control_out_if_i (
    .clock            (clock),
    .reset            (reset),
    .enable_updatePC  (`LC3_TOP_PATH.enable_updatePC),
    .enable_fetch     (`LC3_TOP_PATH.enable_fetch),
    .enable_decode    (`LC3_TOP_PATH.enable_decode),
    .enable_execute   (`LC3_TOP_PATH.enable_execute),
    .enable_writeback (`LC3_TOP_PATH.enable_writeback),
    .bypass_alu_1     (`LC3_TOP_PATH.bypass_alu_1),
    .bypass_alu_2     (`LC3_TOP_PATH.bypass_alu_2),
    .bypass_mem_1     (`LC3_TOP_PATH.bypass_mem_1),
    .bypass_mem_2     (`LC3_TOP_PATH.bypass_mem_2),
    .mem_state        (`LC3_TOP_PATH.mem_state),
    .br_taken         (`LC3_TOP_PATH.br_taken)
  );
  control_out_monitor_bfm control_out_monitor_bfm_i (control_out_if_i);

  // Add to hdl_top's existing uvm_config_db initial block.
  // The string key is the "interface name" that lc3_env_configuration passes down.
  initial begin
    uvm_config_db #(virtual control_in_monitor_bfm )::set(null, "*", "control_in_if",  control_in_monitor_bfm_i);
    uvm_config_db #(virtual control_out_monitor_bfm)::set(null, "*", "control_out_if", control_out_monitor_bfm_i);
  end
