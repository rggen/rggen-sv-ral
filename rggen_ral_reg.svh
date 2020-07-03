class rggen_ral_reg extends rggen_ral_reg_base;
  protected int array_index[$];

  function new(string name, int unsigned n_bits, int has_coverage);
    super.new(name, n_bits, has_coverage);
  endfunction

  function void configure(
    uvm_reg_block parent,
    int           array_index[$],
    string        hdl_path
  );
    super.configure(parent, null, hdl_path);
    foreach (array_index[i]) begin
      this.array_index.push_back(array_index[i]);
    end
  endfunction

  function void build();
  endfunction

`ifndef RGGEN_ENABLE_ENHANCED_RAL
  virtual function uvm_reg_frontdoor create_frontdoor();
    return null;
  endfunction
`endif

  virtual function uvm_reg_block get_parent_block();
    rggen_ral_reg_file  file;
    rggen_ral_block     block;

    if ($cast(file, get_parent())) begin
      return file.get_parent_block();
    end
    else if ($cast(block, get_parent())) begin
      return block;
    end
    else begin
      return null;
    end
  endfunction

  virtual function void get_array_index(ref int array_index[$]);
    foreach (this.array_index[i]) begin
      array_index.push_back(this.array_index[i]);
    end
  endfunction

  virtual function void enable_backdoor();
    if (rggen_ral_backdoor_pkg::is_backdoor_enabled()) begin
      uvm_hdl_path_concat hdl_path[$];
      uvm_reg_backdoor    backdoor;
      get_full_hdl_path(hdl_path);
      backdoor  = rggen_ral_backdoor_pkg::get_backdoor(hdl_path[0].slices[0].path);
      set_backdoor(backdoor);
    end
  endfunction
endclass
