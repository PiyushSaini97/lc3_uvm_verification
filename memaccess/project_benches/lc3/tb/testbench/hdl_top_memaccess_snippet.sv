// ============================================================================
// Paste into project_benches/lc3/tb/testbench/hdl_top.sv  (inside module hdl_top)
// ============================================================================
// Wiring matches the provided RTL (LC3_veloce_encrypted/TopLevelLC3.v):
//   module LC3 ... MemAccess MemAccess ( ... )
//
// Like the control snippet, the interfaces connect to the nets of the LC3 TOP
// module, not to ports of the MemAccess instance. TopLevelLC3.v is the only
// unencrypted file, and the simulator may refuse hierarchical access into a
// protected module.
//
//   MemAccess port   LC3 net            source/sink
//   ---------------  -----------------  ---------------------------------------
//   mem_state        mem_state          Ctrl.mem_state
//   M_Control        Mem_Control_out    Ex.Mem_Control_out      <-- SEE WARNING
//   M_Data           M_Data             Ex.M_Data
//   M_Addr           pcout              Ex.pcout                <-- SEE WARNING
//   Data_dout        Data_dout          LC3 input port  (data memory -> LC3)
//   Data_addr        Data_addr          LC3 output port
//   Data_din         Data_din           LC3 output port
//   Data_rd          Data_rd            LC3 output port
//   memout           memout             -> WB.memout and Ex.Mem_Bypass_Val
//
// WARNING 1 - M_Control is NOT `DUT.M_Control`.
//   TopLevelLC3.v line 29 declares `wire M_Control;` but never connects it to
//   anything: the MemAccess instance takes `.M_Control(Mem_Control_out)`. Wiring
//   this interface to DUT.M_Control would silently sample a floating net (z) and
//   every read/write cycle would mismatch. Use Mem_Control_out.
//
// WARNING 2 - M_Addr is NOT a net called M_Addr.
//   The instance takes `.M_Addr(pcout)`, the Execute stage's pcout output. There is
//   no `M_Addr` net in LC3 to connect to.
//
// LC3_TOP_PATH must be the instance name of LC3 in this hdl_top (e.g. "LC3 DUT(...)").
// If the control snippet already defines it, do not define it twice.
`define LC3_TOP_PATH DUT

  memaccess_in_if memaccess_in_if_i (
    .clock     (clock),
    .reset     (reset),
    .mem_state (`LC3_TOP_PATH.mem_state),
    .M_Control (`LC3_TOP_PATH.Mem_Control_out),  // NOT .M_Control - see WARNING 1
    .M_Data    (`LC3_TOP_PATH.M_Data),
    .M_Addr    (`LC3_TOP_PATH.pcout),            // NOT .M_Addr   - see WARNING 2
    .Data_dout (`LC3_TOP_PATH.Data_dout)
  );
  memaccess_in_monitor_bfm memaccess_in_monitor_bfm_i (memaccess_in_if_i);

  memaccess_out_if memaccess_out_if_i (
    .clock     (clock),
    .reset     (reset),
    .Data_addr (`LC3_TOP_PATH.Data_addr),
    .Data_din  (`LC3_TOP_PATH.Data_din),
    .Data_rd   (`LC3_TOP_PATH.Data_rd),
    .memout    (`LC3_TOP_PATH.memout)
  );
  memaccess_out_monitor_bfm memaccess_out_monitor_bfm_i (memaccess_out_if_i);

  // Add to hdl_top's existing uvm_config_db initial block.
  // The string key is the "interface name" that lc3_env_configuration passes down.
  initial begin
    uvm_config_db #(virtual memaccess_in_monitor_bfm )::set(null, "*", "memaccess_in_if",  memaccess_in_monitor_bfm_i);
    uvm_config_db #(virtual memaccess_out_monitor_bfm)::set(null, "*", "memaccess_out_if", memaccess_out_monitor_bfm_i);
  end
