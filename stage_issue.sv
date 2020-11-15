module issue(
  input entry entries[BUF_SIZE-1:0]
);

logic is_valid[1:0];
logic [BUF_SIZE_LOG-1:0] indexes[1:0];

find_executable_entries find(.entries, .is_valid, .indexes);

endmodule


// find not-executed entries with maximum tag.
module find_executable_entries(
  input entry entries[BUF_SIZE-1:0],
  output logic is_valid[1:0],
  output logic [BUF_SIZE_LOG-1:0] indexes[1:0]
);

logic [BUF_SIZE_LOG-1:0] _maximum_idx[BUF_SIZE:0],
                         _2nd_max_idx[BUF_SIZE:0],
                         num_of_store_ops[BUF_SIZE:0];
logic [BUF_SIZE_LOG:0] _maximum_tag[BUF_SIZE:0],
                       _2nd_max_tag[BUF_SIZE:0];

genvar i;
generate
  for (i = BUF_SIZE-1; i >= 0; i--) begin: Search
    always_comb
      if (_2nd_max_tag[i+1] < entries[i].tag
          && ((entries[i].e_state == S_NOT_EXECUTED
          && entries[i].Qj == 0
          && entries[i].Qk == 0)
          || (entries[i].e_state == S_ADDR_GENERATED
          && num_of_store_ops[i] == 0))) begin

        // index
        _2nd_max_idx[i] = (entries[i].tag < _maximum_tag[i+1]) ? i : _maximum_idx[i+1];
        _maximum_idx[i] = (entries[i].tag > _maximum_tag[i+1]) ? i : _maximum_idx[i+1];

        // tag
        _2nd_max_idx[i] = (entries[i].tag < _maximum_tag[i+1]) ? entries[i].tag : _maximum_tag[i+1];
        _maximum_idx[i] = (entries[i].tag > _maximum_tag[i+1]) ? entries[i].tag : _maximum_tag[i+1];

      end
      else begin
        _maximum_idx[i] = _maximum_idx[i+1];
        _2nd_max_idx[i] = _2nd_max_idx[i+1];
        _maximum_tag[i] = _maximum_tag[i+1];
      end

      // select number of store ops
      mux2 #(BUF_SIZE_LOG) select_noso(
        num_of_store_ops[i+1],
        num_of_store_ops[i+1] + 1,
        entries[i].Unit == STORE,
        num_of_store_ops[i]
      );
  end
endgenerate

assign is_valid[0] = _maximum_tag[0] != 0;
assign is_valid[1] = _2nd_max_tag[0] != 0;

assign indexes[0] = _maximum_idx[0];
assign indexes[1] = _2nd_max_idx[0];

endmodule
