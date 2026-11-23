// lc3_isa
// Encoders for the 12 instructions this LC3 implements (LC3 Instruction Set).
// Every encoder produces a legal word for the subset imem_coverage expects:
//   NOT  bits[5:0] = 111111
//   JMP  bits[11:9] = 000, bits[5:0] = 000000
//   ADD/AND register mode bits[4:3] = 00
// JSR, RTI, TRAP and RESERVED are never produced.
class lc3_isa;

  // ---- operate ----
  static function bit [15:0] add_r(bit [2:0] dr, bit [2:0] sr1, bit [2:0] sr2);
    return {4'b0001, dr, sr1, 3'b000, sr2};
  endfunction
  static function bit [15:0] add_i(bit [2:0] dr, bit [2:0] sr1, bit [4:0] imm5);
    return {4'b0001, dr, sr1, 1'b1, imm5};
  endfunction
  static function bit [15:0] and_r(bit [2:0] dr, bit [2:0] sr1, bit [2:0] sr2);
    return {4'b0101, dr, sr1, 3'b000, sr2};
  endfunction
  static function bit [15:0] and_i(bit [2:0] dr, bit [2:0] sr1, bit [4:0] imm5);
    return {4'b0101, dr, sr1, 1'b1, imm5};
  endfunction
  static function bit [15:0] not_r(bit [2:0] dr, bit [2:0] sr);
    return {4'b1001, dr, sr, 6'b111111};
  endfunction

  // ---- control ----
  static function bit [15:0] br(bit [2:0] nzp, bit [8:0] off9);
    return {4'b0000, nzp, off9};
  endfunction
  static function bit [15:0] jmp(bit [2:0] base);
    return {4'b1100, 3'b000, base, 6'b000000};
  endfunction
  // A never-taken branch with a nonzero offset: a pipeline NOP that writes no
  // register and leaves psr alone. 0x0000 itself is excluded (imem_transaction's
  // known_dut_bug_c), so the offset is 1.
  static function bit [15:0] nop();
    return br(3'b000, 9'd1);
  endfunction

  // ---- memory ----
  static function bit [15:0] ld(bit [2:0] dr, bit [8:0] off9);
    return {4'b0010, dr, off9};
  endfunction
  static function bit [15:0] ldi(bit [2:0] dr, bit [8:0] off9);
    return {4'b1010, dr, off9};
  endfunction
  static function bit [15:0] ldr(bit [2:0] dr, bit [2:0] base, bit [5:0] off6);
    return {4'b0110, dr, base, off6};
  endfunction
  static function bit [15:0] lea(bit [2:0] dr, bit [8:0] off9);
    return {4'b1110, dr, off9};
  endfunction
  static function bit [15:0] st(bit [2:0] sr, bit [8:0] off9);
    return {4'b0011, sr, off9};
  endfunction
  static function bit [15:0] sti(bit [2:0] sr, bit [8:0] off9);
    return {4'b1011, sr, off9};
  endfunction
  static function bit [15:0] str(bit [2:0] sr, bit [2:0] base, bit [5:0] off6);
    return {4'b0111, sr, base, off6};
  endfunction

  // True for every word the generator is allowed to emit.
  static function bit is_legal(bit [15:0] w);
    case (w[15:12])
      4'b0000: return w != 16'h0000;
      4'b0001, 4'b0101: return w[5] || (w[4:3] == 2'b00);
      4'b1001: return w[5:0] == 6'b111111;
      4'b1100: return (w[11:9] == 3'b000) && (w[5:0] == 6'b000000);
      4'b0010, 4'b0011, 4'b0110, 4'b0111, 4'b1010, 4'b1011, 4'b1110: return 1;
      default: return 0;  // JSR, RTI, RESERVED, TRAP
    endcase
  endfunction
endclass : lc3_isa
