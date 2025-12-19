class rggen_ral_maskable_reg extends rggen_ral_reg;
  function new(string name, int unsigned n_bits, int has_coverage);
    super.new(name, n_bits, has_coverage);
  endfunction

  function void configure(
    uvm_reg_block parent,
    int           array_index[$],
    int           array_size[$],
    string        hdl_path
  );
    super.configure(parent, array_index, array_size, hdl_path);
  endfunction

  virtual task update(
    output  uvm_status_e      status,
    input   rggen_door        path      = RGGEN_DEFAULT_DOOR,
    input   uvm_reg_map       map       = null,
    input   uvm_sequence_base parent    = null,
    input   int               prior     = -1,
    input   uvm_object        extension = null,
    input   string            fname     = "",
    input   int               lineno    = 0
  );
    uvm_reg_data_t  value;
    uvm_reg_data_t  mask;
    uvm_reg_field   fields[$];

    if (!needs_update()) begin
      status  = UVM_IS_OK;
      return;
    end

    get_fields(fields);

    value = '0;
    mask  = '0;
    foreach (fields[i]) begin
      if (fields[i].needs_update()) begin
        int unsigned  lsb     = fields[i].get_lsb_pos();
        int unsigned  n_bits  = fields[i].get_n_bits();
        value |= fields[i].XupdateX() << lsb;
        mask  |= ((1 << n_bits) - 1) << lsb;
      end
    end

    maskable_write(status, value, mask, path, map, parent, prior, extension, fname, lineno);
  endtask

  virtual task write(
    output  uvm_status_e      status,
    input   uvm_reg_data_t    value,
    input   rggen_door        path      = RGGEN_DEFAULT_DOOR,
    input   uvm_reg_map       map       = null,
    input   uvm_sequence_base parent    = null,
    input   int               prior     = -1,
    input   uvm_object        extension = null,
    input   string            fname     = "",
    input   int               lineno    = 0
  );
    uvm_reg_data_t  mask = (1 << get_n_bits()) - 1;
    maskable_write(status, value, mask, path, map, parent, prior, extension, fname, lineno);
  endtask

  virtual task maskable_write(
    output  uvm_status_e      status,
    input   uvm_reg_data_t    value,
    input   uvm_reg_data_t    mask,
    input   rggen_door        path      = RGGEN_DEFAULT_DOOR,
    input   uvm_reg_map       map       = null,
    input   uvm_sequence_base parent    = null,
    input   int               prior     = -1,
    input   uvm_object        extension = null,
    input   string            fname     = "",
    input   int               lineno    = 0
  );
    uvm_reg_data_t  value_with_mask;
    value_with_mask = bind_mask(value, mask, map);
    super.write(status, value_with_mask, path, map, parent, prior, extension, fname, lineno);
  endtask

  function void do_predict(
    uvm_reg_item      rw,
    uvm_predict_e     kind  = UVM_PREDICT_DIRECT,
    uvm_reg_byte_en_t be    = -1
  );
    if ((rw.path != UVM_BACKDOOR) && (kind == UVM_PREDICT_WRITE)) begin
      uvm_reg_data_t  value;
      value       = rw.value[0];
      rw.value[0] = apply_mask(rw.value[0], be, rw.map);
      super.do_predict(rw, kind, be);
      rw.value[0] = value;
    end
    else begin
      super.do_predict(rw, kind, be);
    end
  endfunction

  function uvm_reg_data_t bind_mask(uvm_reg_data_t value, uvm_reg_data_t mask, uvm_reg_map map);
    int unsigned    bus_width;
    int unsigned    bus_width_half;
    int             n_bits;
    uvm_reg_data_t  data;

    bus_width = get_bus_width(map);
    if (bus_width == 0) begin
      return value;
    end

    bus_width_half  = bus_width / 2;
    n_bits          = get_n_bits();
    data            = value;
    for (int i = 0;i < n_bits;++i) begin
      if ((i % bus_width) < bus_width_half) begin
        data[i+bus_width_half]  = mask[i];
      end
    end

    return data;
  endfunction

  function uvm_reg_data_t apply_mask(uvm_reg_data_t value, uvm_reg_byte_en_t be, uvm_reg_map map);
    int unsigned    bus_width;
    int unsigned    bus_width_half;
    int unsigned    n_bits;
    uvm_reg_data_t  masked_value;

    bus_width = get_bus_width(map);
    if (bus_width == 0) begin
      return value;
    end

    bus_width_half  = bus_width / 2;
    n_bits          = get_n_bits();
    masked_value    = '0;
    for (int i = 0;i < n_bits;++i) begin
      if ((i % bus_width) < bus_width_half) begin
        int byte_pos  = i / 8;
        int mask_pos  = i + bus_width_half;
        if (be[byte_pos] && value[mask_pos]) begin
          masked_value[i] = value[i];
        end
      end
    end

    return masked_value;
  endfunction

  function int unsigned get_bus_width(uvm_reg_map map);
    if (map == null) begin
      uvm_reg_block parent_block;
      uvm_reg_map   default_map;
      parent_block  = get_parent_block();
      map           = parent_block.get_default_map();
    end

    if (map == null) begin
      // Can't get bus width
      return 0;
    end

    return map.get_n_bytes() * 8;
  endfunction
endclass
