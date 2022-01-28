class rggen_ral_rowo_field extends rggen_ral_field;
  local static  string  access_name = "ROWO";
  local static  bit     defined     = define_access(access_name);

  protected uvm_reg_data_t  m_read_mirrored;

  function new(string name);
    super.new(name);
  endfunction

  function string get_access(uvm_reg_map map = null);
    uvm_reg parent;

    if (map == uvm_reg_map::backdoor()) begin
      return access_name;
    end

    parent  = get_parent();
    case (parent.get_rights(map))
      "WO":     return "WO";
      "RO":     return "RO";
      default:  return access_name;
    endcase
  endfunction

  function bit is_writable(uvm_reg_map map = null);
    return get_access(map) != "RO";
  endfunction

  function bit is_readable(uvm_reg_map map = null);
    return get_access(map) != "WO";
  endfunction

  function bit is_known_access(uvm_reg_map map = null);
    return 1;
  endfunction

  virtual function uvm_reg_data_t get_write_mirrored_value(
    string  fname,
    int     lineno
  );
    return get_mirrored_value(fname, lineno);
  endfunction

  virtual function uvm_reg_data_t get_read_mirrored_value(
    string  fname,
    int     lineno
  );
    //  set fname and lineno
    void'(get(fname, lineno));
    return m_read_mirrored;
  endfunction

  function bit needs_update();
    uvm_reg_data_t  mirrored_value;
    uvm_reg_data_t  desired_value;
    mirrored_value  = get_mirrored_value();
    desired_value   = get();
    return mirrored_value != desired_value;
  endfunction

  function void do_predict(
    uvm_reg_item      rw,
    uvm_predict_e     kind  = UVM_PREDICT_DIRECT,
    uvm_reg_byte_en_t be    = -1
  );
    if (kind == UVM_PREDICT_READ) begin
      do_read_predict(rw, be);
    end
    else begin
      super.do_predict(rw, kind, be);
    end
  endfunction

  function uvm_reg_data_t XpredictX(
    uvm_reg_data_t  cur_val,
    uvm_reg_data_t  wr_val,
    uvm_reg_map     map
  );
    if (is_writable(map)) begin
      return wr_val;
    end
    else begin
      return cur_val;
    end
  endfunction

  protected virtual function void do_read_predict(
    uvm_reg_item      rw,
    uvm_reg_byte_en_t be
  );
    uvm_reg_data_t        mask;
    uvm_reg_data_t        field_value;
    uvm_reg_field_cb_iter cbs;

    //  set fname and lineno
    void'(get(rw.fname, rw.lineno));

    if (rw.path inside {UVM_FRONTDOOR, UVM_PREDICT}) begin
      if (!is_readable(rw.map)) begin
        return;
      end
    end

    mask        = (1 << get_n_bits()) - 1;
    field_value = rw.value[0] & mask;

    //  process callbacks
    cbs = new(this);
    for (uvm_reg_cbs cb = cbs.first();cb != null;cb = cbs.next()) begin
      cb.post_predict(
        this, m_read_mirrored, field_value, UVM_PREDICT_READ, rw.path, rw.map
      );
    end

    m_read_mirrored = field_value & mask;
  endfunction
endclass
