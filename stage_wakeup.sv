typedef struct packed {
  logic is_valid;
  unit Unit;
  ex_mode mode;
  ldst_mode rm;
  logic [5:0] speculative_tag;
  logic [9:0] Op;
  logic [31:0] Vj, Vk, A, pc;
  logic [BUF_SIZE_LOG:0] tag;
} ex_content;

module wakeup(
  input logic is_tag_flooded,
  input entry entries[BUF_SIZE-1:0],
  output ex_content ex_contents[2]
);

logic is_valid[2];
entry entries_target[2];

find_executable_entries find(.entries_all(entries), .is_valid, .entries_target);

genvar i;
generate
  for (i = 0; i < 2; i++) begin: Build_ex_contents
    assign ex_contents[i].is_valid        = is_valid[i];
    assign ex_contents[i].rm              = entries_target[i].rwmm;
    assign ex_contents[i].speculative_tag = entries_target[i].specific_speculative_tag;
    assign ex_contents[i].Vj              = entries_target[i].Vj;
    assign ex_contents[i].A               = entries_target[i].A;
    assign ex_contents[i].pc              = entries_target[i].pc;

    always_comb
      if (is_tag_flooded) begin
        ex_contents[i].tag = { 1'b1, entries_target[i].tag[BUF_SIZE_LOG-1:0] };
      end
      else begin
        ex_contents[i].tag = entries_target[i].tag;
      end

    always_comb
      if (entries_target[i].A_rdy) begin
        ex_contents[i].mode = EX_NORMAL;
        ex_contents[i].Unit = entries_target[i].Unit;
        ex_contents[i].Op   = entries_target[i].Op;
        ex_contents[i].Vk   = entries_target[i].Vk;
      end
      else begin
        ex_contents[i].mode = EX_GEN_ADDR;
        ex_contents[i].Unit = ALU;
        ex_contents[i].Op   = 10'b0;
        ex_contents[i].Vk   = entries_target[i].A;
      end
  end
endgenerate

endmodule


// find not-executed entries with maximum tag.
module find_executable_entries(
  input entry entries_all[BUF_SIZE],
  output logic is_valid[2],
  output entry entries_target[2]
);

logic _max_is_valid[BUF_SIZE], _2nd_is_valid[BUF_SIZE];
entry _maximum[BUF_SIZE], _2nd_max[BUF_SIZE];

always_comb
  if (entries_all[0].J_rdy && entries_all[0].K_rdy
    && (entries_all[0].e_state == S_NOT_EXECUTED || entries_all[0].e_state == S_ADDR_GENERATED)
    && (entries_all[0].Unit != LOAD || entries_all[0].number_of_early_store_ops == 0)) begin
    _max_is_valid[0] = 1;
    _maximum[0] = entries_all[0];
  end
  else begin
    _max_is_valid[0] = 0;
    _maximum[0] = 0;
  end

assign _2nd_is_valid[0] = 0;
assign _2nd_max[0] = 0;

genvar i;
generate
  for (i = 1; i < BUF_SIZE; i++) begin: Search
    always_comb
      if ((!_2nd_is_valid[i-1] || _2nd_max[i-1].tag < entries_all[i].tag)
        && entries_all[i].J_rdy && entries_all[i].K_rdy
        && (entries_all[i].e_state == S_NOT_EXECUTED || entries_all[i].e_state == S_ADDR_GENERATED)
        && (entries_all[i].Unit != LOAD || entries_all[i].number_of_early_store_ops == 0)) begin
        _max_is_valid[i] = 1;
        _2nd_is_valid[i] = _max_is_valid[i-1];
        if (entries_all[i].tag > _maximum[i-1].tag) begin
          _maximum[i] = entries_all[i];
          _2nd_max[i] = _maximum[i-1];
        end
        else begin
          _maximum[i] = _maximum[i-1];
          _2nd_max[i] = entries_all[i];
        end
      end
      else begin
        _max_is_valid[i] = _max_is_valid[i-1];
        _2nd_is_valid[i] = _2nd_is_valid[i-1];
        _maximum[i] = _maximum[i-1];
        _2nd_max[i] = _2nd_max[i-1];
        end
  end
endgenerate

assign is_valid[0] = _max_is_valid[BUF_SIZE-1];
assign is_valid[1] = _2nd_is_valid[BUF_SIZE-1];
assign entries_target[0] = _maximum[BUF_SIZE-1];
assign entries_target[1] = _2nd_max[BUF_SIZE-1];

endmodule
