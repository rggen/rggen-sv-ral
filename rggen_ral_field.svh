class rggen_ral_field extends uvm_reg_field;
  protected string  m_field_access;

  function new(string name = "rggen_ral_field");
    super.new(name);
  endfunction

  function void configure(
    uvm_reg         parent,
    int unsigned    size,
    int unsigned    lsb_pos,
    string          access,
    bit             volatile,
    uvm_reg_data_t  reset,
    bit             has_reset,
    bit             is_rand,
    bit             individually_accessible
  );
    super.configure(
      parent, size, lsb_pos, access, volatile,
      reset, has_reset, is_rand, individually_accessible
    );
    m_field_access  = access.toupper();
  endfunction

  function string set_access(string mode);
    m_field_access  = super.set_access(mode);
    return m_field_access;
  endfunction
endclass
