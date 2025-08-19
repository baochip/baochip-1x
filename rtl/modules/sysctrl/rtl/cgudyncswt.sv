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

module cgudyncswt
(
    input   bit             clk0,
    input   bit             clk1,
    input   bit             resetn,
    input   bit             clksel,
    output  bit             clk0en,
    output  bit             clk1en
);
    logic clksel_s00, clksel_s10, clksel_s01, clksel_s11, clksel_s02, clksel_s12 ;

    assign clksel_s00 = clksel;
    assign clksel_s10 = clksel;
    

    cgudyncswt_sync #(.INIT(1'b0)) sync00 ( .clk( clk1 ), .resetn( resetn ), .sin( clksel_s00 ), .sout( clksel_s01 ));
    cgudyncswt_sync #(.INIT(1'b0)) sync01 ( .clk( clk0 ), .resetn( resetn ), .sin( clksel_s01 ), .sout( clksel_s02 ));
    cgudyncswt_sync #(.INIT(1'b0)) sync10 ( .clk( clk0 ), .resetn( resetn ), .sin( clksel_s10 ), .sout( clksel_s11 ));
    cgudyncswt_sync #(.INIT(1'b0)) sync11 ( .clk( clk1 ), .resetn( resetn ), .sin( clksel_s11 ), .sout( clksel_s12 ));
    assign clk0en = ~clksel & ~clksel_s02;
    assign clk1en =  clksel & clksel_s12;

endmodule



module cgudyncswt_sync#(parameter INIT=1'b0)( 
    input   bit     clk,
    input   bit     resetn,
    input   bit     sin,
    output  bit     sout
    );
    
    parameter scnt = 2;
    bit [0:scnt-1]  sreg;
    
`theregfull(clk, resetn, sreg, {scnt{INIT}}) <= { sin, sreg[0:scnt-2] };
    assign sout = sreg[scnt-1];

endmodule

`ifdef SIMcgudyncswt
`include "icg.v"

module cgudyncswttb();

    parameter   dutcnt = 2;
    bit  [0:dutcnt-1] clk0, clk1, clksel, clk0en, clk1en, clk0_icg, clk1_icg, clkout;
    bit             clksel0;

    parameter int cycle0[0:dutcnt-1] = { 14,  6 };
    parameter int cycle1[0:dutcnt-1] = {  6, 10 };

    `genclk( clksel0, 600 );
genvar i;
generate
	for( i = 0; i < dutcnt; i = i + 1) begin: GenRnd
    `genclk( clk0[i], cycle0[i] );
    `genclk( clk1[i], cycle1[i] );
    always@(posedge clkout[i]) clksel[i] <= clksel0;
    cgudyncswt dut1(
        .clk0   (clk0[i]),
        .clk1   (clk1[i]),
        .clksel (clksel[i]),
        .clk0en (clk0en[i]),
        .clk1en (clk1en[i])
    );
    ICG u0 ( .CK (clk0[i]), .EN ( clk0en[i] ), .CKG ( clk0_icg[i] ));
    ICG u1 ( .CK (clk1[i]), .EN ( clk1en[i] ), .CKG ( clk1_icg[i] ));
    assign clkout[i] = clk0_icg[i] | clk1_icg[i];
	end
endgenerate

    `timemarker

    `maintest( thetestbasic, cgudyncswttb )
        #( 1000 `US );
    `maintestend

endmodule
`endif
