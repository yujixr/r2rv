parameter BUF_SIZE_LOG = 4;
parameter BUF_SIZE = 2**BUF_SIZE_LOG;

typedef enum logic [2:0] {
  S_NOT_USED = 3'b0,
  S_NOT_EXECUTED,
  S_EXECUTING,
  S_ADDR_GENERATED,
  S_EXECUTED
} state;

typedef enum logic [2:0] {
  ALU,
  BRANCH,
  MUL,
  DIV,
  LOAD,
  STORE
} unit;

typedef enum logic [2:0] {
  BYTE        = 3'b000,
  HALF_WORD   = 3'b001,
  WORD        = 3'b010,
  U_BYTE      = 3'b100,
  U_HALF_WORD = 3'b101
} ldst_mode;

typedef enum logic [0:0] {
  EX_NORMAL,
  EX_GEN_ADDR
} ex_mode;

typedef struct packed {
  logic J_rdy, K_rdy, A_rdy;
  state e_state;
  unit Unit;
  ldst_mode rwmm;
  logic [4:0] Dest;
  logic [5:0] speculative_tag;
  logic [9:0] Op;
  logic [31:0] Vj, Vk, A, pc, result;
  logic [BUF_SIZE_LOG-1:0] number_of_early_store_ops;
  logic [BUF_SIZE_LOG:0] Qj, Qk, tag;
} entry;

module buffer(
  input logic clk, reset,

  // from DISPATCH stage
  input logic is_valid_allocation[2],
  input logic [BUF_SIZE_LOG-1:0] allocation_indexes[2],
  input logic entries_new[2],

  // from WAKEUP stage
  input logic is_valid_execution[2],
  input logic [BUF_SIZE_LOG:0] waked_tags[2],

  // from EX stage
  input logic is_valid_result[2],
  input logic [31:0] results[2],
  input ex_mode ex_modes[2],
  input logic [BUF_SIZE_LOG:0] results_tags[2],

  // from COMMIT stage
  input logic is_really_commited[2], is_commited_store[2],
  input logic [BUF_SIZE_LOG:0] commited_tags[2],

  output entry entries[BUF_SIZE]
);

entry entries_next[BUF_SIZE];

genvar i;
generate
  for (i = 0; i < BUF_SIZE; i++) begin: Reg
    always_ff @(negedge clk)
      if (reset) entries[i] <= 0;

      // from COMMIT stage
      else if ((entries[i].tag == commited_tags[0] && is_really_commited[0])
        || (entries[i].tag == commited_tags[1] && is_really_commited[1])) begin
        entries[i] <= 0;
      end

      // from DISPATCH stage
      else if (i == allocation_indexes[0] && is_valid_allocation[0]) begin
        entries[i] <= entries_new[0];
      end
      else if (i == allocation_indexes[1] && is_valid_allocation[1]) begin
        entries[i] <= entries_new[1];
      end
      else begin

        // from WAKEUP & EX stage
        if ((waked_tags[0] == entries[i].tag && is_valid_execution[0])
          || (waked_tags[1] == entries[i].tag && is_valid_execution[1])) begin
          entries_next[i].e_state = S_EXECUTING;
          entries_next[i].result = entries[i].result;
          entries_next[i].A_rdy = entries[i].A_rdy;
          entries_next[i].A = entries[i].A;
        end
        else if (results_tags[0] == entries[i].tag && is_valid_result[0]) begin
          if (ex_modes[0] == EX_NORMAL) begin
            entries_next[i].e_state = S_EXECUTED;
            entries_next[i].result = results[0];
            entries_next[i].A_rdy = entries[i].A_rdy;
            entries_next[i].A = entries[i].A;
          end
          else begin
            entries_next[i].e_state = (entries[i].Unit == STORE) ? S_EXECUTED : S_ADDR_GENERATED;
            entries_next[i].result = entries[i].result;
            entries_next[i].A_rdy = 1;
            entries_next[i].A = results[0];
          end
        end
        else if (results_tags[1] == entries[i].tag && is_valid_result[1]) begin
          if (ex_modes[1] == EX_NORMAL) begin
            entries_next[i].e_state = S_EXECUTED;
            entries_next[i].result = results[1];
            entries_next[i].A_rdy = entries[i].A_rdy;
            entries_next[i].A = entries[i].A;
          end
          else begin
            entries_next[i].e_state = (entries[i].Unit == STORE) ? S_EXECUTED : S_ADDR_GENERATED;
            entries_next[i].result = entries[i].result;
            entries_next[i].A_rdy = 1;
            entries_next[i].A = results[1];
          end
        end
        else begin
          entries_next[i].e_state = entries[i].e_state;
          entries_next[i].result = entries[i].result;
          entries_next[i].A_rdy = entries[i].A_rdy;
          entries_next[i].A = entries[i].A;
        end

        // Operand J
        if (!entries[i].J_rdy && results_tags[0] == entries[i].Qj && ex_modes[0] == EX_NORMAL && is_valid_result[0]) begin
          entries_next[i].J_rdy = 1;
          entries_next[i].Qj = 0;
          entries_next[i].Vj = results[0];
        end
        else if (!entries[i].J_rdy && results_tags[1] == entries[i].Qj && ex_modes[1] == EX_NORMAL && is_valid_result[1]) begin
          entries_next[i].J_rdy = 1;
          entries_next[i].Qj = 0;
          entries_next[i].Vj = results[1];
        end
        else begin
          entries_next[i].J_rdy = entries[i].J_rdy;
          entries_next[i].Qj = entries[i].Qj;
          entries_next[i].Vj = entries[i].Vj;
        end

        // Operand K
        if (!entries[i].K_rdy && results_tags[0] == entries[i].Qk && ex_modes[0] == EX_NORMAL && is_valid_result[0]) begin
          entries_next[i].K_rdy = 1;
          entries_next[i].Qk = 0;
          entries_next[i].Vk = results[0];
        end
        else if (!entries[i].K_rdy && results_tags[1] == entries[i].Qk && ex_modes[1] == EX_NORMAL && is_valid_result[1]) begin
          entries_next[i].K_rdy = 1;
          entries_next[i].Qk = 0;
          entries_next[i].Vk = results[1];
        end
        else begin
          entries_next[i].K_rdy = entries[i].K_rdy;
          entries_next[i].Qk = entries[i].Qk;
          entries_next[i].Vk = entries[i].Vk;
        end

        if ((is_really_commited[0] && is_commited_store[0]) || (is_really_commited[1] && is_commited_store[1])) begin
          entries_next[i].number_of_early_store_ops = entries[i].number_of_early_store_ops - 1;
        end
        else begin
          entries_next[i].number_of_early_store_ops = entries[i].number_of_early_store_ops;
        end

        entries[i].J_rdy            <= entries_next[i].J_rdy;
        entries[i].K_rdy            <= entries_next[i].K_rdy;
        entries[i].A_rdy            <= entries_next[i].A_rdy;
        entries[i].e_state          <= entries_next[i].e_state;
        entries[i].Unit             <= entries[i].Unit;
        entries[i].rwmm             <= entries[i].rwmm;
        entries[i].Dest             <= entries[i].Dest;
        entries[i].speculative_tag  <= entries[i].speculative_tag;
        entries[i].Op               <= entries[i].Op;
        entries[i].Vj               <= entries_next[i].Vj;
        entries[i].Vk               <= entries_next[i].Vk;
        entries[i].A                <= entries_next[i].A;
        entries[i].pc               <= entries[i].pc;
        entries[i].result           <= entries_next[i].result;
        entries[i].Qj               <= entries_next[i].Qj;
        entries[i].Qk               <= entries_next[i].Qk;
        entries[i].tag              <= entries[i].tag;
      end
  end
endgenerate

endmodule
