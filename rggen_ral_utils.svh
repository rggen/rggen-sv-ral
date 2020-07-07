class rggen_ral_name_slice;
  local string  name;
  local string  array_name;
  local int     array_index[$];

  function new(string name);
    this.name = name;
  endfunction

  function string get_name();
    return name;
  endfunction

  function void set_array_index(const ref int array_index[$]);
    foreach (array_index[i]) begin
      this.array_index.push_back(array_index[i]);
    end
  endfunction

  function bit match_name(uvm_object element);
    if (array_name.len() == 0) begin
      array_name  = name;
      foreach (array_index[i]) begin
        array_name  = $sformatf("%s[%0d]", array_name, array_index[i]);
      end
    end

    return element.get_name() inside {name, array_name};
  endfunction
endclass

function automatic void rggen_ral_get_name_slices(
  input string                name,
  ref   rggen_ral_name_slice  name_slices[$]
);
  string                splitted_names[$];
  rggen_ral_name_slice  name_slice;
  uvm_split_string(name, ".", splitted_names);
  foreach (splitted_names[i]) begin
    name_slice  = new(splitted_names[i]);
    name_slices.push_back(name_slice);
  end
endfunction

function automatic uvm_object rggen_ral_find_element_by_name(
  uvm_object            from,
  rggen_ral_name_slice  name_slice
);
  rggen_ral_block block;
  rggen_ral_reg   rg;

  if ($cast(block, from)) begin
    rggen_ral_reg_file  files[$];
    uvm_reg             regs[$];

    block.get_register_files(files, UVM_NO_HIER);
    foreach (files[i]) begin
      if (name_slice.match_name(files[i])) begin
        return files[i];
      end
    end

    block.get_registers(regs, UVM_NO_HIER);
    foreach (regs[i]) begin
      if (name_slice.match_name(regs[i])) begin
        return regs[i];
      end
    end
  end
  else if ($cast(rg, from)) begin
    uvm_reg_field fields[$];

    rg.get_fields(fields);
    foreach (fields[i]) begin
      if (name_slice.match_name(fields[i])) begin
        return fields[i];
      end
    end
  end

  return null;
endfunction

function automatic uvm_reg_field rggen_ral_find_field_by_name(
  input     uvm_reg_block         block,
  const ref rggen_ral_name_slice  name_slices[$]
);
  uvm_object    current_element;
  uvm_reg_field field;

  current_element = block;
  foreach (name_slices[i]) begin
    current_element =
      rggen_ral_find_element_by_name(current_element, name_slices[i]);
    if (current_element == null) begin
      break;
    end
  end

  if ((current_element != null) && $cast(field, current_element)) begin
    return field;
  end
  else begin
    string  field_name;

    foreach (name_slices[i]) begin
      if (i == 0) begin
        field_name  = name_slices[i].get_name();
      end
      else begin
        field_name  = {field_name, ".", name_slices[i].get_name()};
      end
    end

    if (current_element == null) begin
      `uvm_fatal(
        "RegModel",
        $sformatf(
          "Cannot find field '%s' from block '%s'",
          field_name, block.get_full_name()
        )
      )
    end
    else begin
      `uvm_fatal(
        "RegModel",
        $sformatf("Eelement '%s' is not field", field_name)
      )
    end

    return null;
  end
endfunction

function automatic void rggen_ral_get_ancestors(
  input uvm_object  self,
  ref   uvm_object  ancestors[$]
);
  rggen_ral_reg_file  file;
  rggen_ral_reg       rg;
  rggen_ral_field     field;
  ancestors.push_front(self);
  if ($cast(file, self)) begin
    rggen_ral_get_ancestors(file.get_parent(), ancestors);
  end
  else if ($cast(rg, self)) begin
    rggen_ral_get_ancestors(rg.get_parent(), ancestors);
  end
  else if ($cast(field, self)) begin
    rggen_ral_get_ancestors(field.get_parent(), ancestors);
  end
endfunction
