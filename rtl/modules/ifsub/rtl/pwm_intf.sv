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

module pwm #( parameter ICNT = 16*5 )(
	input bit clk,    // Clock
	input bit resetn,
	input bit cmsatpg,

	input bit 			 clk32m,
	input bit [ICNT-1:0] gpiosrc,
	output bit [3:0]   	 ev,

	apbif.slave 	apbs,
	ioif.drive 		pwm0[3:0], pwm1[3:0], pwm2[3:0], pwm3[3:0]

);

apb_adv_timer #(
//        .APB_ADDR_WIDTH ( APB_ADDR_WIDTH ),
        .EXTSIG_NUM      ( ICNT           )
    ) apb_adv_timer_i (
        .HCLK            ( clk                     ),
        .HRESETn         ( resetn                  ),

        .dft_cg_enable_i ( cmsatpg 		           ),

        .PADDR           ( apbs.paddr   ),
        .PWDATA          ( apbs.pwdata  ),
        .PWRITE          ( apbs.pwrite  ),
        .PSEL            ( apbs.psel    ),
        .PENABLE         ( apbs.penable ),
        .PRDATA          ( apbs.prdata  ),
        .PREADY          ( apbs.pready  ),
        .PSLVERR         ( apbs.pslverr ),

        .low_speed_clk_i ( clk32m            ),
        .ext_sig_i       ( gpiosrc           ),

        .events_o        ( ev      ),

        .ch_0_o          ( {pwm0[3].po, pwm0[2].po, pwm0[1].po, pwm0[0].po } ),
        .ch_1_o          ( {pwm1[3].po, pwm1[2].po, pwm1[1].po, pwm1[0].po } ),
        .ch_2_o          ( {pwm2[3].po, pwm2[2].po, pwm2[1].po, pwm2[0].po } ),
        .ch_3_o          ( {pwm3[3].po, pwm3[2].po, pwm3[1].po, pwm3[0].po } )
    );

	assign { pwm0[3].oe, pwm0[2].oe, pwm0[1].oe, pwm0[0].oe } = '1;
	assign { pwm1[3].oe, pwm1[2].oe, pwm1[1].oe, pwm1[0].oe } = '1;
	assign { pwm2[3].oe, pwm2[2].oe, pwm2[1].oe, pwm2[0].oe } = '1;
	assign { pwm3[3].oe, pwm3[2].oe, pwm3[1].oe, pwm3[0].oe } = '1;

	assign { pwm0[3].pu, pwm0[2].pu, pwm0[1].pu, pwm0[0].pu } = '1;
	assign { pwm1[3].pu, pwm1[2].pu, pwm1[1].pu, pwm1[0].pu } = '1;
	assign { pwm2[3].pu, pwm2[2].pu, pwm2[1].pu, pwm2[0].pu } = '1;
	assign { pwm3[3].pu, pwm3[2].pu, pwm3[1].pu, pwm3[0].pu } = '1;

endmodule
