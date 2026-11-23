`uvm_analysis_imp_decl(_lc3_imem_prediction)
`uvm_analysis_imp_decl(_lc3_dmem_prediction)
class lc3_predictor extends uvm_component;
  `uvm_component_utils(lc3_predictor)
  uvm_analysis_imp_lc3_imem_prediction #(imem_transaction, lc3_predictor) imem_export;
  uvm_analysis_imp_lc3_dmem_prediction #(dmem_transaction, lc3_predictor) dmem_export;
  uvm_analysis_port #(imem_transaction)                                   imem_ap;
  uvm_analysis_port #(dmem_transaction)                                   dmem_ap;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    imem_export = new("imem_export", this);
    dmem_export = new("dmem_export", this);
    imem_ap     = new("imem_ap", this);
    dmem_ap     = new("dmem_ap", this);
  endfunction
  function void write_lc3_imem_prediction(imem_transaction t);
    imem_ap.write(t);
  endfunction
  function void write_lc3_dmem_prediction(dmem_transaction t);
    dmem_ap.write(t);
  endfunction
endclass
