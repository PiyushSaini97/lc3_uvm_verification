class imem_monitor extends uvm_monitor;
  `uvm_component_utils(imem_monitor)
  imem_configuration                    configuration;
  uvm_analysis_port #(imem_transaction) monitored_ap;
  int                                   count;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    monitored_ap = new("monitored_ap", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    if (configuration.monitor_bfm == null) `uvm_fatal("CFG", "null memory BFM");
    configuration.monitor_bfm.proxy = this;
  endfunction
  task run_phase(uvm_phase phase);
    configuration.monitor_bfm.start_monitoring();
  endtask
  function void notify_transaction(logic [15:0] address, logic read, logic [15:0] data);
    imem_transaction t;
    t         = imem_transaction::type_id::create("observed");
    t.address = address;
    t.read    = read;
    t.data    = data;
    count++;
    monitored_ap.write(t);
  endfunction
endclass
