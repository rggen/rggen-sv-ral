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

  task backdoor_watch();
    rggen_ral_backdoor_pkg::rggen_backdoor  backdoor;

    if (rggen_ral_backdoor_pkg::is_backdoor_enabled()) begin
      void'($cast(backdoor, get_backdoor()));
    end

    if (backdoor != null) begin
      backdoor.wait_for_change(this);
    end
    else begin
      `uvm_fatal("BACKDOOR", "backdoor access is not enabled")
    end
  endtask

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
      set_backdoor(rggen_ral_backdoor_pkg::get_backdoor());
    end
  endfunction
endclass
