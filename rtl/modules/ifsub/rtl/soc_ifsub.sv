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

module soc_ifsub #(
    parameter IOC = 16*6,
    parameter EVCNT = 128,
    parameter ERRCNT = 1,
    parameter IRQCNT = daric_cfg::IRQCNT-16
)(
    input logic                 clk,
    input logic                 pclk,
    input logic                 pclken,
    input logic                 clk48m,
//    input logic                 clkao25m,
    input logic                 resetn,
    input logic                 perclk,
    input logic                 cmsatpg,
    input logic                 cmsbist,
    rbif.slave           rbif_bioram1kx32   [0:3],
    rbif.slave           rbif_ifram32kx36   [0:1],
    rbif.slavedp         rbif_udcmem_share  [0:0],
    rbif.slavedp         rbif_udcmem_odb    [0:0],
    rbif.slavedp         rbif_udcmem_256x64 [0:0],
    input logic                 clksys,
    input logic                 ioxlock,
    input logic                 fclk,
    input logic                 hclk,
    input logic                 clkudc,
    input logic                 clkbiogate,

    input  logic                ifev_vld,
    input  logic [7:0]          ifev_dat,
    output logic                ifev_rdy,

    output logic                wkupvld, wkupvld_async,
    output logic [EVCNT-1:0]    ifsubevo,
    output logic [ERRCNT-1:0]   ifsuberro,
    input  logic [IRQCNT-1:0]   cm7_irq,
    ahbif.slave                 ahbs,

    apbif.master                apbudp,

    ahbif.master                ahbaoram,

    ahbif.master                bdma_ahb32,
    axiif.master                bdma_axi32,

    `UTMI_IF_DEF
    output padcfg_arm_t  iocfg[0:IOC-1],
    ioif.drive                  iopad[0:IOC-1],
    input logic                 iframeven,
//    ioif.drive                  sddc_clk,
//    ioif.drive                  sddc_cmd,
//    ioif.drive                  sddc_dat0,
//    ioif.drive                  sddc_dat1,
//    ioif.drive                  sddc_dat2,
//    ioif.drive                  sddc_dat3,
    input wire [3:0] ana_adcsrc
);

    parameter IFEVCNT0       = 19*4;
    parameter IFEVCNT        = IFEVCNT0 + 2*4;
        parameter N_SPIM         = 4;
        parameter N_UART         = 4;
        parameter N_I2C          = 4;
        parameter N_CAM          = 1;
        parameter N_SDIO         = 1;
        parameter N_FILTER       = 1;
        parameter N_EXT_PER      = 0;
        parameter N_SPIS         = 2;
    logic clk24m_udc;

//  BMX
//  ====
//
    parameter HIDW  = 4;     // axi id width
    parameter HUDW  = 4;     // axi userdata width
    ahbif bmxifs[0:2](), bmxifm[0:2]();
    ahbif bmxifmdemux[0:4]();
    apbif #(.PAW(12)) apbper[0:15]();
    apbif #(.PAW(17)) apbudma();
    apbif #(.PAW(16)) apbpers();
    axiif #(.DW(32)) axiudma();
    // constrain the .DW parameter of the bdma_axi32 with a `thru` connector
    axiif #(.AW(32), .DW(32), .IDW(6)) bdma_axi32_local();
    axi_thru bdma_thru (bdma_axi32_local, bdma_axi32);

generate
    if(1) begin: __gen_amba

    ahb_thru bmxifs0 ( .ahbslave(ahbs), .ahbmaster( bmxifs[0] ));

    axi_ahb_bdg #( .AW(32), .DW(32)) bmxifs1 (
        .clk,
        .resetn,
        .axislave           (axiudma),
        .ahbmaster          (bmxifs[1])
    );

    // bmxifs: 0-core, 1-udma, 2-USB
    // bmxifm: 0-ifram0, 1-ifram1, 2-other

    ahb_bmxif_intf #(
    ) ahb_bmxif (
        .hclk               ( clk    ),
        .resetn             ( resetn ),
        .ahbs               ( bmxifs ),
        .ahbm               ( bmxifm )
    );

  //
    typedef axi_pkg::xbar_rule_32_t       rule32_t; // Has to be the same width as axi addr
    localparam rule32_t [4:0] bmxifm_map = '{
        '{idx: 32'd4 , start_addr: 32'h5030_0000, end_addr: 32'h5030_1fff}, // aosram
        '{idx: 32'd3 , start_addr: 32'h5014_0000, end_addr: 32'h5014_0fff}, // sddc
        '{idx: 32'd2 , start_addr: 32'h5020_0000, end_addr: 32'h5020_ffff}, // udc
        '{idx: 32'd1 , start_addr: 32'h5012_0000, end_addr: 32'h5012_ffff}, // apbper(64K for 16 ports)
        '{idx: 32'd0 , start_addr: 32'h5010_0000, end_addr: 32'h5011_ffff}  // udma
    };


    ahb_demux_map #(
        .SLVCNT             ( 5  ),
        .DW                 ( 32 ),
        .AW                 ( 32 ),
        .UW                 ( HUDW ),
        .ADDRMAP            ( bmxifm_map )
    ) ubmxifmdemux (
        .hclk               ( clk     ),
        .resetn             ( resetn  ),
        .ahbslave           ( bmxifm[2] ),
        .ahbmaster          ( bmxifmdemux )
    );

    ahb_thru ubmxifmdemux4 ( .ahbslave(bmxifmdemux[4]), .ahbmaster( ahbaoram ));

    apb_bdg #(.PAW(17)) uapbudma (
        .hclk(clk),
        .resetn(resetn),
        .pclken(1'b1),
        .ahbslave(bmxifmdemux[0]),
        .apbmaster(apbudma));

    apb_bdg #(.PAW(16)) uapbperbdg (
        .hclk(clk),
        .resetn(resetn),
        .pclken(pclken),
        .ahbslave(bmxifmdemux[1]),
        .apbmaster(apbpers));

//    apb_mux
    apb_mux uapbper(
        .apbslave   (apbpers),
        .apbmaster  (apbper)
    );

    apbs_nulls #(.SLVCNT(2)) uapbpernull (.apbslave(apbper[13:14]) );
    apbs_nulls #(.SLVCNT(1)) uapbpernull_pio (.apbslave(apbper[3:3]) );
    end
endgenerate

//  INT/EV
//  ====
//

    logic [3:0]         pwmev;
    logic               usbirq, sddcirq;
    logic [IFEVCNT-1:0] udmairq;
    logic               ioxirq;
    logic [3:0]         pioirq;
    logic [3:0]         iframerr;

    assign ifsubevo[IFEVCNT0-1:0] = udmairq;
    assign ifsubevo[IFEVCNT0+3:IFEVCNT0] = pwmev;
    assign ifsubevo[IFEVCNT0+4] = ioxirq;
    assign ifsubevo[EVCNT-N_I2C*2-1:IFEVCNT0+5] = '0 | { pioirq[3:0], sddcirq, usbirq };
    assign ifsubevo[EVCNT-1:EVCNT-N_I2C*2] = udmairq[IFEVCNT-1:IFEVCNT-8];
    assign ifsuberro = |iframerr;

//  IFRAM
//  ====
//

    ramif #(.RAW(15),.DW(32)) ahbifram[1:0]();

     ahbsramc32 #(.HAW(32),.RAW(17-2)) iframc0 (
        .clk,
        .resetn,
        .ahbslave       (bmxifm[0]),
        .rammaster      (ahbifram[0])
        );

     ahbsramc32 #(.HAW(32),.RAW(17-2)) iframc1 (
        .clk,
        .resetn,
        .ahbslave       (bmxifm[1]),
        .rammaster      (ahbifram[1])
        );

//#RAM

`ifdef FPGA

    uram_cas #( .XX (2), .YY (4)) ifram0 (
      .clk          (clk),
      .resetn,
      .waitcyc      ('0),
      .rams         (ahbifram[0])
    );

    uram_cas #( .XX (2), .YY (4)) ifram1 (
      .clk          (clk),
      .resetn,
      .waitcyc      ('0),
      .rams         (ahbifram[1])
    );

`else

    ifram ifram0(
        .clk,
        .resetn,
        .cmsatpg,
        .cmsbist,
        .rbs(rbif_ifram32kx36[0]),
        .scmbkey                ('0),
        .even                   (iframeven),
        .prerr                  (iframerr[0]),
        .verifyerr              (iframerr[1]),
        .rams                   ( ahbifram[0] )
    );

    ifram ifram1(
        .clk,
        .resetn,
        .cmsatpg,
        .cmsbist,
        .rbs(rbif_ifram32kx36[1]),
        .scmbkey                ('0),
        .even                   (iframeven),
        .prerr                  (iframerr[2]),
        .verifyerr              (iframerr[3]),
        .rams                   ( ahbifram[1] )
    );

`endif

//  udc, sddc
//  ====
    logic [0:IOC-1]     iopi;
    ioif pio_gpio[0:31]();
    ioif pwm0[3:0](), pwm1[3:0](), pwm2[3:0](), pwm3[3:0]();
    ioif                  sddc_clk();
    ioif                  sddc_cmd();
    ioif                  sddc_dat0();
    ioif                  sddc_dat1();
    ioif                  sddc_dat2();
    ioif                  sddc_dat3();

generate
    if(1) begin: __gen_pers
    ahbif #(.AW(32)) sdahbm[0:2]();
            // [0]  udc.ahbm
            // [1] sddc.ahbm
            // [2] null

    ahbm_null sdahbm2(sdahbm[2]);

    ahb_mux3  #(.AW(32))hmux3(
        .hclk (clk),
        .resetn(resetn),
        .ahbslave (sdahbm),
        .ahbmaster (bmxifs[2])
        );

    udc #(.AHBMID4(daric_cfg::AMBAID4_UDCA))udc(
        .clk(clkudc),
        .clkao25m(clk24m_udc),
        .resetn,
        .cmsatpg,
        .cmsbist,
        .rbif_udcmem_share  ,
        .rbif_udcmem_odb    ,
        .rbif_udcmem_256x64 ,
        .ahbm(sdahbm[0]),
        .ahbs(bmxifmdemux[2]),
        `UTMI_IF_INST
        .irq ( usbirq )
    );

    apb_thru #(.AW(12)) uapbper2(.apbslave (apbper[2]),.apbmaster(apbudp));
/*
    sddc #(.AHBMID4(daric_cfg::AMBAID4_SDDC))sddc(
        .clk,
        .pclk,
        .resetn,
        .cmsatpg,
        .cmsbist,
        .ahbm(sdahbm[1]),
        .ahbs(bmxifmdemux[3]),
        .apbs(apbper[1]),
        .apbx(apbper[1]),
        .sddc_clk(sddc_clk),
        .sddc_cmd(sddc_cmd),
    //    .sddc_dat(sddc_dat[3:0]),
        .sddc_dat0,
        .sddc_dat1,
        .sddc_dat2,
        .sddc_dat3,
        .irq ( sddcirq )
    );
*/
    ahbm_null sdahbm1(sdahbm[1]);
    ahbs_null bmxifmdemux3(bmxifmdemux[3]);
    apbs_null uapbpernull_sddc (apbper[1]);
    ioifdrv_null ioifnull_sdclk(sddc_clk);
    ioifdrv_null ioifnull_sdcmd(sddc_cmd);
    ioifdrv_null ioifnull_sddat0(sddc_dat0);
    ioifdrv_null ioifnull_sddat1(sddc_dat1);
    ioifdrv_null ioifnull_sddat2(sddc_dat2);
    ioifdrv_null ioifnull_sddat3(sddc_dat3);

    logic resetnbio;
    assign resetnbio = cmsatpg ? 1'b1 : resetn;

    logic hclkbio; ICG hcg_bio_hclk ( .CK (hclk), .EN ( clkbiogate ), .SE(cmsatpg), .CKG ( hclkbio ));
    logic pclkbio; ICG hcg_bio_pclk ( .CK (pclk), .EN ( clkbiogate ), .SE(cmsatpg), .CKG ( pclkbio ));
    logic fclkbio; ICG hcg_bio_fclk ( .CK (fclk), .EN ( clkbiogate ), .SE(cmsatpg), .CKG ( fclkbio ));

    bio_bdma #() bio (
        .hclk     (hclkbio),
        .pclk     (pclkbio),
        .aclk     (fclkbio),
        .dmaclk   (hclkbio),
        .reset_n  (resetnbio),
        .cmatpg   (cmsatpg),
        .cmbist   (cmsbist),
        .rbif_bioram1kx32      (rbif_bioram1kx32),
        .sramtrm  ('0),
        .bio_gpio (pio_gpio),
        .irq      (pioirq),
        // Don't map bottom 16 0's in, as this wastes bits
        // map only events from 16-208 into the BIO-BDMA. To arrive at the event
        // offset used in BIO-BDMA, subtract 16 from the system event number.
        .dmareq   (cm7_irq[207:16]),
        // config interface
        .apbs     (apbper[4]),
        .apbx     (apbper[4]),
        // imem pages
        .apbs_imem(apbper[5:8]),
        .apbx_imem(apbper[5:8]),
        // fifo access alias pages
        .apbs_fifo(apbper[9:12]),
        .apbx_fifo(apbper[9:12]),
        // axi memory bus master
        .axim     (bdma_axi32_local),
        // ahb peripheral bus master
        .ahbm     (bdma_ahb32)
    );

//  ADV_TIMER / PWM
//  ====
//
//    logic [16*5-1:0] pwmgpiosrc;

    pwm #( .ICNT ( IOC ) )pwm(
        .clk (pclk),    // Clock
        .resetn,
        .cmsatpg,

        .clk32m(clk48m),
        .ev         ( pwmev ),
        .gpiosrc    ( iopi ),

        .apbs       ( apbper[0] ),
        .pwm0, .pwm1, .pwm2, .pwm3
    );
    end
endgenerate

//pwmgpiosrc

//  UDMA
//  ====
//

        parameter AW             = 18; // 256KB
        parameter AW32           = AW-2;
        parameter CAM_DW         = 8;
        parameter PAW            = 17;  //APB 4KB * 32 = 17bit
        parameter TRANS_SIZE     = 20;  //max uDMA transaction size of 1MB

        ioif      spim_clk[N_SPIM-1:0]() , spim_clk_a[N_SPIM-1:0]() , spim_clk_b[N_SPIM-1:0]() ;
        ioif      spim_csn0[N_SPIM-1:0](), spim_csn0_a[N_SPIM-1:0](), spim_csn0_b[N_SPIM-1:0]();
        ioif      spim_csn1[N_SPIM-1:0](), spim_csn1_a[N_SPIM-1:0](), spim_csn1_b[N_SPIM-1:0]();
        ioif      spim_csn2[N_SPIM-1:0](), spim_csn2_a[N_SPIM-1:0](), spim_csn2_b[N_SPIM-1:0]();
        ioif      spim_csn3[N_SPIM-1:0](), spim_csn3_a[N_SPIM-1:0](), spim_csn3_b[N_SPIM-1:0]();
        ioif      spim_sd0[N_SPIM-1:0]() , spim_sd0_a[N_SPIM-1:0]() , spim_sd0_b[N_SPIM-1:0]() ;
        ioif      spim_sd1[N_SPIM-1:0]() , spim_sd1_a[N_SPIM-1:0]() , spim_sd1_b[N_SPIM-1:0]() ;
        ioif      spim_sd2[N_SPIM-1:0]() , spim_sd2_a[N_SPIM-1:0]() , spim_sd2_b[N_SPIM-1:0]() ;
        ioif      spim_sd3[N_SPIM-1:0]() , spim_sd3_a[N_SPIM-1:0]() , spim_sd3_b[N_SPIM-1:0]() ;
        ioif      i2c_scl[N_I2C-1:0](), i2c_scl_a[N_I2C-1:0](), i2c_scl_b[N_I2C-1:0]();
        ioif      i2c_sda[N_I2C-1:0](), i2c_sda_a[N_I2C-1:0](), i2c_sda_b[N_I2C-1:0]();
        ioif      uart_rx[N_UART-1:0](), uart_rx_a[N_UART-1:0](), uart_rx_b[N_UART-1:0]();
        ioif      uart_tx[N_UART-1:0](), uart_tx_a[N_UART-1:0](), uart_tx_b[N_UART-1:0]();

        ioif      cam_clk();
        ioif      cam_data[CAM_DW-1:0]();
        ioif      cam_hsync();
        ioif      cam_vsync();
        ioif      sdio_clk();
        ioif      sdio_cmd();
        ioif      sdio_data[3:0]();
        ioif      i2ss_sd();
        ioif      i2ss_ws();
        ioif      i2ss_sck();
        ioif      i2sm_sd();
        ioif      i2sm_ws();
        ioif      i2sm_sck();
        ioif      scif_sck();
        ioif      scif_dat();
        ioif      spis_clk[N_SPIS-1:0](),spis_clk_a[N_SPIS-1:0](),spis_clk_b[N_SPIS-1:0]();
        ioif      spis_csn[N_SPIS-1:0](),spis_csn_a[N_SPIS-1:0](),spis_csn_b[N_SPIS-1:0]();
        ioif      spis_mosi[N_SPIS-1:0](),spis_mosi_a[N_SPIS-1:0](),spis_mosi_b[N_SPIS-1:0]();
        ioif      spis_miso[N_SPIS-1:0](),spis_miso_a[N_SPIS-1:0](),spis_miso_b[N_SPIS-1:0]();

generate
    if(1) begin: __gen_udma
    logic clk24m, clk24m_unbuf, clk24m_reg;
    `theregfull( clk48m, resetn, clk24m_reg, '0 ) <= ~clk24m_reg;
    assign clk24m_unbuf = cmsatpg ? clk : clk24m_reg;
    CLKCELL_BUF uclk24m(.A(clk24m_unbuf), .Z(clk24m));
    assign clk24m_udc = clk24m;

ifsub1
#(
/*      parameter*/ .DW             ( 32         ),
/*      parameter*/ .AW             ( AW         ), // 256KB
/*      parameter*/ .AW32           ( AW32       ),
/*      parameter*/ .CAM_DW         ( CAM_DW     ),
/*      parameter*/ .PAW            ( PAW        ),
/*      parameter*/ .TRANS_SIZE     ( TRANS_SIZE ),  //max uDMA transaction size of 1MB
/*      parameter*/ .N_SPIM         ( N_SPIM     ),
/*      parameter*/ .N_SPIS         ( N_SPIS     ),
/*      parameter*/ .N_UART         ( N_UART     ),
/*      parameter*/ .N_I2C          ( N_I2C      ),
/*      parameter*/ .N_CAM          ( N_CAM      ),
/*      parameter*/ .N_SDIO         ( N_SDIO     ),
/*      parameter*/ .N_FILTER       ( N_FILTER   ),
/*      parameter*/ .N_EXT_PER      ( N_EXT_PER  ),
/*      parameter*/ .EVCNT          ( IFEVCNT    ),
                    .AXIMID4        (daric_cfg::AMBAID4_UDMA)
    )dmasub(
/*      input logic       */  .clk             ,
/*      input logic       */  .resetn          ,
/*      input logic       */  .perclk          ,
/*      input logic       */  .cmsatpg         ,
/*      apbif.slave       */  .apbs            ( apbudma ),
/*      axiif.master      */  .axim            ( axiudma ),
/*        ioif.drive      */  .spim_clk_pad    ( spim_clk   ),
/*        ioif.drive      */  .spim_csn0_pad   ( spim_csn0  ),
/*        ioif.drive      */  .spim_csn1_pad   ( spim_csn1  ),
/*        ioif.drive      */  .spim_csn2_pad   ( spim_csn2  ),
/*        ioif.drive      */  .spim_csn3_pad   ( spim_csn3  ),
/*        ioif.drive      */  .spim_sd0_pad    ( spim_sd0   ),
/*        ioif.drive      */  .spim_sd1_pad    ( spim_sd1   ),
/*        ioif.drive      */  .spim_sd2_pad    ( spim_sd2   ),
/*        ioif.drive      */  .spim_sd3_pad    ( spim_sd3   ),
/*        ioif.drive      */  .i2c_scl_pad     ( i2c_scl    ),
/*        ioif.drive      */  .i2c_sda_pad     ( i2c_sda    ),
/*        ioif.drive      */  .cam_clk_pad     ( cam_clk    ),
/*        ioif.drive      */  .cam_data_pad    ( cam_data   ),
/*        ioif.drive      */  .cam_hsync_pad   ( cam_hsync  ),
/*        ioif.drive      */  .cam_vsync_pad   ( cam_vsync  ),
/*        ioif.drive      */  .uart_rx_pad     ( uart_rx[N_UART-1:0]    ),
/*        ioif.drive      */  .uart_tx_pad     ( uart_tx[N_UART-1:0]    ),
/*        ioif.drive      */  .sdio_clk_pad    ( sdio_clk   ),
/*        ioif.drive      */  .sdio_cmd_pad    ( sdio_cmd   ),
/*        ioif.drive      */  .sdio_data_pad   ( sdio_data  ),
/*        ioif.drive      */  .i2ss_sd_pad     ( i2ss_sd    ),
/*        ioif.drive      */  .i2ss_ws_pad     ( i2ss_ws    ),
/*        ioif.drive      */  .i2ss_sck_pad    ( i2ss_sck   ),
/*        ioif.drive      */  .i2sm_sd_pad     ( i2sm_sd    ),
/*        ioif.drive      */  .i2sm_ws_pad     ( i2sm_ws    ),
/*        ioif.drive      */  .i2sm_sck_pad    ( i2sm_sck   ),
/*        ioif.drive      */  .scif_sck_pad    ( scif_sck   ),
/*        ioif.drive      */  .scif_dat_pad    ( scif_dat   ),
/*        ioif.drive      */  .spis_clk_pad    ( spis_clk   ),
/*        ioif.drive      */  .spis_csn_pad    ( spis_csn   ),
/*        ioif.drive      */  .spis_mosi_pad   ( spis_mosi  ),
/*        ioif.drive      */  .spis_miso_pad   ( spis_miso  ),
/*output logic [EVCNT-1:0]*/  .intr            ( udmairq ),
                              .*
);

    end
endgenerate

//  IOMUX
//  ====
//
    localparam AFC = 4;
    localparam GW = 16;

generate
    if(1) begin: __gen_iomux

    ioif   af1[0:95](),   af2[0:95](),   af3[0:95]();

    ioif afnc();
    ionc uionc(.iodrv(afnc));

    ioif afnc_pio[0:3]();
    ionc_pio uionc_pio0(.iodrv(afnc_pio[0]));
    ionc_pio uionc_pio1(.iodrv(afnc_pio[1]));
    ionc_pio uionc_pio2(.iodrv(afnc_pio[2]));
    ionc_pio uionc_pio3(.iodrv(afnc_pio[3]));

    ioif af1_A[0:15](), af2_A[0:15](), af3_A[0:15]();
    ioif af1_B[0:15](), af2_B[0:15](), af3_B[0:15](), af1_B_pio[0:15]();
    ioif af1_C[0:15](), af2_C[0:15](), af3_C[0:15](), af1_C_pio[0:15]();
    ioif af1_D[0:15](), af2_D[0:15](), af3_D[0:15]();
    ioif af1_E[0:15](), af2_E[0:15](), af3_E[0:15]();
    ioif af1_F[0:15](), af2_F[0:15](), af3_F[0:15]();

    iothrus ioga1A(.ioload(af1_A), .iodrv(af1[ 0:15]));
    iothrus ioga1B(.ioload(af1_B_pio), .iodrv(af1[16:31]));
    iothrus ioga1C(.ioload(af1_C_pio), .iodrv(af1[32:47]));
    iothrus ioga1D(.ioload(af1_D), .iodrv(af1[48:63]));
    iothrus ioga1E(.ioload(af1_E), .iodrv(af1[64:79]));
    iothrus ioga1F(.ioload(af1_F), .iodrv(af1[80:95]));

    iothrus ioga2A(.ioload(af2_A), .iodrv(af2[ 0:15]));
    iothrus ioga2B(.ioload(af2_B), .iodrv(af2[16:31]));
    iothrus ioga2C(.ioload(af2_C), .iodrv(af2[32:47]));
    iothrus ioga2D(.ioload(af2_D), .iodrv(af2[48:63]));
    iothrus ioga2E(.ioload(af2_E), .iodrv(af2[64:79]));
    iothrus ioga2F(.ioload(af2_F), .iodrv(af2[80:95]));

    iothrus ioga3A(.ioload(af3_A), .iodrv(af3[ 0:15]));
    iothrus ioga3B(.ioload(af3_B), .iodrv(af3[16:31]));
    iothrus ioga3C(.ioload(af3_C), .iodrv(af3[32:47]));
    iothrus ioga3D(.ioload(af3_D), .iodrv(af3[48:63]));
    iothrus ioga3E(.ioload(af3_E), .iodrv(af3[64:79]));
    iothrus ioga3F(.ioload(af3_F), .iodrv(af3[80:95]));

    logic  [0:IOC-1][AFC-1:0] afconnmask;
    logic  [0:GW-1][AFC-1:0]  afom_A, afom_B, afom_C, afom_D, afom_E, afom_F;
    logic  [0:31] piosel;
    assign afconnmask = {afom_A, afom_B, afom_C, afom_D, afom_E, afom_F };

    iox #(
            .IOC    ( IOC ),
            .IOCW   ( $clog2(IOC) ),
            .GW     ( GW ),
            .GC     ( IOC/GW ),
            .AFC    ( AFC ), // fixed
            .AFCW   ( $clog2(AFC) ), // fixed
            .INTC   ( 8 )
        )__iox(
        .clksys,
        .pclk       (pclk),
        .resetn,
        .cmsbist,
        .cmsatpg,
        .sfrlock    (ioxlock),

        .apbs       (apbper[15]),
        .apbx       (apbper[15]),
        .wkupvld    ,
        .wkupvld_async    ,
        .intvld     (ioxirq),
        .iopi       (iopi),
        .piosel     (piosel),
        .afconnmask,
        .afpad1     (af1[0:IOC-1]),
        .afpad2     (af2[0:IOC-1]),
        .afpad3     (af3[0:IOC-1]),
        .iopad      (iopad[0:IOC-1]),
        .iocfg      (iocfg[0:IOC-1]),
        .*
    );

ioxdulp #(.IOC(N_SPIM)) spim_clk_dulp  ( .di( spim_clk[N_SPIM-1:0] ) , .doa( spim_clk_a[N_SPIM-1:0] ) , .dob( spim_clk_b[N_SPIM-1:0] ) );
ioxdulp #(.IOC(N_SPIM)) spim_csn0_dulp ( .di( spim_csn0[N_SPIM-1:0] ), .doa( spim_csn0_a[N_SPIM-1:0] ), .dob( spim_csn0_b[N_SPIM-1:0] ));
ioxdulp #(.IOC(N_SPIM)) spim_csn1_dulp ( .di( spim_csn1[N_SPIM-1:0] ), .doa( spim_csn1_a[N_SPIM-1:0] ), .dob( spim_csn1_b[N_SPIM-1:0] ));
ioxdulp #(.IOC(N_SPIM)) spim_csn2_dulp ( .di( spim_csn2[N_SPIM-1:0] ), .doa( spim_csn2_a[N_SPIM-1:0] ), .dob( spim_csn2_b[N_SPIM-1:0] ));
ioxdulp #(.IOC(N_SPIM)) spim_csn3_dulp ( .di( spim_csn3[N_SPIM-1:0] ), .doa( spim_csn3_a[N_SPIM-1:0] ), .dob( spim_csn3_b[N_SPIM-1:0] ));
ioxdulp #(.IOC(N_SPIM)) spim_sd0_dulp  ( .di( spim_sd0[N_SPIM-1:0] ) , .doa( spim_sd0_a[N_SPIM-1:0] ) , .dob( spim_sd0_b[N_SPIM-1:0] ) );
ioxdulp #(.IOC(N_SPIM)) spim_sd1_dulp  ( .di( spim_sd1[N_SPIM-1:0] ) , .doa( spim_sd1_a[N_SPIM-1:0] ) , .dob( spim_sd1_b[N_SPIM-1:0] ) );
ioxdulp #(.IOC(N_SPIM)) spim_sd2_dulp  ( .di( spim_sd2[N_SPIM-1:0] ) , .doa( spim_sd2_a[N_SPIM-1:0] ) , .dob( spim_sd2_b[N_SPIM-1:0] ) );
ioxdulp #(.IOC(N_SPIM)) spim_sd3_dulp  ( .di( spim_sd3[N_SPIM-1:0] ) , .doa( spim_sd3_a[N_SPIM-1:0] ) , .dob( spim_sd3_b[N_SPIM-1:0] ) );
ioxdulp #(.IOC(N_I2C))  i2c_scl_dulp   ( .di( i2c_scl[N_I2C-1:0] ),    .doa( i2c_scl_a[N_I2C-1:0] ),   .dob( i2c_scl_b[N_I2C-1:0] ));
ioxdulp #(.IOC(N_I2C))  i2c_sda_dulp   ( .di( i2c_sda[N_I2C-1:0] ),    .doa( i2c_sda_a[N_I2C-1:0] ),   .dob( i2c_sda_b[N_I2C-1:0] ));
ioxdulp #(.IOC(N_UART)) uart_rx_dulp   ( .di( uart_rx[N_UART-1:0] ),   .doa( uart_rx_a[N_UART-1:0] ),   .dob( uart_rx_b[N_UART-1:0] ));
ioxdulp #(.IOC(N_UART)) uart_tx_dulp   ( .di( uart_tx[N_UART-1:0] ),   .doa( uart_tx_a[N_UART-1:0] ),   .dob( uart_tx_b[N_UART-1:0] ));
ioxdulp #(.IOC(N_SPIS)) spis_clk_dulp  ( .di( spis_clk[N_SPIS-1:0] ),  .doa( spis_clk_a[N_SPIS-1:0] ),  .dob( spis_clk_b[N_SPIS-1:0] ));
ioxdulp #(.IOC(N_SPIS)) spis_csn_dulp  ( .di( spis_csn[N_SPIS-1:0] ),  .doa( spis_csn_a[N_SPIS-1:0] ),  .dob( spis_csn_b[N_SPIS-1:0] ));
ioxdulp #(.IOC(N_SPIS)) spis_mosi_dulp ( .di( spis_mosi[N_SPIS-1:0] ), .doa( spis_mosi_a[N_SPIS-1:0] ), .dob( spis_mosi_b[N_SPIS-1:0] ));
ioxdulp #(.IOC(N_SPIS)) spis_miso_dulp ( .di( spis_miso[N_SPIS-1:0] ), .doa( spis_miso_a[N_SPIS-1:0] ), .dob( spis_miso_b[N_SPIS-1:0] ));

ioifld_null _null_spim_clk_b_3( spim_clk_b[3] );
ioifld_null _null_spim_csn0_b_3( spim_csn0_b[3] );
ioifld_null _null_spim_csn1_b_3( spim_csn1_b[3] );
ioifld_null _null_spim_csn2_b_3( spim_csn2_b[3] );
ioifld_null _null_spim_csn3_b_3( spim_csn3_b[3] );
ioifld_null _null_spim_sd0_b_3( spim_sd0_b[3] );
ioifld_null _null_spim_sd1_b_3( spim_sd1_b[3] );
ioifld_null _null_spim_sd2_b_3( spim_sd2_b[3] );
ioifld_null _null_spim_sd3_b_3( spim_sd3_b[3] );

ioifld_null _null_spim_sd2_b_0( spim_sd2_b[0] );  ioifld_null _null_spim_sd3_b_0( spim_sd3_b[0] );
ioifld_null _null_spim_sd2_b_1( spim_sd2_b[1] );  ioifld_null _null_spim_sd3_b_1( spim_sd3_b[1] );
ioifld_null _null_spim_sd2_b_2( spim_sd2_b[2] );  ioifld_null _null_spim_sd3_b_2( spim_sd3_b[2] );
ioifld_null _null_spim_sd2_a_2( spim_sd2_a[2] );  ioifld_null _null_spim_sd3_a_2( spim_sd3_a[2] );
ioifld_null _null_spim_sd2_a_3( spim_sd2_a[3] );  ioifld_null _null_spim_sd3_a_3( spim_sd3_a[3] );

piomux16 piomuxB (.piosel(piosel[ 0:15]), .gpio16(af1_B[0:15]), .pio16(pio_gpio[ 0:15]), .gpio16mux(af1_B_pio[0:15]));
piomux16 piomuxC (.piosel(piosel[16:31]), .gpio16(af1_C[0:15]), .pio16(pio_gpio[16:31]), .gpio16mux(af1_C_pio[0:15]));

afconn afc_A00(.afomask( afom_A[0] ), .afo1( af1_A[0] ), .afo2( af2_A[0] ), .afo3( af3_A[0] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( i2c_scl_a[1]     ), .afi2pi( i2c_scl_a[1]   .pi  ), .afi3( pwm0[0] ));
afconn afc_A01(.afomask( afom_A[1] ), .afo1( af1_A[1] ), .afo2( af2_A[1] ), .afo3( af3_A[1] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( i2c_sda_a[1]     ), .afi2pi( i2c_sda_a[1]   .pi  ), .afi3( pwm0[1] ));
afconn afc_A02(.afomask( afom_A[2] ), .afo1( af1_A[2] ), .afo2( af2_A[2] ), .afo3( af3_A[2] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( pwm0[2] ));
afconn afc_A03(.afomask( afom_A[3] ), .afo1( af1_A[3] ), .afo2( af2_A[3] ), .afo3( af3_A[3] ),       .afi1( uart_rx_a[0]     ), .afi1pi( uart_rx_a[0]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( pwm0[3] ));
afconn afc_A04(.afomask( afom_A[4] ), .afo1( af1_A[4] ), .afo2( af2_A[4] ), .afo3( af3_A[4] ),       .afi1( uart_tx_a[0]     ), .afi1pi( uart_tx_a[0]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_A05(.afomask( afom_A[5] ), .afo1( af1_A[5] ), .afo2( af2_A[5] ), .afo3( af3_A[5] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( i2c_scl_a[0]     ), .afi2pi( i2c_scl_a[0]   .pi  ), .afi3( afnc    ));
afconn afc_A06(.afomask( afom_A[6] ), .afo1( af1_A[6] ), .afo2( af2_A[6] ), .afo3( af3_A[6] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( i2c_sda_a[0]     ), .afi2pi( i2c_sda_a[0]   .pi  ), .afi3( afnc    ));
afconn afc_A07(.afomask( afom_A[7] ), .afo1( af1_A[7] ), .afo2( af2_A[7] ), .afo3( af3_A[7] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_A08(.afomask( afom_A[8] ), .afo1( af1_A[8] ), .afo2( af2_A[8] ), .afo3( af3_A[8] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_A09(.afomask( afom_A[9] ), .afo1( af1_A[9] ), .afo2( af2_A[9] ), .afo3( af3_A[9] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_A10(.afomask( afom_A[10] ), .afo1( af1_A[10] ), .afo2( af2_A[10] ), .afo3( af3_A[10] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_A11(.afomask( afom_A[11] ), .afo1( af1_A[11] ), .afo2( af2_A[11] ), .afo3( af3_A[11] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_A12(.afomask( afom_A[12] ), .afo1( af1_A[12] ), .afo2( af2_A[12] ), .afo3( af3_A[12] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_A13(.afomask( afom_A[13] ), .afo1( af1_A[13] ), .afo2( af2_A[13] ), .afo3( af3_A[13] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_A14(.afomask( afom_A[14] ), .afo1( af1_A[14] ), .afo2( af2_A[14] ), .afo3( af3_A[14] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_A15(.afomask( afom_A[15] ), .afo1( af1_A[15] ), .afo2( af2_A[15] ), .afo3( af3_A[15] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_B00(.afomask( afom_B[0] ), .afo1( af1_B[0] ), .afo2( af2_B[0] ), .afo3( af3_B[0] ),       .afi1( cam_data[0]      ), .afi1pi( cam_data[0]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( pwm1[0] ));
afconn afc_B01(.afomask( afom_B[1] ), .afo1( af1_B[1] ), .afo2( af2_B[1] ), .afo3( af3_B[1] ),       .afi1( cam_data[1]      ), .afi1pi( cam_data[1]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( pwm1[1] ));
afconn afc_B02(.afomask( afom_B[2] ), .afo1( af1_B[2] ), .afo2( af2_B[2] ), .afo3( af3_B[2] ),       .afi1( cam_data[2]      ), .afi1pi( cam_data[2]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( pwm1[2] ));
afconn afc_B03(.afomask( afom_B[3] ), .afo1( af1_B[3] ), .afo2( af2_B[3] ), .afo3( af3_B[3] ),       .afi1( cam_data[3]      ), .afi1pi( cam_data[3]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( pwm1[3] ));
afconn afc_B04(.afomask( afom_B[4] ), .afo1( af1_B[4] ), .afo2( af2_B[4] ), .afo3( af3_B[4] ),       .afi1( cam_data[4]      ), .afi1pi( cam_data[4]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_B05(.afomask( afom_B[5] ), .afo1( af1_B[5] ), .afo2( af2_B[5] ), .afo3( af3_B[5] ),       .afi1( cam_data[5]      ), .afi1pi( cam_data[5]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_B06(.afomask( afom_B[6] ), .afo1( af1_B[6] ), .afo2( af2_B[6] ), .afo3( af3_B[6] ),       .afi1( cam_data[6]      ), .afi1pi( cam_data[6]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_B07(.afomask( afom_B[7] ), .afo1( af1_B[7] ), .afo2( af2_B[7] ), .afo3( af3_B[7] ),       .afi1( cam_data[7]      ), .afi1pi( cam_data[7]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_B08(.afomask( afom_B[8] ), .afo1( af1_B[8] ), .afo2( af2_B[8] ), .afo3( af3_B[8] ),       .afi1( cam_hsync        ), .afi1pi( cam_hsync       .pi ), .afi2( spim_clk_a[2]    ), .afi2pi( spim_clk_a[2]  .pi  ), .afi3( afnc    ));
afconn afc_B09(.afomask( afom_B[9] ), .afo1( af1_B[9] ), .afo2( af2_B[9] ), .afo3( af3_B[9] ),       .afi1( cam_vsync        ), .afi1pi( cam_vsync       .pi ), .afi2( spim_sd0_a[2]    ), .afi2pi( spim_sd0_a[2]  .pi  ), .afi3( afnc    ));
afconn afc_B10(.afomask( afom_B[10] ), .afo1( af1_B[10] ), .afo2( af2_B[10] ), .afo3( af3_B[10] ),   .afi1( cam_clk          ), .afi1pi( cam_clk         .pi ), .afi2( spim_sd1_a[2]    ), .afi2pi( spim_sd1_a[2]  .pi  ), .afi3( afnc    ));
afconn afc_B11(.afomask( afom_B[11] ), .afo1( af1_B[11] ), .afo2( af2_B[11] ), .afo3( af3_B[11] ),   .afi1( i2c_scl_b[0]     ), .afi1pi( i2c_scl_b[0]    .pi ), .afi2( spim_csn0_a[2]   ), .afi2pi( spim_csn0_a[2] .pi  ), .afi3( afnc    ));
afconn afc_B12(.afomask( afom_B[12] ), .afo1( af1_B[12] ), .afo2( af2_B[12] ), .afo3( af3_B[12] ),   .afi1( i2c_sda_b[0]     ), .afi1pi( i2c_sda_b[0]    .pi ), .afi2( spim_csn1_a[2]   ), .afi2pi( spim_csn1_a[2] .pi  ), .afi3( afnc    ));
afconn afc_B13(.afomask( afom_B[13] ), .afo1( af1_B[13] ), .afo2( af2_B[13] ), .afo3( af3_B[13] ),   .afi1( uart_rx_b[2]     ), .afi1pi( uart_rx_b[2]    .pi ), .afi2( scif_sck         ), .afi2pi( scif_sck       .pi  ), .afi3( afnc    ));
afconn afc_B14(.afomask( afom_B[14] ), .afo1( af1_B[14] ), .afo2( af2_B[14] ), .afo3( af3_B[14] ),   .afi1( uart_tx_b[2]     ), .afi1pi( uart_tx_b[2]    .pi ), .afi2( scif_dat         ), .afi2pi( scif_dat       .pi  ), .afi3( afnc    ));
afconn afc_B15(.afomask( afom_B[15] ), .afo1( af1_B[15] ), .afo2( af2_B[15] ), .afo3( af3_B[15] ),   .afi1( afnc_pio[0]      ), .afi1pi( afnc_pio[0]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_C00(.afomask( afom_C[0] ), .afo1( af1_C[0] ), .afo2( af2_C[0] ), .afo3( af3_C[0] ),       .afi1( sdio_clk         ), .afi1pi( sdio_clk        .pi ), .afi2( spim_clk_b[2]    ), .afi2pi( spim_clk_b[2]  .pi  ), .afi3( pwm2[0] ));
afconn afc_C01(.afomask( afom_C[1] ), .afo1( af1_C[1] ), .afo2( af2_C[1] ), .afo3( af3_C[1] ),       .afi1( sdio_cmd         ), .afi1pi( sdio_cmd        .pi ), .afi2( spim_sd0_b[2]    ), .afi2pi( spim_sd0_b[2]  .pi  ), .afi3( pwm2[1] ));
afconn afc_C02(.afomask( afom_C[2] ), .afo1( af1_C[2] ), .afo2( af2_C[2] ), .afo3( af3_C[2] ),       .afi1( sdio_data[0]     ), .afi1pi( sdio_data[0]    .pi ), .afi2( spim_sd1_b[2]    ), .afi2pi( spim_sd1_b[2]  .pi  ), .afi3( pwm2[2] ));
afconn afc_C03(.afomask( afom_C[3] ), .afo1( af1_C[3] ), .afo2( af2_C[3] ), .afo3( af3_C[3] ),       .afi1( sdio_data[1]     ), .afi1pi( sdio_data[1]    .pi ), .afi2( spim_csn0_b[2]   ), .afi2pi( spim_csn0_b[2] .pi  ), .afi3( pwm2[3] ));
afconn afc_C04(.afomask( afom_C[4] ), .afo1( af1_C[4] ), .afo2( af2_C[4] ), .afo3( af3_C[4] ),       .afi1( sdio_data[2]     ), .afi1pi( sdio_data[2]    .pi ), .afi2( spim_csn1_b[2]   ), .afi2pi( spim_csn1_b[2] .pi  ), .afi3( afnc    ));
afconn afc_C05(.afomask( afom_C[5] ), .afo1( af1_C[5] ), .afo2( af2_C[5] ), .afo3( af3_C[5] ),       .afi1( sdio_data[3]     ), .afi1pi( sdio_data[3]    .pi ), .afi2( i2c_scl_b[3]     ), .afi2pi( i2c_scl_b[3]   .pi  ), .afi3( afnc    ));
afconn afc_C06(.afomask( afom_C[6] ), .afo1( af1_C[6] ), .afo2( af2_C[6] ), .afo3( af3_C[6] ),       .afi1( afnc_pio[1]      ), .afi1pi( afnc_pio[1]     .pi ), .afi2( i2c_sda_b[3]     ), .afi2pi( i2c_sda_b[3]   .pi  ), .afi3( afnc    ));
afconn afc_C07(.afomask( afom_C[7] ), .afo1( af1_C[7] ), .afo2( af2_C[7] ), .afo3( af3_C[7] ),       .afi1( spim_sd0_a[1]    ), .afi1pi( spim_sd0_a[1]   .pi ), .afi2( sddc_dat0        ), .afi2pi( sddc_dat0      .pi  ), .afi3( afnc    ));
afconn afc_C08(.afomask( afom_C[8] ), .afo1( af1_C[8] ), .afo2( af2_C[8] ), .afo3( af3_C[8] ),       .afi1( spim_sd1_a[1]    ), .afi1pi( spim_sd1_a[1]   .pi ), .afi2( sddc_dat1        ), .afi2pi( sddc_dat1      .pi  ), .afi3( afnc    ));
afconn afc_C09(.afomask( afom_C[9] ), .afo1( af1_C[9] ), .afo2( af2_C[9] ), .afo3( af3_C[9] ),       .afi1( spim_sd2_a[1]    ), .afi1pi( spim_sd2_a[1]   .pi ), .afi2( sddc_dat2        ), .afi2pi( sddc_dat2      .pi  ), .afi3( afnc    ));
afconn afc_C10(.afomask( afom_C[10] ), .afo1( af1_C[10] ), .afo2( af2_C[10] ), .afo3( af3_C[10] ),   .afi1( spim_sd3_a[1]    ), .afi1pi( spim_sd3_a[1]   .pi ), .afi2( sddc_dat3        ), .afi2pi( sddc_dat3      .pi  ), .afi3( afnc    ));
afconn afc_C11(.afomask( afom_C[11] ), .afo1( af1_C[11] ), .afo2( af2_C[11] ), .afo3( af3_C[11] ),   .afi1( spim_clk_a[1]    ), .afi1pi( spim_clk_a[1]   .pi ), .afi2( sddc_clk         ), .afi2pi( sddc_clk       .pi  ), .afi3( afnc    ));
afconn afc_C12(.afomask( afom_C[12] ), .afo1( af1_C[12] ), .afo2( af2_C[12] ), .afo3( af3_C[12] ),   .afi1( spim_csn0_a[1]   ), .afi1pi( spim_csn0_a[1]  .pi ), .afi2( sddc_cmd         ), .afi2pi( sddc_cmd       .pi  ), .afi3( afnc    ));
afconn afc_C13(.afomask( afom_C[13] ), .afo1( af1_C[13] ), .afo2( af2_C[13] ), .afo3( af3_C[13] ),   .afi1( spim_csn1_a[1]   ), .afi1pi( spim_csn1_a[1]  .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_C14(.afomask( afom_C[14] ), .afo1( af1_C[14] ), .afo2( af2_C[14] ), .afo3( af3_C[14] ),   .afi1( afnc_pio[2]      ), .afi1pi( afnc_pio[2]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_C15(.afomask( afom_C[15] ), .afo1( af1_C[15] ), .afo2( af2_C[15] ), .afo3( af3_C[15] ),   .afi1( afnc_pio[3]      ), .afi1pi( afnc_pio[3]     .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_D00(.afomask( afom_D[0] ), .afo1( af1_D[0] ), .afo2( af2_D[0] ), .afo3( af3_D[0] ),       .afi1( spim_sd0_a[0]    ), .afi1pi( spim_sd0_a[0]   .pi ), .afi2( spis_mosi_b[0]   ), .afi2pi( spis_mosi_b[0] .pi  ), .afi3( pwm3[0] ));
afconn afc_D01(.afomask( afom_D[1] ), .afo1( af1_D[1] ), .afo2( af2_D[1] ), .afo3( af3_D[1] ),       .afi1( spim_sd1_a[0]    ), .afi1pi( spim_sd1_a[0]   .pi ), .afi2( spis_miso_b[0]   ), .afi2pi( spis_miso_b[0] .pi  ), .afi3( pwm3[1] ));
afconn afc_D02(.afomask( afom_D[2] ), .afo1( af1_D[2] ), .afo2( af2_D[2] ), .afo3( af3_D[2] ),       .afi1( spim_sd2_a[0]    ), .afi1pi( spim_sd2_a[0]   .pi ), .afi2( uart_rx_b[0]     ), .afi2pi( uart_rx_b[0]   .pi  ), .afi3( pwm3[2] ));
afconn afc_D03(.afomask( afom_D[3] ), .afo1( af1_D[3] ), .afo2( af2_D[3] ), .afo3( af3_D[3] ),       .afi1( spim_sd3_a[0]    ), .afi1pi( spim_sd3_a[0]   .pi ), .afi2( uart_tx_b[0]     ), .afi2pi( uart_tx_b[0]   .pi  ), .afi3( pwm3[3] ));
afconn afc_D04(.afomask( afom_D[4] ), .afo1( af1_D[4] ), .afo2( af2_D[4] ), .afo3( af3_D[4] ),       .afi1( spim_clk_a[0]    ), .afi1pi( spim_clk_a[0]   .pi ), .afi2( spis_clk_b[0]    ), .afi2pi( spis_clk_b[0]  .pi  ), .afi3( afnc    ));
afconn afc_D05(.afomask( afom_D[5] ), .afo1( af1_D[5] ), .afo2( af2_D[5] ), .afo3( af3_D[5] ),       .afi1( spim_csn0_a[0]   ), .afi1pi( spim_csn0_a[0]  .pi ), .afi2( spis_csn_b[0]    ), .afi2pi( spis_csn_b[0]  .pi  ), .afi3( afnc    ));
afconn afc_D06(.afomask( afom_D[6] ), .afo1( af1_D[6] ), .afo2( af2_D[6] ), .afo3( af3_D[6] ),       .afi1( spim_csn1_a[0]   ), .afi1pi( spim_csn1_a[0]  .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_D07(.afomask( afom_D[7] ), .afo1( af1_D[7] ), .afo2( af2_D[7] ), .afo3( af3_D[7] ),       .afi1( i2ss_sd          ), .afi1pi( i2ss_sd         .pi ), .afi2( spim_clk_b[1]    ), .afi2pi( spim_clk_b[1]  .pi  ), .afi3( afnc    ));
afconn afc_D08(.afomask( afom_D[8] ), .afo1( af1_D[8] ), .afo2( af2_D[8] ), .afo3( af3_D[8] ),       .afi1( i2ss_ws          ), .afi1pi( i2ss_ws         .pi ), .afi2( spim_sd0_b[1]    ), .afi2pi( spim_sd0_b[1]  .pi  ), .afi3( pwm0[0] ));
afconn afc_D09(.afomask( afom_D[9] ), .afo1( af1_D[9] ), .afo2( af2_D[9] ), .afo3( af3_D[9] ),       .afi1( i2ss_sck         ), .afi1pi( i2ss_sck        .pi ), .afi2( spim_sd1_b[1]    ), .afi2pi( spim_sd1_b[1]  .pi  ), .afi3( pwm0[1] ));
afconn afc_D10(.afomask( afom_D[10] ), .afo1( af1_D[10] ), .afo2( af2_D[10] ), .afo3( af3_D[10] ),   .afi1( i2sm_sd          ), .afi1pi( i2sm_sd         .pi ), .afi2( spim_csn0_b[1]   ), .afi2pi( spim_csn0_b[1] .pi  ), .afi3( pwm0[2] ));
afconn afc_D11(.afomask( afom_D[11] ), .afo1( af1_D[11] ), .afo2( af2_D[11] ), .afo3( af3_D[11] ),   .afi1( i2sm_ws          ), .afi1pi( i2sm_ws         .pi ), .afi2( spim_csn1_b[1]   ), .afi2pi( spim_csn1_b[1] .pi  ), .afi3( pwm0[3] ));
afconn afc_D12(.afomask( afom_D[12] ), .afo1( af1_D[12] ), .afo2( af2_D[12] ), .afo3( af3_D[12] ),   .afi1( i2sm_sck         ), .afi1pi( i2sm_sck        .pi ), .afi2( spis_clk_a[1]    ), .afi2pi( spis_clk_a[1]  .pi  ), .afi3( afnc    ));
afconn afc_D13(.afomask( afom_D[13] ), .afo1( af1_D[13] ), .afo2( af2_D[13] ), .afo3( af3_D[13] ),   .afi1( uart_rx_a[1]     ), .afi1pi( uart_rx_a[1]    .pi ), .afi2( spis_csn_a[1]    ), .afi2pi( spis_csn_a[1]  .pi  ), .afi3( afnc    ));
afconn afc_D14(.afomask( afom_D[14] ), .afo1( af1_D[14] ), .afo2( af2_D[14] ), .afo3( af3_D[14] ),   .afi1( uart_tx_a[1]     ), .afi1pi( uart_tx_a[1]    .pi ), .afi2( spis_mosi_a[1]   ), .afi2pi( spis_mosi_a[1] .pi  ), .afi3( afnc    ));
afconn afc_D15(.afomask( afom_D[15] ), .afo1( af1_D[15] ), .afo2( af2_D[15] ), .afo3( af3_D[15] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( spis_miso_a[1]   ), .afi2pi( spis_miso_a[1] .pi  ), .afi3( afnc    ));
afconn afc_E00(.afomask( afom_E[0] ), .afo1( af1_E[0] ), .afo2( af2_E[0] ), .afo3( af3_E[0] ),       .afi1( spim_clk_b[0]    ), .afi1pi( spim_clk_b[0]   .pi ), .afi2( i2c_scl_b[1]     ), .afi2pi( i2c_scl_b[1]   .pi  ), .afi3( pwm1[0] ));
afconn afc_E01(.afomask( afom_E[1] ), .afo1( af1_E[1] ), .afo2( af2_E[1] ), .afo3( af3_E[1] ),       .afi1( spim_sd0_b[0]    ), .afi1pi( spim_sd0_b[0]   .pi ), .afi2( i2c_sda_b[1]     ), .afi2pi( i2c_sda_b[1]   .pi  ), .afi3( pwm1[1] ));
afconn afc_E02(.afomask( afom_E[2] ), .afo1( af1_E[2] ), .afo2( af2_E[2] ), .afo3( af3_E[2] ),       .afi1( spim_sd1_b[0]    ), .afi1pi( spim_sd1_b[0]   .pi ), .afi2( uart_rx_b[1]     ), .afi2pi( uart_rx_b[1]   .pi  ), .afi3( pwm1[2] ));
afconn afc_E03(.afomask( afom_E[3] ), .afo1( af1_E[3] ), .afo2( af2_E[3] ), .afo3( af3_E[3] ),       .afi1( spim_csn0_b[0]   ), .afi1pi( spim_csn0_b[0]  .pi ), .afi2( uart_tx_b[1]     ), .afi2pi( uart_tx_b[1]   .pi  ), .afi3( pwm1[3] ));
afconn afc_E04(.afomask( afom_E[4] ), .afo1( af1_E[4] ), .afo2( af2_E[4] ), .afo3( af3_E[4] ),       .afi1( uart_rx_a[3]     ), .afi1pi( uart_rx_a[3]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_E05(.afomask( afom_E[5] ), .afo1( af1_E[5] ), .afo2( af2_E[5] ), .afo3( af3_E[5] ),       .afi1( uart_tx_a[3]     ), .afi1pi( uart_tx_a[3]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_E06(.afomask( afom_E[6] ), .afo1( af1_E[6] ), .afo2( af2_E[6] ), .afo3( af3_E[6] ),       .afi1( spim_clk_a[3]    ), .afi1pi( spim_clk_a[3]   .pi ), .afi2( spis_clk_b[1]    ), .afi2pi( spis_clk_b[1]  .pi  ), .afi3( afnc    ));
afconn afc_E07(.afomask( afom_E[7] ), .afo1( af1_E[7] ), .afo2( af2_E[7] ), .afo3( af3_E[7] ),       .afi1( spim_sd0_a[3]    ), .afi1pi( spim_sd0_a[3]   .pi ), .afi2( spis_csn_b[1]    ), .afi2pi( spis_csn_b[1]  .pi  ), .afi3( afnc    ));
afconn afc_E08(.afomask( afom_E[8] ), .afo1( af1_E[8] ), .afo2( af2_E[8] ), .afo3( af3_E[8] ),       .afi1( spim_sd1_a[3]    ), .afi1pi( spim_sd1_a[3]   .pi ), .afi2( spis_mosi_b[1]   ), .afi2pi( spis_mosi_b[1] .pi  ), .afi3( afnc    ));
afconn afc_E09(.afomask( afom_E[9] ), .afo1( af1_E[9] ), .afo2( af2_E[9] ), .afo3( af3_E[9] ),       .afi1( spim_csn0_a[3]   ), .afi1pi( spim_csn0_a[3]  .pi ), .afi2( spis_miso_b[1]   ), .afi2pi( spis_miso_b[1] .pi  ), .afi3( afnc    ));
afconn afc_E10(.afomask( afom_E[10] ), .afo1( af1_E[10] ), .afo2( af2_E[10] ), .afo3( af3_E[10] ),   .afi1( spis_clk_a[0]    ), .afi1pi( spis_clk_a[0]   .pi ), .afi2( i2c_scl_a[2]     ), .afi2pi( i2c_scl_a[2]   .pi  ), .afi3( pwm3[0] ));
afconn afc_E11(.afomask( afom_E[11] ), .afo1( af1_E[11] ), .afo2( af2_E[11] ), .afo3( af3_E[11] ),   .afi1( spis_csn_a[0]    ), .afi1pi( spis_csn_a[0]   .pi ), .afi2( i2c_sda_a[2]     ), .afi2pi( i2c_sda_a[2]   .pi  ), .afi3( pwm3[1] ));
afconn afc_E12(.afomask( afom_E[12] ), .afo1( af1_E[12] ), .afo2( af2_E[12] ), .afo3( af3_E[12] ),   .afi1( spis_mosi_a[0]   ), .afi1pi( spis_mosi_a[0]  .pi ), .afi2( uart_rx_a[2]     ), .afi2pi( uart_rx_a[2]   .pi  ), .afi3( pwm3[2] ));
afconn afc_E13(.afomask( afom_E[13] ), .afo1( af1_E[13] ), .afo2( af2_E[13] ), .afo3( af3_E[13] ),   .afi1( spis_miso_a[0]   ), .afi1pi( spis_miso_a[0]  .pi ), .afi2( uart_tx_a[2]     ), .afi2pi( uart_tx_a[2]   .pi  ), .afi3( pwm3[3] ));
afconn afc_E14(.afomask( afom_E[14] ), .afo1( af1_E[14] ), .afo2( af2_E[14] ), .afo3( af3_E[14] ),   .afi1( i2c_scl_a[3]     ), .afi1pi( i2c_scl_a[3]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_E15(.afomask( afom_E[15] ), .afo1( af1_E[15] ), .afo2( af2_E[15] ), .afo3( af3_E[15] ),   .afi1( i2c_sda_a[3]     ), .afi1pi( i2c_sda_a[3]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F00(.afomask( afom_F[0] ), .afo1( af1_F[0] ), .afo2( af2_F[0] ), .afo3( af3_F[0] ),       .afi1( uart_rx_b[3]     ), .afi1pi( uart_rx_b[3]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F01(.afomask( afom_F[1] ), .afo1( af1_F[1] ), .afo2( af2_F[1] ), .afo3( af3_F[1] ),       .afi1( uart_tx_b[3]     ), .afi1pi( uart_tx_b[3]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F02(.afomask( afom_F[2] ), .afo1( af1_F[2] ), .afo2( af2_F[2] ), .afo3( af3_F[2] ),       .afi1( i2c_scl_b[2]     ), .afi1pi( i2c_scl_b[2]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F03(.afomask( afom_F[3] ), .afo1( af1_F[3] ), .afo2( af2_F[3] ), .afo3( af3_F[3] ),       .afi1( i2c_sda_b[2]     ), .afi1pi( i2c_sda_b[2]    .pi ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F04(.afomask( afom_F[4] ), .afo1( af1_F[4] ), .afo2( af2_F[4] ), .afo3( af3_F[4] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F05(.afomask( afom_F[5] ), .afo1( af1_F[5] ), .afo2( af2_F[5] ), .afo3( af3_F[5] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F06(.afomask( afom_F[6] ), .afo1( af1_F[6] ), .afo2( af2_F[6] ), .afo3( af3_F[6] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F07(.afomask( afom_F[7] ), .afo1( af1_F[7] ), .afo2( af2_F[7] ), .afo3( af3_F[7] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F08(.afomask( afom_F[8] ), .afo1( af1_F[8] ), .afo2( af2_F[8] ), .afo3( af3_F[8] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F09(.afomask( afom_F[9] ), .afo1( af1_F[9] ), .afo2( af2_F[9] ), .afo3( af3_F[9] ),       .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F10(.afomask( afom_F[10] ), .afo1( af1_F[10] ), .afo2( af2_F[10] ), .afo3( af3_F[10] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F11(.afomask( afom_F[11] ), .afo1( af1_F[11] ), .afo2( af2_F[11] ), .afo3( af3_F[11] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F12(.afomask( afom_F[12] ), .afo1( af1_F[12] ), .afo2( af2_F[12] ), .afo3( af3_F[12] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F13(.afomask( afom_F[13] ), .afo1( af1_F[13] ), .afo2( af2_F[13] ), .afo3( af3_F[13] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F14(.afomask( afom_F[14] ), .afo1( af1_F[14] ), .afo2( af2_F[14] ), .afo3( af3_F[14] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));
afconn afc_F15(.afomask( afom_F[15] ), .afo1( af1_F[15] ), .afo2( af2_F[15] ), .afo3( af3_F[15] ),   .afi1( afnc             ), .afi1pi(                     ), .afi2( afnc             ), .afi2pi(                     ), .afi3( afnc    ));

    end
endgenerate

endmodule

module afconn (
    output logic [3:0] afomask,
    ioif.loadin afi1,
    ioif.loadin afi2,
    ioif.loadin afi3,
    output logic afi1pi,
    output logic afi2pi,
    ioif.drive  afo1,
    ioif.drive  afo2,
    ioif.drive  afo3
);

// pu signal is used for indicating the af is connected.
// the real pu is set by the sw setting the iox's sfr.
    assign afomask[0] = '1;
    assign afomask[1] = afi1.pu;
    assign afomask[2] = afi2.pu;
    assign afomask[3] = afi3.pu;

    assign afo1.po = afi1.po;
    assign afo1.oe = afi1.oe;
    assign afo1.pu = afi1.pu;
    assign afi1pi  = afo1.pi;

    assign afo2.po = afi2.po;
    assign afo2.oe = afi2.oe;
    assign afo2.pu = afi2.pu;
    assign afi2pi  = afo2.pi;

    assign afo3.po = afi3.po;
    assign afo3.oe = afi3.oe;
    assign afo3.pu = afi3.pu;
//    assign afi3.pi = afo3.pi;  // af3 are all pmw, no input, so pi is NC.

endmodule

module ioxdulp #( parameter IOC = 8 )
(
    ioif.load di[IOC-1:0],
    ioif.drive doa[IOC-1:0],
    ioif.drive dob[IOC-1:0]
);
generate
    for (genvar i = 0; i < IOC; i++) begin
    assign { doa[i].po, doa[i].oe, doa[i].pu } = { di[i].po, di[i].oe, di[i].pu } ;
    assign { dob[i].po, dob[i].oe, dob[i].pu } = { di[i].po, di[i].oe, di[i].pu } ;
    assign di[i].pi = doa[i].pi & dob[i].pi;
    end
endgenerate

endmodule

module ionc ( ioif.drive iodrv );
assign iodrv.po = 0;
assign iodrv.oe = 0;
assign iodrv.pu = 0;
endmodule

module ionc_pio ( ioif.drive iodrv );
assign iodrv.po = 0;
assign iodrv.oe = 0;
assign iodrv.pu = 1;
endmodule

module piomux16 (
    input logic [0:15] piosel,
    ioif.load gpio16[0:15],
    ioif.load pio16[0:15],
    ioif.drive gpio16mux[0:15]
);

    generate
        for (genvar i = 0; i < 16 ; i++) begin
            assign gpio16mux[i].pu = gpio16[i].pu;
            assign gpio16mux[i].po = piosel[i] ? pio16[i].po : gpio16[i].po;
            assign gpio16mux[i].oe = piosel[i] ? pio16[i].oe : gpio16[i].oe;
            assign gpio16[i].pi = gpio16mux[i].pi;
            assign pio16[i].pi = piosel[i] & gpio16mux[i].pi;
        end
    endgenerate

endmodule


module dummy_soc_ifsub #(
    parameter IOC = 16*6,
    parameter EVCNT = 128,
    parameter ERRCNT = 1,
    parameter IRQCNT = daric_cfg::IRQCNT-16
)(
    input logic                 clk,
    input logic                 pclk,
    input logic                 pclken,
    input logic                 clk48m,
//    input logic                 clkao25m,
    input logic                 resetn,
    input logic                 perclk,
    input logic                 cmsatpg,
    input logic                 cmsbist,
    input logic                 clksys,
    input logic                 ioxlock,
    input logic                 fclk,
    input logic                 hclk,
    input logic                 clkdma,clkudc,clkbiogate,

    input  logic                ifev_vld,
    input  logic [7:0]          ifev_dat,
    output logic                ifev_rdy,

    output logic                wkupvld, wkupvld_async,
    output logic [EVCNT-1:0]    ifsubevo,
    output logic [ERRCNT-1:0]   ifsuberro,
    input  logic [IRQCNT-1:0]   cm7_irq,

    `UTMI_IF_DEF
    input logic dummy
);
    ahbif                 ahbs(), bdma_ahb32(), ahbaoram();
    axiif                 bdma_axi32();
    apbif                 apbudp();
    ioif                  iopad[0:IOC-1]();
    ioif                  sddc_clk();
    ioif                  sddc_cmd();
    ioif                  sddc_dat0();
    ioif                  sddc_dat1();
    ioif                  sddc_dat2();
    ioif                  sddc_dat3();
    padcfg_arm_t  iocfg[0:IOC-1];
    wire [3:0] ana_adcsrc;
    logic                 iframeven;

    rbif #(.AW(10   ),      .DW(32))    rbif_bioram1kx32    [0:3]   ();
    rbif #(.AW(15   ),      .DW(36))    rbif_ifram32kx36    [0:1]   ();
    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_share   [0:0]  ();
    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_odb     [0:0]  ();
    rbif #(.AW(8    ),      .DW(64))    rbif_udcmem_256x64  [0:0]  ();

    soc_ifsub u(.*);

endmodule
