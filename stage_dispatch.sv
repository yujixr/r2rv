module dispatch(
  input entry_t entries_all[BUF_SIZE],
  input logic [31:0] reg_data[4],
  input decode_result_t decoded[2],
  output logic is_valid[2], is_allocatable[2],
  output logic [4:0] reg_addr[4],
  output index_t indexes[2],
  output entry_t entries_new[2]
);

bool is_buffer_ok[2], is_spectag_ok[2], is_branch[2], is_used_reg[4], is_calculated[4], is_not_empty;
logic [4:0] reg_target[4];
logic [31:0] calculated_value[4];
spectag_t spectag[2], spectag_specific[2], spec_tag_before;
index_t number_of_store_ops;
tag_t lastused_tag[4], tag_before, tag[2];
entry_t latest_entry;

finder_next find(.entries(entries_all),
  .is_valid_indexes(is_buffer_ok), .is_valid_latest_entry(is_not_empty),
  .allocatable_indexes(indexes), .latest_entry(latest_entry));

assign tag_before = latest_entry.tag;
assign spec_tag_before = latest_entry.speculative_tag;

always_comb
  if (latest_entry.Unit == STORE) begin
    number_of_store_ops = latest_entry.number_of_early_store_ops + 1'b1;
  end
  else begin
    number_of_store_ops = latest_entry.number_of_early_store_ops;
  end

// generate tag, speculative tag
always_comb
  if (!is_not_empty) begin
    tag[0] = 4'b0000;
    tag[1] = 4'b0001;
  end
  else if (tag_before == 4'b1111) begin
    tag[0] = 4'b0000;
    tag[1] = 4'b0001;
  end
  else if (tag_before == 4'b1110) begin
    tag[0] = 4'b1111;
    tag[1] = 4'b0000;
  end
  else begin
    tag[0] = tag_before + 4'b0001;
    tag[1] = tag_before + 4'b0010;
  end

genvar i;
generate
  for (i = 0; i < 2; i++) begin: assign_is_branch
    assign is_branch[i] = bool'(decoded[i].Unit == BRANCH);
  end
endgenerate

spectag_generator generate_spectag(
  .is_branch(is_branch), .tag_before(spec_tag_before), .is_valid(is_spectag_ok),
  .tag(spectag), .tag_specific(spectag_specific)
);

check_reg_used check_regs(
  .entries(entries_all), .reg_target, .is_used(is_used_reg),
  .is_calculated, .tags(lastused_tag), .calculated_value
);

assign entries_new[0].number_of_early_store_ops = number_of_store_ops;
assign entries_new[1].number_of_early_store_ops = number_of_store_ops + ((decoded[0].Unit == STORE) ? 1'b1 : '0);

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
        entries_new[j].J_rdy = true;
        entries_new[j].Vj    = decoded[j].Vj;
        entries_new[j].Qj    = 'b0;
      end
      else if (!is_used_reg[j*2]) begin
        reg_addr[j*2]        = decoded[j].Qj;
        entries_new[j].J_rdy = true;
        entries_new[j].Vj    = reg_data[j*2];
        entries_new[j].Qj    = 'b0;
      end
      else if(is_calculated[j*2]) begin
        reg_addr[j*2]        = 5'b0;
        entries_new[j].J_rdy = true;
        entries_new[j].Vj    = calculated_value[j*2];
        entries_new[j].Qj    = 'b0;
      end
      else begin
        reg_addr[j*2]        = 5'b0;
        entries_new[j].J_rdy = false;
        entries_new[j].Vj    = 32'b0;
        entries_new[j].Qj    = lastused_tag[j*2];
      end

    always_comb
      if (decoded[j].Qk == 0) begin
        reg_addr[j*2+1]      = 5'b0;
        entries_new[j].K_rdy = true;
        entries_new[j].Vk    = decoded[j].Vk;
        entries_new[j].Qk    = 'b0;
      end
      else if (!is_used_reg[j*2+1]) begin
        reg_addr[j*2+1]      = decoded[j].Qk;
        entries_new[j].K_rdy = true;
        entries_new[j].Vk    = reg_data[j*2+1];
        entries_new[j].Qk    = 'b0;
      end
      else if(is_calculated[j*2+1]) begin
        reg_addr[j*2+1]      = 5'b0;
        entries_new[j].K_rdy = true;
        entries_new[j].Vk    = calculated_value[j*2+1];
        entries_new[j].Qk    = 'b0;
      end
      else begin
        reg_addr[j*2+1]      = 5'b0;
        entries_new[j].K_rdy = false;
        entries_new[j].Vk    = 32'b0;
        entries_new[j].Qk    = lastused_tag[j*2+1];
      end
  end
endgenerate

endmodule


module finder_next(
  input entry_t entries[BUF_SIZE],
  output bool is_valid_indexes[2], is_valid_latest_entry,
  output index_t allocatable_indexes[2],
  output entry_t latest_entry
);

index_t _minval_index[BUF_SIZE], _second_index[BUF_SIZE];
entry_t _latest_entry[BUF_SIZE];

always_comb
  if (entries[BUF_SIZE-1].e_state == S_NOT_USED) begin
    _latest_entry[BUF_SIZE-1] = entries[BUF_SIZE-2];
  end
  else begin
    _latest_entry[BUF_SIZE-1] = entries[BUF_SIZE-1];
  end

assign _minval_index[BUF_SIZE-1] = $bits(index_t)'(BUF_SIZE-1);
assign _second_index[BUF_SIZE-1] = 'b0;

genvar i;
generate
  for (i = BUF_SIZE-2; i >= 1; i--) begin: free_entry
    always_comb
      if (entries[i].e_state == S_NOT_USED) begin
        _minval_index[i]    = $bits(index_t)'(i);
        _second_index[i]    = $bits(index_t)'(i+1);
        _latest_entry[i]    = entries[i-1];
      end
      else begin
        _minval_index[i]    = _minval_index[i+1];
        _second_index[i]    = _second_index[i+1];
        _latest_entry[i]    = _latest_entry[i+1];
      end
  end
endgenerate

always_comb
  if (entries[0].e_state == S_NOT_USED) begin
    allocatable_indexes[0] = $bits(index_t)'(0);
    allocatable_indexes[1] = $bits(index_t)'(1);
    latest_entry           = 'b0;
  end
  else begin
    allocatable_indexes[0] = _minval_index[1];
    allocatable_indexes[1] = _second_index[1];
    latest_entry           = _latest_entry[1];
  end

assign is_valid_indexes[0] = bool'(entries[BUF_SIZE-1].e_state == S_NOT_USED);
assign is_valid_indexes[1] = bool'(entries[BUF_SIZE-2].e_state == S_NOT_USED);
assign is_valid_latest_entry = bool'(entries[0].e_state != S_NOT_USED);

endmodule


// speculative tag (6bit decoded)
module spectag_generator(
  input logic is_branch[2],
  input spectag_t tag_before,
  output bool is_valid[2],
  output spectag_t tag[2], tag_specific[2]
);

bool _is_valid[2], _unused_isvld[6], _second_isvld[6];
spectag_t unused_slot[2], _unused_slot[6], _second_slot[6];

assign _unused_isvld[0] = bool'((tag_before & 6'b000001) == '0);
assign _second_isvld[0] = false;
assign _unused_slot[0]  = 6'b000001;
assign _second_slot[0]  = '0;

genvar i;
generate
  for (i = 1; i < 6; i++) begin: search_unused_slot
    always_comb
      if (tag_before & (6'b000001 << i) == '0) begin
        _unused_isvld[i] = true;
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
    is_valid[0]       = true;
    if (is_branch[1]) begin
      tag[1]          = tag[0] | unused_slot[0];
      tag_specific[1] = unused_slot[0];
      is_valid[1]     = _is_valid[0];
    end
    else begin
      tag[1]          = tag[0];
      tag_specific[1] = 6'b0;
      is_valid[1]     = true;
    end
  end

endmodule


// check registers 
module check_reg_used(
  input entry_t entries[BUF_SIZE],
  input logic [4:0] reg_target[4],
  output bool is_used[4], is_calculated[4],
  output tag_t tags[4],
  output logic [31:0] calculated_value[4]
);

bool _is_used[BUF_SIZE*4], _is_calculated[BUF_SIZE*4];
tag_t _tags[BUF_SIZE*4];
logic [31:0] _calculated_value[BUF_SIZE*4];

genvar i, j;
generate
  for (i = 0; i < 4; i++) begin: each_registers
    assign _is_used[BUF_SIZE*i]          = bool'(entries[0].Dest == reg_target[i]);
    assign _is_calculated[BUF_SIZE*i]    = bool'(entries[0].e_state == S_EXECUTED);
    assign _tags[BUF_SIZE*i]             = entries[0].tag;
    assign _calculated_value[BUF_SIZE*i] = entries[0].result;

    for (j = 1; j < BUF_SIZE; j++) begin: check_dest
      always_comb
        if (entries[j].Dest == reg_target[i]) begin
          _is_used[BUF_SIZE*i+j]          = true;
          _is_calculated[BUF_SIZE*i+j]    = bool'(entries[j].e_state == S_EXECUTED);
          _tags[BUF_SIZE*i+j]             = entries[j].tag;
          _calculated_value[BUF_SIZE*i+j] = entries[j].result;
        end
        else begin
          _is_used[BUF_SIZE*i+j]          = _is_used[BUF_SIZE*i+j-1];
          _is_calculated[BUF_SIZE*i+j]    = _is_calculated[BUF_SIZE*i+j-1];
          _tags[BUF_SIZE*i+j]             = _tags[BUF_SIZE*i+j-1];
          _calculated_value[BUF_SIZE*i+j] = _calculated_value[BUF_SIZE*i+j-1];
        end
    end

    assign is_used[i]          = _is_used[BUF_SIZE*(i+1)-1];
    assign is_calculated[i]    = _is_calculated[BUF_SIZE*(i+1)-1];
    assign tags[i]             = _tags[BUF_SIZE*(i+1)-1];
    assign calculated_value[i] = _calculated_value[BUF_SIZE*(i+1)-1];
  end
endgenerate

endmodule
