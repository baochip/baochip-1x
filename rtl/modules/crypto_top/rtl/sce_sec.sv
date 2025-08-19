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


module sce_sec #(
    parameter COREUSERCNT = 8,
    parameter type coreuser_t = bit[0:COREUSERCNT-1]
)(
  	input 	bit 					clk,
    input   bit                     resetn,
    input   bit [1:0]               devmode,
  	input 	bit [1:0] 				scemode,
    input   coreuser_t  coreuser_cm7,
    input   coreuser_t  coreuser_vex,
    output  bit sceusersel,
  	output 	coreuser_t	sceuser,
  	output  bit mode_non,
  	output  bit mode_xls,
  	output  bit mode_sec,

    ahbif.slave  ahbs,
    ahbif.master ahbm,
  	output  bit ahbs_lock,

  	input 	bit ar_reset,
  	input 	bit ar_clrram,
  	output  bit sceresetnin,
  	output  bit sceramclr

);


// mode

    bit [1:0] scemodereg;
    bit sceuserlock, modequit;
    bit [3:0] initregs;
    coreuser_t coreuserreg;
    logic coreuserselreg;
    logic ahbscpvld;

    assign mode_non = ( scemode == 0 );
    assign mode_xls = ( scemode == 1 );
    assign mode_sec = ( scemode[1] == 1 );

    assign sceuserlock = ( scemodereg == 0 ) && ~( scemode == scemodereg ) ;
    `theregrn( scemodereg ) <= scemode;

    `theregrn( {coreuserselreg, coreuserreg} ) <=   ahbscpvld & ( ahbs.hauser == daric_cfg::AMBAID4_CM7P ) ? { 1'b0, coreuser_cm7 } :
                                                    ahbscpvld & ( ahbs.hauser == daric_cfg::AMBAID4_VEXD ) ? { 1'b1, coreuser_vex } : {coreuserselreg, coreuserreg};

    `theregrn( {sceusersel, sceuser} ) <= sceuserlock ? {coreuserselreg, coreuserreg} : {sceusersel, sceuser};

// ahb controrl

    logic ahben;

    assign ahbscpvld = ahbs.hsel & ahbs.htrans[1] & ahbs.hreadym & ahbs.hready ;

    assign ahben =  mode_non ? 1'b1 :
                            ((sceusersel == 0 ) ? ( ahbs.hauser == daric_cfg::AMBAID4_CM7P ) : ( ahbs.hauser == daric_cfg::AMBAID4_VEXD )) &
                            ((sceusersel == 0 ) ? ( coreuser_cm7 == sceuser ) : ( coreuser_vex == sceuser ));

    ahb_gate #(.AW(32),.DW(32)) ahbsgate(.ahben,.ahbslave(ahbs),.ahbmaster(ahbm));
    assign ahbs_lock = devmode[0] ? 1'b0 : ~ahben;

// reset control

    assign modequit = devmode[1] ? '0 : ~( scemodereg == 0 ) && ~( scemode == scemodereg ) ;

	assign sceresetnin = ~( modequit | ar_reset );

	`theregrn( initregs ) <= { initregs, 1'b1 };

	assign sceramclr = ( initregs == 4'h7 ) | ar_clrram ;

endmodule

module sce_ts #(
    parameter COREUSERCNT = 8,
    parameter type coreuser_t = bit[0:COREUSERCNT-1],
    parameter TSC=128
)(
    input   bit                     clk,
    input   bit                     resetn,

    input   bit [1:0]               scemode,

    input logic        hmac_pass, hmac_fail,
    input logic [9:0]  hmac_kid,

    output logic [TSC-1:0] ts
);

    logic mode_non, mode_xls, mode_sec;

    assign mode_non = ( scemode == 0 );
    assign mode_xls = ( scemode == 1 );
    assign mode_sec = ( scemode[1] == 1 );

    logic [TSC-2:0] tsreg;

generate
    for (genvar i = 0; i < TSC-1; i++) begin
    `theregrn( tsreg[i] ) <= ((hmac_kid==i)&mode_sec & hmac_pass) ? 'b1 : ((hmac_kid==i)&mode_sec & hmac_fail) ? 'b0 : tsreg[i];
    end
endgenerate

    // the MSB is always 1.

    assign ts = { 1'b1, tsreg };


endmodule
