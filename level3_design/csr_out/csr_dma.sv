`ifndef rggen_connect_bit_field_if
  `define rggen_connect_bit_field_if(RIF, FIF, LSB, WIDTH) \
  assign  FIF.valid                 = RIF.valid; \
  assign  FIF.read_mask             = RIF.read_mask[LSB+:WIDTH]; \
  assign  FIF.write_mask            = RIF.write_mask[LSB+:WIDTH]; \
  assign  FIF.write_data            = RIF.write_data[LSB+:WIDTH]; \
  assign  RIF.read_data[LSB+:WIDTH] = FIF.read_data; \
  assign  RIF.value[LSB+:WIDTH]     = FIF.value;
`endif
`ifndef rggen_tie_off_unused_signals
  `define rggen_tie_off_unused_signals(WIDTH, VALID_BITS, RIF) \
  if (1) begin : __g_tie_off \
    genvar  __i; \
    for (__i = 0;__i < WIDTH;++__i) begin : g \
      if (!(((VALID_BITS) >> __i) & 1'b1)) begin : g \
        assign  RIF.read_data[__i]  = 1'b0; \
        assign  RIF.value[__i]      = 1'b0; \
      end \
    end \
  end
`endif
module csr_dma
  import rggen_rtl_pkg::*;
#(
  parameter int ADDRESS_WIDTH = 8,
  parameter bit PRE_DECODE = 0,
  parameter bit [ADDRESS_WIDTH-1:0] BASE_ADDRESS = '0,
  parameter bit ERROR_STATUS = 0,
  parameter bit [63:0] DEFAULT_READ_DATA = '0,
  parameter int ID_WIDTH = 0,
  parameter bit WRITE_FIRST = 1
)(
  input logic i_clk,
  input logic i_rst_n,
  rggen_axi4lite_if.slave axi4lite_if,
  output logic o_dma_control_go,
  output logic o_dma_control_abort,
  output logic [7:0] o_dma_control_max_burst,
  input logic i_dma_status_done,
  input logic [31:0] i_dma_error_addr_error_addr,
  input logic i_dma_error_stats_error_type,
  input logic i_dma_error_stats_error_src,
  input logic i_dma_error_stats_error_trig,
  output logic [4:0][31:0] o_dma_desc_src_addr_src_addr,
  output logic [4:0][31:0] o_dma_desc_dst_addr_dst_addr,
  output logic [4:0][31:0] o_dma_desc_num_bytes_num_bytes,
  output logic [4:0] o_dma_desc_cfg_write_mode,
  output logic [4:0] o_dma_desc_cfg_read_mode,
  output logic [4:0] o_dma_desc_cfg_enable
);
  rggen_register_if #(8, 64, 64) register_if[24]();
  rggen_axi4lite_adapter #(
    .ID_WIDTH             (ID_WIDTH),
    .ADDRESS_WIDTH        (ADDRESS_WIDTH),
    .LOCAL_ADDRESS_WIDTH  (8),
    .BUS_WIDTH            (64),
    .REGISTERS            (24),
    .PRE_DECODE           (PRE_DECODE),
    .BASE_ADDRESS         (BASE_ADDRESS),
    .BYTE_SIZE            (256),
    .ERROR_STATUS         (ERROR_STATUS),
    .DEFAULT_READ_DATA    (DEFAULT_READ_DATA),
    .WRITE_FIRST          (WRITE_FIRST)
  ) u_adapter (
    .i_clk        (i_clk),
    .i_rst_n      (i_rst_n),
    .axi4lite_if  (axi4lite_if),
    .register_if  (register_if)
  );
  generate if (1) begin : g_dma_control
    rggen_bit_field_if #(64) bit_field_if();
    `rggen_tie_off_unused_signals(64, 64'h00000000000003ff, bit_field_if)
    rggen_default_register #(
      .READABLE       (1),
      .WRITABLE       (1),
      .ADDRESS_WIDTH  (8),
      .OFFSET_ADDRESS (8'h00),
      .BUS_WIDTH      (64),
      .DATA_WIDTH     (64),
      .REGISTER_INDEX (0)
    ) u_register (
      .i_clk        (i_clk),
      .i_rst_n      (i_rst_n),
      .register_if  (register_if[0]),
      .bit_field_if (bit_field_if)
    );
    if (1) begin : g_go
      localparam bit INITIAL_VALUE = 1'h0;
      rggen_bit_field_if #(1) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 1)
      rggen_bit_field #(
        .WIDTH          (1),
        .INITIAL_VALUE  (INITIAL_VALUE),
        .SW_WRITE_ONCE  (0),
        .TRIGGER        (0)
      ) u_bit_field (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('1),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            ('0),
        .i_mask             ('1),
        .o_value            (o_dma_control_go),
        .o_value_unmasked   ()
      );
    end
    if (1) begin : g_abort
      localparam bit INITIAL_VALUE = 1'h0;
      rggen_bit_field_if #(1) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 1, 1)
      rggen_bit_field #(
        .WIDTH          (1),
        .INITIAL_VALUE  (INITIAL_VALUE),
        .SW_WRITE_ONCE  (0),
        .TRIGGER        (0)
      ) u_bit_field (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('1),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            ('0),
        .i_mask             ('1),
        .o_value            (o_dma_control_abort),
        .o_value_unmasked   ()
      );
    end
    if (1) begin : g_max_burst
      localparam bit [7:0] INITIAL_VALUE = 8'hff;
      rggen_bit_field_if #(8) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 2, 8)
      rggen_bit_field #(
        .WIDTH          (8),
        .INITIAL_VALUE  (INITIAL_VALUE),
        .SW_WRITE_ONCE  (0),
        .TRIGGER        (0)
      ) u_bit_field (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('1),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            ('0),
        .i_mask             ('1),
        .o_value            (o_dma_control_max_burst),
        .o_value_unmasked   ()
      );
    end
  end endgenerate
  generate if (1) begin : g_dma_status
    rggen_bit_field_if #(64) bit_field_if();
    `rggen_tie_off_unused_signals(64, 64'h000000000003ffff, bit_field_if)
    rggen_default_register #(
      .READABLE       (1),
      .WRITABLE       (0),
      .ADDRESS_WIDTH  (8),
      .OFFSET_ADDRESS (8'h08),
      .BUS_WIDTH      (64),
      .DATA_WIDTH     (64),
      .REGISTER_INDEX (0)
    ) u_register (
      .i_clk        (i_clk),
      .i_rst_n      (i_rst_n),
      .register_if  (register_if[1]),
      .bit_field_if (bit_field_if)
    );
    if (1) begin : g_version
      localparam bit [15:0] INITIAL_VALUE = 16'hcafe;
      rggen_bit_field_if #(16) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 16)
      rggen_bit_field #(
        .WIDTH              (16),
        .STORAGE            (0),
        .EXTERNAL_READ_DATA (1)
      ) u_bit_field (
        .i_clk              ('0),
        .i_rst_n            ('0),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('0),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            (INITIAL_VALUE),
        .i_mask             ('1),
        .o_value            (),
        .o_value_unmasked   ()
      );
    end
    if (1) begin : g_done
      localparam bit INITIAL_VALUE = 1'h0;
      rggen_bit_field_if #(1) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 16, 1)
      rggen_bit_field #(
        .WIDTH              (1),
        .STORAGE            (0),
        .EXTERNAL_READ_DATA (1),
        .TRIGGER            (0)
      ) u_bit_field (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('0),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            (i_dma_status_done),
        .i_mask             ('1),
        .o_value            (),
        .o_value_unmasked   ()
      );
    end
    if (1) begin : g_error
      localparam bit INITIAL_VALUE = 1'h0;
      rggen_bit_field_if #(1) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 17, 1)
      rggen_bit_field #(
        .WIDTH              (1),
        .STORAGE            (0),
        .EXTERNAL_READ_DATA (1),
        .TRIGGER            (0)
      ) u_bit_field (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('0),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            (register_if[3].value[2+:1]),
        .i_mask             ('1),
        .o_value            (),
        .o_value_unmasked   ()
      );
    end
  end endgenerate
  generate if (1) begin : g_dma_error_addr
    rggen_bit_field_if #(64) bit_field_if();
    `rggen_tie_off_unused_signals(64, 64'h00000000ffffffff, bit_field_if)
    rggen_default_register #(
      .READABLE       (1),
      .WRITABLE       (0),
      .ADDRESS_WIDTH  (8),
      .OFFSET_ADDRESS (8'h10),
      .BUS_WIDTH      (64),
      .DATA_WIDTH     (64),
      .REGISTER_INDEX (0)
    ) u_register (
      .i_clk        (i_clk),
      .i_rst_n      (i_rst_n),
      .register_if  (register_if[2]),
      .bit_field_if (bit_field_if)
    );
    if (1) begin : g_error_addr
      localparam bit [31:0] INITIAL_VALUE = 32'h00000000;
      rggen_bit_field_if #(32) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 32)
      rggen_bit_field #(
        .WIDTH              (32),
        .STORAGE            (0),
        .EXTERNAL_READ_DATA (1),
        .TRIGGER            (0)
      ) u_bit_field (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('0),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            (i_dma_error_addr_error_addr),
        .i_mask             ('1),
        .o_value            (),
        .o_value_unmasked   ()
      );
    end
  end endgenerate
  generate if (1) begin : g_dma_error_stats
    rggen_bit_field_if #(64) bit_field_if();
    `rggen_tie_off_unused_signals(64, 64'h0000000000000007, bit_field_if)
    rggen_default_register #(
      .READABLE       (1),
      .WRITABLE       (0),
      .ADDRESS_WIDTH  (8),
      .OFFSET_ADDRESS (8'h18),
      .BUS_WIDTH      (64),
      .DATA_WIDTH     (64),
      .REGISTER_INDEX (0)
    ) u_register (
      .i_clk        (i_clk),
      .i_rst_n      (i_rst_n),
      .register_if  (register_if[3]),
      .bit_field_if (bit_field_if)
    );
    if (1) begin : g_error_type
      localparam bit INITIAL_VALUE = 1'h0;
      rggen_bit_field_if #(1) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 1)
      rggen_bit_field #(
        .WIDTH              (1),
        .STORAGE            (0),
        .EXTERNAL_READ_DATA (1),
        .TRIGGER            (0)
      ) u_bit_field (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('0),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            (i_dma_error_stats_error_type),
        .i_mask             ('1),
        .o_value            (),
        .o_value_unmasked   ()
      );
    end
    if (1) begin : g_error_src
      localparam bit INITIAL_VALUE = 1'h0;
      rggen_bit_field_if #(1) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 1, 1)
      rggen_bit_field #(
        .WIDTH              (1),
        .STORAGE            (0),
        .EXTERNAL_READ_DATA (1),
        .TRIGGER            (0)
      ) u_bit_field (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('0),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            (i_dma_error_stats_error_src),
        .i_mask             ('1),
        .o_value            (),
        .o_value_unmasked   ()
      );
    end
    if (1) begin : g_error_trig
      localparam bit INITIAL_VALUE = 1'h0;
      rggen_bit_field_if #(1) bit_field_sub_if();
      `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 2, 1)
      rggen_bit_field #(
        .WIDTH              (1),
        .STORAGE            (0),
        .EXTERNAL_READ_DATA (1),
        .TRIGGER            (0)
      ) u_bit_field (
        .i_clk              (i_clk),
        .i_rst_n            (i_rst_n),
        .bit_field_if       (bit_field_sub_if),
        .o_write_trigger    (),
        .o_read_trigger     (),
        .i_sw_write_enable  ('0),
        .i_hw_write_enable  ('0),
        .i_hw_write_data    ('0),
        .i_hw_set           ('0),
        .i_hw_clear         ('0),
        .i_value            (i_dma_error_stats_error_trig),
        .i_mask             ('1),
        .o_value            (),
        .o_value_unmasked   ()
      );
    end
  end endgenerate
  generate if (1) begin : g_dma_desc_src_addr
    genvar i;
    for (i = 0;i < 5;++i) begin : g
      rggen_bit_field_if #(64) bit_field_if();
      `rggen_tie_off_unused_signals(64, 64'h00000000ffffffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (8),
        .OFFSET_ADDRESS (8'h20),
        .BUS_WIDTH      (64),
        .DATA_WIDTH     (64),
        .REGISTER_INDEX (i)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[4+i]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_src_addr
        localparam bit [31:0] INITIAL_VALUE = 32'h00000000;
        rggen_bit_field_if #(32) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 32)
        rggen_bit_field #(
          .WIDTH          (32),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_dma_desc_src_addr_src_addr[i]),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_dma_desc_dst_addr
    genvar i;
    for (i = 0;i < 5;++i) begin : g
      rggen_bit_field_if #(64) bit_field_if();
      `rggen_tie_off_unused_signals(64, 64'h00000000ffffffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (8),
        .OFFSET_ADDRESS (8'h48),
        .BUS_WIDTH      (64),
        .DATA_WIDTH     (64),
        .REGISTER_INDEX (i)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[9+i]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_dst_addr
        localparam bit [31:0] INITIAL_VALUE = 32'h00000000;
        rggen_bit_field_if #(32) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 32)
        rggen_bit_field #(
          .WIDTH          (32),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_dma_desc_dst_addr_dst_addr[i]),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_dma_desc_num_bytes
    genvar i;
    for (i = 0;i < 5;++i) begin : g
      rggen_bit_field_if #(64) bit_field_if();
      `rggen_tie_off_unused_signals(64, 64'h00000000ffffffff, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (8),
        .OFFSET_ADDRESS (8'h70),
        .BUS_WIDTH      (64),
        .DATA_WIDTH     (64),
        .REGISTER_INDEX (i)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[14+i]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_num_bytes
        localparam bit [31:0] INITIAL_VALUE = 32'h00000000;
        rggen_bit_field_if #(32) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 32)
        rggen_bit_field #(
          .WIDTH          (32),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_dma_desc_num_bytes_num_bytes[i]),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
  generate if (1) begin : g_dma_desc_cfg
    genvar i;
    for (i = 0;i < 5;++i) begin : g
      rggen_bit_field_if #(64) bit_field_if();
      `rggen_tie_off_unused_signals(64, 64'h0000000000000007, bit_field_if)
      rggen_default_register #(
        .READABLE       (1),
        .WRITABLE       (1),
        .ADDRESS_WIDTH  (8),
        .OFFSET_ADDRESS (8'h98),
        .BUS_WIDTH      (64),
        .DATA_WIDTH     (64),
        .REGISTER_INDEX (i)
      ) u_register (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .register_if  (register_if[19+i]),
        .bit_field_if (bit_field_if)
      );
      if (1) begin : g_write_mode
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 0, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_dma_desc_cfg_write_mode[i]),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_read_mode
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 1, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_dma_desc_cfg_read_mode[i]),
          .o_value_unmasked   ()
        );
      end
      if (1) begin : g_enable
        localparam bit INITIAL_VALUE = 1'h0;
        rggen_bit_field_if #(1) bit_field_sub_if();
        `rggen_connect_bit_field_if(bit_field_if, bit_field_sub_if, 2, 1)
        rggen_bit_field #(
          .WIDTH          (1),
          .INITIAL_VALUE  (INITIAL_VALUE),
          .SW_WRITE_ONCE  (0),
          .TRIGGER        (0)
        ) u_bit_field (
          .i_clk              (i_clk),
          .i_rst_n            (i_rst_n),
          .bit_field_if       (bit_field_sub_if),
          .o_write_trigger    (),
          .o_read_trigger     (),
          .i_sw_write_enable  ('1),
          .i_hw_write_enable  ('0),
          .i_hw_write_data    ('0),
          .i_hw_set           ('0),
          .i_hw_clear         ('0),
          .i_value            ('0),
          .i_mask             ('1),
          .o_value            (o_dma_desc_cfg_enable[i]),
          .o_value_unmasked   ()
        );
      end
    end
  end endgenerate
endmodule
