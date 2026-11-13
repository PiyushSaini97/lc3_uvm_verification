// memaccess_in_coverage
// Functional coverage of the MemAccess INPUT space.
//
// What this is aiming at, in order of importance:
//   1. Every memory FSM state, and every state crossed with M_Control. M_Control is
//      what selects the address source, so (state, M_Control) is the block's real
//      control space: 8 combinations, of which 6 are meaningful.
//   2. The whole-instruction FSM sequences. MemAccess is combinational and cannot
//      tell one instruction from another, but the Controller walks it through a
//      fixed sequence per instruction class, and the transition bins prove those
//      sequences were actually exercised:
//        3->0->3     LD / LDR      (one read)
//        3->2->3     ST / STR      (one write)
//        3->1->0->3  LDI           (read the pointer, then read the data)
//        3->1->2->3  STI           (read the pointer, then write the data)
//      The repetition ranges allow memory wait states, during which the Controller
//      holds the state.
//   3. Corner values on the three 16-bit ports, so address and data paths are not
//      only exercised with mid-range random values.
class memaccess_in_coverage extends uvm_subscriber #(memaccess_in_transaction);
  `uvm_component_utils(memaccess_in_coverage)

  memaccess_in_transaction cov;

  covergroup memaccess_in_cg;
    option.per_instance = 1;
    option.name         = "memaccess_in_cg";
    option.comment      = "MemAccess input control space and FSM sequences";

    state : coverpoint cov.mem_state {
      bins rd_direct   = {2'd0};
      bins rd_indirect = {2'd1};
      bins write       = {2'd2};
      bins idle        = {2'd3};
    }

    control : coverpoint cov.M_Control {
      bins direct   = {1'b0};   // address comes from M_Addr
      bins indirect = {1'b1};   // address comes from Data_dout (the pointer just read)
    }

    // Only the active states are crossed: in IDLE the block drives nothing, so
    // M_Control is a don't-care there and an uncovered bin would be noise.
    state_x_control : cross state, control {
      ignore_bins idle_dontcare = binsof(state.idle);
    }

    // Whole-instruction sequences through the memory FSM. [*1:8] absorbs wait states.
    fsm_sequence : coverpoint cov.mem_state {
      bins ld_ldr = (2'd3 => 2'd0[*1:8] => 2'd3);
      bins st_str = (2'd3 => 2'd2[*1:8] => 2'd3);
      bins ldi    = (2'd3 => 2'd1[*1:8] => 2'd0[*1:8] => 2'd3);
      bins sti    = (2'd3 => 2'd1[*1:8] => 2'd2[*1:8] => 2'd3);
    }

    addr : coverpoint cov.M_Addr {
      bins zero    = {16'h0000};
      bins max     = {16'hFFFF};
      bins low     = {[16'h0001:16'h7FFF]};
      bins high    = {[16'h8000:16'hFFFE]};
    }

    wdata : coverpoint cov.M_Data {
      bins zero = {16'h0000};
      bins max  = {16'hFFFF};
      bins low  = {[16'h0001:16'h7FFF]};
      bins high = {[16'h8000:16'hFFFE]};
    }

    // The word coming back from memory. In RD_INDIRECT it is the pointer that
    // becomes the next access's address, so its corner values matter.
    rdata : coverpoint cov.Data_dout {
      bins zero = {16'h0000};
      bins max  = {16'hFFFF};
      bins low  = {[16'h0001:16'h7FFF]};
      bins high = {[16'h8000:16'hFFFE]};
    }

    // An indirect access whose pointer is a corner value: the address the block
    // forwards is then 0x0000 or 0xFFFF.
    indirect_ptr : cross control, rdata {
      ignore_bins direct_only = binsof(control.direct);
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    memaccess_in_cg = new();
  endfunction

  virtual function void write(memaccess_in_transaction t);
    cov = t;
    memaccess_in_cg.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("memaccess_in coverage = %0.2f%%", memaccess_in_cg.get_inst_coverage()),
              UVM_LOW)
  endfunction
endclass : memaccess_in_coverage
