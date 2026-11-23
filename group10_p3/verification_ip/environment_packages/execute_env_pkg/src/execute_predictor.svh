// execute_predictor
// Subscribes to execute_in transactions (one per enabled cycle) and predicts the Execute
// outputs for that cycle with lc3_prediction_pkg::execute_model().
//
// IMPORTANT - execute_model() is STATEFUL:
//   It keeps its previous outputs in static variables (the bypass_alu path reads the
//   previous aluout). It must be called exactly once per enabled cycle, in order. This
//   predictor calls it exactly once per write(), and nothing else in the testbench may
//   call execute_model().
class execute_predictor extends uvm_subscriber #(execute_in_transaction);
  `uvm_component_utils(execute_predictor)

  uvm_analysis_port #(execute_out_transaction) predicted_ap;

  int unsigned                                 prediction_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    predicted_ap = new("predicted_ap", this);
  endfunction

  function void write(execute_in_transaction t);
    execute_out_transaction predicted;
    bit [15:0] aluout, m_data, ir_exec, pcout;
    bit [1:0] w_control_out;
    bit       mem_control_out;
    bit [2:0] dr, sr1, sr2, nzp;

    if (execute_model(
            t.e_control,
            t.bypass_alu_1,
            t.bypass_alu_2,
            t.bypass_mem_1,
            t.bypass_mem_2,
            1'b1,
            t.ir,
            t.npc_in,
            t.mem_control_in,
            t.w_control_in,
            t.mem_bypass_val,
            t.vsr1,
            t.vsr2,
            aluout,
            w_control_out,
            mem_control_out,
            m_data,
            dr,
            sr1,
            sr2,
            ir_exec,
            nzp,
            pcout
        ))
      `uvm_error(get_type_name(), {"execute_model failed for ", t.convert2string()});

    predicted                 = execute_out_transaction::type_id::create("predicted");
    predicted.aluout          = aluout;
    predicted.pcout           = pcout;
    predicted.w_control_out   = w_control_out;
    predicted.mem_control_out = mem_control_out;
    predicted.dr              = dr;
    predicted.sr1             = sr1;
    predicted.sr2             = sr2;
    predicted.ir_exec         = ir_exec;
    predicted.nzp             = nzp;
    // Preserve four-state store-data forwarding lost by the bit-valued model API.
    predicted.m_data          = t.bypass_alu_2 ? m_data : t.vsr2;
    predicted.index           = t.index;
    predicted.start_time      = t.start_time;
    predicted.end_time        = t.end_time;
    prediction_count++;

    `uvm_info(get_type_name(), {"predicted: ", predicted.convert2string()}, UVM_HIGH);
    predicted_ap.write(predicted);
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("predictions made: %0d", prediction_count), UVM_LOW);
  endfunction
endclass : execute_predictor
