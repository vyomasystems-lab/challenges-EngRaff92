module dma_func_wrapper (
	clk,
	rst,
	dma_ctrl_i,
	dma_desc_i,
	dma_error_o,
	dma_stats_o,
	dma_mosi_o,
	dma_miso_i
);
	input clk;
	input rst;
	input wire [9:0] dma_ctrl_i;
	input wire [494:0] dma_desc_i;
	output wire [34:0] dma_error_o;
	output wire [1:0] dma_stats_o;
	output wire [182:0] dma_mosi_o;
	input wire [59:0] dma_miso_i;
	wire [3:0] dma_rd_stream_in;
	wire [0:0] dma_rd_stream_out;
	wire [3:0] dma_wr_stream_in;
	wire [0:0] dma_wr_stream_out;
	wire [48:0] dma_axi_rd_req;
	wire [0:0] dma_axi_rd_resp;
	wire [48:0] dma_axi_wr_req;
	wire [0:0] dma_axi_wr_resp;
	wire [33:0] dma_fifo_req;
	localparam dma_utils_pkg_FIFO_WIDTH = 4;
	wire [43:0] dma_fifo_resp;
	wire [34:0] axi_dma_err;
	wire axi_pend_txn;
	wire clear_dma;
	wire dma_active;
	dma_fsm u_dma_fsm(
		.clk(clk),
		.rst(rst),
		.dma_ctrl_i(dma_ctrl_i),
		.dma_desc_i(dma_desc_i),
		.axi_pend_txn_i(axi_pend_txn),
		.axi_txn_err_i(axi_dma_err),
		.dma_error_o(dma_error_o),
		.clear_dma_o(clear_dma),
		.dma_active_o(dma_active),
		.dma_stats_o(dma_stats_o),
		.dma_stream_rd_o(dma_rd_stream_in),
		.dma_stream_rd_i(dma_rd_stream_out),
		.dma_stream_wr_o(dma_wr_stream_in),
		.dma_stream_wr_i(dma_wr_stream_out)
	);
	dma_streamer #(.STREAM_TYPE(0)) u_dma_rd_streamer(
		.clk(clk),
		.rst(rst),
		.dma_desc_i(dma_desc_i),
		.dma_abort_i(dma_ctrl_i[8]),
		.dma_maxb_i(dma_ctrl_i[7-:8]),
		.dma_axi_req_o(dma_axi_rd_req),
		.dma_axi_resp_i(dma_axi_rd_resp),
		.dma_stream_i(dma_rd_stream_in),
		.dma_stream_o(dma_rd_stream_out)
	);
	dma_streamer #(.STREAM_TYPE(1)) u_dma_wr_streamer(
		.clk(clk),
		.rst(rst),
		.dma_desc_i(dma_desc_i),
		.dma_abort_i(dma_ctrl_i[8]),
		.dma_maxb_i(dma_ctrl_i[7-:8]),
		.dma_axi_req_o(dma_axi_wr_req),
		.dma_axi_resp_i(dma_axi_wr_resp),
		.dma_stream_i(dma_wr_stream_in),
		.dma_stream_o(dma_wr_stream_out)
	);
	dma_fifo u_dma_fifo(
		.clk(clk),
		.rst(rst),
		.clear_i(clear_dma),
		.write_i(dma_fifo_req[33]),
		.read_i(dma_fifo_req[32]),
		.data_i(dma_fifo_req[31-:32]),
		.data_o(dma_fifo_resp[43-:32]),
		.error_o(),
		.full_o(dma_fifo_resp[1]),
		.empty_o(dma_fifo_resp[0]),
		.ocup_o(dma_fifo_resp[11-:5]),
		.free_o(dma_fifo_resp[6-:5])
	);
	dma_axi_if u_dma_axi_if(
		.clk(clk),
		.rst(rst),
		.dma_axi_rd_req_i(dma_axi_rd_req),
		.dma_axi_rd_resp_o(dma_axi_rd_resp),
		.dma_axi_wr_req_i(dma_axi_wr_req),
		.dma_axi_wr_resp_o(dma_axi_wr_resp),
		.dma_mosi_o(dma_mosi_o),
		.dma_miso_i(dma_miso_i),
		.dma_fifo_req_o(dma_fifo_req),
		.dma_fifo_resp_i(dma_fifo_resp),
		.axi_pend_txn_o(axi_pend_txn),
		.axi_dma_err_o(axi_dma_err),
		.clear_dma_i(clear_dma),
		.dma_abort_i(dma_ctrl_i[8]),
		.dma_active_i(dma_active)
	);
endmodule