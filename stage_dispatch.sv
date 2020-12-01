module dispatch(
  input logic clk, reset,
  input entry entries_all[BUF_SIZE],
  input unit Unit[2],
  input logic is_valid[2], A_rdy[2],
  input ldst_mode rwmm[2],
  input logic [4:0] Qj[2], Qk[2], Dest[2],
  input logic [9:0] Op[2],
  input logic [31:0] regfile[32], Vj[2], Vk[2], A[2], pc[2],
  output entry entries_new[2],
  output logic [BUF_SIZE_LOG-1:0] indexes[2]
);

logic is_allocatable[2], is_enabled[2], is_spectag_granted[2], is_branch[2], is_used_reg[32], is_not_empty;
logic [5:0] spectag[2], lastused_tag[32];

find_allocatable_entries find(.entries(entries_all), .is_valid(is_allocatable), .indexes);

// generate tag, speculative tag
logic unsigned [BUF_SIZE_LOG:0] tag_before, tag[2];
last_finder find_next_tag(.entries(entries_all), .is_valid(is_not_empty),
    .tag(tag_before), .spec_tag(spec_tag_before), .number_of_store_ops);
assign tag[0] = tag_before - 1;
assign tag[1] = tag_before - 2;

logic [5:0] spec_tag_before;
genvar i;
generate
  for (i = 0; i < 2; i++) begin: assign_is_branch
    assign is_branch[i] = (Unit[i]==BRANCH) & is_valid[i] & is_allocatable[i];
  end
endgenerate
spectag_generator generate_spectag(.clk, .reset, .is_branch, .tag_before(spec_tag_before), .is_acceptable(is_spectag_granted), .tag(spectag));

// Can I use current register's value?
check_reg_used check_regs(.entries(entries_all), .is_valid(is_used_reg), .tags(lastused_tag));

logic [BUF_SIZE_LOG-1:0] number_of_store_ops;
assign entries_new[0].number_of_early_store_ops = number_of_store_ops;
assign entries_new[1].number_of_early_store_ops = number_of_store_ops + ((Unit[0] == STORE) ? 1 : 0);

genvar j;
generate
  for (j = 0; j < 2; j++) begin: assign_entries_new
    assign is_enabled[j] = is_valid[j] & is_allocatable[j] & is_spectag_granted[j];

    // fill entry structure
    assign entries_new[j].A_rdy = A_rdy[j];
    assign entries_new[j].e_state = is_enabled[j] ? S_NOT_EXECUTED : S_NOT_USED;
    assign entries_new[j].Unit = Unit[j];
    assign entries_new[j].rwmm = rwmm[j];
    assign entries_new[j].Dest = Dest[j];
    assign entries_new[j].speculative_tag = spectag[j];
    assign entries_new[j].Op = Op[j];
    assign entries_new[j].A = A[j];
    assign entries_new[j].pc = pc[j];
    assign entries_new[j].result = 32'b0;
    assign entries_new[j].tag = tag[j];

    // already available, or fetch from register, or set entry's tag.
    always_comb
      if (Qj[j] == 0) begin
        entries_new[j].J_rdy = 1;
        entries_new[j].Vj = Vj[j];
        entries_new[j].Qj = 'b0;
      end
      else if (is_used_reg[Qj[j]]) begin
        entries_new[j].J_rdy = 0;
        entries_new[j].Vj = 'b0;
        entries_new[j].Qj = lastused_tag[Qj[j]];
      end
      else begin
        entries_new[j].J_rdy = 1;
        entries_new[j].Vj = regfile[Qj[j]];
        entries_new[j].Qj = 'b0;
      end

    always_comb
      if (Qk[j] == 0) begin
        entries_new[j].K_rdy = 1;
        entries_new[j].Vk = Vj[j];
        entries_new[j].Qk = 'b0;
      end
      else if (is_used_reg[Qk[j]]) begin
        entries_new[j].K_rdy = 0;
        entries_new[j].Vk = 'b0;
        entries_new[j].Qk = lastused_tag[Qk[j]];
      end
      else begin
        entries_new[j].K_rdy = 1;
        entries_new[j].Vk = regfile[Qk[j]];
        entries_new[j].Qk = 'b0;
      end
  end
endgenerate

endmodule


module last_finder(
  input entry entries[BUF_SIZE],
  output logic is_valid,
  output logic [BUF_SIZE_LOG:0] tag,
  output logic [5:0] spec_tag,
  output logic [BUF_SIZE_LOG-1:0] number_of_store_ops
);

logic _is_valid[BUF_SIZE];
logic [BUF_SIZE_LOG:0] mintag[BUF_SIZE];
logic [5:0] _spec_tag[BUF_SIZE];
logic [BUF_SIZE_LOG-1:0] noeso[BUF_SIZE];

assign _is_valid[0] = (entries[0].e_state != S_NOT_USED);
assign mintag[0] = entries[0].tag;
assign _spec_tag[0] = entries[0].speculative_tag;

genvar i;
generate
  for (i = 1; i < BUF_SIZE; i++) begin: Search
    always_comb
    if (entries[i].e_state != S_NOT_USED && (entries[i].tag < mintag[i-1] || !_is_valid[i-1])) begin
      _is_valid[i] = 1;
      mintag[i] = entries[i].tag;
      _spec_tag[i] = entries[i].speculative_tag;
      noeso[i] = entries[i].number_of_early_store_ops + ((entries[i].Unit == STORE) ? 1 : 0);
    end
    else begin
      _is_valid[i] = _is_valid[i-1];
      mintag[i] = mintag[i-1];
      _spec_tag[i] = _spec_tag[i-1];
      noeso[i] = noeso[i-1];
    end
  end
endgenerate

assign is_valid = _is_valid[BUF_SIZE-1];
assign tag = mintag[BUF_SIZE-1];
assign spec_tag = _spec_tag[BUF_SIZE-1];
assign number_of_store_ops = noeso[BUF_SIZE-1];

endmodule


// speculative tag (6bit decoded)
module spectag_generator(
  input logic clk, reset,
  input logic is_branch[2],
  input logic [5:0] tag_before,
  output logic is_acceptable[2],
  output logic [5:0] tag[2]
);

logic [5:0] unused_slot[2], _unused_slot[7], _second_slot[7];

genvar i;
generate
  for (i = 0; i < 6; i++) begin: search_unused_slot
    always_comb
      if (tag_before & (6'b1 << i) == 6'b0) begin
        _unused_slot[i] = (6'b1 << i);
        _second_slot[i] = _unused_slot[i+1];
      end
      else begin
        _unused_slot[i] = _unused_slot[i+1];
        _second_slot[i] = _second_slot[i+1];
      end
  end
endgenerate

assign unused_slot[0] = _unused_slot[0];
assign unused_slot[1] = _second_slot[0];

always_comb
  if (is_branch[0]) begin
    tag[0] = tag_before | unused_slot[0];
    tag[1] = tag[0]     | (is_branch[1] ? unused_slot[1] : 6'b0);

    is_acceptable[0] = (unused_slot[0] != 6'b0);
    is_acceptable[1] = is_branch[1] ? (unused_slot[1] != 6'b0) : 1;
  end
  else begin
    tag[0] = tag_before;
    tag[1] = tag_before | (is_branch[1] ? unused_slot[0] : 6'b0);

    is_acceptable[0] = 1;
    is_acceptable[1] = is_branch[1] ? (unused_slot[0] != 6'b0) : 1;
  end

endmodule


// find not-used entries.
module find_allocatable_entries(
  input entry entries[BUF_SIZE],
  output logic is_valid[2],
  output logic [BUF_SIZE_LOG-1:0] indexes[2]
);

logic _1st_isvld[BUF_SIZE+1], _2nd_isvld[BUF_SIZE+1];
logic [BUF_SIZE_LOG-1:0] _1st_index[BUF_SIZE+1], _2nd_index[BUF_SIZE+1];

assign _1st_isvld[0] = (entries[i].e_state == S_NOT_USED);
assign _2nd_isvld[0] = 0;
assign _1st_index[0] = 'b0;
assign _2nd_index[0] = 'b0;

genvar i;
generate
  for (i = 1; i < BUF_SIZE; i++) begin: search_allocatable_entry
    always_comb
      if (entries[i].e_state == S_NOT_USED) begin
        _1st_isvld[i] = 1;
        _2nd_isvld[i] = _1st_isvld[i-1];
        _1st_index[i] = i;
        _2nd_index[i] = _1st_index[i-1];
      end
      else begin
        _1st_isvld[i] = _1st_isvld[i-1];
        _2nd_isvld[i] = _2nd_isvld[i-1];
        _1st_index[i] = _1st_index[i-1];
        _2nd_index[i] = _2nd_index[i-1];
      end
  end
endgenerate

assign is_valid[0] = _1st_isvld[0];
assign is_valid[1] = _2nd_isvld[0];

assign indexes[0] = _1st_index[0];
assign indexes[1] = _2nd_index[0];

endmodule


// check registers 
module check_reg_used(
  input entry entries[BUF_SIZE],
  output logic is_valid[32],
  output logic [BUF_SIZE_LOG-1:0] tags[32]
);

logic [BUF_SIZE_LOG-1:0] _tags[BUF_SIZE+1][1:31];
logic _is_valid[BUF_SIZE+1][1:31];

// zero register is always zero
assign tags[0] = 'b0;
assign is_valid[0] = 0;

genvar i, j;
generate
  for (i = 1; i < 32; i++) begin: each_registers
    for (j = BUF_SIZE-1; j >= 0; j--) begin: check_dest
      always_comb
        if (entries[j].Dest == i && (!_is_valid[j][i] || (_tags[j][i+1] > entries[j].tag))) begin
          _tags[j][i] = entries[j].tag;
          _is_valid[j][i] = 1;
        end
        else begin
          _tags[j][i] = _tags[j+1][i];
          _is_valid[j][i] = _is_valid[j+1][i];
        end
    end

    assign tags[i] = _tags[0][i];
    assign is_valid[i] = _is_valid[0][i];

  end
endgenerate

endmodule
