// control_in_driver_bfm
// ACTIVE driver for the control block bench. Emulation-friendly (synthesizable-style
// always blocks + tasks called by the class driver), like P2's decode_in_driver_bfm.
//
// WHY THIS DRIVER IS REACTIVE
// ---------------------------
// Unlike decode_in, the controller's inputs are not independent stimulus. In the LC3:
//   Instr_dout = instruction memory. SYNCHRONOUS: the word at the PC of cycle t
//                appears on Instr_dout in cycle t+1, if enable_fetch was high in t
//                (Design Spec timing diagrams: PC=3000 in cycle 0 -> Imem[PC]=5020
//                in cycle 1; this is also the FE1/FE2 split in controller_model).
//                The PC advances at edges where enable_updatePC is high.
//   IR         = Decode's register,  loaded from Instr_dout when enable_decode
//   IR_Exec    = Execute's register, loaded from IR when enable_execute
//   NZP        = Execute's register, BR: IR[11:9], JMP: 111, else 000 (when
//                enable_execute); goes to 000 when enable_execute is low (Design Spec)
//   psr        = Writeback's flags,  updated on each register-file write (enable_writeback)
//   complete_data = data memory handshake while the controller's mem_state is busy
// All of these depend on the enables the controller itself produces. Driving them
// independently would create input combinations that cannot occur in the LC3, and the
// scoreboard would report "mismatches" that are not bugs. So this BFM contains a tiny
// model of exactly those registers, clocked by the controller's own outputs (read
// through the control_out_if bundle `fb`).
//
// Only the block bench instantiates this BFM. At LC3 level the real Decode/Execute/
// Writeback and the memory agents drive these nets and the control_in agent is PASSIVE.
interface control_in_driver_bfm (control_in_if bus, control_out_if fb);

  // ---- clock/reset and controller outputs (feedback) ----
  tri       clock_i;
  tri       reset_i;
  tri       enable_updatePC_i;
  tri       enable_fetch_i;
  tri       enable_decode_i;
  tri       enable_execute_i;
  tri       enable_writeback_i;
  tri [1:0] mem_state_i;
  assign clock_i            = bus.clock;
  assign reset_i            = bus.reset;
  assign enable_updatePC_i  = fb.enable_updatePC;
  assign enable_fetch_i     = fb.enable_fetch;
  assign enable_decode_i    = fb.enable_decode;
  assign enable_execute_i   = fb.enable_execute;
  assign enable_writeback_i = fb.enable_writeback;
  assign mem_state_i        = fb.mem_state;

  // ---- controller inputs driven by this BFM ----
  // Instr_dout is preloaded with the first instruction (IMEM[3000]) before reset
  // ends - the spec's startup diagram shows Imem[PC] already valid during reset.
  reg        complete_data_o  = 1'b1;
  reg        complete_instr_o = 1'b1;
  reg [15:0] Instr_dout_o     = 16'h1020;   // ADD R0,R0,#0 until preload()
  reg [15:0] IR_o             = 16'h0000;
  reg [15:0] IR_Exec_o        = 16'h0000;
  reg [2:0]  NZP_o            = 3'b000;
  reg [2:0]  psr_o            = 3'b000;
  assign bus.complete_data  = complete_data_o;
  assign bus.complete_instr = complete_instr_o;
  assign bus.IMem_dout      = Instr_dout_o;
  assign bus.IR             = IR_o;
  assign bus.IR_Exec        = IR_Exec_o;
  assign bus.NZP            = NZP_o;
  assign bus.psr            = psr_o;

  // ---- per-item knobs, written by drive() ----
  int unsigned data_wait_q = 0;
  reg   [2:0]  wb_psr_q    = 3'b010;

  // ---------------------------------------------------------------------------
  // Decode / Execute / Writeback stand-ins (only the controller-visible state).
  // Enables are read at the clock edge (their value during the cycle that just
  // ended), exactly as the real pipeline registers would see them.
  // ---------------------------------------------------------------------------
  function automatic bit [2:0] nzp_of(input logic [15:0] ir);
    case (ir[15:12])
      4'b0000: return ir[11:9];   // BR: condition field
      4'b1100: return 3'b111;     // JMP: unconditional
      default: return 3'b000;     // not a control instruction
    endcase
  endfunction

  always @(posedge clock_i) begin
    if (reset_i === 1'b1) begin
      IR_o      <= 16'h0000;
      IR_Exec_o <= 16'h0000;
      NZP_o     <= 3'b000;
      psr_o     <= 3'b000;
    end
    else begin
      if (enable_decode_i === 1'b1)    IR_o <= Instr_dout_o;
      if (enable_execute_i === 1'b1) begin
        IR_Exec_o <= IR_o;
        NZP_o     <= nzp_of(IR_o);
      end
      else
        NZP_o     <= 3'b000;
      if (enable_writeback_i === 1'b1) psr_o <= wb_psr_q;
    end
  end

  // ---------------------------------------------------------------------------
  // Data-memory stand-in: complete_data handshake.
  // Each memory state (read / indirect read / write) lasts data_wait_q + 1 cycles:
  // complete_data is low for data_wait_q cycles, then high for the completing cycle.
  // When idle, complete_data is pre-set so a zero-wait access completes in its
  // first cycle (1-cycle stall for LD/ST, 2 for LDI/STI, as in the spec).
  // ---------------------------------------------------------------------------
  int unsigned data_cnt = 0;
  always @(posedge clock_i) begin
    if (reset_i === 1'b1) begin
      complete_data_o <= 1'b1;
      data_cnt        <= 0;
    end
    else if (mem_state_i === 2'd3 || complete_data_o === 1'b1) begin
      // Idle, or the current memory state completes at this edge: arm the next one.
      complete_data_o <= (data_wait_q == 0);
      data_cnt        <= data_wait_q;
    end
    else if (data_cnt <= 1)
      complete_data_o <= 1'b1;
    else
      data_cnt <= data_cnt - 1;
  end

  // Instruction memory content at PC 3000 while reset is held.
  task preload(input bit [15:0] instr);
    Instr_dout_o     = instr;
    complete_instr_o = 1'b1;
  endtask

  // Returns when reset has been asserted and released. Does not consume a clock
  // edge, so drive() handles the first post-reset edge itself.
  task wait_for_reset();
    wait (reset_i === 1'b1);
    wait (reset_i === 1'b0);
  endtask

  // ---------------------------------------------------------------------------
  // Instruction-memory stand-in for ONE program-counter value.
  // `instr` is the word stored at the current PC. At every edge where enable_fetch
  // was high, memory returns that word on Instr_dout for the next cycle (synchronous
  // read). The item is finished at the edge where enable_updatePC is high: the PC
  // moves on and the next item becomes the word at the new PC. A taken branch also
  // moves the PC, so the next item is simply the branch target - the controller
  // never sees addresses, only the instruction stream.
  //
  // instr_wait > 0 makes the first instr_wait reads of this PC return with
  // complete_instr low. Off by default: see control_in_stimulus::allow_instr_wait.
  // ---------------------------------------------------------------------------
  task drive(input bit [15:0]   instr,
             input int unsigned instr_wait,
             input int unsigned data_wait,
             input bit [2:0]    wb_psr);
    int unsigned waits_left;
    waits_left  = instr_wait;
    data_wait_q = data_wait;
    wb_psr_q    = wb_psr;
    forever begin
      @(posedge clock_i);
      if (reset_i === 1'b1) continue;
      if (enable_fetch_i === 1'b1) begin
        Instr_dout_o <= instr;
        if (waits_left > 0) begin
          complete_instr_o <= 1'b0;
          waits_left--;
        end
        else
          complete_instr_o <= 1'b1;
      end
      if (enable_updatePC_i === 1'b1) break;
    end
  endtask

endinterface : control_in_driver_bfm
