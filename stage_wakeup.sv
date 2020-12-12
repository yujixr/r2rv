typedef struct packed {
  bool is_valid;
  unit_t Unit;
  ex_mode_t mode;
  ldst_mode_t rm;
  spectag_t speculative_tag;
  logic [9:0] Op;
  logic [31:0] Vj, Vk, A, pc;
  tag_t tag;
} ex_content_t;

module wakeup(
  input entry_t entries[BUF_SIZE-1:0],
  output ex_content_t ex_contents[2]
);

bool is_valid[2];
entry_t entries_target[2];

find_executable_entries find(.entries_all(entries), .is_valid, .entries_target);

genvar i;
generate
  for (i = 0; i < 2; i++) begin: Build_ex_contents
    assign ex_contents[i].is_valid        = is_valid[i];
    assign ex_contents[i].tag             = entries_target[i].tag;
    assign ex_contents[i].rm              = entries_target[i].rwmm;
    assign ex_contents[i].speculative_tag = entries_target[i].specific_speculative_tag;
    assign ex_contents[i].Vj              = entries_target[i].Vj;
    assign ex_contents[i].A               = entries_target[i].A;
    assign ex_contents[i].pc              = entries_target[i].pc;

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
  input entry_t entries_all[BUF_SIZE],
  output bool is_valid[2],
  output entry_t entries_target[2]
);

bool is_executable[BUF_SIZE], is_valid_minval[BUF_SIZE], is_valid_second[BUF_SIZE];
entry_t minval_entry[BUF_SIZE], second_entry[BUF_SIZE];

executable_validation validate_latest(.entry(entries_all[BUF_SIZE-1]),
  .is_executable(is_executable[BUF_SIZE-1]));

assign is_valid_minval[BUF_SIZE-1] = is_executable[BUF_SIZE-1];
assign is_valid_second[BUF_SIZE-1] = false;
assign minval_entry[BUF_SIZE-1] = entries_all[BUF_SIZE-1];
assign second_entry[BUF_SIZE-1] = 'b0;

genvar i;
generate
  // Going smaller index, validating older entry.
  for (i = BUF_SIZE-2; i >= 0; i--) begin: Search
    executable_validation validate(.entry(entries_all[i]), .is_executable(is_executable[i]));
    always_comb
      if (is_executable[i] == true) begin
        is_valid_minval[i] = true;
        is_valid_second[i] = is_valid_minval[i+1];
        minval_entry[i] = entries_all[i];
        second_entry[i] = minval_entry[i+1];
      end
      else begin
        is_valid_minval[i] = is_valid_minval[i+1];
        is_valid_second[i] = is_valid_second[i+1];
        minval_entry[i] = minval_entry[i+1];
        second_entry[i] = second_entry[i+1];
        end
  end
endgenerate

assign is_valid[0] = is_valid_minval[0];
assign is_valid[1] = is_valid_second[0];
assign entries_target[0] = minval_entry[0];
assign entries_target[1] = second_entry[0];

endmodule


module executable_validation(
  input entry_t entry,
  output bool is_executable
);

always_comb
  if (entry.J_rdy && entry.K_rdy
    && (entry.e_state == S_NOT_EXECUTED || entry.e_state == S_ADDR_GENERATED)
    && (entry.Unit != LOAD || entry.number_of_early_store_ops == 0)) begin
    is_executable = true;
  end
  else begin
    is_executable = false;
  end

endmodule
