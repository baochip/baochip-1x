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

module scedmachnl_ahbs #(
    parameter CHID = 0,
    parameter AW = scedma_pkg::AW,
    parameter DW = scedma_pkg::DW,
    parameter FFCNT = scedma_pkg::FFCNT,
    parameter adr_t BA = 0,
    parameter SEGCNT  = scedma_pkg::SEGCNT,
    parameter segcfg_t [0:SEGCNT-1] SEGCFGS = scedma_pkg::SEGCFGS
)(
    input logic clk,
    input logic resetn,

    ahbif.slave ahbs,

    input bit [4:0]         cr_opt,
    input bit [0:FFCNT-1]   segfifoen,

    output chnlreq_t        rpreq,
    input  chnlres_t        rpres,
    output chnlreq_t        wpreq,
    input  chnlres_t        wpres,

    output bit [7:0]        intr,
    output bit [7:0]        err

);

    localparam segcfg_t SEGCFG_NULL =
            '{
                segid: '0,
                segtype: ST_NONE,
                ramsel: '0,
                segaddr: '0,
                segsize: 'd4,
                isfifo: '0,
                isfifostream: '0,
                fifoid: '0
            };

    logic ahbs_cpvld, ahbs_dpvld, ahbshwrite_dp;
    adr_t ahbshaddr_local, ahbshaddr_dp;
    logic [7:0] ahbs_segid;
    segcfg_t ahbs_segcfg, ahbs_segcfgreg;
    logic chnli_start, chnlo_start;
    logic chnli_busy, chnlo_busy;
    logic chnli_done, chnlo_done;
    chnlreq_t ahbsrpreq, ahbswpreq;
    chnlres_t ahbsrpres, ahbswpres;
    chnlcfg_t chnli_thecfg, chnlo_thecfg;
    logic [7:0] chnli_intr, chnlo_intr;
    logic [2:0] cr_ahbwropt_ltx;
    logic cr_ahbwropt_xor;
    logic cr_ahbrdopt_ltx;
    logic ahbs_segvld;

// cr_opt
// ■■■■■■■■■■■■■■■

    assign cr_ahbwropt_ltx = cr_opt[2:0];
    assign cr_ahbwropt_xor = cr_opt[3];
    assign cr_ahbrdopt_ltx = cr_opt[4];

// ahb
// ■■■■■■■■■■■■■■■

    assign ahbs_cpvld = ahbs.hsel & ahbs.hreadym & ahbs.htrans[1] & ahbs.hready & ahbs_segvld;

    `theregrn( ahbs_dpvld ) <= ahbs_cpvld ? 1'b1 : ahbs.hready ? 1'b0 : ahbs_dpvld;
    `theregrn( ahbshwrite_dp ) <= ahbs_cpvld ? ahbs.hwrite : ahbshwrite_dp;

    assign ahbs.hready = ahbs_dpvld ? ( ahbshwrite_dp ? chnli_done : chnlo_done ) : 1'b1;
    assign ahbs.hresp = '0;
    assign ahbs.hrdata = rpres.segrdat;

    assign ahbshaddr_local = ( ahbs.haddr - BA ) >> 2;
    `theregrn( ahbshaddr_dp ) <= ahbs_cpvld ? ahbshaddr_local : ahbshaddr_dp;

    scedmachnl_addr2seg #(.SEGCNT(SEGCNT),.SEGCFGS(SEGCFGS)) ut( .addr(ahbshaddr_local), .segvld( ahbs_segvld ), .segid( ahbs_segid ));

    assign ahbs_segcfg = '{
                            segid:          ahbs_segid,
                            segtype:        SEGCFGS[ahbs_segid].segtype,
                            ramsel:         SEGCFGS[ahbs_segid].ramsel,
                            segaddr:        ( SEGCFGS[ahbs_segid].isfifo & segfifoen[SEGCFGS[ahbs_segid].fifoid] ) ? SEGCFGS[ahbs_segid].segaddr : ahbshaddr_dp,
//                            segaddr:        ahbshaddr_dp,
                            segsize:        'd4,
                            isfifo:         SEGCFGS[ahbs_segid].isfifo,
                            isfifostream:   SEGCFGS[ahbs_segid].isfifostream,
                            fifoid:         SEGCFGS[ahbs_segid].fifoid
                        };

    `theregrn( ahbs_segcfgreg ) <= ahbs_segcfg;

// chnl
// ■■■■■■■■■■■■■■■

    assign chnli_start = ahbs_cpvld &  ahbs.hwrite;
    assign chnlo_start = ahbs_cpvld & ~ahbs.hwrite;

    assign ahbsrpres.segready = 1'b1;
    assign ahbsrpres.segrdat = ahbs.hwdata;
    assign ahbsrpres.segrdatvld = 1'b1;
    assign ahbswpres.segready = 1'b1;
    assign ahbswpres.segrdat = '0;
    assign ahbswpres.segrdatvld = 1'b1;

// chnl
// ■■■■■■■■■■■■■■■
    logic [7:0] chnli_wpffid;
    assign chnli_wpffid = ahbs_segcfgreg.fifoid;

    assign chnli_thecfg.chnlid = 'd0 + CHID;
    assign chnli_thecfg.rpsegcfg = SEGCFG_NULL;
    assign chnli_thecfg.wpsegcfg = ahbs_segcfgreg;
    assign chnli_thecfg.rpptr_start = '0;
    assign chnli_thecfg.wpptr_start = '0; //
    assign chnli_thecfg.wpffen = segfifoen[chnli_wpffid] & ahbs_segcfgreg.isfifo;
    assign chnli_thecfg.transsize = 'd1;
    assign chnli_thecfg.opt_ltx = cr_ahbwropt_ltx | '0;
    assign chnli_thecfg.opt_xor = cr_ahbwropt_xor;
    assign chnli_thecfg.opt_cmpp = '0;
    assign chnli_thecfg.opt_prm = '0;

    assign chnlo_thecfg.chnlid = 'd1 + CHID;
    assign chnlo_thecfg.rpsegcfg = ahbs_segcfg;
    assign chnlo_thecfg.wpsegcfg = SEGCFG_NULL;
    assign chnlo_thecfg.rpptr_start = '0; //
    assign chnlo_thecfg.wpptr_start = '0;
    assign chnlo_thecfg.wpffen = 'd0;
    assign chnlo_thecfg.transsize = 'd1;
    assign chnlo_thecfg.opt_ltx = cr_ahbrdopt_ltx  | '0;
    assign chnlo_thecfg.opt_xor = '0;
    assign chnlo_thecfg.opt_cmpp = '0;
    assign chnlo_thecfg.opt_prm = '0;

    scedma_chnl  #(.TCW(2),.DW(DW))chnli(
        .clk,
        .resetn,
        .thecfg   (chnli_thecfg),
        .start    (chnli_start),
        .busy     (chnli_busy),
        .done     (chnli_done),
        .rpreq    (ahbsrpreq ),
        .rpres    (ahbsrpres ),
        .wpreq    (wpreq    ),
        .wpres    (wpres    ),
        .intr     (chnli_intr )
    );
    scedma_chnl  #(.TCW(2),.DW(DW))chnlo(
        .clk,
        .resetn,
        .thecfg   (chnlo_thecfg),
        .start    (chnlo_start),
        .busy     (chnlo_busy),
        .done     (chnlo_done),
        .rpreq    (rpreq    ),
        .rpres    (rpres    ),
        .wpreq    (ahbswpreq ),
        .wpres    (ahbswpres ),
        .intr     (chnlo_intr )
    );

    assign intr = chnli_intr | chnlo_intr;
    assign err = '0;

endmodule

module scedmachnl_axim  #(
    parameter CHID = 0,
    parameter PM_AXID = 'h5,
    parameter AW = scedma_pkg::AW,
    parameter DW = scedma_pkg::DW,
    parameter FFCNT = scedma_pkg::FFCNT,
    parameter adr_t BA = 0,
    parameter SEGCNT  = scedma_pkg::SEGCNT,
    parameter segcfg_t [0:SEGCNT-1] SEGCFGS = scedma_pkg::SEGCFGS,
    parameter TRANSCNTW = 16
)(
    input logic clk,
    input logic resetn,

    axiif.master axim,
    input   bit [1:0]      scemode,

    output chnlreq_t       rpreq,
    input  chnlres_t       rpres,
    output chnlreq_t       wpreq,
    input  chnlres_t       wpres,

    input   bit             start,
    output  bit             busy,
    output  bit             done,
    input   bit [0:FFCNT-1] segfifoen,

    input   bit             cr_func,
    input   bit [9:0]       cr_opt,
    input   bit [31:0]      cr_axaddrstart,
    input   bit [7:0]       cr_segid,
    input   adr_t           cr_segptrstart,
    input   bit[TRANSCNTW-1:0] cr_transize,

    input   bit             wdatabypass_mode,
    input   bit [DW-1:0]    wdatabypass_data,

    output bit [7:0]        intr,
    output bit [7:0]        err

);
    localparam PM_AXSIZE = 'h2;
    localparam PM_BURST = 'h1;
    localparam PM_PROT = 'h2;
            // [0] 1:priviledged
            // [1] 0:secure access
            // [2] 0:data | 1:instr
    logic [2:0] cr_axiwropt_ltx;
    logic cr_axiwropt_xor;
    logic cr_axirdopt_ltx;
    logic startr, startw, transdone;
    logic [31:0] aximprt;
    logic axunmask, wlast;
    logic [2:0] axlen;
    logic rvld, arrdy, arcp, ardp;
    chnlreq_t aximrpreq, aximwpreq;
    chnlres_t aximrpres, aximwpres;
    logic aximwpreq_segwrreg, aximwpreq_segwrrise, awrdy, awcp, awcpreg;
    logic wrdy, wcp, wcpreg;
    logic awcpext0, awcpext1;
    logic chnli_start, chnlo_start;
    logic chnli_busy, chnlo_busy;
    logic chnli_done, chnlo_done;
    segcfg_t axim_segcfg, axim_segcfgreg;
    chnlcfg_t chnli_thecfg, chnlo_thecfg;
    logic [7:0] chnli_intr, chnlo_intr;
    bit [2:0]       cr_axlen; // 0:single, 1:AxLen
    bit [2:0] cr_axprot;
    localparam segcfg_t SEGCFG_NULL =
            '{
                segid: '0,
                segtype: ST_NONE,
                ramsel: '0,
                segaddr: '0,
                segsize: 'd4,
                isfifo: '0,
                isfifostream: '0,
                fifoid: '0
            };
    localparam segcfg_t SEGCFG_DEF =
            '{
                segid: '0,
                segtype: ST_NONE,
                ramsel: '0,
                segaddr: '0,
                segsize: 'd256,
                isfifo: '0,
                isfifostream: '0,
                fifoid: '0
            };
/*
    segcfg_t segcfg_def;
    assign segcfg_def = '{
                segid: cr_segid,
                segtype: ST_NONE,
                ramsel: '0,
                segaddr: '0,
                segsize: 'd256,
                isfifo: '0,
                isfifostream: '0,
                fifoid: '0
            };
*/
// cr_opt
// ■■■■■■■■■■■■■■■

    bit mode_non;
    bit mode_xls;
    bit mode_sec;

    assign mode_non = ( scemode == 0 );
    assign mode_xls = ( scemode == 1 );
    assign mode_sec = ( scemode[1] == 1 );

    assign cr_axiwropt_ltx = cr_opt[2:0]; // axim rd -> sceram wr(rw@xor)
    assign cr_axiwropt_xor = cr_opt[3];   // axim rd -> sceram wr(rw@xor)
    assign cr_axirdopt_ltx = cr_opt[4];   // sceram rd -> axim wr(no xor)
    assign cr_axlen = cr_opt[7:5];
    assign cr_axprot = mode_sec ? cr_opt[9:8]|3'h0 : mode_xls ? 3'h2|cr_opt[8] : 3'h2;

// axim pointer

//    assign start = startr | startw;
    assign startr = ~cr_func & start;
    assign startw =  cr_func & start;

    `theregrn( aximprt ) <= start ? '0 : transdone ? aximprt + 1 : aximprt;
    assign transdone = ardp & rvld | aximwpres.segready ;

// axim unmask

    assign axunmask =   ( cr_axlen == 0 ) ? '1 :                          // 1
                        ( cr_axlen == 1 ) ? ( aximprt[0] == '0 ) :        // 2
                        ( cr_axlen == 2 ) ? ( aximprt[1:0] == '0 ) :      // 4
                                            ( aximprt[2:0] == '0 ) ;      // 8

    assign axlen =   ( cr_axlen == 0 ) ? 0 :      // 1
                     ( cr_axlen == 1 ) ? 1 :      // 2
                     ( cr_axlen == 2 ) ? 3 :      // 4
                                         7 ;      // 8

    assign wlast =   ( cr_axlen == 0 ) ? '1 :                           // 1
                     ( cr_axlen == 1 ) ? ( aximprt[0] ==   'h1 ) :      // 2
                     ( cr_axlen == 2 ) ? ( aximprt[1:0] == 'h3 ) :      // 4
                                         ( aximprt[2:0] == 'h7 ) ;      // 8

// AR/R chnl

    logic arcpreg0, arcpreg, arcprise;

    assign rvld = axim.rvalid;
    assign arrdy = axunmask ? axim.arready : 'b1;
    assign arcp = aximrpreq.segrd;

    `theregrn( ardp ) <= arcp & arrdy ? 1'b1 : ardp & rvld ? 1'b0 : ardp;

    `theregrn( aximrpres.segrdat ) <= aximrpres.segready ? axim.rdata : aximrpres.segrdat;

    assign arcprise = arcp & ~arcpreg0;
    `theregrn( arcpreg0 ) <= arcp;
    `theregrn( arcpreg ) <= arcp & arrdy ? 'b0 : arcprise ? 'b1 : arcpreg;

    assign aximrpres.segready = rvld;
    assign aximrpres.segrdatvld = '1;//axim.rvalid & ardp;
//    assign aximrpres.segrdat  = axim.rdata;

// AW/W/B chnl

    `theregrn( aximwpreq_segwrreg ) <= aximwpreq.segwr;
    assign aximwpreq_segwrrise = aximwpreq.segwr & ~aximwpreq_segwrreg;

    assign awrdy = axunmask ? axim.awready : 'b1;
    assign awcp = aximwpreq_segwrrise | awcpreg;
//    `theregrn( awcpreg ) <= awcp & awrdy ? 'b0 : aximwpreq.segwr ? 'b1 : awcpreg;
    `theregrn( awcpreg ) <= awcp & awrdy ? 'b0 : aximwpreq_segwrrise ? 'b1 : awcpreg;

    assign wrdy = axim.wready;
    assign wcp = aximwpreq_segwrrise | wcpreg;
    `theregrn( wcpreg ) <= wcp & wrdy ? 'b0 : aximwpreq_segwrrise ? 'b1 : wcpreg;

    assign awcpext0 = ~awcpreg &  wcpreg;
    assign awcpext1 =  awcpreg & ~wcpreg;

    assign aximwpres.segready = axim.bvalid & axim.bready ;
                                //( awcpext0 &  wcp &  wrdy )|
                                //( awcpext1 & awcp & awrdy );
    assign aximwpres.segrdat = '0;
    assign aximwpres.segrdatvld = '1;

// chnl
// ■■■■■■■■■■■■■■■

    assign chnli_start = startr & ~busy;
    assign chnlo_start = startw & ~busy;

//    assign axim.arvalid = arcp & axunmask;
    assign axim.arvalid = (arcprise | arcpreg) & axunmask;
    assign axim.araddr  = cr_axaddrstart + aximprt *4;
    assign axim.arid    = cr_segid | '0;
    assign axim.arburst = PM_BURST;
    assign axim.arlen   = axlen;
    assign axim.arsize  = PM_AXSIZE;
    assign axim.arlock  = '0;
    assign axim.arcache = '0;
    assign axim.arprot  = cr_axprot|3'h0;
    assign axim.armaster= '0;
    assign axim.arinner = '0;
    assign axim.arshare = '0;
    assign axim.aruser  = PM_AXID | '0;

    assign axim.rready = ardp;

    assign axim.awvalid  = awcp & axunmask;
    assign axim.awaddr   = cr_axaddrstart + aximprt *4;
    assign axim.awid     = cr_segid | '0;
    assign axim.awburst  = PM_BURST;
    assign axim.awlen    = axlen;
    assign axim.awsize   = PM_AXSIZE;
    assign axim.awlock   = '0;
    assign axim.awcache  = '0;
    assign axim.awprot   = cr_axprot|3'h0;
    assign axim.awmaster = '0;
    assign axim.awinner  = '0;
    assign axim.awshare  = '0;
    assign axim.awsparse = '1;
    assign axim.awuser   = PM_AXID | '0;

    assign axim.wvalid = wcp;
    assign axim.wid    = '0;
    assign axim.wlast  = wlast;
    assign axim.wstrb  = '1;
    assign axim.wdata  = wdatabypass_mode ? wdatabypass_data : aximwpreq.segwdat;
    assign axim.wuser  = '0;

    assign axim.bready = '1;

// chnl
// ■■■■■■■■■■■■■■■

    assign axim_segcfg = cr_segid < SEGCNT ? SEGCFGS[cr_segid] : SEGCFG_DEF;
    `theregrn( axim_segcfgreg ) <= axim_segcfg;

    logic [7:0] chnli_wpffid;
    assign chnli_wpffid = axim_segcfgreg.fifoid;

    assign chnli_thecfg.chnlid = 'd0 + CHID;
    assign chnli_thecfg.rpsegcfg = SEGCFG_NULL;
    assign chnli_thecfg.wpsegcfg = axim_segcfgreg;
    assign chnli_thecfg.rpptr_start = '0;
    assign chnli_thecfg.wpptr_start = cr_segptrstart; //
    assign chnli_thecfg.wpffen = segfifoen[chnli_wpffid] & axim_segcfgreg.isfifo;
    assign chnli_thecfg.transsize = cr_transize;
    assign chnli_thecfg.opt_ltx = cr_axiwropt_ltx;
    assign chnli_thecfg.opt_xor = cr_axiwropt_xor;
    assign chnli_thecfg.opt_cmpp = '0;
    assign chnli_thecfg.opt_prm = '0;

    assign chnlo_thecfg.chnlid = 'd1 + CHID;
    assign chnlo_thecfg.rpsegcfg = axim_segcfgreg;
    assign chnlo_thecfg.wpsegcfg = SEGCFG_NULL;
    assign chnlo_thecfg.rpptr_start = cr_segptrstart; //
    assign chnlo_thecfg.wpptr_start = '0;
    assign chnlo_thecfg.wpffen = '0;
    assign chnlo_thecfg.transsize = cr_transize;
    assign chnlo_thecfg.opt_ltx = cr_axirdopt_ltx | '0;
    assign chnlo_thecfg.opt_xor = '0;
    assign chnlo_thecfg.opt_cmpp = '0;
    assign chnlo_thecfg.opt_prm = '0;

    scedma_chnl  #(.TCW(TRANSCNTW),.DW(DW))chnli(
        .clk,
        .resetn,
        .thecfg   (chnli_thecfg),
        .start    (chnli_start),
        .busy     (chnli_busy),
        .done     (chnli_done),
        .rpreq    (aximrpreq ),
        .rpres    (aximrpres ),
        .wpreq    (wpreq    ),
        .wpres    (wpres    ),
        .intr     (chnli_intr )
    );
    scedma_chnl  #(.TCW(TRANSCNTW),.DW(DW))chnlo(
        .clk,
        .resetn,
        .thecfg   (chnlo_thecfg),
        .start    (chnlo_start),
        .busy     (chnlo_busy),
        .done     (chnlo_done),
        .rpreq    (rpreq    ),
        .rpres    (rpres    ),
        .wpreq    (aximwpreq ),
        .wpres    (aximwpres ),
        .intr     (chnlo_intr )
    );

    assign busy = chnli_busy | chnlo_busy;
    assign done = chnli_done | chnlo_done;
    assign intr = chnli_intr | chnlo_intr;
    assign err = '0;

endmodule

module scedmachnl_addr2seg #(
    parameter SEGCNT  = scedma_pkg::SEGCNT,
    parameter segcfg_t [0:SEGCNT-1] SEGCFGS = scedma_pkg::SEGCFGS
)(
    input adr_t addr,
    output logic segvld,
    output logic [7:0] segid
);

    assign segvld = addr < ( SEGCFGS[SEGCNT-1].segaddr + SEGCFGS[SEGCNT-1].segsize );

always_comb begin
    segid = 0;
    for (int i = 0; i < SEGCNT; i++)
    if( addr >= SEGCFGS[i].segaddr && addr < ( SEGCFGS[i].segaddr + SEGCFGS[i].segsize ) )
        segid = i;
end

endmodule

module dummytb_scedma_amba ();

    parameter AW = scedma_pkg::AW;
    parameter DW = scedma_pkg::DW;
    parameter adr_t BA = 0;
    parameter SEGCNT  = scedma_pkg::SEGCNT;
    parameter SEGCFGS = scedma_pkg::SEGCFGS;
    parameter TRANSCNTW = 16;

    logic clk;
    logic resetn;
    bit [9:0]  cr_opt;
     chnlreq_t       rpreq;
     chnlres_t       rpres;
     chnlreq_t       wpreq;
     chnlres_t       wpres;
     bit [7:0]        intr;
     bit [7:0]        err;

    chnlreq_t       rpreqx;
    chnlres_t       rpresx;
    chnlreq_t       wpreqx;
    chnlres_t       wpresx;
     bit             startx;
     bit             busyx;
     bit             donex;
     bit             cr_func;
//     bit [15:0]      cr_opt;
     bit [31:0]      cr_axaddrstart;
     bit [7:0]cr_segid;
     adr_t           cr_segptrstart;
    bit [TRANSCNTW-1:0] cr_transize;
    bit [7:0]        intrx;
    bit [7:0]        errx;
    bit [5:0]        segfifoen;
    ahbif ahbs();
    axiif #(.DW(32),.UW(8)) axim();
    bit [1:0]      scemode;

    bit             wdatabypass_mode;
    bit [DW-1:0]    wdatabypass_data;

scedmachnl_axim u2(
    .rpreq(rpreqx),
    .rpres(rpresx),
    .wpreq(wpreqx),
    .wpres(wpresx),
    .start(startx),
    .busy(busyx),
    .done(donex),
    .intr(intrx),
    .err(errx),
    .*);
scedmachnl_ahbs u1(.cr_opt(cr_opt[4:0]),.*);


endmodule

