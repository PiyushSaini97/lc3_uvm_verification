class writeback_predictor extends uvm_subscriber #(writeback_in_transaction);
  `uvm_component_utils(writeback_predictor)
  uvm_analysis_port #(writeback_expected_transaction)       predicted_ap;
  writeback_env_configuration                               configuration;
  // The professor function owns static RF state: one caller only per simulation.
  static bit                                                model_claimed      = 0;
  bit                                                 [7:0] reg_valid          = '0;
  logic                                               [2:0] saved_psr;
  bit                                                       psr_valid          = 0;
  longint unsigned                                          write_count        = 0;
  longint unsigned                                          unknown_read_count = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    predicted_ap = new("predicted_ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (configuration == null) `uvm_fatal("WB_CFG", "Predictor configuration missing");
    if (model_claimed) `uvm_fatal("WB_MODEL_OWNER", "Static professor model already has an owner");
    model_claimed = 1;
  endfunction

  virtual function void write(writeback_in_transaction t);
    writeback_expected_transaction e;
    bit [15:0] r1, r2;
    bit [2:0] new_psr;
    bit [2:0] safe_sr1, safe_sr2, safe_dr;
    bit          valid_write;
    logic [15:0] selected;
    e             = writeback_expected_transaction::type_id::create("expected");
    e.cycle_id    = t.cycle_id;
    e.sample_time = t.sample_time;
    e.reset       = t.reset;
    // Never index an array with X/Z or silently treat an unknown address as R0.
    e.check_vsr1  = 0;
    e.check_vsr2  = 0;
    safe_sr1      = 0;
    safe_sr2      = 0;
    safe_dr       = 0;
    if (!$isunknown(t.sr1)) begin
      safe_sr1     = t.sr1;
      e.check_vsr1 = reg_valid[safe_sr1];
    end else unknown_read_count++;
    if (!$isunknown(t.sr2)) begin
      safe_sr2     = t.sr2;
      e.check_vsr2 = reg_valid[safe_sr2];
    end else unknown_read_count++;
    if (!$isunknown(t.dr)) safe_dr = t.dr;

    // Pre-edge output PSR belongs to the previous committed write.
    e.psr       = saved_psr;
    e.check_psr = psr_valid && (t.reset === 1'b0);
    if (t.reset === 1'b1 && configuration.check_reset_psr) begin
      e.psr       = configuration.reset_psr;
      e.check_psr = 1;
    end
    selected = 'x;
    case (t.W_Control)
      2'd0:    selected = t.aluout;
      2'd1:    selected = t.memout;
      2'd2:    selected = t.pcout;
      default: ;  // No defined selector-3 behavior in professor model.
    endcase
    valid_write = (t.enable_writeback === 1'b1) && !$isunknown(t.dr) && !$isunknown(t.W_Control) &&
        (t.W_Control != 2'd3) && !$isunknown(selected);

    // Safe read-only calls still return pre-write reads. Unknown unused inputs
    // may convert to bit, but can never affect a committed reference write.
    if (writeback_model(
            t.aluout,
            valid_write ? t.W_Control : 2'd0,
            t.npc,
            t.pcout,
            t.memout,
            valid_write,
            safe_sr1,
            safe_sr2,
            safe_dr,
            r1,
            r2,
            new_psr
        ))
      `uvm_error("WB_MODEL", "Professor model returned failure");
    e.vsr1 = r1;
    e.vsr2 = r2;

    // RegFile has no reset port; visible wr is enable_writeback, not reset-gated.
    // A reset therefore does not erase known RF values in this adapter.
    if (valid_write) begin
      reg_valid[safe_dr] = 1;
      write_count++;
    end else if (t.enable_writeback !== 1'b0) begin
      if ($isunknown(t.dr)) reg_valid = '0;
      else reg_valid[safe_dr] = 0;
      if (t.reset !== 1'b1)
        `uvm_error("WB_INPUT", {"Unknown/unsupported enabled write: ", t.convert2string()});
    end

    if (t.reset === 1'b1) begin
      saved_psr = configuration.reset_psr;
      psr_valid = configuration.check_reset_psr;
    end else if (t.reset !== 1'b0) begin
      psr_valid = 0;
      `uvm_error("WB_RESET", "Reset is unknown");
    end else if (valid_write) begin
      saved_psr = new_psr;
      psr_valid = 1;
    end else if (t.enable_writeback !== 1'b0) psr_valid = 0;
    // Disabled cycles preserve PSR; no reliance on unassigned model output.
    predicted_ap.write(e);
  endfunction
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (write_count == 0) `uvm_error("WB_NO_WRITES", "No known register write was observed");
  endfunction
  function void report_phase(uvm_phase phase);
    `uvm_info(
        "WB_PRED_SUMMARY", $sformatf(
        "writes=%0d unknown_read_addresses=%0d known_registers=%b", write_count, unknown_read_count, reg_valid
        ), UVM_NONE);
  endfunction
endclass
