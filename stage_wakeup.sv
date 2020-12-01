typedef struct packed {
  logic is_valid;
  unit Unit;
  ex_mode mode;
  ldst_mode rwmm;
  logic [9:0] Op;
  logic [31:0] Vj, Vk, A, pc;
  logic [BUF_SIZE_LOG:0] tag;
} ex_content;

module wakeup(
  input entry entries[BUF_SIZE-1:0],
  output is_valid[2],
  output [BUF_SIZE_LOG:0] tags[2],
  output ex_content ex_contents[2]
);

logic [BUF_SIZE_LOG-1:0] indexes[2];
entry entries_target[2];

find_executable_entries find(.entries, .is_valid, .indexes);

genvar i;
generate
  for (i = 0; i < 2; i++) begin: Build_ex_contents
    assign entries_target[i] = entries[indexes[i]];
    assign tags[i] = ex_contents[i].tag;
    assign ex_contents[i].is_valid = is_valid[i];
    assign ex_contents[i].Unit = entries_target[i].Unit;
    assign ex_contents[i].rwmm = entries_target[i].rwmm;
    assign ex_contents[i].Op = entries_target[i].Op;
    assign ex_contents[i].Vj = entries_target[i].Vj;
    assign ex_contents[i].Vk = entries_target[i].Vk;
    assign ex_contents[i].A = entries_target[i].A;
    assign ex_contents[i].pc = entries_target[i].pc;
    assign ex_contents[i].tag = entries_target[i].tag;

    always_comb
      if (entries_target[i].e_state == S_NOT_EXECUTED
        && (entries_target[i].Unit == STORE || entries_target[i].Unit == LOAD)) begin
        ex_contents[i].mode =  EX_GEN_ADDR;
      end
      else begin
        ex_contents[i].mode =  EX_NORMAL;
      end
  end
endgenerate

endmodule


// find not-executed entries with maximum tag.
module find_executable_entries(
  input entry entries[BUF_SIZE-1:0],
  output logic is_valid[1:0],
  output logic [BUF_SIZE_LOG-1:0] indexes[1:0]
);

logic [BUF_SIZE_LOG-1:0] _maximum_idx[BUF_SIZE], _2nd_max_idx[BUF_SIZE];
logic [BUF_SIZE_LOG:0] _maximum_tag[BUF_SIZE], _2nd_max_tag[BUF_SIZE];

genvar i;
generate
  for (i = 0; i < BUF_SIZE; i++) begin: Search
    always_comb
      if (_2nd_max_tag[i+1] < entries[i].tag && entries[i].J_rdy && entries[i].K_rdy && entries[i].A_rdy
        && (entries[i].e_state == S_NOT_EXECUTED
        || (entries[i].e_state == S_ADDR_GENERATED && entries[i].number_of_early_store_ops == 0))) begin

        // index
        _maximum_idx[i] = (entries[i].tag > _maximum_tag[i+1]) ? i : _maximum_idx[i+1];
        _2nd_max_idx[i] = (entries[i].tag < _maximum_tag[i+1]) ? i : _maximum_idx[i+1];

        // tag
        _maximum_tag[i] = (entries[i].tag > _maximum_tag[i+1]) ? entries[i].tag : _maximum_tag[i+1];
        _2nd_max_tag[i] = (entries[i].tag < _maximum_tag[i+1]) ? entries[i].tag : _maximum_tag[i+1];
        
      end
      else begin
        _maximum_idx[i] = _maximum_idx[i+1];
        _2nd_max_idx[i] = _2nd_max_idx[i+1];
        _maximum_tag[i] = _maximum_tag[i+1];
        _2nd_max_tag[i] = _2nd_max_tag[i+1];
        end
  end
endgenerate

assign is_valid[0] = _maximum_tag[0] != 0;
assign is_valid[1] = _2nd_max_tag[0] != 0;

assign indexes[0] = _maximum_idx[0];
assign indexes[1] = _2nd_max_idx[0];

endmodule
