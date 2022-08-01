module dma_axi_if (
	clk,
	rst,
	dma_axi_rd_req_i,
	dma_axi_rd_resp_o,
	dma_axi_wr_req_i,
	dma_axi_wr_resp_o,
	dma_mosi_o,
	dma_miso_i,
	dma_fifo_req_o,
	dma_fifo_resp_i,
	axi_pend_txn_o,
	axi_dma_err_o,
	clear_dma_i,
	dma_abort_i,
	dma_active_i
);
	input clk;
	input rst;
	input wire [48:0] dma_axi_rd_req_i;
	output reg [0:0] dma_axi_rd_resp_o;
	input wire [48:0] dma_axi_wr_req_i;
	output reg [0:0] dma_axi_wr_resp_o;
	output reg [182:0] dma_mosi_o;
	input wire [59:0] dma_miso_i;
	output reg [33:0] dma_fifo_req_o;
	localparam dma_utils_pkg_FIFO_WIDTH = 4;
	input wire [43:0] dma_fifo_resp_i;
	output reg axi_pend_txn_o;
	output reg [34:0] axi_dma_err_o;
	input clear_dma_i;
	input dma_abort_i;
	input dma_active_i;
	reg [3:0] rd_counter_ff;
	reg [3:0] next_rd_counter;
	reg [3:0] wr_counter_ff;
	reg [3:0] next_wr_counter;
	wire [3:0] rd_txn_last_strb;
	reg rd_txn_hpn;
	reg wr_txn_hpn;
	reg rd_resp_hpn;
	reg wr_resp_hpn;
	reg rd_err_hpn;
	reg wr_err_hpn;
	wire [31:0] rd_txn_addr;
	wire [31:0] wr_txn_addr;
	reg err_lock_ff;
	reg next_err_lock;
	reg wr_data_txn_hpn;
	reg wr_lock_ff;
	reg next_wr_lock;
	reg wr_new_txn;
	reg wr_beat_hpn;
	wire wr_data_req_empty;
	reg aw_txn_started_ff;
	reg next_aw_txn;
	reg [11:0] wr_data_req_in;
	wire [11:0] wr_data_req_out;
	reg [7:0] beat_counter_ff;
	reg [7:0] next_beat_count;
	reg [34:0] dma_error_ff;
	reg [34:0] next_dma_error;
	function automatic [31:0] apply_strb;
		input reg [31:0] data;
		input reg [3:0] mask;
		reg [31:0] out_data;
		begin
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 4; i = i + 1)
					if (mask[i] == 1'b1)
						out_data[8 * i+:8] = data[8 * i+:8];
					else
						out_data[8 * i+:8] = 8'd0;
			end
			apply_strb = out_data;
		end
	endfunction
	dma_fifo #(
		.SLOTS(8),
		.WIDTH(12)
	) u_fifo_wr_data(
		.clk(clk),
		.rst(rst),
		.write_i(wr_new_txn),
		.read_i(wr_data_txn_hpn),
		.data_i(wr_data_req_in),
		.data_o(wr_data_req_out),
		.error_o(),
		.full_o(),
		.empty_o(wr_data_req_empty),
		.ocup_o(),
		.clear_i(1'b0),
		.free_o()
	);
	dma_fifo #(
		.SLOTS(8),
		.WIDTH(4)
	) u_fifo_rd_strb(
		.clk(clk),
		.rst(rst),
		.write_i(rd_txn_hpn),
		.read_i(rd_resp_hpn),
		.data_i(dma_axi_rd_req_i[5-:4]),
		.data_o(rd_txn_last_strb),
		.error_o(),
		.full_o(),
		.empty_o(),
		.ocup_o(),
		.clear_i(1'b0),
		.free_o()
	);
	dma_fifo #(
		.SLOTS(8),
		.WIDTH(32)
	) u_fifo_rd_error(
		.clk(clk),
		.rst(rst),
		.write_i(rd_txn_hpn),
		.read_i(rd_resp_hpn),
		.data_i(dma_axi_rd_req_i[48-:32]),
		.data_o(rd_txn_addr),
		.error_o(),
		.full_o(),
		.empty_o(),
		.ocup_o(),
		.clear_i(1'b0),
		.free_o()
	);
	dma_fifo #(
		.SLOTS(8),
		.WIDTH(32)
	) u_fifo_wr_error(
		.clk(clk),
		.rst(rst),
		.write_i(wr_txn_hpn),
		.read_i(wr_resp_hpn),
		.data_i(dma_axi_wr_req_i[48-:32]),
		.data_o(wr_txn_addr),
		.error_o(),
		.full_o(),
		.empty_o(),
		.ocup_o(),
		.clear_i(1'b0),
		.free_o()
	);
	always @(*) begin
		axi_pend_txn_o = |rd_counter_ff || |wr_counter_ff;
		axi_dma_err_o = dma_error_ff;
		next_dma_error = dma_error_ff;
		next_err_lock = err_lock_ff;
		next_rd_counter = rd_counter_ff;
		next_wr_counter = wr_counter_ff;
		if (~dma_active_i)
			next_err_lock = 1'b0;
		else
			next_err_lock = rd_err_hpn || wr_err_hpn;
		if (~err_lock_ff)
			if (rd_err_hpn) begin
				next_dma_error[0] = 1'b1;
				next_dma_error[2] = 1'd1;
				next_dma_error[1] = 1'd0;
				next_dma_error[34-:32] = rd_txn_addr;
			end
			else if (wr_err_hpn) begin
				next_dma_error[0] = 1'b1;
				next_dma_error[2] = 1'd1;
				next_dma_error[1] = 1'd1;
				next_dma_error[34-:32] = wr_txn_addr;
			end
		if (clear_dma_i) begin
			next_dma_error = 35'b00000000000000000000000000000000000;
			next_wr_lock = 1'b0;
		end
		rd_txn_hpn = dma_mosi_o[1] && dma_miso_i[45];
		rd_resp_hpn = (dma_miso_i[0] && dma_miso_i[2]) && dma_mosi_o[0];
		wr_txn_hpn = dma_mosi_o[112] && dma_miso_i[59];
		wr_resp_hpn = dma_miso_i[46] && dma_mosi_o[72];
		if (dma_active_i) begin
			if (rd_txn_hpn || rd_resp_hpn)
				next_rd_counter = (rd_counter_ff + (rd_txn_hpn ? 'd1 : 'd0)) - (rd_resp_hpn ? 'd1 : 'd0);
			if (wr_txn_hpn || wr_resp_hpn)
				next_wr_counter = (wr_counter_ff + (wr_txn_hpn ? 'd1 : 'd0)) - (wr_resp_hpn ? 'd1 : 'd0);
		end
		else begin
			next_rd_counter = 'd0;
			next_wr_counter = 'd0;
		end
		wr_data_txn_hpn = (dma_mosi_o[73] && dma_mosi_o[75]) && dma_miso_i[58];
		wr_new_txn = 1'b0;
		next_wr_lock = wr_lock_ff;
		wr_data_req_in = 12'b000000000000;
		if (dma_axi_wr_req_i[0]) begin
			next_wr_lock = ~dma_axi_wr_resp_o[0];
			wr_new_txn = ~wr_lock_ff;
			wr_data_req_in[11-:8] = dma_axi_wr_req_i[16-:8];
			wr_data_req_in[3-:4] = dma_axi_wr_req_i[5-:4];
		end
		if (wr_txn_hpn)
			next_wr_lock = 1'b0;
		wr_beat_hpn = dma_mosi_o[73] && dma_miso_i[58];
		next_beat_count = beat_counter_ff;
		if (wr_beat_hpn)
			next_beat_count = beat_counter_ff + 'd1;
		if (wr_data_txn_hpn)
			next_beat_count = 8'b00000000;
	end
	always @(*) begin : axi4_master
		dma_mosi_o = 183'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		dma_fifo_req_o = 34'b0000000000000000000000000000000000;
		rd_err_hpn = 1'b0;
		wr_err_hpn = 1'b0;
		dma_axi_rd_resp_o = 1'b0;
		dma_axi_wr_resp_o = 1'b0;
		if (dma_active_i) begin
			dma_mosi_o[13-:3] = 3'b010;
			dma_mosi_o[71-:8] = 0;
			dma_mosi_o[1] = (rd_counter_ff < 8 ? dma_axi_rd_req_i[0] : 1'b0);
			if (dma_mosi_o[1]) begin
				dma_axi_rd_resp_o[0] = dma_miso_i[45];
				dma_mosi_o[63-:32] = dma_axi_rd_req_i[48-:32];
				dma_mosi_o[31-:8] = dma_axi_rd_req_i[16-:8];
				dma_mosi_o[23-:3] = dma_axi_rd_req_i[8-:3];
				dma_mosi_o[20-:2] = (dma_axi_rd_req_i[1] == 1'd0 ? 2'd1 : 2'd0);
			end
			dma_mosi_o[0] = ~dma_fifo_resp_i[1] || dma_abort_i;
			if (dma_miso_i[0] && (~dma_fifo_resp_i[1] || dma_abort_i)) begin
				dma_fifo_req_o[33] = (dma_abort_i ? 1'b0 : 1'b1);
				dma_fifo_req_o[31-:32] = apply_strb(dma_miso_i[36-:32], rd_txn_last_strb);
				if (dma_miso_i[2] && dma_mosi_o[0])
					rd_err_hpn = (dma_miso_i[4-:2] == 2'd2) || (dma_miso_i[4-:2] == 2'd3);
			end
			dma_mosi_o[124-:3] = 3'b010;
			dma_mosi_o[182-:8] = 0;
			dma_mosi_o[112] = (wr_counter_ff < 8 ? (dma_axi_wr_req_i[0] && (~dma_fifo_resp_i[0] || dma_abort_i)) || aw_txn_started_ff : 1'b0);
			if (dma_mosi_o[112]) begin
				dma_axi_wr_resp_o[0] = dma_miso_i[59];
				dma_mosi_o[174-:32] = dma_axi_wr_req_i[48-:32];
				dma_mosi_o[142-:8] = dma_axi_wr_req_i[16-:8];
				dma_mosi_o[134-:3] = dma_axi_wr_req_i[8-:3];
				dma_mosi_o[131-:2] = (dma_axi_wr_req_i[1] == 1'd0 ? 2'd1 : 2'd0);
				next_aw_txn = ~dma_miso_i[59];
			end
			if (~wr_data_req_empty && (~dma_fifo_resp_i[0] || dma_abort_i)) begin
				dma_fifo_req_o[32] = (dma_abort_i ? 1'b0 : dma_miso_i[58]);
				dma_mosi_o[111-:32] = dma_fifo_resp_i[43-:32];
				dma_mosi_o[79-:4] = wr_data_req_out[3-:4];
				dma_mosi_o[75] = beat_counter_ff == wr_data_req_out[11-:8];
				dma_mosi_o[73] = 1'b1;
			end
			dma_mosi_o[72] = 1'b1;
			if (dma_miso_i[46])
				wr_err_hpn = (dma_miso_i[49-:2] == 2'd2) || (dma_miso_i[49-:2] == 2'd3);
		end
	end
	always @(posedge clk)
		if (rst) begin
			rd_counter_ff <= 4'b0000;
			wr_counter_ff <= 4'b0000;
			dma_error_ff <= 35'b00000000000000000000000000000000000;
			err_lock_ff <= 1'b0;
			beat_counter_ff <= next_beat_count;
			wr_lock_ff <= 1'b0;
			aw_txn_started_ff <= 1'b0;
		end
		else begin
			rd_counter_ff <= next_rd_counter;
			wr_counter_ff <= next_wr_counter;
			dma_error_ff <= next_dma_error;
			err_lock_ff <= next_err_lock;
			beat_counter_ff <= next_beat_count;
			wr_lock_ff <= next_wr_lock;
			aw_txn_started_ff <= next_aw_txn;
		end
endmodule