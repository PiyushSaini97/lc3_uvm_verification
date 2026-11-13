// memaccess_in_fsm_sequence
// Walks the memory FSM the way the LC3 Controller does, one whole memory operation
// at a time, so the fsm_sequence transition bins in memaccess_in_coverage close.
//
// The four operation shapes (LC3 Design Spec, memory states):
//
//   LD / LDR   M_Control=0   3 -> 0 -> 3        one direct read
//   ST / STR   M_Control=0   3 -> 2 -> 3        one direct write
//   LDI        M_Control=1   3 -> 1 -> 0 -> 3   read the pointer, then read the data
//   STI        M_Control=1   3 -> 1 -> 2 -> 3   read the pointer, then write the data
//
// M_Control is a property of the instruction, not of the cycle: it stays high for
// the whole of an LDI/STI. State 1 ignores it (mem_access_model takes the address
// from M_Addr there unconditionally); it matters in the second access, where the
// address must come from Data_dout instead.
//
// Each state is held for a random 1 to 3 cycles. That is what a data-memory wait
// state looks like from here: the Controller keeps mem_state until complete_data
// goes high, and MemAccess must drive the same outputs for every cycle of the wait.
//
// Data_dout stays random from cycle to cycle rather than holding the pointer that
// state 1 "read". MemAccess is combinational and simply forwards whatever is on
// Data_dout in the cycle being checked, so re-randomizing covers more of the address
// path than replaying a stored value would.
class memaccess_in_fsm_sequence extends memaccess_in_sequence_base;
  `uvm_object_utils(memaccess_in_fsm_sequence)

  // Longest hold, in cycles, for any one state. Must stay within the [*1:8]
  // repetition range used by the fsm_sequence coverpoint.
  int unsigned max_wait = 3;

  function new(string name = "memaccess_in_fsm_sequence");
    super.new(name);
  endfunction

  virtual task body();
    int unsigned op, gap, w1, w2;

    `uvm_info(get_type_name(), $sformatf("driving %0d memory operations", item_count), UVM_LOW)

    repeat (item_count) begin
      op  = $urandom_range(3, 0);
      gap = $urandom_range(3, 1);
      w1  = $urandom_range(max_wait, 1);
      w2  = $urandom_range(max_wait, 1);

      hold(2'd3, 1'b0, gap);                       // idle between operations

      case (op)
        0: hold(2'd0, 1'b0, w1);                   // LD / LDR
        1: hold(2'd2, 1'b0, w1);                   // ST / STR
        2: begin                                   // LDI
             hold(2'd1, 1'b1, w1);
             hold(2'd0, 1'b1, w2);
           end
        3: begin                                   // STI
             hold(2'd1, 1'b1, w1);
             hold(2'd2, 1'b1, w2);
           end
        default: hold(2'd0, 1'b0, w1);             // unreachable: op is 0..3
      endcase
    end

    // Return to idle so the final operation's transition bin closes.
    hold(2'd3, 1'b0, 2);
  endtask
endclass : memaccess_in_fsm_sequence
