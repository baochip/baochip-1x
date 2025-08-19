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

module lut_4x4
(
	input  logic				clk_i,
	input  logic        		rstn_i,

	input  logic                cfg_en_i,
	input  logic                cfg_update_i,

	input  logic         [15:0] cfg_lut_i,

	input  logic          [3:0] signal_i,
	output logic                signal_o

);
	logic                r_active;
	logic         [15:0] r_lut;

	always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_lut
		if(~rstn_i) begin
			r_lut    <= 0;
		end else begin
			if ( (cfg_en_i && !r_active) || cfg_update_i ) //if first enable or explicit update is iven
			begin
				r_lut    <= cfg_lut_i;
			end
		end
	end

	always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_active
		if(~rstn_i) begin
			r_active <= 0;
		end else 
		begin			
			if (cfg_en_i && !r_active)
				r_active <= 1'b1;
			else if (!cfg_en_i && r_active)
				r_active <= 1'b0;
		end
	end


	always_comb begin : proc_signal_o
		signal_o = 1'b0;
		for (int i=0;i<16;i++)
		begin
			if (i == signal_i)
				signal_o = r_lut[i];
		end
	end

endmodule // lut_4x4
