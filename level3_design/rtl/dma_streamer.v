module dma_streamer (
	clk,
	rst,
	dma_desc_i,
	dma_abort_i,
	dma_maxb_i,
	dma_axi_req_o,
	dma_axi_resp_i,
	dma_stream_i,
	dma_stream_o
);
	parameter [0:0] STREAM_TYPE = 0;
	input clk;
	input rst;
	input wire [494:0] dma_desc_i;
	input dma_abort_i;
	input wire [7:0] dma_maxb_i;
	output reg [48:0] dma_axi_req_o;
	input wire [0:0] dma_axi_resp_i;
	input wire [3:0] dma_stream_i;
	output reg [0:0] dma_stream_o;
	localparam bytes_p_burst = 4;
	localparam max_txn_width = 10;
	reg cur_st_ff;
	reg next_st;
	reg [31:0] desc_addr_ff;
	reg [31:0] next_desc_addr;
	reg [31:0] desc_bytes_ff;
	reg [31:0] next_desc_bytes;
	reg dma_mode_ff;
	reg next_dma_mode;
	reg [48:0] dma_req_ff;
	reg [48:0] next_dma_req;
	reg [max_txn_width:0] txn_bytes;
	reg last_txn_ff;
	reg next_last_txn;
	reg full_burst;
	reg [3:0] num_unalign_bytes;
	reg last_txn_proc;
	function automatic [3:0] get_strb;
		input reg [2:0] addr;
		input reg [3:0] bytes;
		reg [3:0] strobe;
		begin
			case (bytes)
				'd1: strobe = 'b1;
				'd2: strobe = 'b11;
				'd3: strobe = 'b111;
				'd4: strobe = 'b1111;
				default: strobe = 1'sb0;
			endcase
			begin : sv2v_autoblock_1
				reg [3:0] i;
				for (i = 0; i < 8; i = i + 1)
					if (addr == i[2:0])
						strobe = strobe << i;
			end
			get_strb = strobe;
		end
	endfunction
	function automatic [3:0] bytes_to_align;
		input reg [31:0] addr;
		bytes_to_align = 4'd4 - {2'b00, addr[1:0]};
	endfunction
	function automatic [31:0] aligned_addr;
		input reg [31:0] addr;
		aligned_addr = {addr[31:2], 2'b00};
	endfunction
	function automatic valid_burst;
		input reg mode;
		input reg [8:0] alen_plus_1;
		if (mode == 1'd1)
			valid_burst = alen_plus_1 <= 16;
		else
			valid_burst = 1;
	endfunction
	function automatic is_aligned;
		input reg [31:0] addr;
		is_aligned = addr[1:0] == {2 {1'sb0}};
	endfunction
	function automatic enough_for_burst;
		input reg [31:0] bytes;
		enough_for_burst = bytes >= 'd4;
	endfunction
	function automatic burst_r4KB;
		input reg [31:0] base;
		input reg [31:0] fut;
		if (fut[31:12] < base[31:12])
			burst_r4KB = 0;
		else if (fut[31:12] > base[31:12])
			burst_r4KB = fut[11:0] == {12 {1'sb0}};
		else
			burst_r4KB = 1;
	endfunction
	function automatic [7:0] sv2v_cast_8;
		input reg [7:0] inp;
		sv2v_cast_8 = inp;
	endfunction
	function automatic [7:0] great_alen;
		input reg [31:0] addr;
		input reg [31:0] bytes;
		reg [31:0] fut_addr;
		reg [7:0] alen;
		reg [31:0] txn_sz;
		reg [0:1] _sv2v_jump;
		begin
			alen = 0;
			_sv2v_jump = 2'b00;
			begin : sv2v_autoblock_2
				reg signed [31:0] i;
				for (i = 256; i > 0; i = i - 1)
					if (_sv2v_jump < 2'b10) begin
						_sv2v_jump = 2'b00;
						fut_addr = addr + (i * bytes_p_burst);
						txn_sz = i * bytes_p_burst;
						if (((bytes >= txn_sz) && ((i - 'd1) <= dma_maxb_i)) && valid_burst(dma_mode_ff, i[8:0]))
							if (burst_r4KB(addr, fut_addr)) begin
								alen = sv2v_cast_8(i - 1);
								great_alen = alen;
								_sv2v_jump = 2'b11;
							end
					end
				if (_sv2v_jump != 2'b11)
					_sv2v_jump = 2'b00;
			end
		end
	endfunction
	always @(*) begin : streamer_dma_ctrl
		next_st = 1'd0;
		case (cur_st_ff)
			1'd0:
				if (dma_stream_i[3])
					next_st = 1'd1;
			1'd1:
				if (dma_abort_i) begin
					if (last_txn_proc)
						next_st = 1'd1;
					else
						next_st = 1'd0;
				end
				else if (desc_bytes_ff > 0)
					next_st = 1'd1;
				else if (last_txn_ff && ~dma_axi_resp_i[0])
					next_st = 1'd1;
		endcase
	end
	function automatic [10:0] sv2v_cast_3D8D6;
		input reg [10:0] inp;
		sv2v_cast_3D8D6 = inp;
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(*) begin : burst_calc
		dma_stream_o = 1'b0;
		next_dma_mode = dma_mode_ff;
		next_dma_req = dma_req_ff;
		next_desc_addr = desc_addr_ff;
		next_desc_bytes = desc_bytes_ff;
		dma_axi_req_o = dma_req_ff;
		next_last_txn = last_txn_ff;
		last_txn_proc = 1'b0;
		full_burst = 1'b0;
		if ((cur_st_ff == 1'd0) && (next_st == 1'd1)) begin
			next_desc_bytes = dma_desc_i[(dma_stream_i[2-:3] * 99) + 34-:32];
			if (STREAM_TYPE) begin
				next_desc_addr = dma_desc_i[(dma_stream_i[2-:3] * 99) + 66-:32];
				next_dma_mode = dma_desc_i[(dma_stream_i[2-:3] * 99) + 2];
			end
			else begin
				next_desc_addr = dma_desc_i[(dma_stream_i[2-:3] * 99) + 98-:32];
				next_dma_mode = dma_desc_i[(dma_stream_i[2-:3] * 99) + 1];
			end
		end
		if (cur_st_ff == 1'd1)
			if (~dma_abort_i) begin
				if ((~dma_req_ff[0] || (dma_req_ff[0] && dma_axi_resp_i[0])) && ~last_txn_ff) begin
					next_dma_req[48-:32] = aligned_addr(desc_addr_ff);
					next_dma_req[8-:3] = 2;
					next_dma_req[1] = dma_mode_ff;
					if (is_aligned(desc_addr_ff) && enough_for_burst(desc_bytes_ff)) begin
						next_dma_req[16-:8] = great_alen(desc_addr_ff, desc_bytes_ff);
						next_dma_req[5-:4] = 1'sb1;
						full_burst = 1'b1;
					end
					else begin
						next_dma_req[16-:8] = 8'b00000000;
						if (enough_for_burst(desc_bytes_ff)) begin
							num_unalign_bytes = bytes_to_align(desc_addr_ff);
							next_dma_req[5-:4] = get_strb(desc_addr_ff[2:0], num_unalign_bytes);
						end
						else if (is_aligned(desc_addr_ff)) begin
							num_unalign_bytes = desc_bytes_ff[3:0];
							next_dma_req[5-:4] = get_strb('d0, num_unalign_bytes);
						end
						else begin
							num_unalign_bytes = desc_bytes_ff[3:0];
							next_dma_req[5-:4] = get_strb(desc_addr_ff[2:0], num_unalign_bytes);
						end
					end
					txn_bytes = (full_burst ? sv2v_cast_3D8D6((next_dma_req[16-:8] + 8'd1) * bytes_p_burst) : sv2v_cast_3D8D6(num_unalign_bytes));
					next_desc_bytes = desc_bytes_ff - sv2v_cast_32(txn_bytes);
					next_last_txn = next_desc_bytes == {32 {1'sb0}};
					if (dma_mode_ff == 1'd1)
						next_desc_addr = desc_addr_ff;
					else
						next_desc_addr = desc_addr_ff + sv2v_cast_32(txn_bytes);
					next_dma_req[0] = 1'b1;
				end
				else if (last_txn_ff && dma_axi_resp_i[0]) begin
					next_dma_req = 49'b0000000000000000000000000000000000000000000000000;
					next_last_txn = 1'b0;
				end
			end
			else if (dma_req_ff[0] && ~dma_axi_resp_i[0])
				last_txn_proc = 'b1;
			else
				next_dma_req = 49'b0000000000000000000000000000000000000000000000000;
		dma_stream_o[0] = (cur_st_ff == 1'd1) && (next_st == 1'd0);
	end
	always @(posedge clk)
		if (rst) begin
			cur_st_ff <= 1'b0;
			desc_addr_ff <= 32'b00000000000000000000000000000000;
			desc_bytes_ff <= 32'b00000000000000000000000000000000;
			dma_mode_ff <= 1'b0;
			last_txn_ff <= 1'b0;
		end
		else begin
			cur_st_ff <= next_st;
			desc_addr_ff <= next_desc_addr;
			desc_bytes_ff <= next_desc_bytes;
			dma_mode_ff <= next_dma_mode;
			last_txn_ff <= next_last_txn;
			dma_req_ff <= next_dma_req;
		end
endmodule