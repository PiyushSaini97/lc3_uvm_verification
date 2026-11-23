// hdl_top - LC3 top-level bench
// Same layout as the decoder and control benches: clock/reset, nets, the DUT,
// interfaces + BFMs, and uvm_config_db registration of the BFM handles.
//
// DUT = module LC3 from TopLevelLC3.v (the only unencrypted RTL file).
//
// Who drives what:
//   * Instruction memory and data memory are the only ACTIVE agents (imem/dmem
//     responders). Their driver BFMs drive Instr_dout/complete_instr and
//     Data_dout/complete_data into the LC3 top-level input ports.
//   * Every stage agent (fetch, decode, execute, memaccess, control, writeback) is
//     PASSIVE. Each stage interface is tied to the LC3 top-module nets that connect
//     to that stage's ports, by hierarchical reference (DUT.<net>). Those nets are
//     declared in TopLevelLC3.v, so nothing reaches into an encrypted module.
//
// Clock period is 10 ns (test_top's end-of-test drain assumes it).
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

  // ---------------------------------------------------------------------------
  // LC3 top-level ports
  // ---------------------------------------------------------------------------
  tri [15:0] pc;  // out: instruction address
  tri        instrmem_rd;  // out: instruction read request
  tri [15:0] Instr_dout;  // in : instruction from IMEM (imem driver BFM)
  tri        complete_instr;  // in : IMEM handshake       (imem driver BFM)
  tri [15:0] Data_addr;  // out: data address
  tri [15:0] Data_din;  // out: store data
  tri        Data_rd;  // out: 1 = read, 0 = write
  tri [15:0] Data_dout;  // in : data read back        (dmem driver BFM)
  tri        complete_data;  // in : DMEM handshake        (dmem driver BFM)

  LC3 DUT (
      .clock         (clock),
      .reset         (reset),
      .pc            (pc),
      .instrmem_rd   (instrmem_rd),
      .Instr_dout    (Instr_dout),
      .Data_addr     (Data_addr),
      .complete_instr(complete_instr),
      .complete_data (complete_data),
      .Data_din      (Data_din),
      .Data_dout     (Data_dout),
      .Data_rd       (Data_rd)
  );

  // ---------------------------------------------------------------------------
  // Memory interfaces (ACTIVE responders)
  // ---------------------------------------------------------------------------
  // The instruction memory is read-only: read is tied high, write_data to 0.
  tri        imem_read;
  tri [15:0] imem_write_data;
  assign imem_read       = 1'b1;
  assign imem_write_data = 16'h0000;

  // The LC3 has no data-memory request pin. A data access is in progress whenever
  // the controller's memory FSM is not idle: mem_state 0 = read, 1 = indirect read,
  // 2 = write, 3 = idle (Design Spec, CONTROLLER). 4-state compares keep the request
  // a clean 0 while mem_state is X.
  tri dmem_request;
  assign dmem_request = (DUT.mem_state === 2'd0) || (DUT.mem_state === 2'd1) || (DUT.mem_state === 2'd2);

  imem_if imem_if_i (
      .clock     (clock),
      .reset     (reset),
      .request   (instrmem_rd),
      .read      (imem_read),
      .address   (pc),
      .write_data(imem_write_data),
      .read_data (Instr_dout),
      .complete  (complete_instr)
  );
  imem_driver_bfm imem_driver_bfm_i (imem_if_i);
  imem_monitor_bfm imem_monitor_bfm_i (imem_if_i);

  dmem_if dmem_if_i (
      .clock     (clock),
      .reset     (reset),
      .request   (dmem_request),
      .read      (Data_rd),
      .address   (Data_addr),
      .write_data(Data_din),
      .read_data (Data_dout),
      .complete  (complete_data)
  );
  dmem_driver_bfm dmem_driver_bfm_i (dmem_if_i);
  dmem_monitor_bfm dmem_monitor_bfm_i (dmem_if_i);

  // ---------------------------------------------------------------------------
  // Stage interfaces (PASSIVE monitors), wired to the LC3 top-module nets
  // ---------------------------------------------------------------------------
  // Fetch: taddr is driven by Execute's pcout.
  fetch_in_if fetch_in_if_i (
      .clock          (clock),
      .reset          (reset),
      .enable_updatePC(DUT.enable_updatePC),
      .enable_fetch   (DUT.enable_fetch),
      .br_taken       (DUT.br_taken),
      .taddr          (DUT.pcout)
  );
  fetch_in_monitor_bfm fetch_in_monitor_bfm_i (fetch_in_if_i);

  fetch_out_if fetch_out_if_i (
      .clock      (clock),
      .reset      (reset),
      .pc         (pc),
      .npc        (DUT.npc_out_fetch),
      .instrmem_rd(instrmem_rd)
  );
  fetch_out_monitor_bfm fetch_out_monitor_bfm_i (fetch_out_if_i);

  // Decode: dout is the instruction from memory; npc_in comes from Fetch.
  decode_in_if decode_in_if_i (
      .clock        (clock),
      .reset        (reset),
      .enable_decode(DUT.enable_decode),
      .dout         (Instr_dout),
      .npc_in       (DUT.npc_out_fetch)
  );
  decode_in_monitor_bfm decode_in_monitor_bfm_i (decode_in_if_i);

  decode_out_if decode_out_if_i (
      .clock        (clock),
      .reset        (reset),
      .enable_decode(DUT.enable_decode),
      .IR           (DUT.IR),
      .npc_out      (DUT.npc_out_dec),
      .E_Control    (DUT.E_Control),
      .W_Control    (DUT.W_Control),
      .Mem_Control  (DUT.Mem_Control)
  );
  decode_out_monitor_bfm decode_out_monitor_bfm_i (decode_out_if_i);

  // Execute: Mem_Bypass_Val is MemAccess's memout.
  execute_in_if execute_in_if_i (
      .clock         (clock),
      .reset         (reset),
      .enable_execute(DUT.enable_execute),
      .E_Control     (DUT.E_Control),
      .IR            (DUT.IR),
      .npc_in        (DUT.npc_out_dec),
      .bypass_alu_1  (DUT.bypass_alu_1),
      .bypass_alu_2  (DUT.bypass_alu_2),
      .bypass_mem_1  (DUT.bypass_mem_1),
      .bypass_mem_2  (DUT.bypass_mem_2),
      .VSR1          (DUT.VSR1),
      .VSR2          (DUT.VSR2),
      .Mem_Bypass_Val(DUT.memout),
      .W_Control_in  (DUT.W_Control),
      .Mem_Control_in(DUT.Mem_Control)
  );
  execute_in_monitor_bfm execute_in_monitor_bfm_i (execute_in_if_i);

  execute_out_if execute_out_if_i (
      .clock          (clock),
      .reset          (reset),
      .enable_execute (DUT.enable_execute),
      .aluout         (DUT.aluout),
      .pcout          (DUT.pcout),
      .W_Control_out  (DUT.W_Control_out),
      .Mem_Control_out(DUT.Mem_Control_out),
      .dr             (DUT.dr),
      .sr1            (DUT.sr1),
      .sr2            (DUT.sr2),
      .IR_Exec        (DUT.IR_Exec),
      .NZP            (DUT.NZP),
      .M_Data         (DUT.M_Data)
  );
  execute_out_monitor_bfm execute_out_monitor_bfm_i (execute_out_if_i);

  // MemAccess: M_Control is Execute's Mem_Control_out, M_Addr is pcout.
  memaccess_in_if memaccess_in_if_i (
      .clock    (clock),
      .reset    (reset),
      .mem_state(DUT.mem_state),
      .M_Control(DUT.Mem_Control_out),
      .M_Data   (DUT.M_Data),
      .M_Addr   (DUT.pcout),
      .Data_dout(Data_dout)
  );
  memaccess_in_monitor_bfm memaccess_in_monitor_bfm_i (memaccess_in_if_i);

  memaccess_out_if memaccess_out_if_i (
      .clock    (clock),
      .reset    (reset),
      .Data_addr(Data_addr),
      .Data_din (Data_din),
      .Data_rd  (Data_rd),
      .memout   (DUT.memout)
  );
  memaccess_out_monitor_bfm memaccess_out_monitor_bfm_i (memaccess_out_if_i);

  // Controller: IMem_dout is the RTL's Instr_dout.
  control_in_if control_in_if_i (
      .clock         (clock),
      .reset         (reset),
      .complete_data (complete_data),
      .complete_instr(complete_instr),
      .IR            (DUT.IR),
      .psr           (DUT.psr),
      .IR_Exec       (DUT.IR_Exec),
      .IMem_dout     (Instr_dout),
      .NZP           (DUT.NZP)
  );
  control_in_monitor_bfm control_in_monitor_bfm_i (control_in_if_i);

  control_out_if control_out_if_i (
      .clock           (clock),
      .reset           (reset),
      .enable_updatePC (DUT.enable_updatePC),
      .enable_fetch    (DUT.enable_fetch),
      .enable_decode   (DUT.enable_decode),
      .enable_execute  (DUT.enable_execute),
      .enable_writeback(DUT.enable_writeback),
      .bypass_alu_1    (DUT.bypass_alu_1),
      .bypass_alu_2    (DUT.bypass_alu_2),
      .bypass_mem_1    (DUT.bypass_mem_1),
      .bypass_mem_2    (DUT.bypass_mem_2),
      .mem_state       (DUT.mem_state),
      .br_taken        (DUT.br_taken)
  );
  control_out_monitor_bfm control_out_monitor_bfm_i (control_out_if_i);

  // Writeback: W_Control is Execute's W_Control_out; vsr1/vsr2 are the RF read ports.
  writeback_in_if writeback_in_if_i (
      .clock           (clock),
      .reset           (reset),
      .enable_writeback(DUT.enable_writeback),
      .W_Control       (DUT.W_Control_out),
      .aluout          (DUT.aluout),
      .npc             (DUT.npc_out_dec),
      .pcout           (DUT.pcout),
      .memout          (DUT.memout),
      .sr1             (DUT.sr1),
      .sr2             (DUT.sr2),
      .dr              (DUT.dr)
  );
  writeback_in_monitor_bfm writeback_in_monitor_bfm_i (writeback_in_if_i);

  writeback_out_if writeback_out_if_i (
      .clock(clock),
      .reset(reset),
      .vsr1 (DUT.VSR1),
      .vsr2 (DUT.VSR2),
      .psr  (DUT.psr)
  );
  writeback_out_monitor_bfm writeback_out_monitor_bfm_i (writeback_out_if_i);

  // ---------------------------------------------------------------------------
  // BFM registration. The string keys are the interface names that
  // lc3_env_configuration::initialize() hands to each agent.
  // ---------------------------------------------------------------------------
  initial begin
    uvm_config_db#(virtual imem_driver_bfm)::set(null, "*", "imem_if", imem_driver_bfm_i);
    uvm_config_db#(virtual imem_monitor_bfm)::set(null, "*", "imem_if", imem_monitor_bfm_i);
    uvm_config_db#(virtual dmem_driver_bfm)::set(null, "*", "dmem_if", dmem_driver_bfm_i);
    uvm_config_db#(virtual dmem_monitor_bfm)::set(null, "*", "dmem_if", dmem_monitor_bfm_i);
    uvm_config_db#(virtual fetch_in_monitor_bfm)::set(null, "*", "fetch_in_if", fetch_in_monitor_bfm_i);
    uvm_config_db#(virtual fetch_out_monitor_bfm)::set(null, "*", "fetch_out_if", fetch_out_monitor_bfm_i);
    uvm_config_db#(virtual decode_in_monitor_bfm)::set(null, "*", "decode_in_if", decode_in_monitor_bfm_i);
    uvm_config_db#(virtual decode_out_monitor_bfm)::set(null, "*", "decode_out_if", decode_out_monitor_bfm_i);
    uvm_config_db#(virtual execute_in_monitor_bfm)::set(null, "*", "execute_in_if", execute_in_monitor_bfm_i);
    uvm_config_db#(virtual execute_out_monitor_bfm)::set(null, "*", "execute_out_if",
                                                         execute_out_monitor_bfm_i);
    uvm_config_db#(virtual memaccess_in_monitor_bfm)::set(null, "*", "memaccess_in_if",
                                                          memaccess_in_monitor_bfm_i);
    uvm_config_db#(virtual memaccess_out_monitor_bfm)::set(null, "*", "memaccess_out_if",
                                                           memaccess_out_monitor_bfm_i);
    uvm_config_db#(virtual control_in_monitor_bfm)::set(null, "*", "control_in_if", control_in_monitor_bfm_i);
    uvm_config_db#(virtual control_out_monitor_bfm)::set(null, "*", "control_out_if",
                                                         control_out_monitor_bfm_i);
    uvm_config_db#(virtual writeback_in_monitor_bfm)::set(null, "*", "writeback_in_if",
                                                          writeback_in_monitor_bfm_i);
    uvm_config_db#(virtual writeback_out_monitor_bfm)::set(null, "*", "writeback_out_if",
                                                           writeback_out_monitor_bfm_i);
  end
endmodule : hdl_top
