module regfile(
  input logic clk, reset,
  input logic we3,
  input logic [4:0] ra1, ra2, wa3,
  output logic [31:0] rd1, rd2,
  input logic [31:0] wd3
);

// x0 is always zero.
logic [31:0] rf[31:1];

genvar i;
generate
  for (i = 1; i < 32; i++) begin: Reg
    flopr ff(.clk, .reset, .d(we3&(wa3==i) ? wd3 : rf[i]), .q(rf[i]));
  end
endgenerate

mux2 #(32) select_rd1(rf[ra1], 0, ra1 == 0, rd1);
mux2 #(32) select_rd2(rf[ra2], 0, ra2 == 0, rd2);

endmodule
