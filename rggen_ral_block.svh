class rggen_ral_block extends uvm_reg_block;
  protected bit lock_in_progress;

  function new(string name, int has_coverage = UVM_NO_COVERAGE);
    super.new(name, has_coverage);
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

  function void lock_model();
    uvm_reg_block parent;
    uvm_reg_map   maps[$];

    if (is_locked()) begin
      return;
    end

    lock_in_progress  = 1;

    super.lock_model();
    parent  = get_parent();
    if (parent != null) begin
      lock_in_progress  = 0;
      return;
    end

    get_maps(maps);
    foreach (maps[i]) begin
      rggen_ral_map rggen_map;
      if ($cast(rggen_map, maps[i])) begin
        rggen_map.Xinit_indirect_reg_address_mapX();
      end
    end

    lock_in_progress  = 0;
  endfunction

  virtual function uvm_reg_map create_map(
    string            name,
    uvm_reg_addr_t    base_addr,
    int unsigned      n_bytes,
    uvm_endianness_e  endian,
    bit               byte_addressing = 1
  );
    uvm_factory f = uvm_factory::get();
    f.set_inst_override_by_type(
      uvm_reg_map::get_type(), rggen_ral_map::get_type(), {get_full_name(), ".", name}
    );
    return super.create_map(name, base_addr, n_bytes, endian, byte_addressing);
  endfunction

  protected virtual function uvm_reg_map create_default_map();
    return null;
  endfunction

  virtual function void enable_backdoor();
    uvm_reg registers[$];
    get_registers(registers, UVM_HIER);
    foreach (registers[i]) begin
      rggen_ral_reg rggen_reg;
      if ($cast(rggen_reg, registers[i])) begin
        rggen_reg.enable_backdoor();
      end
    end
  endfunction

  virtual function bit is_locking_model();
    return lock_in_progress;
  endfunction
endclass
