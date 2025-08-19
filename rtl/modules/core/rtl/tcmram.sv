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

//`include "template.sv"
//`include "rtl/model/artisan_ram_def_v0.1.svh"

module tcmram
  #(
    parameter bit itcm = 0,
    parameter sram_pkg::sramcfg_t thecfg={
        AW: 13,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 2**13,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '0,
        isPRT:  '1,
        EVITVL: 15
    },
    parameter AW = thecfg.AW,
    parameter DW = thecfg.DW+thecfg.PW,
    parameter BC = thecfg.DW/8,
    parameter BW = (thecfg.DW+thecfg.PW)/BC,
    parameter RC=1,
    parameter RDW = 2 // ready_counter/wait_cyc width
   )
   (
    input  logic                 clk,
    input  logic                 clken,
    input  logic                 resetn,
    input  logic                 cmsatpg,
    input  logic                 cmsbist,
    rbif.slave              rbs[0:RC-1],
    input  logic [RDW-1:0]        waitcyc,
    input  logic [2:0]            sramtrm,
    output logic [RC-1:0][BC/RC-1:0][7:0]  tcmdout,
    ramif.slave             rams

    );


    localparam BC2 = BC/RC;
    localparam DW2 = DW/RC;

    logic [BC-1:0][BW-1:0]                 wen0;
    logic [BC-1:0][BW-1:0]                 d0,q0;
    logic [RC-1:0][BC/RC-1:0][8:0]      wen;
    logic [RC-1:0][BC/RC-1:0][8:0]      d,q;
    logic cen, clktcmen, clktcm, gwen;
    logic [AW-1:0]  a;

    genvar gvi,gvj;

    ICG icg(.CK(clk),.EN(clktcmen),.SE(cmsatpg),.CKG(clktcm));

    assign clktcmen = ~cen & clken;
    assign #0.5 cen = ~( rams.ramcs & rams.ramready );
    assign d0 = rams.ramwdata[DW-1:0];
    assign #0.5 d = d0;
    assign #0.5 wen = wen0;
    assign #0.5 gwen = ~|rams.ramwr;
    assign rams.ramrdata = q0;
    assign q0 = q;
    assign #0.5 a = rams.ramaddr;

generate
    for ( gvi = 0; gvi < RC; gvi++) begin: gentcm

    logic rb_clkb, rb_bcen, rb_bgwen;
    logic [AW-1:0]  rb_ba;
    logic [BC/RC-1:0][8:0] rb_bq, rb_bwen, rb_bd;
    logic [BC/RC-1:0]pbit;

    rbspmux #(.AW(AW),.DW(DW2),.TCM(1'b1))rbmux(
         .cmsatpg,
         .cmsbist,
         .rbs         (rbs[gvi]),
         .clk(clktcm),
         .q(q[gvi]),
         .cen(cen),
         .gwen(gwen),
         .wen(wen[gvi]),
         .a(a),
         .d(d[gvi]),
         .rb_clk      (rb_clkb),
         .rb_q        (rb_bq),
         .rb_cen      (rb_bcen),
         .rb_gwen     (rb_bgwen),
         .rb_wen      (rb_bwen),
         .rb_a        (rb_ba),
         .rb_d        (rb_bd)
       );

    if(itcm)begin:gi
//    itcm32kx18 tcm (
    assign rb_bq = {tcmdout[gvi][1],pbit[1],tcmdout[gvi][0],pbit[0]};
    itcm16kx18x2 tcm (
         .clk      (rb_clkb),
//         .q        (rb_bq),
         .q        ({tcmdout[gvi][1],pbit[1],tcmdout[gvi][0],pbit[0]}),
         .cen      (rb_bcen),
         .gwen     (rb_bgwen),
         .wen      (rb_bwen),
         .a        (rb_ba),
         .d        (rb_bd),
//`ifdef TCMSVT
        `sram_sp_svt_inst_tcm
//`else
//        `sram_sp_hde_inst_tcm
//`endif
         );
    end
    else begin:gd
    assign rb_bq = { tcmdout[gvi][3],pbit[3],tcmdout[gvi][2],pbit[2],
                     tcmdout[gvi][1],pbit[1],tcmdout[gvi][0],pbit[0]};
    dtcm8kx36 tcm (
         .clk      (rb_clkb),
//         .q        (rb_bq),
         .q        (
                {tcmdout[gvi][3],pbit[3],tcmdout[gvi][2],pbit[2],
                 tcmdout[gvi][1],pbit[1],tcmdout[gvi][0],pbit[0]}),
         .cen      (rb_bcen),
         .gwen     (rb_bgwen),
         .wen      (rb_bwen),
         .a        (rb_ba),
         .d        (rb_bd),
//`ifdef TCMULL
        `sram_sp_svt_inst_tcm
//`else
//        `sram_sp_hde_inst_tcm
//`endif
         );
    end
    end
    for ( gvj = 0; gvj < BC; gvj++) begin: genwe
        assign wen0[gvj] = rams.ramwr[gvj] ? '0 : '1;
    end
endgenerate


    bit [RDW-1:0]   waitcnt;
    `theregrn( waitcnt ) <= ( rams.ramcs & ( rams.ramwr == '0 ) & rams.ramready ) & clken ? waitcyc :
                            (waitcnt != '0) ? waitcnt - 1 : waitcnt;

    assign rams.ramready = ( waitcnt == '0 );

endmodule

module dummytb_tcm();

    localparam sram_pkg::sramcfg_t dtcmcfg = {
        AW: 13,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 2**13,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL: 15
    };

    localparam sram_pkg::sramcfg_t itcmcfg = {
        AW: 15,
        DW: 64,
        KW: 64,
        PW: 8,
        WCNT: 2**15,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL: 15
    };

    ramif #(.RAW(dtcmcfg.AW),.DW(dtcmcfg.DW+dtcmcfg.PW))dtcmrams();
    ramif #(.RAW(itcmcfg.AW),.DW(itcmcfg.DW+itcmcfg.PW))itcmrams();
    rbif #(.AW(13   ),      .DW(36))    rbsi      [0:0]   ();
    rbif #(.AW(15   ),      .DW(72))    rbsd      [0:3]   ();

    tcmram #(.itcm('0),.thecfg(dtcmcfg),.RC(1))u1
   (
    .clk('0),
    .clken('0),
    .resetn('0),
    .cmsatpg('0),
    .cmsbist('0),
    .rbs(rbsi),
    .waitcyc('0),
    .sramtrm('0),
    .tcmdout(),
    .rams(dtcmrams)
   );

    tcmram #(.itcm('1),.thecfg(itcmcfg),.RC(4))u2
   (
    .clk('0),
    .clken('0),
    .resetn('0),
    .cmsatpg('0),
    .cmsbist('0),
    .rbs(rbsd),
    .waitcyc('0),
    .sramtrm('0),
    .tcmdout(),
    .rams(itcmrams)
   );
 /*
    `maintest(dummytb_tcm,dummytb_tcm)
        #105 ;

        #(1 `MS);
    `maintestend
*/
endmodule




`ifdef SIMTCMRAM

module tcmram_tb (
);

    localparam AW = 13;

    localparam sram_pkg::sramcfg_t dtcmcfg = {
        AW: 13,
        DW: 32,
        KW: 32,
        PW: 8,
        WCNT: 2**AW,
        AWX: 4,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL: 15
    };
    rbif #(.AW(13   ),      .DW(36))    rbs      ();

    logic             clk=0;
    logic             resetn=0;
    logic             cmsatpg=0;
    logic             cmsbist=0;
    logic             scmben=1'b0;
    logic [dtcmcfg.KW-1:0] scmbkey=0;
    logic             prerr;

    bit                    ramm_ramen    ;
    bit                    ramm_ramcs    ;
    bit   [dtcmcfg.AW-1:0]  ramm_ramaddr  ;
    bit   [dtcmcfg.DW/8-1:0]                 ramm_ramwr    ;
    bit   [dtcmcfg.DW-1:0]  ramm_ramwdata ;
    bit   [dtcmcfg.DW-1:0]  ramm_ramrdata ;
    bit                    ramm_ramready ;
    ramif #(.RAW(dtcmcfg.AW))        rams() ;

    bit                         rams_ramen    ;
    bit                         rams_ramcs    ;
    bit   [dtcmcfg.AW-1:0]      rams_ramaddr  ;
    bit   [dtcmcfg.DW/8-1:0]    rams_ramwr    ;
    bit   [dtcmcfg.DW+dtcmcfg.PW-1:0]    rams_ramwdata ;
    bit   [dtcmcfg.DW+dtcmcfg.PW-1:0]    rams_ramrdata, rams_ramrdata0, rams_ramrdata2 ;
    bit                      rams_ramready;
    ramif #(.RAW(dtcmcfg.AW),.BW(9),.DW(dtcmcfg.DW+dtcmcfg.PW))        ramm();
    bit verifyerr;

//    bit clk,resetn;
    integer i, j, k, errcnt=0, warncnt=0;

    bit [1:0] waitcyc = 1;

  //
  //  dut
  //  ==

    gnrl_sramc #(.thecfg(dtcmcfg))dut
    (
        .clk,
        .resetn,
        .cmsatpg,
        .cmsbist,
        .scmben,
        .scmbkey,
        .prerr,
        .verifyerr,
        .ramslave(rams),
        .rammaster(ramm)
    );

`define TCMNAME dtcm8kx36

    tcmram #(.thecfg(dtcmcfg),.RC(1))dut2(
    .clk,
    .resetn,
    .cmsatpg,.cmsbist('0),.rbs,
    .waitcyc(waitcyc),
    .rams(ramm)
    );

    wire2ramm #(.AW(dtcmcfg.AW),.DW(dtcmcfg.DW)) RM(.ramm(rams),.*);
/*
    rams2wire #(.AW(dtcmcfg.AW),.DW(dtcmcfg.DW+dtcmcfg.PW)) RS(.rams(ramm),.*);

    `theregrn( rams_ramready ) <= rams_ramcs ? '0 : '1;

    simram #(.AW(dtcmcfg.AW),.DW(dtcmcfg.DW+dtcmcfg.PW)) simram(
        .clk, .resetn,
        .ramaddr    (rams_ramaddr),
        .ramrdat    (rams_ramrdata0),
        .ramwr      (rams_ramwr[0]),
        .ramrd      (rams_ramcs & ~rams_ramwr[0]),
        .ramwdat    (rams_ramwdata ^ 'h0)
    );
*/

    simram #(.AW(dtcmcfg.AW),.DW(dtcmcfg.DW+dtcmcfg.PW)) simram(
        .clk, .resetn,
        .ramaddr    ('0),
        .ramrdat    (),
        .ramwr      ('0),
        .ramrd      ('0),
        .ramwdat    ('0)
    );



//    assign rams_ramrdata = rams_ramready ? rams_ramrdata2 : '0;
    assign rams_ramrdata =  rams_ramrdata0 ;

  //
  //  monitor and clk
  //  ==

    `genclk( clk, 100 )
    `timemarker2

/*
    initial begin
        for(i=0;i<2**AW;i++)begin
            ramdat[i]=$urandom()*8'ha5;
            ramdat32[i]={ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]};
        end
    end
*/
  //
  //  subtitle
  //  ==

    `maintest(tcmram_tb,tcmram_tb)
        #105 resetn = 1;

`ifdef NOFSDB
        for(i=1;i>0;i=i)begin
        #(10 `MS);
        end
`endif
        #(50 `MS);
    `maintestend

    bit [31:0]  r32a, r32b, r32c;

    assign ramm_ramen = '1;

    always@(posedge clk)
    if(resetn & ramm_ramready) begin
        r32a <= $urandom() & $urandom();
        r32b <= $urandom();
        r32c <= $urandom();
        ramm_ramcs <= r32a[0];
        ramm_ramwr <= {4{&r32a[1:0]}};
        ramm_ramaddr <= r32b;
        ramm_ramwdata <= r32b;
    end

// rdcheck

    bit rdcheck, rdcheck0;
    bit [3:0][8:0] therdata36;
    bit [3:0][7:0] therdata;
    bit rderror;

    assign therdata[0] = therdata36[0]/2;
    assign therdata[1] = therdata36[1]/2;
    assign therdata[2] = therdata36[2]/2;
    assign therdata[3] = therdata36[3]/2;



    `theregrn( rdcheck0 ) <= ramm_ramready ? ramm_ramcs & ~ramm_ramwr[0] : rdcheck0;

    always@(posedge clk)begin
        if( ramm_ramcs & ~ramm_ramwr[0] & ramm_ramready ) begin
            therdata36 <= simram.ramdat[ramm_ramaddr];
        end
    end
    assign rdcheck = rdcheck0 & ramm_ramready;
    `theregrn( rderror ) <= rdcheck & ~( therdata == ramm_ramrdata );

// wrcheck

    bit wrcheck0, wrcheck, wrerror;
    bit [dtcmcfg.AW-1:0] ramm_ramaddrreg;
    bit [31:0] wdat32a, wdat32b;
    bit [35:0] wdat36;

    `thereg( simram.ramdat32[ramm_ramaddr] ) <= ramm_ramcs  & ramm_ramwr[0] & ramm_ramready ? ramm_ramwdata : simram.ramdat32[ramm_ramaddr];
    `thereg( wrcheck0 ) <= ramm_ramready ? ramm_ramcs & ramm_ramwr[0] : wrcheck0;
    `thereg( ramm_ramaddrreg ) <= ramm_ramready & ramm_ramcs & ramm_ramwr[0] ? ramm_ramaddr : ramm_ramaddrreg;

    assign wrcheck = wrcheck0 & ramm_ramready;
    `theregrn( wrerror ) <= wrcheck & ~( simram.ramdat32[ramm_ramaddrreg] ==
                        {simram.ramdat[ramm_ramaddrreg][35:28],simram.ramdat[ramm_ramaddrreg][26:19],simram.ramdat[ramm_ramaddrreg][17:10],simram.ramdat[ramm_ramaddrreg][8:1]} );


    assign wdat32a =    simram.ramdat32[ramm_ramaddrreg];
    assign wdat36 =     simram.ramdat[ramm_ramaddrreg];
    assign wdat32b  = { simram.ramdat[ramm_ramaddrreg][35:28],
                        simram.ramdat[ramm_ramaddrreg][26:19],
                        simram.ramdat[ramm_ramaddrreg][17:10],
                        simram.ramdat[ramm_ramaddrreg][ 8: 1]}   ;

    bit wdat32check;
    `theregrn( wdat32check ) <= wdat32a == wdat32b;

    `thereg( errcnt ) <= errcnt + rderror + wrerror + dut.prerr + dut.verifyerr;


integer x;
    initial begin
        for(x=1;x>0;x=x)begin
            #(10 `MS);
            resetn = 0;
            #(751);
            resetn = 1;
        end

    end

endmodule


module simram #(
    parameter AW = 10,
    parameter string INITFILE="",
    parameter bit RANDOMIZE=1'b1,
    parameter DW = 36

)(
    input   bit             clk,    // Clock
    input   bit             resetn,  // Asynchronous reset active low

    input bit   [AW-1:0]    ramaddr,
    output  bit [DW-1:0]    ramrdat,
    input bit               ramwr,
    input bit               ramrd,
    input bit   [DW-1:0]    ramwdat
);

    bit [DW-1:0]    ramdat[0:2**AW-1];
    bit [DW-1:0]    ramdat0[0:2**AW-1];
    bit [31:0]    ramdat32[0:2**AW-1];
    bit [31:0]    ramdat32b[0:2**AW-1];
    bit [0:2**AW-1][DW-1:0]    vramdat;
    integer i;

    integer errcnt = 0;

    bit [35:0] tmp36;
    bit [2:0] resetnregs;
    bit resetfall;

    always@(posedge clk)  resetnregs <= { resetnregs, resetn };
    assign resetfall = resetnregs[2] & ~resetnregs[1] ;

    always@(negedge clk)  begin
        if(resetfall)begin
        errcnt = 0;
            for(i=0;i<2**AW;i++)begin
                if ( ramdat32[i] != {ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]} ) errcnt = errcnt + 1;
                tmp36 = $urandom() * 8'ha5;
//                ramdat[i]=tmp36;
                ramdat[i]=tmp36;//$urandom()*8'ha5;
                ramdat32[i]={ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]};
            end
        $display("@ram data scan check: %d", errcnt);
        end
    end

    initial begin
        if(INITFILE!="")$readmemh(INITFILE, ramdat);

        if(INITFILE=="" &&RANDOMIZE)begin
            for(i=0;i<2**AW;i++)begin
                ramdat[i]=$urandom()*8'ha5;
                ramdat32[i]={ramdat[i][35:28],ramdat[i][26:19],ramdat[i][17:10],ramdat[i][8:1]};
            end
        end

    end

    bit [DW-1:0] ramrdat0;

    always@(posedge clk) if(ramwr) ramdat[ramaddr] <= ramwdat;
    always@(posedge clk) ramrdat0 <= ramdat[ramaddr];
    always@(posedge clk) ramrdat <= ramrdat0;

    genvar gvi;
    generate
        for(gvi=0;gvi<2**AW;gvi++)begin
        assign vramdat[gvi] = ramdat[gvi];
        assign ramdat32b[gvi] = {ramdat[gvi][35:28],ramdat[gvi][26:19],ramdat[gvi][17:10],ramdat[gvi][8:1]};
    end
    endgenerate


endmodule : simram


`endif