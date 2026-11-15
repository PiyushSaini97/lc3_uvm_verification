// execute_in_driver_bfm
// Used only in the execute block bench. Drives one set of inputs per clock with
// non-blocking assignments right after the rising edge, like P2's decode_in_driver_bfm.
interface execute_in_driver_bfm (
  execute_in_if bus
);
  tri          clock_i;
  tri          reset_i;
  logic        enable_execute_i  = 1'b0;
  logic [5:0]  e_control_i       = '0;
  logic [15:0] ir_i              = '0;
  logic [15:0] npc_in_i          = '0;
  logic        bypass_alu_1_i    = 1'b0;
  logic        bypass_alu_2_i    = 1'b0;
  logic        bypass_mem_1_i    = 1'b0;
  logic        bypass_mem_2_i    = 1'b0;
  logic [15:0] vsr1_i            = '0;
  logic [15:0] vsr2_i            = '0;
  logic [15:0] mem_bypass_val_i  = '0;
  logic [1:0]  w_control_in_i    = '0;
  logic        mem_control_in_i  = 1'b0;

  assign clock_i                = bus.clock;
  assign reset_i                = bus.reset;
  assign bus.enable_execute     = enable_execute_i;
  assign bus.E_Control          = e_control_i;
  assign bus.IR                 = ir_i;
  assign bus.npc_in             = npc_in_i;
  assign bus.bypass_alu_1       = bypass_alu_1_i;
  assign bus.bypass_alu_2       = bypass_alu_2_i;
  assign bus.bypass_mem_1       = bypass_mem_1_i;
  assign bus.bypass_mem_2       = bypass_mem_2_i;
  assign bus.VSR1               = vsr1_i;
  assign bus.VSR2               = vsr2_i;
  assign bus.Mem_Bypass_Val     = mem_bypass_val_i;
  assign bus.W_Control_in       = w_control_in_i;
  assign bus.Mem_Control_in     = mem_control_in_i;

  task assert_enable();
    wait (reset_i == 0);
    @(posedge clock_i);
    enable_execute_i <= 1'b1;
  endtask

  task deassert_enable();
    enable_execute_i <= 1'b0;
  endtask

  task drive(input [5:0] e_control, input [15:0] ir, input [15:0] npc_in,
             input bypass_alu_1, input bypass_alu_2, input bypass_mem_1, input bypass_mem_2,
             input [15:0] vsr1, input [15:0] vsr2, input [15:0] mem_bypass_val,
             input [1:0] w_control_in, input mem_control_in);
    e_control_i      <= e_control;
    ir_i             <= ir;
    npc_in_i         <= npc_in;
    bypass_alu_1_i   <= bypass_alu_1;
    bypass_alu_2_i   <= bypass_alu_2;
    bypass_mem_1_i   <= bypass_mem_1;
    bypass_mem_2_i   <= bypass_mem_2;
    vsr1_i           <= vsr1;
    vsr2_i           <= vsr2;
    mem_bypass_val_i <= mem_bypass_val;
    w_control_in_i   <= w_control_in;
    mem_control_in_i <= mem_control_in;
    @(posedge clock_i);
  endtask
endinterface : execute_in_driver_bfm
