class rggen_ral_reg extends uvm_reg;
  protected int unsigned  array_index[$];

  function new(string name, int unsigned n_bits, int has_coverage);
    super.new(name, n_bits, has_coverage);
  endfunction

  function void configure(
    uvm_reg_block blk_parent,
    uvm_reg_file  regfile_parent,
    int unsigned  array_index[$],
    string        hdl_path  = ""
  );
    super.configure(blk_parent, regfile_parent, hdl_path);
    foreach (array_index[i]) begin
      this.array_index.push_back(array_index[i]);
    end
  endfunction

  function void build();
  endfunction

  virtual function uvm_reg_frontdoor create_frontdoor();
    return null;
  endfunction

`ifdef RGGEN_ENABLE_BACKDOOR
  virtual function void enable_backdoor();
    uvm_hdl_path_concat hdl_path[$];
    uvm_reg_backdoor    backdoor;
    get_full_hdl_path(hdl_path);
    backdoor  = rggen_backdoor_pkg::get_backdoor(hdl_path[0].slices[0].path);
    set_backdoor(backdoor);
  endfunction
`else
  virtual function void enable_backdoor();
  endfunction
`endif
endclass
