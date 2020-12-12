typedef struct packed {
  logic is_valid;
  unit_t Unit;
  bool A_rdy;
  ldst_mode_t rwmm;
  logic [4:0] Qj, Qk, Dest;
  logic [9:0] Op;
  logic [31:0] Vj, Vk, A, pc;
} decode_result_t;

module id(
  input logic is_valid[2],
  input logic [31:0] instr[2], pc[2],
  output decode_result_t decoded[2]
);

genvar i;
generate
  for (i = 0; i < 2; i++) begin: decode_instructions
    assign decoded[i].is_valid = is_valid[i];
    assign decoded[i].pc = pc[i];

    decoder decode(.instr(instr[i]), .pc(pc[i]),
      .A_rdy(decoded[i].A_rdy), .Unit(decoded[i].Unit), .rwmm(decoded[i].rwmm),
      .Op(decoded[i].Op), .Qj(decoded[i].Qj), .Qk(decoded[i].Qk),
      .Dest(decoded[i].Dest), .Vj(decoded[i].Vj), .Vk(decoded[i].Vk), .A(decoded[i].A));
  end
endgenerate

endmodule
