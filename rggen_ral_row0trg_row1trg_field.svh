class rggen_ral_row0trg_row1trg_field extends rggen_ral_field;
  local static  bit row0trg_defined = define_access("ROW0TRG");
  local static  bit row1trg_defined = define_access("ROW1TRG");

  function new(string name);
    super.new(name);
  endfunction

  function bit needs_update();
    return 1;
  endfunction

  function string get_access(uvm_reg_map map = null);
    string  access;
    uvm_reg parent;

    access  = super.get_access(uvm_reg_map::backdoor());
    if (map == uvm_reg_map::backdoor()) begin
      return access;
    end

    parent  = get_parent();
    case (parent.get_rights(map))
      "RW": return  access;
      "WO": return  access.substr(2, access.len() - 1);
      "RO": return  "RO";
    endcase
  endfunction

  function bit is_writable(uvm_reg_map map = null);
    return get_access(map) != "RO";
  endfunction

  function bit is_readable(uvm_reg_map map = null);
    return get_access(map) inside {"ROW0TRG", "ROW1TRG", "RO"};
  endfunction

  function void do_predict(
    uvm_reg_item      rw,
    uvm_predict_e     kind  = UVM_PREDICT_DIRECT,
    uvm_reg_byte_en_t be    = -1
  );
    string          access;
    uvm_reg_data_t  desired_value;

    access  = get_access(uvm_reg_map::backdoor());
    if (rw.kind == UVM_READ) begin
      desired_value = get();  //  to restore desired value
    end
    else begin
      desired_value = 0;
    end

    set_access("RO"); //  do paredict as RO type
    super.do_predict(rw, kind, be);
    set_access(access);

    set_desired_value(desired_value, rw.fname, rw.lineno);
  endfunction

  protected function void set_desired_value(
    uvm_reg_data_t  value,
    string          fname,
    int             lineno
  );
    uvm_reg parent;
    bit     busy;

    parent  = get_parent();
    busy    = parent.is_busy();

    //  override 'is_busy' state to suppress 'UVM/FLD/SET/BSY' warning
    parent.Xset_busyX(0);
    set(value, fname, lineno);
    parent.Xset_busyX(busy);
  endfunction
endclass

typedef rggen_ral_row0trg_row1trg_field rggen_ral_row0trg_field;
typedef rggen_ral_row0trg_row1trg_field rggen_ral_row1trg_field;
