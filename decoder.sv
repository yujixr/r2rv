module decoder(
  input logic [31:0] instr,
  output logic src1_selector, src2_selector, wd3_selector, we3, wem, is_branch_op,
  output logic [2:0] funct3, rwmm,
  output logic [6:0] funct7,
  output logic [4:0] ra1, ra2, wa3,
  output logic [31:0] imm
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

logic [2:0] f3;
logic [4:0] a1, a2;
logic [6:0] f7;
logic [7:0] opcode;
logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

assign opcode = instr[6:0];

assign imm_i = { {20{instr[31]}}, instr[31:20] };
assign imm_s = { {20{instr[31]}}, instr[31:25], instr[11:7] };
assign imm_b = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
assign imm_u = { instr[31:12], 12'b0 };
assign imm_j = { {12{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21] };

assign a1 = instr[19:15];
assign a2 = instr[24:20];
assign f3 = instr[14:12];
assign f7 = instr[31:25];
assign wa3 = instr[11:7];

always_comb
  case (opcode)  // Immediate    Register1   Register2   funct3         funct7         Reg:0, PC+4:1      Reg:0, imm:1       ALU:0, Mem:1      Write to Reg/Mem  Mem Access Mode
    OP_IMM:   begin imm = imm_i; ra1 = a1;   ra2 = 5'b0; funct3 = f3;   funct7 = 7'b0; src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; rwmm = 3'b0; is_branch_op = 0; end
    LUI:      begin imm = imm_u; ra1 = 5'b0; ra2 = 5'b0; funct3 = 3'b0; funct7 = 7'b0; src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; rwmm = 3'b0; is_branch_op = 0; end
    AUIPC:    begin imm = imm_u; ra1 = 5'b0; ra2 = 5'b0; funct3 = 3'b0; funct7 = 7'b0; src1_selector = 1; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; rwmm = 3'b0; is_branch_op = 0; end
    OP:       begin imm = 32'b0; ra1 = a1;   ra2 = a2;   funct3 = f3;   funct7 = f7;   src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 1; wem = 0; rwmm = 3'b0; is_branch_op = 0; end
    JAL:      begin imm = imm_j; ra1 = 5'b0; ra2 = 5'b0; funct3 = 3'b0; funct7 = 7'b0; src1_selector = 1; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; rwmm = 3'b0; is_branch_op = 1; end
    JALR:     begin imm = imm_i; ra1 = a1;   ra2 = a1;   funct3 = 3'b0; funct7 = 7'b0; src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; rwmm = 3'b0; is_branch_op = 1; end
    BRANCH:   begin imm = imm_b; ra1 = 5'b0; ra2 = 5'b0; funct3 = f3;   funct7 = 7'b0; src1_selector = 1; src2_selector = 1; wd3_selector = 0; we3 = 0; wem = 0; rwmm = 3'b0; is_branch_op = 1; end
    LOAD:     begin imm = imm_i; ra1 = a1;   ra2 = 5'b0; funct3 = 3'b0; funct7 = 7'b0; src1_selector = 0; src2_selector = 1; wd3_selector = 1; we3 = 1; wem = 0; rwmm = f3;   is_branch_op = 0; end
    STORE:    begin imm = imm_s; ra1 = a1;   ra2 = a2;   funct3 = 3'b0; funct7 = 7'b0; src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 0; wem = 1; rwmm = f3;   is_branch_op = 0; end
    MISC_MEM: begin imm = 32'b0; ra1 = a1;   ra2 = 5'b0; funct3 = f3;   funct7 = 7'b0; src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; rwmm = 3'b0; is_branch_op = 0; end
    SYSTEM:   begin imm = 32'b0; ra1 = 5'b0; ra2 = 5'b0; funct3 = f3;   funct7 = 7'b0; src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; rwmm = 3'b0; is_branch_op = 0; end
    default:  begin imm = 32'b0; ra1 = 5'b0; ra2 = 5'b0; funct3 = 3'b0; funct7 = 7'b0; src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; rwmm = 3'b0; is_branch_op = 0; end
  endcase

endmodule
