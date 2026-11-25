class imem_pipeline_coverage extends uvm_subscriber #(imem_transaction);
  `uvm_component_utils(imem_pipeline_coverage)

  localparam bit [3:0] OP_BR  = 4'b0000;
  localparam bit [3:0] OP_ADD = 4'b0001;
  localparam bit [3:0] OP_LD  = 4'b0010;
  localparam bit [3:0] OP_ST  = 4'b0011;
  localparam bit [3:0] OP_AND = 4'b0101;
  localparam bit [3:0] OP_LDR = 4'b0110;
  localparam bit [3:0] OP_STR = 4'b0111;
  localparam bit [3:0] OP_NOT = 4'b1001;
  localparam bit [3:0] OP_LDI = 4'b1010;
  localparam bit [3:0] OP_STI = 4'b1011;
  localparam bit [3:0] OP_JMP = 4'b1100;
  localparam bit [3:0] OP_LEA = 4'b1110;

  typedef struct {
    bit       valid;
    bit [3:0] op;
    bit       writes;
    bit [1:0] cls;   // 0 ALU, 1 load, 2 LEA
    bit [2:0] dr;
  } hist_t;

  hist_t       hist[1:3];   // hist[1] is the previous instruction
  int unsigned chain_len;
  int unsigned mem_run;
  int unsigned since_mem;
  bit          mem_seen;
  bit    [2:0] last_mem_kind;
  int unsigned fetches;

  covergroup bypass_sr1_cg with function sample (bit [1:0] producer, bit [3:0] consumer, bit [1:0] distance);
    option.per_instance = 1;
    producer_cp: coverpoint producer {
      bins alu  = {0};
      bins load = {1};
      bins lea  = {2};
    }
    consumer_cp: coverpoint consumer {
      bins ADD = {4'b0001};
      bins AND = {4'b0101};
      bins NOT = {4'b1001};
      bins LDR = {4'b0110};
      bins STR = {4'b0111};
      bins JMP = {4'b1100};
    }
    distance_cp: coverpoint distance {
      bins d1 = {1};
      bins d2 = {2};
      bins d3 = {3};
    }
    producer_x_consumer_x_distance: cross producer_cp, consumer_cp, distance_cp;
  endgroup : bypass_sr1_cg

  covergroup bypass_sr2_cg with function sample (bit [1:0] producer, bit [3:0] consumer, bit [1:0] distance);
    option.per_instance = 1;
    producer_cp: coverpoint producer {
      bins alu  = {0};
      bins load = {1};
      bins lea  = {2};
    }
    consumer_cp: coverpoint consumer {
      bins ADD = {4'b0001};
      bins AND = {4'b0101};
      bins ST  = {4'b0011};
      bins STR = {4'b0111};
      bins STI = {4'b1011};
    }
    distance_cp: coverpoint distance {
      bins d1 = {1};
      bins d2 = {2};
      bins d3 = {3};
    }
    producer_x_consumer_x_distance: cross producer_cp, consumer_cp, distance_cp;
  endgroup : bypass_sr2_cg

  covergroup mixed_bypass_cg with function sample (bit [1:0] distance1, bit [1:0] distance2);
    option.per_instance = 1;
    sr1_distance_cp: coverpoint distance1 {
      bins d1 = {1};
      bins d2 = {2};
      bins d3 = {3};
    }
    sr2_distance_cp: coverpoint distance2 {
      bins d1 = {1};
      bins d2 = {2};
      bins d3 = {3};
    }
    sr1_x_sr2: cross sr1_distance_cp, sr2_distance_cp;
  endgroup : mixed_bypass_cg

  covergroup branch_history_cg with function sample (bit [3:0] setter, bit [2:0] nzp);
    option.per_instance = 1;
    setter_cp: coverpoint setter {
      bins alu_d1  = {0};
      bins alu_d2  = {1};
      bins alu_d3  = {2};
      bins load_d1 = {3};
      bins load_d2 = {4};
      bins load_d3 = {5};
      bins lea_d1  = {6};
      bins lea_d2  = {7};
      bins lea_d3  = {8};
      bins older   = {9};
    }
    nzp_cp: coverpoint nzp {
      bins never = {3'b000};
      bins p     = {3'b001};
      bins z     = {3'b010};
      bins zp    = {3'b011};
      bins n     = {3'b100};
      bins np    = {3'b101};
      bins nz    = {3'b110};
      bins nzp   = {3'b111};
    }
    setter_x_nzp: cross setter_cp, nzp_cp;
  endgroup : branch_history_cg

  covergroup mem_pair_cg with function sample (bit [2:0] prev_kind, bit [2:0] kind, bit [1:0] gap);
    option.per_instance = 1;
    prev_cp: coverpoint prev_kind {
      bins LD  = {0};
      bins LDR = {1};
      bins LDI = {2};
      bins ST  = {3};
      bins STR = {4};
      bins STI = {5};
    }
    kind_cp: coverpoint kind {
      bins LD  = {0};
      bins LDR = {1};
      bins LDI = {2};
      bins ST  = {3};
      bins STR = {4};
      bins STI = {5};
    }
    gap_cp: coverpoint gap {
      bins g0 = {0};
      bins g1 = {1};
      bins g2 = {2};
    }
    prev_x_kind_x_gap: cross prev_cp, kind_cp, gap_cp;
  endgroup : mem_pair_cg

  covergroup mem_run_cg with function sample (int unsigned position);
    option.per_instance = 1;
    position_cp: coverpoint position {
      bins p1      = {1};
      bins p2      = {2};
      bins p3      = {3};
      bins p4      = {4};
      bins p5_plus = {[5 : $]};
    }
  endgroup : mem_run_cg

  covergroup waw_cg with function sample (bit [1:0] first, bit [1:0] second, bit [1:0] distance);
    option.per_instance = 1;
    first_cp: coverpoint first {
      bins alu  = {0};
      bins load = {1};
      bins lea  = {2};
    }
    second_cp: coverpoint second {
      bins alu  = {0};
      bins load = {1};
      bins lea  = {2};
    }
    distance_cp: coverpoint distance {
      bins d1 = {1};
      bins d2 = {2};
    }
    first_x_second_x_distance: cross first_cp, second_cp, distance_cp;
  endgroup : waw_cg

  covergroup chain_cg with function sample (int unsigned length);
    option.per_instance = 1;
    length_cp: coverpoint length {
      bins l1      = {1};
      bins l2      = {2};
      bins l3      = {3};
      bins l4      = {4};
      bins l5_plus = {[5 : $]};
    }
  endgroup : chain_cg

  function new(string name, uvm_component parent);
    super.new(name, parent);
    bypass_sr1_cg     = new();
    bypass_sr2_cg     = new();
    mixed_bypass_cg   = new();
    branch_history_cg = new();
    mem_pair_cg       = new();
    mem_run_cg        = new();
    waw_cg            = new();
    chain_cg          = new();
  endfunction

  protected function bit writes_reg(bit [3:0] op);
    return op inside {OP_ADD, OP_AND, OP_NOT, OP_LD, OP_LDR, OP_LDI, OP_LEA};
  endfunction

  protected function bit [1:0] producer_class(bit [3:0] op);
    if (op inside {OP_LD, OP_LDR, OP_LDI}) return 1;
    if (op == OP_LEA) return 2;
    return 0;
  endfunction

  protected function bit is_mem(bit [3:0] op);
    return op inside {OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI};
  endfunction

  protected function bit [2:0] mem_kind(bit [3:0] op);
    case (op)
      OP_LD:   return 0;
      OP_LDR:  return 1;
      OP_LDI:  return 2;
      OP_ST:   return 3;
      OP_STR:  return 4;
      default: return 5;
    endcase
  endfunction

  protected function void find_producer(bit [2:0] r, output bit [1:0] distance, output bit [1:0] cls);
    distance = 0;
    cls      = 0;
    for (int i = 1; i <= 3; i++) begin
      if (hist[i].valid && hist[i].writes && hist[i].dr == r) begin
        distance = 2'(i);
        cls      = hist[i].cls;
        break;
      end
    end
  endfunction

  virtual function void write(imem_transaction t);
    bit [15:0] insn;
    bit [ 3:0] op;
    bit [ 2:0] dr, sr1, sr2;
    bit        reads_sr1, reads_sr2, writes;
    bit [ 1:0] d1, d2, c1, c2, cls;
    bit [ 3:0] setter;
    bit [ 2:0] kind;

    insn      = t.data;
    op        = insn[15:12];
    dr        = insn[11:9];
    sr1       = insn[8:6];
    reads_sr1 = op inside {OP_ADD, OP_AND, OP_LDR, OP_STR, OP_NOT, OP_JMP};
    reads_sr2 = (op inside {OP_ADD, OP_AND} && !insn[5]) || op inside {OP_ST, OP_STR, OP_STI};
    sr2       = op inside {OP_ADD, OP_AND} ? insn[2:0] : insn[11:9];
    writes    = writes_reg(op);
    cls       = producer_class(op);
    fetches++;

    d1 = 0;
    d2 = 0;
    if (reads_sr1) find_producer(sr1, d1, c1);
    if (reads_sr2) find_producer(sr2, d2, c2);
    if (d1 != 0) bypass_sr1_cg.sample(c1, op, d1);
    if (d2 != 0) bypass_sr2_cg.sample(c2, op, d2);
    if (d1 != 0 && d2 != 0) mixed_bypass_cg.sample(d1, d2);

    if (d1 == 1 || d2 == 1) begin
      chain_len++;
      chain_cg.sample(chain_len);
    end
    else chain_len = 0;

    if (op == OP_BR) begin
      setter = 9;
      for (int i = 1; i <= 3; i++) begin
        if (hist[i].valid && hist[i].writes) begin
          setter = 4'(hist[i].cls * 3 + (i - 1));
          break;
        end
      end
      branch_history_cg.sample(setter, insn[11:9]);
    end

    if (is_mem(op)) begin
      kind = mem_kind(op);
      if (mem_seen && since_mem <= 2) mem_pair_cg.sample(last_mem_kind, kind, 2'(since_mem));
      if (mem_seen && since_mem == 0) mem_run++;
      else mem_run = 1;
      mem_run_cg.sample(mem_run);
      mem_seen      = 1;
      last_mem_kind = kind;
      since_mem     = 0;
    end
    else if (since_mem < 3) since_mem++;

    if (writes) begin
      for (int i = 1; i <= 2; i++) begin
        if (hist[i].valid && hist[i].writes && hist[i].dr == dr) begin
          waw_cg.sample(hist[i].cls, cls, 2'(i));
          break;
        end
      end
    end

    hist[3]        = hist[2];
    hist[2]        = hist[1];
    hist[1].valid  = 1;
    hist[1].op     = op;
    hist[1].writes = writes;
    hist[1].cls    = cls;
    hist[1].dr     = dr;
  endfunction

  function real pipeline_coverage();
    return (bypass_sr1_cg.get_inst_coverage() + bypass_sr2_cg.get_inst_coverage() +
            mixed_bypass_cg.get_inst_coverage() + branch_history_cg.get_inst_coverage() +
            mem_pair_cg.get_inst_coverage() + mem_run_cg.get_inst_coverage() +
            waw_cg.get_inst_coverage() + chain_cg.get_inst_coverage()) / 8.0;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info("IMEM_PIPELINE_COVERAGE", $sformatf("pipeline coverage over %0d fetches: %6.2f%%",
              fetches, pipeline_coverage()), UVM_LOW)
  endfunction
endclass : imem_pipeline_coverage
