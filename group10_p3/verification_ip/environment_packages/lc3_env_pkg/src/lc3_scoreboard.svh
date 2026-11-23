`uvm_analysis_imp_decl(_lc3_imem_expected)
`uvm_analysis_imp_decl(_lc3_imem_actual)
`uvm_analysis_imp_decl(_lc3_dmem_expected)
`uvm_analysis_imp_decl(_lc3_dmem_actual)
class lc3_scoreboard extends uvm_component;
  `uvm_component_utils(lc3_scoreboard)
  int unsigned                                                           min_dmem_checks     = 1;
  imem_transaction                                                       imem_e         [$],      imem_a[$];
  int                                                                    imem_checks;
  uvm_analysis_imp_lc3_imem_expected #(imem_transaction, lc3_scoreboard) imem_expected;
  uvm_analysis_imp_lc3_imem_actual #(imem_transaction, lc3_scoreboard)   imem_actual;
  dmem_transaction                                                       dmem_e         [$],      dmem_a[$];
  int                                                                    dmem_checks;
  uvm_analysis_imp_lc3_dmem_expected #(dmem_transaction, lc3_scoreboard) dmem_expected;
  uvm_analysis_imp_lc3_dmem_actual #(dmem_transaction, lc3_scoreboard)   dmem_actual;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    imem_expected = new("imem_expected", this);
    imem_actual   = new("imem_actual", this);
    dmem_expected = new("dmem_expected", this);
    dmem_actual   = new("dmem_actual", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(int unsigned)::get(this, "", "min_dmem_checks", min_dmem_checks));
  endfunction
  function void write_lc3_imem_expected(imem_transaction t);
    imem_transaction c;
    if (!$cast(c, t.clone())) `uvm_fatal("COPY", "memory clone failed");
    imem_e.push_back(c);
    drain_imem();
  endfunction
  function void write_lc3_imem_actual(imem_transaction t);
    imem_transaction c;
    if (!$cast(c, t.clone())) `uvm_fatal("COPY", "memory clone failed");
    imem_a.push_back(c);
    drain_imem();
  endfunction
  function void drain_imem();
    imem_transaction e, a;
    while (imem_e.size() > 0 && imem_a.size() > 0) begin
      e = imem_e.pop_front();
      a = imem_a.pop_front();
      imem_checks++;
      if (e.address !== a.address || e.read !== a.read || e.data !== a.data)
        `uvm_error("LC3_MEMORY_MISMATCH", "imem response mismatch");
    end
    if (imem_e.size() > 8 || imem_a.size() > 8) `uvm_fatal("LC3_BACKLOG", "memory observation backlog");
  endfunction
  function void write_lc3_dmem_expected(dmem_transaction t);
    dmem_transaction c;
    if (!$cast(c, t.clone())) `uvm_fatal("COPY", "memory clone failed");
    dmem_e.push_back(c);
    drain_dmem();
  endfunction
  function void write_lc3_dmem_actual(dmem_transaction t);
    dmem_transaction c;
    if (!$cast(c, t.clone())) `uvm_fatal("COPY", "memory clone failed");
    dmem_a.push_back(c);
    drain_dmem();
  endfunction
  function void drain_dmem();
    dmem_transaction e, a;
    while (dmem_e.size() > 0 && dmem_a.size() > 0) begin
      e = dmem_e.pop_front();
      a = dmem_a.pop_front();
      dmem_checks++;
      if (e.address !== a.address || e.read !== a.read || e.data !== a.data)
        `uvm_error("LC3_MEMORY_MISMATCH", "dmem response mismatch");
    end
    if (dmem_e.size() > 8 || dmem_a.size() > 8) `uvm_fatal("LC3_BACKLOG", "memory observation backlog");
  endfunction
  function void check_phase(uvm_phase phase);
    if (imem_checks == 0 || imem_e.size() != 0 || imem_a.size() != 0)
      `uvm_error("LC3_MEMORY_INCOMPLETE", "imem absent or unpaired transactions");
    if (dmem_checks < min_dmem_checks || dmem_e.size() != 0 || dmem_a.size() != 0)
      `uvm_error("LC3_MEMORY_INCOMPLETE", "dmem absent or unpaired transactions");
  endfunction
  function void report_phase(uvm_phase phase);
    `uvm_info("LC3_MEMORY_SUMMARY", $sformatf(
              "imem_pairs=%0d dmem_pairs=%0d required_dmem_pairs=%0d imem_pending=%0d/%0d dmem_pending=%0d/%0d",
              imem_checks,
              dmem_checks,
              min_dmem_checks,
              imem_e.size(),
              imem_a.size(),
              dmem_e.size(),
              dmem_a.size()
              ), UVM_LOW);
  endfunction
endclass
