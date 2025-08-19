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

module sce_glbsfr #(
	parameter FFCNT = scedma_pkg::FFCNT,
	parameter AW = scedma_pkg::AW,
	parameter SUBCNT = 16,
	parameter SRCNT = 16,
	parameter FRCNT = 16,
	parameter ERRCNT = 16,
    parameter CHNLACCNT = 8,
    parameter TSC = 128
)
(
    input  logic clk, resetn, resetn0, cmsatpg, cmsbist, devmode,

    apbif.slavein           apbs,
    apbif.slave             apbx,

    output logic [1:0] 			cr_scemode,
    output logic [0:SUBCNT-1] 	cr_suben,
    output logic [4:0]			cr_ahbsopt,
    input  logic [0:SRCNT-1]	sr_busy,
    input  logic [0:FRCNT-1]	fr_done,
    input  logic [0:ERRCNT-1]	fr_err,

    output  logic ar_reset,
    output  logic ar_clrram,

    output  logic [0:FFCNT-1] 		cr_ffen,
    input   logic [0:FFCNT-1][3:0] 	sr_ffsr,
    input   adr_t [0:FFCNT-1] 		sr_ffcnt,
    output  logic [0:FFCNT-1]		ar_ffclr,
    input   logic [0:CHNLACCNT-1]   fr_acerr,
    input   logic [TSC-1:0]       sr_ts

);


// apb
// ■■■■■■■■■■■■■■■

	bit [0:FFCNT-1][AW+4-1:0] sr_ff;


// apb
// ■■■■■■■■■■■■■■■

    logic apbrd, apbwr;
    logic pclk;
    logic sfrlock;
    assign pclk = clk;

//    `theregrn( sfrlock ) <= optlock ? 1'b1 : mfsm_done ? '0 : sfrlock;

    `apbs_common;
    assign apbx.prdata = '0
                        | sfr_scemode.prdata32 | sfr_suben.prdata32 | sfr_ahbs.prdata32
                        | sfr_srbusy.prdata32 | sfr_frdone.prdata32 | sfr_frerr.prdata32 | sfr_fracerr.prdata32
                        | sfr_ffen.prdata32 | sfr_ffcnt.prdata32
                        | sfr_tickcyc.prdata32 | sfr_tickcnt.prdata32
                        | sfr_ts.prdata32
                        ;
    apb_cr #(.A('h00), .DW(2))      sfr_scemode     (.cr(cr_scemode), .prdata32(), .sfrlock(~devmode & (|cr_scemode)), .*);
    apb_cr #(.A('h04), .DW(SUBCNT),.IV('h1f)) sfr_suben       (.cr(cr_suben),   .prdata32(),.*);
    apb_cr #(.A('h08), .DW(5))      sfr_ahbs        (.cr(cr_ahbsopt), .prdata32(),.*);

    apb_sr #(.A('h10), .DW(SRCNT))  sfr_srbusy      (.sr(sr_busy), 	  .prdata32(),.*);
    apb_fr #(.A('h14), .DW(FRCNT))  sfr_frdone      (.fr(fr_done), 	  .prdata32(),.*);
    apb_fr #(.A('h18), .DW(ERRCNT)) sfr_frerr       (.fr(fr_err),     .prdata32(),.*);

    apb_ar #(.A('h1c), .AR(32'h5a)) sfr_arrst       (.ar(ar_reset), .*);
    apb_ar #(.A('h1c), .AR(32'ha5)) sfr_arclr       (.ar(ar_clrram), .*);

    apb_fr #(.A('h60), .DW(CHNLACCNT)) sfr_fracerr  (.fr(fr_acerr),      .prdata32(),.*);

// ff

    apb_cr #(.A('h30), .DW(FFCNT), .REVX(1))          sfr_ffen     (.resetn(resetn0),.cr(cr_ffen),  	.prdata32(),.*);
    apb_sr #(.A('h40), .DW(AW+4), .SFRCNT((FFCNT)) )  sfr_ffcnt    (.resetn(resetn0),.sr(sr_ff), 	.prdata32(),.*);

generate
	for (genvar i = 0; i < FFCNT; i++) begin: gg
		assign sr_ff[i] = { sr_ffcnt[i], sr_ffsr[i] };
	    apb_ar #(.A('h34), .AR((32'hff00+i)) )  sfr_ffclr   (.ar(ar_ffclr[i]), 	.*);
	end
endgenerate

    apb_sr #(.A('he0), .DW(32), .SFRCNT(TSC/32))      sfr_ts     (.sr(sr_ts), .prdata32(), .*);


// tick
    bit [7:0] tickcyc, tickcnt0;
    bit tickclr, ticklock, tickhit;
    bit [31:0] tickcnt, tickcntsr;

    logic [SRCNT-1:0]	sr_busyx;
    logic [FRCNT-1:0]	fr_donex;

    assign { sr_busyx, fr_donex } = { sr_busy, fr_done };
    assign tickclr = ~|sr_busyx[4:1];
    assign ticklock = |fr_donex[4:1];
    assign tickhit = ( tickcnt0 == tickcyc );
    `theregrn( tickcnt0 ) <= tickclr | tickhit ? '0 : tickcnt0 + 1;
    `theregrn( tickcnt ) <= tickclr ? '0 : tickcnt + tickhit ;
    `theregrn( tickcntsr ) <= ticklock ? tickcnt : tickcntsr;

    apb_cr #(.A('h20), .DW(8))   sfr_tickcyc    (.cr(tickcyc),    .prdata32(),.*);
    apb_sr #(.A('h24), .DW(32))  sfr_tickcnt    (.sr(tickcntsr),  .prdata32(),.*);


endmodule

module dummytb_sce_glbsfr (
);
	parameter FFCNT = scedma_pkg::FFCNT;
	parameter AW = scedma_pkg::AW;
	parameter SRCNT = 16;
	parameter FRCNT = 16;
	parameter ERRCNT = 16;
	parameter SUBCNT = 16;
    parameter TSC = 128;
    parameter CHNLACCNT = 8;
    bit clk, resetn, resetn0, cmsatpg, cmsbist;
    apbif apbs();
    bit [1:0] 			cr_scemode;
    bit [0:SRCNT-1]	sr_busy;
    bit [0:FRCNT-1]	fr_done;
    bit [0:ERRCNT-1]	fr_err;
     bit ar_reset;
     bit ar_clrram;
     bit [0:FFCNT-1] 		cr_ffen;
     bit [0:FFCNT-1][3:0] 	sr_ffsr;
     adr_t [0:FFCNT-1] 		sr_ffcnt;
     bit [0:FFCNT-1]		ar_ffclr;
    bit [0:SUBCNT-1] 	cr_suben;
    bit [4:0]			cr_ahbsopt;
    logic [0:CHNLACCNT-1]   fr_acerr;
    logic [TSC-1:0]       sr_ts;
    logic devmode;

sce_glbsfr u0(.apbx(apbs),.apbs(apbs),.*);



endmodule

