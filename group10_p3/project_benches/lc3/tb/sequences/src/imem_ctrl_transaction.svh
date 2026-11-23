// imem_ctrl_transaction
// Control-flow heavy stream: mostly BR, some JMP, and ADD/AND/NOT between them so
// the condition codes keep changing (every nzp condition meets N, Z and P).
// lc3_ctrl_test: imem_transaction::type_id::set_type_override(imem_ctrl_transaction::get_type());
class imem_ctrl_transaction extends imem_transaction;
  `uvm_object_utils(imem_ctrl_transaction)
  constraint ctrl_mix_c {
    opcode dist {
      4'b0000 := 6,
      4'b1100 := 1,
      4'b0001 := 1,
      4'b0101 := 1,
      4'b1001 := 1
    };
  }
  function new(string name = "imem_ctrl_transaction");
    super.new(name);
  endfunction
endclass : imem_ctrl_transaction
