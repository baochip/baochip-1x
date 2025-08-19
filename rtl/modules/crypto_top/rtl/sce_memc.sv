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

import scedma_pkg::*;

module sce_memc #(
    parameter AW = 14,
    parameter SEGCNT = 32,
    parameter INCNT  = 8,
    parameter RAMCNT = 4,
    parameter FFCNT = 6,
    parameter segcfg_t [0:SEGCNT-1] SEGCFGs = '0,
    parameter sramcfg_t [0:RAMCNT-1] RAMCFGs = '0
)(
    input   bit             clk,
    input   bit             resetn,

// fifo ctrl/status
    input   bit        [0:FFCNT-1]     segfifoen,
    input   bit        [0:FFCNT-1]     segfifoclr,
    output  adr_t      [0:FFCNT-1]     segfifocnt,
    output  bit        [0:FFCNT-1][3:0]segfifosr,

// chnl port
//    input   porttype_e [0:INCNT-1]      porttype,
    input   chnlreq_t  [0:INCNT-1]      ramsreq,
    output  chnlres_t  [0:INCNT-1]      ramsres,

// ram port
    output  adr_t      [0:RAMCNT-1]     ramm_addr,
    output  bit        [0:RAMCNT-1]     ramm_rd,
    output  bit        [0:RAMCNT-1]     ramm_wr,
    output  dat_t      [0:RAMCNT-1]     ramm_wdat,
    input   dat_t      [0:RAMCNT-1]     ramm_rdat,

    output  bit        [7:0]            intr
);

    logic [0:INCNT-1][7:0] thesegid;
    logic [0:INCNT-1][7:0] theramsel;
    porttype_e [0:INCNT-1]      porttype;
    adr_t [0:INCNT-1] ramsegaddr;
    logic [0:INCNT-1] ramrd0, ramwr0, theramselreg;
    adr_t [0:INCNT-1] ramptr0;
    dat_t [0:INCNT-1] ramwdat;
    logic [0:INCNT-1] arbs_vld;
    arbdat_t [0:INCNT-1] arbs_dat;
    logic   [0:SEGCNT-1][0:INCNT-1] fo_rd_2d, fi_wr_2d;
    logic   [0:SEGCNT-1]    ffen, ffclr, fo_rd, fi_wr, fi_full, fi_almf, fo_empt, fo_alme ;
    adr_t   [0:SEGCNT-1]    ffcnt, fframptr;
    logic   [0:SEGCNT-1][7:0] ffint, ffid;
    logic       [0:RAMCNT-1][0:INCNT-1]     arbs_req_2d, arbs_gnt_2d;
    arbdat_t    [0:RAMCNT-1][0:INCNT-1]     arbs_dat_2d;
    logic       [0:RAMCNT-1]                arbm_req, arbm_gnt;
    arbdat_t    [0:RAMCNT-1]                arbm_dat;
    bit        [0:FFCNT-1]     segfifo_full;
    bit        [0:FFCNT-1]     segfifo_almf;
    bit        [0:FFCNT-1]     segfifo_empt;
    bit        [0:FFCNT-1]     segfifo_alme;

// rams chnl
// ■■■■■■■■■■■■■■■
    genvar  gvi, gvj, gvk;
    generate
        for(gvi=0; gvi<INCNT; gvi++) begin : genRAMSEG

        // extract seg cfg, static during trans
        assign thesegid[gvi]   = ramsreq[gvi].segcfg.segid;
        assign theramsel[gvi]  = ramsreq[gvi].segcfg.ramsel;
        assign ramsegaddr[gvi] = ramsreq[gvi].segaddr;
        assign ramwdat[gvi] = ramsreq[gvi].segwdat;
        assign porttype[gvi] = ramsreq[gvi].porttype;
        // if fifo is enabled, only when fifo is valid
        assign ramrd0[gvi]  = ffen[thesegid[gvi]] ? ramsreq[gvi].segrd & ~fo_empt[thesegid[gvi]] : ramsreq[gvi].segrd;
        assign ramwr0[gvi]  = ffen[thesegid[gvi]] ? ramsreq[gvi].segwr & ~fi_full[thesegid[gvi]] : ramsreq[gvi].segwr;
        assign ramptr0[gvi] = ffen[thesegid[gvi]] ? fframptr[thesegid[gvi]]                      : ramsreq[gvi].segptr;

        // if fifo is enabled, only when fifo is valid
        assign ramsres[gvi].segready = arbs_gnt_2d[theramsel[gvi]][gvi] &
                                     ( ffen[thesegid[gvi]] ?
                                             (( porttype[gvi] == PT_RO ) & ~fo_empt[thesegid[gvi]])
                                            |(( porttype[gvi] == PT_WO ) & ~fi_full[thesegid[gvi]])
                                            : 1'b1 ) ;
        assign ramsres[gvi].segrdatvld = 1'b1;

        // rdat only need to
        `theregrn( theramselreg[gvi] ) <= theramsel[gvi];
        assign ramsres[gvi].segrdat = ramm_rdat[theramselreg[gvi]];

        // output for arb, axi style
        assign arbs_vld[gvi] = ramrd0[gvi] | ramwr0[gvi];
        assign arbs_dat[gvi] = '{
                    segaddr:    ramsegaddr[gvi],
                    segptr:     ramptr0[gvi],
                    ramrd:      ramrd0[gvi],
                    ramwr:      ramwr0[gvi],
                    ramwdat:    ramwdat[gvi]
                 };
        end
    endgenerate
// fifo
// ■■■■■■■■■■■■■■■
    localparam bit [0:FFCNT-1][7:0] FFIDS = scedma_pkg::FFIDS;
    generate
        for(gvj=0; gvj<FFCNT; gvj++) begin : genFF
                assign segfifosr[gvj][3] = segfifo_full[gvj];
                assign segfifosr[gvj][2] = segfifo_almf[gvj];
                assign segfifosr[gvj][1] = segfifo_empt[gvj];
                assign segfifosr[gvj][0] = segfifo_alme[gvj];

                assign segfifocnt[gvj] = ffcnt[FFIDS[gvj]];
                assign segfifo_full[gvj] = fi_full[FFIDS[gvj]];
                assign segfifo_almf[gvj] = fi_almf[FFIDS[gvj]];
                assign segfifo_empt[gvj] = fo_empt[FFIDS[gvj]];
                assign segfifo_alme[gvj] = fo_alme[FFIDS[gvj]];
        end
        for(gvj=0; gvj<SEGCNT; gvj++) begin : genSEG
        if(SEGCFGs[gvj].isfifo) begin: genisfifo
            always_comb begin
                ffid[gvj] = SEGCFGs[gvj].fifoid;

                ffen[gvj]  = SEGCFGs[gvj].isfifo & segfifoen[ffid[gvj]];
                ffclr[gvj] = SEGCFGs[gvj].isfifo & segfifoclr[ffid[gvj]];

            end
            for(gvi=0; gvi<INCNT; gvi++) begin : genIN
                assign fo_rd_2d[gvj][gvi] = ( theramsel[gvi] == SEGCFGs[gvj].ramsel ) & (thesegid[gvi]==gvj) & ramrd0[gvi] ;
                assign fi_wr_2d[gvj][gvi] = ( theramsel[gvi] == SEGCFGs[gvj].ramsel ) & (thesegid[gvi]==gvj) & ramwr0[gvi] ;
            end

            assign fo_rd[gvj] = |fo_rd_2d[gvj];
            assign fi_wr[gvj] = |fi_wr_2d[gvj];

                scedma_simplefifo #(
                )segff(
                    /* input   bit           */  .clk           (clk            ),
                    /* input   bit           */  .resetn        (resetn         ),
                    /* input   scefifocfg_t  */  .thecfg        (SEGCFGs[gvj]   ),
                    /* input   bit           */  .ffen          (ffen[gvj]      ),
                    /* input   bit           */  .ffclr         (ffclr[gvj]     ),
                    /* output [AW:0]         */  .ffcnt         (ffcnt[gvj]     ),
                    /* input   bit           */  .fi_wr         (fi_wr[gvj]     ),    // fifo in write
                    /* output  bit           */  .fi_full       (fi_full[gvj]   ),    // fifo in full
                    /* output  bit           */  .fi_almf       (fi_almf[gvj]   ),    // fifo in almost full
                    /* input   bit           */  .fo_rd         (fo_rd[gvj]     ),   // fifo out read, should be pulse
                    /* output  bit           */  .fo_empt       (fo_empt[gvj]   ),   // fifo out empty
                    /* output  bit           */  .fo_alme       (fo_alme[gvj]   ),   // fifo out almost empty
                    /* output  bit [RAW-1:0] */  .ramptr        (fframptr[gvj]  ),
                    /* output  bit [7:0]     */  .intr          (ffint[gvj]     )
                );
            end
        else begin: gennotfifo
                assign ffen[gvj] = '0;
                assign ffclr[gvj] = '0;
                assign ffid[gvj] = '0;
                assign ffcnt[gvj] = '0;
                assign { fi_full[gvj], fi_almf[gvj], fo_empt[gvj], fo_alme[gvj] } = '0;
                assign fframptr[gvj] = '0;
                assign ffint[gvj] = '0;
                assign fo_rd_2d[gvj] = '0;
                assign fi_wr_2d[gvj] = '0;
                assign fo_rd[gvj] = '0;
                assign fi_wr[gvj] = '0;
            end
        end
    endgenerate

// fifo
// ■■■■■■■■■■■■■■■

    generate
        for(gvk=0; gvk<RAMCNT; gvk++) begin : genRAM
        rr_arb_tree #(
          .NumIn    ( INCNT         ),
          .DataType ( arbdat_t      ),
          .AxiVldRdy( 1'b1          ),
          .LockIn   ( 1'b1          )
        ) i_aw_arbiter (
          .clk_i  ( clk             ),
          .rst_ni ( resetn          ),
          .flush_i( 1'b0            ),
          .rr_i   ( '0              ),
          .req_i  ( arbs_req_2d[gvk]        ),
          .gnt_o  ( arbs_gnt_2d[gvk]        ),
          .data_i ( arbs_dat_2d[gvk]        ),
          .req_o  ( arbm_req[gvk]           ),
          .gnt_i  ( arbm_gnt[gvk]           ),
          .data_o ( arbm_dat[gvk]           ),
          .idx_o  (                         )
        );

        for(gvi=0; gvi<INCNT; gvi++) begin : genRAMSEG
            assign arbs_req_2d[gvk][gvi] = ( theramsel[gvi] == gvk ) & arbs_vld[gvi] ;
            assign arbs_dat_2d[gvk][gvi] = arbs_dat[gvi];
        end

        assign arbm_gnt[gvk] = 1'b1;
        assign ramm_addr[gvk] = arbm_dat[gvk].segaddr + arbm_dat[gvk].segptr;
        assign ramm_rd[gvk] = arbm_dat[gvk].ramrd;// | arbm_dat[gvk].ramwr;
        assign ramm_wr[gvk] =  arbm_dat[gvk].ramwr;
        assign ramm_wdat[gvk] = arbm_dat[gvk].ramwdat;

        end
    endgenerate

endmodule : sce_memc
