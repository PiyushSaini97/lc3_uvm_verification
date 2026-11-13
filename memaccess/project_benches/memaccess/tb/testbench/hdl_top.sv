// hdl_top - memaccess block bench
// Same layout as the P2 decoder bench and the control block bench: clock/reset,
// tri nets, interfaces + BFMs, the DUT, and uvm_config_db registration of the BFM
// handles.
//
// DUT = MemAccess from LC3_veloce_encrypted/Mem_Access.v (ports from its plaintext
// header). The block itself has no clock or reset port: it is purely combinational.
// The clock here exists so the monitors have a sampling edge and so the bench looks
// the same as every other stage's bench; reset only holds the monitors off until the
// driver has put defined values on the nets.
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

  // MemAccess inputs
  tri [1:0]  mem_state;
  tri        M_Control;
  tri [15:0] M_Data;
  tri [15:0] M_Addr;
  tri [15:0] Data_dout;
  // MemAccess outputs
  tri [15:0] Data_addr;
  tri [15:0] Data_din;
  tri        Data_rd;
  tri [15:0] memout;

  memaccess_in_if memaccess_in_if_i (
    .clock(clock), .reset(reset),
    .mem_state(mem_state), .M_Control(M_Control),
    .M_Data(M_Data), .M_Addr(M_Addr), .Data_dout(Data_dout));

  memaccess_out_if memaccess_out_if_i (
    .clock(clock), .reset(reset),
    .Data_addr(Data_addr), .Data_din(Data_din),
    .Data_rd(Data_rd), .memout(memout));

  memaccess_in_driver_bfm   memaccess_in_driver_bfm_i   (memaccess_in_if_i);
  memaccess_in_monitor_bfm  memaccess_in_monitor_bfm_i  (memaccess_in_if_i);
  memaccess_out_monitor_bfm memaccess_out_monitor_bfm_i (memaccess_out_if_i);

  MemAccess DUT (
    .mem_state (mem_state),
    .M_Control (M_Control),
    .M_Data    (M_Data),
    .M_Addr    (M_Addr),
    .Data_dout (Data_dout),
    .memout    (memout),
    .Data_addr (Data_addr),
    .Data_din  (Data_din),
    .Data_rd   (Data_rd)
  );

  initial begin
    uvm_config_db #(virtual memaccess_in_driver_bfm  )::set(null, "*", "memaccess_in_if",  memaccess_in_driver_bfm_i);
    uvm_config_db #(virtual memaccess_in_monitor_bfm )::set(null, "*", "memaccess_in_if",  memaccess_in_monitor_bfm_i);
    uvm_config_db #(virtual memaccess_out_monitor_bfm)::set(null, "*", "memaccess_out_if", memaccess_out_monitor_bfm_i);
  end
endmodule : hdl_top
