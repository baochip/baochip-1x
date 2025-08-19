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

module aes_key_expand_128(clk, rstn, kld, key, wo_0, wo_1, wo_2, wo_3);
input		      clk;
input          rstn;
input		      kld;
input	[127:0]	key;
output[31:0]	wo_0, wo_1, wo_2, wo_3;
reg	[31:0]	w[3:0];
wire	[31:0]	tmp_w;
wire	[31:0]	subword;
wire	[31:0]	rcon;

assign wo_0 = w[0];
assign wo_1 = w[1];
assign wo_2 = w[2];
assign wo_3 = w[3];
always @(posedge clk or negedge rstn)if(!rstn) w[0] <= 32'h0; else w[0] <= kld ? key[127:096] : w[0]^subword^rcon;
always @(posedge clk or negedge rstn)if(!rstn) w[1] <= 32'h0; else w[1] <= kld ? key[095:064] : w[0]^w[1]^subword^rcon;
always @(posedge clk or negedge rstn)if(!rstn) w[2] <= 32'h0; else w[2] <= kld ? key[063:032] : w[0]^w[2]^w[1]^subword^rcon;
always @(posedge clk or negedge rstn)if(!rstn) w[3] <= 32'h0; else w[3] <= kld ? key[031:000] : w[0]^w[3]^w[2]^w[1]^subword^rcon;
assign tmp_w = w[3];
aes_sbox u0(	.a(tmp_w[23:16]), .d(subword[31:24]));
aes_sbox u1(	.a(tmp_w[15:08]), .d(subword[23:16]));
aes_sbox u2(	.a(tmp_w[07:00]), .d(subword[15:08]));
aes_sbox u3(	.a(tmp_w[31:24]), .d(subword[07:00]));
aes_rcon r0(	.clk(clk), .rstn(rstn), .kld(kld), .out(rcon));
endmodule

