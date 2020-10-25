module mul(
  input logic [1:0] funct3,
  input logic [31:0] a, b,
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
  case(funct3)
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

assign yx = sum(p);

mux select_y(yx[63:32], yx[31:0], funct3==MUL, y);

endmodule
