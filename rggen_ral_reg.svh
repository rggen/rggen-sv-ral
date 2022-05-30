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

  task backdoor_write(uvm_reg_item rw);
    rggen_backdoor  backdoor  = get_rggen_backdoor();
    if (backdoor != null) begin
      backdoor.write(rw);
    end
    else begin
      super.backdoor_write(rw);
    end
  endtask

  task backdoor_read(uvm_reg_item rw);
    rggen_backdoor  backdoor  = get_rggen_backdoor();
    if (backdoor != null) begin
      backdoor.read(rw);
    end
    else begin
      super.backdoor_read(rw);
    end
  endtask

  function uvm_status_e backdoor_read_func(uvm_reg_item rw);
    rggen_backdoor  backdoor  = get_rggen_backdoor();
    if (backdoor != null) begin
      backdoor.read_func(rw);
      return UVM_IS_OK;
    end
    else begin
      return super.backdoor_read_func(rw);
    end
  endfunction

  task backdoor_watch();
    rggen_backdoor  backdoor  = get_rggen_backdoor();
    if (backdoor != null) begin
      backdoor.wait_for_change(this);
    end
    else begin
      super.backdoor_watch();
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

  protected function rggen_backdoor get_rggen_backdoor();
    rggen_backdoor  backdoor;

    backdoor  = rggen_ral_backdoor_pkg::get_backdoor(this);
    if (backdoor == null) begin
      `uvm_warning("BACKDOOR", "backdoor access is not enabled")
    end

    return backdoor;
  endfunction
endclass
