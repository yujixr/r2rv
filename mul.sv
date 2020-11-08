module mul(
  input logic [31:0] Vj, Vk,
  input logic [9:0] Op,
  output logic [31:0] y
);

parameter MUL    = 2'b00;
parameter MULH   = 2'b01;
parameter MULHSU = 2'b10;
parameter MULHU  = 2'b11;

logic [63:0] ax, bx, yx, uax, ubx, sax, sbx;
logic [63:0] p[63:0];

// Unsigned 64bit value
assign uax = { 32'b0, Vj };
assign ubx = { 32'b0, Vk };

// Signed 64bit value
assign sax = { {32{Vj[31]}}, Vj };
assign sbx = { {32{Vk[31]}}, Vk };

always_comb
  case(Op[8:7])
    MUL:    begin ax = uax; bx = ubx; end
    MULH:   begin ax = sax; bx = sbx; end
    MULHSU: begin ax = sax; bx = ubx; end
    MULHU:  begin ax = uax; bx = ubx; end
  endcase

assign yx = bx * ax;

mux2 #(32) select_y(yx[63:32], yx[31:0], Op[8:7]==MUL, y);

endmodule
