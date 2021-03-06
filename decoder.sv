module decoder(
  input logic [31:0] instr, pc,
  output bool A_rdy,
  output unit_t Unit,
  output ldst_mode_t rwmm,
  output logic [4:0] Qj, Qk, Dest,
  output logic [9:0] Op,
  output logic [31:0] Vj, Vk, A
);

// opcode
parameter C_OP_IMM    = 7'b0010011;
parameter C_LUI       = 7'b0110111;
parameter C_AUIPC     = 7'b0010111;
parameter C_OP        = 7'b0110011;
parameter C_JAL       = 7'b1101111;
parameter C_JALR      = 7'b1100111;
parameter C_BRANCH    = 7'b1100011;
parameter C_LOAD      = 7'b0000011;
parameter C_STORE     = 7'b0100011;
parameter C_MISC_MEM  = 7'b0001111;
parameter C_SYSTEM    = 7'b1110011;

unit_t _Unit;
logic [2:0] funct3;
logic [4:0] _Qj, _Qk, _Dest;
logic [6:0] funct7, opcode;
logic [9:0] OP_IMM_Op;
logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

assign opcode = instr[6:0];

// Immediate
assign imm_i = { {20{instr[31]}}, instr[31:20] };
assign imm_s = { {20{instr[31]}}, instr[31:25], instr[11:7] };
assign imm_b = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
assign imm_u = { instr[31:12], 12'b0 };
assign imm_j = { {12{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21] };

assign _Qj = instr[19:15];
assign _Qk = instr[24:20];
assign _Dest = instr[11:7];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];

assign OP_IMM_Op = { funct3, (funct3==3'b101) ? funct7 : 7'b0 };

assign _Unit = unit_t'(Op[0] ? (Op[9] ? DIV : MUL) : ALU);

always_comb
  case (opcode)
    C_OP_IMM:   begin Unit = _Unit;  Op = OP_IMM_Op;          Qj = _Qj;  Qk = 5'b0; Vj = 32'b0; Vk = imm_i; A = 32'b0;      A_rdy = true;  Dest = _Dest; rwmm = BYTE; end
    C_LUI:      begin Unit = ALU;    Op = 10'b0;              Qj = 5'b0; Qk = 5'b0; Vj = 32'b0; Vk = imm_u; A = 32'b0;      A_rdy = true;  Dest = _Dest; rwmm = BYTE; end
    C_AUIPC:    begin Unit = ALU;    Op = 10'b0;              Qj = 5'b0; Qk = 5'b0; Vj = pc;    Vk = imm_u; A = 32'b0;      A_rdy = true;  Dest = _Dest; rwmm = BYTE; end
    C_OP:       begin Unit = _Unit;  Op = { funct3, funct7 }; Qj = _Qj;  Qk = _Qk;  Vj = 32'b0; Vk = 32'b0; A = 32'b0;      A_rdy = true;  Dest = _Dest; rwmm = BYTE; end
    C_JAL:      begin Unit = BRANCH; Op = 10'b0;              Qj = 5'b0; Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = pc + imm_j; A_rdy = true;  Dest = _Dest; rwmm = BYTE; end
    C_JALR:     begin Unit = BRANCH; Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = _Qj;  Vj = 32'b0; Vk = 32'b0; A = imm_i;      A_rdy = false; Dest = _Dest; rwmm = BYTE; end
    C_BRANCH:   begin Unit = BRANCH; Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = _Qk;  Vj = 32'b0; Vk = 32'b0; A = pc + imm_b; A_rdy = true;  Dest = 5'b0;  rwmm = BYTE; end
    C_LOAD:     begin Unit = LOAD;   Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = imm_i;      A_rdy = false; Dest = _Dest; rwmm = ldst_mode_t'(funct3); end
    C_STORE:    begin Unit = STORE;  Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = _Qk;  Vj = 32'b0; Vk = 32'b0; A = imm_s;      A_rdy = false; Dest = 5'b0;  rwmm = ldst_mode_t'(funct3); end
    C_MISC_MEM: begin Unit = ALU;    Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = 32'b0;      A_rdy = true;  Dest = 5'b0;  rwmm = BYTE; end
    C_SYSTEM:   begin Unit = ALU;    Op = { funct3, 7'b0 };   Qj = 5'b0; Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = 32'b0;      A_rdy = true;  Dest = 5'b0;  rwmm = BYTE; end
    default:    begin Unit = ALU;    Op = 10'b0;              Qj = 5'b0; Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = 32'b0;      A_rdy = true;  Dest = 5'b0;  rwmm = BYTE; end
  endcase

endmodule
