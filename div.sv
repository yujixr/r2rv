module div(
  input logic [31:0] Vj, Vk,
  input logic [9:0] Op,
  output logic [31:0] y
);

parameter DIV    = 2'b00;
parameter DIVU   = 2'b01;
parameter REM    = 2'b10;
parameter REMU   = 2'b11;

assign y = 32'b0;

endmodule
