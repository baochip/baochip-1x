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

module vexsys #(
        parameter bit[3:0] AXIIID4 = 4'h3,
        parameter bit[3:0] AXIDID4 = 4'h4,
        parameter bit[3:0] AHBPID4 = 4'hD,

        parameter PM_COREUSERCNT = 8,
        parameter IRQNUM = 256
    )(
// system ctrl
    input   logic               clk,            // Free running clock
    input   logic               resetn,
    input   logic               ahbpclken,

// test mode
    input   logic               cmsatpg,
    input   logic               cmsbist,
    rbif.slavedp rbif_rdram1kx32     [0:5]  ,
    rbif.slavedp rbif_rdram512x64    [0:3]  ,
    rbif.slavedp rbif_rdram128x22    [0:7]  ,
    rbif.slavedp rbif_rdram32x16     [0:1]  ,


// cfg
    input   logic               vexcfg_en,
    input   logic               vexcfg_dev,
    input   logic [31:0]        vexcfg_iv,// = 32'h6000_0000;
    input   logic [2:0]         vexsramtrm,
    input   logic [1:0]         default_user,
    input   logic               default_mm,

// interrupt, nmi, events
    input   logic [IRQNUM-1:0]  vex_irq,

// amba
    axiif.master                iaxim,
    axiif.master                daxim,
    ahbif.master                ahbp,

// coreuser
//    input   axi_pkg::xbar_rule_32_t [0:PM_COREUSERCNT-1]       coreusermap,
    output  logic [PM_COREUSERCNT-1:0]  coreuser,
    output  logic                       machinemode,


// mbox
    input  wire   [31:0] mbox_w_dat,
    input  wire          mbox_w_valid,
    output wire          mbox_w_ready,
    input  wire          mbox_w_done,
    output wire   [31:0] mbox_r_dat,
    output wire          mbox_r_valid,
    input  wire          mbox_r_ready,
    output wire          mbox_r_done,
    input  wire          mbox_w_abort,
    output wire          mbox_r_abort,

// debug
    jtagif.slave jtags

);

    logic [15:0][15:0] irq16;
    logic       wfi_active, clkvex;
    logic       clkvexen, clkvexenreg;
    logic       resetn_vex;

    axiif #(.AW(32),.DW(32),.IDW(8),.LENW(8),.UW(8)) paxim();
    ahbif #(.AW(32),.DW(32)) ahbp0();
//    ahbif #(.AW(32),.DW(32)) ahbp1();

    axi_ahb_bdg #(.DW(32)) paxim2ahbp0(
        .clk,
        .resetn(resetn_vex),
        .axislave(paxim),
        .ahbmaster(ahbp0)
        );

    ahb_sync#(
            .SYNCDOWN (1),
            .SYNCUP   (0),
            .MW       (4)
        ) ahbp_syncdown (
            .hclk       (clk        ),
            .resetn     (resetn_vex ),
            .hclken     (ahbpclken  ),
            .ahbslave   (ahbp0      ),
            .ahbmaster  (ahbp       )
        );
/*
    ahb_sync#(
            .SYNCDOWN (0),
            .SYNCUP   (0),
            .MW       (4)
        ) ahbp_sync (
            .hclk       (clk        ),
            .resetn     (resetn     ),
            .hclken     ('1  ),
            .ahbslave   (ahbp0      ),
            .ahbmaster  (ahbp1      )
        );
*/
    assign iaxim.awsparse = 1'b1;
    assign daxim.awsparse = 1'b1;


    `theregsn( clkvexenreg ) <= '0;
    assign clkvexen = vexcfg_en & ~wfi_active | clkvexenreg;
    ICG icg(.CK(clk),.EN(clkvexen),.SE(cmsatpg),.CKG(clkvex));
    assign resetn_vex  = cmsatpg ? 1'b1 : resetn  & vexcfg_en;

    logic clkjtag0, clkjtag1;
    logic clkjtag0en, clkjtag1en;
    logic [2:0] clkjtag1enregs;
    logic jtagtck;
    logic jtagtck0;
    logic jtagstrst;
    logic jtags_tck;

    assign jtagtck0 = jtags.tck & vexcfg_dev;

    assign clkjtag0en = clkvexenreg;
    assign jtags_tck = cmsatpg ? clk : jtags.tck;
    `theregfull( jtags_tck, resetn_vex, clkjtag1enregs, '0 ) <= { clkjtag1enregs, 1'b1 };
    assign clkjtag1en = clkjtag1enregs[2];
    ICG icgj0(.CK(clk),.EN(clkjtag0en),.SE(cmsatpg),.CKG(clkjtag0));
    ICG icgj1(.CK(jtagtck0),.EN(clkjtag1en),.SE(cmsatpg),.CKG(clkjtag1));

//    assign jtagstrst = cmsatpg ? 1'b1 : jtags.trst & resetn_vex;
    assign jtagstrst = cmsatpg ? resetn : jtags.trst;

`ifdef FPGA
     BUFG bufg_jtagtck(.I(clkjtag0 | clkjtag1), .O(jtagtck));
 //    assign jtagtck = clkjtag0 | clkjtag1;
`else
    logic jtagtck_unbuf;
    assign jtagtck_unbuf =  cmsatpg ? clk : clkjtag0 | clkjtag1 ;
    CLKCELL_BUF buf_jtck(.A(jtagtck_unbuf),.Z(jtagtck));
`endif

    assign paxim.arid = '0;//AHBPID4*16;
    assign paxim.arburst = '0;
    assign paxim.arlen = '0;
    assign paxim.arsize = '0;
    assign paxim.arlock = '0;
    assign paxim.arcache = '0;
    assign paxim.armaster = '0;
    assign paxim.arinner = '0;
    assign paxim.arshare = '0;
    assign paxim.aruser = AHBPID4 | '0;

    assign paxim.awid = '0;//AHBPID4*16;
    assign paxim.awburst = '0;
    assign paxim.awlen = '0;
    assign paxim.awsize = '0;
    assign paxim.awlock = '0;
    assign paxim.awcache = '0;
    assign paxim.awmaster = '0;
    assign paxim.awinner = '0;
    assign paxim.awshare = '0;
    assign paxim.awsparse = '1;
    assign paxim.awuser = AHBPID4 | '0;

    assign paxim.wid = '0;
    assign paxim.wlast = '1;
    assign paxim.wuser = '0;

    assign iaxim.awid[7:1]  = '0;
    assign iaxim.arid[7:1]  = '0;
    assign daxim.awid[7:1]  = '0;
    assign daxim.arid[7:1]  = '0;
    assign iaxim.wid[7:0]   = '0;
    assign daxim.wid[7:0]   = '0;

    assign iaxim.awuser[7:0]  = AXIIID4 | '0;
    assign iaxim.aruser[7:0]  = AXIIID4 | '0;
    assign daxim.awuser[7:0]  = AXIDID4 | '0;
    assign daxim.aruser[7:0]  = AXIDID4 | '0;

    assign iaxim.awvalid = '0;
    assign iaxim.awaddr = '0;
    assign iaxim.awid[0] = '0;
    assign iaxim.awburst = '0;
    assign iaxim.awlen = '0;
    assign iaxim.awsize = '0;
    assign iaxim.awlock = '0;
    assign iaxim.awcache = '0;
    assign iaxim.awprot = '0;
    assign iaxim.awmaster = '0;
    assign iaxim.awinner = '0;
    assign iaxim.awshare = '0;
//    assign iaxim.awsparse = '0;

    assign iaxim.wvalid = '0;
//    assign iaxim.wid = '0;
    assign iaxim.wlast = '0;
    assign iaxim.wstrb = '0;
    assign iaxim.wdata = '0;
    assign iaxim.wuser = '0;
    
    assign daxim.wuser[7:1]  = '0;

    assign iaxim.bready = '1;

    logic [7:0] vexcoreuser; // bunnie: @Liza need to check MSB vs LSB bit ordering
    logic       vex_mm; // bunnie: @Liza need to connect
    logic [31:0] test; // no connect; used for test visibility in simulation

cram_axi vextop(
    .cmatpg(cmsatpg),
    .cmbist(cmsbist),
//    .rbif_rdram1kx32  ,
//    .rbif_rdram512x64 ,
//    .rbif_rdram128x22 ,
//    .rbif_rdram32x16  ,
    /* input  wire          */ .aclk                ( clkvex ),
    /* input  wire          */ .rst                 ( ~resetn_vex ),
    /* input  wire          */ .always_on           ( clk ),
    /* input  wire   [31:0] */ .trimming_reset      ( vexcfg_iv ),
    /* input  wire          */ .trimming_reset_ena  ( 1'b1 ),
                                .vexsramtrm,
    /* output wire          */ .ibus_axi_awvalid    (  ),
    /* input  wire          */ .ibus_axi_awready    ( '1   ),
    /* output wire   [31:0] */ .ibus_axi_awaddr     (  ),
    /* output wire    [1:0] */ .ibus_axi_awburst    (  ),
    /* output wire    [7:0] */ .ibus_axi_awlen      (  ),
    /* output wire    [2:0] */ .ibus_axi_awsize     (  ),
    /* output wire          */ .ibus_axi_awlock     (  ),
    /* output wire    [2:0] */ .ibus_axi_awprot     (  ),
    /* output wire    [3:0] */ .ibus_axi_awcache    (  ),
    /* output wire    [3:0] */ .ibus_axi_awqos      (  ),
    /* output wire    [3:0] */ .ibus_axi_awregion   (  ),
    /* output wire          */ .ibus_axi_awid       (  ),
    /* output wire          */ .ibus_axi_awuser     (  ),
    /* output wire          */ .ibus_axi_wvalid     (  ),
    /* input  wire          */ .ibus_axi_wready     ( '1    ),
    /* output wire          */ .ibus_axi_wlast      (  ),
    /* output wire   [63:0] */ .ibus_axi_wdata      (  ),
    /* output wire    [7:0] */ .ibus_axi_wstrb      (  ),
    /* output wire          */ .ibus_axi_wuser      (  ),
    /* input  wire          */ .ibus_axi_bvalid     ( '0 ),
    /* output wire          */ .ibus_axi_bready     (  ),
    /* input  wire    [1:0] */ .ibus_axi_bresp      ( '0 ),
    /* input  wire          */ .ibus_axi_bid        ( '0 ),
    /* input  wire          */ .ibus_axi_buser      ( '0 ),
    /* output wire          */ .ibus_axi_arvalid    ( iaxim.arvalid   ),
    /* input  wire          */ .ibus_axi_arready    ( iaxim.arready   ),
    /* output wire   [31:0] */ .ibus_axi_araddr     ( iaxim.araddr    ),
    /* output wire    [1:0] */ .ibus_axi_arburst    ( iaxim.arburst   ),
    /* output wire    [7:0] */ .ibus_axi_arlen      ( iaxim.arlen     ),
    /* output wire    [2:0] */ .ibus_axi_arsize     ( iaxim.arsize    ),
    /* output wire          */ .ibus_axi_arlock     ( iaxim.arlock    ),
    /* output wire    [2:0] */ .ibus_axi_arprot     ( iaxim.arprot    ),
    /* output wire    [3:0] */ .ibus_axi_arcache    ( iaxim.arcache   ),
    /* output wire    [3:0] */ .ibus_axi_arqos      (  ),
    /* output wire    [3:0] */ .ibus_axi_arregion   (  ),
    /* output wire          */ .ibus_axi_arid       ( iaxim.arid[0]      ),
    /* output wire          */ .ibus_axi_aruser     (     ),
    /* input  wire          */ .ibus_axi_rvalid     ( iaxim.rvalid    ),
    /* output wire          */ .ibus_axi_rready     ( iaxim.rready    ),
    /* input  wire          */ .ibus_axi_rlast      ( iaxim.rlast     ),
    /* input  wire    [1:0] */ .ibus_axi_rresp      ( iaxim.rresp     ),
    /* input  wire   [63:0] */ .ibus_axi_rdata      ( iaxim.rdata     ),
    /* input  wire          */ .ibus_axi_rid        ( iaxim.rid[0]       ),
    /* input  wire          */ .ibus_axi_ruser      ( iaxim.ruser[0]     ),

    /* output wire          */ .dbus_axi_awvalid    ( daxim.awvalid   ),
    /* input  wire          */ .dbus_axi_awready    ( daxim.awready   ),
    /* output wire   [31:0] */ .dbus_axi_awaddr     ( daxim.awaddr    ),
    /* output wire    [1:0] */ .dbus_axi_awburst    ( daxim.awburst   ),
    /* output wire    [7:0] */ .dbus_axi_awlen      ( daxim.awlen     ),
    /* output wire    [2:0] */ .dbus_axi_awsize     ( daxim.awsize    ),
    /* output wire          */ .dbus_axi_awlock     ( daxim.awlock    ),
    /* output wire    [2:0] */ .dbus_axi_awprot     ( daxim.awprot    ),
    /* output wire    [3:0] */ .dbus_axi_awcache    ( daxim.awcache   ),
    /* output wire    [3:0] */ .dbus_axi_awqos      (  ),
    /* output wire    [3:0] */ .dbus_axi_awregion   (  ),
    /* output wire          */ .dbus_axi_awid       ( daxim.awid[0]      ),
    /* output wire          */ .dbus_axi_awuser     (     ),
    /* output wire          */ .dbus_axi_wvalid     ( daxim.wvalid    ),
    /* input  wire          */ .dbus_axi_wready     ( daxim.wready    ),
    /* output wire          */ .dbus_axi_wlast      ( daxim.wlast     ),
    /* output wire   [31:0] */ .dbus_axi_wdata      ( daxim.wdata     ),
    /* output wire    [3:0] */ .dbus_axi_wstrb      ( daxim.wstrb     ),
    /* output wire          */ .dbus_axi_wuser      ( daxim.wuser[0]     ),
    /* input  wire          */ .dbus_axi_bvalid     ( daxim.bvalid    ),
    /* output wire          */ .dbus_axi_bready     ( daxim.bready    ),
    /* input  wire    [1:0] */ .dbus_axi_bresp      ( daxim.bresp     ),
    /* input  wire          */ .dbus_axi_bid        ( daxim.bid[0]       ),
    /* input  wire          */ .dbus_axi_buser      ( daxim.buser[0]     ),
    /* output wire          */ .dbus_axi_arvalid    ( daxim.arvalid   ),
    /* input  wire          */ .dbus_axi_arready    ( daxim.arready   ),
    /* output wire   [31:0] */ .dbus_axi_araddr     ( daxim.araddr    ),
    /* output wire    [1:0] */ .dbus_axi_arburst    ( daxim.arburst   ),
    /* output wire    [7:0] */ .dbus_axi_arlen      ( daxim.arlen     ),
    /* output wire    [2:0] */ .dbus_axi_arsize     ( daxim.arsize    ),
    /* output wire          */ .dbus_axi_arlock     ( daxim.arlock    ),
    /* output wire    [2:0] */ .dbus_axi_arprot     ( daxim.arprot    ),
    /* output wire    [3:0] */ .dbus_axi_arcache    ( daxim.arcache   ),
    /* output wire    [3:0] */ .dbus_axi_arqos      (  ),
    /* output wire    [3:0] */ .dbus_axi_arregion   (  ),
    /* output wire          */ .dbus_axi_arid       ( daxim.arid[0]      ),
    /* output wire          */ .dbus_axi_aruser     (     ),
    /* input  wire          */ .dbus_axi_rvalid     ( daxim.rvalid    ),
    /* output wire          */ .dbus_axi_rready     ( daxim.rready    ),
    /* input  wire          */ .dbus_axi_rlast      ( daxim.rlast     ),
    /* input  wire    [1:0] */ .dbus_axi_rresp      ( daxim.rresp     ),
    /* input  wire   [31:0] */ .dbus_axi_rdata      ( daxim.rdata     ),
    /* input  wire          */ .dbus_axi_rid        ( daxim.rid[0]       ),
    /* input  wire          */ .dbus_axi_ruser      ( daxim.ruser[0]     ),
    /* output reg           */ .p_axi_awvalid       ( paxim.awvalid    ),
    /* input  wire          */ .p_axi_awready       ( paxim.awready    ),
    /* output reg    [31:0] */ .p_axi_awaddr        ( paxim.awaddr     ),
    /* output reg     [2:0] */ .p_axi_awprot        ( paxim.awprot     ),
    /* output reg           */ .p_axi_wvalid        ( paxim.wvalid     ),
    /* input  wire          */ .p_axi_wready        ( paxim.wready     ),
    /* output reg    [31:0] */ .p_axi_wdata         ( paxim.wdata      ),
    /* output reg     [3:0] */ .p_axi_wstrb         ( paxim.wstrb      ),
    /* input  wire          */ .p_axi_bvalid        ( paxim.bvalid     ),
    /* output reg           */ .p_axi_bready        ( paxim.bready     ),
    /* input  wire    [1:0] */ .p_axi_bresp         ( paxim.bresp      ),
    /* output reg           */ .p_axi_arvalid       ( paxim.arvalid    ),
    /* input  wire          */ .p_axi_arready       ( paxim.arready    ),
    /* output reg    [31:0] */ .p_axi_araddr        ( paxim.araddr     ),
    /* output reg     [2:0] */ .p_axi_arprot        ( paxim.arprot     ),
    /* input  wire          */ .p_axi_rvalid        ( paxim.rvalid     ),
    /* output reg           */ .p_axi_rready        ( paxim.rready     ),
    /* input  wire    [1:0] */ .p_axi_rresp         ( paxim.rresp      ),
    /* input  wire   [31:0] */ .p_axi_rdata         ( paxim.rdata      ),

    /* input  wire          */ .jtag_tdi            ( jtags.tdi     &  vexcfg_dev   ),
    /* output wire          */ .jtag_tdo            ( jtags.tdo                     ),
    /* input  wire          */ .jtag_tms            ( jtags.tms     &  vexcfg_dev   ),
    /* input  wire          */ .jtag_tck            ( jtagtck   ),
//    /* input  wire          */ .jtag_trst           ( ( jtags.trst & resetn )  | ~vexcfg_dev   ),
    /* input  wire          */ .jtag_trst_n         ( jtagstrst   ),

    /* output reg           */ .coreuser_vex        ( vexcoreuser),
    /* output reg           */ .vex_mm              ( vex_mm ),
//    /* output wire          */ .wfi_active          ( wfi_active ),
                               .sleep_req          (wfi_active),

    /* input  wire   [19:0] */ .irqarray_bank0     ( 16'h0 | irq16[0 ] ),
    /* input  wire   [19:0] */ .irqarray_bank1     ( 16'h0 | irq16[1 ] ),
    /* input  wire   [19:0] */ .irqarray_bank2     ( 16'h0 | irq16[2 ] ),
    /* input  wire   [19:0] */ .irqarray_bank3     ( 16'h0 | irq16[3 ] ),
    /* input  wire   [19:0] */ .irqarray_bank4     ( 16'h0 | irq16[4 ] ),
    /* input  wire   [19:0] */ .irqarray_bank5     ( 16'h0 | irq16[5 ] ),
    /* input  wire   [19:0] */ .irqarray_bank6     ( 16'h0 | irq16[6 ] ),
    /* input  wire   [19:0] */ .irqarray_bank7     ( 16'h0 | irq16[7 ] ),
    /* input  wire   [19:0] */ .irqarray_bank8     ( 16'h0 | irq16[8 ] ),
    /* input  wire   [19:0] */ .irqarray_bank9     ( 16'h0 | irq16[9 ] ),
    /* input  wire   [19:0] */ .irqarray_bank10    ( 16'h0 | irq16[10] ),
    /* input  wire   [19:0] */ .irqarray_bank11    ( 16'h0 | irq16[11] ),
    /* input  wire   [19:0] */ .irqarray_bank12    ( 16'h0 | irq16[12] ),
    /* input  wire   [19:0] */ .irqarray_bank13    ( 16'h0 | irq16[13] ),
    /* input  wire   [19:0] */ .irqarray_bank14    ( 16'h0 | irq16[14] ),
    /* input  wire   [19:0] */ .irqarray_bank15    ( 16'h0 | irq16[15] ),
    /* input  wire   [19:0] */ .irqarray_bank16    ( 16'h0  ),
    /* input  wire   [19:0] */ .irqarray_bank17    ( 16'h0  ),
    /* input  wire   [19:0] */ .irqarray_bank18    ( 16'h0  ),
    /* input  wire   [19:0] */ .irqarray_bank19    ( 16'h0  ),
    .mbox_w_dat,
    .mbox_w_valid,
    .mbox_w_ready,
    .mbox_w_done,
    .mbox_r_dat,
    .mbox_r_valid,
    .mbox_r_ready,
    .mbox_r_done,
    .mbox_w_abort,
    .mbox_r_abort,
    .default_user,      // default to boot0  LIZA: please wire up to IFR
    .default_mm,        // default to machine mode  LIZA: If needed, wire up to IFR or set to correct fixed default
    /* output wire [31:0] */ .test(test),
    .*
);

    assign coreuser =  vexcoreuser; // bunnie: cram_axi generates coreuser already at bits 4:7, bits 3:0 are 0.
    assign machinemode = vex_mm;
    assign irq16[0 ] = vex_irq[ 16*0 +15 : 16*0  ];
    assign irq16[1 ] = vex_irq[ 16*1 +15 : 16*1  ];
    assign irq16[2 ] = vex_irq[ 16*2 +15 : 16*2  ];
    assign irq16[3 ] = vex_irq[ 16*3 +15 : 16*3  ];
    assign irq16[4 ] = vex_irq[ 16*4 +15 : 16*4  ];
    assign irq16[5 ] = vex_irq[ 16*5 +15 : 16*5  ];
    assign irq16[6 ] = vex_irq[ 16*6 +15 : 16*6  ];
    assign irq16[7 ] = vex_irq[ 16*7 +15 : 16*7  ];
    assign irq16[8 ] = vex_irq[ 16*8 +15 : 16*8  ];
    assign irq16[9 ] = vex_irq[ 16*9 +15 : 16*9  ];
    assign irq16[10] = vex_irq[ 16*10+15 : 16*10 ];
    assign irq16[11] = vex_irq[ 16*11+15 : 16*11 ];
    assign irq16[12] = vex_irq[ 16*12+15 : 16*12 ];
    assign irq16[13] = vex_irq[ 16*13+15 : 16*13 ];
    assign irq16[14] = vex_irq[ 16*14+15 : 16*14 ];
    assign irq16[15] = vex_irq[ 16*15+15 : 16*15 ];

endmodule : vexsys

module dummytb_vexsys ();

        parameter PM_COREUSERCNT = 8;
        parameter IRQNUM = 256;

    logic               clk;
    logic               resetn;
    logic               ahbpclken;
    logic               cmsatpg;
    logic               cmsbist;
    logic               vexcfg_en;
    logic               vexcfg_dev;
    logic [31:0]        vexcfg_iv;
    logic [IRQNUM-1:0]  vex_irq;
    logic [PM_COREUSERCNT-1:0]       coreuser;
    logic               machinemode;
    logic [1:0]         default_user;
    logic               default_mm;
    axiif #(.DW(64))               iaxim();
    axiif #(.DW(32))               daxim();
    ahbif #(.DW(32))               ahbp();
//    input   axi_pkg::xbar_rule_32_t [0:PM_COREUSERCNT-1]       coreusermap;
    jtagif jtags();
    logic   [31:0] mbox_w_dat;
    logic          mbox_w_valid;
    logic          mbox_w_ready;
    logic          mbox_w_done;
    logic   [31:0] mbox_r_dat;
    logic          mbox_r_valid;
    logic          mbox_r_ready;
    logic          mbox_r_done;
    logic          mbox_w_abort;
    logic          mbox_r_abort;
    logic   [2:0]  vexsramtrm;
    rbif #(.AW(10   ),      .DW(32))    rbif_rdram1kx32     [0:5]   ();
    rbif #(.AW(9    ),      .DW(64))    rbif_rdram512x64    [0:3]   ();
    rbif #(.AW(7    ),      .DW(22))    rbif_rdram128x22    [0:7]   ();
    rbif #(.AW(5    ),      .DW(16))    rbif_rdram32x16     [0:1]   ();
    vexsys u0(.*);

endmodule
