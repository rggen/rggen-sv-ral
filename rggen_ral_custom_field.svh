class rggen_ral_custom_field_base extends rggen_ral_field;
  local static  bit defined = define_access("CUSTOM");

  protected bit written;

  function new(string name);
    super.new(name);
  endfunction

  function void configure(
    uvm_reg         parent,
    int unsigned    size,
    int unsigned    lsb_pos,
    string          access,
    bit             volatile,
    uvm_reg_data_t  reset_value,
    uvm_reg_data_t  reset_values[$],
    bit             has_reset,
    int             sequence_index,
    int             sequence_size,
    string          reference_name
  );
    if (hw_update()) begin
      volatile  = 1;
    end
    else if ((sw_read() == "DEFAULT") && (sw_write() == "NONE")) begin
      volatile  = 1;
    end

    super.configure(
      parent, size, lsb_pos, access, volatile,
      reset_value, reset_values, has_reset, sequence_index, sequence_size, reference_name
    );
  endfunction

  function bit is_writable(uvm_reg_map map = null);
    return (get_rights(map) != "RO") && (sw_write() != "NONE");
  endfunction

  function bit is_readable(uvm_reg_map map = null);
    return (get_rights(map) != "WO") && (sw_read() != "NONE");
  endfunction

  protected function string get_rights(uvm_reg_map map);
    uvm_reg parent;
    parent  = get_parent();
    return parent.get_rights(map);
  endfunction

  function void reset(string kind = "HARD");
    super.reset(kind);
    if (kind == "HARD") begin
      written = 0;
    end
  endfunction

  function void set(
    uvm_reg_data_t  value,
    string          fname   = "",
    int             lineno  = 0
  );
    uvm_reg_data_t  set_value;
    uvm_reg_data_t  current_value;
    uvm_reg_data_t  mask;

    current_value = get(fname, lineno);
    mask          = (1 << get_n_bits()) - 1;
    set_value     = get_effecive_write_value(value, current_value, mask);

    super.set(set_value, fname, lineno);
  endfunction

  function void do_predict(
    uvm_reg_item      rw,
    uvm_predict_e     kind  = UVM_PREDICT_DIRECT,
    uvm_reg_byte_en_t be    = -1
  );
    uvm_reg_data_t  mask;
    uvm_reg_data_t  field_value;
    uvm_reg_data_t  current_value;
    uvm_reg_data_t  paredicted_value;

    mask          = (1 << get_n_bits()) - 1;
    field_value   = rw.value[0] & mask;
    current_value = get_mirrored_value();
    case (kind)
      UVM_PREDICT_READ:   paredicted_value  = do_read_predict(field_value, current_value, mask);
      UVM_PREDICT_WRITE:  paredicted_value  = do_write_predict(field_value, current_value, mask);
      default:            paredicted_value  = field_value;
    endcase

    begin
      uvm_reg_data_t  value = rw.value[0];
      rggen_door      path  = rw.path;

      rw.value[0] = paredicted_value;
      rw.path     = RGGEN_DEFAULT_DOOR;
      super.do_predict(rw, kind, be);

      rw.value[0] = value;
      rw.path     = path;
    end
  endfunction

  protected virtual function uvm_reg_data_t do_read_predict(
    uvm_reg_data_t  field_value,
    uvm_reg_data_t  current_value,
    uvm_reg_data_t  mask
  );
    case (sw_read())
      "DEFAULT":  return field_value;
      "SET":      return mask;
      "CLEAR":    return 0;
      default:    return current_value;
    endcase
  endfunction

  protected virtual function uvm_reg_data_t do_write_predict(
    uvm_reg_data_t  field_value,
    uvm_reg_data_t  current_value,
    uvm_reg_data_t  mask
  );
    if (sw_write_once() && written) begin
      return current_value;
    end

    written = 1;
    return get_effecive_write_value(field_value, current_value, mask);
  endfunction

  virtual function bit hw_write(
    uvm_reg_data_t  value,
    string          fname   = "",
    int             lineno  = 0
  );
    uvm_reg_data_t  mask;
    mask  = (1 << get_n_bits()) - 1;
    return predict(.value(value & mask), .kind(UVM_PREDICT_DIRECT));
  endfunction

  virtual function bit hw_set(string fname = "", int lineno = 0);
    return hw_write('1, fname, lineno);
  endfunction

  virtual function bit hw_clear(string fname = "", int lineno = 0);
    return hw_write('0, fname, lineno);
  endfunction

  protected virtual function string sw_read();
  endfunction

  protected virtual function string sw_write();
  endfunction

  protected virtual function bit sw_write_once();
  endfunction

  protected virtual function bit hw_update();
  endfunction

  protected virtual function uvm_reg_data_t get_effecive_write_value(
    uvm_reg_data_t  value,
    uvm_reg_data_t  current_value,
    uvm_reg_data_t  mask
  );
    case (sw_write())
      "DEFAULT":  return value;
      "SET":      return mask;
      "SET_0":    return current_value | ((~value) & mask);
      "SET_1":    return current_value | value;
      "CLEAR":    return 0;
      "CLEAR_0":  return current_value & value;
      "CLEAR_1":  return current_value & ((~value) & mask);
      "TOGGLE_0": return current_value ^ ((~value) & mask);
      "TOGGLE_1": return current_value ^ value;
      default:    return current_value;
    endcase
  endfunction
endclass

class rggen_ral_custom_field #(
  string  SW_READ       = "",
  string  SW_WRITE      = "",
  bit     SW_WRITE_ONCE = 0,
  bit     HW_UPDATE     = 0
) extends rggen_ral_custom_field_base;
  function new(string name);
    super.new(name);
  endfunction

  protected function string sw_read();
    return SW_READ;
  endfunction

  protected function string sw_write();
    return SW_WRITE;
  endfunction

  protected function bit sw_write_once();
    return SW_WRITE_ONCE;
  endfunction

  protected function bit hw_update();
    return HW_UPDATE;
  endfunction
endclass
