class rggen_ral_map extends rggen_ral_map_base;
  protected uvm_reg m_indirect_regs_by_offset[uvm_reg_addr_t][uvm_reg];

  function new(string name = "rggen_ral_map");
    super.new(name);
  endfunction

`ifdef RGGEN_ENABLE_ENHANCED_RAL
  typedef tue_pkg::tue_reg_map  tue_reg_map;

  protected function void m_remove_cached_reg(tue_reg_map root_map, uvm_reg rg, uvm_reg_addr_t addr);
    rggen_ral_map map;
    void'($cast(map, root_map));
    if (map.m_indirect_regs_by_offset.exists(addr)) begin
      map.m_indirect_regs_by_offset[addr].delete(rg);
    end
    else begin
      super.m_remove_cached_reg(root_map, rg, addr);
    end
  endfunction

  protected function void m_map_reg(tue_reg_map root_map, uvm_reg rg, uvm_reg_addr_t addr);
    rggen_ral_map           map;
    rggen_ral_indirect_reg  indirect_reg;
    if ($cast(indirect_reg, rg)) begin
      void'($cast(map, root_map));
      map.m_indirect_regs_by_offset[addr][rg] = rg;
    end
    else begin
      super.m_map_reg(root_map, rg, addr);
    end
  endfunction

  protected function void m_check_reg_addr(
    tue_reg_map     root_map,
    uvm_reg         rg,
    uvm_reg_addr_t  addr
  );
    rggen_ral_map           map;
    rggen_ral_indirect_reg  indirect_reg;

    void'($cast(map, root_map));
    if (!$cast(indirect_reg, rg)) begin
      if (map.m_indirect_regs_by_offset.exists(addr)) begin
        uvm_reg other_reg;
        if (map.m_indirect_regs_by_offset[addr].first(other_reg)) begin
          `uvm_warning(
            "RegModel",
            $sformatf(
              "In map '%s' register '%s' maps to same address as register '%s': 'h%0h",
              get_full_name(), rg.get_full_name(),
              other_reg.get_full_name(), addr
            )
          )
          return;
        end
      end
    end

    super.m_check_reg_addr(root_map, rg, addr);
  endfunction

  protected function void m_check_mem_addr(
    tue_reg_map             root_map,
    uvm_mem                 mem,
    uvm_reg_map_addr_range  mem_range
  );
    rggen_ral_map map;

    void'($cast(map, root_map));
    foreach (map.m_indirect_regs_by_offset[addr]) begin
      if (map.m_indirect_regs_by_offset.size() == 0) begin
        continue;
      end
      if ((addr >= mem_range.min) && (addr <= mem_range.max)) begin
        `uvm_warning(
          "RegModel",
          $sformatf(
            {
              "In map '%s' memory '%s' with [%0h:%0h] overlaps with ",
              "address of existing register: 'h%0h"
            },
            get_full_name(), mem.get_full_name(), mem_range.min, mem_range.max, addr
          )
        )
        return;
      end
    end

    super.m_check_mem_addr(root_map, mem, mem_range);
  endfunction
`else
  virtual function void add_reg(
    uvm_reg           rg,
    uvm_reg_addr_t    offset,
    string            rights    = "RW",
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
        root_rggen_map.m_indirect_regs_by_offset[map_info.addr[j]][indirect_reg]  = indirect_reg;
      end
    end
  endfunction
`endif

  function uvm_reg get_reg_by_offset(uvm_reg_addr_t offset, bit read = 1);
    begin
      uvm_reg rg  = super.get_reg_by_offset(offset, read);
      if (rg != null) begin
        return rg;
      end
    end

    if (!m_indirect_regs_by_offset.exists(offset)) begin
      return null;
    end

    foreach (m_indirect_regs_by_offset[offset][rg]) begin
      rggen_ral_indirect_reg  indirect_reg;
      void'($cast(indirect_reg, rg));
      if (indirect_reg.is_active()) begin
        return rg;
      end
    end

    return null;
  endfunction

  `uvm_object_utils(rggen_ral_map)
endclass
