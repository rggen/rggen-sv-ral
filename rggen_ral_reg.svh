class rggen_ral_reg extends rggen_ral_reg_base;
  protected int             array_index[$];
  protected int             array_size[$];
  protected rggen_backdoor  backdoor;

  function new(string name, int unsigned n_bits, int has_coverage);
    super.new(name, n_bits, has_coverage);
  endfunction

  function void configure(
    uvm_reg_block parent,
    int           array_index[$],
    int           array_size[$],
    string        hdl_path
  );
    super.configure(parent, null, hdl_path);
    this.array_index  = array_index;
    this.array_size   = array_size;
  endfunction

  function void build();
  endfunction

  virtual task do_read(uvm_reg_item rw);
    rggen_ral_reg_item  reg_item;

    if ($cast(reg_item, rw)) begin
      reg_item.caller = "do_read";
    end

    super.do_read(rw);
  endtask

  virtual task do_write(uvm_reg_item rw);
    rggen_ral_reg_item  reg_item;

    if ($cast(reg_item, rw)) begin
      reg_item.caller = "do_write";
    end

    super.do_write(rw);
  endtask

  virtual task peek(
    output  uvm_status_e      status,
    output  uvm_reg_data_t    value,
    input   string            kind      = "",
    input   uvm_sequence_base parent    = null,
    input   uvm_object        extension = null,
    input   string            fname     = "",
    input   int               lineno    = 0
  );
    void'(get(fname, lineno));
    lookup_backdoor();
    if (backdoor != null) begin
      rggen_ral_reg_item  rw;

      if (!Xis_locked_by_fieldX()) begin
        XatomicX(1);
      end

      rw              = rggen_ral_reg_item::type_id::create("peek_item",, get_full_name());
      rw.element      = this;
      rw.element_kind = UVM_REG;
      rw.path         = UVM_BACKDOOR;
      rw.kind         = UVM_READ;
      rw.bd_kind      = kind;
      rw.parent       = parent;
      rw.extension    = extension;
      rw.fname        = fname;
      rw.lineno       = lineno;
      rw.caller       = "peek";

      void'(backdoor_read_func(rw));
      do_predict(rw, UVM_PREDICT_READ);

      status  = rw.status;
      value   = rw.value[0];
      `uvm_info(
        "RegModel",
        $sformatf(
          "Peeked register \"%s\": 'h%h",
          get_full_name(), rw.value[0]
        ),
        UVM_HIGH
      )

      if (!Xis_locked_by_fieldX()) begin
        XatomicX(0);
      end
    end
    else begin
      super.peek(status, value, kind, parent, extension, fname, lineno);
    end
  endtask

  virtual task poke(
    output  uvm_status_e      status,
    input   uvm_reg_data_t    value,
    input   string            kind      = "",
    input   uvm_sequence_base parent    = null,
    input   uvm_object        extension = null,
    input   string            fname     = "",
    input   int               lineno    = 0
  );
    void'(get(fname, lineno));
    lookup_backdoor();
    if (backdoor != null) begin
      rggen_ral_reg_item  rw;

      if (!Xis_locked_by_fieldX()) begin
        XatomicX(1);
      end

      rw              = rggen_ral_reg_item::type_id::create("poke_item",, get_full_name());
      rw.element      = this;
      rw.element_kind = UVM_REG;
      rw.path         = UVM_BACKDOOR;
      rw.kind         = UVM_WRITE;
      rw.bd_kind      = kind;
      rw.value[0]     = value & ((1 << get_n_bits()) - 1);
      rw.parent       = parent;
      rw.extension    = extension;
      rw.fname        = fname;
      rw.lineno       = lineno;
      rw.caller       = "poke";
      backdoor_write(rw);

      do_predict(rw, UVM_PREDICT_WRITE);

      status  = rw.status;
      `uvm_info(
        "RegModel",
        $sformatf(
          "Poked register \"%s\": 'h%h",
          get_full_name(), rw.value[0]
        ),
        UVM_HIGH
      )

      if (!Xis_locked_by_fieldX()) begin
        XatomicX(0);
      end
    end
    else begin
      super.poke(status, value, kind, parent, extension, fname, lineno);
    end
  endtask

  virtual function void do_predict(
    uvm_reg_item      rw,
    uvm_predict_e     kind  = UVM_PREDICT_DIRECT,
    uvm_reg_byte_en_t be    = -1
  );
    rggen_ral_reg_item  reg_item;
    if ($cast(reg_item, rw) && (reg_item.caller == "do_read") && (reg_item.path == UVM_BACKDOOR) && (kind == UVM_PREDICT_READ)) begin
      reg_item.path = UVM_PREDICT;
      super.do_predict(reg_item, kind, be);
      reg_item.path = UVM_BACKDOOR;
    end
    else begin
      super.do_predict(rw, kind, be);
    end
  endfunction

  virtual task backdoor_write(uvm_reg_item rw);
    if (rw.kind != UVM_WRITE) begin
      return;
    end

    lookup_backdoor();
    if (backdoor != null) begin
      backdoor.write(rw);
    end
    else begin
      super.backdoor_write(rw);
    end
  endtask

  virtual task backdoor_read(uvm_reg_item rw);
    if (rw.kind != UVM_READ) begin
      return;
    end

    lookup_backdoor();
    if (backdoor != null) begin
      backdoor.read(rw);
    end
    else begin
      super.backdoor_read(rw);
    end
  endtask

  virtual function uvm_status_e backdoor_read_func(uvm_reg_item rw);
    if (rw.kind != UVM_READ) begin
      return UVM_NOT_OK;
    end

    lookup_backdoor();
    if (backdoor != null) begin
      backdoor.read_func(rw);
      return UVM_IS_OK;
    end
    else begin
      return super.backdoor_read_func(rw);
    end
  endfunction

  virtual task backdoor_watch();
    lookup_backdoor();
    if (backdoor != null) begin
      backdoor.wait_for_change(this);
    end
    else begin
      super.backdoor_watch();
    end
  endtask

`ifndef RGGEN_ENABLE_ENHANCED_RAL
  virtual function uvm_reg_frontdoor create_frontdoor();
    return null;
  endfunction
`endif

  virtual function uvm_reg_block get_parent_block();
    rggen_ral_reg_file  file;
    rggen_ral_block     block;

    if ($cast(file, get_parent())) begin
      return file.get_parent_block();
    end
    else if ($cast(block, get_parent())) begin
      return block;
    end
    else begin
      return null;
    end
  endfunction

  virtual function void get_array_index(ref int array_index[$]);
    foreach (this.array_index[i]) begin
      array_index.push_back(this.array_index[i]);
    end
  endfunction

  virtual function void get_array_info(
    ref   int         array_index[$],
    ref   int         array_size[$],
    input uvm_hier_e  hier  = UVM_HIER
  );
    if (hier == UVM_HIER) begin
      rggen_ral_reg_file  rf;
      if ($cast(rf, get_parent())) begin
        rf.get_array_info(array_index, array_size, hier);
      end
    end

    foreach (this.array_index[i]) begin
      array_index.push_back(this.array_index[i]);
      array_size.push_back(this.array_size[i]);
    end
  endfunction

  protected function void lookup_backdoor();
    if (backdoor == null) begin
      backdoor  = rggen_ral_backdoor_pkg::get_backdoor(this);
      if (backdoor != null) begin
        set_backdoor(backdoor);
      end
      else begin
        `uvm_warning("BACKDOOR", "backdoor access is not enabled")
      end
    end
  endfunction
endclass
