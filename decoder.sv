module decoder(
  input logic [31:0] instr, pc,
  output logic is_load_op, we3, wem, is_branch_op,
  output logic [2:0] rwmm,
  output logic [4:0] Qj, Qk, wa3,
  output logic [9:0] Op,
  output logic [31:0] Vj, Vk
);

parameter OP_IMM    = 7'b0010011;
parameter LUI       = 7'b0110111;
parameter AUIPC     = 7'b0010111;
parameter OP        = 7'b0110011;
parameter JAL       = 7'b1101111;
parameter JALR      = 7'b1100111;
parameter BRANCH    = 7'b1100011;
parameter LOAD      = 7'b0000011;
parameter STORE     = 7'b0100011;
parameter MISC_MEM  = 7'b0001111;
parameter SYSTEM    = 7'b1110011;

logic [2:0] funct3;
logic [4:0] Rj, Rk;
logic [6:0] funct7, opcode;
logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

assign opcode = instr[6:0];

// Immediate
assign imm_i = { {20{instr[31]}}, instr[31:20] };
assign imm_s = { {20{instr[31]}}, instr[31:25], instr[11:7] };
assign imm_b = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
assign imm_u = { instr[31:12], 12'b0 };
assign imm_j = { {12{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21] };

assign Rj = instr[19:15];
assign Rk = instr[24:20];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];
assign wa3 = instr[11:7];
assign Op = { funct3, funct7 };

always_comb
  case (opcode)                                                // Write to Reg/Mem  Mem Access Mode
    OP_IMM:   begin Vj = 32'b0; Vk = imm_i; Qj = Rj;   Qk = 5'b0; we3 = 1; wem = 0; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; end
    LUI:      begin Vj = 32'b0; Vk = imm_u; Qj = 5'b0; Qk = 5'b0; we3 = 1; wem = 0; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; end
    AUIPC:    begin Vj = pc;    Vk = imm_u; Qj = 5'b0; Qk = 5'b0; we3 = 1; wem = 0; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; end
    OP:       begin Vj = 32'b0; Vk = 32'b0; Qj = Rj;   Qk = Rk;   we3 = 1; wem = 0; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; end
    JAL:      begin Vj = pc;    Vk = imm_j; Qj = 5'b0; Qk = 5'b0; we3 = 1; wem = 0; rwmm = 3'b0;   is_branch_op = 1; is_load_op = 0; end
    JALR:     begin Vj = 32'b0; Vk = imm_i; Qj = Rj;   Qk = Rj;   we3 = 1; wem = 0; rwmm = 3'b0;   is_branch_op = 1; is_load_op = 0; end
    BRANCH:   begin Vj = pc;    Vk = imm_b; Qj = 5'b0; Qk = 5'b0; we3 = 0; wem = 0; rwmm = 3'b0;   is_branch_op = 1; is_load_op = 0; end
    LOAD:     begin Vj = 32'b0; Vk = imm_i; Qj = Rj;   Qk = 5'b0; we3 = 1; wem = 0; rwmm = funct3; is_branch_op = 0; is_load_op = 1; end
    STORE:    begin Vj = 32'b0; Vk = imm_s; Qj = Rj;   Qk = Rk;   we3 = 0; wem = 1; rwmm = funct3; is_branch_op = 0; is_load_op = 0; end
    MISC_MEM: begin Vj = 32'b0; Vk = 32'b0; Qj = Rj;   Qk = 5'b0; we3 = 0; wem = 0; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; end
    SYSTEM:   begin Vj = 32'b0; Vk = 32'b0; Qj = 5'b0; Qk = 5'b0; we3 = 0; wem = 0; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; end
    default:  begin Vj = 32'b0; Vk = 32'b0; Qj = 5'b0; Qk = 5'b0; we3 = 0; wem = 0; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; end
  endcase

endmodule
