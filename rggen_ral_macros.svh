`ifndef RGGEN_RAL_MACROS_SVH
`define RGGEN_RAL_MACROS_SVH

`define rggen_ral_create_field(HANDLE, LSB, SIZE, ACCESS, VOLATILE, RESET, HAS_RESET, SEQUENCE_INDEX, REFERNCE_NAME) \
begin \
  HANDLE  = new(`"HANDLE`"); \
  HANDLE.configure(this, SIZE, LSB, ACCESS, VOLATILE, RESET, HAS_RESET, SEQUENCE_INDEX, REFERNCE_NAME); \
end

`define rggen_ral_create_reg(HANDLE, ARRAY_INDEX, OFFSET, RIGHTS, HDL_PATH) \
begin \
  HANDLE  = new(`"HANDLE`"); \
  HANDLE.configure(this, ARRAY_INDEX, HDL_PATH); \
  HANDLE.build(); \
  default_map.add_reg(HANDLE, OFFSET, RIGHTS, 0); \
end

`define rggen_ral_create_reg_file(HANDLE, ARRAY_INDEX, OFFSET, HDL_PATH) \
begin \
  HANDLE  = new(`"HANDLE`"); \
  HANDLE.configure(this, ARRAY_INDEX, HDL_PATH); \
  HANDLE.build(); \
  this.default_map.add_submap(HANDLE.default_map, OFFSET); \
end

`define rggen_ral_create_block(HANDLE, OFFSET, PARENT = this, CREATE = 1) \
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

`ifdef UVM_VERSION_1_0
  `define RGGEN_UVM_PRE_IEEE
`elsif UVM_VERSION_1_1
  `define RGGEN_UVM_PRE_IEEE
`elsif UVM_VERSION_1_2
  `define RGGEN_UVM_PRE_IEEE
`endif

`ifndef RGGEN_UVM_PRE_IEEE
  `ifndef UVM_VERSION_POST_2017
    `define RGGEN_UVM_PRE_2020
  `endif
`else
  `define RGGEN_UVM_PRE_2020
`endif

`endif
