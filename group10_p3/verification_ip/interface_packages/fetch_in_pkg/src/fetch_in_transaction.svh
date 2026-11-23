class fetch_in_transaction extends uvm_sequence_item;
  `uvm_object_utils(fetch_in_transaction)
  logic                   reset;
  logic                   enable_updatePC;
  logic                   enable_fetch;
  logic                   br_taken;
  logic            [15:0] taddr;
  longint unsigned        cycle;
  function new(string name = "fetch_in_transaction");
    super.new(name);
  endfunction
  function void do_copy(uvm_object rhs);
    fetch_in_transaction o;
    if (!$cast(o, rhs)) `uvm_fatal("COPY", "wrong type");
    super.do_copy(rhs);
    reset           = o.reset;
    enable_updatePC = o.enable_updatePC;
    enable_fetch    = o.enable_fetch;
    br_taken        = o.br_taken;
    taddr           = o.taddr;
    cycle           = o.cycle;
  endfunction
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    fetch_in_transaction o;
    if (!$cast(o, rhs)) return 0;
    return cycle==o.cycle && (reset===o.reset) && (enable_updatePC===o.enable_updatePC) && (enable_fetch===o.enable_fetch) && (br_taken===o.br_taken) && (taddr===o.taddr);
  endfunction
endclass
