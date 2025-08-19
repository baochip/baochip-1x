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

module digitalization
#(
  parameter ANA_NUM=4'd8
)
(
input  wire                clk,
input  wire                rstn,
input  wire [ANA_NUM-1:0]  clk_ana,
input  wire [ANA_NUM-1:0]  ana_en,
input  wire [ANA_NUM-1:0]  ana_data,
input  wire [ANA_NUM-1:0]  ana_vld,
input  wire                partityfilter_en,
output wire                digi_data_out,
output wire                digi_data_vld
);

reg  [ANA_NUM-1:0]  data_samp;
reg  [ANA_NUM-1:0]  clk_ana_dly1;
reg  [ANA_NUM-1:0]  clk_ana_dly2;
reg  [ANA_NUM-1:0]  clk_ana_dly3;
reg  [ANA_NUM-1:0]  digi_data_out_tmp;
reg  [ANA_NUM-1:0]  digi_data_vld_tmp;
reg  [ANA_NUM-1:0]  digi_cnt;
reg                 cnt_en;

wire                digi_data_vld_out;
wire [ANA_NUM-1:0]  digi_data_vld_sel;
wire [ANA_NUM-1:0]  digi_data_out_sel;  
wire [ANA_NUM-1:0]  digi_data_out_tmp_pre;
wire [ANA_NUM-1:0]  digi_data_vld_tmp_pre;
wire [ANA_NUM-1:0]  data_samp_pre;
wire [ANA_NUM-1:0]  clk_ana_pos;
wire [ANA_NUM-1:0]  ana_vld_sys;
wire [ANA_NUM-1:0]  digi_cnt_pre;
wire                cnt_en_pre;
//Analog data sample
genvar    i;                            
generate 
    for(i=0;i<ANA_NUM;i=i+1) begin : digi_sample
        always @(posedge clk_ana[i] or negedge rstn)begin
            if(!rstn)
                data_samp[i] <= 1'b0;
	    else	
                data_samp[i] <= data_samp_pre[i];
        end
        assign data_samp_pre[i]=ana_vld[i]?ana_data[i]:data_samp[i];

	always @(posedge clk or negedge rstn)begin
            if(!rstn)begin
                clk_ana_dly1[i] <= 1'b0;
                clk_ana_dly2[i] <= 1'b0;
                clk_ana_dly3[i] <= 1'b0;
	    end
	    else begin
	        clk_ana_dly1[i] <= clk_ana[i];
                clk_ana_dly2[i] <= clk_ana_dly1[i];
                clk_ana_dly3[i] <= clk_ana_dly2[i];
   	    end	
        end
        assign clk_ana_pos[i]= clk_ana_dly2[i] & (~clk_ana_dly3[i]);
	assign ana_vld_sys[i]= clk_ana_pos[i]  & ana_en[i] & ana_vld[i];
    end
endgenerate

//parityfilter enable or disable
assign digi_data_out_tmp_pre[0]           = partityfilter_en ? (^data_samp[ANA_NUM-1:0]): data_samp[0];
assign digi_data_out_tmp_pre[ANA_NUM-1:1] = partityfilter_en ? 'h0                      : data_samp[ANA_NUM-1:1];
assign digi_data_vld_tmp_pre[0]           = (digi_cnt==ANA_NUM) ? 1'b0:
			                     clk_ana_pos[0]     ? (partityfilter_en ? 1'b1 : ana_vld_sys[0])          : digi_data_vld_tmp[0];
assign digi_data_vld_tmp_pre[ANA_NUM-1:1] = (digi_cnt==ANA_NUM) ?  'h0:
			                     clk_ana_pos[0]     ? (partityfilter_en ?  'h0 : ana_vld_sys[ANA_NUM-1:1]): digi_data_vld_tmp[ANA_NUM-1:1];
//serial data output
genvar    j;                            
generate 
    for(j=0;j<ANA_NUM;j=j+1) begin : data_serial
         assign digi_data_out_sel[j]=digi_data_out_tmp[j]&(digi_cnt==j+1);
         assign digi_data_vld_sel[j]=digi_data_vld_tmp[j]&(digi_cnt==j+1);
    end
endgenerate
assign digi_data_out     = |digi_data_out_sel[ANA_NUM-1:0];
assign digi_data_vld_out = |digi_data_vld_sel[ANA_NUM-1:0];

//always@(*)begin
//    case(digi_cnt)
//        4'd1   :digi_data_out=digi_data_out_tmp[0];
//        4'd2   :digi_data_out=digi_data_out_tmp[1];
//        4'd3   :digi_data_out=digi_data_out_tmp[2];
//        4'd4   :digi_data_out=digi_data_out_tmp[3];
//        4'd5   :digi_data_out=digi_data_out_tmp[4];
//        4'd6   :digi_data_out=digi_data_out_tmp[5];
//        4'd7   :digi_data_out=digi_data_out_tmp[6];
//        4'd8   :digi_data_out=digi_data_out_tmp[7];
//        default:digi_data_out=1'b0;
//    endcase
//end
//
//always@(*)begin
//    case(digi_cnt)
//        4'd1   :digi_data_vld_sel=digi_data_vld_tmp[0];
//        4'd2   :digi_data_vld_sel=digi_data_vld_tmp[1];
//        4'd3   :digi_data_vld_sel=digi_data_vld_tmp[2];
//        4'd4   :digi_data_vld_sel=digi_data_vld_tmp[3];
//        4'd5   :digi_data_vld_sel=digi_data_vld_tmp[4];
//        4'd6   :digi_data_vld_sel=digi_data_vld_tmp[5];
//        4'd7   :digi_data_vld_sel=digi_data_vld_tmp[6];
//        4'd8   :digi_data_vld_sel=digi_data_vld_tmp[7];
//        default:digi_data_vld_sel=1'b0;
//    endcase
//end

assign digi_data_vld =(digi_cnt>=4'd1)&(digi_cnt<=ANA_NUM)&digi_data_vld_out;



always @(posedge clk or negedge rstn)begin
    if(!rstn)begin
        digi_data_out_tmp <= {ANA_NUM{1'h0}};
        digi_data_vld_tmp <= {ANA_NUM{1'h0}};
	digi_cnt          <= {ANA_NUM{1'h0}};
	cnt_en            <= 1'h0;
    end
    else begin
        digi_data_out_tmp <= digi_data_out_tmp_pre;
        digi_data_vld_tmp <= digi_data_vld_tmp_pre;
        digi_cnt          <= digi_cnt_pre;
        cnt_en            <= cnt_en_pre;
    end	
end
assign digi_cnt_pre  =(clk_ana_pos[0]|cnt_en) ? (digi_cnt+1'b1): 'h0;
assign cnt_en_pre    = clk_ana_pos[0] ? 1'b1 : (digi_cnt==(ANA_NUM-1)) ? 1'b0: cnt_en;
endmodule
