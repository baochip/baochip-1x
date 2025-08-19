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

module sce_tb_hash();

    parameter COREUSERCNT = 8;
    parameter type coreuser_t = bit[0:COREUSERCNT-1];
    parameter INTC = 8;
    parameter ERRC = 8;
    localparam AW = 16;
    localparam IDW = 8;
    localparam DW = 32;
    localparam UW = 4;

    `include "sce_tb_v0.1.svh"

    bit clk;
    bit resetn;
    bit cmsatpg, cmsbist;
    coreuser_t   coreuser=8;
    coreuser_t   sceuser;
    bit        secmode;
    ahbif ahbs();
    axiif axim[0:1]();
    bit [INTC-1:0] intr;
    bit [ERRC-1:0] err;

    integer j=0, k=0, errcnt=0, warncnt=0;


	bit            hsel;
	bit  [AW-1:0]  haddr;
	bit  [1:0]     htrans;
	bit            hwrite;
	bit  [2:0]     hsize;
	bit  [2:0]     hburst;
	bit  [3:0]     hprot;
	bit  [IDW-1:0] hmaster;
	bit   [DW-1:0]  hwdata;
	bit            hmasterlock;
	bit            hreadym=1;
	bit  [UW-1:0]  hauser;
	bit  [UW-1:0]  hwuser;
	bit   [DW-1:0]  hrdata;
	bit            hready;
	bit            hresp;
	logic  [UW-1:0]  hruser;
	bit hdataphase;
	bit [DW-1:0] hrdatareg;
	bit hclk;
    bit [DW-1:0] membuf[0:511];
    bit [0:31][DW-1:0] refbuf;

    bit [DW-1:0] membufx[0:511];
    bit [0:31][DW-1:0] refbufx;



  //
  //  dut
  //  ==
    logic [4:0] pkefd = 0, PM_PFD = 5'h1;
    logic [4:0] scefd = 0, PM_SFD = 5'h6;
    logic clkpkeen, clksceen, clkpke, clksce;
    logic clktop = 0;
    logic por = 0;
    logic ana_rng_0p1u;
    logic [15:0] truststate;
    sce
    dut
    (
        .clk    (clk),
        .clktop (clktop),
        .clksceen(clksceen),
//        .clkpke(clkpke),
        .clkpkeen(clkpkeen),
        .resetn (resetn),
		.*
    );

    wire2ahbm ahbdrv(.ahbm(ahbs),.*);

  //
  //  monitor and clk
  //  ==

    `genclk( clktop, 10 )
    `timemarker2
    assign hclk = clk;

    `theregfull( clktop, por, pkefd, 0 ) <= ( pkefd == PM_PFD ) ? '0 : pkefd + 1;
    `theregfull( clktop, por, scefd, 0 ) <= ( scefd == PM_SFD ) ? '0 : scefd + 1;

    assign clkpkeen = ( pkefd == PM_PFD );
    assign clksceen = ( scefd == PM_SFD );

    ICG icgclkpke(.CK (clktop),.SE('0),.EN (clkpkeen),.CKG(clkpke));
    ICG icgclksce(.CK (clktop),.SE('0),.EN (clksceen),.CKG(clksce));

    assign clk = clksce;

  //
  //  subtitle
  //  ==

    initial begin
      #(10000 `MS);
    `maintestend

    `maintest(sce_tb_hash,sce_tb_hash)
        resetn = 0;
        por = 0;
        #( 200 );
        por = 1;
        #( 2 `US );
        resetn = 1;
        #( 2 `US );

        #( 500 `US );

        membuf[0:3] = { 32'h0123_4567, 32'h89ab_cdef, 32'h76543210, 32'hfedc_ba98 };

        memwr('0, 4);
        memrd('0, 4);

// init hash

        $readmemh("../../testbench/hashram.dua", membuf);
        memwr('0, 512);
        memrd('0, 512);


        sfrwr(GLB_suben, 32'hb );

        sfrwr(HASH_crfunc, 32'hff); sfrrd(HASH_crfunc); sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);

`ifdef NOFSDB
while(1) begin
`endif
// blk2s
        $display("\n@I:: blk2s ");

        membuf[ 0  ] = 32'h6b08e647;//32'h6a09e667 ;
        membuf[ 1  ] = 32'hbb67ae85 ;
        membuf[ 2  ] = 32'h3c6ef372 ;
        membuf[ 3  ] = 32'ha54ff53a ;
        membuf[ 4  ] = 32'h510e527f ;
        membuf[ 5  ] = 32'h9b05688c ;
        membuf[ 6  ] = 32'h1f83d9ab ;
        membuf[ 7  ] = 32'h5be0cd19 ;
        membuf[ 8  ] = 32'h0 ;
        membuf[ 9  ] = 32'h0 ;
        membuf[ 10 ] = 32'h0 ;
        membuf[ 11 ] = 32'h0 ;
        membuf[ 12 ] = 32'h0 ^ 32'h3;
        membuf[ 13 ] = 32'h0 ^ 32'h0;
        membuf[ 14 ] = '1 ;
        membuf[ 15 ] = 32'h0 ;
        memwr(SEGADDR_HOUT, 16);

        membuf[ 0  ] = 32'h00636261;
        membuf[ 1  ] = 32'h0;
        membuf[ 2  ] = 32'h0;
        membuf[ 3  ] = 32'h0;
        membuf[ 4  ] = 32'h0;
        membuf[ 5  ] = 32'h0;
        membuf[ 6  ] = 32'h0;
        membuf[ 7  ] = 32'h0;
        membuf[ 8  ] = 32'h0;
        membuf[ 9  ] = 32'h0;
        membuf[ 10 ] = 32'h0;
        membuf[ 11 ] = 32'h0;
        membuf[ 12 ] = 32'h0;
        membuf[ 13 ] = 32'h0;
        membuf[ 14 ] = 32'h0;
        membuf[ 15 ] = 32'h0;
        memwr(SEGADDR_MSG, 16);

        sfrwr(HASH_opt1, 0);
        sfrwr(HASH_opt2, 0);
        sfrwr(HASH_opt3, 'h80);
//        sfrwr(HASH_optblk, 'h01234567);
        sfrwr(HASH_segptr_HOUT2, 'h10 );
        sfrwr(HASH_crfunc, 32'h03); sfrrd(HASH_crfunc); sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
//        memrd(SEGADDR_HOUT+16,8);
        memrd(SEGADDR_HOUT+16,8);
        refbuf[0:7] =  256'h508c5e8c327c14e2_e1a72ba34eeb452f_37458b209ed63a29_4d999b4c86675982;
        checkref(8);

        sfrwr(HASH_opt1, 0);
        sfrwr(HASH_opt2, 0);
        sfrwr(HASH_opt3, 'h80);
        sfrwr(HASH_optblk, 'h01234567);
        sfrwr(HASH_crfunc, 32'h03); sfrrd(HASH_crfunc); sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
        memrd(SEGADDR_HOUT+16,8);
        refbuf[0:7] =  256'h508c5e8c327c14e2_e1a72ba34eeb452f_37458b209ed63a29_4d999b4c86675982;
        checkref(8);

        sfrwr(HASH_opt3, 'h00);
        sfrwr(HASH_segptr_HOUT2, 'h00 );


        #( 10 `US);

//        $finish;
//        refbuf[31:0] =  512'h0d4d1c983fa580ba_e9f6129fb697276a_b7c45a68142f214c_d1a2ffdb6fbb124b_2d79ab2a39c5877d_95cc3345ded552c2_5a92f1dba88ad318_239900d4ed8623b9;
//508c5e8c327c14e2e1a72ba34eeb452f37458b209ed63a294d999b4c86675982
// blk2b
        $display("\n@I:: blk2b");

        membuf[ 0  ] = 32'hf2bdc948;//32'hF3BCC908;
        membuf[ 1  ] = 32'h6a09e667;//32'h6A09E667;
        membuf[ 2  ] = 32'h84CAA73B;
        membuf[ 3  ] = 32'hBB67AE85;
        membuf[ 4  ] = 32'hFE94F82B;
        membuf[ 5  ] = 32'h3C6EF372;
        membuf[ 6  ] = 32'h5F1D36F1;
        membuf[ 7  ] = 32'hA54FF53A;
        membuf[ 8  ] = 32'hADE682D1;
        membuf[ 9  ] = 32'h510E527F;
        membuf[ 10 ] = 32'h2B3E6C1F;
        membuf[ 11 ] = 32'h9B05688C;
        membuf[ 12 ] = 32'hFB41BD6B;
        membuf[ 13 ] = 32'h1F83D9AB;
        membuf[ 14 ] = 32'h137E2179;
        membuf[ 15 ] = 32'h5BE0CD19;
        membuf[ 16 + 0  ] =  32'h0;
        membuf[ 16 + 1  ] =  32'h0;
        membuf[ 16 + 2  ] =  32'h0;
        membuf[ 16 + 3  ] =  32'h0;
        membuf[ 16 + 4  ] =  32'h0;
        membuf[ 16 + 5  ] =  32'h0;
        membuf[ 16 + 6  ] =  32'h0;
        membuf[ 16 + 7  ] =  32'h0;
        membuf[ 16 + 8  ] =  32'h3;//t0
        membuf[ 16 + 9  ] =  32'h0;
        membuf[ 16 + 10 ] =  32'h0;
        membuf[ 16 + 11 ] =  32'h0;
        membuf[ 16 + 12 ] =  '1;
        membuf[ 16 + 13 ] =  '1;
        membuf[ 16 + 14 ] =  32'h0;
        membuf[ 16 + 15 ] =  32'h0;
        memwr(SEGADDR_HOUT, 32);

        membuf[ 0  ] = 32'h00636261;
        membuf[ 1  ] = 32'h0;
        membuf[ 2  ] = 32'h0;
        membuf[ 3  ] = 32'h0;
        membuf[ 4  ] = 32'h0;
        membuf[ 5  ] = 32'h0;
        membuf[ 6  ] = 32'h0;
        membuf[ 7  ] = 32'h0;
        membuf[ 8  ] = 32'h0;
        membuf[ 9  ] = 32'h0;
        membuf[ 10 ] = 32'h0;
        membuf[ 11 ] = 32'h0;
        membuf[ 12 ] = 32'h0;
        membuf[ 13 ] = 32'h0;
        membuf[ 14 ] = 32'h0;
        membuf[ 15 ] = 32'h0;
        membuf[ 16 + 0  ] =  32'h0;
        membuf[ 16 + 1  ] =  32'h0;
        membuf[ 16 + 2  ] =  32'h0;
        membuf[ 16 + 3  ] =  32'h0;
        membuf[ 16 + 4  ] =  32'h0;
        membuf[ 16 + 5  ] =  32'h0;
        membuf[ 16 + 6  ] =  32'h0;
        membuf[ 16 + 7  ] =  32'h0;
        membuf[ 16 + 8  ] =  32'h0;
        membuf[ 16 + 9  ] =  32'h0;
        membuf[ 16 + 10 ] =  32'h0;
        membuf[ 16 + 11 ] =  32'h0;
        membuf[ 16 + 12 ] =  32'h0;
        membuf[ 16 + 13 ] =  32'h0;
        membuf[ 16 + 14 ] =  32'h0;
        membuf[ 16 + 15 ] =  32'h0;
        memwr(SEGADDR_MSG, 32);
/*
        membuf[ 0  ] = 32'h6a09e667;//32'h6A09E667;
        membuf[ 1  ] = 32'hf2bdc948;//32'hF3BCC908;
        membuf[ 2  ] = 32'hBB67AE85;
        membuf[ 3  ] = 32'h84CAA73B;
        membuf[ 4  ] = 32'h3C6EF372;
        membuf[ 5  ] = 32'hFE94F82B;
        membuf[ 6  ] = 32'hA54FF53A;
        membuf[ 7  ] = 32'h5F1D36F1;
        membuf[ 8  ] = 32'h510E527F;
        membuf[ 9  ] = 32'hADE682D1;
        membuf[ 10 ] = 32'h9B05688C;
        membuf[ 11 ] = 32'h2B3E6C1F;
        membuf[ 12 ] = 32'h1F83D9AB;
        membuf[ 13 ] = 32'hFB41BD6B;
        membuf[ 14 ] = 32'h5BE0CD19;
        membuf[ 15 ] = 32'h137E2179;
        membuf[ 16 + 0  ] =  32'h0;
        membuf[ 16 + 1  ] =  32'h0;
        membuf[ 16 + 2  ] =  32'h0;
        membuf[ 16 + 3  ] =  32'h0;
        membuf[ 16 + 4  ] =  32'h0;
        membuf[ 16 + 5  ] =  32'h0;
        membuf[ 16 + 6  ] =  32'h0;
        membuf[ 16 + 7  ] =  32'h0;
        membuf[ 16 + 8  ] =  32'h0;
        membuf[ 16 + 9  ] =  32'h3;//t0
        membuf[ 16 + 10 ] =  32'h0;
        membuf[ 16 + 11 ] =  32'h0;
        membuf[ 16 + 12 ] =  '1;
        membuf[ 16 + 13 ] =  '1;
        membuf[ 16 + 14 ] =  32'h0;
        membuf[ 16 + 15 ] =  32'h0;
        memwr(SEGADDR_HOUT, 32);

        membuf[ 0  ] = 32'h0;
        membuf[ 1  ] = 32'h00636261;
        membuf[ 2  ] = 32'h0;
        membuf[ 3  ] = 32'h0;
        membuf[ 4  ] = 32'h0;
        membuf[ 5  ] = 32'h0;
        membuf[ 6  ] = 32'h0;
        membuf[ 7  ] = 32'h0;
        membuf[ 8  ] = 32'h0;
        membuf[ 9  ] = 32'h0;
        membuf[ 10 ] = 32'h0;
        membuf[ 11 ] = 32'h0;
        membuf[ 12 ] = 32'h0;
        membuf[ 13 ] = 32'h0;
        membuf[ 14 ] = 32'h0;
        membuf[ 15 ] = 32'h0;
        membuf[ 16 + 0  ] =  32'h0;
        membuf[ 16 + 1  ] =  32'h0;
        membuf[ 16 + 2  ] =  32'h0;
        membuf[ 16 + 3  ] =  32'h0;
        membuf[ 16 + 4  ] =  32'h0;
        membuf[ 16 + 5  ] =  32'h0;
        membuf[ 16 + 6  ] =  32'h0;
        membuf[ 16 + 7  ] =  32'h0;
        membuf[ 16 + 8  ] =  32'h0;
        membuf[ 16 + 9  ] =  32'h0;
        membuf[ 16 + 10 ] =  32'h0;
        membuf[ 16 + 11 ] =  32'h0;
        membuf[ 16 + 12 ] =  32'h0;
        membuf[ 16 + 13 ] =  32'h0;
        membuf[ 16 + 14 ] =  32'h0;
        membuf[ 16 + 15 ] =  32'h0;
        memwr(SEGADDR_MSG, 32);
*/
        sfrwr(HASH_opt1, 0);
        sfrwr(HASH_opt2, 0);
        sfrwr(HASH_opt3, 'h80);
        sfrwr(HASH_crfunc, 32'h04); sfrrd(HASH_crfunc); sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
        memrd(SEGADDR_HOUT,16);
        refbuf[0:15] =  512'h0d4d1c983fa580ba_e9f6129fb697276a_b7c45a68142f214c_d1a2ffdb6fbb124b_2d79ab2a39c5877d_95cc3345ded552c2_5a92f1dba88ad318_239900d4ed8623b9;
        refbuf[0:15] =  512'hba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923;
        checkref(16);
        sfrwr(HASH_opt3, 'h00);



//        refbuf[31:0] =  512'h0d4d1c983fa580ba_e9f6129fb697276a_b7c45a68142f214c_d1a2ffdb6fbb124b_2d79ab2a39c5877d_95cc3345ded552c2_5a92f1dba88ad318_239900d4ed8623b9;
        #( 10 `US);
//        $finish;

// blk3
        $display("\n@I:: blk3");

        membuf[ 0  ] = 32'h6a09e667;//32'hF3BCC908;
        membuf[ 1  ] = 32'hbb67ae85;//32'h6A09E667;
        membuf[ 2  ] = 32'h3c6ef372;
        membuf[ 3  ] = 32'ha54ff53a;
        membuf[ 4  ] = 32'h510e527f;
        membuf[ 5  ] = 32'h9b05688c;
        membuf[ 6  ] = 32'h1f83d9ab;
        membuf[ 7  ] = 32'h5be0cd19;
        membuf[ 8  ] = 32'h00000000;
        membuf[ 9  ] = 32'h00000000;
        membuf[ 10 ] = 32'h00000000;
        membuf[ 11 ] = 32'h00000000;
        membuf[ 12 ] = 32'h00000000;
        membuf[ 13 ] = 32'h00000000;
        membuf[ 14 ] = 32'h00000003;
        membuf[ 15 ] = 32'h0000000b;

        memwr(SEGADDR_HOUT, 16);

        membuf[ 0  ] = 32'h00636261;
        membuf[ 1  ] = 32'h0;
        membuf[ 2  ] = 32'h0;
        membuf[ 3  ] = 32'h0;
        membuf[ 4  ] = 32'h0;
        membuf[ 5  ] = 32'h0;
        membuf[ 6  ] = 32'h0;
        membuf[ 7  ] = 32'h0;
        membuf[ 8  ] = 32'h0;
        membuf[ 9  ] = 32'h0;
        membuf[ 10 ] = 32'h0;
        membuf[ 11 ] = 32'h0;
        membuf[ 12 ] = 32'h0;
        membuf[ 13 ] = 32'h0;
        membuf[ 14 ] = 32'h0;
        membuf[ 15 ] = 32'h0;
        memwr(SEGADDR_MSG, 16);

        sfrwr(HASH_opt1, 0);
        sfrwr(HASH_opt2, 0);
        sfrwr(HASH_opt3, 'h80);
        sfrwr(HASH_crfunc, 32'h05); sfrrd(HASH_crfunc); sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
        memrd(SEGADDR_HOUT,16);
        refbuf[0:7] =  512'h6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85;//ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923;
        checkref(8);
        sfrwr(HASH_opt3, 'h00);



//        refbuf[31:0] =  512'h0d4d1c983fa580ba_e9f6129fb697276a_b7c45a68142f214c_d1a2ffdb6fbb124b_2d79ab2a39c5877d_95cc3345ded552c2_5a92f1dba88ad318_239900d4ed8623b9;
        #( 10 `US);




// sha256
        $display("\n@I:: sha256 ");

        membuf[ 0  ] = 32'h61626364;
        membuf[ 1  ] = 32'h62636465;
        membuf[ 2  ] = 32'h63646566;
        membuf[ 3  ] = 32'h64656667;
        membuf[ 4  ] = 32'h65666768;
        membuf[ 5  ] = 32'h66676869;
        membuf[ 6  ] = 32'h6768696a;
        membuf[ 7  ] = 32'h68696a6b;
        membuf[ 8  ] = 32'h696a6b6c;
        membuf[ 9  ] = 32'h6a6b6c6d;
        membuf[ 10 ] = 32'h6b6c6d6e;
        membuf[ 11 ] = 32'h6c6d6e6f;
        membuf[ 12 ] = 32'h6d6e6f70;
        membuf[ 13 ] = 32'h6e6f7071;
        membuf[ 14 ] = 32'h80000000;
        membuf[ 15 ] = 32'h00000000;

        membuf[ 16 ] = 32'h00000000;
        membuf[ 17 ] = 32'h00000000;
        membuf[ 18 ] = 32'h00000000;
        membuf[ 19 ] = 32'h00000000;
        membuf[ 20 ] = 32'h00000000;
        membuf[ 21 ] = 32'h00000000;
        membuf[ 22 ] = 32'h00000000;
        membuf[ 23 ] = 32'h00000000;
        membuf[ 24 ] = 32'h00000000;
        membuf[ 25 ] = 32'h00000000;
        membuf[ 26 ] = 32'h00000000;
        membuf[ 27 ] = 32'h00000000;
        membuf[ 28 ] = 32'h00000000;
        membuf[ 29 ] = 32'h00000000;
        membuf[ 30 ] = 32'h00000000;
        membuf[ 31 ] = 32'h000001c0;

        memwr(SEGADDR_MSG,32);
        sfrwr(HASH_opt1, 1);
        sfrwr(HASH_opt2, 4);
        sfrwr(HASH_crfunc, 32'h00); sfrrd(HASH_crfunc); sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
        memrd(SEGADDR_HOUT,8);
        refbuf[0:7] = 'h248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1; checkref(8);

        sfrwr(HASH_opt1, 0);
        sfrwr(HASH_opt2, 4);
        sfrwr(HASH_opt3, 'h80);
        sfrwr(HASH_crfunc, 32'h00); sfrrd(HASH_crfunc); sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
        memrd(SEGADDR_HOUT,8);
        refbuf[0:7] = 'h85e655d6417a17953363376a624cde5c76e09589cac5f811cc4b32c1f20e533a; checkref(8);

        sfrwr(HASH_opt1, 0);
        sfrwr(HASH_opt2, 0);
        sfrwr(HASH_opt3, 'h20);
        sfrwr(HASH_segptr_MSG, 'h10);
        sfrwr(HASH_crfunc, 32'h00); sfrrd(HASH_crfunc); sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
        memrd(SEGADDR_HOUT,8);
        sfrwr(HASH_segptr_MSG, 'h0);
        refbuf[0:7] = 'h248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1; checkref(8);

// hmac256
  // pass1
        $display("\n@I:: hmac256 pass1");

        membuf[ 0  ] = 32'h0b0b0b0b;
        membuf[ 1  ] = 32'h0b0b0b0b;
        membuf[ 2  ] = 32'h0b0b0b0b;
        membuf[ 3  ] = 32'h0b0b0b0b;
        membuf[ 4  ] = 32'h0b0b0b0b;
        membuf[ 5  ] = 32'h00000000;
        membuf[ 6  ] = 32'h00000000;
        membuf[ 7  ] = 32'h00000000;
        membuf[ 8  ] = 32'h00000000;
        membuf[ 9  ] = 32'h00000000;
        membuf[ 10 ] = 32'h00000000;
        membuf[ 11 ] = 32'h00000000;
        membuf[ 12 ] = 32'h00000000;
        membuf[ 13 ] = 32'h00000000;
        membuf[ 14 ] = 32'h00000000;
        membuf[ 15 ] = 32'h00000000;
        memwr(SEGADDR_KEY,16);

        membuf[ 0  ] = 32'h48692054;
        membuf[ 1  ] = 32'h68657265;
        membuf[ 2  ] = 32'h80000000;
        membuf[ 3  ] = 32'h00000000;
        membuf[ 4  ] = 32'h00000000;
        membuf[ 5  ] = 32'h00000000;
        membuf[ 6  ] = 32'h00000000;
        membuf[ 7  ] = 32'h00000000;
        membuf[ 8  ] = 32'h00000000;
        membuf[ 9  ] = 32'h00000000;
        membuf[ 10 ] = 32'h00000000;
        membuf[ 11 ] = 32'h00000000;
        membuf[ 12 ] = 32'h00000000;
        membuf[ 13 ] = 32'h00000000;
        membuf[ 14 ] = 32'h00000000;
        membuf[ 15 ] = 32'h00000240;
        memwr(SEGADDR_MSG,16);

        refbuf[0:7] = 'h92ab4d9a1f3b6152bca9dd9e69af43f4ce99e42fd4e30ff972c48025b9f9cfef;

        sfrwr(HASH_crfunc, 32'h50); sfrrd(HASH_crfunc);
        sfrwr(HASH_opt1, 0);
        sfrwr(HASH_opt2, 4);
        sfrwr(HASH_opt3, 0);
        sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
        memrd(SEGADDR_HOUT,8);
        checkref(8);

    // pass2
        $display("\n@I:: hmac256 pass2");

        refbuf[0:7] = 'hb0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff0;
        for (int i = 0; i < 8; i++) begin
             membuf[i] = refbuf[i];
         end
        memwr(SEGADDR_SCRT, 8);

        sfrwr(HASH_crfunc, 32'h60); sfrrd(HASH_crfunc);
//        sfrwr(HASH_opt1, 1);
        sfrwr(HASH_opt2, 5);
        sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
        memrd(SEGADDR_HOUT,8);
        checkref(8);
        errcnt = errcnt -1;

        #( 1 `US );
        sfrwr(SDMA_ichcr_segid,32'h0503);
        sfrwr(SDMA_ichcr_transize,32'h8);
        sfrwr(SDMA_chstart_ar,32'h5a);
        #( 10 `US );

#(100 `US);

//$finish;


// sha512
        $display("\n@I:: SHA512");

    membuf[0    ] = 32'h61626380;
    membuf[1    ] = 32'h00000000;
    membuf[2    ] = 32'h00000000;
    membuf[3    ] = 32'h00000000;
    membuf[4    ] = 32'h00000000;
    membuf[5    ] = 32'h00000000;
    membuf[6    ] = 32'h00000000;
    membuf[7    ] = 32'h00000000;
    membuf[8    ] = 32'h00000000;
    membuf[9    ] = 32'h00000000;
    membuf[10   ] = 32'h00000000;
    membuf[11   ] = 32'h00000000;
    membuf[12   ] = 32'h00000000;
    membuf[13   ] = 32'h00000000;
    membuf[14   ] = 32'h00000000;
    membuf[15   ] = 32'h00000000;
    membuf[0 +16] = 32'h00000000;
    membuf[1 +16] = 32'h00000000;
    membuf[2 +16] = 32'h00000000;
    membuf[3 +16] = 32'h00000000;
    membuf[4 +16] = 32'h00000000;
    membuf[5 +16] = 32'h00000000;
    membuf[6 +16] = 32'h00000000;
    membuf[7 +16] = 32'h00000000;
    membuf[8 +16] = 32'h00000000;
    membuf[9 +16] = 32'h00000000;
    membuf[10+16] = 32'h00000000;
    membuf[11+16] = 32'h00000000;
    membuf[12+16] = 32'h00000000;
    membuf[13+16] = 32'h00000000;
    membuf[14+16] = 32'h00000000;
    membuf[15+16] = 32'h00000018;
        memwr(SEGADDR_MSG,32);


        refbuf[0:15] = 512'hDDAF35A193617ABACC417349AE20413112E6FA4E89A97EA20A9EEEE64B55D39A2192992A274FC1A836BA3C23A3FEEBBD454D4423643CE80E2A9AC94FA54CA49F;

        sfrwr(HASH_crfunc, 32'h1); sfrrd(HASH_crfunc);
        sfrwr(HASH_opt1, 0);
        sfrwr(HASH_opt2, 4);
//        sfrwr(HASH_opt3, 'h10);
        sfrwr(HASH_ar, 32'h5a); sfrwait(HASH_fr, 32'h1, 32'h1); sfrwr(HASH_fr, 32'h1);
        memrd(SEGADDR_HOUT,16);
        checkref(16);

//        #( 10 `US ); $finish;



// aes
        #( 10 `US );
        $display("\n@I:: AES");

        membuf[ 0  ] = 32'h00112233;
        membuf[ 1  ] = 32'h44556677;
        membuf[ 2  ] = 32'h8899aabb;
        membuf[ 3  ] = 32'hccddeeff;
        membuf[ 0  ] = 32'h69c4e0d8;
        membuf[ 1  ] = 32'h6a7b0430;
        membuf[ 2  ] = 32'hd8cdb780;
        membuf[ 3  ] = 32'h70b4c55a;
        memwr(SEGADDR_AIB,4);
        membuf[ 0  ] = 32'h00010203;
        membuf[ 1  ] = 32'h04050607;
        membuf[ 2  ] = 32'h08090a0b;
        membuf[ 3  ] = 32'h0c0d0e0f;
        membuf[ 4  ] = 32'h296bd6eb;
        membuf[ 5  ] = 32'h2ca90321;
        membuf[ 6  ] = 32'hbbef5f5f;
        membuf[ 7  ] = 32'h4cfc10ec;
        membuf[ 8  ] = 32'h11111111;
        membuf[ 9  ] = 32'h22222222;
        membuf[ 10 ] = 32'h33333333;
        membuf[ 11 ] = 32'h44444444;
        memwr(SEGADDR_AKEY,12);
        sfrwr(AES_segptr_IV,8);

        sfrwr(AES_ar,32'h5a);sfrwait(AES_fr, 32'h1, 32'h1); sfrwr(AES_fr, 32'h1);

        #( 1 `US );
        sfrwr(AES_opt1,32'h0);
        sfrwr(AES_crfunc,32'h2);
        sfrwr(AES_ar,32'h5a);sfrwait(AES_fr, 32'h1, 32'h1); sfrwr(AES_fr, 32'h1);
        memrd(SEGADDR_AIB,4);
        memrd(SEGADDR_AOB,4);

        refbuf[0:3] = {
            32'h00112233,
            32'h44556677,
            32'h8899aabb,
            32'hccddeeff
            };
        checkref(4);

        #( 1 `US );
        sfrwr(SDMA_ichcr_segid,32'h0F0E);
        sfrwr(SDMA_ichcr_transize,32'h4);
        sfrwr(SDMA_chstart_ar,32'h5a);

        #( 10 `US );
        sfrwr(AES_crfunc,32'h1);
        sfrwr(AES_ar,32'h5a);sfrwait(AES_fr, 32'h1, 32'h1); sfrwr(AES_fr, 32'h1);
        memrd(SEGADDR_AIB,4);
        memrd(SEGADDR_AOB,4);
        refbuf[0:3] = {
            32'h69c4e0d8,
            32'h6a7b0430,
            32'hd8cdb780,
            32'h70b4c55a
            };
        checkref(4);


// pke
        #( 10 `US );
        $display("\n@I:: PKE ED25519");

        sfrwr( GLB_suben,'1 );
        sfrwr( PKE_optnw, 32'd255 );
        sfrwr( PKE_optew, 32'd255 );

        // P:
        membuf[ 0  ] = 32'hffffffed;
        membuf[ 1  ] = 32'hffffffff;
        membuf[ 2  ] = 32'hffffffff;
        membuf[ 3  ] = 32'hffffffff;
        membuf[ 4  ] = 32'hffffffff;
        membuf[ 5  ] = 32'hffffffff;
        membuf[ 6  ] = 32'hffffffff;
        membuf[ 7  ] = 32'h7fffffff;
        // A
        membuf[ 8  ] = 32'h135978a3;
        membuf[ 9  ] = 32'h75eb4dca;
        membuf[ 10 ] = 32'h4141d8ab;
        membuf[ 11 ] = 32'h00700a4d;
        membuf[ 12 ] = 32'h7779e898;
        membuf[ 13 ] = 32'h8cc74079;
        membuf[ 14 ] = 32'h2b6ffe73;
        membuf[ 15 ] = 32'h52036cee;
        memwr(SEGADDR_PCON,16);
        membuf[ 0  ] = 32'h0;
        membuf[ 1  ] = 32'h0;
        membuf[ 2  ] = 32'h0;
        membuf[ 3  ] = 32'h0;
        membuf[ 4  ] = 32'h0;
        membuf[ 5  ] = 32'h0;
        membuf[ 6  ] = 32'h0;
        membuf[ 7  ] = 32'h80000000;
        membuf[ 8  ] = 32'h0;
        memwr(SEGADDR_PCON+16,9);
//        membuf[ 0  ] = 32'h1;
//        membuf[ 1  ] = 32'h0;
//        membuf[ 2  ] = 32'h0;
//        membuf[ 3  ] = 32'h0;
//        membuf[ 4  ] = 32'h0;
//        membuf[ 5  ] = 32'h0;
//        membuf[ 6  ] = 32'h0;
//        membuf[ 7  ] = 32'h0;
//        memwr(SEGADDR_PCON+16+9,8);

        sfrwr( PKE_crfunc, 32'h01 );
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);

        // K
        membuf[ 0  ] = 32'h86837c30;
        membuf[ 1  ] = 32'hcb33284f;
        membuf[ 2  ] = 32'hf12e7a42;
        membuf[ 3  ] = 32'h3c010ac0;
        membuf[ 4  ] = 32'h6827fffd;
        membuf[ 5  ] = 32'ha3c080d9;
        membuf[ 6  ] = 32'h06f020a5;
        membuf[ 7  ] = 32'h4fe94d90;
        memwr(SEGADDR_PKB,8);

    $display("\n@I:: PKE ED25519 - I2MD ");


        // Q0_X,Q0_Y, I2MD
        membuf[ 0   ] = 32'h8f25d51a;
        membuf[ 1   ] = 32'hc9562d60;
        membuf[ 2   ] = 32'h9525a7b2;
        membuf[ 3   ] = 32'h692cc760;
        membuf[ 4   ] = 32'hfdd6dc5c;
        membuf[ 5   ] = 32'hc0a4e231;
        membuf[ 6   ] = 32'hcd6e53fe;
        membuf[ 7   ] = 32'h216936d3;
        membuf[ 0+8 ] = 32'h66666658;
        membuf[ 1+8 ] = 32'h66666666;
        membuf[ 2+8 ] = 32'h66666666;
        membuf[ 3+8 ] = 32'h66666666;
        membuf[ 4+8 ] = 32'h66666666;
        membuf[ 5+8 ] = 32'h66666666;
        membuf[ 6+8 ] = 32'h66666666;
        membuf[ 7+8 ] = 32'h66666666;

        refbuf[0  ] =  32'h3f9da287;
        refbuf[1  ] =  32'he2cabc55;
        refbuf[2  ] =  32'h2396e489;
        refbuf[3  ] =  32'h9ca59856;
        refbuf[4  ] =  32'hade4b5b7;
        refbuf[5  ] =  32'h9879936b;
        refbuf[6  ] =  32'h7e6077d0;
        refbuf[7  ] =  32'h759e2370;
        refbuf[0+8] =  32'h3333334a;
        refbuf[1+8] =  32'h33333333;
        refbuf[2+8] =  32'h33333333;
        refbuf[3+8] =  32'h33333333;
        refbuf[4+8] =  32'h33333333;
        refbuf[5+8] =  32'h33333333;
        refbuf[6+8] =  32'h33333333;
        refbuf[7+8] =  32'h33333333;
        refbuf[0+16] = 32'h00000026;
        refbuf[1+16] = 32'h00000000;
        refbuf[2+16] = 32'h00000000;
        refbuf[3+16] = 32'h00000000;
        refbuf[4+16] = 32'h00000000;
        refbuf[5+16] = 32'h00000000;
        refbuf[6+16] = 32'h00000000;
        refbuf[7+16] = 32'h00000000;
        refbuf[0+24] = 32'h994ae86c;
        refbuf[1+24] = 32'h4f0896aa;
        refbuf[2+24] = 32'hb612506e;
        refbuf[3+24] = 32'he3b7ad11;
        refbuf[4+24] = 32'hf183c492;
        refbuf[5+24] = 32'h46c7a922;
        refbuf[6+24] = 32'hfeb3930d;
        refbuf[7+24] = 32'h5e181c59;

        memwr(SEGADDR_PIB,16);
        sfrwr( PKE_crfunc, 32'h24 ); // I2MD
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);

        memrd(SEGADDR_POB,8*4);
        checkref(8*4);
/*
        // Q0_X,Q0_Y, I2MD
        membuf[ 0   ] = 32'h8f25d51a;
        membuf[ 1   ] = 32'hc9562d60;
        membuf[ 2   ] = 32'h9525a7b2;
        membuf[ 3   ] = 32'h692cc760;
        membuf[ 4   ] = 32'hfdd6dc5c;
        membuf[ 5   ] = 32'hc0a4e231;
        membuf[ 6   ] = 32'hcd6e53fe;
        membuf[ 7   ] = 32'h216936d3;
        membuf[ 0+8 ] = 32'h66666658;
        membuf[ 1+8 ] = 32'h66666666;
        membuf[ 2+8 ] = 32'h66666666;
        membuf[ 3+8 ] = 32'h66666666;
        membuf[ 4+8 ] = 32'h66666666;
        membuf[ 5+8 ] = 32'h66666666;
        membuf[ 6+8 ] = 32'h66666666;
        membuf[ 7+8 ] = 32'h66666660;

        membuf[ 16+0   ] = 32'h8f25d51a;
        membuf[ 16+1   ] = 32'hc9562d60;
        membuf[ 16+2   ] = 32'h9525a7b2;
        membuf[ 16+3   ] = 32'h692cc760;
        membuf[ 16+4   ] = 32'hfdd6dc5c;
        membuf[ 16+5   ] = 32'hc0a4e231;
        membuf[ 16+6   ] = 32'hcd6e53fe;
        membuf[ 16+7   ] = 32'h216936d3;
        membuf[ 16+0+8 ] = 32'h66666658;
        membuf[ 16+1+8 ] = 32'h66666666;
        membuf[ 16+2+8 ] = 32'h66666666;
        membuf[ 16+3+8 ] = 32'h66666666;
        membuf[ 16+4+8 ] = 32'h66666666;
        membuf[ 16+5+8 ] = 32'h66666666;
        membuf[ 16+6+8 ] = 32'h66666666;
        membuf[ 16+7+8 ] = 32'h66666666;
        refbuf[0  ] =  'h3f9da287;
        refbuf[1  ] =  'he2cabc55;
        refbuf[2  ] =  'h2396e489;
        refbuf[3  ] =  'h9ca59856;
        refbuf[4  ] =  'hade4b5b7;
        refbuf[5  ] =  'h9879936b;
        refbuf[6  ] =  'h7e6077d0;
        refbuf[7  ] =  'h759e2370;
        refbuf[0+8] =  'h3333334a;
        refbuf[1+8] =  'h33333333;
        refbuf[2+8] =  'h33333333;
        refbuf[3+8] =  'h33333333;
        refbuf[4+8] =  'h33333333;
        refbuf[5+8] =  'h33333333;
        refbuf[6+8] =  'h33333333;
        refbuf[7+8] =  'h3333324f;
        refbuf[0+16] = 'h00000026;
        refbuf[1+16] = 'h00000000;
        refbuf[2+16] = 'h00000000;
        refbuf[3+16] = 'h00000000;
        refbuf[4+16] = 'h00000000;
        refbuf[5+16] = 'h00000000;
        refbuf[6+16] = 'h00000000;
        refbuf[7+16] = 'h00000000;
        refbuf[0+24] = 'h9cbb2c7f;
        refbuf[1+24] = 'h9ca50bdc;
        refbuf[2+24] = 'h3296a3b6;
        refbuf[3+24] = 'h0405d58a;
        refbuf[4+24] = 'h253c78ac;
        refbuf[5+24] = 'hb8dcf35b;
        refbuf[6+24] = 'h3ddc02dc;
        refbuf[7+24] = 'h60664cc7;


        memwr(SEGADDR_PIB,32);
        sfrwr( PKE_segptr_PIB0, 32'h0 );
        sfrwr( PKE_crfunc, 32'h24 ); // I2MD
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);

        memrd(SEGADDR_POB,8*4);
        checkref(8*4);
        #( 1 `US );

    $display("\n@I:: PKE ED25519 - I2MD2 ");

        refbuf[0  ] =  32'h3f9da287;
        refbuf[1  ] =  32'he2cabc55;
        refbuf[2  ] =  32'h2396e489;
        refbuf[3  ] =  32'h9ca59856;
        refbuf[4  ] =  32'hade4b5b7;
        refbuf[5  ] =  32'h9879936b;
        refbuf[6  ] =  32'h7e6077d0;
        refbuf[7  ] =  32'h759e2370;
        refbuf[0+8] =  32'h3333334a;
        refbuf[1+8] =  32'h33333333;
        refbuf[2+8] =  32'h33333333;
        refbuf[3+8] =  32'h33333333;
        refbuf[4+8] =  32'h33333333;
        refbuf[5+8] =  32'h33333333;
        refbuf[6+8] =  32'h33333333;
        refbuf[7+8] =  32'h33333333;
        refbuf[0+16] = 32'h00000026;
        refbuf[1+16] = 32'h00000000;
        refbuf[2+16] = 32'h00000000;
        refbuf[3+16] = 32'h00000000;
        refbuf[4+16] = 32'h00000000;
        refbuf[5+16] = 32'h00000000;
        refbuf[6+16] = 32'h00000000;
        refbuf[7+16] = 32'h00000000;
        refbuf[0+24] = 32'h994ae86c;
        refbuf[1+24] = 32'h4f0896aa;
        refbuf[2+24] = 32'hb612506e;
        refbuf[3+24] = 32'he3b7ad11;
        refbuf[4+24] = 32'hf183c492;
        refbuf[5+24] = 32'h46c7a922;
        refbuf[6+24] = 32'hfeb3930d;
        refbuf[7+24] = 32'h5e181c59;
//        memwr(SEGADDR_PIB,32);
        sfrwr( PKE_segptr_PIB0, 32'h10 );
        sfrwr( PKE_crfunc, 32'h24 ); // I2MD
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);
        sfrwr( PKE_segptr_PIB0, 32'h0 );

        memrd(SEGADDR_POB,8*4);
        checkref(8*4);
        #( 1 `US );
/*    $display("\n@I:: PKE ED25519 - I2MA ");

        sfrwr( PKE_segptr_PIB0, 32'h0 );
        sfrwr( PKE_segptr_PIB1, 32'h10 );
        sfrwr( PKE_crfunc, 32'h23 ); // I2MA
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);

        memrd(SEGADDR_POB,8*4);
        checkref(8*4);
        sfrwr( PKE_segptr_PIB1, 32'h0 );
        #( 1 `US );
*/

//#(10 `US ) $finish;

        #( 1 `US );
        sfrwr(SDMA_ichcr_segid,32'h0b09);
        sfrwr(SDMA_ichcr_transize,32'd32);
        sfrwr(SDMA_chstart_ar,32'h5a);
        #( 10 `US );

        refbuf[0  ] =  32'h972189f4;
        refbuf[1  ] =  32'h37afef4b;
        refbuf[2  ] =  32'h2cd49994;
        refbuf[3  ] =  32'h4070c6f3;
        refbuf[4  ] =  32'h4444f76a;
        refbuf[5  ] =  32'hc1173625;
        refbuf[6  ] =  32'hee6d891e;
        refbuf[7  ] =  32'h4b5c6e98;
        refbuf[0+8] =  32'hfac0fb07;
        refbuf[1+8] =  32'hb728a843;
        refbuf[2+8] =  32'h7e3b703d;
        refbuf[3+8] =  32'h86a34b2a;
        refbuf[4+8] =  32'hb9e22a85;
        refbuf[5+8] =  32'hb13d7170;
        refbuf[6+8] =  32'h25ddb291;
        refbuf[7+8] =  32'h176e9b58;
        refbuf[0+16] = 32'h5df1062f;
        refbuf[1+16] = 32'hc3511f0e;
        refbuf[2+16] = 32'ha7c2d514;
        refbuf[3+16] = 32'h01606607;
        refbuf[4+16] = 32'hcbdaa1cf;
        refbuf[5+16] = 32'h96af2b24;
        refbuf[6+16] = 32'heefc74f3;
        refbuf[7+16] = 32'h2a015005;
        refbuf[0+24] = 32'h0d78ed3b;
        refbuf[1+24] = 32'h2e9d950e;
        refbuf[2+24] = 32'h51bbc5b8;
        refbuf[3+24] = 32'h40ac787d;
        refbuf[4+24] = 32'hc902b652;
        refbuf[5+24] = 32'ha1e4cd8a;
        refbuf[6+24] = 32'h52f53e27;
        refbuf[7+24] = 32'h156aabe7;

        sfrwr( PKE_crfunc, 32'h26 );
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);
        memrd(SEGADDR_POB,8*4);
        checkref(8*4);

        #( 1 `US );
        sfrwr(SDMA_ichcr_segid,32'h0b09);
        sfrwr(SDMA_ichcr_transize,32'd32);
        sfrwr(SDMA_ichcr_wpstart,32'd32);
        sfrwr(SDMA_chstart_ar,32'h5a);
        #( 10 `US );


        sfrwr( PKE_segptr_PIB1, 'd32 );

        sfrwr( PKE_crfunc, 32'h2b );
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);
        memrd(SEGADDR_POB,8*4);

        refbuf[0  ] =  32'h2d066d9e;
        refbuf[1  ] =  32'h30eccbb4;
        refbuf[2  ] =  32'h03735d6a;
        refbuf[3  ] =  32'h01144cb6;
        refbuf[4  ] =  32'h8c900430;
        refbuf[5  ] =  32'h8eb9c012;
        refbuf[6  ] =  32'h2012176b;
        refbuf[7  ] =  32'h544539f8;
        refbuf[0+8] =  32'hccdde4d6;
        refbuf[1+8] =  32'h24d124f8;
        refbuf[2+8] =  32'h9fc385b1;
        refbuf[3+8] =  32'h23c64004;
        refbuf[4+8] =  32'hb4ee4089;
        refbuf[5+8] =  32'h713b604b;
        refbuf[6+8] =  32'h5e447916;
        refbuf[7+8] =  32'h7464294c;
        refbuf[0+16] = 32'h1d19d4f6;
        refbuf[1+16] = 32'h494cd6cb;
        refbuf[2+16] = 32'h1ceb4430;
        refbuf[3+16] = 32'ha4b5a0bf;
        refbuf[4+16] = 32'h0a23bd49;
        refbuf[5+16] = 32'haa9f813c;
        refbuf[6+16] = 32'heedca845;
        refbuf[7+16] = 32'h36381de3;
        refbuf[0+24] = 32'hd728eef6;
        refbuf[1+24] = 32'hda1bec5b;
        refbuf[2+24] = 32'h81094f61;
        refbuf[3+24] = 32'hc5536070;
        refbuf[4+24] = 32'hcb5fb33d;
        refbuf[5+24] = 32'hdd2abf27;
        refbuf[6+24] = 32'hcf5ee31a;
        refbuf[7+24] = 32'h3f9ff638;

       checkref(8*4);

        #( 1 `US );
        sfrwr(SDMA_ichcr_segid,32'h0b09);
        sfrwr(SDMA_ichcr_transize,32'd32);
        sfrwr(SDMA_ichcr_wpstart,32'd0);
        sfrwr(SDMA_chstart_ar,32'h5a);
        #( 10 `US );

        sfrwr( PKE_crfunc, 32'h27 );
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);
        memrd(SEGADDR_POB,8*2);

        refbuf[0   ] = 32'h777645ce;
        refbuf[1   ] = 32'hb12786bd;
        refbuf[2   ] = 32'h53187c24;
        refbuf[3   ] = 32'hc513d472;
        refbuf[4   ] = 32'h60d0f620;
        refbuf[5   ] = 32'h2297e08d;
        refbuf[6   ] = 32'h2b9d3429;
        refbuf[7   ] = 32'h55d0e09a;
        refbuf[0+8 ] = 32'h01985ad7;
        refbuf[1+8 ] = 32'hb70ab182;
        refbuf[2+8 ] = 32'hd3fe4bd5;
        refbuf[3+8 ] = 32'h3a0764c9;
        refbuf[4+8 ] = 32'hf372e10e;
        refbuf[5+8 ] = 32'h2523a6da;
        refbuf[6+8 ] = 32'h681a02af;
        refbuf[7+8 ] = 32'h1a5107f7;

        checkref(8*2);

       #( 10 `US );
//        $finish;


// pke
        #( 10 `US );
        $display("\n@I:: PKE ECC256r1");

        sfrwr( GLB_suben,'1 );
        sfrwr( PKE_optnw, 32'd256 );
        sfrwr( PKE_optew, 32'd256 );


        // P:
        membuf[ 0  ] = 32'h1F6E5377;
        membuf[ 1  ] = 32'h2013481D;
        membuf[ 2  ] = 32'hD5262028;
        membuf[ 3  ] = 32'h6E3BF623;
        membuf[ 4  ] = 32'h9D838D72;
        membuf[ 5  ] = 32'h3E660A90;
        membuf[ 6  ] = 32'hA1EEA9BC;
        membuf[ 7  ] = 32'hA9FB57DB;
        // A
        membuf[ 8  ] = 32'hF330B5D9;
        membuf[ 9  ] = 32'hE94A4B44;
        membuf[ 10 ] = 32'h26DC5C6C;
        membuf[ 11 ] = 32'hFB8055C1;
        membuf[ 12 ] = 32'h417AFFE7;
        membuf[ 13 ] = 32'hEEF67530;
        membuf[ 14 ] = 32'hFC2C3057;
        membuf[ 15 ] = 32'h7D5A0975;
        memwr(SEGADDR_PCON,16);
        membuf[ 0  ] = 32'h0;
        membuf[ 1  ] = 32'h0;
        membuf[ 2  ] = 32'h0;
        membuf[ 3  ] = 32'h0;
        membuf[ 4  ] = 32'h0;
        membuf[ 5  ] = 32'h0;
        membuf[ 6  ] = 32'h0;
        membuf[ 7  ] = 32'h0;
        membuf[ 8  ] = 32'h1;
        memwr(SEGADDR_PCON+16,9);
//        membuf[ 0  ] = 32'h1;
//        membuf[ 1  ] = 32'h0;
//        membuf[ 2  ] = 32'h0;
//        membuf[ 3  ] = 32'h0;
//        membuf[ 4  ] = 32'h0;
//        membuf[ 5  ] = 32'h0;
//        membuf[ 6  ] = 32'h0;
//        membuf[ 7  ] = 32'h0;
//        memwr(SEGADDR_PCON+16+9,8);

        sfrwr( PKE_crfunc, 32'h01 );
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);

        // K
        membuf[ 0  ] = 32'h39804F1D;
        membuf[ 1  ] = 32'hF77B0630;
        membuf[ 2  ] = 32'h41D79950;
        membuf[ 3  ] = 32'h300CB542;
        membuf[ 4  ] = 32'h8271BE38;
        membuf[ 5  ] = 32'hEA338D70;
        membuf[ 6  ] = 32'h00150FF2;
        membuf[ 7  ] = 32'h81DB1EE1;
        memwr(SEGADDR_PKB,8);

        // Q0_X,Q0_Y, I2MD
        membuf[ 0   ] = 32'h9ACE3262;
        membuf[ 1   ] = 32'h3A4453BD;
        membuf[ 2   ] = 32'hE3BD23C2;
        membuf[ 3   ] = 32'hB9DE27E1;
        membuf[ 4   ] = 32'hFC81B7AF;
        membuf[ 5   ] = 32'h2C4B482F;
        membuf[ 6   ] = 32'hCB7E57CB;
        membuf[ 7   ] = 32'h8BD2AEB9;
        membuf[ 0+8 ] = 32'h2F046997;
        membuf[ 1+8 ] = 32'h5C1D54C7;
        membuf[ 2+8 ] = 32'h2DED8E54;
        membuf[ 3+8 ] = 32'hC2774513;
        membuf[ 4+8 ] = 32'h14611DC9;
        membuf[ 5+8 ] = 32'h97F8461A;
        membuf[ 6+8 ] = 32'hC3DAC4FD;
        membuf[ 7+8 ] = 32'h547EF835;

        refbuf[0  ] = 32'h351fd10c;
        refbuf[1  ] = 32'h27c0d92d;
        refbuf[2  ] = 32'hb97cf30a;
        refbuf[3  ] = 32'h80de4d9a;
        refbuf[4  ] = 32'h6b892ad3;
        refbuf[5  ] = 32'h704c311d;
        refbuf[6  ] = 32'h9e119bdf;
        refbuf[7  ] = 32'h8e1f767a;
        refbuf[0+8] = 32'ha0917a17;
        refbuf[1+8] = 32'h9a4fe948;
        refbuf[2+8] = 32'hcd950162;
        refbuf[3+8] = 32'ha618f259;
        refbuf[4+8] = 32'hdfbd8b03;
        refbuf[5+8] = 32'h16fdf6e8;
        refbuf[6+8] = 32'h026eb0a2;
        refbuf[7+8] = 32'h14eb78c6;
        refbuf[0+16] = 32'he091ac89;
        refbuf[1+16] = 32'hdfecb7e2;
        refbuf[2+16] = 32'h2ad9dfd7;
        refbuf[3+16] = 32'h91c409dc;
        refbuf[4+16] = 32'h627c728d;
        refbuf[5+16] = 32'hc199f56f;
        refbuf[6+16] = 32'h5e115643;
        refbuf[7+16] = 32'h5604a824;

        memwr(SEGADDR_PIB,16);
        sfrwr( PKE_crfunc, 32'h04 ); // I2MD
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);

        memrd(SEGADDR_POB,8*3);
        checkref(8*3);

        #( 1 `US );
        sfrwr(SDMA_ichcr_segid,32'h0b09);
        sfrwr(SDMA_ichcr_transize,32'd24);
        sfrwr(SDMA_chstart_ar,32'h5a);
        #( 10 `US );

        refbuf[0   ] =  32'h4273816f;
        refbuf[1   ] =  32'h522c4f61;
        refbuf[2   ] =  32'h954dee9a;
        refbuf[3   ] =  32'h850f4a8b;
        refbuf[4   ] =  32'h47fb38ca;
        refbuf[5   ] =  32'hcea591e4;
        refbuf[6   ] =  32'h16a0bad9;
        refbuf[7   ] =  32'h2350fb71;
        refbuf[0+8 ] =  32'h118003c1;
        refbuf[1+8 ] =  32'h00f4fb49;
        refbuf[2+8 ] =  32'ha3353283;
        refbuf[3+8 ] =  32'h2c546a9b;
        refbuf[4+8 ] =  32'he7e6f540;
        refbuf[5+8 ] =  32'hf39e663d;
        refbuf[6+8 ] =  32'h08258897;
        refbuf[7+8 ] =  32'h556f60af;
        refbuf[0+16] = 32'h4122f42e;
        refbuf[1+16] = 32'h349fd291;
        refbuf[2+16] = 32'h9b2a02c5;
        refbuf[3+16] = 32'h4c31e4b3;
        refbuf[4+16] = 32'hbf7b1607;
        refbuf[5+16] = 32'h2dfbedd1;
        refbuf[6+16] = 32'h04dd6144;
        refbuf[7+16] = 32'h29d6f18c;

       sfrwr( PKE_crfunc, 32'h06 );
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);
        memrd(SEGADDR_POB,8*3);
        checkref(8*3);

        #( 1 `US );
        sfrwr(SDMA_ichcr_segid,32'h0b09);
        sfrwr(SDMA_ichcr_transize,32'd24);
        sfrwr(SDMA_ichcr_wpstart,32'd24);
        sfrwr(SDMA_chstart_ar,32'h5a);
        #( 10 `US );


        sfrwr( PKE_segptr_PIB1, 'd24 );

        sfrwr( PKE_crfunc, 32'h0b );
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);
        memrd(SEGADDR_POB,8*3);

        refbuf[0   ] = 32'hb033388e;
        refbuf[1   ] = 32'ha9274524;
        refbuf[2   ] = 32'hf64bcc5e;
        refbuf[3   ] = 32'h38f92d82;
        refbuf[4   ] = 32'hc150a4d4;
        refbuf[5   ] = 32'h9de08088;
        refbuf[6   ] = 32'hc0b1bf85;
        refbuf[7   ] = 32'ha3b76364;
        refbuf[0+8 ] = 32'hab1aa5e2;
        refbuf[1+8 ] = 32'h0e34b98d;
        refbuf[2+8 ] = 32'h45d1085d;
        refbuf[3+8 ] = 32'h81523076;
        refbuf[4+8 ] = 32'h032908ac;
        refbuf[5+8 ] = 32'haa3c1e36;
        refbuf[6+8 ] = 32'h7ec54bf8;
        refbuf[7+8 ] = 32'h1f4d97af;
        refbuf[0+16] = 32'hb8af1d7d;
        refbuf[1+16] = 32'hee69f560;
        refbuf[2+16] = 32'h2caa4cf1;
        refbuf[3+16] = 32'hb316455a;
        refbuf[4+16] = 32'hb0af23b3;
        refbuf[5+16] = 32'h76a1f23b;
        refbuf[6+16] = 32'hde723ec3;
        refbuf[7+16] = 32'h24433ae5;

       checkref(8*3);

        #( 1 `US );
        sfrwr(SDMA_ichcr_segid,32'h0b09);
        sfrwr(SDMA_ichcr_transize,32'd24);
        sfrwr(SDMA_ichcr_wpstart,32'd0);
        sfrwr(SDMA_chstart_ar,32'h5a);
        #( 10 `US );

        sfrwr( PKE_crfunc, 32'h07 );
        sfrwr( PKE_ar, 32'h5a ); sfrwait(PKE_fr, 32'h1, 32'h1); sfrwr(PKE_fr, 32'h1);
        memrd(SEGADDR_POB,8*2);

        refbuf[0   ] = 32'he3100be5;
        refbuf[1   ] = 32'h85f929a8;
        refbuf[2   ] = 32'h49e81d9e;
        refbuf[3   ] = 32'hb95e1aaa;
        refbuf[4   ] = 32'h53a8414d;
        refbuf[5   ] = 32'ha1705d99;
        refbuf[6   ] = 32'h3f92bc02;
        refbuf[7   ] = 32'h44106e91;
        refbuf[0+8 ] = 32'heb089bdc;
        refbuf[1+8 ] = 32'hf789ef10;
        refbuf[2+8 ] = 32'h2c272223;
        refbuf[3+8 ] = 32'h00a69fd3;
        refbuf[4+8 ] = 32'hd120f5a9;
        refbuf[5+8 ] = 32'h3ce49cbd;
        refbuf[6+8 ] = 32'h11caccb7;
        refbuf[7+8 ] = 32'h8ab4846f;
        refbuf[0+16] = 32'h0;
        refbuf[1+16] = 32'h0;
        refbuf[2+16] = 32'h0;
        refbuf[3+16] = 32'h0;
        refbuf[4+16] = 32'h0;
        refbuf[5+16] = 32'h0;
        refbuf[6+16] = 32'h0;
        refbuf[7+16] = 32'h0;

        checkref(8*2);
`ifdef NOFSDB
end
`endif
    `maintestend

// ■■■■■■■■■■■■■■■


    task memwr();
        input bit [AW-1:0] thaddr;
        input integer tc;
        $write("@::memwr:: %04x <- ", SCERAM_BA+thaddr );
        for (int i = 0; i < tc; i++) begin
            ahbwr( (SCERAM_BA+thaddr+i)*4, membuf[i] );
            $write(" %08x", membuf[i]);
            @(negedge hclk);
        end
        $write("\n");
    endtask

    task memrd();
        input bit [AW-1:0] thaddr;
        input integer tc;
        $write("@::memrd:: %04x -> ", SCERAM_BA+thaddr );
        for (int i = 0; i < tc; i++) begin
            ahbrd( (SCERAM_BA+thaddr+i)*4 );
            @(negedge hdataphase);
            @(negedge hclk);
            membuf[i] = hrdatareg;
            $write(" %08x", membuf[i]);
        end
        $write("\n");
    endtask

    task checkref();
        input integer tc;
        bit checkbit=1;
        checkbit='1;
        $write("@::chref:: ---- -> " );
        for (int i = 0; i < tc; i++) begin
            $write(" %08x", refbuf[i]);
            checkbit = checkbit & ( refbuf[i] == membuf[i] );
            if(refbuf[i] != membuf[i] )
            $write("@E: !!![%02d][ref:%08x][mem:%08x]\n",i,refbuf[i],membuf[i]);
        end
        $write(" %01x \n", checkbit);
        if(checkbit)
            $write("@i: PASS!\n");
        else begin
            errcnt = errcnt + 1;
            $write("@E: FAIL! %0d\n", errcnt);
           // $stop;
        end
        sfrrd(GLB_tickcyc);
        sfrrd(GLB_tickcnt);
    endtask

    task sfrwr();
        input bit  [AW-1:0]  thaddr;
        input bit  [DW-1:0]  thwdata;
        $write("@::sfrwr:: %04x <- ", thaddr );
        ahbwr( thaddr, thwdata );
        $write(" %08x", thwdata );
        $write("\n");
    endtask

    task sfrrd();
        input bit [AW-1:0] thaddr;
        $write("@::sfrrd:: %04x -> ", thaddr );
        ahbrd( thaddr );
        @(negedge hdataphase);
        @(negedge hclk);
        $write(" %08x", hrdatareg);
        $write("\n");
    endtask

    task sfrwait();
        input bit [AW-1:0] thaddr;
        input bit [DW-1:0] texpdata;
        input bit [DW-1:0] tmask;

        $write("@::sfrwait:: %04x == %08x & %08x ? ", thaddr, texpdata, tmask );
        while(1)begin
            ahbrd( thaddr );
            @(negedge hdataphase);
            @(negedge hclk);
            if( hrdatareg & tmask == texpdata ) break;
        end
        $write(" done! ");
        $write("\n");
    endtask

// ■■■■■■■■■■■■■■■

    task ahbrd();
        input bit  [AW-1:0]  thaddr;
        @( posedge hready & clk);
        @(negedge hclk);
        hsel = 1;
        haddr = thaddr;
        htrans = 'h2;
        hwrite = '0;
        @(negedge hclk);
        hsel = 0;
    endtask : ahbrd

        `theregrn(hdataphase) <= ( hsel & hreadym & |htrans & ~hwrite ) ? 1 : hready ? 0 : hdataphase;
        `theregrn(hrdatareg) <= hdataphase & hready ? hrdata : hrdatareg;

    task ahbwr();
        input bit  [AW-1:0]  thaddr;
        input bit  [DW-1:0]   thwdata;
        @( posedge hready & clk);
        @(negedge hclk);
        hsel = 1;
        haddr = thaddr;
        htrans = 'h2;
        hwrite = '1;
        hwdata = thwdata;
        @(negedge hclk);
        hsel = 0;
        hwrite = '0;
    endtask : ahbwr

endmodule


    module wire2ahbm #(
      parameter AW=16,
      parameter DW=32,
      parameter IDW=8,
      parameter UW=4
     )(
        ahbif.master          ahbm,
        input wire            hsel,
        input wire  [AW-1:0]  haddr,
        input wire  [1:0]     htrans,
        input wire            hwrite,
        input wire  [2:0]     hsize,
        input wire  [2:0]     hburst,
        input wire  [3:0]     hprot,
        input wire  [IDW-1:0] hmaster,
        input bit   [DW-1:0]  hwdata,
        input wire            hmasterlock,
        input wire            hreadym,
        input wire  [UW-1:0]  hauser,
        input wire  [UW-1:0]  hwuser,
        output bit   [DW-1:0]  hrdata,
        output wire            hready,
        output wire            hresp,
        output logic  [UW-1:0]  hruser
    );
        assign ahbm.hsel = hsel;
        assign ahbm.haddr = haddr;
        assign ahbm.htrans = htrans;
        assign ahbm.hwrite = hwrite;
        assign ahbm.hsize = hsize;
        assign ahbm.hburst = hburst;
        assign ahbm.hprot = hprot;
        assign ahbm.hmaster = hmaster;
        assign ahbm.hwdata = hwdata;
        assign ahbm.hmasterlock = hmasterlock;
        assign ahbm.hreadym = hreadym;
        assign ahbm.hauser = hauser;
        assign ahbm.hwuser = hwuser;

        assign hrdata = ahbm.hrdata;
        assign hready = ahbm.hready;
        assign hresp = ahbm.hresp;
        assign hruser = ahbm.hruser;

    endmodule


