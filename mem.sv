parameter RAM_SIZE_LOG = 7;
parameter RAM_SIZE = 2**(RAM_SIZE_LOG + 1);

parameter BYTE        = 3'b000;
parameter HALF_WORD   = 3'b001;
parameter WORD        = 3'b010;
parameter U_BYTE      = 3'b100;
parameter U_HALF_WORD = 3'b101;


module writer(
  input logic clk,
  input logic [31:0] RAM_READ[RAM_SIZE-1:0],
  output logic [31:0] RAM_WRITE[RAM_SIZE-1:0],
  input logic enabler,
  input logic [2:0] mode,
  input logic [RAM_SIZE_LOG:0] addr,
  input logic [31:0] data
);

logic [31:0] x;
assign x = RAM_READ[addr];

always_ff @(posedge clk)
  if (enabler)
    case(mode)
      BYTE:       RAM_WRITE[addr] <= { x[31:8], data[7:0] };
      HALF_WORD:  RAM_WRITE[addr] <= { x[31:16], data[15:0] };
      WORD:       RAM_WRITE[addr] <= data;
      default: ;
    endcase

endmodule


module reader(
  input logic [31:0] RAM[RAM_SIZE-1:0],
  input logic [2:0] mode,
  input logic [RAM_SIZE_LOG:0] addr,
  output logic [31:0] data
);

logic [31:0] x;
assign x = RAM[addr];

always_comb
  case(mode)
    BYTE:         data = { { 24{ x[7] } }, x[7:0] };
    HALF_WORD:    data = { { 16{ x[15] } }, x[15:0] };
    WORD:         data = x;
    U_BYTE:       data = { 24'b0, x[7:0] };
    U_HALF_WORD:  data = { 16'b0, x[15:0] };
    default:      data = 32'b0;
  endcase

endmodule


module mem(
  input logic clk, we,
  input logic [8:0] ra1, ra2, wa3, 
  input logic [2:0] rm1, rm2, wm3, 
  input logic [31:0] wd3,
  output logic [31:0] rd1, rd2,
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

logic [31:0] RAM[RAM_SIZE-1:0];

initial
  $readmemh("memfile.dat", RAM);

reader read1(RAM, rm1, ra1, rd1);
reader read2(RAM, rm2, ra2, rd2);
writer write(clk, RAM, RAM, we, wm3, wa3, wd3);

logic [31:0] disp;
assign disp = RAM[RAM_SIZE-1];

hex_display hex5(disp[23:20], HEX5);
hex_display hex4(disp[19:16], HEX4);
hex_display hex3(disp[15:12], HEX3);
hex_display hex2(disp[11:8], HEX2);
hex_display hex1(disp[7:4], HEX1);
hex_display hex0(disp[3:0], HEX0);

endmodule
