module soc_sce #(
    parameter AHW = 32,  // AHB address width
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

    output  [31:0] hrdata,
    output  hready,
    output  hresp,

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