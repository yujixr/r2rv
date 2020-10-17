module decoder(
  input logic [31:0] instr,
  output logic src1_selector, src2_selector, wd3_selector, we3, wem,
  output logic [4:0] ra1, ra2, wa3,
  output logic [31:0] imm
);

logic [7:0] opcode;
logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
logic [4:0] ra1_pre, ra2_pre;

assign opcode = instr[6:0];

assign imm_i = { {12{instr[31]}}, instr[31:12] };
assign imm_s = { {12{instr[31]}}, instr[31:25], instr[11:7] };
assign imm_b = { {11{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
assign imm_u = { instr[31:12], 12'b0 };
assign imm_j = { {12{instr[31]}}, instr[31], instr[30:21], instr[20], instr[19:12] };

assign ra1_pre = instr[19:15];
assign ra2_pre = instr[24:20];
assign wa3 = instr[11:7];

always_comb
  case (opcode)       // Encoding  Register1      Register2     Reg:1, PC+4:1      Reg:1, imm:1       ALU:0, Mem:1      Write to Reg/Mem
    7'b0110111: begin imm = imm_u; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; end // LUI
    7'b0010111: begin imm = imm_u; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 1; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; end // AUIPC
    7'b1101111: begin imm = imm_j; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 1; src2_selector = 0; wd3_selector = 0; we3 = 1; wem = 0; end // JAL
    7'b1100111: begin imm = imm_i; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 1; src2_selector = 0; wd3_selector = 0; we3 = 1; wem = 0; end // JALR
    7'b1100011: begin imm = imm_b; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; end // Branch
    7'b0000011: begin imm = imm_i; ra1 = ra1_pre; ra2 = 5'b0;   src1_selector = 0; src2_selector = 1; wd3_selector = 1; we3 = 1; wem = 0; end // Load
    7'b0100011: begin imm = imm_s; ra1 = ra1_pre; ra2 = ra2_pre;src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 0; wem = 1; end // Store
    7'b0010011: begin imm = imm_i; ra1 = ra1_pre; ra2 = 5'b0;   src1_selector = 0; src2_selector = 1; wd3_selector = 0; we3 = 1; wem = 0; end // ALU reg&imm
    7'b0110011: begin imm = 32'b0; ra1 = ra1_pre; ra2 = ra2_pre;src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 1; wem = 0; end // ALU reg&reg
    7'b0001111: begin imm = 32'b0; ra1 = ra1_pre; ra2 = 5'b0;   src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; end // FENCE
    7'b1110011: begin imm = 32'b0; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; end // ECALL, EBREAK
    default:    begin imm = 32'b0; ra1 = 5'b0;    ra2 = 5'b0;   src1_selector = 0; src2_selector = 0; wd3_selector = 0; we3 = 0; wem = 0; end
  endcase

endmodule