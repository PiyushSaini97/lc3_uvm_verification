// memaccess_out_coverage
// Functional coverage of the MemAccess OUTPUT space.
//
// Coverpoints sample the transaction's classification helpers rather than the raw
// fields, because a coverpoint bin cannot match an x or z value and this block's
// IDLE state legitimately produces z on three of its four outputs.
//
// The illegal bins are bug detectors, not coverage targets: an x on Data_addr,
// Data_din or Data_rd means MemAccess is driving a memory control line to an unknown
// value, which no mem_state can ask for. If one fires during LC3 integration and it
// turns out to be a reset tail rather than a real bug, change that line to
// `ignore_bins` and say so in the test plan.
class memaccess_out_coverage extends uvm_subscriber #(memaccess_out_transaction);
  `uvm_component_utils(memaccess_out_coverage)

  memaccess_out_transaction cov;

  covergroup memaccess_out_cg;
    option.per_instance = 1;
    option.name         = "memaccess_out_cg";
    option.comment      = "MemAccess output behaviour: direction, address and data classes";

    rd : coverpoint cov.rd_class() {
      bins write     = {2'd0};   // mem_state 2
      bins read      = {2'd1};   // mem_state 0 or 1
      bins tristated = {2'd2};   // mem_state 3 (IDLE)
      illegal_bins unknown = {2'd3};
    }

    addr : coverpoint cov.addr_class() {
      bins zero      = {3'd0};
      bins ones      = {3'd1};
      bins other     = {3'd2};
      bins tristated = {3'd3};
      illegal_bins unknown = {3'd4};
    }

    din : coverpoint cov.din_class() {
      bins zero      = {3'd0};   // reads drive Data_din = 0
      bins ones      = {3'd1};
      bins other     = {3'd2};
      bins tristated = {3'd3};
      illegal_bins unknown = {3'd4};
    }

    // memout is Data_dout forwarded unchanged, in every state. At LC3 level it can
    // be x before the first memory read completes, which is the memory's business,
    // not this block's, so those samples are ignored rather than flagged.
    memout : coverpoint cov.memout_class() {
      bins zero  = {3'd0};
      bins ones  = {3'd1};
      bins other = {3'd2};
      ignore_bins undriven = {3'd3, 3'd4};
    }

    // Each memory direction seen with each class of address. IDLE cycles are
    // excluded: there the direction and the address are both tri-stated, so the
    // combination carries no information.
    active_addr : cross rd, addr {
      ignore_bins idle_cycles = binsof(rd.tristated) || binsof(addr.tristated);
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    memaccess_out_cg = new();
  endfunction

  virtual function void write(memaccess_out_transaction t);
    cov = t;
    memaccess_out_cg.sample();
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("memaccess_out coverage = %0.2f%%", memaccess_out_cg.get_inst_coverage()),
              UVM_LOW)
  endfunction
endclass : memaccess_out_coverage
