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

module alucomm #(
    parameter DW = 64,
    parameter LW = 4096,
    parameter DWW = $clog2(DW),
    parameter LWW = $clog2(LW)+1,
    parameter RAW = $clog2(LW/DW)+2
)(
    input logic clk,
    input logic resetn,
    input logic [7:0] func,
    input logic [31:0] opt,
    input logic start,
    output logic busy,
    output logic done,
    input logic [LWW-1:0] alen,
    output logic [RAW-1:0] ramaddr,
    output logic           ramrd,
    output logic           ramwr,
    output logic [DW-1:0]  ramwdat,
    input logic [DW-1:0]   ramrdat,
    output logic crreg
);

    localparam AF_0       = 8'h0 ;
    localparam AF_DIV     = 8'h1 ;
    localparam AF_ADD     = 8'h2 ;
    localparam AF_SUB     = 8'h3 ;
    localparam AF_SFT     = 8'h10 ;
    localparam AF_SFTW    = 8'h11 ;
    localparam AF_BLG     = 8'h20 ;
    localparam AF_BEX     = 8'h30 ;

    parameter RAMBASE_A = 0;
    parameter RAMBASE_B = RAMBASE_A + LW*2/DW;
    parameter RAMBASE_C = RAMBASE_B + LW/DW;

    localparam MFSM_IDLE = 'h0;
    localparam MFSM_RND1 = 'h3;
    localparam MFSM_SFT1 = 'h4;
    localparam MFSM_SFTR = 'h5;
    localparam MFSM_SFTW = 'h6;
    localparam MFSM_DONE = 'hF;
    localparam MFSM_EX = 'h7;

    logic [$clog2(LW/DW):0] acnt;
    logic [7:0] mfsm, mfsmnext;
    logic [7:0] mfsm_rnd0cyc, mfsm_rnd1cyc, mfsm_sft1cyc, mfsm_sftwcyc, mfsm_excyc;
    logic mfsm_sftrcyc;
    logic [1:0] mfsm_rnd1cyc0;
    logic mfsm_rndlast, mfsm_rndwlast;
    logic [7:0] sft1rnd, sftwrnd;
    logic mfsm_rnd1done, cr;
    logic mfsm_sft1done, sft1bit;
    logic mfsm_sftrdone;
    logic mfsm_sftwdone;
    logic mfsm_exdone;
    logic ramrdreg;
    logic [RAW-1:0] ramaddr_rnd1, ramaddr_sftr, ramaddr_sftw, ramaddr_ex, ramaddr_sft1, ramaddr_sftw0;
    logic           ramwr_rnd1,   ramrd_sftr,   ramrd_sftw,   ramrd_ex,   ramrd_sft1;
    logic           ramrd_rnd1,   ramwr_sftr,   ramwr_sftw,   ramwr_ex,   ramwr_sft1;
    logic [DW-1:0]  ramwdat_rnd1, ramwdat_sftr, ramwdat_sftw, ramwdat_ex, ramwdat_sft1;
    logic [DW-1:0]  ramrdatreg;
    logic [$clog2(LW)-1:0] aidx_msd;
    logic rnd0cyc_cmpflag, rnd0cyc_rddspl2, rnd0cyc_rddspl1;
    logic mfsm_ifpresftcyc, ifpresft, mfsm_ifpresftdone, mfsm_clrramdone;
    logic mfsmdone;
    logic [1:0]  opt_add, opt_sub, opt_blg     ;
    logic     opt_sftleft ;
    logic     opt_sftroll ;
    logic [3:0]  opt_tt      ;
    logic [7:0] opt_sftcnt  ;
    logic [DW-1:0] ramwdat_lgc;
    integer i,j;
    logic mfsm_sftwrnddone;
    logic sftw_init;

     logic [DW-1:0]  ramrdat_comb_test;

// mfsm

    assign acnt = alen / DW + |( alen % DW );
    `theregrn( busy ) <= start ? 1 : done ? '0 : busy;
    assign done = ( mfsm == MFSM_DONE );
    `theregfull(clk, resetn, mfsm, MFSM_IDLE ) <= ( start & ( mfsm == MFSM_IDLE)) | mfsmdone ? mfsmnext : mfsm;

    always_comb begin
        mfsmnext = mfsm;
        mfsmdone = '0;
        case (func)
            AF_ADD, AF_SUB, AF_BLG:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_RND1;
                    MFSM_RND1 : begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = mfsm_rnd1done;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            AF_SFT:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_SFT1;
                    MFSM_SFT1 : begin
                                                mfsmnext = MFSM_SFTR;           mfsmdone = mfsm_sft1done;
                        end
                    MFSM_SFTR : begin
                                                mfsmnext = ( mfsm_rndlast ? MFSM_DONE : MFSM_SFT1 );       mfsmdone = mfsm_sftrdone;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            AF_SFTW:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_SFTW;
                    MFSM_SFTW : begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = mfsm_sftwdone;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            AF_BEX:
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_EX;
                    MFSM_EX : begin
                                                mfsmnext = MFSM_DONE;           mfsmdone = mfsm_exdone;
                        end
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
            default :
                case( mfsm )
                    MFSM_IDLE:
                                                mfsmnext = MFSM_DONE;
                    MFSM_DONE: begin
                                                mfsmnext = MFSM_IDLE;           mfsmdone = 'h1;
                        end
                endcase
        endcase
    end

// mfsm rnd1

    assign opt_add      = func == AF_ADD ;
    assign opt_sub      = func == AF_SUB ;
    assign opt_blg      = func == AF_BLG ;
    assign opt_sftleft  = opt[2] ;
    assign opt_sftroll  = opt[3] ;
    assign opt_tt       = opt[7:4];
    assign opt_sftcnt   = opt[15:8];

    `theregrn( mfsm_rnd1cyc0 ) <= ~( mfsm == MFSM_RND1 )|mfsm_rnd1done|(mfsm_rnd1cyc0=='h2) ? '0 : ( mfsm_rnd1cyc0 + 1 );
    `theregrn( mfsm_rnd1cyc )  <= ~( mfsm == MFSM_RND1 )|mfsm_rnd1done ? '0 :
                                   ( mfsm_rnd1cyc0=='h2) ? ( mfsm_rnd1cyc + 1 ) : mfsm_rnd1cyc;
    assign mfsm_rnd1done = ( ramaddr_rnd1 == ( aidx_msd + RAMBASE_A ) ) & (mfsm_rnd1cyc0=='h2);
    assign ramaddr_rnd1 = ( mfsm_rnd1cyc0 ? RAMBASE_A : RAMBASE_B ) + mfsm_rnd1cyc;
    assign ramrd_rnd1 = ~ramwr_rnd1;
    assign ramwr_rnd1 = (mfsm_rnd1cyc0=='h2);
    assign { cr, ramwdat_rnd1 } = opt_add ? {  1'b0,ramrdat[DW-1:0]  } + { 1'b0, ramrdatreg } + crreg  :
                                  opt_sub ? { 1'b0, ramrdat[DW-1:0] } - { 1'b0, ramrdatreg } - crreg :
                                            { 1'b0, ramwdat_lgc };
    always_comb for( i = 0; i < DW; i++ ) ramwdat_lgc[i] = opt_tt[{ramrdatreg[i],ramrdat[i]}];
    always_comb for(j= 0; j < DW; j++ )  ramrdat_comb_test[j] = {ramrdatreg[j],ramrdat[j]};

    `theregrn( crreg ) <= start ? '0 : ( mfsm_rnd1cyc0 == 'h2 ) ? cr : crreg;

// mfsm sft1

    `theregrn( mfsm_sft1cyc ) <= ~( mfsm == MFSM_SFT1 )|mfsm_sft1done ? '0 : ( mfsm_sft1cyc + 1 );
    assign mfsm_sft1done = ( mfsm == MFSM_SFT1 )&( mfsm_sft1cyc == aidx_msd*2 + 1 );

    `theregrn( sft1rnd ) <= start ? '0 : mfsm_sftrdone ? sft1rnd + 1 : sft1rnd;
    assign mfsm_rndlast = ( sft1rnd == opt_sftcnt-1);

    assign ramaddr_sft1 = opt_sftleft ? ( RAMBASE_A + mfsm_sft1cyc/2 ): ( RAMBASE_A + aidx_msd - mfsm_sft1cyc/2 ) ;
    assign ramwr_sft1 =  mfsm_sft1cyc[0];
    assign ramrd_sft1 = ~mfsm_sft1cyc[0];
    assign ramwdat_sft1 = opt_sftleft ? { ramrdat[DW-2:0], sft1bit } : { sft1bit, ramrdat[DW-1:1] };

    `theregrn( sft1bit ) <= ( start | mfsm_sftrdone ) ? '0 : mfsm_sft1cyc[0] ? (opt_sftleft ? ramrdat[DW-1] : ramrdat[0]) : sft1bit;

// mfsm sftr

    `theregrn( mfsm_sftrcyc ) <= ~( mfsm == MFSM_SFTR )|mfsm_sftrdone ? '0 : ( mfsm_sftrcyc + 1 );
    assign mfsm_sftrdone = ( mfsm == MFSM_SFTR )&( mfsm_sftrcyc == 1 );

    assign ramaddr_sftr = opt_sftleft ? ( RAMBASE_A ): ( RAMBASE_A + aidx_msd ) ;
    assign ramwr_sftr =  mfsm_sftrcyc & opt_sftroll;
    assign ramrd_sftr = ~mfsm_sftrcyc;
    assign ramwdat_sftr = opt_sftleft ? { ramrdat[DW-1:1], sft1bit } : { sft1bit, ramrdat[DW-2:0] };

// mfsm sftw

    `theregrn( mfsm_sftwcyc ) <= ~( mfsm == MFSM_SFTW )|mfsm_sftwdone|mfsm_sftwrnddone ? '0 : ( mfsm_sftwcyc + 1 );
    assign mfsm_sftwrnddone = ( mfsm_sftwcyc == (aidx_msd + 1)*2 + 1 - 1 );
    assign mfsm_sftwdone = ( mfsm == MFSM_SFTW ) & mfsm_sftwrnddone & mfsm_rndwlast;
    `theregrn( sftwrnd ) <= start|mfsm_sftwdone ? '0 : sftwrnd + mfsm_sftwrnddone;
    assign mfsm_rndwlast = ( sftwrnd == opt_sftcnt-1);

    `theregrn( ramaddr_sftw0 ) <= start ? '0: ( mfsm_sftwcyc[0] ==0 ) ?  ( ( ramaddr_sftw0 == aidx_msd) ? 0 : ramaddr_sftw0+1 ) : ramaddr_sftw0;
    `theregrn( sftw_init ) <= start ? (func==AF_SFTW) : (mfsm==MFSM_SFTW) ? '0 : sftw_init;
    assign ramaddr_sftw = opt_sftleft ? ( RAMBASE_A + ramaddr_sftw0 ): ( RAMBASE_A + aidx_msd - ramaddr_sftw0 ) ;
    assign ramwr_sftw =  ~ramrd_sftw;//mfsm_sftwcyc[0];
    assign ramrd_sftw = mfsm_sftwcyc[0] | sftw_init;
        assign ramwdat_sftw = (( ramaddr_sftw0 == '0 ) & ~opt_sftroll ) ? '0 : ramrdatreg ;

// mfsm bex

    logic [DW-1:0] rdat_ex0, rdat_ex1, rdat_ex2;
    logic ex_w64, ex_w32, ex_byte, ex_bit ;
    logic [RAW-1:0] exidx_wr, exidx_rd;

    `theregrn( mfsm_excyc ) <= ~( mfsm == MFSM_EX )|mfsm_exdone ? '0 : ( mfsm_excyc + 1 );
    assign mfsm_exdone = ( mfsm == MFSM_EX )&( mfsm_excyc == aidx_msd*2 - 1 );

    assign {ex_w64, ex_w32, ex_byte, ex_bit } = opt[19:16];
    alucomm_ex  #(.DW0(1), .DW1(8), .DW2(8) ) ex0 (.di(ramrdat ), .exen(ex_bit ), .dx(rdat_ex0));
    alucomm_ex  #(.DW0(8), .DW1(4), .DW2(2) ) ex1 (.di(rdat_ex0), .exen(ex_byte), .dx(rdat_ex1));
    alucomm_ex  #(.DW0(32),.DW1(2), .DW2(1) ) ex2 (.di(rdat_ex1), .exen(ex_w32 ), .dx(rdat_ex2));

    assign exidx_wr = ex_w64 ? ( aidx_msd - mfsm_excyc/2 ) : mfsm_excyc/2;
    assign exidx_rd = mfsm_excyc/2;

    assign ramaddr_ex = ramwr_ex ? ( RAMBASE_B + exidx_wr ) : ( RAMBASE_A + exidx_rd ) ;
    assign ramwr_ex =  mfsm_excyc[0];
    assign ramrd_ex = ~mfsm_excyc[0];
    assign ramwdat_ex = rdat_ex1;

// ram mux

    assign { ramaddr, ramrd, ramwr, ramwdat } =
                ( mfsm == MFSM_RND1 ) ?   { ramaddr_rnd1, ramrd_rnd1, ramwr_rnd1, ramwdat_rnd1 } :
                ( mfsm == MFSM_SFTR ) ?   { ramaddr_sftr, ramrd_sftr, ramwr_sftr, ramwdat_sftr } :
                ( mfsm == MFSM_SFTW ) ?   { ramaddr_sftw, ramrd_sftw, ramwr_sftw, ramwdat_sftw } :
                ( mfsm == MFSM_EX   ) ?   { ramaddr_ex,   ramrd_ex,   ramwr_ex,   ramwdat_ex   } :
                                          { ramaddr_sft1, ramrd_sft1, ramwr_sft1, ramwdat_sft1 } ;

    `theregrn( ramrdreg ) <= ramrd;
    `theregrn( ramrdatreg ) <= ramrdreg ? ramrdat : ramrdatreg;

// ds/de idx

    assign aidx_msd = acnt -1;

endmodule

module alucomm_ex
#(
    parameter DW2 = 64,
    parameter DW1 = 8,
    parameter DW0 = 4
)(
    input  logic [DW2-1:0][DW1-1:0][DW0-1:0] di,
    input  logic exen,
    output logic [DW2-1:0][DW1-1:0][DW0-1:0] dx
);

    logic [DW2-1:0][DW1-1:0][DW0-1:0] dx0;

    genvar i,j;
    generate
        for (i = 0; i < DW2; i++) begin
            for (j = 0; j < DW1; j++) begin
                assign dx0[i][DW1-1-j] = di[i][j];
            end
        end
    endgenerate

    assign dx = exen ? dx0 : di;

endmodule
