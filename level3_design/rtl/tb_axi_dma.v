module tb_axi_dma (
	clk,
	rst,
	dma_done_o,
	dma_error_o,
	dma_s_awaddr,
	dma_s_awprot,
	dma_s_awvalid,
	dma_s_wdata,
	dma_s_wstrb,
	dma_s_wlast,
	dma_s_wvalid,
	dma_s_bready,
	dma_s_araddr,
	dma_s_arprot,
	dma_s_arvalid,
	dma_s_rready,
	dma_s_awready,
	dma_s_wready,
	dma_s_bresp,
	dma_s_bvalid,
	dma_s_arready,
	dma_s_rdata,
	dma_s_rresp,
	dma_s_rlast,
	dma_s_rvalid,
	dma_m_awid,
	dma_m_awaddr,
	dma_m_awlen,
	dma_m_awsize,
	dma_m_awburst,
	dma_m_awlock,
	dma_m_awcache,
	dma_m_awprot,
	dma_m_awqos,
	dma_m_awregion,
	dma_m_awuser,
	dma_m_awvalid,
	dma_m_wdata,
	dma_m_wstrb,
	dma_m_wlast,
	dma_m_wuser,
	dma_m_wvalid,
	dma_m_bready,
	dma_m_arid,
	dma_m_araddr,
	dma_m_arlen,
	dma_m_arsize,
	dma_m_arburst,
	dma_m_arlock,
	dma_m_arcache,
	dma_m_arprot,
	dma_m_arqos,
	dma_m_arregion,
	dma_m_aruser,
	dma_m_arvalid,
	dma_m_rready,
	dma_m_awready,
	dma_m_wready,
	dma_m_bid,
	dma_m_bresp,
	dma_m_buser,
	dma_m_bvalid,
	dma_m_arready,
	dma_m_rid,
	dma_m_rdata,
	dma_m_rresp,
	dma_m_rlast,
	dma_m_ruser,
	dma_m_rvalid
);
	input clk;
	input rst;
	output wire dma_done_o;
	output wire dma_error_o;
	input wire [31:0] dma_s_awaddr;
	input wire [2:0] dma_s_awprot;
	input wire dma_s_awvalid;
	input wire [31:0] dma_s_wdata;
	input wire [3:0] dma_s_wstrb;
	input wire dma_s_wlast;
	input wire dma_s_wvalid;
	input wire dma_s_bready;
	input wire [31:0] dma_s_araddr;
	input wire [2:0] dma_s_arprot;
	input wire dma_s_arvalid;
	input wire dma_s_rready;
	output reg dma_s_awready;
	output reg dma_s_wready;
	output reg [1:0] dma_s_bresp;
	output reg dma_s_bvalid;
	output reg dma_s_arready;
	output reg [31:0] dma_s_rdata;
	output reg [1:0] dma_s_rresp;
	output wire dma_s_rlast;
	output reg dma_s_rvalid;
	output reg [7:0] dma_m_awid;
	output reg [31:0] dma_m_awaddr;
	output reg [7:0] dma_m_awlen;
	output reg [2:0] dma_m_awsize;
	output reg [1:0] dma_m_awburst;
	output reg dma_m_awlock;
	output reg [3:0] dma_m_awcache;
	output reg [2:0] dma_m_awprot;
	output reg [3:0] dma_m_awqos;
	output reg [3:0] dma_m_awregion;
	output reg [0:0] dma_m_awuser;
	output reg dma_m_awvalid;
	output reg [31:0] dma_m_wdata;
	output reg [3:0] dma_m_wstrb;
	output reg dma_m_wlast;
	output reg [0:0] dma_m_wuser;
	output reg dma_m_wvalid;
	output reg dma_m_bready;
	output reg [7:0] dma_m_arid;
	output reg [31:0] dma_m_araddr;
	output reg [7:0] dma_m_arlen;
	output reg [2:0] dma_m_arsize;
	output reg [1:0] dma_m_arburst;
	output reg dma_m_arlock;
	output reg [3:0] dma_m_arcache;
	output reg [2:0] dma_m_arprot;
	output reg [3:0] dma_m_arqos;
	output reg [3:0] dma_m_arregion;
	output reg [0:0] dma_m_aruser;
	output reg dma_m_arvalid;
	output reg dma_m_rready;
	input wire dma_m_awready;
	input wire dma_m_wready;
	input wire [7:0] dma_m_bid;
	input wire [1:0] dma_m_bresp;
	input wire [0:0] dma_m_buser;
	input wire dma_m_bvalid;
	input wire dma_m_arready;
	input wire [7:0] dma_m_rid;
	input wire [31:0] dma_m_rdata;
	input wire [1:0] dma_m_rresp;
	input wire dma_m_rlast;
	input wire [0:0] dma_m_ruser;
	input wire dma_m_rvalid;
	reg [126:0] dma_s_mosi;
	wire [56:0] dma_s_miso;
	wire [182:0] dma_m_mosi;
	reg [59:0] dma_m_miso;
	always @(*) begin
		dma_s_mosi[118-:32] = dma_s_awaddr;
		dma_s_mosi[86-:3] = dma_s_awprot;
		dma_s_mosi[83] = dma_s_awvalid;
		dma_s_mosi[82-:32] = dma_s_wdata;
		dma_s_mosi[50-:4] = dma_s_wstrb;
		dma_s_mosi[46] = dma_s_wvalid;
		dma_s_mosi[45] = dma_s_bready;
		dma_s_mosi[36-:32] = dma_s_araddr;
		dma_s_mosi[4-:3] = dma_s_arprot;
		dma_s_mosi[1] = dma_s_arvalid;
		dma_s_mosi[0] = dma_s_rready;
		dma_s_awready = dma_s_miso[56];
		dma_s_wready = dma_s_miso[55];
		dma_s_bresp = dma_s_miso[46-:2];
		dma_s_bvalid = dma_s_miso[44];
		dma_s_arready = dma_s_miso[43];
		dma_s_rdata = dma_s_miso[34-:32];
		dma_s_rresp = dma_s_miso[2-:2];
		dma_s_rvalid = dma_s_miso[0];
		dma_m_awid = dma_m_mosi[182-:8];
		dma_m_awaddr = dma_m_mosi[174-:32];
		dma_m_awlen = dma_m_mosi[142-:8];
		dma_m_awsize = dma_m_mosi[134-:3];
		dma_m_awburst = dma_m_mosi[131-:2];
		dma_m_awlock = dma_m_mosi[129];
		dma_m_awcache = dma_m_mosi[128-:4];
		dma_m_awprot = dma_m_mosi[124-:3];
		dma_m_awqos = dma_m_mosi[121-:4];
		dma_m_awregion = dma_m_mosi[117-:4];
		dma_m_awuser = dma_m_mosi[113];
		dma_m_awvalid = dma_m_mosi[112];
		dma_m_wdata = dma_m_mosi[111-:32];
		dma_m_wstrb = dma_m_mosi[79-:4];
		dma_m_wlast = dma_m_mosi[75];
		dma_m_wuser = dma_m_mosi[74];
		dma_m_wvalid = dma_m_mosi[73];
		dma_m_bready = dma_m_mosi[72];
		dma_m_arid = dma_m_mosi[71-:8];
		dma_m_araddr = dma_m_mosi[63-:32];
		dma_m_arlen = dma_m_mosi[31-:8];
		dma_m_arsize = dma_m_mosi[23-:3];
		dma_m_arburst = dma_m_mosi[20-:2];
		dma_m_arlock = dma_m_mosi[18];
		dma_m_arcache = dma_m_mosi[17-:4];
		dma_m_arprot = dma_m_mosi[13-:3];
		dma_m_arqos = dma_m_mosi[10-:4];
		dma_m_arregion = dma_m_mosi[6-:4];
		dma_m_aruser = dma_m_mosi[2];
		dma_m_arvalid = dma_m_mosi[1];
		dma_m_rready = dma_m_mosi[0];
		dma_m_miso[59] = dma_m_awready;
		dma_m_miso[58] = dma_m_wready;
		dma_m_miso[57-:8] = dma_m_bid;
		dma_m_miso[49-:2] = dma_m_bresp;
		dma_m_miso[47] = dma_m_buser;
		dma_m_miso[46] = dma_m_bvalid;
		dma_m_miso[45] = dma_m_arready;
		dma_m_miso[44-:8] = dma_m_rid;
		dma_m_miso[36-:32] = dma_m_rdata;
		dma_m_miso[4-:2] = dma_m_rresp;
		dma_m_miso[2] = dma_m_rlast;
		dma_m_miso[1] = dma_m_ruser;
		dma_m_miso[0] = dma_m_rvalid;
	end
	dma_axi_wrapper u_dma_axi_wrapper(
		.clk(clk),
		.rst(rst),
		.dma_csr_mosi_i(dma_s_mosi),
		.dma_csr_miso_o(dma_s_miso),
		.dma_m_mosi_o(dma_m_mosi),
		.dma_m_miso_i(dma_m_miso),
		.dma_done_o(dma_done_o),
		.dma_error_o(dma_error_o)
	);
endmodule