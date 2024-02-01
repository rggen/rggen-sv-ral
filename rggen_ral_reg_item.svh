class rggen_ral_reg_item extends rggen_ral_reg_item_base;
  string  caller;

  function new(string name = "rggen_ral_reg_item");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    rggen_ral_reg_item  _rhs;
    super.do_copy(rhs);
    if ((rhs != null) && $cast(_rhs, rhs)) begin
      caller  = _rhs.caller;
    end
  endfunction

  `uvm_object_utils(rggen_ral_reg_item)
endclass

function bit override_reg_item();
  uvm_reg_item::type_id::set_type_override(rggen_ral_reg_item::type_id::get());
  return 1;
endfunction

const bit reg_item_overridden = override_reg_item();
