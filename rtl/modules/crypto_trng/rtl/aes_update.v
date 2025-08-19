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

module aes_update(clk, rstn, ld, done, key, sel,text_in, text_out);
input		       clk, rstn;
input		       ld;
input           sel;
output		    done;
input	[127:0]	 key;
input	[127:0]	 text_in;
output[255:0]	 text_out;
 
wire            ld_tmp;
wire		       done_tmp;
wire  [127:0]	 text_in_tmp;
wire	[127:0]	 text_out_tmp;
wire            aes_sel_pre;
wire  [127:0]   text_out0_pre;
wire            done;         

reg             aes_sel;
reg             done_tmp_dly;
reg     [127:0] text_out0;

aes_cipher_top u_aes_cipher_top(
	.clk      (clk         ), 
	.rstn     (rstn        ), 
	.ld       (ld_tmp      ), 
	.done     (done_tmp    ),
	.key      (key         ), 
	.text_in  (text_in_tmp ), 
	.text_out (text_out_tmp)
);

always @(posedge clk or negedge rstn)begin
    if(!rstn)begin	
	     done_tmp_dly <= 1'b0;
        aes_sel      <= 1'b0;
        text_out0    <= 128'h0;
    end
    else begin
	     done_tmp_dly <= done_tmp;
        aes_sel      <= aes_sel_pre;
	     text_out0    <= text_out0_pre;
    end
end

assign ld_tmp       = ld | (done_tmp_dly&aes_sel&sel);
assign aes_sel_pre  = ld | (~sel)|(aes_sel &sel& done_tmp) ? 1'b0 : (~aes_sel)& done_tmp ? 1'b1:aes_sel;
assign done         = (done_tmp&(~sel)) |(done_tmp&aes_sel&sel);
assign text_in_tmp  = aes_sel&sel ? (text_in+1'b1):text_in;
assign text_out0_pre= (~sel)? 128'h0: ((~aes_sel)&sel&done_tmp) ? text_out_tmp:text_out0;
assign text_out     = {text_out0,text_out_tmp};

endmodule
