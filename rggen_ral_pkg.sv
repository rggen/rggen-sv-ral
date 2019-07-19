`ifndef RGGEN_RAL_PKG_SV
`define RGGEN_RAL_PKG_SV
package rggen_ral_pkg;
  import  uvm_pkg::*;
  `include  "uvm_macros.svh"

  `include  "rggen_ral_macros.svh"
  `include  "rggen_ral_field.svh"
  `include  "rggen_ral_rwe_rwl_field.svh"
  `include  "rggen_ral_reg.svh"
  `include  "rggen_ral_indirect_reg.svh"
  `include  "rggen_ral_block.svh"
endpackage
`endif
