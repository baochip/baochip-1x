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

`timescale 1ns / 10ps
module data_buf(
input   wire         clk,
input   wire         rstn,
input   wire         digi_data_out,
input   wire         digi_data_vld,
input   wire  [1:0]  postprocess_opt,
input   wire         trng_drng_sel,
input   wire         buf_read,
input   wire         buf_write,
input   wire  [2:0]  buf_addr,
input   wire  [31:0] buf_datain,
input   wire         post_read,
output  wire         postprocess_opt_chg,
output  wire         trng_drng_sel_chg,
output  reg  [31:0]  buf_dataout, 
output  reg  [255:0] buf_data,
output  reg          buf_ready   
);

reg   [8:0]    buf_cnt;
reg   [255:0]  buf_data_pre;
reg            trng_drng_sel_dly;
reg   [1:0]    postprocess_opt_dly;

wire           buf_ready_pre;
wire  [8:0]    buf_cnt_pre;

//data input
always @(posedge clk or negedge rstn)begin
    if(!rstn)begin
        buf_data           <= 256'b0;
        buf_ready          <= 1'b0;
	buf_cnt            <= 9'h0;
	trng_drng_sel_dly  <= 1'b0;
	postprocess_opt_dly<= 2'b0;
    end
    else begin
        buf_data           <= buf_data_pre;
        buf_ready          <= buf_ready_pre;
        buf_cnt            <= buf_cnt_pre;	
        trng_drng_sel_dly  <= trng_drng_sel;
	postprocess_opt_dly<= postprocess_opt;
    end	
end
assign postprocess_opt_chg=(postprocess_opt_dly!=postprocess_opt);
assign trng_drng_sel_chg  =trng_drng_sel_dly  ^trng_drng_sel;
	 
assign buf_cnt_pre= trng_drng_sel_chg|postprocess_opt_chg|post_read|(buf_read  & (buf_addr==3'd7)) ? 9'h0 :
	          ((~trng_drng_sel)&digi_data_vld&(buf_cnt<9'd256))?(buf_cnt+1'b1):buf_cnt;

always @(*)begin
    if(trng_drng_sel&buf_write)begin
        buf_data_pre[31 :  0] = (buf_addr==3'd7) ? buf_datain: buf_data[31 :  0]; 	
        buf_data_pre[63 : 32] = (buf_addr==3'd6) ? buf_datain: buf_data[63 : 32]; 	
        buf_data_pre[95 : 64] = (buf_addr==3'd5) ? buf_datain: buf_data[95 : 64]; 	
        buf_data_pre[127: 96] = (buf_addr==3'd4) ? buf_datain: buf_data[127: 96]; 	
        buf_data_pre[159:128] = (buf_addr==3'd3) ? buf_datain: buf_data[159:128]; 	
        buf_data_pre[191:160] = (buf_addr==3'd2) ? buf_datain: buf_data[191:160]; 	
        buf_data_pre[223:192] = (buf_addr==3'd1) ? buf_datain: buf_data[223:192]; 	
        buf_data_pre[255:224] = (buf_addr==3'd0) ? buf_datain: buf_data[255:224];
    end
    else if((~trng_drng_sel)&digi_data_vld)begin 
        buf_data_pre[255:0] = {buf_data[254:0],digi_data_out};
    end
    else
        buf_data_pre[255:0] =  buf_data[255:0];
end

//data output
always @(*)begin
    case(buf_addr)
         3'd7   :buf_dataout=buf_data[31 :  0]; 	
         3'd6   :buf_dataout=buf_data[63 : 32]; 	
         3'd5   :buf_dataout=buf_data[95 : 64]; 	
         3'd4   :buf_dataout=buf_data[127: 96]; 	
         3'd3   :buf_dataout=buf_data[159:128]; 	
         3'd2   :buf_dataout=buf_data[191:160]; 	
         3'd1   :buf_dataout=buf_data[223:192]; 	
         3'd0   :buf_dataout=buf_data[255:224];
	 default:buf_dataout=buf_data[255:224];
   endcase
end

assign buf_ready_pre= (trng_drng_sel_chg|postprocess_opt_chg|(buf_read  & (buf_addr==3'd7))|post_read)? 1'b0: 
		      ((trng_drng_sel & buf_write & (buf_addr==3'd7))|(~trng_drng_sel &(buf_cnt>=9'd256)))? 1'b1:
		                 buf_ready;
	              
endmodule
