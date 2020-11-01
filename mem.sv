parameter RAM_SIZE_LOG = 8;
parameter RAM_SIZE = 2**RAM_SIZE_LOG;

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
  input logic [RAM_SIZE_LOG-1:0] addr,
  input logic [31:0] data
);

genvar i;
generate
  for (i = 0; i < RAM_SIZE; i++) begin: Update
    always_ff @(negedge clk)
      if ((addr==i) & enabler)
        case(mode)
          BYTE:       RAM_WRITE[i] <= { RAM_READ[i][31:8], data[7:0] };
          HALF_WORD:  RAM_WRITE[i] <= { RAM_READ[i][31:16], data[15:0] };
          WORD:       RAM_WRITE[i] <= data;
          default:    RAM_WRITE[i] <= RAM_READ[i];
        endcase
      else
        RAM_WRITE[i] <= RAM_READ[i];
  end
endgenerate

endmodule


module reader(
  input logic [31:0] RAM[RAM_SIZE-1:0],
  input logic [2:0] mode,
  input logic [RAM_SIZE_LOG-1:0] addr,
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
  input logic [31:0] ra1, ra2, wa3,
  input logic [2:0] rm1, rm2, wm3,
  input logic [31:0] wd3,
  output logic [31:0] rd1, rd2,
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

logic [31:0] imem[RAM_SIZE-1:0], dmem[RAM_SIZE-1:0], stdout;

initial begin
  $readmemh("imem.dat", imem);
  $readmemh("dmem.dat", dmem);
end

reader read1(imem, rm1, ra1[RAM_SIZE_LOG+1:2], rd1);
reader read2(dmem, rm2, ra2[RAM_SIZE_LOG+1:2], rd2);
writer write(clk, dmem, dmem, we, wm3, wa3[RAM_SIZE_LOG+1:2], wd3);

assign stdout = dmem['h3f];

hex_display hex5(stdout[23:20], HEX5);
hex_display hex4(stdout[19:16], HEX4);
hex_display hex3(stdout[15:12], HEX3);
hex_display hex2(stdout[11:8], HEX2);
hex_display hex1(stdout[7:4], HEX1);
hex_display hex0(stdout[3:0], HEX0);

endmodule
