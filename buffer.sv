parameter BUF_SIZE_LOG = 4;
parameter BUF_SIZE = 2**BUF_SIZE_LOG;

typedef logic [BUF_SIZE_LOG-1:0] index_t;
typedef logic [BUF_SIZE_LOG:0] tag_t;
typedef logic [5:0] spectag_t;

typedef enum logic {
  false = 1'b0,
  true  = 1'b1
} bool;

typedef enum logic [2:0] {
  S_NOT_USED = 3'b0,
  S_NOT_EXECUTED,
  S_EXECUTING,
  S_ADDR_GENERATED,
  S_EXECUTED
} state_t;

typedef enum logic [2:0] {
  ALU,
  BRANCH,
  MUL,
  DIV,
  LOAD,
  STORE
} unit_t;

typedef enum logic [2:0] {
  BYTE        = 3'b000,
  HALF_WORD   = 3'b001,
  WORD        = 3'b010,
  U_BYTE      = 3'b100,
  U_HALF_WORD = 3'b101
} ldst_mode_t;

typedef enum logic {
  EX_NORMAL,
  EX_GEN_ADDR
} ex_mode_t;

typedef struct packed {
  bool J_rdy, K_rdy, A_rdy;
  state_t e_state;
  unit_t Unit;
  ldst_mode_t rwmm;
  logic [4:0] Dest;
  spectag_t speculative_tag, specific_speculative_tag;
  logic [9:0] Op;
  logic [31:0] Vj, Vk, A, pc, result;
  index_t number_of_early_store_ops;
  tag_t Qj, Qk, tag;
} entry_t;

module buffer(
  input logic clk, reset,

  // from DISPATCH stage
  input logic is_valid_allocation[2], is_tag_flooded,
  input index_t allocation_indexes[2],
  input entry_t entries_new[2],

  // from WAKEUP stage
  input ex_content_t ex_contents[2],

  // from EX stage
  input ex_result_t results[2],

  // from COMMIT stage
  input logic is_really_commited[2], is_commited_store[2],
  input tag_t commited_tags[2],

  output entry_t entries[BUF_SIZE]
);

entry_t entries_next[BUF_SIZE];
spectag_t _speculative_tag[BUF_SIZE], _specific_speculative_tag[BUF_SIZE];

genvar i;
generate
  for (i = 0; i < BUF_SIZE; i++) begin: Reg
    flopr #($bits(entry_t)) ff(.clk, .reset, .d(entries_next[i]), .q(entries[i]));
    always_comb
      // from DISPATCH stage
      if (entries[i].e_state == S_NOT_USED) begin
        if (i == allocation_indexes[0] && is_valid_allocation[0]) begin
          entries_next[i] = entries_new[0];
        end
        else if (i == allocation_indexes[1] && is_valid_allocation[1]) begin
          entries_next[i] = entries_new[1];
        end
        else begin
          entries_next[i] = 0;
        end
      end

      // from COMMIT stage
      else if ((entries[i].tag == commited_tags[0] && is_really_commited[0])
        || (entries[i].tag == commited_tags[1] && is_really_commited[1])) begin
        entries_next[i] = 0;
      end

      // from EX stage (flash speculative entry)
      else if (results[0].is_branch_established
        && (entries[i].specific_speculative_tag != results[0].speculative_tag)
        && (entries[i].speculative_tag & results[0].speculative_tag) != 6'b000000) begin
        entries_next[i] = 0;
      end
      else if (results[1].is_branch_established
        && (entries[i].specific_speculative_tag != results[1].speculative_tag)
        && (entries[i].speculative_tag & results[1].speculative_tag) != 6'b000000) begin
        entries_next[i] = 0;
      end
      else begin

        // from WAKEUP stage
        if ((ex_contents[0].tag == entries[i].tag && ex_contents[0].is_valid)
          || (ex_contents[0].tag == entries[i].tag && ex_contents[1].is_valid)) begin
          entries_next[i].e_state = S_EXECUTING;
          entries_next[i].result = entries[i].result;
          entries_next[i].A_rdy = entries[i].A_rdy;
          entries_next[i].A = entries[i].A;
        end

        // from EX stage
        else if (results[0].tag == entries[i].tag && results[0].is_valid) begin
          if (results[0].mode == EX_GEN_ADDR) begin
            entries_next[i].e_state = (entries[i].Unit == STORE) ? S_EXECUTED : S_ADDR_GENERATED;
            entries_next[i].result = entries[i].result;
            entries_next[i].A_rdy = true;
            entries_next[i].A = results[0].result;
          end
          else begin
            entries_next[i].e_state = S_EXECUTED;
            entries_next[i].result = results[0].result;
            entries_next[i].A_rdy = entries[i].A_rdy;
            entries_next[i].A = entries[i].A;
          end
        end
        else if (results[1].tag == entries[i].tag && results[1].is_valid) begin
          if (results[1].mode == EX_GEN_ADDR) begin
            entries_next[i].e_state = (entries[i].Unit == STORE) ? S_EXECUTED : S_ADDR_GENERATED;
            entries_next[i].result = entries[i].result;
            entries_next[i].A_rdy = true;
            entries_next[i].A = results[1].result;
          end
          else begin
            entries_next[i].e_state = S_EXECUTED;
            entries_next[i].result = results[1].result;
            entries_next[i].A_rdy = entries[i].A_rdy;
            entries_next[i].A = entries[i].A;
          end
        end
        else begin
          entries_next[i].e_state = entries[i].e_state;
          entries_next[i].result = entries[i].result;
          entries_next[i].A_rdy = entries[i].A_rdy;
          entries_next[i].A = entries[i].A;
        end

        // Operand J
        if (!entries[i].J_rdy && results[0].tag == entries[i].Qj && results[0].mode == EX_NORMAL && results[0].is_valid) begin
          entries_next[i].J_rdy = true;
          entries_next[i].Qj = 0;
          entries_next[i].Vj = results[0].result;
        end
        else if (!entries[i].J_rdy && results[1].tag == entries[i].Qj && results[1].mode == EX_NORMAL && results[1].is_valid) begin
          entries_next[i].J_rdy = true;
          entries_next[i].Qj = 0;
          entries_next[i].Vj = results[1].result;
        end
        else begin
          entries_next[i].J_rdy = entries[i].J_rdy;
          entries_next[i].Qj = entries[i].Qj;
          entries_next[i].Vj = entries[i].Vj;
        end

        // Operand K
        if (!entries[i].K_rdy && results[0].tag == entries[i].Qk && results[0].mode == EX_NORMAL && results[0].is_valid) begin
          entries_next[i].K_rdy = true;
          entries_next[i].Qk = 0;
          entries_next[i].Vk = results[0].result;
        end
        else if (!entries[i].K_rdy && results[1].tag == entries[i].Qk && results[1].mode == EX_NORMAL && results[1].is_valid) begin
          entries_next[i].K_rdy = true;
          entries_next[i].Qk = 0;
          entries_next[i].Vk = results[1].result;
        end
        else begin
          entries_next[i].K_rdy = entries[i].K_rdy;
          entries_next[i].Qk = entries[i].Qk;
          entries_next[i].Vk = entries[i].Vk;
        end

        if ((is_really_commited[0] && is_commited_store[0]) || (is_really_commited[1] && is_commited_store[1])) begin
          entries_next[i].number_of_early_store_ops = entries[i].number_of_early_store_ops - BUF_SIZE_LOG'(1);
        end
        else begin
          entries_next[i].number_of_early_store_ops = entries[i].number_of_early_store_ops;
        end

        // speculative -> normal execution
        if (results[0].is_branch_established) begin
          _speculative_tag[i]          = entries[i].speculative_tag & (~results[0].speculative_tag);
          _specific_speculative_tag[i] = entries[i].specific_speculative_tag & (~results[0].speculative_tag);
        end
        else begin
          _speculative_tag[i]          = entries[i].speculative_tag;
          _specific_speculative_tag[i] = entries[i].specific_speculative_tag;
        end

        if (results[1].is_branch_established) begin
          entries_next[i].speculative_tag          = _speculative_tag[i] & (~results[1].speculative_tag);
          entries_next[i].specific_speculative_tag = _specific_speculative_tag[i] & (~results[1].speculative_tag);
        end
        else begin
          entries_next[i].speculative_tag          = _speculative_tag[i];
          entries_next[i].specific_speculative_tag = _specific_speculative_tag[i];
        end

        if (is_tag_flooded) begin
          entries_next[i].tag = { 1'b1, entries[i].tag[BUF_SIZE_LOG-1:0] };
        end
        else begin
          entries_next[i].tag = entries[i].tag;
        end

        entries_next[i].Unit            = entries[i].Unit;
        entries_next[i].rwmm            = entries[i].rwmm;
        entries_next[i].Dest            = entries[i].Dest;
        entries_next[i].Op              = entries[i].Op;
        entries_next[i].pc              = entries[i].pc;
      end
  end
endgenerate

endmodule
