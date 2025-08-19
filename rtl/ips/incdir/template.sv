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



  //  simulation
  //  ==

`define US *1000
`define MS *1000000
`ifdef FPGA
    `default_nettype wire
`endif

`ifdef SYN
    `default_nettype wire
`endif

`ifdef SIM
    `default_nettype none
`endif

`ifdef NOFSDB
    `define maintest(dumpfile, tbname) \
        initial \
            begin \
            $display("@I: basic"); \
    
    `define maintestend \
            $finish; \
        end 
`else
    `define maintest(dumpfile, tbname) \
        initial \
            begin \
            $display("@I: basic"); \
            $fsdbDumpfile(`"tbname.dumpfile.fsdb`"); \
            $fsdbDumpvars(0, "+all", tbname); \
            $fsdbDumpflush; \
            $fsdbDumpon; 
    
    `define maintestend \
            $fsdbDumpoff; \
            $finish; \
        end 
`endif


`define timemarker \
    integer tmms=0, tmus=0; \
    initial forever #( 1 `US ) tmus = ( tmus == 1000 ) ? 0 : tmus + 1 ; \
    initial forever #( 1 `MS ) tmms = tmms + 1 ; \
    always@( tmms ) $display("------------------------------------[%0dms]------------------------------------", tmms) ;

`define genclk( theclk, theperiod ) \
    initial forever #(theperiod/2) theclk = ~theclk ;


`define timemarker2 \
    integer tmms=0, tmus=0; \
    initial forever #( 1 `US ) tmus = ( tmus == 1000 ) ? 0 : tmus + 1 ; \
    initial forever #( 1 `MS ) tmms = tmms + 1 ; \
    always@( tmms ) $display("------------------------------------[%0dms][error:%0d][warning:%0d]------------------------------------", tmms, errcnt, warncnt) ;


  //  registers
  //  ==


`define theregfull( theclk, theresetn, theregname, theinitvalue ) \
    always@( posedge theclk or negedge theresetn ) \
    if( ~theresetn) \
        theregname <= theinitvalue; \
    else \
        theregname 
    

`define theregrn(theregname) \
    `theregfull( clk, resetn, theregname, '0 )

`define theregsn(theregname) \
    `theregfull( clk, resetn, theregname, '1 )

`define thereg(theregname) \
    always@( posedge clk ) theregname 


`timescale 1 ns/1 ps

/*
module test();

bit clk,resetn,myreg1,myreg2,myreg3;

`theregfull( clk, resetn, myreg1, 1) <= ~myreg1;
`theregrn( myreg2 ) <= ~myreg2;
`thereg( myreg3 ) <= ~myreg3;




`timemarker
`genclk( clk, 10 );
`maintest( thetestbasic, test )
    resetn = 0;
    #( 2 `US );
    resetn = 1;
    #( 10 `MS );
`maintestend




endmodule
*/
/*
`include "template.sv"

module tb();

    bit clk,resetn;
    integer i, j, k, errcnt, warncnt;

  //
  //  dut
  //  ==

    dutmodule 
    #(
        .pm1(32),
        .pm2(8)
    )
    dut
    (
        .clk    (clk),
        .resetn (resetn),
        
    );
    

  //
  //  monitor and clk
  //  ==

    `genclk( clk, 100 )
    `timemarker2

  //
  //  subtitle
  //  ==

    `maintest(dumpfile,tb)
        #105 resetn = 1;


    
    `maintestend

endmodule

*/




  //  sannity check
  //  ==

  `define checkmax(thename, themaxvalue) \
    initial if(thename>themaxvalue) $display("@W: checkmax thename = %d > themaxvalue !", thename);$stop
