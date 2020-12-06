parameter RAM_SIZE_LOG = 8;
parameter RAM_SIZE = 2**RAM_SIZE_LOG;

module writer(
  input logic clk,
  input logic [31:0] RAM_READ[RAM_SIZE-1:0],
  output logic [31:0] RAM_WRITE[RAM_SIZE-1:0],
  input logic enabler,
  input ldst_mode mode,
  input logic [31:0] addr, data
);

genvar i;
generate
  for (i = 0; i < RAM_SIZE; i++) begin: Update
    always_ff @(negedge clk)
      if ((addr[RAM_SIZE_LOG+1:2]==i) & enabler)
        RAM_WRITE[i] <= data;
      else
        RAM_WRITE[i] <= RAM_READ[i];
  end
endgenerate

endmodule


module reader(
  input logic [31:0] RAM[RAM_SIZE-1:0],
  input ldst_mode mode,
  input logic [31:0] addr,
  output logic [31:0] data
);

assign data = RAM[addr[RAM_SIZE_LOG+1:2]];

endmodule


module mem(
  input logic clk, we,
  input logic [31:0] ra[4], wa,
  input ldst_mode rm[4], wm,
  input logic [31:0] wd,
  output logic [31:0] rd[4],
  output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

logic [31:0] imem[RAM_SIZE-1:0], dmem[RAM_SIZE-1:0], stdout;

initial begin
  $readmemh("imem.dat", imem);
  $readmemh("dmem.dat", dmem);
end

reader read1(imem, rm[0], ra[0], rd[0]);
reader read2(imem, rm[1], ra[1], rd[1]);
reader read3(dmem, rm[2], ra[2], rd[2]);
reader read4(dmem, rm[3], ra[3], rd[3]);
writer write(clk, dmem, dmem, we, wm, wa, wd);

assign stdout = dmem['h3f];

hex_display hex2023(stdout[23:20], HEX5);
hex_display hex1619(stdout[19:16], HEX4);
hex_display hex1215(stdout[15:12], HEX3);
hex_display hex0811(stdout[11:8], HEX2);
hex_display hex0407(stdout[7:4], HEX1);
hex_display hex0003(stdout[3:0], HEX0);

endmodule
