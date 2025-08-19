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

module cgufdsync

// 1, fdsync makes clk2 is fixed freq-div to clk0.
// 2, clk2en are sync with clk1en.
// 3, when clk2fd is faster than clk1fd. the actual clk2en equal clk1en.
// 4, clk0 is clk gated by clk0en.

// output clk2en: is used for clk2 icg@clk
// output clk2en_atclk1: is used for clk2 domain for essential reg-ce, e.g., 'penable'.

#(
    parameter FDW = 8,
    parameter FD0 = 2**(FDW-1)-1
)(
    input   bit             clk,
    input   bit             resetn,
    input   bit             clk0en,
    input   bit             clk1en,
    input   bit [FDW-1:0]   fd0,
    input   bit [FDW-1:0]   fd2,
    input   bit             fdload,
    output  bit             clk2en,
    output  bit             clk2en_atclk1
);

    bit [FDW-1:0] fd0reg;
    bit [FDW-1:0] fd2reg;
    logic clk2en0;

    `theregrn( fd0reg ) <= clk0en & fdload ? fd0 : fd0reg;
    `theregrn( fd2reg ) <= clk0en & fdload ? fd2 : fd2reg;

// fd0: lmt

    bit [FDW:0] fd0cnt;
    logic       fd0cnthold, fd0rdy;

    `thereg( fd0cnt ) <= clk0en ?
                            ( clk2en0 | fdload ? '0 : ( fd0cnthold ? fd0cnt : fd0cnt + 1 )) :
                        fd0cnt;
    assign fd0cnthold = ( fd0cnt == fd0reg );
    assign fd0rdy = fd0cnthold;

// fd2: gear

    bit [FDW:0] fd2cnt;
    logic       fd2cnthold, fd2rdy;

    `thereg( fd2cnt ) <= clk0en ?
                            ( fdload ? '0 : fd2cnthold ? fd2cnt : ( fd2cnt[FDW-1:0] + fd2reg[FDW-1:0] + 1 )) :
                        fd2cnt;
    assign fd2cnthold = fd2cnt[FDW] && ~clk2en0;
    assign fd2rdy = fd2cnt[FDW];

// clk1en


    assign clk2en0 = clk0en && clk1en && fd0rdy && fd2rdy;
    `thereg( clk2en_atclk1 ) <= clk0en ? ( fdload ? '0 : ( clk2en0 ? 1'b1 : clk1en ? 1'b0 : clk2en_atclk1 )) : clk2en_atclk1;
    assign clk2en = clk2en_atclk1 & clk1en & clk0en;

endmodule

`ifdef SIMcgufdsynctb
`include "icg.v"
module cgufdsynctb();
    bit         clk,clk1,clk2,resetn,dut1clken,dut2clken;
    bit [3:0]   dut1fd0=0, dut2fd0=3, dut1fd, dut2fd;
    integer     clkcnt=0, dut1clkcnt=0, dut2clkcnt=0, dut1mincycle=0, dut2mincycle=0;
    bit clk0en;
    bit fdload = 0;
    assign clk0en = 1;
    integer i,j;
    cgufdsync #(4) dut1(
        .clk1en  (1'b1),
        .fd0     (dut1fd0),
        .fd2     (dut1fd),
        .clk2en  (dut1clken),
        .clk2en_atclk1(),
        .*
    );

    cgufdsync #(4) dut2(
        .clk1en  (dut1clken),
        .fd0     (dut2fd0),
        .fd2     (dut2fd),
        .clk2en  (dut2clken),
        .clk2en_atclk1(),
        .*
    );

    ICG u1 ( .CK (clk), .EN ( dut1clken ), .CKG ( clk1 ));
    ICG u2 ( .CK (clk), .EN ( dut2clken ), .CKG ( clk2 ));

    `timemarker
    `genclk( clk, 10 );
    `maintest( thetestbasic, cgufdsynctb )
        resetn = 0;
        #( 2 `US );
        resetn = 1;

        #( 1 `US );

        for( i = 0; i < 16; i = i + 1 ) begin
            for( j = 0; j < 16; j = j + 1 ) begin
                dut1fd = i; dut2fd = j;
                @(negedge clk) fdload = 1;@(negedge clk) fdload = 0;
                #( 10 `US );
                $display("@i: fd1:%x(%d), fd2:%x(%d), clkcnt=%d, dut1clkcnt=%d,%d dut2clkcnt=%d,%d .", dut1fd, clkcnt/(dut1fd+1), dut2fd, clkcnt/(dut2fd+1), clkcnt, dut1clkcnt, dut1clkcnt-clkcnt/(dut1fd+1), dut2clkcnt, clkcnt/(dut2fd+1)+1-dut2clkcnt);
                clkcnt = 0; dut1clkcnt = 0; dut2clkcnt = 0;
                dut1mincycle = 1000;
                dut2mincycle = 1000;
            end
        end

        #( 10 `US );
    `maintestend

    `thereg( clkcnt ) <= clkcnt + 1;
    `thereg( dut1clkcnt ) <= dut1clkcnt + dut1clken;
    `thereg( dut2clkcnt ) <= dut2clkcnt + dut2clken;

endmodule
`endif
