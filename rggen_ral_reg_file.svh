class rggen_ral_reg_file extends rggen_ral_block;
  protected int array_index[$];
  protected int array_size[$];

  function new(string name, int unsigned n_bytes, int has_coverage);
    super.new(name, n_bytes, has_coverage);
  endfunction

  function void configure(
    uvm_reg_block parent,
    int           array_index[$],
    int           array_size[$],
    string        hdl_path
  );
    super.configure(parent, hdl_path);
    this.array_index  = array_index;
    this.array_size   = array_size;
  endfunction

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

  virtual function void get_array_info(
    ref   int         array_index[$],
    ref   int         array_size[$],
    input uvm_hier_e  hier  = UVM_HIER
  );
    if (hier == UVM_HIER) begin
      rggen_ral_reg_file  rf;
      if ($cast(rf, get_parent())) begin
        rf.get_array_info(array_index, array_size, hier);
      end
    end

    foreach (this.array_index[i]) begin
      array_index.push_back(this.array_index[i]);
      array_size.push_back(this.array_size[i]);
    end
  endfunction
endclass
