`ifndef RGGEN_RAL_MACROS_SVH
`define RGGEN_RAL_MACROS_SVH

`define rggen_ral_create_field_model(handle, lsb, size, access, volatile, reset, has_reset) \
begin \
  handle  = new(`"handle`"); \
  handle.configure(this, size, lsb, `"access`", volatile, reset, has_reset, 1, 0); \
end

`define rggen_ral_create_reg_model(handle, array_index, offset, rights, unmapped, hdl_path) \
begin \
  handle  = new(`"handle`"); \
  handle.configure(this, null, array_index, `"hdl_path`"); \
  handle.build(); \
  default_map.add_reg(handle, offset, `"rights`", unmapped); \
end

`define rggen_ral_create_block_model(handle, offset) \
begin \
  handle  = new(`"handle`"); \
  handle.configure(this); \
  handle.build(); \
  default_map.add_submap(handle.default_map, offset); \
end

`endif