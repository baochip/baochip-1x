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

module dkpc#(
    parameter KPOC = 4,
    parameter KPIC = 4
)(

    input logic pclk,
    input logic resetn,
    input logic clk ,

    apbif.slavein   apbs,
    apbif.slave     apbx,

    ioif.drive kpo[KPOC-1:0],
    ioif.drive kpi[KPIC-1:0],

    output logic evirq,
    output logic wkupvld_async

);

    bit [3:0][7:0] cfg_cnt;
    bit [7:0] cfg_cnt1ms;
    bit [7:0] cfg_step,cfg_filter;
    bit [7:0] cfgcnt_predrv, cfgcnt_smpl, cfgcnt_pstdrv, cfgcnt_intv;

    bit [15:0] tikcnt,cfg_deep10ms,tikcntsleep;
    bit [7:0]  tikcnt_10mscnt;
    bit tikcnt_10mshit;

    bit [7:0] mfsm, mfsmnext, mfsmcnt, cnttikcnt ;
    bit cnttik, mfsmdone, mfsmsleep;
    bit kpivld_async;
    bit autosleepen, autosleep;

    bit kpodrv0, mfsmcnt_smpl, mfsmcnt_smpl1, mfsmcnt_smpl2;
    bit KPOOE1,KPOOE0,KPOPO1,KPOPO0,dkpcen;
    bit [KPOC-1:0][KPIC-1:0] kpnodereg, kpnodereg1, kpnoderise, kpnodefall, kpnoderiseen, kpnodefallen;

    bit [4:0] evidx;
    bit [20:0] evdat,evffrdat;
    bit evvld, evffvld, evffrd;

    assign cfgcnt_predrv = cfg_cnt[0];
    assign cfgcnt_smpl = cfg_cnt[1];
    assign cfgcnt_pstdrv = cfg_cnt[2];
    assign cfgcnt_intv = cfg_cnt[3];

     assign wkupvld_async = kpivld_async;

// mfsm

    `theregrn( mfsm ) <= mfsmnext;
    assign mfsmnext = ~dkpcen ? 0 : ( mfsm == KPOC )&mfsmdone ? 1 : mfsm + mfsmdone;

    `theregrn( mfsmcnt ) <= ~dkpcen|mfsmdone ? '0 : mfsmsleep ? mfsmcnt : ( mfsmcnt + cnttik );
    assign mfsmdone = cnttik & ( mfsmcnt == cfgcnt_intv );

    `theregrn( cnttikcnt ) <= ~dkpcen|cnttik ? '0 : mfsmsleep ? cnttikcnt : ( cnttikcnt + 1 );
    assign cnttik = (cnttikcnt == cfg_step);

    `theregrn( mfsmsleep  ) <= ~autosleep ? 0 : autosleep & mfsmdone ? 1 : mfsmsleep;


// mfsm
    `theregsn( tikcnt )         <= ~dkpcen ? '1 : evvld ? '0 : (tikcnt == cfg_deep10ms) ? tikcnt : tikcnt + tikcnt_10mshit;
    `theregsn( tikcnt_10mscnt ) <= ~dkpcen ? '0 : evvld ? '0 : (tikcnt == cfg_deep10ms) ? '0 : tikcnt_10mshit ? '0 : tikcnt_10mscnt + 1;
    assign tikcnt_10mshit = ( tikcnt_10mscnt == cfg_cnt1ms * 10 );

    `theregsn( tikcntsleep )    <= ~dkpcen ? '1 : evvld | kpivld_async ? '0 : (tikcntsleep == cfg_deep10ms) ? tikcntsleep : tikcntsleep + tikcnt_10mshit;
    `theregrn( autosleep ) <= (tikcntsleep == cfg_deep10ms - 1) & tikcnt_10mshit & autosleepen & dkpcen ? 1 : autosleep & kpivld_async ? 0 : autosleep;

    assign kpivld_async = dkpcen & (( kpi[3].pi == KPOPO1 ) | ( kpi[2].pi == KPOPO1 ) | ( kpi[1].pi == KPOPO1 ) | ( kpi[0].pi == KPOPO1 ) );

// drive

    genvar i,j;

    assign mfsmcnt_smpl = ( mfsmcnt == cfgcnt_smpl ) & cnttik ;
    `theregrn( {mfsmcnt_smpl2, mfsmcnt_smpl1} ) <= { mfsmcnt_smpl1, mfsmcnt_smpl };
    `theregrn( kpodrv0 ) <= cnttik ? (( mfsmcnt == cfgcnt_predrv ) ? 1 : ( mfsmcnt == cfgcnt_pstdrv ) ? '0 : kpodrv0 ) : kpodrv0;

    generate
        for ( i = 0; i < KPOC; i++) begin: gendrv
            bit kpodrv;
            `theregrn( kpodrv ) <= (mfsm == i+1) & kpodrv0;
            assign kpo[i].po = (mfsmsleep | kpodrv) ? KPOPO1:KPOPO0;
            assign kpo[i].oe = (mfsmsleep | kpodrv) ? KPOOE1:KPOOE0;
            assign kpo[i].pu = 1'b1;

            assign kpi[i].po = '0;
            assign kpi[i].oe = '0;
            assign kpi[i].pu = '0;

            for ( j = 0; j < KPIC; j++) begin: gennode
                bit kpnodein, kpnodeinreg, kpnodeintog;
                bit [7:0] kpnodeincnt;
                `theregrn( kpnodein ) <= ~dkpcen ? KPOPO0 : (mfsm==i+1) & mfsmcnt_smpl ? kpi[j].pi : kpnodein;
                `theregrn( kpnodeinreg ) <= ~dkpcen ? KPOPO0 : kpnodein;
                assign kpnodeintog = (mfsm==i+1) & mfsmcnt_smpl1 & (kpnodeinreg != kpnodein);
                `theregrn( kpnodeincnt ) <= (mfsm==i+1) & mfsmcnt_smpl1 ? ( kpnodeintog ? '0 :  ( kpnodeincnt != cfg_filter ) ?  kpnodeincnt + 1 : kpnodeincnt ) : kpnodeincnt;

                `theregrn( kpnodereg[i][j] ) <=  ~dkpcen ? KPOPO0 : (mfsm==i+1) & mfsmcnt_smpl2 & ( kpnodeincnt == cfg_filter ) ? kpnodeinreg : kpnodereg[i][j];
                `theregrn( kpnodereg1[i][j] ) <= ~dkpcen ? KPOPO0 : kpnodereg[i][j];
                `theregrn( kpnoderise[i][j] ) <=  kpnodereg[i][j] & ~kpnodereg1[i][j] & kpnoderiseen[i][j];
                `theregrn( kpnodefall[i][j] ) <= ~kpnodereg[i][j] &  kpnodereg1[i][j] & kpnodefallen[i][j];
            end

        end
    endgenerate


    always@(*)
    begin
        evidx = '0;
        for (int m = 0; m < KPOC; m++) begin
            for (int n = 0; n < KPIC; n++) begin
                if( kpnoderise[m][n] ) evidx = m*KPOC+n;
                if( kpnodefall[m][n] ) evidx = m*KPOC+n + (KPOC*KPIC);
            end
        end
    end

    assign evvld = |{ kpnoderise, kpnodefall };

    assign evdat = {tikcnt, evidx};

    assign evirq = evvld;

// queue


    bit evfifofull_atclk, evfifofullreg0, evfifofullreg, evffrd_sfr, evffrd_drop;

    udma_dc_fifo #(
        .DATA_WIDTH(5+16),
        .BUFFER_DEPTH(8+3)
    ) evfifo
    (
        .src_clk_i    ( clk       ),
        .src_rstn_i   ( resetn    ),
        .src_data_i   ( evdat ),
        .src_valid_i  ( evvld ),
        .src_ready_o  (  ),
        .dst_clk_i    ( pclk          ),
        .dst_rstn_i   ( resetn ),
        .dst_data_o   ( evffrdat     ),
        .dst_valid_o  ( evffvld ),
        .dst_ready_i  ( evffrd )
    );

    assign evfifofull_atclk = ~evfifo.src_ready_o;

    `theregfull( pclk, resetn, {evfifofullreg,evfifofullreg0}, '0 ) <= {evfifofullreg0, evfifofull_atclk};
    assign evffrd = evffrd_sfr | evffrd_drop;
    assign evffrd_drop = evfifofullreg0 & ~evfifofullreg;


// sfr
// ==

    bit apbrd, apbwr;

    `apbs_common;
    logic sfrlock;
    assign sfrlock = '0;
    assign apbx.prdata = '0
                | sfr_cfg0.prdata32 |  sfr_cfg1.prdata32 | sfr_cfg2.prdata32 | sfr_cfg3.prdata32 | sfr_cfg4.prdata32
                | sfr_sr0.prdata32 | sfr_sr1.prdata32
                | sfr_ff.prdata32
                ;

    apb_cr #(.A('h00), .DW(6), .IV(32'hd))              sfr_cfg0  (.cr({autosleepen,dkpcen,KPOOE1,KPOOE0,KPOPO1,KPOPO0}),   .prdata32(),.*);
    apb_cr #(.A('h04), .DW(24), .IV(32'h1f1010))        sfr_cfg1  (.cr({cfg_cnt1ms,cfg_filter,cfg_step}),   .prdata32(),.*);
    apb_cr #(.A('h08), .DW(32), .IV(32'hff20_18_10))    sfr_cfg2  (.cr(cfg_cnt),   .prdata32(),.*);
    apb_cr #(.A('h0C), .DW(32), .IV(32'hffffffff))      sfr_cfg3  (.cr({kpnodefallen,kpnoderiseen}),   .prdata32(),.*);
    apb_cr #(.A('h30), .DW(16), .IV(32'd500))           sfr_cfg4  (.cr(cfg_deep10ms),   .prdata32(),.*);

    apb_sr #(.A('h10), .DW(KPOC*KPIC+4) )      sfr_sr0          (.sr({kpi[3].pi, kpi[2].pi, kpi[1].pi, kpi[0].pi,  kpnodereg}), .prdata32(),.*);
    apb_sr #(.A('h14), .DW(1) )                sfr_sr1          (.sr(evffvld), .prdata32(),.*);

    apb_buf2  #(.BAW(3), .A(12'h20), .DW(32) ) sfr_ff (
        .prdata32(),
        .buf_addr   (),
        .buf_write  (),
        .buf_read   (evffrd_sfr),
        .buf_datain (),
        .buf_dataout({evffrdat[20:5],11'h0,evffrdat[4:0]}),
        .*);


endmodule;

module dummytb_dpkc ();
    parameter KPOC = 4;
    parameter KPIC = 4;
    logic pclk;
    logic resetn;
    logic clk;
    apbif apbs();
    apbif apbx();
    ioif kpo[KPOC-1:0]();
    ioif kpi[KPIC-1:0]();
    logic evirq;
    logic wkupvld_async;

    dkpc u0(.*);

endmodule

module apb_buf2
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

`ifdef SIM_DKPC

module dkpc_tb ();

    localparam AW = 12;
    localparam IDW = 8;
    localparam DW = 32;
    localparam UW = 4;

    parameter KPOC = 4;
    parameter KPIC = 4;
    integer i=0, j=0, k=0, errcnt=0, warncnt=0;
    bit pclk, hclk;
    bit resetn;
    bit clk;
    bit clklf;
    apbif apbs();
    ahbif ahbs();
    ioif kpo[KPOC-1:0]();
    ioif kpi[KPIC-1:0]();
    bit evirq;
    bit wkupvld_async;
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
    wire2ahbm2 ahbdrv(.ahbm(ahbs),.*);

    apb_bdg #(.PAW(12)) pbdg(
        .hclk     (clk),
        .resetn   (resetn),
        .pclken   (1'b1),
        .ahbslave (ahbs),
        .apbmaster(apbs)
    );

    dkpc dut(
        .pclk,
        .resetn,
        .clk (clklf),
        .apbs(apbs),
        .apbx(apbs),
        .kpo,
        .kpi,
        .evirq,
        .wkupvld_async,
        .*
        );

    wire [3:0] kpiline, kpoline, kpolinedrv, kpolineoe;
    bit [3:0][3:0] kpad;

    pullup(kpiline[0]);
    pullup(kpiline[1]);
    pullup(kpiline[2]);
    pullup(kpiline[3]);
    pullup(kpoline[0]);
    pullup(kpoline[1]);
    pullup(kpoline[2]);
    pullup(kpoline[3]);

    assign kpoline[0] = kpolineoe[0] ? kpolinedrv[0] : 1'hz;
    assign kpoline[1] = kpolineoe[1] ? kpolinedrv[1] : 1'hz;
    assign kpoline[2] = kpolineoe[2] ? kpolinedrv[2] : 1'hz;
    assign kpoline[3] = kpolineoe[3] ? kpolinedrv[3] : 1'hz;

    ioif2wire #(KPOC)iokpo(.ioout(kpolinedrv),.iooe(kpolineoe),.iopu(),.ioin('0),.ioifld(kpo));
    ioif2wire #(KPIC)iokpi(.ioout(),.iooe(),.iopu(),.ioin(kpiline),.ioifld(kpi));

    assign kpiline[0] = kpad[0][0] ? kpoline[0] : kpad[1][0] ? kpoline[1] : kpad[2][0] ? kpoline[2] : kpad[3][0] ? kpoline[3] : 1'hz;
    assign kpiline[1] = kpad[0][1] ? kpoline[0] : kpad[1][1] ? kpoline[1] : kpad[2][1] ? kpoline[2] : kpad[3][1] ? kpoline[3] : 1'hz;
    assign kpiline[2] = kpad[0][2] ? kpoline[0] : kpad[1][2] ? kpoline[1] : kpad[2][2] ? kpoline[2] : kpad[3][2] ? kpoline[3] : 1'hz;
    assign kpiline[3] = kpad[0][3] ? kpoline[0] : kpad[1][3] ? kpoline[1] : kpad[2][3] ? kpoline[2] : kpad[3][3] ? kpoline[3] : 1'hz;

  //
  //  monitor and clk
  //  ==

    `genclk( clk, 5 )
    `genclk( clklf, 100 )
    `timemarker2
    assign hclk = clk;
    assign pclk = clk;


// ■■■■■■■■■■■■■■■
//    apb_cr #(.A('h00), .DW(5), .IV(32'hd))              sfr_cfg0  (.cr({dkpcen,KPOOE1,KPOOE0,KPOPO1,KPOPO0}),   .prdata32(),.*);
//    apb_cr #(.A('h04), .DW(16), .IV(32'h1010))             sfr_cfg1  (.cr({cfg_filter,cfg_step}),   .prdata32(),.*);
//    apb_cr #(.A('h08), .DW(32), .IV(32'hff20_18_10))    sfr_cfg2  (.cr(cfg_cnt),   .prdata32(),.*);
//    apb_cr #(.A('h0C), .DW(32), .IV(32'hffffffff))      sfr_cfg3  (.cr({kpnodefallen,kpnoderiseen}),   .prdata32(),.*);
//
//    apb_sr #(.A('h10), .DW(KPOC*KPIC) )      sfr_sr0          (.sr(kpnodereg), .prdata32(),.*);
//    apb_sr #(.A('h14), .DW(1) )              sfr_sr1          (.sr(evffvld), .prdata32(),.*);
//
//    apb_buf2  #(.BAW(3), .A(12'h20), .DW(5+16) ) sfr_ff (
//        .prdata32(),
//        .buf_addr   (),
//        .buf_write  (),
//        .buf_read   (evffrd),
//        .buf_datain (),
//        .buf_dataout(evffrdat),
//        .*);

    `maintest(dkpc_tb,dkpc_tb)
        resetn = 0;
        #( 200 );
        #( 2 `US );
        resetn = 1;
        #( 2 `US );

        sfrwr('h0, 32'h0d );
        #( 200 `US );
        sfrwr('h0, 32'h3d );
        sfrwr('h4, 32'h0f0300 );
        sfrwr('h8, 32'h0f0c0804 );
        sfrwr('hc, 32'h0000ffff );
        sfrwr('h30, 32'h3 );

        for(i=0;i<16;i++)begin
           #(100 `US); kpadpush(i);
           #(100 `US); kpadrelease(i);
        end
        #(100 `US); kpadpush(5);
        #(100 `US); kpadpush(7);
        #(100 `US); kpadrelease(7);
        #(100 `US); kpadpush(2);
        #(100 `US); kpadrelease(5);
        #(100 `US); kpadrelease(2);

        sfrrd('h10);
        sfrrd('h14);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);
        sfrrd('h20);

        #( 500 `US );



    `maintestend

// ■■■■■■■■■■■■■■■

    task kpadpush();
        input bit  [3:0]  thenum;
        @(negedge clk);
        kpad[thenum[3:2]][thenum[1:0]]=1;
        @(negedge clk);
    endtask : kpadpush

    task kpadrelease();
        input bit  [3:0]  thenum;
        @(negedge clk);
        kpad[thenum[3:2]][thenum[1:0]]=0;
        @(negedge clk);
    endtask : kpadrelease

// ■■■■■■■■■■■■■■■

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


endmodule : dkpc_tb


    module wire2ahbm2 #(
      parameter AW=12,
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



`endif