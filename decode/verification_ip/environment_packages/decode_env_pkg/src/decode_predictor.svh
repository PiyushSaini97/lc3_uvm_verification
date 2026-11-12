class decode_predictor extends uvm_subscriber #(decode_in_transaction);
  `uvm_component_utils(decode_predictor)

  uvm_analysis_port #(decode_out_transaction) predicted_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    predicted_ap = new("predicted_ap", this);
  endfunction

  function void write(decode_in_transaction t);
    decode_out_transaction predicted;
    bit [15:0] ir, npc_out;
    bit [5:0]  e_control;
    bit [1:0]  w_control;
    bit        mem_control;

    if (decode_model(t.dout, t.npc_in, ir, npc_out, e_control, w_control, mem_control))
      `uvm_error(get_type_name(), {"decode_model failed for ", t.convert2string()})

    predicted = decode_out_transaction::type_id::create("predicted");
    predicted.IR          = ir;
    predicted.npc_out     = npc_out;
    predicted.E_Control   = e_control;
    predicted.W_Control   = w_control;
    predicted.Mem_Control = mem_control;

    `uvm_info(get_type_name(), {"predicted: ", predicted.convert2string()}, UVM_MEDIUM)
    predicted_ap.write(predicted);
  endfunction
endclass : decode_predictor
