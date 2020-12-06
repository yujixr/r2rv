module commit(
  input logic is_tag_flooded,
  input entry entries[BUF_SIZE],
  output logic is_valid[2], is_store[2],
  output logic [BUF_SIZE_LOG:0] tags[2],
  output logic store_enable,
  output ldst_mode store_mode,
  output logic [4:0] reg_addr[2],
  output logic [31:0] store_addr, store_data, reg_data[2]
);

logic _is_valid[2];
entry entries_target[2];

find_committable_entries find(.entries_all(entries), .is_valid(_is_valid), .entries_target);

assign is_valid[0] = _is_valid[0];
assign is_store[0] = entries_target[0].Unit == STORE;
assign is_store[1] = entries_target[1] == STORE;

always_comb
  if (is_tag_flooded) begin
    tags[0] = { 1'b1, entries_target[0].tag[BUF_SIZE_LOG-1:0] };
    tags[1] = { 1'b1, entries_target[1].tag[BUF_SIZE_LOG-1:0] };
  end
  else begin
    tags[0] = entries_target[0].tag;
    tags[1] = entries_target[1].tag;
  end

always_comb
  if (is_valid[0]) begin
    reg_addr[0] = entries_target[0].Dest;
    reg_data[0] = entries_target[0].result;
  end
  else begin
    reg_addr[0] = '0;
    reg_data[0] = '0;
  end

always_comb
  if (is_store[0] && is_store[1] && _is_valid[0] && _is_valid[1]) begin
    is_valid[1] = '0;
    reg_addr[1] = entries_target[1].Dest;
    reg_data[1] = entries_target[1].result;
  end
  else begin
    is_valid[1] = _is_valid[1];
    reg_addr[1] = '0;
    reg_data[1] = '0;
  end

always_comb
  if (is_store[0] && _is_valid[0]) begin
    store_enable = 1;
    store_mode = entries_target[0].rwmm;
    store_addr = entries_target[0].A;
    store_data = entries_target[0].Vk;
  end
  else if (is_store[1] && _is_valid[1]) begin
    store_enable = 1;
    store_mode = entries_target[1].rwmm;
    store_addr = entries_target[1].A;
    store_data = entries_target[1].Vk;
  end
  else begin
    store_enable = 0;
    store_mode = WORD;
    store_addr = 32'b0;
    store_data = 32'b0;
  end

endmodule


// find executed entries with maximum tag.
module find_committable_entries(
  input entry entries_all[BUF_SIZE],
  output logic is_valid[2],
  output entry entries_target[2]
);

logic _max_is_valid[BUF_SIZE], _2nd_is_valid[BUF_SIZE];
entry _maximum[BUF_SIZE], _2nd_max[BUF_SIZE];

assign _max_is_valid[0] = (entries_all[0].e_state == S_EXECUTED);
assign _2nd_is_valid[0] = 0;
assign _maximum[0] = entries_all[0];
assign _2nd_max[0] = 0;

genvar i;
generate
  for (i = 1; i < BUF_SIZE; i++) begin: Search
    always_comb
      if (entries_all[i].e_state == S_EXECUTED && (entries_all[i].tag > _2nd_max[i-1].tag || !_2nd_is_valid[i-1])) begin
        _max_is_valid[i] = 1;
        _2nd_is_valid[i] = _max_is_valid[i-1];

        if (!_max_is_valid[i-1] || entries_all[i].tag > _maximum[i-1].tag) begin
          _maximum[i] = entries_all[i];
          _2nd_max[i] = _maximum[i-1];
        end
        else begin
          _maximum[i] = _maximum[i-1];
          _2nd_max[i] = entries_all[i];
        end
      end
      else begin
        _max_is_valid[i] = _max_is_valid[i-1];
        _2nd_is_valid[i] = _2nd_is_valid[i-1];
        _maximum[i] = _maximum[i-1];
        _2nd_max[i] = _2nd_max[i-1];
      end
  end
endgenerate

assign is_valid[0] = _max_is_valid[BUF_SIZE-1];
assign is_valid[1] = _2nd_is_valid[BUF_SIZE-1];
assign entries_target[0] = _maximum[BUF_SIZE-1];
assign entries_target[1] = _2nd_max[BUF_SIZE-1];

endmodule
