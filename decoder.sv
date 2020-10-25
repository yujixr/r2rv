module decoder(
  input logic [31:0] instr,
  output logic src1_selector, src2_selector, wd3_selector, we3, wem,
  output logic [2:0] funct3,
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

logic [7:0] opcode;
logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
logic [4:0] ra1_pre, ra2_pre;

assign opcode = instr[6:0];
assign funct7 = instr[31:25];
assign funct3 = instr[14:12];

assign imm_i = { {12{instr[31]}}, instr[31:12] };
assign imm_s = { {12{instr[31]}}, instr[31:25], instr[11:7] };
assign imm_b = { {11{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
assign imm_u = { instr[31:12], 12'b0 };
assign imm_j = { {12{instr[31]}}, instr[31], instr[30:21], instr[20], instr[19:12] };

assign ra1_pre = instr[19:15];
assign ra2_pre = instr[24:20];
assign wa3 = instr[11:7];

always_comb
  case (opcode)  // Immediate    Register1      Register2     Reg:1, PC+4:1      Reg:1, imm:1       ALU:0, Mem:1      Write to Reg/Mem
    OP_IMM:   begin imm = imm_i; ra1 = ra1_pre; ra2 = 5'b0;   src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; end
    LUI:      begin imm = imm_u; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; end
    AUIPC:    begin imm = imm_u; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 1; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; end
    OP:       begin imm = 32'b0; ra1 = ra1_pre; ra2 = ra2_pre;src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 1; wem = 0; end
    JAL:      begin imm = imm_j; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 1; src2_selector = 0; wd3_selector = 0; we3 = 1; wem = 0; end
    JALR:     begin imm = imm_i; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 1; src2_selector = 0; wd3_selector = 0; we3 = 1; wem = 0; end
    BRANCH:   begin imm = imm_b; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; end
    LOAD:     begin imm = imm_i; ra1 = ra1_pre; ra2 = 5'b0;   src1_selector = 0; src2_selector = 1; wd3_selector = 1; we3 = 1; wem = 0; end
    STORE:    begin imm = imm_s; ra1 = ra1_pre; ra2 = ra2_pre;src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 0; wem = 1; end
    MISC_MEM: begin imm = 32'b0; ra1 = ra1_pre; ra2 = 5'b0;   src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; end
    SYSTEM:   begin imm = 32'b0; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; end
    default:  begin imm = 32'b0; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; end
  endcase

endmodule
