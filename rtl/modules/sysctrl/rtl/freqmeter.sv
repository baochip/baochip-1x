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

module freqmeter
 #(
    parameter FW     = 16,
    parameter PRECNT = 4,
    parameter FSCNT  = 4
)(
    input logic                     clk,
    input logic                     cmsatpg,
    input logic                     resetn,
    input logic  [FW-1:0]           interval,
    input logic  [FSCNT-1:0]        clkin,
    output logic [FSCNT-1:0]        fsvld,
    output logic [FSCNT-1:0][FW-1:0]fsfreq
);

// metercnt

    logic [FW:0] meterprecnt , metercnt;
    logic metercnthit, meterprecnthit, metertog;
    assign meterprecnthit = meterprecnt == PRECNT-1;
    assign metercnthit = meterprecnthit & ( metercnt == interval-1 );
    `theregrn( meterprecnt ) <= meterprecnthit ? 0 : meterprecnt + 1;
    `theregrn( metercnt )    <= metercnthit ? 0 : metercnt + meterprecnthit;
    `theregrn( metertog ) <= metertog ^ metercnthit;

    logic [FSCNT-1:0]           tog2fs, fscheck, fsresetn,fsresetnreg;
    logic [FSCNT-1:0][3:0]      togsyncbackregs;
    logic [FSCNT-1:0][FW:0]     fscnt;

    genvar gvi;
generate
    for(gvi=0;gvi<FSCNT;gvi++)begin: genFS
        always@(posedge clkin[gvi] or negedge fsresetn[gvi]) if(~fsresetn[gvi]) tog2fs[gvi] <= '0; else tog2fs[gvi] <= metertog;
        `theregrn(togsyncbackregs[gvi]) <= { togsyncbackregs[gvi], tog2fs[gvi] };
        always@(posedge clkin[gvi] or negedge fsresetn[gvi])
         if(~fsresetn[gvi]) fscnt[gvi] <= '0; else fscnt[gvi] <= fscnt[gvi] + tog2fs[gvi];

        assign fscheck[gvi] = togsyncbackregs[gvi][3] & ~togsyncbackregs[gvi][2];
        assign fsresetn[gvi] = cmsatpg ? resetn : resetn & fsresetnreg[gvi] ;
        `theregrn( fsresetnreg[gvi] ) <= ~( metercnthit & ~metertog );
        `theregrn(fsfreq[gvi]) <= fscheck[gvi] ? fscnt[gvi]/PRECNT : fsfreq[gvi];
        `theregrn(fsvld[gvi])  <= metercnthit & metertog  ? togsyncbackregs[gvi][3] : fsvld[gvi] ;
    end
endgenerate

endmodule : freqmeter


`ifdef SIMFREQMETER

module metertb();

    parameter FW     = 16;
    parameter PRECNT = 4;
    parameter FSCNT  = 4;

    bit                    clk;
    bit                    cmsatpg;
    bit                    resetn;
    bit [FW-1:0]           interval=25;
    bit [FSCNT-1:0]        clkin,clkin0,clkinen='1;
    bit [FSCNT-1:0]        fsvld;
    bit [FSCNT-1:0][FW-1:0]fsfreq;

    `genclk( clkin0[0], 40 );   // osc
    `genclk( clkin0[1], 41 );   // xtal
    `genclk( clkin0[2], 4  );  // clkpll
    `genclk( clkin0[3], 1000  );  // clkpll

    `genclk( clk,    40 );   // osc

    assign clkin = clkin0 & clkinen;


freqmeter  #(
        .FW ( FW ),
        .PRECNT ( PRECNT ),
        .FSCNT ( FSCNT )
    )dut(.*);
/*
//    `timemarker
    integer tmms=0, tmus=0;
    initial forever #( 1 `US ) tmus = ( tmus == 1000 ) ? 0 : tmus + 1 ;
    initial forever #( 1 `MS ) tmms = tmms + 1 ;
    always@( tmms ) $display("------------------------------------[%0dms][%4h][%4h][%4h][%4h][%d]------------------------------------", tmms,
            dut.checkcnt0[1],
            dut.checkcnt0[2],
            dut.checkcnt0[3],
            dut.checkcnt0[4],
            (dut.checkcnt0[4]+dut.checkcnt0[1]+dut.checkcnt0[2]+dut.checkcnt0[3])-
            (dut.checkcnt1[4]+dut.checkcnt1[1]+dut.checkcnt1[2]+dut.checkcnt1[3])
        ) ;
*/
    `ifndef NOFSDB
    initial begin
        #(10 `MS); `maintestend
    `endif

    `maintest( metertb, metertb )
        #( 1`US ); #100 resetn = 1;

        #( 100 `US ); clkinen[0] = 0;
        #( 100 `US ); clkinen[1] = 0;
        #( 100 `US ); clkinen[2] = 0;
        #( 100 `US ); clkinen[3] = 0;

        #( 100 `US ); clkinen[0] = 1;
        #( 100 `US ); clkinen[1] = 1;
        #( 100 `US ); clkinen[2] = 1;
        #( 100 `US ); clkinen[3] = 1;

        #( 100 `US ); clkinen[0] = 0;
        #( 100 `US ); clkinen[1] = 0;
        #( 100 `US ); clkinen[2] = 0;
        #( 100 `US ); clkinen[3] = 0;

        #( 100 `US ); clkinen[0] = 1;
        #( 100 `US ); clkinen[1] = 1;
        #( 100 `US ); clkinen[2] = 1;
        #( 100 `US ); clkinen[3] = 1;

        #( 100 `US ); clkinen[0] = 0;
        #( 100 `US ); clkinen[1] = 0;
        #( 100 `US ); clkinen[2] = 0;
        #( 100 `US ); clkinen[3] = 0;

        #( 100 `US ); clkinen[0] = 1;
        #( 100 `US ); clkinen[1] = 1;
        #( 100 `US ); clkinen[2] = 1;
        #( 100 `US ); clkinen[3] = 1;


        #( 10 `MS );
        #( 100 `US );


        #( 100 `US );

    `maintestend

endmodule


`endif

