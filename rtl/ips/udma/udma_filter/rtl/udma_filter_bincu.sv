// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

///////////////////////////////////////////////////////////////////////////////
//
// Description: Binarization and counting unit
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module udma_filter_bincu
#(
  parameter DATA_WIDTH     = 32,
  parameter TRANS_SIZE     = 16
)   (
  input  logic                  clk_i,
  input  logic                  resetn_i,

  input  logic                  cfg_use_signed_i,
  input  logic                  cfg_out_enable_i,
  input  logic                  cfg_en_counter_i,

  input  logic [DATA_WIDTH-1:0] cfg_threshold_i,
  input  logic [TRANS_SIZE-1:0] cfg_counter_i,
  input  logic            [1:0] cfg_datasize_i,
  output logic [TRANS_SIZE-1:0] counter_val_o,

  input  logic                  cmd_start_i,

  output logic                  act_event_o,

  input  logic [DATA_WIDTH-1:0] input_data_i,
  input  logic            [1:0] input_datasize_i,
  input  logic                  input_valid_i,
  input  logic                  input_sof_i,
  input  logic                  input_eof_i,
  output logic                  input_ready_o,

  output logic [DATA_WIDTH-1:0] output_data_o,
  output logic            [1:0] output_datasize_o,
  output logic                  output_valid_o,
  output logic                  output_sof_o,
  output logic                  output_eof_o,
  input  logic                  output_ready_i

  );

	logic                  s_th_event;
	logic                  s_counter_of;
	logic                  r_count_of;
	logic [TRANS_SIZE-1:0] r_counter;
	logic [DATA_WIDTH-1:0] s_input_data;

  	assign s_th_event    = (s_input_data > cfg_threshold_i);
  	assign s_counter_of  = r_counter == cfg_counter_i;

  	assign act_event_o   = cfg_en_counter_i ? (s_counter_of & ~r_count_of) : 1'b0;

  	assign output_data_o = s_th_event ? 32'h1 : 32'h0;
  	assign output_valid_o = input_valid_i;
  	assign output_eof_o = input_eof_i;
  	assign output_sof_o = input_sof_i;
  	assign input_ready_o = cfg_out_enable_i ? output_ready_i : 1'b1;

  	assign counter_val_o = r_counter;

	always_comb begin : proc_
		s_input_data = input_data_i;
		case(cfg_datasize_i)
			2'b00:
				s_input_data = $signed({input_data_i[7] & cfg_use_signed_i,input_data_i[7:0]});
			2'b01:
				s_input_data = $signed({input_data_i[15] & cfg_use_signed_i,input_data_i[15:0]});
		endcase // input_datasize_i
	end

	always_ff @(posedge clk_i or negedge resetn_i) begin : proc_r_counter
		if(~resetn_i) begin
			r_counter  <= 0;
			r_count_of <= 0;
		end else begin
			if(cmd_start_i)
			begin
				r_counter <= 0;
				r_count_of <= 1'b0;
			end
			else
			begin
				r_count_of <= s_counter_of;
				if(cfg_en_counter_i && s_th_event && input_valid_i)
					r_counter <= r_counter + 1;
			end
		end
	end


endmodule
