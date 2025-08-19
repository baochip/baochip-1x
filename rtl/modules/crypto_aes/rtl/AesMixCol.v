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

module AesMixCol(E_D, DIn, DOut);
input E_D;
input [31:0]DIn;
output [31:0]DOut;

wire  E_D;
wire  [31:0]DIn;
wire   [31:0]DOut;

wire [7:0]Data0;
wire [7:0]Data1;
wire [7:0]Data2;
wire [7:0]Data3;
wire [7:0] Data0xe;
wire [7:0] Data1xe;
wire [7:0] Data2xe;
wire [7:0] Data3xe;
wire [7:0] Data0xd;
wire [7:0] Data1xd;
wire [7:0] Data2xd;
wire [7:0] Data3xd;
wire [7:0] Data0xb;
wire [7:0] Data1xb;
wire [7:0] Data2xb;
wire [7:0] Data3xb;
wire [7:0] Data0x9;
wire [7:0] Data1x9;
wire [7:0] Data2x9;
wire [7:0] Data3x9;
wire [7:0]Data0x2;
wire [7:0]Data1x2;
wire [7:0]Data2x2;
wire [7:0]Data3x2;
wire [7:0]Data0x4;
wire [7:0]Data1x4;
wire [7:0]Data2x4;
wire [7:0]Data3x4;
wire [7:0]Data0x8;
wire [7:0]Data1x8;
wire [7:0]Data2x8;
wire [7:0]Data3x8;
wire [7:0]Data0xc;
wire [7:0]Data1xc;
wire [7:0]Data2xc;
wire [7:0]Data3xc;

assign Data0 = DIn[31:24];
assign Data1 = DIn[23:16];
assign Data2 = DIn[15:8];
assign Data3 = DIn[7:0];

assign Data0x2 = {Data0[6:4], Data0[3]^Data0[7], Data0[2]^Data0[7], Data0[1], Data0[0]^Data0[7], Data0[7]};
assign Data1x2 = {Data1[6:4], Data1[3]^Data1[7], Data1[2]^Data1[7], Data1[1], Data1[0]^Data1[7], Data1[7]};
assign Data2x2 = {Data2[6:4], Data2[3]^Data2[7], Data2[2]^Data2[7], Data2[1], Data2[0]^Data2[7], Data2[7]};
assign Data3x2 = {Data3[6:4], Data3[3]^Data3[7], Data3[2]^Data3[7], Data3[1], Data3[0]^Data3[7], Data3[7]};

assign Data0x4 = E_D ? {Data0[5:4], Data0[3]^Data0[7], Data0[2]^Data0[7]^Data0[6], Data0[1]^Data0[6], Data0[0]^Data0[7], Data0[7]^Data0[6], Data0[6]} : 0;
assign Data1x4 = E_D ? {Data1[5:4], Data1[3]^Data1[7], Data1[2]^Data1[7]^Data1[6], Data1[1]^Data1[6], Data1[0]^Data1[7], Data1[7]^Data1[6], Data1[6]} : 0;
assign Data2x4 = E_D ? {Data2[5:4], Data2[3]^Data2[7], Data2[2]^Data2[7]^Data2[6], Data2[1]^Data2[6], Data2[0]^Data2[7], Data2[7]^Data2[6], Data2[6]} : 0;
assign Data3x4 = E_D ? {Data3[5:4], Data3[3]^Data3[7], Data3[2]^Data3[7]^Data3[6], Data3[1]^Data3[6], Data3[0]^Data3[7], Data3[7]^Data3[6], Data3[6]} : 0;

assign Data0x8 = E_D ? {Data0[4], Data0[3]^Data0[7], Data0[2]^Data0[7]^Data0[6], Data0[1]^Data0[6]^Data0[5], Data0[0]^Data0[7]^Data0[5], Data0[7]^Data0[6], Data0[6]^Data0[5], Data0[5]} : 0;
assign Data1x8 = E_D ? {Data1[4], Data1[3]^Data1[7], Data1[2]^Data1[7]^Data1[6], Data1[1]^Data1[6]^Data1[5], Data1[0]^Data1[7]^Data1[5], Data1[7]^Data1[6], Data1[6]^Data1[5], Data1[5]} : 0;
assign Data2x8 = E_D ? {Data2[4], Data2[3]^Data2[7], Data2[2]^Data2[7]^Data2[6], Data2[1]^Data2[6]^Data2[5], Data2[0]^Data2[7]^Data2[5], Data2[7]^Data2[6], Data2[6]^Data2[5], Data2[5]} : 0;
assign Data3x8 = E_D ? {Data3[4], Data3[3]^Data3[7], Data3[2]^Data3[7]^Data3[6], Data3[1]^Data3[6]^Data3[5], Data3[0]^Data3[7]^Data3[5], Data3[7]^Data3[6], Data3[6]^Data3[5], Data3[5]} : 0;

assign Data0xc = Data0x4^Data0x8;
assign Data1xc = Data1x4^Data1x8;
assign Data2xc = Data2x4^Data2x8;
assign Data3xc = Data3x4^Data3x8;

assign Data0x9 = Data0x8^Data0;
assign Data1x9 = Data1x8^Data1;
assign Data2x9 = Data2x8^Data2;
assign Data3x9 = Data3x8^Data3;

assign Data0xb = Data0x8^Data0x2^Data0;
assign Data1xb = Data1x8^Data1x2^Data1;
assign Data2xb = Data2x8^Data2x2^Data2;
assign Data3xb = Data3x8^Data3x2^Data3;

assign Data0xd = Data0xc^Data0;
assign Data1xd = Data1xc^Data1;
assign Data2xd = Data2xc^Data2;
assign Data3xd = Data3xc^Data3;

assign Data0xe = Data0xc^Data0x2;
assign Data1xe = Data1xc^Data1x2;
assign Data2xe = Data2xc^Data2x2;
assign Data3xe = Data3xc^Data3x2;

assign DOut[31:24] = Data0xe^Data1xb^Data2xd^Data3x9;
assign DOut[23:16] = Data0x9^Data1xe^Data2xb^Data3xd;
assign DOut[15: 8] = Data0xd^Data1x9^Data2xe^Data3xb;
assign DOut[7 : 0] = Data0xb^Data1xd^Data2x9^Data3xe;

endmodule

