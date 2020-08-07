`ifndef RGGEN_RAL_BACKDOOR_PKG_SV
`define RGGEN_RAL_BACKDOOR_PKG_SV
package rggen_ral_backdoor_pkg;
  import  uvm_pkg::*;

`ifdef RGGEN_ENABLE_BACKDOOR
  typedef rggen_backdoor_pkg::rggen_backdoor_vif  rggen_backdoor_vif;

  class rggen_backdoor extends uvm_reg_backdoor;
    protected rggen_backdoor_vif  vif_cache[uvm_reg];

    function new(string name);
      super.new(name);
    endfunction

    function bit is_auto_updated(uvm_reg_field field);
      return 1;
    endfunction

    task wait_for_change(uvm_object element);
      rggen_backdoor_vif  vif;
      vif = get_vif(element);
      vif.wait_for_change();
    endtask

    task write(uvm_reg_item rw);
      int unsigned        width;
      int unsigned        lsb;
      uvm_reg_data_t      mask;
      uvm_reg_data_t      data;
      rggen_backdoor_vif  vif;

      get_location_info(rw, width, lsb);
      mask  = ((1 << width) - 1) << lsb;
      data  = rw.value[0] << lsb;

      vif = get_vif(rw.element);
      vif.backdoor_write(mask, data);
    endtask

    function void read_func(uvm_reg_item rw);
      int unsigned        width;
      int unsigned        lsb;
      uvm_reg_data_t      mask;
      uvm_reg_data_t      data;
      rggen_backdoor_vif  vif;

      get_location_info(rw, width, lsb);
      mask  = ((1 << width) - 1);

      vif   = get_vif(rw.element);
      data  = vif.get_read_data();
      rw.value[0] = (data >> lsb) & mask;
    endfunction

    protected function rggen_backdoor_vif get_vif(uvm_object element);
      uvm_reg       rg;
      uvm_reg_field field;

      if ($cast(field, element)) begin
        rg  = field.get_parent();
      end
      else if (!$cast(rg, element)) begin
        `uvm_fatal(
          "RegModel",
          $sformatf(
            "Casting failed, '%s' is neither uvm_reg nor uvm_reg_field",
            element.get_full_name()
          )
        )
      end

      if (!vif_cache.exists(rg)) begin
        vif_cache[rg] = get_backdoor_vif(rg);
      end

      return vif_cache[rg];
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

    protected static  rggen_backdoor  backdoor;

    static function uvm_reg_backdoor get();
      if (backdoor == null) begin
        backdoor  = new("backdoor");
      end
      return backdoor;
    endfunction
  endclass

  function automatic rggen_backdoor_vif get_backdoor_vif(uvm_reg rg);
    uvm_hdl_path_concat hdl_path[$];
    rg.get_full_hdl_path(hdl_path);
    return rggen_backdoor_pkg::get_backdoor_vif(hdl_path[0].slices[0].path);
  endfunction

  function automatic bit is_backdoor_enabled();
    return 1;
  endfunction

  function automatic uvm_reg_backdoor get_backdoor();
    return rggen_backdoor::get();
  endfunction
`else
  typedef uvm_object  rggen_backdoor_vif; //  dummy

  function automatic rggen_backdoor_vif get_backdoor_vif(uvm_reg rg);
    return null;
  endfunction

  function automatic bit is_backdoor_enabled();
    return 0;
  endfunction

  function automatic uvm_reg_backdoor get_backdoor();
    return null;
  endfunction
`endif
endpackage
`endif
