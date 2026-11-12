class test_top extends uvm_test;
  `uvm_component_utils(test_top)

  decode_env_configuration env_config;
  decode_environment       env;

  function new(string name = "test_top", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    string                  interface_names[]    = '{"decode_in_if", "decode_out_if"};
    uvm_active_passive_enum interface_activity[] = '{UVM_ACTIVE, UVM_PASSIVE};
    super.build_phase(phase);

    env_config = decode_env_configuration::type_id::create("env_config");
    env_config.initialize({get_full_name(), ".env"}, interface_names, interface_activity);

    env = decode_environment::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    decode_in_random_sequence seq;
    phase.raise_objection(this, "running 50 random decode_in sequences");
    repeat (50) begin
      seq = decode_in_random_sequence::type_id::create("seq");
      seq.start(env_config.decode_in_config.sequencer);
    end
    #40;
    phase.drop_objection(this);
  endtask
endclass : test_top
