// control_out_coverage
// Coverage of the controller's decisions. These bins map directly to the controller
// features in the spec: memory-stall FSM sequences, branch resolution, the four
// bypass paths, and pipeline stall/bubble patterns.
class control_out_coverage extends uvm_subscriber #(control_out_transaction);
  `uvm_component_utils(control_out_coverage)

  control_out_transaction t_s;

  covergroup control_out_cg;
    option.per_instance = 1;

    // ---- Memory-access FSM (spec: mem_state 3=idle, 0=read, 2=write, 1=indirect read)
    mem_state_cp : coverpoint t_s.mem_state {
      bins read     = {2'd0};
      bins ind_read = {2'd1};
      bins write    = {2'd2};
      bins idle     = {2'd3};
    }
    // Complete access sequences per instruction class; [*1:8] allows wait states.
    mem_seq_cp : coverpoint t_s.mem_state {
      bins ld_ldr  = (3 => 0[*1:8] => 3);
      bins st_str  = (3 => 2[*1:8] => 3);
      bins ldi     = (3 => 1[*1:8] => 0[*1:8] => 3);
      bins sti     = (3 => 1[*1:8] => 2[*1:8] => 3);
      bins rd_wait = (0 [*2:8]);   // load stretched by complete_data
      bins wr_wait = (2 [*2:8]);   // store stretched by complete_data
    }

    // ---- Branch resolution
    br_taken_cp : coverpoint t_s.br_taken {
      bins not_taken = {1'b0};
      bins taken     = {1'b1};
    }

    // ---- Data-forwarding paths
    bypass_alu_1_cp : coverpoint t_s.bypass_alu_1 { bins on = {1'b1}; bins off = {1'b0}; }
    bypass_alu_2_cp : coverpoint t_s.bypass_alu_2 { bins on = {1'b1}; bins off = {1'b0}; }
    bypass_mem_1_cp : coverpoint t_s.bypass_mem_1 { bins on = {1'b1}; bins off = {1'b0}; }
    bypass_mem_2_cp : coverpoint t_s.bypass_mem_2 { bins on = {1'b1}; bins off = {1'b0}; }
    bypass_combo_cp : coverpoint t_s.bypasses() {
      bins none         = {4'b0000};
      bins alu1         = {4'b1000};
      bins alu2         = {4'b0100};
      bins alu1_alu2    = {4'b1100};   // e.g. ADD R1,R2,R2 after write to R2
      bins mem1         = {4'b0010};
      bins mem2         = {4'b0001};
      bins mem1_mem2    = {4'b0011};
      // One producing instruction in Execute is either ALU-type or MEMORY-type,
      // never both, so an ALU bypass and a MEM bypass can never be on together.
      illegal_bins alu_and_mem = {4'b1010, 4'b1001, 4'b0110, 4'b0101,
                                  4'b1110, 4'b1101, 4'b1011, 4'b0111, 4'b1111};
    }

    // ---- Pipeline enable patterns {updatePC, fetch, decode, execute, writeback}
    enables_cp : coverpoint t_s.enables() {
      bins full_flow  = {5'b11111};
      bins all_stall  = {5'b00000};
      bins wb_bubble  = {5'b11110};          // store / control: no writeback
    }
    // Whole pipeline frozen while the memory FSM is busy, for every FSM state.
    mem_stall_cp : coverpoint t_s.mem_state iff (t_s.enables() == 5'b00000) {
      bins read     = {2'd0};
      bins ind_read = {2'd1};
      bins write    = {2'd2};
    }
  endgroup : control_out_cg

  function new(string name, uvm_component parent);
    super.new(name, parent);
    control_out_cg = new();
  endfunction

  virtual function void write(control_out_transaction t);
    t_s = t;
    control_out_cg.sample();
  endfunction
endclass : control_out_coverage
