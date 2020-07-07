class rggen_ral_rwe_rwl_field_callbacks #(
  bit ENABLE_MODE = 1
) extends uvm_reg_cbs;
  function new(string name = "rggen_ral_rwe_rwl_field_callbacks");
    super.new(name);
  endfunction

  function void post_predict(
    input uvm_reg_field   fld,
    input uvm_reg_data_t  previous,
    inout uvm_reg_data_t  value,
    input uvm_predict_e   kind,
    input uvm_door_e      path,
    input uvm_reg_map     map
  );
    if ((kind == UVM_PREDICT_WRITE) && (!is_writable(fld))) begin
      value = previous;
    end
  endfunction

  local function bit is_writable(uvm_reg_field field);
    uvm_reg_field mode_field  = get_mode_field(field);
    if (mode_field != null) begin
      return mode_field.value[0] == ENABLE_MODE;
    end
    else begin
      return 0;
    end
  endfunction

  local function uvm_reg_field get_mode_field(uvm_reg_field field);
    rggen_ral_field temp;
    void'($cast(temp, field));
    return temp.get_reference_field();
  endfunction
endclass

class rggen_ral_rwe_rwl_field #(
  string  TYPE_NAME = "",
  type    CALLBACKS = uvm_reg_cbs
) extends rggen_ral_field;
  local static  bit       defined = define_access(TYPE_NAME);
  local static  CALLBACKS cb;

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

  local function void register_cb();
    if (cb == null) begin
      cb  = new();
    end
    uvm_reg_field_cb::add(this, cb);
  endfunction
endclass

typedef rggen_ral_rwe_rwl_field_callbacks #(1)  rggen_ral_rwe_field_callbacks;
typedef rggen_ral_rwe_rwl_field_callbacks #(0)  rggen_ral_rwl_field_callbacks;

typedef rggen_ral_rwe_rwl_field #(
  .TYPE_NAME  ("RWE"                          ),
  .CALLBACKS  (rggen_ral_rwe_field_callbacks  )
) rggen_ral_rwe_field;

typedef rggen_ral_rwe_rwl_field #(
  .TYPE_NAME  ("RWL"                          ),
  .CALLBACKS  (rggen_ral_rwl_field_callbacks  )
) rggen_ral_rwl_field;
