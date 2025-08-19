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

module jtag_sync
  (
   input logic 	clk_i,
   input logic 	rst_ni,
   input logic 	tosynch,
   output logic synched
   );

   logic 	synch1,synch2,synch3;

   always_ff @(posedge clk_i, negedge rst_ni)
     begin
	if (~rst_ni)  begin
	   synch1 <= 1'b0;
	   synch2 <= 1'b0;
	   synch3 <= 1'b0;
	   synched <= 1'b0;
	end
	else begin
	   synch1 <= tosynch;
	   synch2 <= synch1;
	   synch3 <= synch2;
	   synched<= synch3;
	end
     end


endmodule // jtag_sync
