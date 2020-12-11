module clk_divider(
  input logic clk,
  output logic divided_clk
);

logic [25:0] cnt;

always_ff @(posedge clk)
  if (cnt == 26'd24_999_999) begin
    cnt <= 26'd0;
    divided_clk <= ~(divided_clk);
  end
  else begin
    cnt <= cnt + 26'd1;
    divided_clk <= divided_clk;
  end

endmodule
