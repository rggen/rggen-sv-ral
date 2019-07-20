`ifndef RGGEN_RAL_MACROS_SVH
`define RGGEN_RAL_MACROS_SVH

`define rggen_ral_create_field_model(HANDLE, LSB, SIZE, ACCESS, VOLATILE, RESET, HAS_RESET) \
begin \
  HANDLE  = new(`"HANDLE`"); \
  HANDLE.configure(this, SIZE, LSB, `"ACCESS`", VOLATILE, RESET, HAS_RESET, 1, 0); \
end

`define rggen_ral_create_reg_model(HANDLE, ARRAY_INDEX, OFFSET, RIGHTS, UNMAPPED, HDL_PATH) \
begin \
  HANDLE  = new(`"HANDLE`"); \
  HANDLE.configure(this, null, ARRAY_INDEX, `"HDL_PATH`"); \
  HANDLE.build(); \
  default_map.add_reg(HANDLE, OFFSET, `"RIGHTS`", UNMAPPED); \
end

`define rggen_ral_create_block_model(HANDLE, OFFSET, PARENT = this, CREATE = 1) \
if (CREATE) begin \
  uvm_reg_block __parent; \
  void'($cast(__parent, PARENT)); \
  HANDLE  = new(`"HANDLE`"); \
  HANDLE.configure(__parent); \
  HANDLE.build(); \
  if (__parent != null) begin \
    __parent.default_map.add_submap(HANDLE.default_map, OFFSET); \
  end \
end

`endif
