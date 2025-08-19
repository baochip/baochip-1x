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

module drng_lfsr#
(
    parameter LFSR_WW = 10,
    parameter LFSR_W = 401,
    parameter LFSR_IW = 1,
    parameter LFSR_OW = 8,

    parameter [LFSR_W-1:0] LFSR_IV = 0,
    parameter [2:0][ LFSR_WW-1:0 ] LFSR_NODE = { 10'd399, 10'd392, 10'd389 }
)(
    input   wire    clk,
    input   wire    resetn,
    input   wire    sen,
    input   wire    swr,
    input   wire  [LFSR_IW-1:0]  sdin,
    output  wire  [LFSR_OW-1:0]  sdout
    );

    reg [LFSR_W-1:0] sdata=LFSR_IV, sdatapre, stap;

    `theregfull( clk, resetn, sdata, LFSR_IV ) <= sen ? ( swr ? ( sdin[LFSR_IW-1] ^ sdata ) : sdatapre ) : sdata ;

    genvar gvi;
    generate
        for( gvi = 0; gvi < LFSR_W -1 ; gvi = gvi + 1) begin: GenRnd
            assign stap[gvi] = ( gvi == LFSR_NODE[0]-1 )|( gvi == LFSR_NODE[1] - 1)|( gvi == LFSR_NODE[2]-1 );
            assign sdatapre[gvi] = sdata[gvi+1] ^ ( sdata[0] & stap[gvi] );
        end
    endgenerate

    assign sdatapre[LFSR_W-1] = sdata[0];

    generate
        for( gvi = 0; gvi < LFSR_OW; gvi = gvi + 1) begin: g1
            assign sdout[gvi] = sdata[(23*gvi*gvi)%LFSR_W];
        end
    endgenerate

//    assign sdout = sdata[LFSR_OW-1:0];

endmodule

`ifdef SIM_DRNG_LFSR
module tb_insauth(
 );

    integer j=0, k=0, errcnt=0, warncnt=0;

    logic clk = 0, resetn = 0;

    drng_lfsr #( .LFSR_W(229),.LFSR_NODE({ 10'd228, 10'd225, 10'd219 }), .LFSR_OW(32), .LFSR_IW(32), .LFSR_IV('h55aa_aa55_5a5a_a5a5) )
        ua( .clk(clk), .sen('1), .resetn(resetn), .swr('0), .sdin('0), .sdout() );

    `genclk( clk, 20 )



    `maintest(tb_insauth,tb_insauth)
        #( 235 ) resetn = 1;
        #( 100 `MS ) ;

    `maintestend


    `timemarker2

    logic [0:15] testforcgu;
    logic [0:15][31:0] testforcgucnt;
    logic [0:15][15:0] testforcgurate;
    logic [9:0] clkcnt;

generate
    for (genvar i = 0; i < 16; i++) begin

    assign testforcgu[i] = ( ua.sdout[7:0] >= i*16);
    `theregrn( testforcgucnt[i] ) <= ( clkcnt == '1 ) ? 0 : testforcgucnt[i] + testforcgu[i] ;
    `theregrn( testforcgurate[i] ) <= ( clkcnt == '1 ) ? testforcgucnt[i] * 100 / clkcnt : testforcgurate[i] ;
    end
endgenerate


    `theregrn( clkcnt ) <= clkcnt + 1;






endmodule : tb_insauth

`endif
