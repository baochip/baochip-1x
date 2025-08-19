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

module cgupll #(
    parameter PREDIV_W  = 5 ,
    parameter FBDIV_W   = 12 ,
    parameter FRAC_W    = 24 ,
    parameter POSTDIV_W0 = 3 ,
    parameter POSTDIV_W1 = 3
)(
    input logic clk,
    input logic resetn,
    input logic cmsatpg,
    input logic setcfg,

    input logic refclk,
    input logic pllen,
    input logic [ PREDIV_W-1   : 0 ] pll_m     ,
    input logic [ FBDIV_W -1   : 0 ] pll_n     ,
    input logic [ FRAC_W-1     : 0 ] pll_f     ,
    input logic                      pll_fen   ,
    input logic [ POSTDIV_W0-1 : 0 ] pll_q00 ,
    input logic [ POSTDIV_W1-1 : 0 ] pll_q10 ,
    input logic [ POSTDIV_W0-1 : 0 ] pll_q01 ,
    input logic [ POSTDIV_W1-1 : 0 ] pll_q11 ,
    input logic [ 1            : 0 ] gvco_bias  ,
    input logic [ 2            : 0 ] cpp_bias   ,
    input logic [ 2            : 0 ] cpi_bias   ,
    output logic clkpll0, clkpll1

);

bit     fracen;
bit     setpd0, setpd1, setcfgpd;

wire                         vcca       ;
wire                         vccdcore   ;
wire                         vssa       ;
wire                         vccdpost   ;

//logic                         refclk     ;
logic                         pd         ;

logic    [ PREDIV_W-1   : 0 ] prediv     ;   // M
logic    [ FBDIV_W -1   : 0 ] fbdiv      ;   // NI
logic    [ FRAC_W-1     : 0 ] frac       ;   // NF
logic    [ POSTDIV_W0-1 : 0 ] postdiv0_0 ;
logic    [ POSTDIV_W1-1 : 0 ] postdiv1_0 ;
logic    [ POSTDIV_W0-1 : 0 ] postdiv0_1 ;
logic    [ POSTDIV_W1-1 : 0 ] postdiv1_1 ;

logic                         dacpd      ;
logic                         dsmpd      ;
logic                         testen     ;
logic    [ 1            : 0 ] testsel    ;

logic                         lock       ;
logic                         clko0      ;
logic                         clko1      ;
logic                         testout    ;

    assign dacpd =fracen;
    assign dsmpd =fracen;
    assign testen =1'b0;
    assign testsel =2'b0;

    assign pd = ~( pllen & setcfgpd );

    INNO_FNPLL_TOP u(.*);

//  Fvco = Fref * NI / M
//  Fvco = Fref * ( NI + NF ) / M



    bit [1:0] lock_syncclk;
    bit       setcfgextlock, setpll;
    bit [7:0] setcfgregs;
    bit [1:0] clko0ensync, clko1ensync;
    logic clko0en, clko1en;

//  ■■■■■■■■■■■■■■■
//     lock
//  ■■■■■■■■■■■■■■■

    `theregfull( clko0, resetn, clko0ensync, '0 ) <= { clko0ensync, setcfgextlock & lock };
    `theregfull( clko1, resetn, clko1ensync, '0 ) <= { clko1ensync, setcfgextlock & lock };

    ICG i0(.CK (clko0), .EN (clko0en), .SE(1'b0), .CKG(clkpll0));
    ICG i1(.CK (clko1), .EN (clko1en), .SE(1'b0), .CKG(clkpll1));

    assign clko0en = clko0ensync[1];
    assign clko1en = clko1ensync[1];

//  ■■■■■■■■■■■■■■■
//     setcfg
//  ■■■■■■■■■■■■■■■


    `theregfull( clk, resetn, lock_syncclk, '0 ) <= { lock_syncclk, lock };
    `theregfull( clk, resetn, setcfgextlock, '1 ) <= setcfg & lock ? 1'b0 : ~lock_syncclk[1] ? 1'b1 : setcfgextlock;

    `theregrn( prediv ) <= setpll ? pll_m : prediv;
    `theregrn( fbdiv )  <= setpll ? pll_n : fbdiv;
    `theregrn( frac )   <= setpll ? pll_f : frac;
    `theregrn( fracen ) <= setpll ? pll_fen : fracen;

    `theregrn( postdiv0_0 ) <= setpll ? pll_q00 : postdiv0_0;
    `theregrn( postdiv1_0 ) <= setpll ? pll_q10 : postdiv1_0;
    `theregrn( postdiv0_1 ) <= setpll ? pll_q01 : postdiv0_1;
    `theregrn( postdiv1_1 ) <= setpll ? pll_q11 : postdiv1_1;

    `theregfull( clk, resetn, setcfgregs, '0 ) <= { setcfgregs, setcfg };

    assign setpll = setcfgregs[6];
    assign setpd0 = setcfgregs[3];
    assign setpd1 = setcfgregs[7];

    `theregfull( clk, resetn, setcfgpd, '1 ) <= setpd0 ? 1'b0 : setpd1 ? 1'b1 : setcfgpd;

endmodule



`ifdef SIMcgupll

module cguplltb();
    bit         clk,resetn;
    integer i,j;

    parameter PREDIV_W  = 5 ;
    parameter FBDIV_W   = 12 ;
    parameter FRAC_W    = 24 ;
    parameter POSTDIV_W0 = 3 ;
    parameter POSTDIV_W1 = 3 ;

     bit cmsatpg = 0;
     bit setcfg;

     bit refclk=0;
     bit pllen=0;
     bit [ PREDIV_W-1   : 0 ] pll_m = 0    ;
     bit [ FBDIV_W -1   : 0 ] pll_n = 0    ;
     bit [ FRAC_W-1     : 0 ] pll_f = 0 ;
     bit                      pll_fen = 0 ;
     bit    [ POSTDIV_W0-1 : 0 ] pll_q00 ;
     bit    [ POSTDIV_W1-1 : 0 ] pll_q10 ;
     bit    [ POSTDIV_W0-1 : 0 ] pll_q01 ;
     bit    [ POSTDIV_W1-1 : 0 ] pll_q11 ;

logic    [ 1            : 0 ] gvco_bias  ;
logic    [ 2            : 0 ] cpp_bias   ;
logic    [ 2            : 0 ] cpi_bias   ;

     logic clkpll0, clkpll1;

    cgupll dut(.*);

    `timemarker
    `genclk( refclk, 20 );
    `genclk( clk, 50 );
    `maintest( cguplltb, cguplltb )
        resetn = 0;
        #( 20 `US );
        resetn = 1;

        #( 20 `US );

        pll_n = 'd1432; pll_m = 'd31;
        pll_q00 = 1; pll_q10 = 0;
        pll_q01 = 7; pll_q11 = 1;
        @(negedge clk); setcfg = 1; @(negedge clk); setcfg = 0;
        #( 1 `US ) pllen = 1;

        #( 100 `US );
        pll_n = 'd1482; pll_m = 'd25;
        pll_q00 = 1; pll_q10 = 0;
        pll_q01 = 7; pll_q11 = 1;
        @(negedge clk); setcfg = 1; @(negedge clk); setcfg = 0;

        #( 100 `US );
        pll_n = 'd1437; pll_m = 'd30;
        pll_q00 = 1; pll_q10 = 2;
        pll_q01 = 7; pll_q11 = 1;
        @(negedge clk); setcfg = 1; @(negedge clk); setcfg = 0;


        #( 100 `US );
        pll_n = 'd1400; pll_m = 'd29;
        pll_q00 = 1; pll_q10 = 2;
        pll_q01 = 6; pll_q11 = 1;
        @(negedge clk); setcfg = 1; @(negedge clk); setcfg = 0;

        #( 100 `US );
//        pll_n = 'd700; pll_m = 'd29;
        pll_q00 = 1; pll_q10 = 2;
        pll_q01 = 6; pll_q11 = 1;
        @(negedge clk); setcfg = 1; @(negedge clk); setcfg = 0;



        #( 1 `MS );
    `maintestend


endmodule
`endif
