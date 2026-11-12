// control_in_random_sequence
// Sends num_items random instructions of the chosen mix. The test sets `mix` and
// `num_items` before start(); the derived classes below are just convenient presets
// so a test (or the command line via +UVM_TESTNAME variants) can name the intent.
class control_in_random_sequence extends control_in_sequence_base;
  `uvm_object_utils(control_in_random_sequence)

  int unsigned  num_items = 100;
  control_mix_e mix       = MIX_RANDOM;

  function new(string name = "control_in_random_sequence");
    super.new(name);
  endfunction

  virtual task body();
    repeat (num_items) begin
      req = control_in_stimulus::type_id::create("req");
      start_item(req);
      req.mix = mix;
      if (!req.randomize())
        `uvm_fatal(get_type_name(), "control_in_stimulus randomize failed")
      finish_item(req);
    end
  endtask
endclass : control_in_random_sequence

// Back-to-back dependent ALU/load/store instructions on R0/R1 -> exercises all four
// bypass paths and load-use behavior.
class control_in_hazard_sequence extends control_in_random_sequence;
  `uvm_object_utils(control_in_hazard_sequence)
  function new(string name = "control_in_hazard_sequence");
    super.new(name);
    mix = MIX_HAZARD;
  endfunction
endclass : control_in_hazard_sequence

// Loads/stores incl. LDI/STI with data-memory wait states -> mem_state FSM and stalls.
class control_in_memory_sequence extends control_in_random_sequence;
  `uvm_object_utils(control_in_memory_sequence)
  function new(string name = "control_in_memory_sequence");
    super.new(name);
    mix = MIX_MEMORY;
  endfunction
endclass : control_in_memory_sequence

// BR/JMP mixed with psr-setting ALU ops -> br_taken both ways, fetch stalls on control.
class control_in_branch_sequence extends control_in_random_sequence;
  `uvm_object_utils(control_in_branch_sequence)
  function new(string name = "control_in_branch_sequence");
    super.new(name);
    mix = MIX_BRANCH;
  endfunction
endclass : control_in_branch_sequence
