class rggen_ral_indirect_reg extends rggen_ral_reg;
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

  protected virtual function void setup_index_fields();
  endfunction

  protected function void setup_index_field(
    string          reg_name,
    string          field_name,
    uvm_reg_data_t  value
  );
  endfunction
endclass
