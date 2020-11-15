module dispatch(
  input logic clk, reset,
  input entry entries_all[BUF_SIZE],
  input logic is_valid[2], A_rdy[2],
  input logic [2:0] Unit[2], rwmm[2],
  input logic [4:0] Qj[2], Qk[2], Dest[2],
  input logic [9:0] Op[2],
  input logic [31:0] regfile[32], Vj[2], Vk[2], A[2], pc[2],
  output entry entries_new[2],
  output logic [BUF_SIZE_LOG-1:0] indexes[2]
);

logic is_allocatable[2], is_enabled[2], is_spectag_granted[2], is_branch[2], is_used_reg[32];
logic [5:0] spectag[2], lastused_tag[32];

find_allocatable_entries find(.entries(entries_all), .is_valid(is_allocatable), .indexes);

// generate tag
logic unsigned [BUF_SIZE_LOG-1:0] tag_before, tag[2], tag_taken_min;
flopr #(BUF_SIZE_LOG) tag_reg(clk, reset, tag_taken_min, tag_before);
assign tag[0] = tag_before - 1;
assign tag[1] = tag_before - 2;
assign tag_taken_min = is_enabled[1] ? tag[1] : (is_enabled[0] ? tag[0] : tag_before);

// generate speculative tag
genvar i;
generate
  for (i = 0; i < 2; i++) begin: assign_is_branch
    assign is_branch[i] = (Unit[i]==BRANCH) & is_valid[i] & is_allocatable[i];
  end
endgenerate
spectag_generator generate_spectag(.clk, .reset,
  .is_branch, .is_acceptable(is_spectag_granted), .tag(spectag));

// Can I use current register's value?
check_reg_used check_regs(.entries(entries_all), .is_valid(is_used_reg), .tags(lastused_tag));

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

    // cur register OR fetch from CDB
    always_comb
      if (is_used_reg[Qj[j]] == 1) begin
        entries_new[j].Vj = Vj[j];
        entries_new[j].Qj = lastused_tag[Qj[j]];
      end
      else begin
        entries_new[j].Vj = regfile[Qj[j]];
        entries_new[j].Qj = 'b0;
      end

    always_comb
      if (is_used_reg[Qk[j]] == 1) begin
        entries_new[j].Vk = Vk[j];
        entries_new[j].Qk = lastused_tag[Qk[j]];
      end
      else begin
        entries_new[j].Vk = regfile[Qk[j]];
        entries_new[j].Qk = 'b0;
      end
  end
endgenerate

endmodule


// speculative tag (6bit decoded)
module spectag_generator(
  input logic clk, reset,
  input logic is_branch[2],
  output logic is_acceptable[2],
  output logic [5:0] tag[2]
);

logic [5:0] tag_before, tag_taken, unused_slot[2], _unused_slot[7], _second_slot[7];

flopr #(6) tag_reg(clk, reset, tag_taken, tag_before);
assign tag_taken = tag[1];

genvar i;
generate
  for (i = 5; i >= 0; i--) begin: search_unused_slot
    always_comb
      if ((tag_before & (6'b1 << i)) == 6'b0) begin
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
  if (is_branch[0] == 0) begin
    tag[0] = tag_before;
    tag[1] = tag_before | ((is_branch[1] == 0) ? 6'b0 : unused_slot[0]);

    is_acceptable[0] = 1;
    is_acceptable[1] = (is_branch[1] == 0) ? 1 : (unused_slot[0] != 6'b0);
  end
  else begin
    tag[0] = tag_before | unused_slot[0];
    tag[1] = tag[0]     | ((is_branch[1] == 0) ? 6'b0 : unused_slot[1]);

    is_acceptable[0] = (unused_slot[0] != 6'b0);
    is_acceptable[1] = (is_branch[1] == 0) ? 1 : (unused_slot[1] != 6'b0);
  end

endmodule


// find not-used entries.
module find_allocatable_entries(
  input entry entries[BUF_SIZE-1:0],
  output logic is_valid[2],
  output logic [BUF_SIZE_LOG-1:0] indexes[2]
);

logic _1st_isvld[BUF_SIZE:0];
logic _2nd_isvld[BUF_SIZE:0];

logic [BUF_SIZE_LOG-1:0] _1st_index[BUF_SIZE:0];
logic [BUF_SIZE_LOG-1:0] _2nd_index[BUF_SIZE:0];

genvar i;
generate
  for (i = BUF_SIZE-1; i >= 0; i--) begin: search_allocatable_entry
    always_comb
      if (entries[i].e_state == S_NOT_USED) begin
        _1st_isvld[i] = 1;
        _2nd_isvld[i] = _1st_isvld[i+1];
        _1st_index[i] = i;
        _2nd_index[i] = _1st_index[i+1];
      end
      else begin
        _1st_isvld[i] = _1st_isvld[i+1];
        _2nd_isvld[i] = _2nd_isvld[i+1];
        _1st_index[i] = _1st_index[i+1];
        _2nd_index[i] = _2nd_index[i+1];
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
  input entry entries[BUF_SIZE-1:0],
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
        if (entries[j].Dest == i
            && (!_is_valid[j][i] || (_tags[j][i+1]>entries[j].tag))) begin
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
