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

module out_filter
(
	input  logic				clk_i,
	input  logic        		rstn_i,

	input  logic                ctrl_active_i,
	input  logic                ctrl_update_i,
	
	input  logic          [1:0] cfg_mode_i,

	input  logic                signal_i,
	output logic                signal_o

);

	logic s_rise;
	logic s_fall;

	logic                r_active;
	logic                r_oldval;
	logic          [1:0] r_mode;


	assign s_rise = ~r_oldval &  signal_i;
	assign s_fall =  r_oldval & ~signal_i;

	always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_mode
		if(~rstn_i) begin
			r_mode    <= 0;
		end else begin
			if (ctrl_update_i) //if first enable or explicit update is iven
			begin
				r_mode    <= cfg_mode_i;
			end
		end
	end

	always_comb begin : proc_signal_o
		case (r_mode)
			2'b00:
				signal_o = signal_i;
			2'b01:
				signal_o = s_rise;
			2'b10:
				signal_o = s_fall;
			2'b11:
				signal_o = s_rise | s_fall;
		endcase // cfg_mode_i
	end

	always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_oldval
		if(~rstn_i) begin
			r_oldval <= 0;
		end else begin
			if(ctrl_active_i)
				r_oldval <= signal_i;
		end
	end

endmodule // out_filter
