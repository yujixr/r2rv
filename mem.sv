module mem(
  input logic clk, we,
  input logic [8:0] ra1, ra2, wa3, 
  input logic [2:0] rm1, rm2, wm3, 
  input logic [31:0] wd3,
  output logic [31:0] rd1, rd2,
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

parameter RAM_SIZE = 128;
logic [7:0] RAM[RAM_SIZE-1:0];

initial
  $readmemh("memfile.dat",RAM);

function [31:0] read(
  input logic [7:0] RAM[RAM_SIZE-1:0],
  input logic [8:0] addr,
  input logic [2:0] access_mode
);

  case(access_mode)
    3'b000: read = { { 24{ RAM[addr][7] } }, RAM[addr] };
    3'b001: read = { { 16{ RAM[addr + 1][7] } }, RAM[addr + 1], RAM[addr] };
    3'b010: read = { RAM[addr + 3], RAM[addr + 2], RAM[addr + 1], RAM[addr] };
    3'b100: read = { 24'b0, RAM[addr] };
    3'b101: read = { 16'b0, RAM[addr + 1], RAM[addr] };
    default: read = 32'b0;
  endcase

endfunction


assign rd1 = read(RAM, ra1, rm1);
assign rd2 = read(RAM, ra2, rm2);

always_ff @(posedge clk)
  case(wm3)
    3'b000: if (we) begin RAM[wa3] <= wd3[7:0]; end
    3'b001: if (we) begin RAM[wa3] <= wd3[7:0]; RAM[wa3 + 1] <= wd3[15:8]; end
    3'b010: if (we) begin RAM[wa3] <= wd3[7:0]; RAM[wa3 + 1] <= wd3[15:8]; RAM[wa3 + 2] <= wd3[23:16]; RAM[wa3 + 3] <= wd3[31:24]; end
    default: ;
  endcase

hex_display hex5(RAM[RAM_SIZE-1][7:4], HEX5);
hex_display hex4(RAM[RAM_SIZE-1][3:0], HEX4);
hex_display hex3(RAM[RAM_SIZE-1][7:4], HEX3);
hex_display hex2(RAM[RAM_SIZE-1][3:0], HEX2);
hex_display hex1(RAM[RAM_SIZE-1][7:4], HEX1);
hex_display hex0(RAM[RAM_SIZE-1][3:0], HEX0);

endmodule
