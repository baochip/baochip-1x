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

module healthtest(
input  wire       clk,
input  wire       rstn,
input  wire       digi_data_out,
input  wire       digi_data_vld,
input  wire       healthtest_en,
input  wire[5:0]  healthtest_length,
output reg        healthtest_err
);

wire   [5:0]  healthtest_cnt_pre;
wire          healthtest_err_pre;
wire          digi_data_save_pre;

reg    [5:0]  healthtest_cnt;
reg           digi_data_save;

assign digi_data_save_pre = digi_data_vld ? digi_data_out :digi_data_save;
assign healthtest_cnt_pre = (~healthtest_en) ? 6'h0 : 
	                    (digi_data_vld&(digi_data_out==digi_data_save)&(healthtest_cnt< healthtest_length))? healthtest_cnt+1'b1:
			    (digi_data_vld&(digi_data_out!=digi_data_save))? 6'h0 :healthtest_cnt;

assign healthtest_err_pre = (digi_data_vld&(digi_data_out==digi_data_save)&(healthtest_cnt>=healthtest_length))? 1'b1:
	                    (digi_data_vld&(digi_data_out!=digi_data_save))? 1'b0 :healthtest_err;   


always @(posedge clk or negedge rstn)begin
    if(!rstn)begin
        digi_data_save <= 1'b0;	    
        healthtest_cnt <= 6'b0;
        healthtest_err <= 1'b0;
    end
    else begin
        healthtest_cnt <= healthtest_cnt_pre;
	healthtest_err <= healthtest_err_pre;
	digi_data_save <= digi_data_save_pre;	    
    end
end

endmodule
