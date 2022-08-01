module dma_axi_wrapper (
	clk,
	rst,
	dma_csr_mosi_i,
	dma_csr_miso_o,
	dma_m_mosi_o,
	dma_m_miso_i,
	dma_done_o,
	dma_error_o
);
	input clk;
	input rst;
	input wire [126:0] dma_csr_mosi_i;
	output wire [56:0] dma_csr_miso_o;
	output wire [182:0] dma_m_mosi_o;
	input wire [59:0] dma_m_miso_i;
	output reg dma_done_o;
	output reg dma_error_o;
	localparam AXI_DATA_WIDTH = 32;
	wire [159:0] dma_desc_src_vec;
	wire [159:0] dma_desc_dst_vec;
	wire [159:0] dma_desc_byt_vec;
	wire [4:0] dma_desc_wr_mod;
	wire [4:0] dma_desc_rd_mod;
	wire [4:0] dma_desc_en;
	reg [494:0] dma_desc;
	wire [9:0] dma_ctrl;
	wire [1:0] dma_stats;
	wire [34:0] dma_error;
	always @(*) begin
		dma_done_o = dma_stats[0];
		dma_error_o = dma_stats[1];
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 5; i = i + 1)
				begin : connecting_structs_with_csr
					dma_desc[(i * 99) + 98-:32] = dma_desc_src_vec[i * 32+:32];
					dma_desc[(i * 99) + 66-:32] = dma_desc_dst_vec[i * 32+:32];
					dma_desc[(i * 99) + 34-:32] = dma_desc_byt_vec[i * 32+:32];
					dma_desc[(i * 99) + 2] = dma_desc_wr_mod[i];
					dma_desc[(i * 99) + 1] = dma_desc_rd_mod[i];
					dma_desc[i * 99] = dma_desc_en[i];
				end
		end
	end
	csr_dma #(.ID_WIDTH(8)) u_csr_dma(
		.i_clk(clk),
		.i_rst_n(~rst),
		.i_awvalid(dma_csr_mosi_i[83]),
		.o_awready(dma_csr_miso_o[56]),
		.i_awid(dma_csr_mosi_i[126-:8]),
		.i_awaddr(dma_csr_mosi_i[118-:32]),
		.i_awprot(dma_csr_mosi_i[86-:3]),
		.i_wvalid(dma_csr_mosi_i[46]),
		.o_wready(dma_csr_miso_o[55]),
		.i_wdata(dma_csr_mosi_i[82-:32]),
		.i_wstrb(dma_csr_mosi_i[50-:4]),
		.o_bvalid(dma_csr_miso_o[44]),
		.i_bready(dma_csr_mosi_i[45]),
		.o_bid(dma_csr_miso_o[54-:8]),
		.o_bresp(dma_csr_miso_o[46-:2]),
		.i_arvalid(dma_csr_mosi_i[1]),
		.o_arready(dma_csr_miso_o[43]),
		.i_arid(dma_csr_mosi_i[44-:8]),
		.i_araddr(dma_csr_mosi_i[36-:32]),
		.i_arprot(dma_csr_mosi_i[4-:3]),
		.o_rvalid(dma_csr_miso_o[0]),
		.i_rready(dma_csr_mosi_i[0]),
		.o_rid(dma_csr_miso_o[42-:8]),
		.o_rdata(dma_csr_miso_o[34-:32]),
		.o_rresp(dma_csr_miso_o[2-:2]),
		.o_dma_control_go(dma_ctrl[9]),
		.o_dma_control_max_burst(dma_ctrl[7-:8]),
		.o_dma_control_abort(dma_ctrl[8]),
		.i_dma_status_done(dma_stats[0]),
		.i_dma_error_stats_error_trig(dma_stats[1]),
		.i_dma_error_addr_error_addr(dma_error[34-:32]),
		.i_dma_error_stats_error_type(dma_error[2]),
		.i_dma_error_stats_error_src(dma_error[1]),
		.o_dma_desc_src_addr_src_addr(dma_desc_src_vec),
		.o_dma_desc_dst_addr_dst_addr(dma_desc_dst_vec),
		.o_dma_desc_num_bytes_num_bytes(dma_desc_byt_vec),
		.o_dma_desc_cfg_write_mode(dma_desc_wr_mod),
		.o_dma_desc_cfg_read_mode(dma_desc_rd_mod),
		.o_dma_desc_cfg_enable(dma_desc_en)
	);
	dma_func_wrapper u_dma_func_wrapper(
		.clk(clk),
		.rst(rst),
		.dma_ctrl_i(dma_ctrl),
		.dma_desc_i(dma_desc),
		.dma_stats_o(dma_stats),
		.dma_error_o(dma_error),
		.dma_mosi_o(dma_m_mosi_o),
		.dma_miso_i(dma_m_miso_i)
	);
endmodule