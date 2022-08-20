`ifndef RGGEN_RAL_BACKDOOR_PKG_SV
`define RGGEN_RAL_BACKDOOR_PKG_SV
package rggen_ral_backdoor_pkg;
  import  uvm_pkg::*;
  `include  "uvm_macros.svh"

`ifdef RGGEN_ENABLE_BACKDOOR
  typedef rggen_backdoor_pkg::rggen_backdoor_vif  rggen_backdoor_vif;

  class rggen_backdoor extends uvm_reg_backdoor;
    protected rggen_backdoor_vif  vif;

    function new(string name, uvm_reg rg);
      super.new(name);
      this.vif  = get_backdoor_vif(rg);
    endfunction

    function bit is_auto_updated(uvm_reg_field field);
      return 1;
    endfunction

    task wait_for_change(uvm_object element);
      vif.wait_for_change();
    endtask

    task write(uvm_reg_item rw);
      int unsigned    width;
      int unsigned    lsb;
      uvm_reg_data_t  mask;
      uvm_reg_data_t  data;

      if (rw.kind != UVM_WRITE) begin
        return;
      end

      get_location_info(rw, width, lsb);
      mask  = ((1 << width) - 1) << lsb;
      data  = rw.value[0] << lsb;

      vif.backdoor_write(mask, data);
    endtask

    task read(uvm_reg_item rw);
      read_func(rw);
    endtask

    function void read_func(uvm_reg_item rw);
      int unsigned    width;
      int unsigned    lsb;
      uvm_reg_data_t  mask;
      uvm_reg_data_t  data;

      if (rw.kind != UVM_READ) begin
        return;
      end

      get_location_info(rw, width, lsb);
      mask  = ((1 << width) - 1);

      data  = vif.get_read_data();
      rw.value[0] = (data >> lsb) & mask;
    endfunction

    protected function rggen_backdoor_vif get_backdoor_vif(uvm_reg rg);
      uvm_hdl_path_concat hdl_path[$];
      string              path;
      rg.get_full_hdl_path(hdl_path);
      path  = {hdl_path[0].slices[0].path, ".u_register_common.u_backdoor"};
      return rggen_backdoor_pkg::get_backdoor_vif(path);
    endfunction

    protected function void get_location_info(
      input uvm_reg_item  rw,
      ref   int unsigned  width,
      ref   int unsigned  lsb
    );
      case (rw.element_kind)
        UVM_REG: begin
          uvm_reg element;
          $cast(element, rw.element);
          width = element.get_n_bits();
          lsb   = 0;
        end
        UVM_FIELD: begin
          uvm_reg_field element;
          $cast(element, rw.element);
          width = element.get_n_bits();
          lsb   = element.get_lsb_pos();
        end
      endcase
    endfunction
  endclass

  function automatic bit is_backdoor_enabled();
    return 1;
  endfunction

  function automatic rggen_backdoor get_backdoor(uvm_reg rg);
    rggen_backdoor  backdoor;
    backdoor  = new("backdoor", rg);
    return backdoor;
  endfunction
`else
  class rggen_backdoor extends uvm_reg_backdoor;
    task wait_for_change(uvm_object element);
    endtask
  endclass

  function automatic bit is_backdoor_enabled();
    return 0;
  endfunction

  function automatic rggen_backdoor get_backdoor();
    return null;
  endfunction
`endif
endpackage
`endif
