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

`include "template.sv"
module RNG_CELL (
	input wire        IN_0P1U,

	input logic [2:0] SEL,
	input logic       EN,
	output logic RNG1_OUT,
	output logic RNG2_OUT,
	output logic RNG3_OUT,
	output logic RNG4_OUT,
	output logic RNG5_OUT,
	output logic RNG6_OUT,
	output logic RNG7_OUT,
	output logic RNG8_OUT
);

`ifdef SIM
    rng_osc #(.KHz(510))   u1 ( .EN(EN), .CKO( RNG1_OUT  ) );
    rng_osc #(.KHz(554))   u2 ( .EN(EN), .CKO( RNG2_OUT  ) );
    rng_osc #(.KHz(596))   u3 ( .EN(EN), .CKO( RNG3_OUT  ) );
    rng_osc #(.KHz(630))   u4 ( .EN(EN), .CKO( RNG4_OUT  ) );
    rng_osc #(.KHz(552))   u5 ( .EN(EN), .CKO( RNG5_OUT  ) );
    rng_osc #(.KHz(603))   u6 ( .EN(EN), .CKO( RNG6_OUT  ) );
    rng_osc #(.KHz(647))   u7 ( .EN(EN), .CKO( RNG7_OUT  ) );
    rng_osc #(.KHz(698))   u8 ( .EN(EN), .CKO( RNG8_OUT  ) );
`endif

endmodule

module RNGCELL_BUF ( A, Z );
    input wire A;
    output wire Z;

`ifdef SYN
    `ifdef SC9T_TSMC
//        CKBD4BWP35P140 u1 (.I(A),.Z(Z));
//		BUFFD0BWP40P140HVT u( .I(A), .Z(Z) );;
//		DEL075MD1BWP40P140HVT
		DEL075MD1BWP40P140HVT u( .I(A), .Z(Z) );
    `endif
`else

	localparam real DELAY = 0.5;
	real thedelay = 0;
	real rndfactorint = 0;
	logic Zreg;
	assign Z = Zreg;

	initial begin
		rndfactorint = $random();
		thedelay = (rndfactorint / ( 2**31 ))*DELAY;
		if(thedelay<0) thedelay = thedelay * -1;
//		#( thedelay ) Zreg = A;
	end

	always@(*)begin
//		rndfactorint = $random();
//		thedelay = (rndfactorint / ( 2**31 ))*DELAY;
//		if(thedelay<0) thedelay = thedelay * -1;
		#( thedelay ) Zreg = A;
//		#( 0.3 ) Zreg = A;
	end

`endif

endmodule : RNGCELL_BUF

`ifdef RNGCELL_SIM

module rng_cell_tb ();
    bit clk,resetn;
    integer i, j, k, errcnt, warncnt;
	wire        IN_0P1U;
	logic [2:0] SEL = '1;
	logic       EN = '1;

	logic [7:0] rngclklf, rngsrc_dat;
	logic 		rngclkhf;
    logic rngsrc_datx;
    logic [64:0] rngchain;
    logic rngclkhfxor;

    RNG_CELL osclf(
        .IN_0P1U    (),
        .SEL        ,
        .EN         ,
        .RNG1_OUT   (rngclklf[0]),
        .RNG2_OUT   (rngclklf[1]),
        .RNG3_OUT   (rngclklf[2]),
        .RNG4_OUT   (rngclklf[3]),
        .RNG5_OUT   (rngclklf[4]),
        .RNG6_OUT   (rngclklf[5]),
        .RNG7_OUT   (rngclklf[6]),
        .RNG8_OUT   (rngclklf[7])
    );
    OSC_SIM #(.PERIOD(/*1000000/698*/31.333))   u8 ( .EN('1), .CFG('0),      .CKO( rngclkhf  ) );

    assign rngchain[0] = rngclkhf;
	genvar gvi;
    generate
    	for ( gvi = 0; gvi < 64; gvi++) begin: gbuf
		    RNGCELL_BUF u( .A(rngchain[gvi]), .Z(rngchain[gvi+1]));
    	end
    endgenerate
    assign rngclkhfxor = ^rngchain;

    `theregfull( rngclklf[0], resetn, rngsrc_dat[0], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[1], resetn, rngsrc_dat[1], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[2], resetn, rngsrc_dat[2], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[3], resetn, rngsrc_dat[3], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[4], resetn, rngsrc_dat[4], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[5], resetn, rngsrc_dat[5], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[6], resetn, rngsrc_dat[6], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[7], resetn, rngsrc_dat[7], '0 ) <= rngclkhfxor;

    assign rngsrc_datx = ^rngsrc_dat;

  //
  //
  //  monitor and clk
  //  ==

    `genclk( clk, 100 )
    `timemarker2

  //
  //  subtitle
  //  ==

    `maintest(rng_cell_tb,rng_cell_tb)
        #105 resetn = 1;


		#( 3 `MS );
    `maintestend

endmodule

`endif
`ifdef SIM
module rng_osc #(
	parameter shortreal KHz = 500,
	parameter shortreal LTCYCCNT = 1000,
	parameter shortreal FASTJIT_RATE = 0.01
)(
	input logic EN,
	output logic CKO
);

	localparam shortreal PERIOD = 1000000 / KHz;
	localparam shortreal PERIOD0 = 1000000 / ( KHz + 0.001 );
	real theperiod=0, slowjitter_cyc=0, fastjitter_cyc=0, rndfactor=0, pmperiod = PERIOD, pmperiod0 = PERIOD0, delta, slowjitter_step;
	logic [31:0] cyccnt = 0;
	logic cyccnt0 = 0;
	real rndfactorint = 0;
	initial begin
		CKO = 0;
		theperiod = 0;
		slowjitter_cyc = 0;
		fastjitter_cyc = 0;
		cyccnt = 0;
		while(1)begin
			pmperiod = PERIOD;
			pmperiod0 = PERIOD0;
			delta = ( PERIOD - PERIOD0 )   / LTCYCCNT ;
			rndfactorint = $random(); // 2**32;
			rndfactor = rndfactorint / ( 2**31 );
			slowjitter_step = cyccnt;
			slowjitter_cyc = delta * slowjitter_step ;
			theperiod = PERIOD + slowjitter_cyc + fastjitter_cyc;
			fastjitter_cyc = PERIOD * FASTJIT_RATE * rndfactor;
			#( theperiod ) CKO = EN & ~CKO;
			cyccnt = ( cyccnt == LTCYCCNT ) ? 0 : cyccnt + 1;
			cyccnt0 =  ( cyccnt == LTCYCCNT ) ^ cyccnt0;
		end
	end


endmodule
`endif