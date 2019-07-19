class rggen_ral_rwe_rwl_field extends rggen_ral_field;
  local static  bit rwe_defined = define_access("RWE");
  local static  bit rwl_defined = define_access("RWL");

  function new(string name, bit enable_mode, string reg_name, string field_name);
    super.new(name);
  endfunction
endclass

class rggen_ral_rwe_field #(
  string  REG_NAME    = "",
  string  FIELD_NAME  = ""
) extends rggen_ral_rwe_rwl_field;
  function new(string name);
    super.new(name, 1, REG_NAME, FIELD_NAME);
  endfunction
endclass

class rggen_ral_rwl_field #(
  string  REG_NAME    = "",
  string  FIELD_NAME  = ""
) extends rggen_ral_rwe_rwl_field;
  function new(string name);
    super.new(name, 0, REG_NAME, FIELD_NAME);
  endfunction
endclass
