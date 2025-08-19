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
//`include "rtl/model/artisan_ram_def_v0.1.svh"

import sram_pkg::*;

module cryptoram #(
    parameter ramname = "HRAM", // HRAM, PRAM, ARAM, SCERAM, ALURAM
    parameter sramcfg_t thecfg = sram_pkg::samplecfg,
    parameter clrstart = '0,
    parameter clrend = thecfg.WCNT-1
    )(
    input  logic clk, resetn, cmsatpg, cmsbist,
    rbif.slave rbs,
    input  logic clkram, clkramen,
    input  logic ramclr,
    input  logic [thecfg.AW-1:0] ramaddr,
    input  logic ramen,
    input  logic ramrd,
    input  logic [thecfg.DW/8-1:0] ramwr,
    input  logic [thecfg.DW-1:0] ramwdat,
    output logic [thecfg.DW-1:0] ramrdat,
    output logic ramready,
    output logic [1:0] ramerror,
    output logic ramclren
);

    localparam RC = 1;
    localparam RCW = $clog2(RC);
    localparam DW0 = thecfg.DW+thecfg.PW;
    localparam AW = thecfg.AW;

    ramif #(.RAW(thecfg.AW),.DW(thecfg.DW))           rams();
    ramif #(.RAW(thecfg.AW),.DW(thecfg.DW+thecfg.PW)) ramm();

    logic [thecfg.AW-1:0] ramaddr0, ramaddr_clr;
    logic ramen0, ramen_clr;
    logic ramrd0, ramrd_clr;
    logic [thecfg.DW/8-1:0] ramwr0, ramwr_clr;
    logic [thecfg.DW-1:0] ramwdat0, ramwdat_clr;
    logic [thecfg.DW-1:0] ramrdat0;
    logic ramready0;

    logic ramclrdone;
    logic [thecfg.AW-1:0] ramclrfsm;

    assign ramclrdone = ( ramclrfsm == clrend );
    `theregrn( ramclrfsm ) <= ramclr ? clrstart :
                              ramclrdone ? '0 : ramclrfsm + ramclren;
    `theregrn( ramclren ) <= ramclr ? 1'b1 : ramclrdone ? 1'b0 : ramclren;
    assign ramaddr_clr = ramclrfsm;
    assign ramen_clr = '1;
    assign ramrd_clr = '0;
    assign ramwr_clr = '1;
    assign ramwdat_clr = '0;

    assign ramaddr0 = ramclren ? ramaddr_clr: ramaddr;
    assign ramen0 = ramclren ? ramen_clr: ramen;
    assign ramrd0 = ramclren ? ramrd_clr: ramrd;
    assign ramwr0 = ramclren ? ramwr_clr: ramwr;
    assign ramwdat0 = ramclren ? ramwdat_clr: ramwdat;

    assign ramrdat = ramclren ? '0 : ramrdat0;
    assign ramready = ramclren ? '1 : ramready0;


`ifdef SIM
    bit [0:thecfg.WCNT-1][thecfg.DW-1:0] ramdat;
    `thereg( ramdat[ramaddr0] ) <= ramwr ? ramwdat0 : ramdat[ramaddr0];

`endif


`ifndef FPGA

    wire2ramm
    #(
        .AW(thecfg.AW),
        .DW(thecfg.DW),
        .BW(8)
    )u(
        .ramm_ramen      (ramen0),
        .ramm_ramcs      (ramrd0 | (|ramwr0)),
        .ramm_ramaddr    (ramaddr0),
        .ramm_ramwr      (ramwr0),
        .ramm_ramwdata   (ramwdat0),
        .ramm_ramrdata   (ramrdat0),
        .ramm_ramready   (ramready0),
        .ramm            (rams)
    );

    gnrl_sramc #(.thecfg(thecfg))hram
    (
        .clk,
        .resetn,
        .cmsatpg,
        .cmsbist,
        .scmben('0),
        .scmbkey('0),
        .even     (1'b1),
        .prerr(ramerror[0]),
        .verifyerr(ramerror[1]),
        .ramslave(rams),
        .rammaster(ramm)
    );

    logic [RCW-1:0]         bsel, bselreg   ;
    logic [DW0-1:0]         bd              ;
    logic [RC-1:0][DW0-1:0] bq              ;
    logic [RC-1:0]          bcen, bgwen     ;
    logic [RC-1:0][DW0-1:0]   bwen        ;
    logic [AW-RCW-1:0]        ba              ;
    logic [RC-1:0]          clkb, clkben    ;

    assign bsel = 0;// rams_ramaddr[AW-1:AW-RCW] ;
    `theregrn(bselreg) <= ( ramm.ramcs & ramm.ramready ) ? bsel : bselreg;
    assign ramm.ramready = '1;
    assign ramm.ramrdata = bq[bselreg];
    assign #0.5 bd = ramm.ramwdata;
    assign #0.5 ba = ramm.ramaddr;

generate
  for (genvar i = 0; i < RC; i++) begin: genram

    assign #0.5 bcen[i] = ~( ramm.ramcs & (bsel==i) );
    assign #0.5 bgwen[i] =  ~( |ramm.ramwr & ramm.ramcs & (bsel==i) );
//    assign #0.5 bwen[i]  =  rams_ramcs & (bsel==i) ? ~rams.ramwr : '1;
    logic rb_clkb, rb_bcen, rb_bgwen;
    logic [AW-1:0]  rb_ba;
    logic [DW0-1:0] rb_bq, rb_bwen, rb_bd;

    rbspmux #(.AW(AW),.DW(DW0))rbmux(
         .cmsatpg,
         .cmsbist,
         .rbs         (rbs),
         .clk         (clkb[i]),
         .q           (bq[i]),
         .cen         (bcen[i]),
         .wen         (bwen[i]),
         .gwen        (bgwen[i]),
         .a           (ba),
         .d           (bd),
         .rb_clk      (rb_clkb),
         .rb_q        (rb_bq),
         .rb_cen      (rb_bcen),
         .rb_gwen     (rb_bgwen),
         .rb_wen      (rb_bwen),
         .rb_a        (rb_ba),
         .rb_d        (rb_bd)
       );

    if(ramname=="ARAM")begin:genARAM
        assign bwen[i] = '1;
       sce_aesram_1k  m (
         .clk         (rb_clkb         ),
         .q           (rb_bq           ),
         .cen         (rb_bcen         ),
         .wen         (rb_bgwen         ),
         .a           (rb_ba           ),
         .d           (rb_bd           ),
        `rf_sp_hde_inst
         );
    end
    if(ramname=="PRAM")begin:genPRAM
    assign #0.5 bwen[i]  =  rams.ramcs & (bsel==i) ? ~({{36{rams.ramwr[thecfg.DW/8-1]}},{36{rams.ramwr[0]}}}) : '1;
       sce_pkeram_4k  m (
         .clk          (rb_clkb  ),
         .q            (rb_bq    ),
         .cen          (rb_bcen  ),
         .wen          (rb_bwen  ),
         .gwen         (rb_bgwen ),
         .a            (rb_ba    ),
         .d            (rb_bd    ),
        `rf_sp_hde_inst
         );
    end
    if(ramname=="HRAM")begin:genHRAM
        assign bwen[i] = '1;
       sce_hashram_3k  m (
         .clk         (rb_clkb         ),
         .q           (rb_bq           ),
         .cen         (rb_bcen         ),
         .wen         (rb_bgwen         ),
         .a           (rb_ba           ),
         .d           (rb_bd           ),
        `rf_sp_hde_inst
         );
    end
    if(ramname=="ALURAM")begin:genALURAM
    assign #0.5 bwen[i]  =  rams.ramcs & (bsel==i) ? ~({36{rams.ramwr[0]}}) : '1;
       sce_aluram_3k  m (
         .clk          (rb_clkb  ),
         .q            (rb_bq    ),
         .cen          (rb_bcen  ),
         .wen          (rb_bwen  ),
         .gwen         (rb_bgwen ),
         .a            (rb_ba    ),
         .d            (rb_bd    ),
        `rf_sp_hde_inst
         );
    end
    if(ramname=="SCERAM")begin:genSCERAM
       sce_sceram_10k  m (
         .clk          (rb_clkb  ),
         .q            (rb_bq    ),
         .cen          (rb_bcen  ),
         .gwen         (rb_bgwen ),
         .a            (rb_ba    ),
         .d            (rb_bd    ),
        `sram_sp_hde_inst
         );
    end

    ICG icg(.CK(clkram),.EN(clkben[i]),.SE(cmsatpg),.CKG(clkb[i]));
    assign clkben[i] = ~bcen[i] & clkramen;
  end
endgenerate
/*
    sce_aesram_1k uram(
               .clk         (clk),
               .q           (ramm.ramrdata),
               .cen         (ramm.ramen),
               .gwen        (ramm.ramwr),
               .wen         (ramm.ramen),
               .a           (ramm.ramen),
               .d           (ramm.ramen),
               .ema         ('0),
               .emaw        ('0),
               .emas        ('0),
               .ret1n       (1'b1),
               .wabl        ('1),
               .wablm       ('0),
               .rawl        ('0),
               .rawlm       ('0)
               );

    ICG icg(.CK(clk),.EN(clkben[i]),.SE(cmsatpg),.CKG(clkb[i]));
    assign clkben[i] = ~bcen[i] ;

    `ifdef SIM
        sceram_sim #(
            .AW ( thecfg.AW ),
            .DW ( thecfg.DW + thecfg.PW),
            .WCNT ( thecfg.WCNT )
        )m(
            .clk,
            .rams(ramm)
        );
    `endif
    `ifdef SYN

    `endif
 */
`else // ifdef FPGA

    assign ramready0 = 1'b1;
//    assign ramready = '1;
    assign ramerror = '0;

generate
    if(ramname=="SCERAM") begin: gensceram
        bramsp #(
            .BS ( "36Kb" ),
            .AW ( thecfg.AW ),
            .DW ( 8 )
        )br0(
            .clk        ( clk      ),
            .ramaddr    ( ramaddr0  ),
            .ramcs      ( ramrd0 | ramwr0[0]   ),
            .ramwr      ( ramwr0[0]  ),
            .ramwdata   ( ramwdat0[7:0] ),
            .ramrdata   ( ramrdat0[7:0] )
        );
        bramsp #(
            .BS ( "36Kb" ),
            .AW ( thecfg.AW ),
            .DW ( 8 )
        )br1(
            .clk        ( clk      ),
            .ramaddr    ( ramaddr0  ),
            .ramcs      ( ramrd0 | ramwr0[0]   ),
            .ramwr      ( ramwr0[0]  ),
            .ramwdata   ( ramwdat0[15:8] ),
            .ramrdata   ( ramrdat0[15:8] )
        );
        bramsp #(
            .BS ( "36Kb" ),
            .AW ( thecfg.AW ),
            .DW ( 8 )
        )br2(
            .clk        ( clk      ),
            .ramaddr    ( ramaddr0  ),
            .ramcs      ( ramrd0 | ramwr0[0]   ),
            .ramwr      ( ramwr0[0]  ),
            .ramwdata   ( ramwdat0[23:16] ),
            .ramrdata   ( ramrdat0[23:16] )
        );
        bramsp #(
            .BS ( "36Kb" ),
            .AW ( thecfg.AW ),
            .DW ( 8 )
        )br3(
            .clk        ( clk      ),
            .ramaddr    ( ramaddr0  ),
            .ramcs      ( ramrd0 | ramwr0[0]   ),
            .ramwr      ( ramwr0[0]  ),
            .ramwdata   ( ramwdat0[31:24] ),
            .ramrdata   ( ramrdat0[31:24] )
        );
    end
    else if( ramname=="PRAM" ) begin: genpram
        bramsp #(
            .BS ( "36Kb" ),
            .AW ( thecfg.AW ),
            .DW ( 32 )
        )br0(
            .clk        ( clk      ),
            .ramaddr    ( ramaddr0  ),
            .ramcs      ( ramrd0 | ramwr0[0]   ),
            .ramwr      ( ramwr0[0]  ),
            .ramwdata   ( ramwdat0[31:0] ),
            .ramrdata   ( ramrdat0[31:0] )
        );
        bramsp #(
            .BS ( "36Kb" ),
            .AW ( thecfg.AW ),
            .DW ( 32 )
        )br1(
            .clk        ( clk      ),
            .ramaddr    ( ramaddr0  ),
            .ramcs      ( ramrd0 | ramwr0[4] ),
            .ramwr      ( ramwr0[4]  ),
            .ramwdata   ( ramwdat0[63:32] ),
            .ramrdata   ( ramrdat0[63:32] )
        );
    end
    else begin: gen1bram
        bramsp #(
            .BS ( "36Kb" ),
            .AW ( thecfg.AW ),
            .DW ( thecfg.DW )
        )br(
            .clk        ( clk      ),
            .ramaddr    ( ramaddr0  ),
            .ramcs      ( ramrd0 | ramwr0[0] ),
            .ramwr      ( ramwr0[0]  ),
            .ramwdata   ( ramwdat0 ),
            .ramrdata   ( ramrdat0 )
        );
    end

endgenerate

`endif



endmodule

module sceram_sim #(
    parameter AW = 10,
    parameter DW = 36,
    parameter WCNT = 2**AW

)(
    input   bit     clk,
    ramif.slave     rams
);

    bit [0:WCNT-1][DW-1:0]    ramdat;
    bit [DW-1:0] ramrdat;

generate
    for (genvar i = 0; i < DW/9; i++) begin: gg
        always@(posedge clk) if(rams.ramwr[i])  ramdat[rams.ramaddr][i*9+8:i*9] <= rams.ramwdata[i*9+8:i*9];
    end
endgenerate
    always@(posedge clk) ramrdat <= ramdat[rams.ramaddr];
    assign rams.ramrdata = ramrdat;
    assign rams.ramready = '1;

endmodule : sceram_sim

module dummytb_sceram_sim();
    parameter AW = 10;
    parameter DW = 36;
    parameter WCNT = 2**AW;
    bit     clk;
    bit clkram, clkramen;
    ramif #(.RAW(AW),.DW(DW))    rams();
    rbif #(.AW(8    ),      .DW(72))    rbs  [0:0]   ();

sceram_sim u0(.*);

endmodule
