`ifndef RGGEN_RAL_PKG_SV
`define RGGEN_RAL_PKG_SV
package rggen_ral_pkg;
  import  uvm_pkg::*;

  `include  "uvm_macros.svh"
  `include  "rggen_ral_macros.svh"

  `ifdef RGGEN_UVM_PRE_IEEE
    typedef uvm_path_e  uvm_door_e;
  `endif

  `ifdef RGGEN_ENABLE_ENHANCED_RAL
    typedef tue_pkg::tue_reg_field  rggen_ral_field_base;
    typedef tue_pkg::tue_reg        rggen_ral_reg_base;
    typedef tue_pkg::tue_reg_block  rggen_ral_block_base;
    typedef tue_pkg::tue_reg_map    rggen_ral_map_base;
  `else
    typedef uvm_pkg::uvm_reg_field  rggen_ral_field_base;
    typedef uvm_pkg::uvm_reg        rggen_ral_reg_base;
    typedef uvm_pkg::uvm_reg_block  rggen_ral_block_base;
    typedef uvm_pkg::uvm_reg_map    rggen_ral_map_base;
  `endif

  typedef class rggen_ral_field;
  typedef class rggen_ral_reg;
  typedef class rggen_ral_reg_file;
  typedef class rggen_ral_block;
  typedef class rggen_ral_map;

  `include  "rggen_ral_utils.svh"
  `include  "rggen_ral_field.svh"
  `include  "rggen_ral_rwe_rwl_field.svh"
  `include  "rggen_ral_w0trg_w1trg_field.svh"
  `include  "rggen_ral_reg.svh"
  `include  "rggen_ral_reg_file.svh"
  `include  "rggen_ral_indirect_reg.svh"
  `include  "rggen_ral_block.svh"
  `include  "rggen_ral_map.svh"
endpackage
`endif
