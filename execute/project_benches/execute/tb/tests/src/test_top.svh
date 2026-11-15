// test_top - execute block bench
// Builds the env config, initializes it with the interface names/activities, creates the
// env and runs the sequences on the execute_in sequencer.
//
// Stimulus plan:
//   1. random  : every legal opcode once, then random      -> general sanity
//   2. alu     : ADD/AND/NOT with corner operands/imm5      -> aluout, nzp
//   3. offset  : BR/JMP/LD/LDR/LDI/LEA/ST/STR/STI offsets   -> pcout, M_Data
//   4. bypass  : alu and mem bypass on both operands        -> bypass muxes
//   5. random  : again, to mix everything back-to-back
// Item counts can be scaled from the command line: +EXEC_ITEMS=<n> (default 200).
class test_top extends uvm_test;
  `uvm_component_utils(test_top)

  execute_env_configuration env_config;
  execute_environment       env;

  int unsigned items_per_seq = 200;

  function new(string name = "test_top", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    string                  interface_names[]    = '{"execute_in_if", "execute_out_if"};
    uvm_active_passive_enum interface_activity[] = '{UVM_ACTIVE, UVM_PASSIVE};
    super.build_phase(phase);

    void'($value$plusargs("EXEC_ITEMS=%d", items_per_seq));

    env_config = execute_env_configuration::type_id::create("env_config");
    env_config.initialize({get_full_name(), ".env"}, interface_names, interface_activity);

    env = execute_environment::type_id::create("env", this);
  endfunction

  protected task run_seq(execute_in_sequence_base seq);
    seq.num_items = items_per_seq;
    `uvm_info(get_type_name(), $sformatf("starting %s (%0d items)", seq.get_type_name(), seq.num_items), UVM_LOW)
    seq.start(env_config.execute_in_config.sequencer);
  endtask

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this, "running execute sequences");
    run_seq(execute_in_random_sequence ::type_id::create("random_seq"));
    run_seq(execute_in_alu_sequence    ::type_id::create("alu_seq"));
    run_seq(execute_in_offset_sequence ::type_id::create("offset_seq"));
    run_seq(execute_in_bypass_sequence ::type_id::create("bypass_seq"));
    run_seq(execute_in_random_sequence ::type_id::create("random_seq2"));
    //#100;   // last item's registered outputs reach the out monitor one edge later
    env_config.execute_in_config.driver_bfm.deassert_enable();
    #30;
    phase.drop_objection(this);
  endtask
endclass : test_top
