typedef class rggen_ral_indirect_reg_index_field;
typedef class rggen_ral_indirect_reg_frontdoor;

class rggen_ral_indirect_reg extends rggen_ral_reg;
  protected rggen_ral_indirect_reg_index_field  index_fields[$];

  function new(string name, int unsigned n_bits, int has_coverage);
    super.new(name, n_bits, has_coverage);
  endfunction

  function void configure(
    uvm_reg_block parent,
    int           array_index[$],
    int           array_size[$],
    string        hdl_path
  );
    super.configure(parent, array_index, array_size, hdl_path);
    setup_index_fields();
  endfunction

  virtual function uvm_reg_frontdoor create_frontdoor();
    rggen_ral_indirect_reg_frontdoor  frontdoor;
    frontdoor = new("indirect_reg_frontdoor", index_fields);
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

  protected function void setup_index_field(string field_name, uvm_reg_data_t value);
    rggen_ral_indirect_reg_index_field  index_field;
    index_field = new(this, field_name, value);
    index_fields.push_back(index_field);
  endfunction
endclass

class rggen_ral_indirect_reg_index_field;
  protected rggen_ral_reg   rg;
  protected string          field_name;
  protected uvm_reg_data_t  value;
  protected uvm_reg_field   index_field;
  protected uvm_reg         index_reg;

  function new(rggen_ral_reg rg, string field_name, uvm_reg_data_t value);
    this.rg         = rg;
    this.field_name = field_name;
    this.value      = value;
  endfunction

  function uvm_reg get_index_reg();
    if (index_reg == null) begin
      uvm_reg_field field = get_index_field();
      index_reg = field.get_parent();
    end
    return index_reg;
  endfunction

  function uvm_reg_field get_index_field();
    if (index_field == null) begin
      lookup_index_field();
    end
    return index_field;
  endfunction

  function uvm_reg_data_t get_value();
    return value;
  endfunction

  function bit is_matched();
    uvm_reg_field field = get_index_field();
    return field.value == value;
  endfunction

  local function void lookup_index_field();
    rggen_ral_name_slice  name_slices[$];
    rggen_ral_get_name_slices(field_name, name_slices);
    index_field = rggen_ral_find_field_by_name(rg.get_parent_block(), name_slices);
  endfunction
endclass

class rggen_ral_indirect_reg_frontdoor extends uvm_reg_frontdoor;
  protected rggen_ral_indirect_reg_index_field  index_fields[$];
  protected bit                                 index_regs[uvm_reg];

  function new(
    input string                              name,
    ref   rggen_ral_indirect_reg_index_field index_fields[$]
  );
    super.new(name);
    foreach (index_fields[i]) begin
      this.index_fields.push_back(index_fields[i]);
    end
  endfunction

  task body();
    uvm_status_e  status;

    update_index_fields(status);
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

  local task update_index_fields(ref uvm_status_e status);
    if (index_regs.size() == 0) begin
      foreach (index_fields[i]) begin
        uvm_reg rg  = index_fields[i].get_index_reg();
        if (!index_regs.exists(rg)) begin
          index_regs[rg]  = 1;
        end
      end
    end

    foreach (index_fields[i]) begin
      uvm_reg_field field = index_fields[i].get_index_field();
      field.set(index_fields[i].get_value(), rw_info.fname, rw_info.lineno);
    end

    foreach (index_regs[index_reg]) begin
      index_reg.update(
        status, rw_info.path, null, rw_info.parent,
        rw_info.prior, rw_info.extension, rw_info.fname, rw_info.lineno
      );
      if (status == UVM_NOT_OK) begin
        return;
      end
    end
  endtask
endclass
