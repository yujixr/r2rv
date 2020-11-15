parameter BUF_SIZE_LOG = 4;
parameter BUF_SIZE = 2**BUF_SIZE_LOG;

typedef enum logic [2:0] {
  S_NOT_USED = 3'b0,
  S_NOT_EXECUTED,
  S_EXECUTING,
  S_ADDR_GENERATED,
  S_EXECUTED
} state;

typedef struct packed {
  logic A_rdy;
  state e_state;
  logic [2:0] Unit, rwmm;
  logic [4:0] Dest;
  logic [5:0] speculative_tag;
  logic [9:0] Op;
  logic [31:0] Vj, Vk, A, pc, result;
  logic [BUF_SIZE_LOG:0] Qj, Qk, tag;
} entry;

module buffer(
  input logic clk, reset,
  output entry entries[BUF_SIZE-1:0]
);

genvar i;
generate
  for (i = 0; i < BUF_SIZE; i++) begin: Reg
    always_ff @(negedge clk)
      if (reset) entries[i] <= 0;
      else entries[i] <= entries[i];
  end
endgenerate

endmodule
