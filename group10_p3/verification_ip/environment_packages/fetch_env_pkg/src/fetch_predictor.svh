class fetch_predictor extends uvm_subscriber #(fetch_in_transaction);
  `uvm_component_utils(fetch_predictor)
  uvm_analysis_port #(fetch_out_transaction) predicted_ap;
  bit                                        started       = 0;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    predicted_ap = new("predicted_ap", this);
  endfunction
  function void write(fetch_in_transaction t);
    fetch_out_transaction e;
    bit [15:0] pc, npc;
    bit rd;
    e       = fetch_out_transaction::type_id::create("e");
    e.cycle = t.cycle;
    e.reset = t.reset;
    if (t.reset === 1) begin
      if (started)
        `uvm_fatal("LC3_MID_RESET", "Fetch model has no reset API; restart simulation for a reset test");
      // PC reset value is the professor model's initial PC; rd is combinational.
      e.pc          = 16'h3000;
      e.npc         = 16'h3001;
      e.instrmem_rd = t.enable_fetch;
    end else begin
      started = 1;
      if ($isunknown(
              {t.reset, t.enable_updatePC, t.enable_fetch, t.br_taken}
          ) || (t.enable_updatePC && t.br_taken && $isunknown(
              t.taddr
          )))
        `uvm_fatal("FETCH_X", "Unknown fetch control or used branch address");
      if (fetch_model(t.enable_updatePC, t.enable_fetch, t.br_taken, t.taddr, npc, pc, rd))
        `uvm_error("FETCH_MODEL", "reference failed");
      e.pc          = pc;
      e.npc         = npc;
      e.instrmem_rd = rd;
    end
    predicted_ap.write(e);
  endfunction
endclass
