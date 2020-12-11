module dispatch(
  input entry_t entries_all[BUF_SIZE],
  input logic [31:0] reg_data[4],
  input decode_result_t decoded[2],
  output logic is_valid[2], is_allocatable[2], is_tag_flooded,
  output logic [4:0] reg_addr[4],
  output index_t indexes[2],
  output entry_t entries_new[2]
);

logic is_buffer_ok[2], is_spectag_ok[2], is_branch[2], is_used_reg[4], is_not_empty;
logic [4:0] reg_target[4];
logic [5:0] spectag[2], spectag_specific[2], spec_tag_before;
index_t number_of_store_ops;
tag_t lastused_tag[4];

find_allocatable_entries find(.entries(entries_all), .is_valid(is_buffer_ok), .indexes);

// generate tag, speculative tag
tag_t tag_before, tag[2];
last_finder find_last_entry(.entries(entries_all), .is_valid(is_not_empty),
    .tag(tag_before), .spec_tag(spec_tag_before), .number_of_store_ops);
always_comb
  if (!is_not_empty) begin
    tag[0] = 5'b01111;
    tag[1] = 5'b01110;
    is_tag_flooded = 0;
  end
  else if (tag_before == 5'b00000) begin
    tag[0] = 5'b01111;
    tag[1] = 5'b01110;
    is_tag_flooded = 1;
  end
  else if (tag_before == 5'b00001) begin
    tag[0] = 5'b10000;
    tag[1] = 5'b01111;
    is_tag_flooded = 1;
  end
  else begin
    tag[0] = tag_before - 5'b00001;
    tag[1] = tag_before - 5'b00010;
    is_tag_flooded = 0;
  end

genvar i;
generate
  for (i = 0; i < 2; i++) begin: assign_is_branch
    assign is_branch[i] = (decoded[i].Unit==BRANCH);
  end
endgenerate
spectag_generator generate_spectag(.is_branch, .tag_before(spec_tag_before), .is_valid(is_spectag_ok), .tag(spectag), .tag_specific(spectag_specific));
check_reg_used check_regs(.entries(entries_all), .reg_target, .is_used(is_used_reg), .tags(lastused_tag));

assign entries_new[0].number_of_early_store_ops = number_of_store_ops;
assign entries_new[1].number_of_early_store_ops = number_of_store_ops + ((decoded[0].Unit == STORE) ? BUF_SIZE_LOG'(1) : '0);

genvar j;
generate
  for (j = 0; j < 2; j++) begin: assign_entries_new
    assign is_allocatable[j] = is_buffer_ok[j] & is_spectag_ok[j];
    assign is_valid[j] = decoded[j].is_valid & is_allocatable[j];

    // fill entry structure
    assign entries_new[j].A_rdy                    = decoded[j].A_rdy;
    assign entries_new[j].e_state                  = S_NOT_EXECUTED;
    assign entries_new[j].Unit                     = decoded[j].Unit;
    assign entries_new[j].rwmm                     = decoded[j].rwmm;
    assign entries_new[j].Dest                     = decoded[j].Dest;
    assign entries_new[j].speculative_tag          = spectag[j];
    assign entries_new[j].specific_speculative_tag = spectag_specific[j];
    assign entries_new[j].Op                       = decoded[j].Op;
    assign entries_new[j].A                        = decoded[j].A;
    assign entries_new[j].pc                       = decoded[j].pc;
    assign entries_new[j].result                   = 32'b0;
    assign entries_new[j].tag                      = tag[j];

    assign reg_target[j*2]   = decoded[j].Qj;
    assign reg_target[j*2+1] = decoded[j].Qk;

    // already available, or fetch from register, or set entry's tag.
    always_comb
      if (decoded[j].Qj == 0) begin
        reg_addr[j*2]        = 5'b0;
        entries_new[j].J_rdy = 1;
        entries_new[j].Vj    = decoded[j].Vj;
        entries_new[j].Qj    = 'b0;
      end
      else if (is_used_reg[j*2]) begin
        reg_addr[j*2]        = 5'b0;
        entries_new[j].J_rdy = 0;
        entries_new[j].Vj    = 32'b0;
        entries_new[j].Qj    = lastused_tag[j*2];
      end
      else begin
        reg_addr[j*2]        = decoded[j].Qj;
        entries_new[j].J_rdy = 1;
        entries_new[j].Vj    = reg_data[j*2];
        entries_new[j].Qj    = 'b0;
      end

    always_comb
      if (decoded[j].Qk == 0) begin
        reg_addr[j*2+1]      = 5'b0;
        entries_new[j].K_rdy = 1;
        entries_new[j].Vk    = decoded[j].Vk;
        entries_new[j].Qk    = 'b0;
      end
      else if (is_used_reg[j*2+1]) begin
        reg_addr[j*2+1]      = 5'b0;
        entries_new[j].K_rdy = 0;
        entries_new[j].Vk    = 32'b0;
        entries_new[j].Qk    = lastused_tag[j*2+1];
      end
      else begin
        reg_addr[j*2+1]      = decoded[j].Qk;
        entries_new[j].K_rdy = 1;
        entries_new[j].Vk    = reg_data[j*2+1];
        entries_new[j].Qk    = 'b0;
      end
  end
endgenerate

endmodule


module last_finder(
  input entry_t entries[BUF_SIZE],
  output logic is_valid,
  output tag_t tag,
  output logic [5:0] spec_tag,
  output index_t number_of_store_ops
);

logic _is_valid[BUF_SIZE];
tag_t mintag[BUF_SIZE];
logic [5:0] _spec_tag[BUF_SIZE];
index_t _number_of_store_ops[BUF_SIZE];

assign _is_valid[0] = entries[0].e_state != S_NOT_USED;
assign mintag[0]    = entries[0].tag;
assign _spec_tag[0] = entries[0].speculative_tag;

always_comb
  if (entries[0].Unit == STORE) begin
    _number_of_store_ops[0] = entries[0].number_of_early_store_ops + BUF_SIZE_LOG'(1);
  end
  else begin
    _number_of_store_ops[0] = entries[0].number_of_early_store_ops;
  end

genvar i;
generate
  for (i = 1; i < BUF_SIZE; i++) begin: Search
    always_comb
    if (entries[i].e_state != S_NOT_USED && (entries[i].tag < mintag[i-1] || !_is_valid[i-1])) begin
      _is_valid[i] = 1;
      mintag[i]    = entries[i].tag;
      _spec_tag[i] = entries[i].speculative_tag;

      if (entries[i].Unit == STORE) begin
        _number_of_store_ops[i] = entries[i].number_of_early_store_ops + BUF_SIZE_LOG'(1);
      end
      else begin
        _number_of_store_ops[i] = entries[i].number_of_early_store_ops;
      end
    end
    else begin
      _is_valid[i]            = _is_valid[i-1];
      mintag[i]               = mintag[i-1];
      _spec_tag[i]            = _spec_tag[i-1];
      _number_of_store_ops[i] = _number_of_store_ops[i-1];
    end
  end
endgenerate

assign is_valid            = _is_valid[BUF_SIZE-1];
assign tag                 = mintag[BUF_SIZE-1];
assign spec_tag            = _spec_tag[BUF_SIZE-1];
assign number_of_store_ops = _number_of_store_ops[BUF_SIZE-1];

endmodule


// speculative tag (6bit decoded)
module spectag_generator(
  input logic is_branch[2],
  input logic [5:0] tag_before,
  output logic is_valid[2],
  output logic [5:0] tag[2], tag_specific[2]
);

logic _is_valid[2], _unused_isvld[6], _second_isvld[6];
logic [5:0] unused_slot[2], _unused_slot[6], _second_slot[6];

assign _unused_isvld[0] = ((tag_before & 6'b000001) == '0);
assign _second_isvld[0] = 0;
assign _unused_slot[0] = 6'b000001;
assign _second_slot[0] = '0;

genvar i;
generate
  for (i = 1; i < 6; i++) begin: search_unused_slot
    always_comb
      if (tag_before & (6'b000001 << i) == '0) begin
        _unused_isvld[i] = 1;
        _second_isvld[i] = _unused_isvld[i-1];
        _unused_slot[i] = (6'b000001 << i);
        _second_slot[i] = _unused_slot[i-1];
      end
      else begin
        _unused_isvld[i] = _unused_isvld[i-1];
        _second_isvld[i] = _second_isvld[i-1];
        _unused_slot[i] = _unused_slot[i-1];
        _second_slot[i] = _second_slot[i-1];
      end
  end
endgenerate

assign _is_valid[0] = _unused_isvld[5];
assign _is_valid[1] = _second_isvld[5];
assign unused_slot[0] = _unused_slot[5];
assign unused_slot[1] = _second_slot[5];

always_comb
  if (is_branch[0]) begin
    tag[0]            = tag_before | unused_slot[0];
    tag_specific[0]   = unused_slot[0];
    is_valid[0]       = _is_valid[0];
    if (is_branch[1]) begin
      tag[1]          = tag[0] | unused_slot[1];
      tag_specific[1] = unused_slot[1];
      is_valid[1]     = _is_valid[1];
    end
    else begin
      tag[1]          = tag[0];
      tag_specific[1] = 6'b0;
      is_valid[1]     = _is_valid[0];
    end
  end
  else begin
    tag[0]            = tag_before;
    tag_specific[0]   = 6'b0;
    is_valid[0]       = 1;
    if (is_branch[1]) begin
      tag[1]          = tag[0] | unused_slot[0];
      tag_specific[1] = unused_slot[0];
      is_valid[1]     = _is_valid[0];
    end
    else begin
      tag[1]          = tag[0];
      tag_specific[1] = 6'b0;
      is_valid[1]     = 1;
    end
  end

endmodule


// find not-used entries.
module find_allocatable_entries(
  input entry_t entries[BUF_SIZE],
  output logic is_valid[2],
  output index_t indexes[2]
);

logic _1st_isvld[BUF_SIZE], _2nd_isvld[BUF_SIZE];
index_t _1st_index[BUF_SIZE], _2nd_index[BUF_SIZE];

assign _1st_isvld[0] = (entries[0].e_state == S_NOT_USED);
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
        _1st_index[i] = BUF_SIZE_LOG'(i);
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

assign is_valid[0] = _1st_isvld[BUF_SIZE-1];
assign is_valid[1] = _2nd_isvld[BUF_SIZE-1];

assign indexes[0] = _1st_index[BUF_SIZE-1];
assign indexes[1] = _2nd_index[BUF_SIZE-1];

endmodule


// check registers 
module check_reg_used(
  input entry_t entries[BUF_SIZE],
  input logic [4:0] reg_target[4],
  output logic is_used[4],
  output tag_t tags[4]
);

tag_t _tags[BUF_SIZE*4];
logic _is_used[BUF_SIZE*4];

genvar i, j;
generate
  for (i = 0; i < 4; i++) begin: each_registers
    assign _tags[BUF_SIZE*i]    = entries[0].tag;
    assign _is_used[BUF_SIZE*i] = entries[0].Dest == reg_target[i];

    for (j = 1; j < BUF_SIZE; j++) begin: check_dest
      always_comb
        if (entries[j].Dest == reg_target[i]
          && (!_is_used[BUF_SIZE*i+j-1] || (_tags[BUF_SIZE*i+j-1] > entries[j].tag))) begin
          _tags[BUF_SIZE*i+j]    = entries[j].tag;
          _is_used[BUF_SIZE*i+j] = 1;
        end
        else begin
          _tags[BUF_SIZE*i+j]    = _tags[BUF_SIZE*i+j-1];
          _is_used[BUF_SIZE*i+j] = _is_used[BUF_SIZE*i+j-1];
        end
    end

    assign tags[i]    = _tags[BUF_SIZE*(i+1)-1];
    assign is_used[i] = _is_used[BUF_SIZE*(i+1)-1];
  end
endgenerate

endmodule
