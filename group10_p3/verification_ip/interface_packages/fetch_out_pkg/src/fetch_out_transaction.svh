class fetch_out_transaction extends uvm_sequence_item;
  `uvm_object_utils(fetch_out_transaction)
  logic                   reset;
  logic            [15:0] pc;
  logic            [15:0] npc;
  logic                   instrmem_rd;
  longint unsigned        cycle;
  function new(string name = "fetch_out_transaction");
    super.new(name);
  endfunction
  function void do_copy(uvm_object rhs);
    fetch_out_transaction o;
    if (!$cast(o, rhs)) `uvm_fatal("COPY", "wrong type");
    super.do_copy(rhs);
    reset       = o.reset;
    pc          = o.pc;
    npc         = o.npc;
    instrmem_rd = o.instrmem_rd;
    cycle       = o.cycle;
  endfunction
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    fetch_out_transaction o;
    if (!$cast(o, rhs)) return 0;
    return cycle==o.cycle && (reset===o.reset) && (pc===o.pc) && (npc===o.npc) && (instrmem_rd===o.instrmem_rd);
  endfunction
endclass
