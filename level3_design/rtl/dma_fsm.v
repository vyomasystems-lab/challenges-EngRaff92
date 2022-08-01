module dma_fsm (
	clk,
	rst,
	dma_ctrl_i,
	dma_desc_i,
	dma_stats_o,
	axi_pend_txn_i,
	axi_txn_err_i,
	dma_error_o,
	clear_dma_o,
	dma_active_o,
	dma_stream_rd_o,
	dma_stream_rd_i,
	dma_stream_wr_o,
	dma_stream_wr_i
);
	input clk;
	input rst;
	input wire [9:0] dma_ctrl_i;
	input wire [494:0] dma_desc_i;
	output reg [1:0] dma_stats_o;
	input axi_pend_txn_i;
	input wire [34:0] axi_txn_err_i;
	output reg [34:0] dma_error_o;
	output reg clear_dma_o;
	output reg dma_active_o;
	output reg [3:0] dma_stream_rd_o;
	input wire [0:0] dma_stream_rd_i;
	output reg [3:0] dma_stream_wr_o;
	input wire [0:0] dma_stream_wr_i;
	reg [1:0] cur_st_ff;
	reg [1:0] next_st;
	reg [4:0] rd_desc_done_ff;
	reg [4:0] next_rd_desc_done;
	reg [4:0] wr_desc_done_ff;
	reg [4:0] next_wr_desc_done;
	reg pending_desc;
	reg pending_rd_desc;
	reg pending_wr_desc;
	reg abort_ff;
	function automatic check_cfg;
		input reg _sv2v_unused;
		reg [4:0] valid_desc;
		begin
			valid_desc = 1'sb0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 5; i = i + 1)
					if (dma_desc_i[i * 99])
						valid_desc[i] = |dma_desc_i[(i * 99) + 34-:32];
			end
			check_cfg = |valid_desc;
		end
	endfunction
	always @(*) begin : fsm_dma_ctrl
		next_st = 2'd0;
		pending_desc = pending_rd_desc || pending_wr_desc;
		case (cur_st_ff)
			2'd0:
				if (dma_ctrl_i[9])
					next_st = 2'd1;
			2'd1:
				if (~dma_ctrl_i[8] && check_cfg(0))
					next_st = 2'd2;
				else
					next_st = 2'd3;
			2'd2:
				if (pending_desc || axi_pend_txn_i)
					next_st = 2'd2;
				else
					next_st = 2'd3;
			2'd3:
				if (dma_ctrl_i[9])
					next_st = 2'd3;
		endcase
	end
	always @(*) begin : sv2v_autoblock_2
		reg [0:1] _sv2v_jump;
		_sv2v_jump = 2'b00;
		begin : rd_streamer
			dma_stream_rd_o = 4'b0000;
			next_rd_desc_done = rd_desc_done_ff;
			pending_rd_desc = 1'b0;
			dma_active_o = cur_st_ff == 2'd2;
			if (cur_st_ff == 2'd2) begin
				begin : sv2v_autoblock_3
					reg signed [31:0] i;
					for (i = 0; i < 5; i = i + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if ((dma_desc_i[i * 99] && |dma_desc_i[(i * 99) + 34-:32]) && ~rd_desc_done_ff[i]) begin
								dma_stream_rd_o[2-:3] = i;
								dma_stream_rd_o[3] = 1'b1;
								_sv2v_jump = 2'b10;
							end
						end
					if (_sv2v_jump != 2'b11)
						_sv2v_jump = 2'b00;
				end
				if (_sv2v_jump == 2'b00) begin
					if (dma_stream_rd_i[0]) begin
						next_rd_desc_done[dma_stream_rd_o[2-:3]] = 1'b1;
						if (abort_ff)
							dma_stream_rd_o[3] = 1'b0;
					end
					pending_rd_desc = dma_stream_rd_o[3];
				end
			end
			if (_sv2v_jump == 2'b00)
				if (cur_st_ff == 2'd3)
					next_rd_desc_done = 1'sb0;
		end
	end
	always @(*) begin : sv2v_autoblock_4
		reg [0:1] _sv2v_jump;
		_sv2v_jump = 2'b00;
		begin : wr_streamer
			dma_stream_wr_o = 4'b0000;
			next_wr_desc_done = wr_desc_done_ff;
			pending_wr_desc = 1'b0;
			if (cur_st_ff == 2'd2) begin
				begin : sv2v_autoblock_5
					reg signed [31:0] i;
					for (i = 0; i < 5; i = i + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if ((dma_desc_i[i * 99] && |dma_desc_i[(i * 99) + 34-:32]) && ~wr_desc_done_ff[i]) begin
								dma_stream_wr_o[2-:3] = i;
								dma_stream_wr_o[3] = 1'b1;
								_sv2v_jump = 2'b10;
							end
						end
					if (_sv2v_jump != 2'b11)
						_sv2v_jump = 2'b00;
				end
				if (_sv2v_jump == 2'b00) begin
					if (dma_stream_wr_i[0]) begin
						next_wr_desc_done[dma_stream_wr_o[2-:3]] = 1'b1;
						if (abort_ff)
							dma_stream_wr_o[3] = 1'b0;
					end
					pending_wr_desc = dma_stream_wr_o[3];
				end
			end
			if (_sv2v_jump == 2'b00)
				if (cur_st_ff == 2'd3)
					next_wr_desc_done = 1'sb0;
		end
	end
	always @(*) begin : dma_status
		dma_error_o = 35'b00000000000000000000000000000000000;
		if (axi_txn_err_i[0]) begin
			dma_error_o[34-:32] = axi_txn_err_i[34-:32];
			dma_error_o[2] = 1'd1;
			dma_error_o[1] = axi_txn_err_i[1];
			dma_error_o[0] = 1'b1;
		end
		dma_stats_o[1] = axi_txn_err_i[0];
		dma_stats_o[0] = cur_st_ff == 2'd3;
		clear_dma_o = (cur_st_ff == 2'd3) && (next_st == 2'd0);
	end
	always @(posedge clk)
		if (rst) begin
			cur_st_ff <= 2'b00;
			rd_desc_done_ff <= 1'sb0;
			wr_desc_done_ff <= 1'sb0;
			abort_ff <= 1'sb0;
		end
		else begin
			cur_st_ff <= next_st;
			rd_desc_done_ff <= next_rd_desc_done;
			wr_desc_done_ff <= next_wr_desc_done;
			abort_ff <= dma_ctrl_i[8];
		end
endmodule