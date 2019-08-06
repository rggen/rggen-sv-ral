class rggen_ral_field extends uvm_reg_field;
  function new(string name = "rggen_ral_field");
    super.new(name);
  endfunction

  virtual function bit is_known_access(uvm_reg_map map = null);
    if (super.is_known_access(map)) begin
      return 1;
    end
    else begin
      string  access  = get_access(map);
      case (access)
        "RWE":    return 1;
        "RWL":    return 1;
        default:  return 0;
      endcase
    end
  endfunction
endclass
