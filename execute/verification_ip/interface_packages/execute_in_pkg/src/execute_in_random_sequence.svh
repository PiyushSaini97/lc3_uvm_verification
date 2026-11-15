// execute_in_random_sequence
// The first 12 items force one opcode each (every legal opcode once, like P2's
// decode_in_random_sequence), the rest are fully random over the legal opcodes.
class execute_in_random_sequence extends execute_in_sequence_base;
  `uvm_object_utils(execute_in_random_sequence)

  bit [3:0] all_opcodes[12] = '{4'b0000, 4'b0001, 4'b0010, 4'b0011,
                                4'b0101, 4'b0110, 4'b0111, 4'b1001,
                                4'b1010, 4'b1011, 4'b1100, 4'b1110};

  function new(string name = "execute_in_random_sequence");
    super.new(name);
  endfunction

  virtual task body();
    execute_in_transaction tr;
    for (int i = 0; i < num_items; i++) begin
      tr = execute_in_transaction::type_id::create("tr");
      start_item(tr);
      if (i < 12) begin
        tr.force_opcode  = 1;
        tr.forced_opcode = all_opcodes[i];
      end
      if (!tr.randomize())
        `uvm_fatal("RAND", "randomize failed")
      finish_item(tr);
    end
  endtask
endclass : execute_in_random_sequence
