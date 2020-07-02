class rggen_ral_rwe_rwl_field_callbacks extends uvm_reg_cbs;
  local rggen_ral_field field;
  local bit             enable_mode;

  function new(string name, rggen_ral_field field, bit enable_mode);
    super.new(name);
    this.field        = field;
    this.enable_mode  = enable_mode;
  endfunction

  function void post_predict(
    input uvm_reg_field   fld,
    input uvm_reg_data_t  previous,
    inout uvm_reg_data_t  value,
    input uvm_predict_e   kind,
    input uvm_door_e      path,
    input uvm_reg_map     map
  );
    if ((kind == UVM_PREDICT_WRITE) && !is_writable()) begin
      value = previous;
    end
  endfunction

  local function bit is_writable();
    uvm_reg_field mode_field  = field.get_reference_field();
    if (mode_field != null) begin
      return mode_field.value[0] == enable_mode;
    end
    else begin
      return 0;
    end
  endfunction
endclass

class rggen_ral_rwe_rwl_field #(
  bit ENABLE_MODE = 1
) extends rggen_ral_field;
  local static  bit rwl_defined = define_access("RWL");

  protected rggen_ral_rwe_rwl_field_callbacks callbacks;

  function new(string name);
    super.new(name);
    callbacks = new("callbacks", this, ENABLE_MODE);
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
    int unsigned    sequence_index,
    string          reference_name
  );
    super.configure(
      parent, size, lsb_pos, access, volatile,
      reset, has_reset, is_rand, sequence_index, reference_name
    );
    uvm_reg_field_cb::add(this, callbacks);
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
      "RW":     return access;
      "WO":     return access;
      "RO":     return "RO";
      default:  return super.get_access(map);
    endcase
  endfunction

  function bit is_known_access(uvm_reg_map map = null);
    case (get_access(map))
      "RWE":    return 1;
      "RWL":    return 1;
      "RO":     return 1;
      default:  return 0;
    endcase
  endfunction
endclass

typedef rggen_ral_rwe_rwl_field #(1)  rggen_ral_rwe_field;
typedef rggen_ral_rwe_rwl_field #(0)  rggen_ral_rwl_field;
