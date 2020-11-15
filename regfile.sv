module regfile(
  input logic clk, reset,
  input logic [4:0] ra1, ra2, wa3,
  output logic [31:0] rd1, rd2,
  input logic [31:0] wd3
);

parameter REG_SIZE = 32;

// x0 is always zero.
logic [31:0] rf[REG_SIZE-1:1];

genvar i;
generate
  for (i = 1; i < REG_SIZE; i++) begin: Reg
    flopr #(32) ff(.clk, .reset, .d((wa3==i) ? wd3 : rf[i]), .q(rf[i]));
  end
endgenerate

assign rd1 = rf[ra1];
assign rd2 = rf[ra2];

endmodule
