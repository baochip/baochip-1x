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


import scedma_pkg::*;

module trng #(
        parameter RAW = 8,
        parameter ERRCNT = 8,
        parameter INTCNT = 8,
        parameter ETPC = 8,
        parameter CHAINW = 128
    )(
    input wire        ana_rng_0p1u,

    input  logic clk, resetn, sysresetn, cmsatpg, cmsbist,
    input  logic [6:0] ipt_rngcfg,
    apbif.slavein           apbs,
    apbif.slave             apbx,
    output bit busy,
    output bit done,
    output  chnlreq_t       chnl_wpreq   ,
    input   chnlres_t       chnl_wpres   ,

    output bit iptorndlf, iptorndhf,

    output logic [0:ERRCNT-1]      err,
    output logic [0:INTCNT-1]      intr
);


// apb
// ■■■■■■■■■■■■■■■

    logic apbrd, apbwr;
    logic pclk;
    logic sfrlock;
    assign pclk = clk;

    `theregrn( sfrlock ) <= '0;

    `apbs_common;
    assign apbx.prdata = '0
                        | sfr_crsrc.prdata32 | sfr_crana.prdata32 | sfr_pp.prdata32 | sfr_opt.prdata32
                        | sfr_sr.prdata32 | sfr_fr.prdata32 | sfr_chain.prdata32
                        | sfr_buf.prdata32
                        ;

    logic [6:0] rnghf_cfg;
    logic [2:0] rnglf_sel;
    logic rnghf_en;
    logic rnglf_en;
    logic [7:0] cr_anaen, cr_anavld;
    logic [12:0] cr_src;
    logic [15:0] cr_ana;
    logic ar_start, ar_stop;
    logic opt_segsel;
    logic [15:0] opt_rngcnt, rngcnt;
    logic [16:0] cr_opt;
    logic [31:0] sr_rng;
    logic [16:0] cr_postproc;
    logic [7:0] rngsrc_dat;
    logic rngcore_en;
    logic cr_gen_en;
    logic  cr_drng_en;
    logic  cr_hlthtest_en;
    logic  cr_pfilter_en;
    logic [1:0] cr_reseed_intval;
    logic [1:0] cr_gen_intval;
    logic [5:0] cr_healthtest_len;
    logic [1:0] cr_postproc_opt;
    logic sr_drng_reseed_req, sr_bufrdy;
    logic [11:0] sr_hlthtest_errcnt;
    logic sr_hlthtest_err, sr_hlthtest_errreg, sr_hlthtest_errrise;
    logic [2:0]        buf_addr;
    logic              buf_read;
    logic              buf_write;
    logic [31:0]       buf_datain, buf_dataout;
    logic [3:0][31:0]   rngcore_data;
    logic [127:0]       rngcore_data128;
    logic               rngcore_dataout_vld;
    logic chnlo_start ;
    logic chnlo_busy  ;
    logic chnlo_done  ;
    chnlcfg_t chnlo_cfg   ;
    chnlreq_t chnlo_rpreq ;
    chnlres_t chnlo_rpres ;
    logic stop2;
    logic [2:0] fr;
    logic [CHAINW-1:0] rngchainen;
    logic cr_reseed_sel;
    logic ar_generate, fr_generate;
    logic hlthtest_errof;
    logic chaincut;

    apb_cr #(.A('h00), .DW(13) )      sfr_crsrc       (.cr(cr_src), .prdata32(),.*);
    apb_cr #(.A('h04), .DW(16)  )     sfr_crana       (.cr(cr_ana), .prdata32(),.*);
    apb_cr #(.A('h08), .DW(17) )      sfr_pp          (.cr(cr_postproc), .prdata32(),.*);
    apb_cr #(.A('h0c), .DW(17) )      sfr_opt         (.cr(cr_opt), .prdata32(),.*);

    apb_ar #(.A('h14), .AR(32'h5a))   sfr_ar_start    (.ar(ar_start),.*);
    apb_ar #(.A('h14), .AR(32'ha5))   sfr_ar_stop     (.ar(ar_stop),.*);
    apb_ar #(.A('h14), .AR(32'h55))   sfr_ar_gen      (.ar(ar_generate),.*);

    apb_sr #(.A('h10), .DW(32) )      sfr_sr          (.sr(sr_rng | 32'h0 ), .prdata32(),.*);
    apb_fr #(.A('h18), .DW(3) )       sfr_fr         (.fr(fr), .prdata32(),.*);

    apb_cr #(.A('h40), .DW(32), .REVY(1), .SFRCNT(CHAINW/32) )      sfr_chain       (.cr(rngchainen), .prdata32(),.*);

    assign fr[0] = ( rngcnt == opt_rngcnt - 1 ) & chnlo_done;
    assign fr[1] = fr_generate;
    assign fr[2] = hlthtest_errof;

// entropy source
// ■■■■■■■■■■■■■■■
    logic [7:0] rngclklfpre_undft, rngclklf;
    logic rngclkhf_undft, rngclkhf;

    assign { chaincut, rnghf_cfg[6:0], rnglf_sel[2:0], rnghf_en, rnglf_en } = cr_src;
    assign { cr_anaen[7:0], cr_anavld[7:0] } = cr_ana ;
    assign { opt_segsel , opt_rngcnt[15:0] } = cr_opt ;

// fpga only
// ■■■■■■■■■■■■■■■


    logic [7:0] rngclklfsim, clklfhitsim, rngsrc_datsim, rngsrc_datsimreg;
    logic [7:0][7:0] clklfcntsim;

    `theregrn( clklfcntsim[0] ) <= clklfhitsim[0] ? 0 : clklfcntsim[0] + 1 ;
    `theregrn( clklfcntsim[1] ) <= clklfhitsim[1] ? 0 : clklfcntsim[1] + 1 ;
    `theregrn( clklfcntsim[2] ) <= clklfhitsim[2] ? 0 : clklfcntsim[2] + 1 ;
    `theregrn( clklfcntsim[3] ) <= clklfhitsim[3] ? 0 : clklfcntsim[3] + 1 ;
    `theregrn( clklfcntsim[4] ) <= clklfhitsim[4] ? 0 : clklfcntsim[4] + 1 ;
    `theregrn( clklfcntsim[5] ) <= clklfhitsim[5] ? 0 : clklfcntsim[5] + 1 ;
    `theregrn( clklfcntsim[6] ) <= clklfhitsim[6] ? 0 : clklfcntsim[6] + 1 ;
    `theregrn( clklfcntsim[7] ) <= clklfhitsim[7] ? 0 : clklfcntsim[7] + 1 ;
    assign clklfhitsim[0] = clklfcntsim[0] == 100;
    assign clklfhitsim[1] = clklfcntsim[1] == 101;
    assign clklfhitsim[2] = clklfcntsim[2] == 102;
    assign clklfhitsim[3] = clklfcntsim[3] == 103;
    assign clklfhitsim[4] = clklfcntsim[4] == 104;
    assign clklfhitsim[5] = clklfcntsim[5] == 105;
    assign clklfhitsim[6] = clklfcntsim[6] == 106;
    assign clklfhitsim[7] = clklfcntsim[7] == 107;

 `ifdef FPGA

    drng_lfsr #( .LFSR_W(229),.LFSR_NODE({ 10'd228, 10'd225, 10'd219 }), .LFSR_OW(8),.LFSR_IV('h55aa_aa55_5a5a_a5a5) )
        ua( .clk(clk),.resetn('1), .sen('1), .swr('0), .sdin('0), .sdout(rngsrc_datsim) );

    `theregrn( rngclklfsim ) <= clklfhitsim ^ rngclklfsim;
    `theregfull( rngclklfsim[0], resetn, rngsrc_datsimreg[0], '0 ) <= rngsrc_datsim[0];
    `theregfull( rngclklfsim[1], resetn, rngsrc_datsimreg[1], '0 ) <= rngsrc_datsim[1];
    `theregfull( rngclklfsim[2], resetn, rngsrc_datsimreg[2], '0 ) <= rngsrc_datsim[2];
    `theregfull( rngclklfsim[3], resetn, rngsrc_datsimreg[3], '0 ) <= rngsrc_datsim[3];
    `theregfull( rngclklfsim[4], resetn, rngsrc_datsimreg[4], '0 ) <= rngsrc_datsim[4];
    `theregfull( rngclklfsim[5], resetn, rngsrc_datsimreg[5], '0 ) <= rngsrc_datsim[5];
    `theregfull( rngclklfsim[6], resetn, rngsrc_datsimreg[6], '0 ) <= rngsrc_datsim[6];
    `theregfull( rngclklfsim[7], resetn, rngsrc_datsimreg[7], '0 ) <= rngsrc_datsim[7];

    assign rngclklf = rngclklfsim;
    assign rngsrc_dat = rngsrc_datsimreg;

 `else
    logic [2:0] t_rnglf_sel;
    logic       t_rnglf_en;
    logic       t_rnghf_en;
    logic [6:0] t_rnghf_cfg;
    logic [7:0] t_rngsrc_dat;

    logic [7:0] rngclklfpre;
    logic cmstest;

    assign cmstest = cmsbist;
    assign t_rnglf_sel = cmsatpg ? '0 : cmstest ? '1 : rnglf_sel;
    assign t_rnglf_en =  cmsatpg ? '0 : cmstest ? '1 : rnglf_en;
    assign t_rnghf_en =  cmsatpg ? '0 : cmstest ? '1 : rnghf_en;
    assign t_rnghf_cfg = cmsatpg ? 7'b0100110 : cmstest ? ipt_rngcfg : rnghf_cfg;
//    assign rngclklfpre = cmsatpg ? clk

    RNG_CELL osclf(
        .IN_0P1U    (ana_rng_0p1u),
        .SEL        (t_rnglf_sel[2:0]),
        .EN         (t_rnglf_en),
        .RNG1_OUT   (rngclklfpre_undft[0]),
        .RNG2_OUT   (rngclklfpre_undft[1]),
        .RNG3_OUT   (rngclklfpre_undft[2]),
        .RNG4_OUT   (rngclklfpre_undft[3]),
        .RNG5_OUT   (rngclklfpre_undft[4]),
        .RNG6_OUT   (rngclklfpre_undft[5]),
        .RNG7_OUT   (rngclklfpre_undft[6]),
        .RNG8_OUT   (rngclklfpre_undft[7])
    );

    OSC_32M oschf(
        .EN     (t_rnghf_en),
        .CFG    (t_rnghf_cfg[6:0]),
        .CKO    (rngclkhf_undft)
    );

    assign rngclkhf = cmsatpg ? clk : rngclkhf_undft;

    logic [CHAINW/2:0] rngchain0,rngchain1;
    logic rngclkhfxor;

    assign rngchain0[0] = cmsatpg ? 1'b0 : rngclkhf;
    assign rngchain1[0] = cmsatpg ? 1'b0 : ~chaincut & rngchain0[CHAINW/2];
    genvar gvi;
    generate
        for ( gvi = 0; gvi < CHAINW/2; gvi++) begin: gbuf
            RNGCELL_BUF u0( .A(rngchain0[gvi]), .Z(rngchain0[gvi+1]));
            RNGCELL_BUF u1( .A(rngchain1[gvi]), .Z(rngchain1[gvi+1]));
        end
    endgenerate
    assign rngclkhfxor = ^( {rngchain0[CHAINW/2:1],rngchain1[CHAINW/2:1]} & rngchainen[CHAINW-1:0] );

    generate
        for ( gvi = 0; gvi < 8; gvi++) begin: gicg
            assign rngclklfpre[gvi] = cmsatpg ? clk : rngclklfpre_undft[gvi] ;
            ICG uicg(.CK(rngclklfpre[gvi]),.EN('1),.SE(cmsatpg),.CKG(rngclklf[gvi]));
        end
    endgenerate

    `theregfull( rngclklf[0], resetn, t_rngsrc_dat[0], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[1], resetn, t_rngsrc_dat[1], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[2], resetn, t_rngsrc_dat[2], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[3], resetn, t_rngsrc_dat[3], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[4], resetn, t_rngsrc_dat[4], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[5], resetn, t_rngsrc_dat[5], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[6], resetn, t_rngsrc_dat[6], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[7], resetn, t_rngsrc_dat[7], '0 ) <= rngclkhfxor;

    bit [3:0] rngclkhftestfdcnt;
    `theregfull( rngclkhf, sysresetn, rngclkhftestfdcnt, '0 ) <= ( rngclkhftestfdcnt == 9 ) ? 0 : rngclkhftestfdcnt + cmstest ;
    `theregfull( rngclkhf, sysresetn, iptorndhf, '0 ) <= ( rngclkhftestfdcnt == 9 ) ? cmstest ^ iptorndhf : iptorndhf;
    assign iptorndlf = rngclklfpre[0];

    assign rngsrc_dat = cmsatpg ? ~{ t_rnglf_sel, t_rnglf_en, t_rnghf_en, t_rnghf_cfg} : t_rngsrc_dat;

`endif

// cr

    assign { cr_reseed_sel,
            cr_reseed_intval[1:0],
             cr_gen_intval[1:0],
             cr_healthtest_len[5:0],
             cr_postproc_opt[1:0],
             cr_drng_en,
             cr_hlthtest_en,
             cr_pfilter_en, cr_gen_en } = cr_postproc;

    assign sr_rng = {buf_addr[2],|buf_addr[1:0], sr_drng_reseed_req, sr_bufrdy, sr_hlthtest_errcnt[11:0], rngcnt[15:0]} | '0;

    `theregrn( sr_hlthtest_errreg ) <= sr_hlthtest_err;
    assign sr_hlthtest_errrise = ( sr_hlthtest_err && ~sr_hlthtest_errreg );
    `theregrn( sr_hlthtest_errcnt ) <= ar_start ? '0 : sr_hlthtest_errcnt + sr_hlthtest_errrise;
    `theregrn( hlthtest_errof ) <= ( sr_hlthtest_errcnt == '1);

    logic [255:0]   dr_psz_str, dr_gen_dat, dr_gen_reseed;

    apb_shfin #(.A(12'h20), .DW(32), .REVY(1), .SFRCNT(8)) sfr_drpsz     (.dr(dr_psz_str),.*);
    apb_shfin #(.A(12'h24), .DW(32), .REVY(1), .SFRCNT(8)) sfr_drgen     (.dr(dr_gen_dat),.*);
    apb_shfin #(.A(12'h28), .DW(32), .REVY(1), .SFRCNT(8)) sfr_drreseed  (.dr(dr_gen_reseed),.*);
    apb_buf  #(.BAW(3), .A(12'h30), .DW(32) ) sfr_buf (.prdata32(),.*);

    `theregrn( rngcore_en ) <= ar_start ? '1 : stop2 ? '0 : rngcore_en;
    assign stop2 = ( rngcnt == opt_rngcnt - 1 ) & chnlo_done | ar_stop;
    `theregrn( rngcnt ) <= ar_start ? '0 : rngcnt + chnlo_done;
    `theregrn( intr ) <= '0;
    `theregrn( err  ) <= '0;

    assign busy = rngcore_en;
    assign done = rngcore_en & ( rngcnt == opt_rngcnt - 1 ) & chnlo_done ;

    rng_top #(
            .ANA_NUM  (ETPC)
        )c(
    /*        input  logic              */ .clk,
    /*        input  logic              */ .rstn    (resetn),
    /**/
    /*    // entropy*/
    /*        input  logic [ETPC-1:0]   */ .clk_ana     (rngclklf[7:0]),
    /*        input  logic [ETPC-1:0]   */ .ana_data    (rngsrc_dat[7:0]),
    /*        input  logic [ETPC-1:0]   */ .ana_en      (cr_anaen[7:0]),
    /*        input  logic [ETPC-1:0]   */ .ana_vld     (cr_anavld[7:0]),
    /**/
    /*    // ctrl*/
    /*        input  logic              */ .rngcore_en  ( rngcore_en ),  // enable
    /*    */
    /*    // cr    */
    /*        input  logic              */ .partityfilter_en          ( cr_pfilter_en  ),
    /*        input  logic              */ .healthtest_en             ( cr_hlthtest_en ),
    /*        input  logic              */ .trng_drng_sel             ( cr_drng_en ), // 0,trng;1,drng
    /*        input  logic [1:0]        */ .postprocess_opt           ( cr_postproc_opt[1:0] ),
    /*        input  logic [5:0]        */ .healthtest_length         ( cr_healthtest_len[5:0] ),
    /*        input  logic [1:0]        */ .generate_interval         ( cr_gen_intval[1:0] ),
    /*        input  logic [1:0]        */ .reseed_interval           ( cr_reseed_intval[1:0] ),
//                                           .reseed_sel                ( cr_reseed_sel ),
    /*        input  logic [255:0]      */ .personalization_string    ( dr_psz_str[255:0] ),
    /*        input  logic              */ .additional_input_gen_en   ( cr_gen_en ), //pulse?
    /*        input  logic [255:0]      */ .additional_input_generate ( dr_gen_dat[255:0] ),
    /*        input  logic [255:0]      */ .additional_input_reseed   ( dr_gen_reseed[255:0] ),
    /*    */
    /*    // sr    */
    /*        output logic              */ .drng_reseed_req           ( sr_drng_reseed_req ), // drng req for sw
    /*        output logic              */ .buf_ready                 ( sr_bufrdy ), // sr
    /*        output logic              */ .healthtest_err            ( sr_hlthtest_err ),
    /*    */
    /*    // buf    */
    /*        input  logic [2:0]        */ .buf_addr,
    /*        input  logic              */ .buf_read,
    /*        input  logic              */ .buf_write,
    /*        input  logic [31:0]       */ .buf_datain,
    /*        output logic [31:0]       */ .buf_dataout,
    /*    */
//                                           .generate_run              ( ar_generate ),
//                                           .generate_done             ( fr_generate ),

    /*    // channel    */
    /*        output logic [127:0]      */ .rngcore_dataout     (rngcore_data128),
    /*        output logic              */ .rngcore_dataout_vld,
    /*        input  logic              */ .rngcore_rddone      (chnlo_done)
    );
        assign fr_generate = '0;


    assign rngcore_data = rngcore_data128;

    scedma_chnl chnlo(
        .clk,
        .resetn,
        .thecfg   (chnlo_cfg   ),
        .start    (chnlo_start ),
        .busy     (chnlo_busy  ),
        .done     (chnlo_done  ),
        .rpreq    (chnlo_rpreq ),
        .rpres    (chnlo_rpres ),
        .wpreq    (chnl_wpreq  ),
        .wpres    (chnl_wpres  ),
        .intr     (  )
    );

    assign chnlo_start = rngcore_en & rngcore_dataout_vld & ~chnlo_busy ;

    assign chnlo_rpres.segready = '1;
    assign chnlo_rpres.segrdatvld = '1;
    `theregrn( chnlo_rpres.segrdat ) <= rngcore_data[chnlo_rpreq.segptr[1:0]];

    localparam scedma_pkg::segcfg_t RNGSEG_DO      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h0, segsize: 'd4, isfifo:'0, isfifostream:0, fifoid:'0 };

    assign chnlo_cfg.rpsegcfg = RNGSEG_DO;
    assign chnlo_cfg.wpsegcfg = ~opt_segsel ? scedma_pkg::SEG_RNGA : scedma_pkg::SEG_RNGB;
    assign chnlo_cfg.wpptr_start = '0;
    assign chnlo_cfg.transsize = 4;

    assign chnlo_cfg.chnlid = '0;
    assign chnlo_cfg.rpptr_start = '0;
    assign chnlo_cfg.opt_ltx = '0;
    assign chnlo_cfg.opt_xor = '0;
    assign chnlo_cfg.opt_cmpp = '0;
    assign chnlo_cfg.opt_prm = '0;
    assign chnlo_cfg.wpffen = '0;

endmodule

module apb_shfin
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=32,
      parameter REVX=0,
      parameter REVY=0,
      parameter IV=32'h0,
      parameter SFRCNT=4
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                          sfrlock     ,
        output logic [0:SFRCNT-1][DW-1:0]   dr
);

    logic [0:SFRCNT-1][DW-1:0]   dr0;
    logic[DW-1:0] prdata;
    logic sfrsel, apbwr;

    assign sfrsel = ( apbs.paddr == A[AW-1:0] );
    assign apbwr = ~sfrlock & apbs.psel & apbs.penable & apbs.pwrite;
   `theregfull( pclk, resetn, dr0, IV ) <= ( sfrsel & apbwr ) ? { dr0, apbs.pwdata[DW-1:0] } : dr0;

    sfrdatrev #(.DW(DW),.SFRCNT(SFRCNT),.REVX(REVX), .REVY(REVY)) dx(.din(dr0),.dout(dr));

endmodule

module apb_buf
#(
      parameter A=0,
      parameter BAW=3,
      parameter AW=12,
      parameter DW=32,
      parameter SFRCNT=8
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                          sfrlock     ,
        output logic [31:0]         prdata32,
        output logic [BAW-1:0]      buf_addr, // addr can keep inc1 mode
        output logic                buf_write,
        output logic                buf_read,
        output logic [DW-1:0]       buf_datain,
        input logic  [DW-1:0]       buf_dataout
);

    logic[DW-1:0] prdata;
    logic sfrsel, apbwr, apbrd;

    assign sfrsel = ( apbs.paddr[AW-1:BAW+2] == A[AW-1:BAW+2] );
    assign apbwr = ~sfrlock & apbs.psel & apbs.penable & apbs.pwrite;
    assign apbrd = ~sfrlock & apbs.psel & apbs.penable & ~apbs.pwrite;

//    assign buf_addr = apbs.paddr[BAW+2-1:2];
    logic clk;
    assign clk = pclk;
    `theregrn( buf_addr ) <= buf_addr + buf_write + buf_read;
    assign buf_write = sfrsel & apbwr;
    assign buf_read = sfrsel & apbrd;
    assign buf_datain = apbs.pwdata;
    assign prdata32 = sfrsel ? buf_dataout : '0;

endmodule

/*

module trngsrc #(
        parameter CHAINW = 128
)(
    input wire        ana_rng_0p1u,
    input  logic clk, resetn, sysresetn, cmsatpg, cmsbist,
    input logic rnghf_en,
    input logic rnglf_en,
    input logic [2:0] rnglf_sel,
    input logic [6:0] rnghf_cfg, ipt_rngcfg,
    input logic chaincut,
    output logic iptorndlf, iptorndhf,
    output logic [7:0] rngclklf, rngsrc_dat
);

    logic [2:0] t_rnglf_sel;
    logic       t_rnglf_en;
    logic       t_rnghf_en;
    logic [6:0] t_rnghf_cfg;
    logic [7:0] t_rngsrc_dat;

    logic [7:0] rngclklfpre;
    logic cmstest;
    logic [7:0] rngclklfpre_undft, rngclklf;
    logic rngclkhf_undft, rngclkhf;

    assign cmstest = cmsbist;
    assign t_rnglf_sel = cmsatpg ? '0 : cmstest ? '1 : rnglf_sel;
    assign t_rnglf_en =  cmsatpg ? '0 : cmstest ? '1 : rnglf_en;
    assign t_rnghf_en =  cmsatpg ? '0 : cmstest ? '1 : rnghf_en;
    assign t_rnghf_cfg = cmsatpg ? 7'b0100110 : cmstest ? ipt_rngcfg : rnghf_cfg;
//    assign rngclklfpre = cmsatpg ? clk

    RNG_CELL osclf(
        .IN_0P1U    (ana_rng_0p1u),
        .SEL        (t_rnglf_sel[2:0]),
        .EN         (t_rnglf_en),
        .RNG1_OUT   (rngclklfpre_undft[0]),
        .RNG2_OUT   (rngclklfpre_undft[1]),
        .RNG3_OUT   (rngclklfpre_undft[2]),
        .RNG4_OUT   (rngclklfpre_undft[3]),
        .RNG5_OUT   (rngclklfpre_undft[4]),
        .RNG6_OUT   (rngclklfpre_undft[5]),
        .RNG7_OUT   (rngclklfpre_undft[6]),
        .RNG8_OUT   (rngclklfpre_undft[7])
    );

    OSC_32M oschf(
        .EN     (t_rnghf_en),
        .CFG    (t_rnghf_cfg[6:0]),
        .CKO    (rngclkhf_undft)
    );

    assign rngclkhf = cmsatpg ? clk : rngclkhf_undft;

    logic [CHAINW/2:0] rngchain0,rngchain1;
    logic rngclkhfxor;

    assign rngchain0[0] = cmsatpg ? 1'b0 : rngclkhf;
    assign rngchain1[0] = cmsatpg ? 1'b0 : ~chaincut & rngchain0[CHAINW/2];
    genvar gvi;
    generate
        for ( gvi = 0; gvi < CHAINW/2; gvi++) begin: gbuf
            RNGCELL_BUF u0( .A(rngchain0[gvi]), .Z(rngchain0[gvi+1]));
            RNGCELL_BUF u1( .A(rngchain1[gvi]), .Z(rngchain1[gvi+1]));
        end
    endgenerate
    assign rngclkhfxor = ^( {rngchain0[CHAINW/2:1],rngchain1[CHAINW/2:1]} & rngchainen[CHAINW-1:0] );

    generate
        for ( gvi = 0; gvi < 8; gvi++) begin: gicg
            assign rngclklfpre[gvi] = cmsatpg ? clk : rngclklfpre_undft[gvi] ;
            ICG uicg(.CK(rngclklfpre[gvi]),.EN('1),.SE(cmsatpg),.CKG(rngclklf[gvi]));
        end
    endgenerate

    `theregfull( rngclklf[0], resetn, t_rngsrc_dat[0], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[1], resetn, t_rngsrc_dat[1], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[2], resetn, t_rngsrc_dat[2], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[3], resetn, t_rngsrc_dat[3], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[4], resetn, t_rngsrc_dat[4], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[5], resetn, t_rngsrc_dat[5], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[6], resetn, t_rngsrc_dat[6], '0 ) <= rngclkhfxor;
    `theregfull( rngclklf[7], resetn, t_rngsrc_dat[7], '0 ) <= rngclkhfxor;

    bit [3:0] rngclkhftestfdcnt;
    `theregfull( rngclkhf, sysresetn, rngclkhftestfdcnt, '0 ) <= ( rngclkhftestfdcnt == 9 ) ? 0 : rngclkhftestfdcnt + cmstest ;
    `theregfull( rngclkhf, sysresetn, iptorndhf, '0 ) <= ( rngclkhftestfdcnt == 9 ) ? cmstest ^ iptorndhf : iptorndhf;
    assign iptorndlf = rngclklfpre[0];

    assign rngsrc_dat = cmsatpg ? ~{ t_rnglf_sel, t_rnglf_en, t_rnghf_en, t_rnghf_cfg} : t_rngsrc_dat;

endmodule : trngsrc
*/