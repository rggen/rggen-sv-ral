class rggen_ral_w0trg_w1trg_field_callbacks extends uvm_reg_cbs;
  function new(string name = "rggen_ral_w0trg_w1trg_field_callbacks");
    super.new(name);
  endfunction

  function void post_predict(
    input uvm_reg_field   fld,
    input uvm_reg_data_t  previous,
    inout uvm_reg_data_t  value,
    input uvm_predict_e   kind,
    input rggen_door      path,
    input uvm_reg_map     map
  );
    value = 0;
  endfunction
endclass

class rggen_ral_w0trg_w1trg_field extends rggen_ral_field;
  local static  bit w0trg_defined = define_access("W0TRG");
  local static  bit w1trg_defined = define_access("W1TRG");

  local static  rggen_ral_w0trg_w1trg_field_callbacks cb;

  function new(string name);
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
    int             sequence_index,
    string          reference_name
  );
    super.configure(
      parent, size, lsb_pos, access, volatile,
      reset, has_reset, sequence_index, reference_name
    );
    register_cb();
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

`ifdef RGGEN_ENABLE_ENHANCED_RAL
  protected function void post_predict(
    input uvm_reg_data_t  current_value,
    inout uvm_reg_data_t  rw_value,
    input uvm_predict_e   kind,
    input rggen_door      path,
    input uvm_reg_map     map
  );
    rw_value  = '0;
  endfunction

  local function void register_cb();
  endfunction
`else
  local function void register_cb();
    if (cb == null) begin
      cb  = new();
    end
    uvm_reg_field_cb::add(this, cb);
  endfunction
`endif
endclass

typedef rggen_ral_w0trg_w1trg_field rggen_ral_w0trg_field;
typedef rggen_ral_w0trg_w1trg_field rggen_ral_w1trg_field;
