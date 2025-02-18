class rggen_ral_field extends rggen_ral_field_base;
  protected int           sequence_index;
  protected int           sequence_size;
  protected string        reference_name;
  protected uvm_reg_field reference_field;

  function new(string name);
    super.new(name);
  endfunction

  function void configure(
    uvm_reg         parent,
    int unsigned    size,
    int unsigned    lsb_pos,
    string          access,
    bit             volatile,
    uvm_reg_data_t  reset_value,
    uvm_reg_data_t  reset_values[$],
    bit             has_reset,
    int             sequence_index,
    int             sequence_size,
    string          reference_name
  );
    uvm_reg_data_t  reset;

    this.sequence_index = sequence_index;
    this.sequence_size  = sequence_size;
    this.reference_name = reference_name;

    if (reset_values.size() > 0) begin
      int bit_field_index;
      bit_field_index = calc_reset_value_index(parent);
      reset = reset_values[bit_field_index];
    end
    else begin
      reset = reset_value;
    end

    super.configure(
      parent, size, lsb_pos, access, volatile,
      reset, has_reset, 1, 0
    );
  endfunction

  virtual function uvm_reg_block get_parent_block();
    rggen_ral_reg rg;
    if ($cast(rg, get_parent())) begin
      return rg.get_parent_block();
    end
    else begin
      return null;
    end
  endfunction

  function uvm_reg_field get_reference_field();
    if ((reference_name.len() > 0) && (reference_field == null)) begin
      lookup_reference_field();
    end
    return reference_field;
  endfunction

  protected function int calc_reset_value_index(uvm_reg parent);
    rggen_ral_reg rg;
    int           array_index[$];
    int           array_size[$];
    int           index;
    int           size;

    if ($cast(rg, parent)) begin
      rg.get_array_info(array_index, array_size, UVM_HIER);
    end

    if (sequence_size > 0) begin
      array_index.push_back(sequence_index);
      array_size.push_back(sequence_size);
    end

    index = 0;
    size  = 1;
    for (int i = (array_index.size() - 1);i >= 0;--i) begin
      index += size * array_index[i];
      size  *= array_size[i];
    end

    return index;
  endfunction

  protected function void lookup_reference_field();
    rggen_ral_name_slice  name_slices[$];
    uvm_object            ancestors[$];

    rggen_ral_get_name_slices(reference_name, name_slices);
    rggen_ral_get_ancestors(this, ancestors);
    void'(ancestors.pop_front()); //  Remove block layer

    if (name_slices.size() == ancestors.size()) begin
      foreach (name_slices[i]) begin
        set_array_index(name_slices[i], ancestors[i]);
      end
    end

    reference_field =
      rggen_ral_find_field_by_name(get_parent_block(), name_slices);
  endfunction

  protected function void set_array_index(
    rggen_ral_name_slice  name_slice,
    uvm_object            element
  );
    rggen_ral_reg_file  file;
    rggen_ral_reg       rg;
    rggen_ral_field     field;
    int                 array_index[$];

    if ($cast(file, element)) begin
      file.get_array_index(array_index);
    end
    else if ($cast(rg, element)) begin
      rg.get_array_index(array_index);
    end
    else if ($cast(field, element) && (field.sequence_index >= 0)) begin
      array_index.push_back(field.sequence_index);
    end

    name_slice.set_array_index(array_index);
  endfunction

`ifdef RGGEN_ENABLE_ENHANCED_RAL
  protected function bit m_need_prediction(uvm_reg_item rw, uvm_predict_e kind);
    if (kind == UVM_PREDICT_READ) begin
      return super.m_need_prediction(rw, kind);
    end
    else begin
      return 1;
    end
  endfunction
`endif
endclass
