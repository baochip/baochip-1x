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

module lfsr129
#(
  parameter GENERATE_0=4'd1,
  parameter GENERATE_1=4'd2,
  parameter GENERATE_2=4'd4,
  parameter GENERATE_3=4'd8,
  parameter RESEED_1  =11'd1,
  parameter RESEED_2  =11'd128,
  parameter RESEED_3  =11'd1024 
)
(
input  wire         clk,
input  wire         rstn,
input  wire         trng_drng_sel,
input  wire         trng_drng_sel_chg,
input  wire         rngcore_en,
input  wire         rngcore_rddone,
input  wire[255:0]  buf_data,
input  wire         buf_ready,
input  wire[1:0]    generate_interval,
input  wire[1:0]    reseed_interval,
input  wire[1:0]    postprocess_opt,
input  wire         digi_data_out,
input  wire         digi_data_vld,
output wire         post_read_lfsr,
output wire         drng_reseed_req,
output wire[127:0]  lfsr_dataout,
output reg          lfsr_dataout_vld
);

reg   [7:0]     lfsr_cnt;
reg   [128:0]   lfsr_chain;
reg   [13:0]    reseed_cnt;
reg   [3:0]     generate_value;
reg   [10:0]    reseed_value;
reg             lfsr_stable;
reg             reseed_req;

wire  [7:0]     lfsr_cnt_pre;
wire  [128:0]   lfsr_chain_pre;
wire            lfsr_dataout_vld_pre;
wire  [13:0]    reseed_cnt_pre;
wire            lfsr_stable_pre; 
wire            reseed_req_pre;
wire            rngcore_en_lfsr;
wire            lfsr_out;

always @(posedge clk or negedge rstn)begin
    if(!rstn)begin
        lfsr_cnt          <= 8'd0;
        lfsr_chain        <= 129'h1_A39A8864_5DF3BECE_074EC5D3_BAF39D18;
        lfsr_cnt          <= 8'h0;
        lfsr_dataout_vld  <= 1'b0;
	lfsr_stable       <= 1'b0;
	reseed_cnt        <= 14'd0;
	reseed_req        <= 1'd0;
    end
    else begin
        lfsr_cnt          <= lfsr_cnt_pre;
	lfsr_chain        <= lfsr_chain_pre;
        lfsr_cnt          <= lfsr_cnt_pre;
	lfsr_dataout_vld  <= lfsr_dataout_vld_pre;
	lfsr_stable       <= lfsr_stable_pre;
	reseed_cnt        <= reseed_cnt_pre;
	reseed_req        <= reseed_req_pre;
    end
end

assign rngcore_en_lfsr  = rngcore_en & (postprocess_opt==2'd0);
assign lfsr_stable_pre  = (~rngcore_en_lfsr)| trng_drng_sel_chg |drng_reseed_req ? 1'b0:
	                  buf_ready & post_read_lfsr                        ? 1'b1:lfsr_stable;

assign lfsr_chain_pre   = (|lfsr_chain==1'b0) ? 129'h1_A39A8864_5DF3BECE_074EC5D3_BAF39D18:
	                  (rngcore_en_lfsr& (~lfsr_stable) &  buf_ready & post_read_lfsr) ? buf_data[255:127]:
                          (rngcore_en_lfsr&   lfsr_stable  &  (~lfsr_dataout_vld) &   trng_drng_sel)                  ? {lfsr_chain[127:0],lfsr_out}: 
                          (rngcore_en_lfsr&   lfsr_stable  &  (~lfsr_dataout_vld) & (~trng_drng_sel) & digi_data_vld) ? {lfsr_chain[127:0],lfsr_out^digi_data_out}: 
               		  lfsr_chain;
	
assign lfsr_out         = lfsr_chain[128]^lfsr_chain[114]^lfsr_chain[110]^lfsr_chain[100]^lfsr_chain[43]^lfsr_chain[41];

assign lfsr_cnt_pre     = (~rngcore_en_lfsr| ~lfsr_stable |rngcore_rddone) ? 8'h0 :
                          ((lfsr_cnt<8'd129)&trng_drng_sel) |
			  ((lfsr_cnt<8'd129)&(~trng_drng_sel)&digi_data_vld) ? (lfsr_cnt +1'b1):lfsr_cnt;

assign lfsr_dataout     = lfsr_chain[127:0];		  

assign lfsr_dataout_vld_pre = (lfsr_cnt_pre==8'd128)&&(lfsr_cnt==8'd127) ? 1'b1 :
	                       rngcore_rddone                            ? 1'b0 :lfsr_dataout_vld;

assign reseed_cnt_pre       = (~rngcore_en_lfsr)|(buf_ready & post_read_lfsr) ? 14'd0 : 
	                      (lfsr_dataout_vld & ~lfsr_dataout_vld_pre & (reseed_interval!=2'h0)&
			                     (reseed_cnt < (generate_value*reseed_value))) ? (reseed_cnt+1'b1):reseed_cnt;

assign reseed_req_pre       = (buf_ready  &post_read_lfsr)|trng_drng_sel_chg? 1'b0:
	                      (reseed_cnt == generate_value*reseed_value) ? 1'b1: reseed_req;

assign drng_reseed_req      = reseed_req_pre & (~reseed_req);

assign post_read_lfsr       =((rngcore_en_lfsr& (~lfsr_stable)) |reseed_req)  &  buf_ready;

always@(*)begin
    case(generate_interval)
        2'd0   : generate_value = GENERATE_0;     
	2'd1   : generate_value = GENERATE_1;     
	2'd2   : generate_value = GENERATE_2;     
	2'd3   : generate_value = GENERATE_3;
	default: generate_value = GENERATE_3;
    endcase
end     

always@(*)begin
    case(reseed_interval)
	2'd1   : reseed_value = RESEED_1;     
	2'd2   : reseed_value = RESEED_2;     
	2'd3   : reseed_value = RESEED_3;
	default: reseed_value = RESEED_3;
    endcase
end    
endmodule
