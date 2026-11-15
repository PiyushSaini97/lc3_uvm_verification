// execute_in_monitor_bfm
// Samples the Execute inputs on every rising edge where enable_execute is high and reset
// is low. Reading at @(posedge) gives the values that were stable during the cycle that
// just ended, because the RTL registers update through non-blocking assignments later in
// the same time step. execute_out_monitor_bfm samples one edge later (outputs are
// registered), so input sample N pairs with output sample N.
interface execute_in_monitor_bfm (execute_in_if bus);

  execute_in_pkg::execute_in_monitor proxy;

  tri        clock_i;
  tri        reset_i;
  tri        enable_execute_i;
  tri [5:0]  e_control_i;
  tri [15:0] ir_i;
  tri [15:0] npc_in_i;
  tri        bypass_alu_1_i, bypass_alu_2_i, bypass_mem_1_i, bypass_mem_2_i;
  tri [15:0] vsr1_i, vsr2_i, mem_bypass_val_i;
  tri [1:0]  w_control_in_i;
  tri        mem_control_in_i;

  assign clock_i          = bus.clock;
  assign reset_i          = bus.reset;
  assign enable_execute_i = bus.enable_execute;
  assign e_control_i      = bus.E_Control;
  assign ir_i             = bus.IR;
  assign npc_in_i         = bus.npc_in;
  assign bypass_alu_1_i   = bus.bypass_alu_1;
  assign bypass_alu_2_i   = bus.bypass_alu_2;
  assign bypass_mem_1_i   = bus.bypass_mem_1;
  assign bypass_mem_2_i   = bus.bypass_mem_2;
  assign vsr1_i           = bus.VSR1;
  assign vsr2_i           = bus.VSR2;
  assign mem_bypass_val_i = bus.Mem_Bypass_Val;
  assign w_control_in_i   = bus.W_Control_in;
  assign mem_control_in_i = bus.Mem_Control_in;

  task start_monitoring();
    forever begin
      @(posedge clock_i);
      if ((enable_execute_i === 1'b1) && (reset_i !== 1'b1))
        proxy.notify_transaction(e_control_i, ir_i, npc_in_i,
                                 bypass_alu_1_i, bypass_alu_2_i, bypass_mem_1_i, bypass_mem_2_i,
                                 vsr1_i, vsr2_i, mem_bypass_val_i,
                                 w_control_in_i, mem_control_in_i);
    end
  endtask
endinterface : execute_in_monitor_bfm
