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

//`include "io_interface_def_v0.1.sv"
import pad_pkg::*;
//`include "rtl/model/artisan_ram_def_v0.1.svh"

module qfc #(
    parameter QFC_SSCNT = 2,
    parameter QFC_SIOCNT = 8,
    parameter TX_FIFO_DEPTH  = 8'd128,
    parameter RX_FIFO_DEPTH  = 8'd128,
    parameter CMD_FIFO_DEPTH = 8'd32,
    parameter XAW = 29
    )(

    input logic qfc_en,
    input bit   clk,
    input bit   pclk,
    input bit   resetn,
    input bit   cmsatpg,
    input bit   cmsbist,
    rbif.slavedp rbif_tx_fifo128x32    ,
    rbif.slavedp rbif_rx_fifo128x32    ,
    rbif.slavedp rbif_fifo32x19        ,

    axiif.slave     axis,
    apbif.slavein   apbs,
    apbif.slave     apbx,

    ioif.drive qfc_sck,
    ioif.drive qfc_sckn,
    ioif.drive qfc_dqs,
    ioif.drive qfc_ss[QFC_SSCNT-1:0],
    ioif.drive qfc_sio[QFC_SIOCNT-1:0],
    //ioif.drive qfc_miso,
//    ioif.drive qfc_rwds, // null
    ioif.drive qfc_rstm[QFC_SSCNT-1:0],
    ioif.drive qfc_rsts[QFC_SSCNT-1:0],
    ioif.drive qfc_int,

    output padcfg_arm_t  padcfg_qfc_sck,
    output padcfg_arm_t  padcfg_qfc_qds,
    output padcfg_arm_t  padcfg_qfc_ss,
    output padcfg_arm_t  padcfg_qfc_sio,
//    output padcfg_arm_t  padcfg_qfc_rwds, // null
    output padcfg_arm_t  padcfg_qfc_int,
    output padcfg_arm_t  padcfg_qfc_rst,

    output logic irq

);

//  io interface
//  ====
//

    logic o_spi_sck, i_spi_dqs, i_spi_rwds;
    logic [7:0] o_spi_mosi_en, i_spi_miso, o_spi_mosi, o_spi_ss;
    logic qfcio_pu_sck, qfcio_pu_dqs, qfcio_pu_ss, qfcio_pu_sio, qfcio_enable;
    logic [31:0] apbx_prdata1;

    logic        o_spi_dm     ;
    logic        o_spi_dm_en  ;
    logic        o_spi_sck_n  ;
    logic [7:0]  o_spi_reset  ;
    logic        i_spi_int    ;
    logic [7:0]  i_spi_reset  ;

    logic qfcio_pu_rstm;
    logic qfcio_pu_rsts;
    logic qfcio_pu_int;

    assign qfc_sck.pu = qfcio_pu_sck;
    assign qfc_sckn.pu = qfcio_pu_sck;
    assign qfc_dqs.pu = qfcio_pu_dqs;

    assign qfc_sck.oe = qfcio_enable & qfc_en;
    assign qfc_sck.po = o_spi_sck;
    assign qfc_sckn.oe = qfcio_enable & qfc_en;
    assign qfc_sckn.po = o_spi_sck_n;

    assign qfc_dqs.oe = o_spi_dm_en & qfc_en;
    assign qfc_dqs.po = o_spi_dm;
    assign i_spi_dqs = qfc_dqs.pi;
    assign i_spi_rwds = qfc_dqs.pi;

//    assign qfc_rwds.oe = '0;
//    assign qfc_rwds.po = '0;
//    assign qfc_rwds.pu = '1;

    generate
        for (genvar i = 0; i < 8; i++) begin:gi
            if( i < QFC_SIOCNT )begin:gsio
                assign qfc_sio[i].pu = qfcio_pu_sio;
                assign qfc_sio[i].oe = qfcio_enable & o_spi_mosi_en[i];
                assign qfc_sio[i].po = o_spi_mosi[i];
                assign i_spi_miso[i] = qfc_sio[i].pi;
            end
            else begin:gsio_null
                assign i_spi_miso[i] = '1;
            end
            if( i < QFC_SSCNT )begin:gpad
                assign qfc_ss[i].oe = qfcio_enable;
                assign qfc_ss[i].pu = qfcio_pu_ss;
                assign qfc_ss[i].po = o_spi_ss[i];
                assign qfc_rstm[i].oe = qfcio_enable;
                assign qfc_rstm[i].pu = qfcio_pu_rstm;
                assign qfc_rstm[i].po = o_spi_reset[i];
                assign qfc_rsts[i].oe = '0;
                assign qfc_rsts[i].pu = qfcio_pu_rsts;
                assign qfc_rsts[i].po = '0;
                assign i_spi_reset[i] = qfc_rsts[i].pi;
            end
            else begin:gpad_null
                assign i_spi_reset[i] = '1;
            end
        end
    endgenerate

    assign qfc_int.oe  = '0;
    assign qfc_int.pu  = qfcio_pu_int;
    assign qfc_int.po  = '0;
    assign i_spi_int   = qfc_int.pi;

    bit [5:0][1:0] paddrvsel;

    assign padcfg_qfc_sck  = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:paddrvsel[0] };
    assign padcfg_qfc_qds  = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:paddrvsel[1] };
    assign padcfg_qfc_ss   = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:paddrvsel[2] };
    assign padcfg_qfc_sio  = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:paddrvsel[3] };
//    assign padcfg_qfc_rwds = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:paddrvsel[4] }; // null, useless
    assign padcfg_qfc_int  = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:paddrvsel[4] };
    assign padcfg_qfc_rst  = '{schmsel:'0, anamode:'0, slewslow:'0, drvsel:paddrvsel[5] };


//  sfr
//  ====
//
    logic qfcresetn;
//    logic apbrd, apbwr;
    logic apbx_pready1, apbx_pslverr1;
    logic apbx_psel1;
    logic sfrlock;
    logic sdioresetn;
    logic arreset;
    logic [1:0] ahbs_hresp2;
    bit [7:0] cr_io;
    bit [31:0] cfg_xip_opcode;
    bit [7:0]  cfg_xip_rd_opcode, cfg_xip_rd_opcode_ext, cfg_xip_wr_opcode, cfg_xip_wr_opcode_ext;
    bit [1:0]  cfg_xip_addr_mode;
    bit [5:0]  cfg_xip_width;
    bit [6:0]  cfg_xip_ssel;
    bit [7:0]  cfg_xip_rd_dummy_cycs, cfg_xip_wr_dummy_cycs;
    bit [15:0] cfg_xip_dumcyc;
    bit cfg_xip_clk_phase, cfg_xip_lsb_first, cfg_xip_side_band;
    bit [2:0] cfg_xip_ddr_mode;
    bit [7:0] cfg_xip_prescaler;
    bit [14:0] cfg_xip_cfg;
    bit cfg_xip_clk_polarity;
    bit [127:0] aeskeyin;
    bit aesena;

    `theregrn( sfrlock ) <= '0;

//    `apbs_common;
    assign apbx.pready = apbx_psel1 ? apbx_pready1 : 1'b1;
    assign apbx.pslverr = apbx_psel1 ? apbx_pslverr1 : 1'b0;
//    assign apbrd = apbs.psel & apbs.penable & ~apbs.pwrite;
//    assign apbwr = apbs.psel & apbs.penable & apbs.pwrite
    assign apbx.prdata = '0
                        | sfr_io.prdata32 | sfr_iodrv.prdata32
                        | cr_xip_addrmode.prdata32 | cr_xip_opcode.prdata32
                        | cr_xip_width.prdata32 | cr_xip_ssel.prdata32 | cr_xip_dumcyc.prdata32 | cr_xip_cfg.prdata32
                        | cr_aesena.prdata32
                        | apbx_prdata1
                        ;

    apb_cr #(.A('h00), .DW(8), .IV('hFE))          sfr_io          (.cr(cr_io), .prdata32(),.*);
    apb_ar #(.A('h04), .AR(32'h5a))     sfr_ar           (.ar(arreset),.*);
    apb_cr #(.A('h08), .DW(12))         sfr_iodrv        (.cr(paddrvsel),.prdata32(),.*);

    apb_cr #(.A('h10), .DW( 2))         cr_xip_addrmode (.cr(cfg_xip_addr_mode), .prdata32(),.*);
    apb_cr #(.A('h14), .DW(32))         cr_xip_opcode   (.cr(cfg_xip_opcode), .prdata32(),.*);
    apb_cr #(.A('h18), .DW( 6))         cr_xip_width    (.cr(cfg_xip_width), .prdata32(),.*);
    apb_cr #(.A('h1C), .DW( 7))         cr_xip_ssel     (.cr(cfg_xip_ssel), .prdata32(),.*);
    apb_cr #(.A('h20), .DW(16))         cr_xip_dumcyc   (.cr(cfg_xip_dumcyc), .prdata32(),.*);
    apb_cr #(.A('h24), .DW(15))         cr_xip_cfg      (.cr(cfg_xip_cfg), .prdata32(),.*);

    apb_cr #(.A('h40), .DW(32), .SFRCNT(4)) cr_aeskey      (.cr(aeskeyin), .prdata32(),.*);
    apb_cr #(.A('h50), .DW(1))              cr_aesena      (.cr(aesena), .prdata32(),.*);

assign { qfcio_pu_rstm, qfcio_pu_rsts, qfcio_pu_int, qfcio_pu_sck, qfcio_pu_dqs, qfcio_pu_ss, qfcio_pu_sio, qfcio_enable } = cr_io;
assign { cfg_xip_rd_opcode, cfg_xip_rd_opcode_ext, cfg_xip_wr_opcode, cfg_xip_wr_opcode_ext } = cfg_xip_opcode;
assign { cfg_xip_rd_dummy_cycs, cfg_xip_wr_dummy_cycs } = cfg_xip_dumcyc;
assign { cfg_xip_clk_polarity, cfg_xip_clk_phase, cfg_xip_lsb_first, cfg_xip_side_band, cfg_xip_ddr_mode, cfg_xip_prescaler } = cfg_xip_cfg;

    bit cfg_boot_enable = '0;
    bit [7:0] cfg_boot_dummy_cycs = '0;
    bit [2:0] cfg_boot_width = '0;
    bit [6:0] cfg_boot_ssel = '0;
    bit [7:0] cfg_boot_prescaler = '0;
    bit cfg_boot_clk_phase = '0;
    bit cfg_boot_lsb_first = '0;
    bit [31:0] cfg_boot_size = '0;
    bit cfg_boot_ddr_mode = '0;
    bit cfg_boot_side_band = '0;
    bit [31:0] cfg_boot_dst_addr = '0;

// reset

    logic qfcresetn_undft;

    scresetgen #(.ICNT(1),.EXTCNT(16))sdresetgen(
        .clk         ( clk ),
        .cmsatpg     ( cmsatpg ),
        .resetn      ( resetn ),
        .resetnin    ( ~arreset ),
        .resetnout   ( qfcresetn_undft )
    );

    assign qfcresetn = cmsatpg ? resetn : qfcresetn_undft;

//  axi
//  ====
//
    axiif #(.AW(XAW), .DW(64), .IDW(4)) axix();
//  aes
//  ====
//

    qfc_aes aes(
        .clk,
        .resetn,
        .axis   (axis),
        .axim   (axix)
    );

//  inst
//  ====
//

    logic [3:0] axix_bid4, axix_rid4, axix_awlen, axix_arlen;
    assign apbx_prdata1 = apbx_psel1 ? u.o_apb_slv_rdata : 0;
    assign apbx_psel1 = apbx.psel & (apbx.paddr[11:9]=='h1);

    logic [3:0] axix_awid4, axix_arid4, axix_wid4;
    logic [63:0] axix_awaddr64, axix_araddr64;

    assign axix_awid4 = axix.awid[3:0] | 4'h0;
    assign axix_awaddr64 = axix.awaddr[XAW-1:0] | 64'h0;
    assign axix_arid4 = axix.arid[3:0] | 4'h0;
    assign axix_araddr64 = axix.araddr[XAW-1:0] | 64'h0;
    assign axix_wid4 = axix.wid[3:0] | 4'h0;


  sdvt_spi_master_core  #(.TX_FIFO_DEPTH(TX_FIFO_DEPTH),.RX_FIFO_DEPTH(RX_FIFO_DEPTH),.CMD_FIFO_DEPTH(CMD_FIFO_DEPTH))u (
/*
    .cmsatpg                       (cmsatpg                     ),
    .cmsbist                       (cmsbist                     ),
    .i_clk                         (clk                         ),
    .i_dma_clk                     (hclk                        ),

    .i_rst_n                       (qfcresetn                   ),
    .i_dma_rst_n                   (qfcresetn                   ),

    .o_spi_sck                     (o_spi_sck                     ),
    .o_spi_mosi                    (o_spi_mosi                    ),
    .o_spi_mosi_en                 (o_spi_mosi_en                 ),
    .i_spi_miso                    (i_spi_miso                    ),
    .o_spi_ss                      (o_spi_ss                      ),
    .i_spi_dqs                     (i_spi_dqs                     ),

    .i_cfg_xip_addr_mode           (cfg_xip_addr_mode            ),
    .i_cfg_xip_rd_opcode           (cfg_xip_rd_opcode            ),
    .i_cfg_xip_rd_opcode_ext       (cfg_xip_rd_opcode_ext        ),
    .i_cfg_xip_wr_opcode           (cfg_xip_wr_opcode            ),
    .i_cfg_xip_wr_opcode_ext       (cfg_xip_wr_opcode_ext        ),
    .i_cfg_xip_width               (cfg_xip_width                ),
    .i_cfg_xip_ssel                (cfg_xip_ssel                 ),
    .i_cfg_xip_wr_dummy_cycs       (cfg_xip_wr_dummy_cycs        ),
    .i_cfg_xip_rd_dummy_cycs       (cfg_xip_rd_dummy_cycs        ),
    .i_cfg_xip_prescaler           (cfg_xip_prescaler            ),
    .i_cfg_xip_clk_phase           (cfg_xip_clk_phase            ),
    .i_cfg_xip_lsb_first           (cfg_xip_lsb_first            ),
    .i_cfg_xip_side_band           (cfg_xip_side_band            ),
    .i_cfg_xip_ddr_mode            (cfg_xip_ddr_mode             ),
    .i_cfg_boot_enable             (cfg_boot_enable              ),
    .i_cfg_boot_dummy_cycs         (cfg_boot_dummy_cycs          ),
    .i_cfg_boot_width              (cfg_boot_width               ),
    .i_cfg_boot_ssel               (cfg_boot_ssel                ),
    .i_cfg_boot_prescaler          (cfg_boot_prescaler           ),
    .i_cfg_boot_clk_phase          (cfg_boot_clk_phase           ),
    .i_cfg_boot_lsb_first          (cfg_boot_lsb_first           ),
    .i_cfg_boot_size               (cfg_boot_size                ),
    .i_cfg_boot_ddr_mode           (cfg_boot_ddr_mode            ),
    .i_cfg_boot_side_band          (cfg_boot_side_band           ),
    .i_cfg_boot_dst_addr           (cfg_boot_dst_addr            ),

    .i_scan_rst                    (i_scan_rst                    ),
    .i_scan_clk                    (i_scan_clk                    ),
    .i_scan_mode                   (i_scan_mode                   ),
    .i_scan_in                     (i_scan_in                     ),
    .o_scan_out                    (o_scan_out                    ),

    .i_apb_slv_addr                ( apbx.paddr[8:0]              ),
    .i_apb_slv_wdata               ( apbx.pwdata                  ),
    .o_apb_slv_rdata               ( apbx.prdata                  ),
    .i_apb_slv_sel                 ( apbx.psel & apbx.paddr[9]    ),
    .i_apb_slv_enable              ( apbx.penable                 ),
    .i_apb_slv_write               ( apbx.pwrite                  ),
    .o_apb_slv_ready               ( apbx.pready                  ),
    .o_apb_slv_err                 ( apbx.pslverr                 ),

    .o_irq                         ( irq                          ),

    .i_ahb_slv_addr                ( ahbs.haddr                   ),##
    .i_ahb_slv_trans               ( ahbs.htrans                  ),
    .i_ahb_slv_write               ( ahbs.hwrite                  ),
    .i_ahb_slv_burst               ( ahbs.hburst                  ),
    .i_ahb_slv_size                ( ahbs.hsize                   ),
    .i_ahb_slv_wdata               ( ahbs.hwdata                  ),
    .i_ahb_slv_sel                 ( ahbs.hsel                    ),
    .i_ahb_slv_ready               ( ahbs.hready                  ),
    .o_ahb_slv_rdata               ( ahbs.hrdata                  ),
    .o_ahb_slv_ready               ( ahbs.hready                  ),
    .o_ahb_slv_resp                ( ahbs_hresp2                  ),

    .o_ahb_mst_addr                ( ahbm.haddr                   ),
    .o_ahb_mst_trans               ( ahbm.htrans                  ),
    .o_ahb_mst_write               ( ahbm.hwrite                  ),
    .o_ahb_mst_size                ( ahbm.hsize                   ),
    .o_ahb_mst_burst               ( ahbm.hburst                  ),
    .o_ahb_mst_prot                ( ahbm.hprot                   ),
    .o_ahb_mst_wdata               ( ahbm.hwdata                  ),
    .o_ahb_mst_busreq              (                              ),
    .o_ahb_mst_lock                ( ahbm.hmasterlock             ),
    .i_ahb_mst_rdata               ( ahbm.hrdata                  ),
    .i_ahb_mst_ready               ( ahbm.hready                  ),
    .i_ahb_mst_resp                ( ahbm.hresp | 2'h0            ),
    .i_ahb_mst_grant               ( '1                           )
*/
    .cmsatpg                       (cmsatpg                     ),
    .cmsbist                       (cmsbist                     ),
    .rbif_tx_fifo128x32,
    .rbif_rx_fifo128x32,
    .rbif_fifo32x19    ,
    .aesena,
    .aeskeyin,

/*  input     wire          */ .i_clk                        (clk), // System clock input
/*  input     wire          */ .i_rst_n                      (qfcresetn), // Active low system reset input
/*  output    wire          */ .o_spi_sck                    ( o_spi_sck     ), // SPI - Serial clock to Slave
/*  output    wire   [7:0]  */ .o_spi_mosi                   ( o_spi_mosi    ), // SPI - Serial output data from Master to Slave
/*  output    wire   [7:0]  */ .o_spi_mosi_en                ( o_spi_mosi_en ), // SPI - Serial output data enable
/*  input     wire   [7:0]  */ .i_spi_miso                   ( i_spi_miso    ), // SPI - Serial input data from Slave to Master
/*  output    wire   [7:0]  */ .o_spi_ss                     ( o_spi_ss      ), // SPI - Slave enable
/*  input     wire          */ .i_spi_dqs                    ( i_spi_dqs     ), // SPI - Data strobe signal for read
/*  output    wire          */ .o_spi_dm                     ( o_spi_dm      ), // SPI - Data Mask output
/*  output    wire          */ .o_spi_dm_en                  ( o_spi_dm_en   ), // SPI - Data Mask output enable
/*  output    wire          */ .o_spi_sck_n                  ( o_spi_sck_n   ), // SPI - Inverted serial clock output
/*  output    wire   [7:0]  */ .o_spi_reset                  ( o_spi_reset   ), // SPI - Reset signal to Slave
/*  input     wire          */ .i_spi_int                    ( i_spi_int     ), // SPI - Slave interrupt
/*  input     wire   [7:0]  */ .i_spi_reset                  ( i_spi_reset   ), // SPI - Reset from Slave to Master
/*  input     wire   [1:0]  */ .i_cfg_xip_addr_mode          ( cfg_xip_addr_mode        ), // CFG - XIP - Address mode 0 - 8 bits, 1 - 16 bits, 2 - 24 bits, 3 - 32 bits
/*  input     wire   [7:0]  */ .i_cfg_xip_rd_opcode          ( cfg_xip_rd_opcode        ), // CFG - XIP - Read opcode (instruction)
/*  input     wire   [7:0]  */ .i_cfg_xip_rd_opcode_ext      ( cfg_xip_rd_opcode_ext    ), // CFG - XIP - Read opcode (instruction) Extension Byte
/*  input     wire   [7:0]  */ .i_cfg_xip_wr_opcode          ( cfg_xip_wr_opcode        ), // CFG - XIP - Write opcode (instruction)
/*  input     wire   [7:0]  */ .i_cfg_xip_wr_opcode_ext      ( cfg_xip_wr_opcode_ext    ), // CFG - XIP - Write opcode (instruction) Extension Byte
/*  input     wire   [5:0]  */ .i_cfg_xip_width              ( cfg_xip_width            ), // CFG - XIP - Width 0 - 1 bit, 1 - 2 bits, 2 - 4 bits, 3 - 8 bits
/*  input     wire   [6:0]  */ .i_cfg_xip_ssel               ( cfg_xip_ssel             ), // CFG - XIP - Slave select
/*  input     wire   [7:0]  */ .i_cfg_xip_wr_dummy_cycs      ( cfg_xip_wr_dummy_cycs    ), // CFG - XIP - Write Dummy cycles after address phase
/*  input     wire   [7:0]  */ .i_cfg_xip_rd_dummy_cycs      ( cfg_xip_rd_dummy_cycs    ), // CFG - XIP - Read Dummy cycles after address phase
/*  input     wire   [7:0]  */ .i_cfg_xip_prescaler          ( cfg_xip_prescaler        ), // CFG - XIP - Prescaler
/*  input     wire          */ .i_cfg_xip_clk_phase          ( cfg_xip_clk_phase        ), // CFG - XIP - SPI clock phase
/*  input     wire          */ .i_cfg_xip_lsb_first          ( cfg_xip_lsb_first        ), // CFG - XIP - LSB first control
/*  input     wire          */ .i_cfg_xip_side_band          ( cfg_xip_side_band        ), // CFG - XIP - Side Band for Read and Write data DS
/*  input     wire   [2:0]  */ .i_cfg_xip_ddr_mode           ( cfg_xip_ddr_mode         ), // CFG - XIP - Mode of transfer as STR (3'b000 S-S-S) or DTR (3'b111 D-D-D)
//                             .i_cfg_xip_clk_polarity       ( cfg_xip_clk_polarity     ), // liza,deleted in 1218 version IP.
/*  input     wire          */ .i_scan_rst                   (qfcresetn), // DFT - Scan reset
/*  input     wire          */ .i_scan_clk                   (clk), // DFT - Scan clock
/*  input     wire          */ .i_scan_mode                  (cmsatpg), // DFT - Scan Mode
/*  input     wire          */ .i_scan_in                    (1'b0), // DFT - Scan serial data in
/*  output    wire          */ .o_scan_out                   (), // DFT - Scan serial data out
/*  input     wire   [8:0]  */ .i_apb_slv_addr               ( apbx.paddr[8:0]), // APB Slave Bus - External interface address input
/*  input     wire   [31:0] */ .i_apb_slv_wdata              ( apbx.pwdata    ), // APB Slave Bus - External interface write data input
/*  output    wire   [31:0] */ .o_apb_slv_rdata              (     ), // APB Slave Bus - External interface Read data output
/*  input     wire          */ .i_apb_slv_sel                ( apbx_psel1     ), // APB Slave Bus - External interface transfer type input
/*  input     wire          */ .i_apb_slv_enable             ( apbx.penable   ), // APB Slave Bus - External interface enable control input
/*  input     wire          */ .i_apb_slv_write              ( apbx.pwrite    ), // APB Slave Bus - External interface read/write control input
/*  output    wire          */ .o_apb_slv_ready              ( apbx_pready1    ), // APB Slave Bus - External interface Ready output
/*  output    wire          */ .o_apb_slv_err                ( apbx_pslverr1   ), // APB Slave Bus - External interface Slave error output
/*  output    wire          */ .o_irq                        ( irq ), // IRQ SOC - interrupt output
/*  input     wire   [3:0]  */ .i_axi_slv_awid               ( axix_awid4    ), // AXI Slave Bus - External Interface - Write Address ID Tag to AXI Slave
/*  input     wire   [63:0] */ .i_axi_slv_awaddr             ( axix_awaddr64  ), // AXI Slave Bus - External Interface - Write Address to AXI Slave
/*  input     wire   [3:0]  */ .i_axi_slv_awlen              ( axix_awlen[3:0]    ), // AXI Slave Bus - External Interface - Write Transfer Length to AXI Slave
/*  input     wire   [2:0]  */ .i_axi_slv_awsize             ( axix.awsize   ), // AXI Slave Bus - External Interface - Write Transfer Size to AXI Slave
/*  input     wire   [1:0]  */ .i_axi_slv_awburst            ( axix.awburst  ), // AXI Slave Bus - External Interface - Write Transfer Burst Type to AXI Slave
/*  input     wire   [3:0]  */ .i_axi_slv_awqos              ( 4'h0   ), // AXI Slave Bus - External Interface - Write Address/Control QOS to AXI Slave
/*  input     wire          */ .i_axi_slv_awvalid            ( axix.awvalid  ), // AXI Slave Bus - External Interface - Write Address/Control Valid Indication to AXI Slave
/*  output    wire          */ .o_axi_slv_awready            ( axix.awready  ), // AXI Slave Bus - External Interface - Write Address/Control Ready Indication from AXI Slave

/*  input     wire   [3:0]  */ .i_axi_slv_wid                ( axix_awid4    ), // AXI Slave Bus - External Interface - Write Data ID Tag to AXI Slave
/*  input     wire   [63:0] */ .i_axi_slv_wdata              ( axix.wdata    ), // AXI Slave Bus - External Interface - Write Data to AXI Slave
/*  input     wire   [7:0]  */ .i_axi_slv_wstrb              ( axix.wstrb    ), // AXI Slave Bus - External Interface - Write Data Strobe to AXI Slave
/*  input     wire          */ .i_axi_slv_wlast              ( axix.wlast    ), // AXI Slave Bus - External Interface - Write Data Last Indication to AXI Slave
/*  input     wire          */ .i_axi_slv_wvalid             ( axix.wvalid   ), // AXI Slave Bus - External Interface - Write Data Valid Indication to AXI Slave
/*  output    wire          */ .o_axi_slv_wready             ( axix.wready   ), // AXI Slave Bus - External Interface - Write Data Ready Indication from AXI Slave

/*  input     wire          */ .i_axi_slv_bready             ( axix.bready   ), // AXI Slave Bus - External Interface - Write Response Ready Indication to AXI Slave
/*  output    wire          */ .o_axi_slv_bvalid             ( axix.bvalid   ), // AXI Slave Bus - External Interface - Write Reaponse Valid Indication from AXI Slave
/*  output    wire   [3:0]  */ .o_axi_slv_bid                ( axix_bid4     ), // AXI Slave Bus - External Interface - Write Response ID from AXI Slave
/*  output    wire   [1:0]  */ .o_axi_slv_bresp              ( axix.bresp    ), // AXI Slave Bus - External Interface - Write Response from AXI Slave

/*  input     wire   [3:0]  */ .i_axi_slv_arid               ( axix_arid4   ), // AXI Slave Bus - External Interface - Read Address ID Tag to AXI Slave
/*  input     wire   [63:0] */ .i_axi_slv_araddr             ( axix_araddr64   ), // AXI Slave Bus - External Interface - Read Address to AXI Slave
/*  input     wire   [3:0]  */ .i_axi_slv_arlen              ( axix_arlen[3:0]   ), // AXI Slave Bus - External Interface - Read Transfer Length to AXI Slave
/*  input     wire   [2:0]  */ .i_axi_slv_arsize             ( axix.arsize   ), // AXI Slave Bus - External Interface - Read Transfer Size to AXI Slave
/*  input     wire   [1:0]  */ .i_axi_slv_arburst            ( axix.arburst  ), // AXI Slave Bus - External Interface - Read Transfer Burst Type to AXI Slave
/*  input     wire   [3:0]  */ .i_axi_slv_arqos              ( 4'h0    ), // AXI Slave Bus - External Interface - Read Address/Control QOS to AXI Slave
/*  input     wire          */ .i_axi_slv_arvalid            ( axix.arvalid  ), // AXI Slave Bus - External Interface - Read Address/Control Valid Indication to AXI Slave
/*  output    wire          */ .o_axi_slv_arready            ( axix.arready  ), // AXI Slave Bus - External Interface - Read Address/Control Ready Indication from AXI Slave

/*  input     wire          */ .i_axi_slv_rready             ( axix.rready   ), // AXI Slave Bus - External Interface - Read Data/Response Ready Indication to AXI Slave
/*  output    wire   [3:0]  */ .o_axi_slv_rid                ( axix_rid4[3:0]     ), // AXI Slave Bus - External Interface - Read Data ID Tag length from AXI Slave
/*  output    wire   [63:0] */ .o_axi_slv_rdata              ( axix.rdata    ), // AXI Slave Bus - External Interface - Read Data from AXI Slave
/*  output    wire   [1:0]  */ .o_axi_slv_rresp              ( axix.rresp    ), // AXI Slave Bus - External Interface - Read Response from AXI Slave
/*  output    wire          */ .o_axi_slv_rlast              ( axix.rlast    ), // AXI Slave Bus - External Interface - Read Data Last from AXI Slave
/*  output    wire          */ .o_axi_slv_rvalid             ( axix.rvalid   ),  // AXI Slave Bus - External Interface - Read Data/Response Valid Indication from AXI Slave
                               .*
  );
    assign axix_awlen = axix.awlen | '0;
    assign axix_arlen = axix.arlen | '0;
    assign axix.bid = axix_bid4 | '0;
    assign axix.rid = axix_rid4 | '0;
    assign axix.rid = axix_rid4 | '0;

    assign axix.ruser = '0;
    assign axix.buser = '0;

//    assign ahbs.hresp = ahbs_hresp2;

endmodule


module sdvt_spi_master_sync_dpram #(
  parameter SYNC_DPRAM_ADDR_WIDTH      = 4                ,  // Address bus width
  parameter SYNC_DPRAM_DEPTH           = 16               ,  // FIFO Depth
  parameter SYNC_DPRAM_DATA_WIDTH      = 32                  // Data port width
 ) (
  input     wire cmsatpg,
  input     wire cmsbist,
  rbif.slavedp rbs,
  input     wire                                   i_wr_clk                       , // SYNC DP RAM - Write Clock input
  input     wire                                   i_rd_clk                       , // SYNC DP RAM - Read Clock input
  input     wire                                   i_sync_dpram_write             , // SYNC DP RAM - Write control
  input     wire   [SYNC_DPRAM_ADDR_WIDTH - 1:0]   i_sync_dpram_waddr             , // SYNC DP RAM - Write pointer input
  input     wire   [SYNC_DPRAM_DATA_WIDTH - 1:0]   i_sync_dpram_data              , // SYNC DP RAM - Write data input
  input     wire                                   i_sync_dpram_read              , // SYNC DP RAM - Read control
  input     wire   [SYNC_DPRAM_ADDR_WIDTH - 1:0]   i_sync_dpram_raddr             , // SYNC DP RAM - Read Pointer input
  output    reg    [SYNC_DPRAM_DATA_WIDTH - 1:0]   o_sync_dpram_data                // SYNC DP RAM - Read data
);

`ifdef FPGA
    bramdp #(.AW(SYNC_DPRAM_ADDR_WIDTH),.DW(SYNC_DPRAM_DATA_WIDTH))u(
        .rclk(i_rd_clk),
        .wclk(i_wr_clk),
        .rramaddr(i_sync_dpram_raddr),
        .wramaddr(i_sync_dpram_waddr),
        .rramrd(i_sync_dpram_read),
        .wramwr(i_sync_dpram_write),
        .rramrdata(o_sync_dpram_data),
        .wramwdata(i_sync_dpram_data)
        );
`else
/*
  //1-------------------------------------------------------------------------------------------------
  // Define local variables
  //1-------------------------------------------------------------------------------------------------
  reg [SYNC_DPRAM_DATA_WIDTH-1:0]            reg_storage_2d_bv [0:(SYNC_DPRAM_DEPTH - 1)]             ; // Register storage memory

  //1-------------------------------------------------------------------------------------------------
  // Write clock
  //1-------------------------------------------------------------------------------------------------
  always @ (posedge i_wr_clk)
    begin
      //3---------------------------------------------------------------------------------------------
      // write output data
      //3---------------------------------------------------------------------------------------------
      if (i_sync_dpram_write == 1) begin
        reg_storage_2d_bv[i_sync_dpram_waddr] <= i_sync_dpram_data; // spyglass disable ResetFlop-ML
      end
    end

  //1-------------------------------------------------------------------------------------------------
  // Read clock
  //1-------------------------------------------------------------------------------------------------
  always @ (posedge i_rd_clk)
    begin
      //3---------------------------------------------------------------------------------------------
      // Read output data
      //3---------------------------------------------------------------------------------------------
      if (i_sync_dpram_read) begin
        o_sync_dpram_data <= reg_storage_2d_bv[i_sync_dpram_raddr]; // spyglass disable ResetFlop-ML
      end
    end
`endif
*/

    logic clka, clkb, cena, cenb;

    ICG icga(.CK(i_rd_clk),.EN(i_sync_dpram_read ),.SE(cmsatpg),.CKG(clka));
    ICG icgb(.CK(i_wr_clk),.EN(i_sync_dpram_write),.SE(cmsatpg),.CKG(clkb));
    assign #0.5 cena = ~( i_sync_dpram_read );
    assign #0.5 cenb = ~( i_sync_dpram_write );

    localparam AW = SYNC_DPRAM_ADDR_WIDTH;
    localparam DW = SYNC_DPRAM_DATA_WIDTH;

    logic rb_clka, rb_cena, rb_clkb, rb_cenb;
    logic [AW-1:0] rb_aa, rb_ab;
    logic [DW-1:0] rb_wenb, rb_qa, rb_db;

    rbdpmux #(.AW(AW),.DW(DW))rbmux(
         .cmsatpg,
         .cmsbist,
            .clka     (clka     ),.clkb      (clkb     ),
            .qa       (o_sync_dpram_data  ),.qb        (         ),
            .cena     (cena     ),.cenb      (cenb     ),
            .gwena    ('1       ),.gwenb     (cenb     ),
            .wena     ('1       ),.wenb      ('1       ),
            .aa       (i_sync_dpram_raddr  ),.ab        (i_sync_dpram_waddr  ),
            .da       ('0       ),.db        (i_sync_dpram_data  ),
            .rb_clka  (rb_clka  ),.rb_clkb   (rb_clkb  ),
            .rb_qa    (rb_qa    ),.rb_qb     ('0       ),
            .rb_cena  (rb_cena  ),.rb_cenb   (rb_cenb  ),
            .rb_gwena (         ),.rb_gwenb  (         ),
            .rb_wena  (         ),.rb_wenb   (rb_wenb  ),
            .rb_aa    (rb_aa    ),.rb_ab     (rb_ab    ),
            .rb_da    (         ),.rb_db     (rb_db    ),
         .rbs         (rbs)
       );

    generate
        if(SYNC_DPRAM_DEPTH==128||SYNC_DPRAM_DATA_WIDTH==32) begin:gen_DP128x32
            fifo128x32 m(

            /*  input        */    .clka   (rb_clka),
            /*  input        */    .cena   (rb_cena),
            /*  input [6:0]  */    .aa     (rb_aa  ),
            /*  output [38:0]*/    .qa     (rb_qa  ),
            /*  input        */    .clkb   (rb_clkb),
            /*  input        */    .cenb   (rb_cenb),
            /*  input [6:0]  */    .ab     (rb_ab  ),
            /*  input [38:0] */    .db     (rb_db  ),
            ///*  input        */    .STOV   ('0),
            ///*  input [2:0]  */    .EMAA   ('0),
            ///*  input        */    .EMASA  ('0),
            ///*  input [2:0]  */    .EMAB   ('0),
            ///*  input        */    .RET1N  ('1)
            `rf_2p_hdc_inst
            );
        end
        if(SYNC_DPRAM_DEPTH==32||SYNC_DPRAM_DATA_WIDTH==19) begin:gen_DP32x19
            fifo32x19 m(

            /*  input        */    .clka   (rb_clka),
            /*  input        */    .cena   (rb_cena),
            /*  input [6:0]  */    .aa     (rb_aa),
            /*  output [38:0]*/    .qa     (rb_qa),
            /*  input        */    .clkb   (rb_clkb),
            /*  input        */    .cenb   (rb_cenb),
            /*  input [6:0]  */    .ab     (rb_ab),
            /*  input [38:0] */    .db     (rb_db),
            ///*  input        */    .STOV   ('0),
            ///*  input [2:0]  */    .EMAA   ('0),
            ///*  input        */    .EMASA  ('0),
            ///*  input [2:0]  */    .EMAB   ('0),
            ///*  input        */    .RET1N  ('1)
            `rf_2p_hdc_inst
            );
        end
    endgenerate

`endif

endmodule


module dummytb_qfc ();

    parameter QFC_SSCNT = 2;
    parameter QFC_SIOCNT = 8;
    parameter TX_FIFO_DEPTH  = 128;
    parameter RX_FIFO_DEPTH  = 128;
    parameter CMD_FIFO_DEPTH = 32;
    parameter XAW = 29;

    bit   clk;
    bit   pclk;
    bit   resetn;
    bit   cmsatpg;
    bit   cmsbist;
    bit   qfc_en;
    axiif axis();
    apbif apbs();
    apbif apbx();

    ioif qfc_sck();
    ioif qfc_sckn();
    ioif qfc_ss[QFC_SSCNT-1:0]();
    ioif qfc_sio[QFC_SIOCNT-1:0]();
    ioif qfc_dqs();
//    ioif qfc_rwds();
    ioif qfc_rstm[QFC_SSCNT-1:0]();
    ioif qfc_rsts[QFC_SSCNT-1:0]();
    ioif qfc_int();

    padcfg_arm_t  padcfg_qfc_sck;
    padcfg_arm_t  padcfg_qfc_qds;
    padcfg_arm_t  padcfg_qfc_ss;
    padcfg_arm_t  padcfg_qfc_sio;
    padcfg_arm_t  padcfg_qfc_rwds;
    padcfg_arm_t  padcfg_qfc_int;
    padcfg_arm_t  padcfg_qfc_rst;

    rbif #(.AW(7    ),      .DW(32))    rbif_tx_fifo128x32     ();
    rbif #(.AW(7    ),      .DW(32))    rbif_rx_fifo128x32     ();
    rbif #(.AW(5    ),      .DW(19))    rbif_fifo32x19         ();
    logic irq;

    qfc u(.*);


endmodule



