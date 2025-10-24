module soc_sce #(
    parameter AHW = 32,  // AHB address width
    parameter AW = 32,
    parameter DW = 32,
    parameter IDW = 4,
    parameter UW = 4
)(
    input ana_rng_0p1u,
    input clkpke,
    input clksce,
    input clktop,
    input clken,
    input resetn,
    input sysresetn,
    input scedevmode,
    input [7:0] coreuser,
    input [7:0] coreuser_vex,
    output [7:0] sceuser,
    output secmode,
    input [255:0] cfgsce,
    output [255:0] truststate,
    output iptorndlf,
    output iptorndhf,
    input [6:0] ipt_rngcfg,

    input  hsel,
    input  [31:0] haddr,
    input  [1:0] htrans,
    input  hwrite,
    input  [2:0] hsize,
    input  [2:0] hburst,
    input  [3:0] hprot,
    input  [3:0] hmaster,
    input  [31:0] hwdata,
    input  hmasterlock,
    input  hreadyin,

    input  [3:0] hauser,
    output [31:0] hrdata,
    output hready,
    output hresp,

    // == channel 0
    output   logic            axi0_awvalid,
    input    logic            axi0_awready,
    output   logic [IDW-1:0]  axi0_awid,
    output   logic [AW-1:0]   axi0_awaddr,
    output   logic [2:0]      axi0_awsize,
    output   logic [2:0]      axi0_awprot,
    output   logic [7:0]      axi0_awlen,
    output   logic [1:0]      axi0_awburst,

    output   logic            axi0_wvalid,
    input    logic            axi0_wready,
    output   logic [DW-1:0]   axi0_wdata,
    output   logic [DW/8-1:0] axi0_wstrb,
    output   logic            axi0_wlast,

    input    logic            axi0_bvalid,
    output   logic            axi0_bready,
    input    logic [1:0]      axi0_bresp,
    input    logic [IDW-1:0]  axi0_bid,
    // AXI   Read Channel,
    output   logic            axi0_arvalid,
    input    logic            axi0_arready,
    output   logic [IDW-1:0]  axi0_arid,
    output   logic [AW-1:0]   axi0_araddr,
    output   logic [2:0]      axi0_arsize,
    output   logic [2:0]      axi0_arprot,
    output   logic [7:0]      axi0_arlen,
    output   logic [1:0]      axi0_arburst,

    input    logic            axi0_rvalid,
    output   logic            axi0_rready,
    input    logic [IDW-1:0]  axi0_rid,
    input    logic [DW-1:0]   axi0_rdata,
    input    logic [1:0]      axi0_rresp,

    // == channel 1
    output   logic            axi1_awvalid,
    input    logic            axi1_awready,
    output   logic [IDW-1:0]  axi1_awid,
    output   logic [AW-1:0]   axi1_awaddr,
    output   logic [2:0]      axi1_awsize,
    output   logic [2:0]      axi1_awprot,
    output   logic [7:0]      axi1_awlen,
    output   logic [1:0]      axi1_awburst,

    output   logic            axi1_wvalid,
    input    logic            axi1_wready,
    output   logic [DW-1:0]   axi1_wdata,
    output   logic [DW/8-1:0] axi1_wstrb,
    output   logic            axi1_wlast,

    input    logic            axi1_bvalid,
    output   logic            axi1_bready,
    input    logic [1:0]      axi1_bresp,
    input    logic [IDW-1:0]  axi1_bid,
    // AXI   Read Channel,
    output   logic            axi1_arvalid,
    input    logic            axi1_arready,
    output   logic [IDW-1:0]  axi1_arid,
    output   logic [AW-1:0]   axi1_araddr,
    output   logic [2:0]      axi1_arsize,
    output   logic [2:0]      axi1_arprot,
    output   logic [7:0]      axi1_arlen,
    output   logic [1:0]      axi1_arburst,

    input    logic            axi1_rvalid,
    output   logic            axi1_rready,
    input    logic [IDW-1:0]  axi1_rid,
    input    logic [DW-1:0]   axi1_rdata,
    input    logic [1:0]      axi1_rresp,

    output [7:0] sceintr,
    output [7:0] sceerrs
);
// security crypto engine

    ahbif  #(.AW(AHW),.DW(DW),.IDW(IDW),.UW(UW)) ahbs;
    ahb_wire2ifm ahb_wire2ifm (
        .ahbmaster(ahbs),
        .hsel(hsel),
        .haddr(haddr),
        .htrans(htrans),
        .hwrite(hwrite),
        .hsize(hsize),
        .hburst(hburst),
        .hprot(hprot),
        .hmaster(hmaster),
        .hwdata(hwdata),
        .hmasterlock(hmasterlock),
        .hreadym('1), // not sure if this is correct
        .hrdata(hrdata),
        .hready(hready),
        .hauser(hauser),
        .hresp(hresp)
    );

    ahbif sceahbif();
    ahb_thru sceifs ( .ahbslave(ahbs), .ahbmaster( sceahbif ));
    axiif #(.AW(32),.DW(32),.IDW(5),.LENW(8),.UW(8)) sce_axi32[0:1]();

    rbif #(.AW(12   ),      .DW(36))    rbif_sce_sceram_10k [0:0]   ();
    rbif #(.AW(10   ),      .DW(36))    rbif_sce_hashram_3k [0:0]   ();
    rbif #(.AW(8    ),      .DW(36))    rbif_sce_aesram_1k  [0:0]   ();
    rbif #(.AW(9    ),      .DW(72))    rbif_sce_pkeram_4k  [0:1]   ();
    rbif #(.AW(10   ),      .DW(36))    rbif_sce_aluram_3k  [0:1]   ();
    rbif #(.AW(8    ),      .DW(72))    rbif_sce_mimmdpram  [0:0]   ();

    // == channel 0
    assign   axi0_awvalid = sce_axi32[0].awvalid;
    assign   sce_axi32[0].awready = axi0_awready;
    assign   axi0_awid = sce_axi32[0].awid;
    assign   axi0_awaddr = sce_axi32[0].awaddr;
    assign   axi0_awsize = sce_axi32[0].awsize;
    assign   axi0_awprot = sce_axi32[0].awprot;
    assign   axi0_awlen = sce_axi32[0].awlen;
    assign   axi0_awburst = sce_axi32[0].awburst;

    assign   axi0_wvalid = sce_axi32[0].wvalid;
    assign   sce_axi32[0].wready = axi0_wready;
    assign   axi0_wdata = sce_axi32[0].wdata;
    assign   axi0_wstrb = sce_axi32[0].wstrb;
    assign   axi0_wlast = sce_axi32[0].wlast;

    assign   sce_axi32[0].bvalid = axi0_bvalid;
    assign   axi0_bready = sce_axi32[0].bready;
    assign   sce_axi32[0].bresp = axi0_bresp;
    assign   sce_axi32[0].bid = axi0_bid;

    assign   axi0_arvalid = sce_axi32[0].arvalid;
    assign   sce_axi32[0].arready = axi0_arready;
    assign   axi0_arid = sce_axi32[0].arid;
    assign   axi0_araddr = sce_axi32[0].araddr;
    assign   axi0_arsize = sce_axi32[0].arsize;
    assign   axi0_arprot = sce_axi32[0].arprot;
    assign   axi0_arlen = sce_axi32[0].arlen;
    assign   axi0_arburst = sce_axi32[0].arburst;
    assign   sce_axi32[0].rvalid = axi0_rvalid;
    assign   axi0_rready = sce_axi32[0].rready;
    assign   sce_axi32[0].rid = axi0_rid;
    assign   sce_axi32[0].rdata = axi0_rdata;
    assign   sce_axi32[0].rresp = axi0_rresp;

    // == channel 1
    assign   axi1_awvalid = sce_axi32[1].awvalid;
    assign   sce_axi32[1].awready = axi1_awready;
    assign   axi1_awid = sce_axi32[1].awid;
    assign   axi1_awaddr = sce_axi32[1].awaddr;
    assign   axi1_awsize = sce_axi32[1].awsize;
    assign   axi1_awprot = sce_axi32[1].awprot;
    assign   axi1_awlen = sce_axi32[1].awlen;
    assign   axi1_awburst = sce_axi32[1].awburst;

    assign   axi1_wvalid = sce_axi32[1].wvalid;
    assign   sce_axi32[1].wready = axi1_wready;
    assign   axi1_wdata = sce_axi32[1].wdata;
    assign   axi1_wstrb = sce_axi32[1].wstrb;
    assign   axi1_wlast = sce_axi32[1].wlast;

    assign   sce_axi32[1].bvalid = axi1_bvalid;
    assign   axi1_bready = sce_axi32[1].bready;
    assign   sce_axi32[1].bresp = axi1_bresp;
    assign   sce_axi32[1].bid = axi1_bid;

    assign   axi1_arvalid = sce_axi32[1].arvalid;
    assign   sce_axi32[1].arready = axi1_arready;
    assign   axi1_arid = sce_axi32[1].arid;
    assign   axi1_araddr = sce_axi32[1].araddr;
    assign   axi1_arsize = sce_axi32[1].arsize;
    assign   axi1_arprot = sce_axi32[1].arprot;
    assign   axi1_arlen = sce_axi32[1].arlen;
    assign   axi1_arburst = sce_axi32[1].arburst;
    assign   sce_axi32[1].rvalid = axi1_rvalid;
    assign   axi1_rready = sce_axi32[1].rready;
    assign   sce_axi32[1].rid = axi1_rid;
    assign   sce_axi32[1].rdata = axi1_rdata;
    assign   sce_axi32[1].rresp = axi1_rresp;

    logic cmsatpg, cmsbist;
    assign cmsatpg = 0;
    assign cmsbist = 0;

    sce #(
        .AXID ( daric_cfg::AMBAID4_SCEA ),
        .COREUSERCNT ( 8 ),
        .INTC ( 8 ),
        .ERRC ( 8 ),
        .TSC(256)
    )sce(
        .ana_rng_0p1u(ana_rng_0p1u),
        .clk        (clksce),
        .clktop     (clktop),
        .clksceen   (clken),
        .clkpke   (clkpke),
        .resetn, .sysresetn,
        .cmsatpg, .cmsbist,
        .devmode             (scedevmode),
        .rbif_sce_sceram     (rbif_sce_sceram_10k[0] ),
        .rbif_sce_hashram    (rbif_sce_hashram_3k[0] ),
        .rbif_sce_aesram     (rbif_sce_aesram_1k[0]  ),
        .rbif_sce_pkeram     (rbif_sce_pkeram_4k  ),
        .rbif_sce_aluram     (rbif_sce_aluram_3k  ),
        .rbif_sce_mimmdpram  (rbif_sce_mimmdpram[0]  ),
        .coreuser_cm7   ( coreuser     ),
        .coreuser_vex   ( coreuser_vex ),
        .sceuser    ( sceuser  ),
        .secmode    ( secmode  ),
        .nvrcfg     ( cfgsce ),
        .truststate ( truststate ),
        .iptorndlf, .iptorndhf,
        .ipt_rngcfg ( ipt_rngcfg ),
        .ahbs       ( sceahbif ),
        .axim       ( sce_axi32 ),

        .intr       ( sceintr ),
        .err        ( sceerrs )
    );
endmodule