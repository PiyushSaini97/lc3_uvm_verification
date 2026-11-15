// execute_out_monitor_bfm
// The Execute outputs are registered: they change after the clock edge where
// enable_execute was high. Sampling at the NEXT rising edge therefore sees the result of
// the previous edge's inputs, so output sample N pairs with execute_in_monitor_bfm
// sample N. Same idea as P2's decode_out_monitor_bfm (enable_d1).
//
// sr1 and sr2 are combinational functions of IR, not registers. They are latched at the
// enable edge (sr1_d1, sr2_d1) so they describe the same instruction as the registered
// outputs.
interface execute_out_monitor_bfm (execute_out_if bus);

  execute_out_pkg::execute_out_monitor proxy;

  tri        clock_i;
  tri        reset_i;
  tri        enable_execute_i;
  tri [15:0] aluout_i;
  tri [15:0] pcout_i;
  tri [1:0]  w_control_out_i;
  tri        mem_control_out_i;
  tri [2:0]  dr_i;
  tri [2:0]  sr1_i;
  tri [2:0]  sr2_i;
  tri [15:0] ir_exec_i;
  tri [2:0]  nzp_i;
  tri [15:0] m_data_i;

  assign clock_i           = bus.clock;
  assign reset_i           = bus.reset;
  assign enable_execute_i  = bus.enable_execute;
  assign aluout_i          = bus.aluout;
  assign pcout_i           = bus.pcout;
  assign w_control_out_i   = bus.W_Control_out;
  assign mem_control_out_i = bus.Mem_Control_out;
  assign dr_i              = bus.dr;
  assign sr1_i             = bus.sr1;
  assign sr2_i             = bus.sr2;
  assign ir_exec_i         = bus.IR_Exec;
  assign nzp_i             = bus.NZP;
  assign m_data_i          = bus.M_Data;

  logic       enable_d1 = 1'b0;
  logic       reset_d1  = 1'b1;
  logic [2:0] sr1_d1;
  logic [2:0] sr2_d1;

  task start_monitoring();
    forever begin
      @(posedge clock_i);
      if ((enable_d1 === 1'b1) && (reset_d1 !== 1'b1))
        proxy.notify_transaction(aluout_i, pcout_i, w_control_out_i, mem_control_out_i,
                                 dr_i, sr1_d1, sr2_d1, ir_exec_i, nzp_i, m_data_i);
      enable_d1 <= (enable_execute_i === 1'b1);
      reset_d1  <= (reset_i === 1'b1);
      sr1_d1    <= sr1_i;
      sr2_d1    <= sr2_i;
    end
  endtask
endinterface : execute_out_monitor_bfm
