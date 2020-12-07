module flopr #(parameter WIDTH = 8) (
  input logic clk, reset,
  input logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q
);

always_ff @(posedge clk)
  if (reset) q <= 0;
  else q <= d;

endmodule

module twinflop #(parameter WIDTH = 8) (
  input logic clk, reset, can_proceed[2],
  input logic [WIDTH-1:0] in[2],
  output logic [WIDTH-1:0] out[2]
);

logic [WIDTH-1:0] next[2];

always_comb
  if (!can_proceed[0]) begin
    next[0] = out[0];
    next[1] = out[1];
  end
  else if (!can_proceed[1]) begin
    next[0] = out[1];
    next[1] = in[0];
  end
  else begin
    next[0] = in[0];
    next[1] = in[1];
  end

flopr #(WIDTH) ff1(.clk, .reset, .d(next[0]), .q(out[0]));
flopr #(WIDTH) ff2(.clk, .reset, .d(next[1]), .q(out[1]));

endmodule
