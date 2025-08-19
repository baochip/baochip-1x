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

module rng_top
#(
  parameter GENERATE_0=4'd1,
  parameter GENERATE_1=4'd2,
  parameter GENERATE_2=4'd4,
  parameter GENERATE_3=4'd8,
  parameter RESEED_1  =11'd1,
  parameter RESEED_2  =11'd128,
  parameter RESEED_3  =11'd1024,
  parameter ANA_NUM   =4'd8
)
(
input  wire                   clk,
input  wire                   rstn,
input  wire  [ANA_NUM-1:0]    clk_ana,
input  wire  [ANA_NUM-1:0]    ana_en,
input  wire  [ANA_NUM-1:0]    ana_data,
input  wire  [ANA_NUM-1:0]    ana_vld,
input  wire                   partityfilter_en,
input  wire                   rngcore_en,
input  wire                   rngcore_rddone,
input  wire                   trng_drng_sel,
input  wire  [1:0]            generate_interval,
input  wire  [1:0]            reseed_interval,
input  wire  [1:0]            postprocess_opt,
input  wire                   additional_input_gen_en,
input  wire  [255:0]          additional_input_generate,
input  wire  [255:0]          additional_input_reseed,
input  wire  [255:0]          personalization_string,
input  wire                   buf_read,
input  wire                   buf_write,
input  wire  [2:0]            buf_addr,
input  wire  [31:0]           buf_datain,
input  wire                   healthtest_en,
input  wire  [5:0]            healthtest_length,
output wire                   buf_ready,
output wire                   healthtest_err,
output wire  [31:0]           buf_dataout,
output wire                   drng_reseed_req,
output wire  [127:0]          rngcore_dataout,
output wire                   rngcore_dataout_vld
);

wire            digi_data_out;
wire            digi_data_vld;
wire            trng_drng_sel_chg;
wire            postprocess_opt_chg;
wire   [255:0]  buf_data;
wire            post_read;

digitalization #(.ANA_NUM  (ANA_NUM))
u_digitalization(
 	.clk               	      (clk                      ),
 	.rstn              	      (rstn                     ),
 	.clk_ana           	      (clk_ana                  ),
 	.ana_en            	      (ana_en                   ),
 	.ana_data           	      (ana_data                 ),
 	.ana_vld            	      (ana_vld                  ),
 	.partityfilter_en   	      (partityfilter_en         ),
 	.digi_data_out     	      (digi_data_out            ),
 	.digi_data_vld     	      (digi_data_vld            ) 
);

healthtest u_healthtest(
        .clk                          (clk                      ),
        .rstn                         (rstn                     ),
        .digi_data_out                (digi_data_out            ),
        .digi_data_vld                (digi_data_vld            ),
        .healthtest_en                (healthtest_en            ),
        .healthtest_length            (healthtest_length        ),
        .healthtest_err               (healthtest_err           )
);

data_buf u_data_buf(
 	.clk                 	      (clk                      ),
 	.rstn                 	      (rstn                     ),
 	.digi_data_out      	      (digi_data_out            ),
 	.digi_data_vld      	      (digi_data_vld            ),
 	.trng_drng_sel      	      (trng_drng_sel            ),
	.postprocess_opt              (postprocess_opt          ),
 	.buf_read           	      (buf_read                 ),
 	.buf_write             	      (buf_write                ),
 	.buf_addr           	      (buf_addr                 ),
 	.buf_datain         	      (buf_datain               ),
 	.post_read          	      (post_read                ),
 	.trng_drng_sel_chg  	      (trng_drng_sel_chg        ),
	.postprocess_opt_chg          (postprocess_opt_chg      ),
 	.buf_dataout        	      (buf_dataout              ), 
 	.buf_data           	      (buf_data                 ),
 	.buf_ready                    (buf_ready                )	
);

postprocess #(.GENERATE_0(GENERATE_0),
 	      .GENERATE_1(GENERATE_1),
    	      .GENERATE_2(GENERATE_2),
   	      .GENERATE_3(GENERATE_3),
              .RESEED_1  (RESEED_1  ),
              .RESEED_2  (RESEED_2  ),
              .RESEED_3  (RESEED_3  ))
u_postprocess(
 	.clk                 	      (clk                	),
 	.rstn                	      (rstn               	), 
 	.trng_drng_sel       	      (trng_drng_sel      	),
  	.trng_drng_sel_chg   	      (trng_drng_sel_chg  	),
        .rngcore_en                   (rngcore_en               ),
        .rngcore_rddone               (rngcore_rddone           ),
	.buf_write          	      (buf_write                ),
 	.buf_addr           	      (buf_addr                 ),
        .buf_data                     (buf_data                 ),
 	.buf_ready           	      (buf_ready          	),
 	.generate_interval   	      (generate_interval        ),
 	.reseed_interval     	      (reseed_interval    	),
 	.digi_data_out     	      (digi_data_out            ),
 	.digi_data_vld     	      (digi_data_vld            ),	
        .post_read                    (post_read                ),
        .drng_reseed_req              (drng_reseed_req          ),
        .rngcore_dataout              (rngcore_dataout          ),
 	.rngcore_dataout_vld          (rngcore_dataout_vld      ),
	.postprocess_opt              (postprocess_opt          ),
	.postprocess_opt_chg          (postprocess_opt_chg      ),
        .additional_input_gen_en      (additional_input_gen_en  ),
 	.additional_input_generate    (additional_input_generate),
 	.additional_input_reseed      (additional_input_reseed  ),
 	.personalization_string       (personalization_string   )
); 	
        
endmodule     
