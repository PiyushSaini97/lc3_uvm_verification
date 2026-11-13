// test_top - memaccess block bench
//
// Builds the memaccess environment with the in agent ACTIVE (this bench drives the
// five input nets) and the out agent PASSIVE, then runs three sequences:
//
//   1. fsm    - whole memory operations: LD/LDR, ST/STR, LDI, STI, with 1-3 cycle
//               waits in each state. Closes the fsm_sequence transition bins, which
//               a random walk would essentially never hit.
//   2. random - every input field random on every cycle. MemAccess is combinational
//               and stateless, so any vector is legal to ask of it; this reaches
//               input combinations the Controller would never produce and fills the
//               state x M_Control cross and the value-class bins.
//   3. fsm    - again, so the realistic sequences follow the random ones rather than
//               the test ending on an unusual state.
//
// Items per sequence come from +MEMACCESS_ITEMS (default 200). For the fsm
// sequences that is whole memory operations, each several cycles long.
class test_top extends uvm_test;
  `uvm_component_utils(test_top)

  memaccess_env_configuration env_config;
  memaccess_environment       environment;

  memaccess_in_fsm_sequence    fsm_seq_1;
  memaccess_in_random_sequence random_seq;
  memaccess_in_fsm_sequence    fsm_seq_2;

  int unsigned items = 200;

  // Interface names must match the uvm_config_db keys used in hdl_top.
  string interface_names[] = '{ "memaccess_in_if", "memaccess_out_if" };

  // in is ACTIVE here (block bench); at LC3 level both are PASSIVE.
  uvm_active_passive_enum interface_activities[] = '{ UVM_ACTIVE, UVM_PASSIVE };

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!$value$plusargs("MEMACCESS_ITEMS=%d", items))
      items = 200;

    env_config = memaccess_env_configuration::type_id::create("env_config");
    env_config.initialize("uvm_test_top.environment", interface_names, interface_activities);

    environment = memaccess_environment::type_id::create("environment", this);

    fsm_seq_1  = memaccess_in_fsm_sequence   ::type_id::create("fsm_seq_1");
    random_seq = memaccess_in_random_sequence::type_id::create("random_seq");
    fsm_seq_2  = memaccess_in_fsm_sequence   ::type_id::create("fsm_seq_2");

    fsm_seq_1.item_count  = items;
    random_seq.item_count = items;
    fsm_seq_2.item_count  = items;
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), {"environment configuration -> ", env_config.convert2string()}, UVM_LOW)
    uvm_top.print_topology();
  endfunction

  virtual task run_phase(uvm_phase phase);
    memaccess_in_sequencer sqr = env_config.memaccess_in_config.sequencer;

    phase.raise_objection(this, "test_top raised objection");

    `uvm_info(get_type_name(), $sformatf("starting memaccess test with %0d items per sequence", items), UVM_LOW)

    fsm_seq_1.start(sqr);
    random_seq.start(sqr);
    fsm_seq_2.start(sqr);

    // Let the last driven cycle reach both monitors, the predictor and the
    // scoreboard. The odd 5 ns ends the test between clock edges rather than on one,
    // so neither monitor is cut off mid-edge and the two queues drain evenly.
    #105ns;

    `uvm_info(get_type_name(), "memaccess test finished", UVM_LOW)

    phase.drop_objection(this, "test_top dropped objection");
  endtask
endclass : test_top
