module mul(
  input logic [31:0] a, b,
  input logic [2:0] funct3,
  output logic [31:0] y
);

parameter MUL    = 2'b00;
parameter MULH   = 2'b01;
parameter MULHSU = 2'b10;
parameter MULHU  = 2'b11;

logic [63:0] ax, bx, yx, uax, ubx, sax, sbx;
logic [63:0] p[63:0];

// Unsigned 64bit value
assign uax = { 32'b0, a };
assign ubx = { 32'b0, b };

// Signed 64bit value
assign sax = { {32{a[31]}}, a };
assign sbx = { {32{b[31]}}, b };

always_comb
  case(funct3[1:0])
    MUL:    begin ax = uax; bx = ubx; end
    MULH:   begin ax = sax; bx = sbx; end
    MULHSU: begin ax = sax; bx = ubx; end
    MULHU:  begin ax = uax; bx = ubx; end
  endcase

genvar i;
generate
  for (i=0; i < 64; i++) begin: And
    assign p[i] = (bx << i) & { 64{ax[i]} };
  end
endgenerate

assign yx = p[0] + p[1] + p[2] + p[3] + p[4] + p[5] + p[6] + p[7]
          + p[8] + p[9] + p[10] + p[11] + p[12] + p[13] + p[14] + p[15]
          + p[16] + p[17] + p[18] + p[19] + p[20] + p[21] + p[22] + p[23]
          + p[24] + p[25] + p[26] + p[27] + p[28] + p[29] + p[30] + p[31];

mux2 #(32) select_y(yx[63:32], yx[31:0], funct3[1:0]==MUL, y);

endmodule
