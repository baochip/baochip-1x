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

module bscell
  #(parameter bit IV=0)
  (
   input logic 	clk_i,
   input logic 	rst_ni,
   input logic 	mode_i,
   input logic 	enable_i,
   input logic 	shift_dr_i,
   input logic 	capture_dr_i,
   input logic 	update_dr_i,
   input logic 	scan_in_i,
   input logic 	jtagreg_in_i,
   output logic scan_out_o,
   output logic jtagreg_out_o
   );

   logic 	r_dataout;
   logic 	r_datasample;
   logic 	s_datasample_next;

   always_ff @(negedge rst_ni, posedge clk_i)
     begin
	if (~rst_ni)
	  begin
	     r_datasample <= IV;
	     r_dataout    <= IV;
	  end
	else
	  begin
	     if ((shift_dr_i | capture_dr_i) & enable_i)
               r_datasample <= s_datasample_next;
	     if (update_dr_i & enable_i)
               r_dataout <= r_datasample;
	  end
     end

   assign s_datasample_next = (shift_dr_i) ? scan_in_i : jtagreg_in_i;
   assign jtagreg_out_o = (mode_i) ? r_dataout : jtagreg_in_i;
   assign scan_out_o = r_datasample;

endmodule






