module commit(
  input entry entries[BUF_SIZE],
  output logic is_valid[2], is_store[2],
  output logic [BUF_SIZE_LOG-1:0] tags[2],
  output logic store_enable,
  output logic [2:0] store_mode,
  output logic [31:0] store_addr, store_data
);

logic _is_valid[2];

find_committable_entries find(.entries, .is_valid(_is_valid), .indexes, .tags);

assign is_valid[0] = _is_valid[0];
assign is_store[0] = entries[indexes[0]].Unit == STORE;
assign is_store[1] = entries[indexes[1]].Unit == STORE;

always_comb
  if (is_store[0] && is_store[1] && _is_valid[0] && _is_valid[1]) begin
    is_valid[1] = 0;
  end
  else begin
    is_valid[1] = _is_valid[1];
  end

  if (is_store[0] && _is_valid[0]) begin
    store_enable = 1;
    store_mode = entries[indexes[0]].rwmm;
    store_addr = entries[indexes[0]].A;
    store_data = entries[indexes[0]].Vk;
  end
  else if (is_store[1] && _is_valid[1]) begin
    store_enable = 1;
    store_mode = entries[indexes[1]].rwmm;
    store_addr = entries[indexes[1]].A;
    store_data = entries[indexes[1]].Vk;
  end
  else begin
    store_enable = 0;
    store_mode = 'b0;
    store_addr = 'b0;
    store_data = 'b0;
  end

endmodule


// find executed entries with maximum tag.
module find_committable_entries(
  input entry entries[BUF_SIZE],
  output logic is_valid[2],
  output logic [BUF_SIZE_LOG-1:0] indexes[2],
  output logic [BUF_SIZE_LOG:0] tags[2]
);

logic _max_is_valid[BUF_SIZE], _2nd_is_valid[BUF_SIZE];
logic [BUF_SIZE_LOG-1:0] _maximum_idx[BUF_SIZE], _2nd_max_idx[BUF_SIZE];
logic [BUF_SIZE_LOG:0] _maximum_tag[BUF_SIZE], _2nd_max_tag[BUF_SIZE];

assign _max_is_valid[0] = (entries[i].e_state == S_EXECUTED);
assign _2nd_is_valid[0] = 0;
assign _maximum_idx[0] = 0;
assign _2nd_max_idx[0] = 0;
assign _maximum_tag[0] = entries[i].tag;
assign _2nd_max_tag[0] = 0;

ganvar i;
generate
  always_comb
  for (i = 1; i < BUF_SIZE; i++) begin: Search
    if (entries[i].e_state == S_EXECUTED && (entries[i].tag > _2nd_max_tag[i-1] || !_2nd_is_valid[i-1])) begin
      _max_is_valid[i] = 1;
      _2nd_is_valid[i] = _max_is_valid[i-1];

      if (!_max_is_valid[i-1]) begin
        _maximum_idx[i] = i;
        _2nd_max_idx[i] = 'b0;
        _maximum_tag[i] = entries[i].tag;
        _2nd_max_tag[i] = 'b0;
      end
      else if (entries[i].tag > _maximum_tag[i-1]) begin
        _maximum_idx[i] = i;
        _2nd_max_idx[i] = _maximum_idx[i-1];
        _maximum_tag[i] = entries[i].tag;
        _2nd_max_tag[i] = _maximum_tag[i-1];
      end
      else begin
        _maximum_idx[i] = _maximum_idx[i-1];
        _2nd_max_idx[i] = i;
        _maximum_tag[i] = _maximum_tag[i-1];
        _2nd_max_tag[i] = entries[i].tag;
      end
    end
    else begin
      _max_is_valid[i] = _max_is_valid[i-1];
      _2nd_is_valid[i] = _2nd_is_valid[i-1];
      _maximum_idx[i] = _maximum_idx[i-1];
      _2nd_max_idx[i] = _2nd_max_idx[i-1];
      _maximum_tag[i] = _maximum_tag[i-1];
      _2nd_max_tag[i] = _2nd_max_tag[i-1];
    end
  end
endgenerate

assign is_valid[0] = _max_is_valid[BUF_SIZE-1];
assign is_valid[1] = _2nd_is_valid[BUF_SIZE-1];
assign indexes[0] = _maximum_idx[BUF_SIZE-1];
assign indexes[1] = _2nd_max_idx[BUF_SIZE-1];
assign tags[0] = _maximum_tag[BUF_SIZE-1];
assign tags[1] = _2nd_max_tag[BUF_SIZE-1];

endmodule
