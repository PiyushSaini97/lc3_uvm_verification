// memaccess_in_driver_bfm
// Emulation-friendly driver BFM (same split-transaction style as P2): plain data
// types on the task API, no class handles, no UVM.
//
// Used ONLY by the memaccess block bench, where the memaccess_in agent is ACTIVE.
// At LC3 level nothing instantiates this interface, but it is still compiled,
// because memaccess_in_configuration declares a `virtual memaccess_in_driver_bfm`
// handle (same situation as decode_in_driver_bfm and control_in_driver_bfm).
//
// TIMING: drive() consumes exactly one clock. It assigns with non-blocking
// assignments at a rising edge, so the new values are stable through the cycle that
// follows and are what both monitors sample at the NEXT rising edge. One item in
// gives one compared cycle out.
//
// Out of reset the nets idle at mem_state = 3 (IDLE), which is the state in which
// MemAccess drives no memory bus.
interface memaccess_in_driver_bfm (memaccess_in_if bus);

  tri clock_i;
  tri reset_i;
  assign clock_i = bus.clock;
  assign reset_i = bus.reset;

  logic [1:0]  mem_state_o;
  logic        M_Control_o;
  logic [15:0] M_Data_o;
  logic [15:0] M_Addr_o;
  logic [15:0] Data_dout_o;

  assign bus.mem_state = mem_state_o;
  assign bus.M_Control = M_Control_o;
  assign bus.M_Data    = M_Data_o;
  assign bus.M_Addr    = M_Addr_o;
  assign bus.Data_dout = Data_dout_o;

  initial begin
    mem_state_o = 2'd3;      // IDLE
    M_Control_o = 1'b0;
    M_Data_o    = 16'h0000;
    M_Addr_o    = 16'h0000;
    Data_dout_o = 16'h0000;
  end

  task drive ( input bit [1:0]  mem_state,
               input bit        M_Control,
               input bit [15:0] M_Data,
               input bit [15:0] M_Addr,
               input bit [15:0] Data_dout );

    while ( reset_i !== 1'b0 ) @(posedge clock_i);

    @(posedge clock_i);
    mem_state_o <= mem_state;
    M_Control_o <= M_Control;
    M_Data_o    <= M_Data;
    M_Addr_o    <= M_Addr;
    Data_dout_o <= Data_dout;

  endtask

endinterface : memaccess_in_driver_bfm
