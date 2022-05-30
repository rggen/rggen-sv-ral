class rggen_ral_block extends rggen_ral_block_base;
  protected int unsigned  n_bytes;

  function new(string name, int unsigned n_bytes, int has_coverage);
    super.new(name, has_coverage);
    this.n_bytes  = n_bytes;
  endfunction

  function void configure(
    uvm_reg_block parent    = null,
    string        hdl_path  = ""
  );
    super.configure(parent, hdl_path);
    if (default_map == null) begin
      default_map = create_default_map();
    end
  endfunction

  function void build();
  endfunction

  virtual function void get_register_files(
    ref   rggen_ral_reg_file  files[$],
    input uvm_hier_e          hier  = UVM_HIER
  );
    uvm_reg_block       blocks[$];
    rggen_ral_reg_file  file;

    get_blocks(blocks, UVM_NO_HIER);
    foreach (blocks[i]) begin
      if ($cast(file, blocks[i])) begin
        files.push_back(file);
        if (hier == UVM_HIER) begin
          file.get_register_files(files, hier);
        end
      end
    end
  endfunction

`ifndef RGGEN_ENABLE_ENHANCED_RAL
  function void lock_model();
    uvm_reg_block parent;
    uvm_reg_map   maps[$];

    if (is_locked()) begin
      return;
    end

    super.lock_model();
    parent  = get_parent();
    if (parent != null) begin
      return;
    end

    get_maps(maps);
    foreach (maps[i]) begin
      rggen_ral_map map;
      if ($cast(map, maps[i])) begin
        map.Xinit_indirect_reg_address_mapX();
      end
    end
  endfunction
`endif

  virtual function uvm_reg_map create_map(
    string            name,
    uvm_reg_addr_t    base_addr,
    int unsigned      n_bytes,
    uvm_endianness_e  endian,
    bit               byte_addressing = 1
  );
    uvm_factory f = uvm_factory::get();
    f.set_inst_override_by_type(
      rggen_ral_map_base::get_type(), rggen_ral_map::get_type(), {get_full_name(), ".", name}
    );
    return super.create_map(name, base_addr, n_bytes, endian, byte_addressing);
  endfunction

  protected virtual function uvm_reg_map create_default_map();
    return create_map("default_map", 0, n_bytes, UVM_LITTLE_ENDIAN, 1);
  endfunction
endclass
