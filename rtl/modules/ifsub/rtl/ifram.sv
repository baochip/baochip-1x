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

//`include "rtl/model/artisan_ram_def_v0.1.svh"


module ifram #(
    parameter RC = 1,
    parameter sram_pkg::sramcfg_t thecfg = {
        AW: 17-2,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 2**(17-2),
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    }
    )(

    input logic             clk,
    input logic             resetn,
    input logic             cmsatpg,
    input logic             cmsbist,
    rbif.slave              rbs,
//    input logic             scmben,
    input logic [thecfg.KW-1:0] scmbkey,
    input logic             even,
    output logic            prerr,
    output logic            verifyerr,

    ramif.slave             rams
);

    localparam AW = thecfg.AW;
    localparam DW = thecfg.DW;
    localparam PW = thecfg.PW;
    localparam DW0 = DW+PW;
    localparam BW0 = 9;
    localparam BC  = DW0/BW0;
    localparam RCW = $clog2(RC);
    localparam AW0 = AW-$clog2(RC);

    ramif #(.RAW(AW),.DW(DW0),.BW(BW0)) ram0();
    logic                   rams_ramen      ;
    logic                   rams_ramcs      ;
    logic [AW-1:0]          rams_ramaddr    ;
    logic [DW0/BW0-1:0]     rams_ramwr      ;
    logic [DW0-1:0]         rams_ramwdata   ;
    logic [DW0-1:0]         rams_ramrdata   ;
    logic                   rams_ramready   ;
    logic [RCW-1:0]         bsel, bselreg   ;
    logic [DW0-1:0]         bd              ;
    logic [RC-1:0][DW0-1:0] bq              ;
    logic [RC-1:0]          bcen, bgwen     ;
    logic [RC-1:0][BC-1:0][BW0-1:0]   bwen        ;
//    logic [RC-1:0][DW0/BW0-1:0] bwen        ;
    logic [AW-RCW-1:0]        ba              ;
    logic [RC-1:0]          clkb, clkben    ;

    gnrl_sramc #(.thecfg(thecfg))dut
    (
        .clk,
        .resetn,
        .cmsatpg,
        .cmsbist,
//        .scmben(thecfg.isSCMB),
        .scmben(1'b0),
        .scmbkey,
        .even,
        .prerr,
        .verifyerr,
        .ramslave(rams),
        .rammaster(ram0)
    );

    rams2wire
    #(
        .AW(AW),
        .DW(DW0),
        .BW(BW0)
    )r2w(
        .rams            (ram0            ),
        .rams_ramen      (rams_ramen      ),
        .rams_ramcs      (rams_ramcs      ),
        .rams_ramaddr    (rams_ramaddr    ),
        .rams_ramwr      (rams_ramwr      ),
        .rams_ramwdata   (rams_ramwdata   ),
        .rams_ramrdata   (rams_ramrdata   ),
        .rams_ramready   (rams_ramready   )
    );

    assign bsel = 0;// rams_ramaddr[AW-1:AW-RCW] ;
    `theregrn(bselreg) <= ( rams_ramcs & rams_ramready ) ? bsel : bselreg;
    assign rams_ramready = '1;
    assign rams_ramrdata = bq[bselreg];
    assign #0.5 bd = rams_ramwdata;
    assign #0.5 ba = rams_ramaddr;
generate
    for (genvar i = 0; i < RC; i++) begin: genram

    assign #0.5 bcen[i] = ~( rams_ramcs & (bsel==i) );
    assign #0.5 bgwen[i] =  ~( |rams_ramwr & rams_ramcs & (bsel==i) );
//    assign #0.5 bwen[i]  =  rams_ramcs & (bsel==i) ? ~rams.ramwr : '1;
    logic rb_clkb, rb_bcen, rb_bgwen;
    logic [AW-1:0]  rb_ba;
    logic [DW0-1:0] rb_bq, rb_bwen, rb_bd;

    rbspmux #(.AW(AW),.DW(DW0))rbmux(
         .cmsatpg,
         .cmsbist,
         .rbs         (rbs),
         .clk(clkb[i]),
         .q(bq[i]),
         .cen(bcen[i]),
         .gwen(bgwen[i]),
         .wen(bwen[i]),
         .a(ba),
         .d(bd),
         .rb_clk      (rb_clkb),
         .rb_q        (rb_bq),
         .rb_cen      (rb_bcen),
         .rb_gwen     (rb_bgwen),
         .rb_wen      (rb_bwen),
         .rb_a        (rb_ba),
         .rb_d        (rb_bd)
       );

    ifram32kx36  m (
         .clk         (rb_clkb),
         .q           (rb_bq),
         .cen         (rb_bcen),
         .gwen        (rb_bgwen),
         .wen         (rb_bwen),
         .a           (rb_ba),
         .d           (rb_bd),
        `sram_sp_uhde_inst
         );

    ICG icg(.CK(clk),.EN(clkben[i]),.SE(cmsatpg),.CKG(clkb[i]));
    assign clkben[i] = ~bcen[i] ;

    for (genvar gvj = 0; gvj < BC; gvj++) begin: genwe
        assign bwen[i][gvj] = rams_ramcs & (bsel==i) & rams_ramwr[gvj] ? '0 : '1;
    end

    end
endgenerate

endmodule

module dummytb_ifram();

    parameter RC = 1;
    parameter sram_pkg::sramcfg_t thecfg = {
        AW: 17-2,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 2**(17-2),
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    };

    logic             clk;
    logic             resetn;
    logic             cmsatpg;
    logic             cmsbist;
    logic [thecfg.KW-1:0] scmbkey;
    logic            prerr;
    logic            verifyerr;
    rbif #(.AW(15   ),      .DW(36))    rbs    ();

    ramif #(.RAW(thecfg.AW),.DW(thecfg.DW)) rams();

    ifram #(RC,thecfg) u0(
    .clk           ,
    .resetn        ,
    .cmsatpg       ,
    .cmsbist       ,
    .rbs           ,
    .scmbkey       ,
    .even     ('0),
    .prerr         ,
    .verifyerr     ,
    .rams
    );

endmodule
