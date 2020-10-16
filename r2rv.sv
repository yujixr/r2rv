module r2rv(
  input logic clk,
  input logic reset,
  input logic [9:0] sw,
  input logic [2:0] key,
  output logic [9:0] led
);

  assign led = sw & ~key[0] & ~key[1] & ~key[2];

endmodule
