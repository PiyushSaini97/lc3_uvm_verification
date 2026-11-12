// test_top - control block bench
// Same structure as the P2 decoder test: build the env config, initialize it with the
// interface names/activities, create the env, run sequences on the in-agent sequencer.
//
// Stimulus plan (instructions are fed at the pace the controller fetches them):
//   1. random  : every legal opcode, uniform            -> general sanity
//   2. hazard  : dependent ops on R0/R1                 -> bypass_alu_* / bypass_mem_*
//   3. memory  : LD/LDR/LDI/ST/STR/STI + data waits     -> mem_state FSM, pipeline stalls
//   4. branch  : BR/JMP + psr-setting ALU ops           -> br_taken, control stalls
//   5. random  : again, to mix everything back-to-back
// Item counts can be scaled from the command line: +CTRL_ITEMS=<n> (default 200).
class test_top extends uvm_test;
  `uvm_component_utils(test_top)

  control_env_configuration env_config;
  control_environment       env;

  int unsigned items_per_seq = 200;

  function new(string name = "test_top", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    string                  interface_names[]    = '{"control_in_if", "control_out_if"};
    uvm_active_passive_enum interface_activity[] = '{UVM_ACTIVE, UVM_PASSIVE};
    super.build_phase(phase);

    void'($value$plusargs("CTRL_ITEMS=%d", items_per_seq));

    env_config = control_env_configuration::type_id::create("env_config");
    env_config.initialize({get_full_name(), ".env"}, interface_names, interface_activity);

    env = control_environment::type_id::create("env", this);
  endfunction

  protected task run_seq(control_in_random_sequence seq);
    seq.num_items = items_per_seq;
    `uvm_info(get_type_name(), $sformatf("starting %s (%0d instructions)",
                                         seq.get_type_name(), seq.num_items), UVM_LOW)
    seq.start(env_config.control_in_config.sequencer);
  endtask

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this, "running control sequences");
    run_seq(control_in_random_sequence ::type_id::create("random_seq"));
    run_seq(control_in_hazard_sequence ::type_id::create("hazard_seq"));
    run_seq(control_in_memory_sequence ::type_id::create("memory_seq"));
    run_seq(control_in_branch_sequence ::type_id::create("branch_seq"));
    run_seq(control_in_random_sequence ::type_id::create("random_seq2"));
    // Let the last instructions drain through decode/execute/writeback/memory.
    #200;
    phase.drop_objection(this);
  endtask
endclass : test_top
