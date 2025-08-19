// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// This documentation and source code is licensed under the CERN Open Hardware
// License Version 2 – Weakly Reciprocal (http://ohwr.org/cernohl; the
// “License”). Your use of any source code herein is governed by the License.
//
// You may redistribute and modify this documentation under the terms of the
// License. This documentation and source code is distributed WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
// PARTICULAR PURPOSE. Please see the License for the specific language governing
// permissions and limitations under the License.

module aes_rcon(clk,rstn, kld, out);
input		clk;
input           rstn;
input		kld;
output	[31:0]	out;
reg	[31:0]	out;
reg	[3:0]	rcnt;
wire	[3:0]	rcnt_next;

always @(posedge clk or negedge rstn) 
	if(!rstn)       out <= 32'h01_00_00_00;
	else if(kld)	out <= 32'h01_00_00_00;
	else		out <= frcon(rcnt_next);

assign rcnt_next = rcnt + 4'h1;
always @(posedge clk or negedge rstn) 
	if(!rstn)       rcnt <= 4'h0;
	else if(kld)	rcnt <= 4'h0;
	else		rcnt <= rcnt_next;

function [31:0]	frcon;
input	[3:0]	i;
case(i)	// synopsys parallel_case
   4'h0: frcon=32'h01_00_00_00;
   4'h1: frcon=32'h02_00_00_00;
   4'h2: frcon=32'h04_00_00_00;
   4'h3: frcon=32'h08_00_00_00;
   4'h4: frcon=32'h10_00_00_00;
   4'h5: frcon=32'h20_00_00_00;
   4'h6: frcon=32'h40_00_00_00;
   4'h7: frcon=32'h80_00_00_00;
   4'h8: frcon=32'h1b_00_00_00;
   4'h9: frcon=32'h36_00_00_00;
   default: frcon=32'h00_00_00_00;
endcase
endfunction

endmodule
