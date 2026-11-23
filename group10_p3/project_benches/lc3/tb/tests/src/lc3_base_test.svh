// lc3_base_test - LC3 top-level test, plain constrained-random stimulus
// Same structure as the decoder/control tests: build the env configuration,
// initialize it, create the environment, then run one virtual sequence
// (lc3_vseq). With no factory override every instruction after the prologue is
// a randomized imem_transaction (any legal encoding of the 12 opcodes).
//
// Derived tests change only the stimulus, in set_overrides(), with factory type
// overrides. The bench itself never changes.
//
// Plusargs:
//   +LC3_INSTRS=<n>   instruction fetches, prologue included (default default_instructions())
//   +LC3_DRAIN=<n>    cycles after the last counted fetch (default 20)
// A watchdog ends the test with UVM_FATAL if the CPU stops fetching.
class lc3_base_test extends uvm_test;
  `uvm_component_utils(lc3_base_test)

  localparam int unsigned CLOCK_PERIOD_NS = 10;  // must match hdl_top

  lc3_env_configuration env_config;
  lc3_environment       env;

  int unsigned          num_instructions;
  int unsigned          drain_cycles      = 20;

  function new(string name = "lc3_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Hooks for derived tests.
  protected virtual function void set_overrides();
  endfunction

  // Data-memory accesses the LC3 scoreboard must see for the test to pass. Tests
  // whose instruction mix has no loads or stores (lc3_alu_test, lc3_ctrl_test)
  // return 0, so an empty data-memory stream is not reported as an error.
  protected virtual function int unsigned min_dmem_checks();
    return 1;
  endfunction

  protected virtual function int unsigned default_instructions();
    return 5000;
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    num_instructions = default_instructions();
    void'($value$plusargs("LC3_INSTRS=%d", num_instructions));
    void'($value$plusargs("LC3_DRAIN=%d", drain_cycles));
    set_overrides();
    uvm_config_db#(int unsigned)::set(this, "env.scoreboard", "min_dmem_checks", min_dmem_checks());

    env_config = lc3_env_configuration::type_id::create("env_config");
    env_config.initialize({get_full_name(), ".env"});

    env = lc3_environment::type_id::create("env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    if (uvm_report_enabled(UVM_MEDIUM)) factory.print();
  endfunction

  virtual task run_phase(uvm_phase phase);
    lc3_vseq vseq;

    phase.raise_objection(this, "running LC3 stimulus");

    vseq                  = lc3_vseq::type_id::create("vseq");
    vseq.imem_sqr         = env.imem_agent_h.sequencer;
    vseq.dmem_sqr         = env.dmem_agent_h.sequencer;
    vseq.num_instructions = num_instructions;
    `uvm_info(get_type_name(), $sformatf(
              "running %0d instruction fetches, then %0d drain cycles", num_instructions, drain_cycles),
              UVM_LOW);

    // The virtual sequence runs in this thread: the memory sequences it forks must
    // keep answering through the drain, so nothing here may `disable fork` over
    // them. Only the named watchdog block is disabled.
    fork : watchdog
      begin
        #(num_instructions * CLOCK_PERIOD_NS * 50);
        `uvm_fatal(
            get_type_name(), $sformatf(
            "watchdog: only %0d of %0d fetches completed", env.imem_agent_h.driver.completed, num_instructions
            ));
      end
    join_none
    vseq.start(null);
    disable watchdog;

    // vseq returns at a falling edge (the IMEM driver completes there). Drain, then
    // stop 1 ns after a falling edge: every memory handshake completes on a falling
    // edge (expected) or the rising edge before it (observed), so none is left
    // half-recorded.
    #(drain_cycles * CLOCK_PERIOD_NS + 1);
    `uvm_info(get_type_name(), $sformatf(
              "done: %0d instruction fetches, %0d data accesses",
              env.imem_agent_h.driver.completed,
              env.dmem_agent_h.driver.completed
              ), UVM_LOW);
    phase.drop_objection(this);
  endtask
  // Questa records a test's status in its UCDB from the worst $error/$fatal seen,
  // and the test plan's "test" rows only count passing tests. UVM errors alone
  // do not set that status, so turn any UVM_ERROR/UVM_FATAL into one $error.
  virtual function void report_phase(uvm_phase phase);
    uvm_report_server server = uvm_report_server::get_server();
    int unsigned      failures = server.get_severity_count(UVM_ERROR) + server.get_severity_count(UVM_FATAL);
    super.report_phase(phase);
    if (failures != 0) $error("%s FAILED: %0d UVM errors/fatals", get_type_name(), failures);
    else `uvm_info(get_type_name(), "TEST PASSED", UVM_NONE);
  endfunction
endclass : lc3_base_test
