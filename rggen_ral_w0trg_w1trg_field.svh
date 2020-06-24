class rggen_ral_w0trg_w1trg_field extends rggen_ral_field;
  local static  bit w0trg_defined = define_access("W0TRG");
  local static  bit w1trg_defined = define_access("W1TRG");

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
      "RW": return access;
      "WO": return access;
      "RO": return super.get_access(map);
    endcase
  endfunction

  function bit is_writable(uvm_reg_map map = null);
    return get_access(map) != "NOACCESS";
  endfunction

  function bit is_readable(uvm_reg_map map = null);
    return 0;
  endfunction

  function bit is_known_access(uvm_reg_map map = null);
    case (get_access(map))
      "W0TRG":  return 1;
      "W1TRG":  return 1;
      "WO":     return 1;
      default:  return 0;
    endcase
  endfunction

  function void do_predict(
    uvm_reg_item      rw,
    uvm_predict_e     kind  = UVM_PREDICT_DIRECT,
    uvm_reg_byte_en_t be    = -1
  );
    uvm_reg_data_t  value;
    value       = rw.value[0];
    rw.value[0] = 0;
    super.do_predict(rw, kind, be);
    rw.value[0] = value;
  endfunction
endclass

typedef rggen_ral_w0trg_w1trg_field rggen_ral_w0trg_field;
typedef rggen_ral_w0trg_w1trg_field rggen_ral_w1trg_field;
