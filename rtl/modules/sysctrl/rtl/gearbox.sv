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

module gearbox#(
parameter DW = 8,
parameter FD0 = 2**(DW-1)-1 )(
	input logic clk,
	input logic resetn,
//	gnumld,
	input logic gnumld,
	input logic [DW-1:0] gnum,
	output logic gen
);

	bit [DW-1:0] gnumreg;
	bit [DW:0] gcnt, gcnt1;
//	logic gnumld;

	`theregfull( clk, resetn, gnumreg, FD0 ) <= gnumld ? gnum : gnumreg;
//	assign gnumld = ( gnumreg != gnum );
	`thereg( gcnt  ) <= gnumld | ( gnumreg == 0 ) ? '0 : gcnt[DW-1:0] + gnumreg + 1;
	`thereg( gen ) <= gcnt >= 2**DW;

endmodule

`ifdef SIMCGUGB
module cgugearboxtb ();

    bit clk,resetn;
    integer i=0, j=0, k=0, errcnt=0, warncnt=0;

	bit gnumld;
    localparam DW = 4;
    bit [DW-1:0]   gnum, gnumreg;
	logic gen;
  //
  //  dut
  //  ==

    gearbox #(DW) dut(.*);


  //
  //  monitor and clk
  //  ==

    `genclk( clk, 10 )
    `timemarker2

    initial forever #(20 `US) gnum = gnum + 1;

  //
  //  subtitle
  //  ==

    initial begin
        #(10 `MS);
    `maintestend

    `maintest(cgugearboxtb,cgugearboxtb)
        #105 resetn = 1; //padresetn = 1;
    
        #(10 `MS);
    `maintestend

    initial resetn = 0;
    initial clk = 0;

    `thereg( gnumreg ) <= gnum;
    `theregrn( gnumld ) <= ( gnumreg != gnum );


endmodule

`endif
