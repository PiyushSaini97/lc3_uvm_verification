`uvm_analysis_imp_decl(_writeback_expected)
`uvm_analysis_imp_decl(_writeback_actual)
class writeback_scoreboard extends uvm_component;
  `uvm_component_utils(writeback_scoreboard)
  uvm_analysis_imp_writeback_expected #(writeback_expected_transaction, writeback_scoreboard) expected_export;
  uvm_analysis_imp_writeback_actual #(writeback_out_transaction, writeback_scoreboard) actual_export;
  writeback_env_configuration configuration;
  writeback_expected_transaction expected_by_cycle[longint unsigned];
  writeback_out_transaction actual_by_cycle[longint unsigned];
  longint unsigned paired_count, mismatch_count, read_checks, psr_checks, skipped_fields;
  longint unsigned last_expected, last_actual;
  bit have_expected = 0, have_actual = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (configuration == null) `uvm_fatal("WB_CFG", "Scoreboard configuration missing");
    if (configuration.max_pending == 0 || configuration.max_mismatch_prints == 0)
      `uvm_fatal("WB_CFG", "Queue and diagnostic bounds must be nonzero");
  endfunction
  function void write_writeback_expected(writeback_expected_transaction t);
    writeback_expected_transaction c;
    if (have_expected && t.cycle_id != last_expected + 1) begin
      `uvm_error("WB_ORDER", "Expected stream duplicate or missing cycle");
      return;
    end
    if (!have_expected && t.cycle_id != 0) `uvm_error("WB_ORDER", "Expected stream must start at cycle zero");
    if (!$cast(c, t.clone())) `uvm_fatal("WB_COPY", "Cannot clone expected");
    have_expected                 = 1;
    last_expected                 = t.cycle_id;
    expected_by_cycle[t.cycle_id] = c;
    pair_cycle(t.cycle_id);
    check_bound();
  endfunction
  function void write_writeback_actual(writeback_out_transaction t);
    writeback_out_transaction c;
    if (have_actual && t.cycle_id != last_actual + 1) begin
      `uvm_error("WB_ORDER", "Actual stream duplicate or missing cycle");
      return;
    end
    if (!have_actual && t.cycle_id != 0) `uvm_error("WB_ORDER", "Actual stream must start at cycle zero");
    if (!$cast(c, t.clone())) `uvm_fatal("WB_COPY", "Cannot clone actual");
    have_actual                 = 1;
    last_actual                 = t.cycle_id;
    actual_by_cycle[t.cycle_id] = c;
    pair_cycle(t.cycle_id);
    check_bound();
  endfunction
  function void check_bound();
    if (expected_by_cycle.num()>configuration.max_pending || actual_by_cycle.num()>configuration.max_pending)
      `uvm_fatal("WB_BACKLOG", "Unmatched observations exceeded configured bound");
  endfunction
  function void pair_cycle(longint unsigned id);
    writeback_expected_transaction e;
    writeback_out_transaction      a;
    bit                            bad;
    if (!expected_by_cycle.exists(id) || !actual_by_cycle.exists(id)) return;
    e   = expected_by_cycle[id];
    a   = actual_by_cycle[id];
    bad = (e.sample_time != a.sample_time) || (e.reset !== a.reset);
    if (e.check_vsr1) begin
      read_checks++;
      bad |= (a.vsr1 !== e.vsr1);
    end else skipped_fields++;
    if (e.check_vsr2) begin
      read_checks++;
      bad |= (a.vsr2 !== e.vsr2);
    end else skipped_fields++;
    if (e.check_psr) begin
      psr_checks++;
      bad |= (a.psr !== e.psr);
    end else skipped_fields++;
    paired_count++;
    if (bad) begin
      mismatch_count++;
      if (mismatch_count <= configuration.max_mismatch_prints)
        `uvm_error("WB_MISMATCH", $sformatf(
                   "expected: %s\nactual: %s", e.convert2string(), a.convert2string()));
    end
    expected_by_cycle.delete(id);
    actual_by_cycle.delete(id);
  endfunction
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (expected_by_cycle.num() != 0 || actual_by_cycle.num() != 0)
      `uvm_error("WB_UNPAIRED", $sformatf(
                 "Unpaired expected=%0d actual=%0d", expected_by_cycle.num(), actual_by_cycle.num()));
    if (paired_count == 0 || read_checks == 0 || psr_checks == 0)
      `uvm_error("WB_NO_CHECKS",
                 "Need nonzero paired cycles, valid register reads AND valid PSR comparisons");
    if (mismatch_count > configuration.max_mismatch_prints)
      `uvm_error("WB_MISMATCH_SUMMARY", $sformatf(
                 "Total mismatches=%0d (individual messages capped)", mismatch_count));
  endfunction
  function void report_phase(uvm_phase phase);
    `uvm_info("WB_SUMMARY", $sformatf(
              "paired=%0d mismatches=%0d read_checks=%0d psr_checks=%0d skipped_fields=%0d",
              paired_count,
              mismatch_count,
              read_checks,
              psr_checks,
              skipped_fields
              ), UVM_NONE);
  endfunction
endclass
