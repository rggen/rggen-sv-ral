class rggen_ral_map extends uvm_reg_map;
  protected rggen_ral_indirect_reg  m_indirect_regs_by_offset[uvm_reg_addr_t][$];

  function new(string name = "rggen_ral_map");
    super.new(name);
  endfunction

  virtual function void add_reg(
    uvm_reg           rg,
    uvm_reg_addr_t    offset,
    string            rights  = "RW",
    bit               unmapped  = 0,
    uvm_reg_frontdoor frontdoor = null
  );
    rggen_ral_reg           rggen_reg;
    rggen_ral_indirect_reg  rggen_indirect_reg;

    if ((frontdoor == null) && $cast(rggen_reg, rg)) begin
      frontdoor = rggen_reg.create_frontdoor();
    end
    if ($cast(rggen_indirect_reg, rg)) begin
      unmapped  = 1;
    end
    super.add_reg(rg, offset, rights, unmapped, frontdoor);
  endfunction

  virtual function void set_base_addr(uvm_reg_addr_t offset);
    uvm_reg_block parent;
    uvm_reg_map   parent_map;

    super.set_base_addr(offset);

    parent  = get_parent();
    if (parent == null) begin
      return;
    end

    parent_map  = get_parent_map();
    if (parent.is_locked() && (parent_map == null)) begin
      Xinit_indirect_reg_address_mapX();
    end
  endfunction

  virtual function void set_submap_offset(uvm_reg_map submap, uvm_reg_addr_t offset);
    uvm_reg_block parent;

    super.set_submap_offset(submap, offset);

    parent  = get_parent();
    if ((submap != null) && (parent != null) && parent.is_locked()) begin
      rggen_ral_map root_map;
      if ($cast(root_map, get_root_map())) begin
        root_map.Xinit_indirect_reg_address_mapX();
      end
    end
  endfunction

  virtual function uvm_reg get_reg_by_offset(uvm_reg_addr_t offset, bit read);
    uvm_reg       rg;
    uvm_reg_block parent;

    rg  = super.get_reg_by_offset(offset, read);
    if (rg != null) begin
      return rg;
    end

    parent  = get_parent();
    if (parent == null) begin
      return null;
    end

    if (!(parent.is_locked() && m_indirect_regs_by_offset.exists(offset))) begin
      return null;
    end

    foreach (m_indirect_regs_by_offset[offset][i]) begin
      if (m_indirect_regs_by_offset[offset][i].is_active()) begin
        return m_indirect_regs_by_offset[offset][i];
      end
    end

    return null;
  endfunction

  function void Xinit_indirect_reg_address_mapX();
    uvm_reg_map   root_map;
    rggen_ral_map root_rggen_map;
    uvm_reg_map   submaps[$];
    uvm_reg       registers[$];

    root_map  = get_root_map();
    if (root_map == this) begin
      m_indirect_regs_by_offset.delete();
    end
    if (!$cast(root_rggen_map, root_map)) begin
      return;
    end

    get_submaps(submaps, UVM_NO_HIER);
    foreach (submaps[i]) begin
      rggen_ral_map rggen_map;
      if ($cast(rggen_map, submaps[i])) begin
        rggen_map.Xinit_indirect_reg_address_mapX();
      end
    end

    get_registers(registers, UVM_NO_HIER);
    foreach (registers[i]) begin
      rggen_ral_indirect_reg  indirect_reg;
      uvm_reg_map_info        map_info;

      if (!$cast(indirect_reg, registers[i])) begin
        continue;
      end

      map_info          = get_reg_map_info(indirect_reg);
      map_info.unmapped = 0;
      void'(get_physical_addresses(
        map_info.offset, 0, indirect_reg.get_n_bytes(), map_info.addr
      ));
      foreach (map_info.addr[j]) begin
        root_rggen_map.m_indirect_regs_by_offset[map_info.addr[j]].push_back(indirect_reg);
      end
    end
  endfunction

  `uvm_object_utils(rggen_ral_map)
endclass
