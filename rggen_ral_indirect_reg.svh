typedef class rggen_ral_indirect_reg_index_field;
typedef class rggen_ral_indirect_reg_frontdoor;

class rggen_ral_indirect_reg extends rggen_ral_reg;
  protected rggen_ral_indirect_reg_index_field  index_fields[$];

  function new(string name, int unsigned n_bits, int has_coverage);
    super.new(name, n_bits, has_coverage);
  endfunction

  function void configure(
    uvm_reg_block blk_parent,
    uvm_reg_file  regfile_parent,
    int unsigned  array_index[$],
    string        hdl_path  = ""
  );
    super.configure(blk_parent, regfile_parent, array_index, hdl_path);
    setup_index_fields();
  endfunction

  virtual function uvm_reg_frontdoor create_frontdoor();
    rggen_ral_indirect_reg_frontdoor  frontdoor;
    frontdoor = new(index_fields);
    return frontdoor;
  endfunction

  virtual function bit is_active();
    foreach (index_fields[i]) begin
      if (!index_fields[i].is_matched()) begin
        return 0;
      end
    end
    return 1;
  endfunction

  protected virtual function void setup_index_fields();
  endfunction

  protected function void setup_index_field(
    string          reg_name,
    string          field_name,
    uvm_reg_data_t  value
  );
    rggen_ral_indirect_reg_index_field  index_field;
    index_field = new(this, reg_name, field_name, value);
    index_fields.push_back(index_field);
  endfunction
endclass

class rggen_ral_indirect_reg_index_field;
  protected uvm_reg         register;
  protected string          reg_name;
  protected string          field_name;
  protected uvm_reg_data_t  value;
  protected uvm_reg         index_reg;
  protected uvm_reg_field   index_field;

  function new(
    uvm_reg         register,
    string          reg_name,
    string          field_name,
    uvm_reg_data_t  value
  );
    this.register   = register;
    this.reg_name   = reg_name;
    this.field_name = field_name;
    this.value      = value;
  endfunction

  function uvm_reg get_index_reg();
    if (index_reg == null) begin
      uvm_reg_block parent;
      parent    = register.get_parent();
      index_reg = parent.get_reg_by_name(reg_name);
    end
    return index_reg;
  endfunction

  function uvm_reg_field get_index_field();
    if (index_field == null) begin
      void'(get_index_reg());
      if (index_reg != null) begin
        index_field = index_reg.get_field_by_name(field_name);
      end
    end
    return index_field;
  endfunction

  function uvm_reg_data_t get_value();
    return value;
  endfunction
  
  function bit is_matched();
    void'(get_index_field());
    return (index_field.value == value) ? 1 : 0;
  endfunction
endclass

class rggen_ral_indirect_reg_frontdoor extends uvm_reg_frontdoor;
  protected rggen_ral_indirect_reg_index_field  index_fields[$];
  protected bit                                 index_regs[uvm_reg];

  function new(ref rggen_ral_indirect_reg_index_field index_fields[$]);
    super.new("");
    foreach (index_fields[i]) begin
      this.index_fields.push_back(index_fields[i]);
    end
  endfunction

  task body();
    uvm_status_e  status;

    update_index_fiels(status);
    if (status == UVM_NOT_OK) begin
      rw_info.status  = status;
      return;
    end

    if (rw_info.kind == UVM_WRITE) begin
      rw_info.local_map.do_write(rw_info);
    end
    else begin
      rw_info.local_map.do_read(rw_info);
    end
  endtask

  local task update_index_fiels(ref uvm_status_e status);
    if (index_regs.size() == 0) begin
      foreach (index_fields[i]) begin
        uvm_reg index_reg = index_fields[i].get_index_reg();
        if (!index_regs.exists(index_reg)) begin
          index_regs[index_reg] = 1;
        end
      end
    end

    foreach (index_fields[i]) begin
      uvm_reg_field index_field = index_fields[i].get_index_field();
      index_field.set(index_fields[i].get_value(), rw_info.fname, rw_info.lineno);
    end

    foreach (index_regs[index_reg]) begin
      index_reg.update(
        status, rw_info.path, rw_info.map, rw_info.parent,
        rw_info.prior, rw_info.extension, rw_info.fname, rw_info.lineno
      );
      if (status == UVM_NOT_OK) begin
        return;
      end
    end
  endtask
endclass
