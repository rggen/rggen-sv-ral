class rggen_ral_block extends uvm_reg_block;
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

  protected virtual function uvm_reg_map create_default_map();
    return null;
  endfunction
endclass
