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

module scedma #
(
    parameter AXID = 'h5,
    parameter AW = scedma_pkg::AW,
    parameter DW = scedma_pkg::DW,
    parameter FFCNT = scedma_pkg::FFCNT,
    parameter adr_t BA = 0,
    parameter SEGCNT  = scedma_pkg::SEGCNT,
    parameter segcfg_t [0:SEGCNT-1] SEGCFGS = scedma_pkg::SEGCFGS,
    parameter TRANSCNTW = scedma_pkg::TRANSCNTW,
    parameter TSW = TRANSCNTW
)(
    input logic clk,
    input logic resetn,

    apbif.slavein apbs,
    apbif.slave   apbx,
    axiif.master  axim[0:1],
    input  bit [1:0]       scemode,

    output chnlreq_t       xchrpreq,
    input  chnlres_t       xchrpres,
    output chnlreq_t       xchwpreq,
    input  chnlres_t       xchwpres,

    output chnlreq_t       schrpreq,
    input  chnlres_t       schrpres,
    output chnlreq_t       schwpreq,
    input  chnlres_t       schwpres,

    output chnlreq_t       ichrpreq,
    input  chnlres_t       ichrpres,
    output chnlreq_t       ichwpreq,
    input  chnlres_t       ichwpres,

    input   bit            schcrxsel, schstartx,
    input   chcr_t         schcrx,
    output chnlreq_t       schxrpreq,
    input  chnlres_t       schxrpres,
    output chnlreq_t       schxwpreq,
    input  chnlres_t       schxwpres,

    input   bit [0:FFCNT-1] segfifoen,
    output bit[2:0]           sr_sdma,
    output bit[2:0]           fr_sdma,

    output bit [7:0]       intr,
    output bit [7:0]       err
);
    bit [15:0]  ichcr_segid;
    bit [7:0]   ichcr_rpsegid;
    bit [7:0]   ichcr_wpsegid;
    adr_t       ichcr_rpstart;
    adr_t       ichcr_wpstart;
    adr_t       ichcr_transize;
    bit [3:0]   ichcr_opt;
    bit [2:0]   ichcr_opt_ltx;
    bit         ichcr_opt_xor;

    chcr_t            xchcr,          schcr, schcr0;

    logic ichstart, xchstart, schstart;
    logic ichbusy, xchbusy, schbusy;
    logic ichdone, xchdone, schdone;

    logic [7:0]  schcr_intr, xchcr_intr, ichcr_intr, schcr_err, xchcr_err;
    logic apbrd, apbwr, sfrlock;
    logic pclk;
    bit [1:0]  wdatabypass_mode;
    bit [31:0] wdatabypass_data;

// sfr
// ■■■■■■■■■■■■■■■

    assign pclk = clk;
    assign sfrlock = 0;

//    apb_sr #(.A('h18 ), .DW(1)    ) sfr_sdma_sr      (.sr( sr_sdma        ), .prdata32(),.*);
    apb_ar #(.A('h00 ), .AR('h5a) ) sfr_ichstart_ar  (.ar( ichstart       ), .*);
    apb_ar #(.A('h00 ), .AR('ha5) ) sfr_xchstart_ar  (.ar( xchstart       ), .*);
    apb_ar #(.A('h00 ), .AR('haa) ) sfr_schstart_ar  (.ar( schstart       ), .*);

    apb_cr #(.A('h10 ), .DW(1)    ) sfr_xch_func     (.cr( xchcr.func     ), .prdata32(),.*);
    apb_cr #(.A('h14 ), .DW(10)   ) sfr_xch_opt      (.cr( xchcr.opt      ), .prdata32(),.*);
    apb_cr #(.A('h18 ), .DW(32)   ) sfr_xch_axstart  (.cr( xchcr.axstart  ), .prdata32(),.*);
    apb_cr #(.A('h1c ), .DW(8)    ) sfr_xch_segid    (.cr( xchcr.segid    ), .prdata32(),.*);
    apb_cr #(.A('h20 ), .DW(AW)   ) sfr_xch_segstart (.cr( xchcr.segstart ), .prdata32(),.*);
    apb_cr #(.A('h24 ), .DW(TSW)  ) sfr_xch_transize (.cr( xchcr.transize ), .prdata32(),.*);

    apb_cr #(.A('h30 ), .DW(1)    ) sfr_sch_func     (.cr( schcr.func     ), .prdata32(),.*);
    apb_cr #(.A('h34 ), .DW(10)   ) sfr_sch_opt      (.cr( schcr.opt      ), .prdata32(),.*);
    apb_cr #(.A('h38 ), .DW(32)   ) sfr_sch_axstart  (.cr( schcr.axstart  ), .prdata32(),.*);
    apb_cr #(.A('h3c ), .DW(8)    ) sfr_sch_segid    (.cr( schcr.segid    ), .prdata32(),.*);
    apb_cr #(.A('h40 ), .DW(AW)   ) sfr_sch_segstart (.cr( schcr.segstart ), .prdata32(),.*);
    apb_cr #(.A('h44 ), .DW(TSW)  ) sfr_sch_transize (.cr( schcr.transize ), .prdata32(),.*);

    apb_cr #(.A('h50 ), .DW(4)    ) sfr_ich_opt      (.cr( ichcr_opt      ), .prdata32(),.*);
    apb_cr #(.A('h54 ), .DW(16)   ) sfr_ich_segid    (.cr( ichcr_segid    ), .prdata32(),.*);
    apb_cr #(.A('h58 ), .DW(AW)   ) sfr_ich_rpstart  (.cr( ichcr_rpstart  ), .prdata32(),.*);
    apb_cr #(.A('h5c ), .DW(AW)   ) sfr_ich_wpstart  (.cr( ichcr_wpstart  ), .prdata32(),.*);
    apb_cr #(.A('h60 ), .DW(AW)   ) sfr_ich_transize (.cr( ichcr_transize ), .prdata32(),.*);

    apb_cr #(.A('h70 ), .DW(2)    ) sfr_wdatabypass_mode  (.cr( wdatabypass_mode  ), .prdata32(),.*);
    apb_cr #(.A('h74 ), .DW(32)   ) sfr_wdatabypass_data  (.cr( wdatabypass_data  ), .prdata32(),.*);


    assign sr_sdma = { xchbusy, schbusy, ichbusy };
    assign fr_sdma = { xchdone, schdone, ichdone };
    assign { ichcr_rpsegid, ichcr_wpsegid } = ichcr_segid;
    assign { ichcr_opt_ltx, ichcr_opt_xor } = ichcr_opt;

    `apbs_common;
    assign apbx.prdata = '0
        | sfr_xch_func.prdata32 | sfr_xch_opt.prdata32 | sfr_xch_axstart.prdata32 | sfr_xch_segid.prdata32 | sfr_xch_segstart.prdata32 | sfr_xch_transize.prdata32
        | sfr_sch_func.prdata32 | sfr_sch_opt.prdata32 | sfr_sch_axstart.prdata32 | sfr_sch_segid.prdata32 | sfr_sch_segstart.prdata32 | sfr_sch_transize.prdata32
        | sfr_ich_opt.prdata32 | sfr_ich_segid.prdata32 | sfr_ich_rpstart.prdata32 | sfr_ich_wpstart.prdata32 | sfr_ich_transize.prdata32;

// axi mux
// ■■■■■■■■■■■■■■■
//
//    parameter XAW  = 32;
//    parameter XDW  = 32;
//    parameter XIDW  = 8;
//    parameter XUDW  = 8;
//    parameter XLENW = 3;
//
//     axiif #(
//        .AW     ( XAW    ),
//        .DW     ( XDW    ),
//        .LENW   ( XLENW  ),
//        .IDW    ( XIDW   ),
//        .UW     ( XUDW   )
//      ) xchaxi(), schaxi();
//
//     AXI_BUS #(
//        .AXI_ADDR_WIDTH     ( XAW    ),
//        .AXI_DATA_WIDTH     ( XDW    ),
//        .AXI_ID_WIDTH       ( XIDW   ),
//        .AXI_USER_WIDTH     ( XUDW   )
//      ) axim_pulp[1:0](), axis_pulp();
//
//    axi_mux_intf #(
//    /*  parameter int unsigned*/ .SLV_AXI_ID_WIDTH ( XIDW   ), // Synopsys DC requires default value for params
//    /*  parameter int unsigned*/ .MST_AXI_ID_WIDTH ( XIDW+1 ),
//    /*  parameter int unsigned*/ .AXI_ADDR_WIDTH   ( XAW    ),
//    /*  parameter int unsigned*/ .AXI_DATA_WIDTH   ( XDW    ),
//    /*  parameter int unsigned*/ .AXI_USER_WIDTH   ( XUDW   ),
//    /*  parameter int unsigned*/ .NO_SLV_PORTS     ( 2      ), // Number of slave ports
//    /*  parameter int unsigned*/ .MAX_W_TRANS      ( 1      ),
//    /*  parameter bit         */ .FALL_THROUGH     ( 1'b0  ),
//    /*  parameter bit         */ .SPILL_AW         ( 1'b0  ),
//    /*  parameter bit         */ .SPILL_W          ( 1'b0  ),
//    /*  parameter bit         */ .SPILL_B          ( 1'b0  ),
//    /*  parameter bit         */ .SPILL_AR         ( 1'b0  ),
//    /*  parameter bit         */ .SPILL_R          ( 1'b0  )
//    ) axi_mux (
//          .clk_i                  ( clk     ),
//          .rst_ni                 ( resetn  ),
//          .test_i                 ( 1'b0    ),
//          .slv                    ( axim_pulp ),
//          .mst                    ( axis_pulp )
//    );
//
//    axitrans_axi2pulp at1( .axis(xchaxi), .axim(axim_pulp[0]) );
//    axitrans_axi2pulp at2( .axis(schaxi), .axim(axim_pulp[1]) );
//    axitrans_pulp2axi at3( .axis(axis_pulp), .axim(axim ));
//
// axi chnl
    // ■■■■■■■■■■■■■■■
    logic schstart0;
    bit [0:FFCNT-1] segfifoen0;
    chnlreq_t       sch0rpreq;
    chnlres_t       sch0rpres;
    chnlreq_t       sch0wpreq;
    chnlres_t       sch0wpres;

    scedmachnl_axim  #(
        .PM_AXID   (AXID+1    ),
        .AW        (AW        ),
        .DW        (DW        ),
        .FFCNT     (FFCNT     ),
        .BA        (BA        ),
        .SEGCNT    (SEGCNT    ),
        .SEGCFGS   (SEGCFGS   ),
        .TRANSCNTW (TRANSCNTW )
    )axim_sec(
    /*    input logic                */ .clk            (clk               ),
    /*    input logic                */ .resetn         (resetn            ),
    /*    axiif.master               */ .axim           (axim[1]           ),
                                        .scemode        ,
    /*    output chnlreq_t           */ .rpreq          (sch0rpreq          ),
    /*    input  chnlres_t           */ .rpres          (sch0rpres          ),
    /*    output chnlreq_t           */ .wpreq          (sch0wpreq          ),
    /*    input  chnlres_t           */ .wpres          (sch0wpres          ),
    /*    input   bit                */ .start          (schstart0         ),
    /*    output  bit                */ .busy           (schbusy           ),
    /*    output  bit                */ .done           (schdone           ),
    /*    input   bit [0:FFCNT-1]    */ .segfifoen      (segfifoen0        ),
    /*    input   bit                */ .cr_func        (schcr0.func       ),
    /*    input   bit [9:0]          */ .cr_opt         (schcr0.opt        ),
    /*    input   bit [31:0]         */ .cr_axaddrstart (schcr0.axstart    ),
    /*    input   adr_t              */ .cr_segid       (schcr0.segid      ),
    /*    input   adr_t              */ .cr_segptrstart (schcr0.segstart   ),
    /*    input   bit[TRANSCNTW-1:0] */ .cr_transize    (schcr0.transize   ),
                                        .wdatabypass_mode (wdatabypass_mode[1]),
                                        .wdatabypass_data,
    /*    output bit [7:0]           */ .intr           (schcr_intr        ),
    /*    output bit [7:0]           */ .err            (schcr_err         )
    );

    assign schstart0       =  schcrxsel ? schstartx       : schstart       ;
    assign segfifoen0      =  schcrxsel ? '0              : segfifoen      ;
    assign schcr0          =  schcrxsel ? schcrx          : schcr          ;

    assign schrpreq  =  schcrxsel ? scedma_pkg::CHNLREP_NULL : sch0rpreq;
    assign schwpreq  =  schcrxsel ? scedma_pkg::CHNLREP_NULL : sch0wpreq;
    assign schxrpreq = ~schcrxsel ? scedma_pkg::CHNLREP_NULL : sch0rpreq;
    assign schxwpreq = ~schcrxsel ? scedma_pkg::CHNLREP_NULL : sch0wpreq;
    assign sch0rpres  = schcrxsel ? schxrpres : schrpres;
    assign sch0wpres  = schcrxsel ? schxwpres : schwpres;


    scedmachnl_axim  #(
        .PM_AXID   (AXID           ),
        .AW        (AW        ),
        .DW        (DW        ),
        .FFCNT     (FFCNT     ),
        .BA        (BA        ),
        .SEGCNT    (SEGCNT    ),
        .SEGCFGS   (SEGCFGS   ),
        .TRANSCNTW (TRANSCNTW )
    )axim_gnl(
    /*    input logic                */ .clk            (clk               ),
    /*    input logic                */ .resetn         (resetn            ),
    /*    axiif.master               */ .axim           (axim[0]           ),
                                        .scemode        (scemode&2'h1),   // no mode_sec
    /*    output chnlreq_t           */ .rpreq          (xchrpreq          ),
    /*    input  chnlres_t           */ .rpres          (xchrpres          ),
    /*    output chnlreq_t           */ .wpreq          (xchwpreq          ),
    /*    input  chnlres_t           */ .wpres          (xchwpres          ),
    /*    input   bit                */ .start          (xchstart          ),
    /*    output  bit                */ .busy           (xchbusy           ),
    /*    output  bit                */ .done           (xchdone           ),
    /*    input   bit [0:FFCNT-1]    */ .segfifoen      (segfifoen         ),
    /*    input   bit                */ .cr_func        (xchcr.func        ),
    /*    input   bit [9:0]          */ .cr_opt         (xchcr.opt         ),
    /*    input   bit [31:0]         */ .cr_axaddrstart (xchcr.axstart     ),
    /*    input   adr_t              */ .cr_segid       (xchcr.segid       ),
    /*    input   adr_t              */ .cr_segptrstart (xchcr.segstart    ),
    /*    input   bit[TRANSCNTW-1:0] */ .cr_transize    (xchcr.transize    ),
                                        .wdatabypass_mode (wdatabypass_mode[0]),
                                        .wdatabypass_data,
    /*    output bit [7:0]           */ .intr           (xchcr_intr        ),
    /*    output bit [7:0]           */ .err            (xchcr_err         )
    );

    logic [7:0] ich_wpffid;
    segcfg_t ichrpsegcfg, ichrpsegcfgreg;
    segcfg_t ichwpsegcfg, ichwpsegcfgreg;
    chnlcfg_t ichthecfg;

    assign ichrpsegcfg = SEGCFGS[ichcr_rpsegid];
    assign ichwpsegcfg = SEGCFGS[ichcr_wpsegid];
    `theregrn( ichrpsegcfgreg ) <= ichrpsegcfg;
    `theregrn( ichwpsegcfgreg ) <= ichwpsegcfg;
    assign ich_wpffid = ichwpsegcfgreg.fifoid;

    assign ichthecfg.chnlid = 'd1;
    assign ichthecfg.rpsegcfg = ichrpsegcfgreg;
    assign ichthecfg.wpsegcfg = ichwpsegcfgreg;
    assign ichthecfg.rpptr_start = ichcr_rpstart;
    assign ichthecfg.wpptr_start = ichcr_wpstart;
    assign ichthecfg.wpffen = segfifoen[ich_wpffid];// & ichwpsegcfgreg.isfifo;
    assign ichthecfg.transsize = ichcr_transize;
    assign ichthecfg.opt_ltx = ichcr_opt_ltx  | '0;
    assign ichthecfg.opt_xor = ichcr_opt_xor;
    assign ichthecfg.opt_cmpp = '0;
    assign ichthecfg.opt_prm = '0;

    scedma_chnl  #(.TCW(TRANSCNTW),.DW(DW))chix(
        .clk,
        .resetn,
        .thecfg   (ichthecfg),
        .start    (ichstart),
        .busy     (ichbusy),
        .done     (ichdone),
        .rpreq    (ichrpreq ),
        .rpres    (ichrpres ),
        .wpreq    (ichwpreq ),
        .wpres    (ichwpres ),
        .intr     (ichcr_intr )
    );

endmodule

module dummytb_sce_dma ();
    parameter AXID = 'h5;
    parameter AW = scedma_pkg::AW;
    parameter DW = scedma_pkg::DW;
    parameter FFCNT = scedma_pkg::FFCNT;
    parameter adr_t BA = 0;
    parameter SEGCNT  = scedma_pkg::SEGCNT;
    parameter segcfg_t [0:SEGCNT-1] SEGCFGS = scedma_pkg::SEGCFGS;
    parameter TRANSCNTW = 16;
    bit            schcrxsel, schstartx;
    chcr_t         schcrx;
    chnlreq_t       schxrpreq;
    chnlres_t       schxrpres;
    chnlreq_t       schxwpreq;
    chnlres_t       schxwpres;
    bit [1:0]       scemode;

    logic clk;
    logic resetn;
    chnlreq_t       xchrpreq;
    chnlres_t       xchrpres;
    chnlreq_t       xchwpreq;
    chnlres_t       xchwpres;
    chnlreq_t       schrpreq;
    chnlres_t       schrpres;
    chnlreq_t       schwpreq;
    chnlres_t       schwpres;
    chnlreq_t       ichrpreq;
    chnlres_t       ichrpres;
    chnlreq_t       ichwpreq;
    chnlres_t       ichwpres;
    bit [0:FFCNT-1] segfifoen;
    bit[2:0]           sr_sdma;
    bit[2:0]           fr_sdma;
    bit [7:0]       intr;
    bit [7:0]       err;

    apbif #(.PAW(12),.DW(32)) apbs();
    apbif apbx();
    axiif axim[0:1]();

    scedma u0(.*);

endmodule
