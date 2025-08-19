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

module aes #(

        parameter RAW = 8,
        parameter ERRCNT = 8,
        parameter INTCNT = 8
    )(

    input  logic clk, clkram, resetn, sysresetn, cmsatpg, cmsbist,
    rbif.slave   rbs   ,
    input  logic ramclr,
    apbif.slavein           apbs,
    apbif.slave             apbx,
    output  chnlreq_t       chnl_rpreq, chnl_wpreq   ,
    input   chnlres_t       chnl_rpres, chnl_wpres   ,

    input  logic [31:0]    maskin,
    output bit busy, done,
    output logic [0:ERRCNT-1]      err,
    output logic [0:INTCNT-1]      intr
);
// localparam
// ■■■■■■■■■■■■■■■

    localparam [7:0] SEGID_AKEY = scedma_pkg::SEGID_AKEY ;
    localparam [7:0] SEGID_AIB  = scedma_pkg::SEGID_AIB  ;
    localparam [7:0] SEGID_AOB  = scedma_pkg::SEGID_AOB  ;

    localparam segcfg_t SEG_AKEY = scedma_pkg::SEGCFGS[SEGID_AKEY];
    localparam segcfg_t SEG_AIB  = scedma_pkg::SEGCFGS[SEGID_AIB ];
    localparam segcfg_t SEG_AOB  = scedma_pkg::SEGCFGS[SEGID_AOB ];

//  cr_func

//    localparam AF_INIT    = 8'hff ;
    localparam AF_KS      = 2'h0 ;
    localparam AF_ENC     = 2'h1 ;
    localparam AF_DEC     = 2'h2 ;

    localparam MFSM_IDLE      = 8'h00;
    localparam MFSM_DONE      = 8'hff;
    localparam MFSM_AF        = 8'h01;
    localparam MFSM_LD_K      = 8'h10;
    localparam MFSM_LD_D      = 8'h11;
    localparam MFSM_LD_IV     = 8'h12;
    localparam MFSM_WB_D      = 8'h30;
    localparam MFSM_WB_IV     = 8'h31;

    localparam scedma_pkg::segcfg_t AESSEG_K      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h08, segsize: 'd8, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t AESSEG_I      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h00, segsize: 'd4, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t AESSEG_O      = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h44, segsize: 'd4, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t AESSEG_IV     = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h04, segsize: 'd4, isfifo:'0, isfifostream:0, fifoid:'0 };
    localparam scedma_pkg::segcfg_t AESSEG_OFB_X  = '{ segid:'0, segtype:ST_NONE, ramsel:'0, segaddr: 'h48, segsize: 'd4, isfifo:'0, isfifostream:0, fifoid:'0 };

// opt
    localparam MODE_ECB = 3'h0;
    localparam MODE_CBC = 3'h1;
    localparam MODE_CTR = 3'h2;
    localparam MODE_CFB = 3'h4;
    localparam MODE_OFB = 3'h3;


// typedef
// ■■■■■■■■■■■■■■■

    bit [7:0]   cr_func;
//    bit [###]   cr_opt;

    logic [7:0] mfsm, mfsmnext;
    bit mfsmtog, mfsmdone, mfsm_done;
    logic acore_start, chnli_start, chnlo_start;
    logic acore_busy,  chnli_busy, chnlo_busy;
    logic acore_done,  chnli_done, chnlo_done;
    logic [1:0] ramerror;
    logic acore_en, chnli_en, chnlo_en;
    chnlreq_t chnlo_rpreq, chnli_wpreq, chnl_rpreq0;
    chnlres_t chnlo_rpres, chnli_wpres, chnl_rpres0, aramres;
    chnlcfg_t chnli_cfg, chnlo_cfg;
    bit [7:0] chnlo_intr, chnli_intr;
    bit optlock;

    logic [RAW-1:0] chnl_ramadd, chnl_segptr;
    logic  chnl_ramrd, chnl_ramwr;
    dat_t  chnl_ramwdat;
    logic [31:0] ramwdat, ramrdat, acore_ramrdat, acore_ramwdat;
    logic [3:0] chnl_ramwrs, ramwr;
    logic [RAW-1:0]  ramadd, acore_ramadd;
    logic ramrd, acore_ramrd, acore_ramwr;
    logic ramready;

    logic [8:0] opt_d32, opt_key32;
    bit [3:0] opt_mode0, opt_klen0;
    bit opt_ifstart0;
    bit [3:0] opt_mode, opt_klen;
    bit opt_ifstart;
    bit start;
    bit [0:3][31:0] opt_iv;
    adr_t [0:3] cr_segptrstart;
    logic opt_mode_ofb;
    logic [15:0] opt_aescnt;
    logic [15:0] opt_aescnt0, aescnt, aescntnext;
    logic aes0;
    logic ramclrbusy;
    logic [5:0] cr_optltx;

    logic [31:0] maskseed;
    logic maskseedupd;

// apb
// ■■■■■■■■■■■■■■■

    logic apbrd, apbwr;
    logic pclk;
    logic sfrlock;
    assign pclk = clk;

    `theregrn( sfrlock ) <= optlock ? 1'b1 : mfsm_done ? '0 : sfrlock;

    `apbs_common;
    assign apbx.prdata = '0
                        | sfr_crfunc.prdata32 | sfr_srmfsm.prdata32 | sfr_fr.prdata32
                        | sfr_opt.prdata32 | sfr_opt1.prdata32 | sfr_optltx.prdata32 | sfr_segptr.prdata32
                        | sfr_maskseed.prdata32
                        ;

    apb_cr #(.A('h00), .DW(8))      sfr_crfunc      (.cr(cr_func), .prdata32(),.*);
    apb_ar #(.A('h04), .AR(32'h5a)) sfr_ar          (.ar(start),.*);
    apb_sr #(.A('h08), .DW(8))      sfr_srmfsm      (.sr(mfsm), .prdata32(),.*);
    apb_fr #(.A('h0c), .DW(4))      sfr_fr          (.fr({chnli_done, chnlo_done, acore_done, mfsm_done}), .prdata32(),.*);

    apb_cr #(.A('h10), .DW(9))       sfr_opt        (.cr({opt_ifstart0,opt_mode0,opt_klen0}), .prdata32(),.*); //## width?
    apb_cr #(.A('h14), .DW(16))      sfr_opt1       (.cr(opt_aescnt0), .prdata32(),.*);
    apb_cr #(.A('h18), .DW(6))       sfr_optltx     (.cr(cr_optltx), .prdata32(),.*);

//    apb_cr #(.A('h14), .DW(32), .SFRCNT(4))      sfr_optiv      (.cr(opt_iv), .prdata32(),.*); //## width?
    apb_cr #(.A('h20), .DW(32))      sfr_maskseed     (.cr(maskseed), .prdata32(),.*);
    apb_ar #(.A('h24), .AR(32'h5a))  sfr_maskseedar   (.ar(maskseedupd),  .*);

    apb_cr #(.A('h30), .DW(scedma_pkg::AW), .SFRCNT(4) )      sfr_segptr    (.cr(cr_segptrstart), .prdata32(),.*); //## width?

    assign optlock = ( start & ( mfsm == MFSM_IDLE));

    `theregrn( opt_ifstart ) <= optlock ? opt_ifstart0 : opt_ifstart ;
    `theregrn( opt_mode )    <= optlock ? opt_mode0    : opt_mode ;
    `theregrn( opt_klen )    <= optlock ? opt_klen0    : opt_klen ;
    `theregrn( opt_aescnt )  <= optlock ? opt_aescnt0  : opt_aescnt ;

    assign opt_mode_ofb = ( opt_mode == MODE_OFB );

    assign busy = |mfsm | ramclrbusy;
    assign done = mfsm_done;

// mfsm
// ■■■■■■■■■■■■■■■
    `theregfull(clk, resetn, mfsm, MFSM_IDLE ) <= ( start & ( mfsm == MFSM_IDLE)) | mfsmdone ? mfsmnext : mfsm;
    `theregrn( mfsmtog ) <= ( start & ( mfsm == MFSM_IDLE)) | mfsmdone;
    assign mfsm_done = ( mfsm == MFSM_DONE );

    `theregrn( aescnt ) <= ( start & ( mfsm == MFSM_IDLE)) ? '0 : ( mfsm == MFSM_WB_D ) & chnlo_done ? aescntnext : aescnt;
    assign aes0 = opt_ifstart & ( aescnt == 0 );
    assign aescntnext = aescnt + 1;

    always_comb begin
        mfsmnext = mfsm;
        mfsmdone = '0;
        case (cr_func)
            AF_KS:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_K;
                    MFSM_LD_K : begin
                                                mfsmnext = MFSM_AF;         mfsmdone = chnli_done;
                        end
                    MFSM_AF : begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = acore_done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            AF_ENC, AF_DEC:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_LD_IV;
                    MFSM_LD_IV : begin
                                                mfsmnext = MFSM_LD_D;       mfsmdone = chnli_done;
                        end
                    MFSM_LD_D : begin
                                                mfsmnext = MFSM_AF;         mfsmdone = chnli_done;
                        end
                    MFSM_AF : begin
                                                mfsmnext = MFSM_WB_IV;      mfsmdone = acore_done;
                        end
                    MFSM_WB_IV : begin
                                                mfsmnext = MFSM_WB_D;       mfsmdone = chnlo_done;
                        end
                    MFSM_WB_D : begin
                        if( opt_aescnt == aescnt )begin
                                                mfsmnext = MFSM_DONE;       mfsmdone = chnlo_done;
                            end
                            else begin
                                                mfsmnext = MFSM_LD_IV;       mfsmdone = chnlo_done;
                            end
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            default :
                begin
                    mfsmnext = mfsm;
                    mfsmdone = '1;
                end
        endcase
    end

// subcore, chnl
// ■■■■■■■■■■■■■■■

    `theregrn( acore_start ) <= mfsmtog & ( mfsm == MFSM_AF  );

    assign acore_en = ( mfsm == MFSM_AF );

    logic [31:0] acore_ramwdat1, acore_ramwdat0, aesmaskdat;
    logic [2:0] opt_mode1;
    assign opt_mode1 = opt_mode + 1;

    bit [1:0] aesir;
    assign aesir = ( cr_func == AF_KS  ) ? 2'h0 :
                   ( cr_func == AF_DEC )&&(( opt_mode == MODE_ECB ) | ( opt_mode == MODE_CBC )) ? 2'h3 : 'h2;
//                   ( cr_func == AF_ENC ) ? 2'h2 :

    AesCore acore(
            .Clk              (clk),
            .Resetn           (resetn),
            .StartAes         (acore_start),
            .AesDone          (acore_done),
            .AesIR            (aesir),
            .AesLen           (opt_klen[1:0]),
            .AesMode          (opt_mode1),

//        	.IVector0 		  (opt_iv[0]),
//        	.IVector1 		  (opt_iv[1]),
//        	.IVector2 		  (opt_iv[2]),
//        	.IVector3 		  (opt_iv[3]),

            .AesRamRd         (acore_ramrd),
            .AesRamWr         (acore_ramwr),
            .AesRamAdr        (acore_ramadd),
            .AesRamDat        (acore_ramwdat),
//            .AesRamDat1       (acore_ramwdat1),
            .RamAesDat        (acore_ramrdat),
            //##

            .MaskIn           (aesmaskdat)
		);

// chnl behavior
// ■■■■■■■■■■■■■■■


    drng_lfsr #( .LFSR_W(229),.LFSR_NODE({ 10'd228, 10'd225, 10'd219 }), .LFSR_OW(32), .LFSR_IW(32), .LFSR_IV('h55aa_aa55_5a5a_a5a5) )
        ua( .clk(clk), .sen('1), .resetn(sysresetn), .swr(maskseedupd), .sdin(maskseed), .sdout(aesmaskdat) );


// chnl behavior
// ■■■■■■■■■■■■■■■
    logic ld_d_to_iv, ld_iv_to_i;
    logic ld_iv_from_aesram;

    assign ld_iv_to_i = ld_d_to_iv;
    assign ld_d_to_iv =  ~(( opt_mode == MODE_ECB ) | ( opt_mode == MODE_CBC )) ;
    assign ld_iv_from_aesram = '0;// ~aes0 && (mfsm == MFSM_LD_IV) && (( opt_mode == MODE_CBC ) | ( opt_mode == MODE_OFB ) |  ( opt_mode == MODE_CFB ));

    adr_t segptrdyna_rd, segptrdyna_rdnext;
    adr_t segptrdyna_wr, segptrdyna_wrnext;

    `theregrn( segptrdyna_rd ) <= ( mfsm == MFSM_IDLE ) | ( mfsm == MFSM_DONE ) ? '0 :
                               ( mfsm == MFSM_LD_D ) & chnli_done ? segptrdyna_rdnext : segptrdyna_rd;
     assign segptrdyna_rdnext = ( chnl_rpreq.segptr == chnli_cfg.rpsegcfg.segsize - 1 ) ? '0 : chnl_rpreq.segptr + 1;

   `theregrn( segptrdyna_wr ) <= ( mfsm == MFSM_IDLE ) | ( mfsm == MFSM_DONE ) ? '0 :
                               ( mfsm == MFSM_WB_D ) & chnlo_done ? segptrdyna_wrnext : segptrdyna_wr;
     assign segptrdyna_wrnext = ( chnl_wpreq.segptr == chnlo_cfg.wpsegcfg.segsize - 1 ) ? '0 : chnl_wpreq.segptr + 1;

    `theregrn( chnli_start ) <= mfsmtog & chnli_en;
    `theregrn( chnlo_start ) <= mfsmtog & chnlo_en;

    localparam PTRID_IV   = 0;
    localparam PTRID_AKEY = 1;
    localparam PTRID_AIB  = 2;
    localparam PTRID_AOB  = 3;

	assign opt_key32 = ( opt_klen == 0 ) ? 4 : ( opt_klen == 1 ) ? 6 : 8;
	assign opt_d32 = 4;
    always_comb begin
        chnli_en = '0;
        chnli_cfg.opt_ltx = '0;
        case(mfsm)
            MFSM_LD_K      :
                begin
                    chnli_cfg.wpsegcfg = AESSEG_K;
			        chnli_cfg.rpptr_start = cr_segptrstart[PTRID_AKEY];
			        chnli_cfg.rpsegcfg = SEG_AKEY;
                    chnli_cfg.opt_ltx = cr_optltx[PTRID_AKEY];
			        chnli_cfg.transsize = opt_key32;
                    chnli_en = '1;
                end
            MFSM_LD_D      :
                begin
                    chnli_cfg.wpsegcfg = ld_d_to_iv ? AESSEG_IV : AESSEG_I;
			        chnli_cfg.rpptr_start = cr_segptrstart[PTRID_AIB] + segptrdyna_rd;
			        chnli_cfg.rpsegcfg = SEG_AIB;
                    chnli_cfg.opt_ltx = cr_optltx[PTRID_AIB];
			        chnli_cfg.transsize = opt_d32;
                    chnli_en = '1;
                end
            MFSM_LD_IV      :
                begin
                    chnli_cfg.wpsegcfg = ld_iv_to_i ? AESSEG_I : AESSEG_IV;
                    chnli_cfg.rpptr_start = cr_segptrstart[PTRID_IV];
                    chnli_cfg.rpsegcfg =    SEG_AKEY;
                    chnli_cfg.opt_ltx =     cr_optltx[PTRID_IV];
                    chnli_cfg.transsize = opt_d32;
                    chnli_en = '1;
                end
            default : /* default */
                begin
                    chnli_cfg.wpsegcfg = AESSEG_I;
			        chnli_cfg.rpptr_start = cr_segptrstart[PTRID_AIB];
			        chnli_cfg.rpsegcfg = SEG_AIB;
			        chnli_cfg.transsize = opt_d32;
                    chnli_en = '0;
                end
        endcase
    end

    assign chnli_cfg.chnlid = '0;
    assign chnli_cfg.wpptr_start = '0;
//    assign chnli_cfg.opt_ltx = '0;
    assign chnli_cfg.opt_xor = '0;
    assign chnli_cfg.opt_cmpp = '0;
    assign chnli_cfg.opt_prm = '0;
    assign chnli_cfg.wpffen = '0;

    scedma_pkg::segcfg_t wbiv_rdsegcfg;

    always_comb begin
        chnlo_en = '0;
        chnlo_cfg.wpsegcfg = SEG_AOB;
        chnlo_cfg.wpptr_start = cr_segptrstart[PTRID_AOB] + segptrdyna_wr;
        chnlo_cfg.transsize = opt_d32;
        chnlo_cfg.opt_ltx = cr_optltx[PTRID_AOB];
        chnlo_cfg.rpsegcfg = AESSEG_O;
        case(mfsm)
            MFSM_WB_D:
                begin
                    chnlo_en = '1;
                    chnlo_cfg.rpsegcfg = ( opt_mode == MODE_OFB ) ? AESSEG_OFB_X : AESSEG_O;
                end
            MFSM_WB_IV:
                begin
                    chnlo_en = '1;
                    chnlo_cfg.rpsegcfg = wbiv_rdsegcfg;
                    chnlo_cfg.wpsegcfg = SEG_AKEY;
                    chnlo_cfg.wpptr_start = cr_segptrstart[PTRID_IV];
                    chnlo_cfg.transsize = opt_d32;
                    chnlo_cfg.opt_ltx = cr_optltx[PTRID_IV];
                end
            default : /* default */
                begin
                    chnlo_en = '0;
                end
        endcase
    end

    assign wbiv_rdsegcfg =  ( opt_mode == MODE_ECB ) ? (( cr_func == AF_ENC ) ? AESSEG_IV : AESSEG_IV ) :
                            ( opt_mode == MODE_CBC ) ? (( cr_func == AF_ENC ) ? AESSEG_O  : AESSEG_I  ) :
                            ( opt_mode == MODE_CTR ) ? (( cr_func == AF_ENC ) ? AESSEG_I  : AESSEG_I  ) :
                            ( opt_mode == MODE_CFB ) ? (( cr_func == AF_ENC ) ? AESSEG_O  : AESSEG_IV ) :
//                            ( opt_mode == MODE_OFB ) ? (( cr_func == AF_ENC ) ? AESSEG_O : AESSEG_IV ) :
                                                                                            AESSEG_O ;


    assign chnlo_cfg.chnlid = '0;
    assign chnlo_cfg.rpptr_start = '0;
    assign chnlo_cfg.opt_xor = '0;
    assign chnlo_cfg.opt_cmpp = '0;
    assign chnlo_cfg.opt_prm = '0;
    assign chnlo_cfg.wpffen = '0;

// chnl instance
// ■■■■■■■■■■■■■■■

    assign chnl_rpreq.segcfg   = chnl_rpreq0.segcfg   ;
    assign chnl_rpreq.segaddr  = chnl_rpreq0.segaddr  ;
    assign chnl_rpreq.segptr   = chnl_rpreq0.segptr   ;
    assign chnl_rpreq.segrd    = chnl_rpreq0.segrd    ;
    assign chnl_rpreq.segwr    = chnl_rpreq0.segwr    ;
    assign chnl_rpreq.segwdat  = chnl_rpreq0.segwdat  ;
    assign chnl_rpreq.porttype = chnl_rpreq0.porttype ;

    scedma_chnl chnli(
        .clk,
        .resetn,
        .thecfg   (chnli_cfg   ),
        .start    (chnli_start ),
        .busy     (chnli_busy  ),
        .done     (chnli_done  ),
        .rpreq    (chnl_rpreq0 ),
        .rpres    (chnl_rpres0 ),
        .wpreq    (chnli_wpreq ),
        .wpres    (chnli_wpres ),
        .intr     (chnli_intr  )
    );

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
        .intr     (chnlo_intr  )
    );

// mem data path
// ■■■■■■■■■■■■■■■
    logic segrdat_ctren;
    dat_t segrdat_ctr, aramres_segrdatx, segrdat_ctrx;
    logic opt_crtopt1, opt_crtopt0;
    assign { opt_crtopt1, opt_crtopt0 } = cr_optltx[5:4];
    assign aramres_segrdatx = ~opt_crtopt0 ?
                                      aramres.segrdat :
                                    { aramres.segrdat[7:0], aramres.segrdat[15:8], aramres.segrdat[23:16], aramres.segrdat[31:24]};
    assign segrdat_ctr = ~opt_crtopt0 ?
                                      segrdat_ctrx :
                                    { segrdat_ctrx[7:0], segrdat_ctrx[15:8], segrdat_ctrx[23:16], segrdat_ctrx[31:24]};
    assign segrdat_ctrx = aramres_segrdatx + 'h1;
    assign segrdat_ctren = ( opt_mode == MODE_CTR ) && ( mfsm == MFSM_WB_IV )
                        && ( opt_crtopt1 ? ( chnlo_rpreq.segptr == 'h3 ) : ( chnlo_rpreq.segptr == 'h0 ));

    assign chnl_ramadd = chnlo_en ?  chnlo_rpreq.segaddr + chnlo_rpreq.segptr  :
                                     chnli_wpreq.segaddr + chnli_wpreq.segptr  ; //chnli_en ?

    assign chnl_segptr = chnlo_en ?  chnlo_rpreq.segptr  :
                                     chnli_wpreq.segptr  ; //chnli_en ?

    assign chnl_ramrd  = chnli_wpreq.segrd | chnlo_rpreq.segrd;
    assign chnl_ramwr  = chnli_wpreq.segwr | chnlo_rpreq.segwr;
    assign chnl_ramwrs = {4{chnl_ramwr}};

    assign chnl_ramwdat = chnlo_en ?  chnlo_rpreq.segwdat  :
                                      chnli_wpreq.segwdat  ; //chnli_en ?

    assign ramrd = acore_en ? acore_ramrd : chnl_ramrd;
    assign ramwr = acore_en ? {4{acore_ramwr}} : {4{chnl_ramwr}};
    assign ramadd = acore_en ? acore_ramadd : chnl_ramadd;
    assign ramwdat = acore_en ? acore_ramwdat : { chnl_ramwdat, chnl_ramwdat };

    assign chnli_wpres = aramres;
    assign chnl_rpres0 = chnl_rpres;
    assign chnlo_rpres.segready = aramres.segready;
    assign chnlo_rpres.segrdatvld = aramres.segrdatvld;
    assign chnlo_rpres.segrdat = segrdat_ctren ? segrdat_ctr : aramres.segrdat ;

    assign acore_ramrdat = ramrdat;
    assign aramres.segready = '1;  // pram always ready
    assign aramres.segrdat  = ramrdat ;
    assign aramres.segrdatvld = '1;

// mem
// ■■■■■■■■■■■■■■■

    localparam sramcfg_t thecfg = '{
        AW: RAW,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 256,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    };

    cryptoram #(
        .ramname    ("ARAM"), // HRAM, PRAM, ARAM, SCERAM
        .thecfg     (thecfg)
    )m(
        .clk(clkram), .resetn, .cmsatpg, .cmsbist,.rbs,
        .clkram(clkram), .clkramen('1),
        .ramaddr (ramadd[RAW-1:0] ),
        .ramclr(ramclr),
        .ramclren(ramclrbusy),
        .ramen('1),
        .ramrd(ramrd),
        .ramwr(ramwr),
        .ramwdat(ramwdat),
        .ramrdat(ramrdat),
        .ramready(ramready),
        .ramerror(ramerror)
    );

// err/intr
// ■■■■■■■■■■■■■■■

    `theregrn( intr[0] ) <= ( mfsm == MFSM_DONE );
    `theregrn( err[0:1] ) <= ramerror;

endmodule

module dummytb_aes ();

    logic clk, resetn, cmsatpg, cmsbist, sysresetn;
    apbif apbs();
    rbif #(.AW(8    ),      .DW(36))    rbs     ();
    chnlreq_t       chnl_rpreq, chnl_wpreq;
    chnlres_t       chnl_rpres, chnl_wpres;
    logic [0:8-1]      err;
    logic [0:8-1]      intr;
    logic [31:0] maskin;
    logic busy,done,clkram,ramclr;
   aes u1(
        .apbs(apbs),
        .apbx(apbs),
        .*
    );



endmodule

