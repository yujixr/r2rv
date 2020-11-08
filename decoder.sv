module decoder(
  input logic [31:0] instr, pc,
  output logic is_branch_op, is_load_op, is_store_op, A_rdy,
  output logic [2:0] rwmm,
  output logic [4:0] Qj, Qk, Dest,
  output logic [9:0] Op,
  output logic [31:0] Vj, Vk, A
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
logic [4:0] _Qj, _Qk, _Dest;
logic [6:0] funct7, opcode;
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

always_comb
  case (opcode)                                                                                                                  // Mem Access Mode
    OP_IMM:   begin Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = 5'b0; Vj = 32'b0; Vk = imm_i; A = 32'b0;      A_rdy = 1; Dest = _Dest; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; is_store_op = 0; end
    LUI:      begin Op = { funct3, 7'b0 };   Qj = 5'b0; Qk = 5'b0; Vj = 32'b0; Vk = imm_u; A = 32'b0;      A_rdy = 1; Dest = _Dest; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; is_store_op = 0; end
    AUIPC:    begin Op = { funct3, 7'b0 };   Qj = 5'b0; Qk = 5'b0; Vj = pc;    Vk = imm_u; A = 32'b0;      A_rdy = 1; Dest = _Dest; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; is_store_op = 0; end
    OP:       begin Op = { funct3, funct7 }; Qj = _Qj;  Qk = _Qk;  Vj = 32'b0; Vk = 32'b0; A = 32'b0;      A_rdy = 1; Dest = _Dest; rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; is_store_op = 0; end
    JAL:      begin Op = { funct3, 7'b0 };   Qj = 5'b0; Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = pc + imm_j; A_rdy = 1; Dest = _Dest; rwmm = 3'b0;   is_branch_op = 1; is_load_op = 0; is_store_op = 0; end
    JALR:     begin Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = _Qj;  Vj = 32'b0; Vk = 32'b0; A = imm_i;      A_rdy = 0; Dest = _Dest; rwmm = 3'b0;   is_branch_op = 1; is_load_op = 0; is_store_op = 0; end
    BRANCH:   begin Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = _Qk;  Vj = 32'b0; Vk = 32'b0; A = pc + imm_b; A_rdy = 1; Dest = 5'b0;  rwmm = 3'b0;   is_branch_op = 1; is_load_op = 0; is_store_op = 0; end
    LOAD:     begin Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = imm_i;      A_rdy = 0; Dest = _Dest; rwmm = funct3; is_branch_op = 0; is_load_op = 1; is_store_op = 0; end
    STORE:    begin Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = _Qk;  Vj = 32'b0; Vk = 32'b0; A = imm_s;      A_rdy = 0; Dest = 5'b0;  rwmm = funct3; is_branch_op = 0; is_load_op = 0; is_store_op = 1; end
    MISC_MEM: begin Op = { funct3, 7'b0 };   Qj = _Qj;  Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = 32'b0;      A_rdy = 1; Dest = 5'b0;  rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; is_store_op = 0; end
    SYSTEM:   begin Op = { funct3, 7'b0 };   Qj = 5'b0; Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = 32'b0;      A_rdy = 1; Dest = 5'b0;  rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; is_store_op = 0; end
    default:  begin Op = { funct3, 7'b0 };   Qj = 5'b0; Qk = 5'b0; Vj = 32'b0; Vk = 32'b0; A = 32'b0;      A_rdy = 1; Dest = 5'b0;  rwmm = 3'b0;   is_branch_op = 0; is_load_op = 0; is_store_op = 0; end
  endcase

endmodule
