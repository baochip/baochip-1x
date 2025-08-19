// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2015-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`define PDM_MODE_1CH     2'b00
`define PDM_MODE_2CH_RF  2'b01
`define PDM_MODE_2CH_SEP 2'b10
`define PDM_MODE_4CH     2'b11

module pdm_top (
	input  logic          clk_i,
	input  logic          rstn_i,
	output logic          pdm_clk_o,
    input  logic  [1:0]   cfg_pdm_ch_mode_i,
    input  logic  [9:0]   cfg_pdm_decimation_i,
    input  logic  [2:0]   cfg_pdm_shift_i,
    input  logic          cfg_pdm_en_i,
	input  logic          pdm_ch0_i,
	input  logic          pdm_ch1_i,
	output logic   [15:0] pcm_data_o,
	output logic          pcm_data_valid_o,
	input  logic          pcm_data_ready_i
);

	logic [1:0] s_ch_target;
	logic       s_data;
	logic       s_data_valid;
	logic       r_store_ch0;
	logic       r_store_ch1;
	logic       r_store_ch2;
	logic       r_store_ch3;
	logic       r_send_ch0;
	logic       r_send_ch1;
	logic       r_send_ch2;
	logic       r_send_ch3;
	logic       r_data_ch0;
	logic       r_data_ch1;
	logic       r_data_ch2;
	logic       r_data_ch3;
	logic       r_valid;
	logic       r_clk;
	logic       r_clk_dly;

	assign pdm_clk_o = r_clk;

	varcic #( 
  		.STAGES(5),
  		.ACC_WIDTH(51)
	) i_varcic (
  		.clk_i            ( clk_i                ),
  		.rstn_i           ( rstn_i               ),
  		.cfg_en_i         ( cfg_pdm_en_i         ),
  		.cfg_ch_num_i     ( s_ch_target          ),
  		.cfg_decimation_i ( cfg_pdm_decimation_i ),
  		.cfg_shift_i      ( cfg_pdm_shift_i      ),
  		.data_i           ( s_data               ),
  		.data_valid_i     ( s_data_valid         ),
  		.data_o           ( pcm_data_o           ),
  		.data_valid_o     ( pcm_data_valid_o     )
	);
	always_comb begin : proc_s_ch_target
		s_ch_target = 0;
		case(cfg_pdm_ch_mode_i)
			`PDM_MODE_1CH:
				s_ch_target = 0;
			`PDM_MODE_2CH_RF:
				s_ch_target = 1;
			`PDM_MODE_2CH_SEP:
				s_ch_target = 1;
			`PDM_MODE_4CH:
				s_ch_target = 3;
		endcase // cfg_pdm_ch_mode_i
	end

	always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_store
		if(~rstn_i) begin
			r_store_ch0 <= 1;
			r_store_ch1 <= 0;
			r_store_ch2 <= 0;
			r_store_ch3 <= 0;
			r_send_ch0  <= 0;
			r_send_ch1  <= 0;
			r_send_ch2  <= 0;
			r_send_ch3  <= 0;
			r_data_ch0  <= 0;
			r_data_ch1  <= 0;
			r_data_ch2  <= 0;
			r_data_ch3  <= 0;
			r_clk       <= 0;
			r_clk_dly   <= 0;
		end else begin
	  		if(cfg_pdm_en_i)
	  		begin

	        case(cfg_pdm_ch_mode_i)
	        	`PDM_MODE_1CH:
	        	begin
	        		r_store_ch0 <= ~r_store_ch0;
	        		r_send_ch0  <= ~r_send_ch0;
	        		if(r_store_ch0)
	        			r_data_ch0 <= pdm_ch0_i;
	        		r_clk <= ~r_clk;
	        	end
	        	`PDM_MODE_2CH_RF:
	        	begin
	        		r_store_ch0 <= ~r_store_ch0;
	        		r_send_ch0  <= ~r_send_ch0;
	        		r_store_ch1 <= ~r_store_ch1;
	        		r_send_ch1  <=  r_send_ch0;
	        		if(r_store_ch0)
	        			r_data_ch0 <= pdm_ch0_i;
	        		if(r_store_ch1)
	        			r_data_ch1 <= pdm_ch0_i;
	        		r_clk <= ~r_clk;
	        	end
	        	`PDM_MODE_2CH_SEP:
	        	begin
	        		r_store_ch0 <= ~r_store_ch0;
	        		r_send_ch0  <= ~r_send_ch0;
	        		r_send_ch1  <=  r_send_ch0;
	        		if(r_store_ch0)
	        		begin
	        			r_data_ch0 <= pdm_ch0_i;
	        			r_data_ch1 <= pdm_ch1_i;
	        		end
	        		r_clk <= ~r_clk;
	        	end
	        	`PDM_MODE_4CH:
	        	begin
	        		r_store_ch0 <=  r_clk_dly & ~r_clk;
	        		r_store_ch2 <= ~r_clk_dly &  r_clk;
	        		r_send_ch0 <= r_store_ch0;
	        		r_send_ch1 <= r_send_ch0;
	        		r_send_ch2 <= r_send_ch1;
	        		r_send_ch3 <= r_send_ch2;
	        		if(r_store_ch0)
	        		begin
	        			r_data_ch0 <= pdm_ch0_i;
	        			r_data_ch1 <= pdm_ch1_i;
	        		end
	        		if(r_store_ch2)
	        		begin
	        			r_data_ch2 <= pdm_ch0_i;
	        			r_data_ch3 <= pdm_ch1_i;
	        		end
	        		r_clk      <= ~r_clk_dly;
	        		r_clk_dly  <= r_clk;

	        	end
	        endcase // cfg_pdm_ch_mode_i
			end	
			else
			begin
				r_store_ch0 <= 1'b1;
				r_store_ch1 <= 0;
				r_store_ch2 <= 0;
				r_store_ch3 <= 0;
				r_send_ch0  <= 0;
				r_send_ch1  <= 0;
				r_send_ch2  <= 0;
				r_send_ch3  <= 0;
				r_clk       <= 0;
				r_clk_dly   <= 0;
			end
		end
	end

	always_comb begin : proc_s_data
		if(r_send_ch0)
		begin
				s_data = r_data_ch0;
		end
		else if(r_send_ch1)
		begin
				s_data = r_data_ch1;
		end
		else if(r_send_ch2)
		begin
				s_data = r_data_ch2;
		end
		else
		begin
				s_data = r_data_ch3;
		end
	end

	assign s_data_valid = r_send_ch0 | r_send_ch1 | r_send_ch2 | r_send_ch3;

endmodule