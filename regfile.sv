module regfile(
  input logic clk, reset,
  input logic we3,
  input logic [4:0] ra1, ra2, wa3,
  output logic [31:0] rd1, rd2,
  input logic [31:0] wd3
);

logic [31:0] rf[31:0];

genvar i;
generate
    for (i = 0; i < 32; i++) begin: Reg
      flopr ff(clk, reset, we3&(wa3==i) ? wd3 : rf[i], rf[i]);
    end
endgenerate

assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
assign rd2 = (ra2 != 0) ? rf[ra2] : 0;

endmodule
