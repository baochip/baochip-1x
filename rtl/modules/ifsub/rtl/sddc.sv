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

module sddc #(
    parameter NUM_OF_IO_FUNC             = 3'h7 ,
    parameter CFGBAAW = 18,
    parameter bit[31:0] BA   = 32'h5000_0000,
    parameter bit[3:0] AHBMID4 = 4'hc
)(
    input bit   clk,
    input bit   pclk,
    input bit   resetn,
    input bit   cmsatpg,
    input bit   cmsbist,
    ahbif.slave     ahbs,//aw12/dw32
    ahbif.master    ahbm,//aw32/dw32
    apbif.slavein   apbs,//aw12/dw32
    apbif.slave     apbx,

    ioif.drive sddc_clk,
    ioif.drive sddc_cmd,
//    ioif.drive sddc_dat[3:0],
    ioif.drive sddc_dat0,
    ioif.drive sddc_dat1,
    ioif.drive sddc_dat2,
    ioif.drive sddc_dat3,

    output logic irq

);

//  io interface
//  ====
//

    logic clksdio              ;
    logic sddc_cmd_w           ;
    logic o_sddc_cmd           ;
    logic o_sddc_cmd_en        ;
    logic o_sddc_cmd_pullup    ;
    logic [3:0] sddc_data_4w         ;
    logic [3:0] o_sddc_data          ;
    logic [3:0] o_sddc_data_en       ;
    logic [3:0] o_sddc_data_pullup   ;
    logic sddcio_pu_clk, sddcio_enable;
    logic [1:0] cr_io;
    assign sddc_clk.oe = '0;
    assign sddc_clk.pu = 1'b1;//sddcio_pu_clk;
    assign sddc_clk.po = '0;
//    assign clksdio = sddc_clk.pi;

    CLKCELL_BUF uckb ( .A(sddc_clk.pi), .Z(clksdio) );

    assign sddc_cmd.oe = sddcio_enable & o_sddc_cmd_en;
    assign sddc_cmd.pu = 1'b1;//sddcio_enable ? o_sddc_cmd_pullup : 1'b1;
    assign sddc_cmd.po = o_sddc_cmd;
    assign sddc_cmd_w = sddc_cmd.pi;

    assign sddc_dat0.oe = sddcio_enable & o_sddc_data_en[0];
    assign sddc_dat1.oe = sddcio_enable & o_sddc_data_en[1];
    assign sddc_dat2.oe = sddcio_enable & o_sddc_data_en[2];
    assign sddc_dat3.oe = sddcio_enable & o_sddc_data_en[3];
    assign sddc_dat0.pu = 1'b1;//sddcio_enable ? o_sddc_data_pullup : 1'b1;
    assign sddc_dat1.pu = 1'b1;//sddcio_enable ? o_sddc_data_pullup : 1'b1;
    assign sddc_dat2.pu = 1'b1;//sddcio_enable ? o_sddc_data_pullup : 1'b1;
    assign sddc_dat3.pu = 1'b1;//sddcio_enable ? o_sddc_data_pullup : 1'b1;
    assign sddc_dat0.po = o_sddc_data[0]; assign sddc_data_4w[0] = sddc_dat0.pi;
    assign sddc_dat1.po = o_sddc_data[1]; assign sddc_data_4w[1] = sddc_dat1.pi;
    assign sddc_dat2.po = o_sddc_data[2]; assign sddc_data_4w[2] = sddc_dat2.pi;
    assign sddc_dat3.po = o_sddc_data[3]; assign sddc_data_4w[3] = sddc_dat3.pi;

//  sfr
//  ====
//
    bit [23:0] cfg_reg_ocr;
    bit [7:0]  cfg_rd_fifo_threshold;
    bit [7:0] cfg_reg_cccr_sdio_revision, cfg_reg_sd_spec_revision;

    bit [CFGBAAW-1:0] cfg_base_addr_csa;
    bit [0:7][CFGBAAW-1:0] cfg_base_addr_io_func;

    bit [0:7][16:0] cfg_reg_func_cis_ptr;
    bit [0:7][7:0] cfg_reg_func_ext_std_code;

    logic apbrd, apbwr;
    logic sfrlock;
    logic sdioresetn;
    logic arreset;
    logic [1:0] ahbs_hresp2;

    `theregrn( sfrlock ) <= '0;

    `apbs_common;
    assign apbx.prdata = '0
                        | sfr_io.prdata32
                        | cr_ocr.prdata32 | cr_rdffthres.prdata32 | cr_rev.prdata32
                        | cr_bacsa.prdata32 | cr_baiofn.prdata32 | cr_fncisptr.prdata32 | cr_fnextstdcode.prdata32
                        | cr_write_protect.prdata32 | cr_reg_dsr.prdata32 | cr_reg_cid.prdata32 | cr_reg_csd.prdata32 | cr_reg_scr.prdata32 | cr_reg_sd_status.prdata32
                        | cr_base_addr_mem_func.prdata32
                        | cr_reg_func_isdio_interface_code.prdata32 | cr_reg_func_manufact_code.prdata32 | cr_reg_func_manufact_info.prdata32 | cr_reg_func_isdio_type_sup_code.prdata32 | cr_reg_func_info.prdata32
                        | cr_reg_uhs_1_support.prdata32
                        ;

    apb_cr #(.A('h00), .DW(2), .IV(2'b10))          sfr_io          (.cr(cr_io),.prdata32(),.*);
    apb_ar #(.A('h04), .AR(32'h5a))     sfr_ar          (.ar(arreset),.*);

    apb_cr #(.A('h10), .DW(24))         cr_ocr          (.cr(cfg_reg_ocr), .prdata32(),.*);
    apb_cr #(.A('h14), .DW( 8))         cr_rdffthres    (.cr(cfg_rd_fifo_threshold), .prdata32(),.*);
    apb_cr #(.A('h18), .DW(16))         cr_rev          (.cr({cfg_reg_cccr_sdio_revision,cfg_reg_sd_spec_revision}), .prdata32(),.*);

    apb_cr #(.A('h1C), .DW(CFGBAAW))                cr_bacsa    (.cr(cfg_base_addr_csa), .prdata32(),.*);
    apb_cr #(.A('h20), .DW(CFGBAAW), .SFRCNT(8))    cr_baiofn   (.cr(cfg_base_addr_io_func), .prdata32(),.*);

    apb_cr #(.A('h40), .DW(17), .SFRCNT(8))    cr_fncisptr        (.cr(cfg_reg_func_cis_ptr), .prdata32(),.*);
    apb_cr #(.A('h60), .DW( 8), .SFRCNT(8))    cr_fnextstdcode    (.cr(cfg_reg_func_ext_std_code), .prdata32(),.*);


    bit   [15:0]   cfg_reg_dsr       ;
    bit   [127:0]  cfg_reg_cid       ;
    bit   [127:0]  cfg_reg_csd       ; // 111
    bit   [63:0]   cfg_reg_scr       ;
    bit   [511:0]  cfg_reg_sd_status ; // 509
    bit            cfg_write_protect ;

    apb_cr #(.A('h80), .DW( 1)            )    cr_write_protect    (.cr( cfg_write_protect ), .prdata32(),.*);
    apb_cr #(.A('h84), .DW(16)            )    cr_reg_dsr          (.cr( cfg_reg_dsr       ), .prdata32(),.*);
    apb_cr #(.A('h88), .DW(32), .SFRCNT(4),  .REVY(1) )    cr_reg_cid          (.cr( cfg_reg_cid       ), .prdata32(),.*);
    apb_cr #(.A('h98), .DW(32), .SFRCNT(4),  .REVY(1) )    cr_reg_csd          (.cr( cfg_reg_csd       ), .prdata32(),.*);
    apb_cr #(.A('hA8), .DW(32), .SFRCNT(2),  .REVY(1) )    cr_reg_scr          (.cr( cfg_reg_scr       ), .prdata32(),.*);
    apb_cr #(.A('hB0), .DW(32), .SFRCNT(16), .REVY(1) )    cr_reg_sd_status    (.cr( cfg_reg_sd_status ), .prdata32(),.*);

    bit [0:17][CFGBAAW-1:0]  cfg_base_addr_mem_func;
    apb_cr #(.A('h100), .DW(CFGBAAW), .SFRCNT(18) )    cr_base_addr_mem_func    (.cr( cfg_base_addr_mem_func ), .prdata32(),.*);

    bit [1:7][7:0]   cfg_reg_func_isdio_interface_code ;
    bit [1:7][15:0]  cfg_reg_func_manufact_code        ;
    bit [1:7][15:0]  cfg_reg_func_manufact_info        ;
    bit [1:7][7:0]   cfg_reg_func_isdio_type_sup_code  ;
    bit [1:7][15:0]  cfg_reg_func_info;

    apb_cr #(.A('h148), .DW( 8), .SFRCNT(7) )    cr_reg_func_isdio_interface_code   (.cr( cfg_reg_func_isdio_interface_code  ), .prdata32(),.*);
    apb_cr #(.A('h168), .DW(16), .SFRCNT(7) )    cr_reg_func_manufact_code          (.cr( cfg_reg_func_manufact_code         ), .prdata32(),.*);
    apb_cr #(.A('h188), .DW(16), .SFRCNT(7) )    cr_reg_func_manufact_info          (.cr( cfg_reg_func_manufact_info         ), .prdata32(),.*);
    apb_cr #(.A('h1A8), .DW( 8), .SFRCNT(7) )    cr_reg_func_isdio_type_sup_code    (.cr( cfg_reg_func_isdio_type_sup_code   ), .prdata32(),.*);
    apb_cr #(.A('h1C8), .DW(16), .SFRCNT(7) )    cr_reg_func_info                   (.cr( cfg_reg_func_info                  ), .prdata32(),.*);

    bit [7:0]   cfg_reg_uhs_1_support     ;
    bit [7:0]   cfg_reg_data_strc_version ;
    bit [15:0]  cfg_reg_max_current       ;
    apb_cr #(.A('h1F0), .DW(32) )    cr_reg_uhs_1_support   (.cr( { cfg_reg_uhs_1_support, cfg_reg_data_strc_version, cfg_reg_max_current } ), .prdata32(),.*);



assign { sddcio_pu_clk, sddcio_enable } = cr_io;

// reset

    scresetgen #(.ICNT(1),.EXTCNT(16))sdresetgen(
        .clk         ( clk ),
        .cmsatpg     ( cmsatpg ),
        .resetn      ( resetn ),
        .resetnin    ( ~arreset ),
        .resetnout   ( sdioresetn )
    );

//  inst
//  ====
//

    logic [31:0] ahbm_haddr;

    assign ahbm.haddr = BA + ahbm_haddr[CFGBAAW-1:0];
    assign ahbm.hmaster = AHBMID4;
    assign ahbm.hsel = '1;
    assign ahbm.hreadym = ahbm.hready;//'1;
    assign ahbm.hauser = '0;
    assign ahbm.hwuser = '0;

    assign ahbs.hresp = ahbs_hresp2;
    assign ahbs.hruser = '0;

sdvt_sdio_device_core  #(.NUM_OF_IO_FUNC(NUM_OF_IO_FUNC))u (
    .cmsatpg, .cmsbist,
    .i_clk                         (clk                           ),
    .i_rst_n                       (sdioresetn                    ),
    .i_dma_clk                     (clk                           ),
    .i_dma_rst_n                   (sdioresetn                    ),

    .i_sdio_clk                    (clksdio                       ),
    .i_sdio_cmd                    (sddc_cmd_w                    ),
    .i_sdio_data                   (sddc_data_4w                  ),
    .o_sdio_cmd                    (o_sddc_cmd                    ),
    .o_sdio_cmd_en                 (o_sddc_cmd_en                 ),
    .o_sdio_data                   (o_sddc_data                   ),
    .o_sdio_data_en                (o_sddc_data_en                ),
    .o_sdio_cmd_pullup             (o_sddc_cmd_pullup             ),
    .o_sdio_data_pullup            (o_sddc_data_pullup            ),

    .i_reg_ocr                     ( cfg_reg_ocr                  ),
    .i_rd_fifo_threshold           ( cfg_rd_fifo_threshold        ),
/*  input     wire   [15:0]  */   .i_reg_dsr         ( cfg_reg_dsr[15:0]        ), // REG -  DSR Register
/*  input     wire   [127:0] */   .i_reg_cid         ( cfg_reg_cid[127:0]       ), // REG -  CID Register
/*  input     wire   [111:0] */   .i_reg_csd         ( cfg_reg_csd[111:0]       ), // REG -  CSD Register[127A1B1_XZ16] only
/*  input     wire   [63:0]  */   .i_reg_scr         ( cfg_reg_scr[63:0]        ), // REG -  SCR Register
/*  input     wire   [509:0] */   .i_reg_sd_status   ( cfg_reg_sd_status[509:0] ), // REG -  SD STATUS Register
/*  input     wire           */   .i_write_protect   ( cfg_write_protect        ),

    .i_base_addr_io_func0          ( cfg_base_addr_io_func[0]  | 64'h0 ),
    .i_base_addr_io_func1          ( cfg_base_addr_io_func[1]  | 64'h0 ),
    .i_base_addr_io_func2          ( cfg_base_addr_io_func[2]  | 64'h0 ),
    .i_base_addr_io_func3          ( cfg_base_addr_io_func[3]  | 64'h0 ),
    .i_base_addr_io_func4          ( cfg_base_addr_io_func[4]  | 64'h0 ),
    .i_base_addr_io_func5          ( cfg_base_addr_io_func[5]  | 64'h0 ),
    .i_base_addr_io_func6          ( cfg_base_addr_io_func[6]  | 64'h0 ),
    .i_base_addr_io_func7          ( cfg_base_addr_io_func[7]  | 64'h0 ),
    .i_base_addr_csa               ( cfg_base_addr_csa         | 64'h0 ),

/* input     wire   [63:0]  */ .i_base_addr_mem_func0       ( cfg_base_addr_mem_func[0 ] | 64'h0 )     , // Base addr MEM FUNC0
/* input     wire   [63:0]  */ .i_base_addr_mem_func1       ( cfg_base_addr_mem_func[1 ] | 64'h0 )     , // Base addr MEM FUNC1
/* input     wire   [63:0]  */ .i_base_addr_mem_func2       ( cfg_base_addr_mem_func[2 ] | 64'h0 )     , // Base addr MEM FUNC2
/* input     wire   [63:0]  */ .i_base_addr_mem_func3       ( cfg_base_addr_mem_func[3 ] | 64'h0 )     , // Base addr MEM FUNC3
/* input     wire   [63:0]  */ .i_base_addr_mem_func4       ( cfg_base_addr_mem_func[4 ] | 64'h0 )     , // Base addr MEM FUNC4
/* input     wire   [63:0]  */ .i_base_addr_mem_func5       ( cfg_base_addr_mem_func[5 ] | 64'h0 )     , // Base addr MEM FUNC5
/* input     wire   [63:0]  */ .i_base_addr_mem_func6       ( cfg_base_addr_mem_func[6 ] | 64'h0 )     , // Base addr MEM FUNC6
/* input     wire   [63:0]  */ .i_base_addr_mem_func7       ( cfg_base_addr_mem_func[7 ] | 64'h0 )     , // Base addr MEM FUNC7
/* input     wire   [63:0]  */ .i_base_addr_mem_func8       ( cfg_base_addr_mem_func[8 ] | 64'h0 )     , // Base addr MEM FUNC8
/* input     wire   [63:0]  */ .i_base_addr_mem_func9       ( cfg_base_addr_mem_func[9 ] | 64'h0 )     , // Base addr MEM FUNC9
/* input     wire   [63:0]  */ .i_base_addr_mem_func10      ( cfg_base_addr_mem_func[10] | 64'h0 )     , // Base addr MEM FUNC10
/* input     wire   [63:0]  */ .i_base_addr_mem_func11      ( cfg_base_addr_mem_func[11] | 64'h0 )     , // Base addr MEM FUNC11
/* input     wire   [63:0]  */ .i_base_addr_mem_func12      ( cfg_base_addr_mem_func[12] | 64'h0 )     , // Base addr MEM FUNC12
/* input     wire   [63:0]  */ .i_base_addr_mem_func13      ( cfg_base_addr_mem_func[13] | 64'h0 )     , // Base addr MEM FUNC13
/* input     wire   [63:0]  */ .i_base_addr_mem_func14      ( cfg_base_addr_mem_func[14] | 64'h0 )     , // Base addr MEM FUNC14
/* input     wire   [63:0]  */ .i_base_addr_mem_func15      ( cfg_base_addr_mem_func[15] | 64'h0 )     , // Base addr MEM FUNC15
/* input     wire   [63:0]  */ .i_base_addr_gen_cmd         ( cfg_base_addr_mem_func[16] | 64'h0 )     , // Base addr Gen command
/* input     wire   [63:0]  */ .i_base_addr_mem             ( cfg_base_addr_mem_func[17] | 64'h0 )     , // Base addr memory

    .i_reg_cccr_sdio_revision      ( cfg_reg_cccr_sdio_revision      ),
    .i_reg_sd_spec_revision        ( cfg_reg_sd_spec_revision        ),

    .i_reg_func0_cis_ptr           ( cfg_reg_func_cis_ptr[0]           ),
    .i_reg_func1_ext_std_code      ( cfg_reg_func_ext_std_code[1]      ),
    .i_reg_func1_cis_ptr           ( cfg_reg_func_cis_ptr[1]           ),
    .i_reg_func2_ext_std_code      ( cfg_reg_func_ext_std_code[2]      ),
    .i_reg_func2_cis_ptr           ( cfg_reg_func_cis_ptr[2]           ),
    .i_reg_func3_ext_std_code      ( cfg_reg_func_ext_std_code[3]      ),
    .i_reg_func3_cis_ptr           ( cfg_reg_func_cis_ptr[3]           ),
    .i_reg_func4_ext_std_code      ( cfg_reg_func_ext_std_code[4]      ),
    .i_reg_func4_cis_ptr           ( cfg_reg_func_cis_ptr[4]           ),
    .i_reg_func5_ext_std_code      ( cfg_reg_func_ext_std_code[5]      ),
    .i_reg_func5_cis_ptr           ( cfg_reg_func_cis_ptr[5]           ),
    .i_reg_func6_ext_std_code      ( cfg_reg_func_ext_std_code[6]      ),
    .i_reg_func6_cis_ptr           ( cfg_reg_func_cis_ptr[6]           ),
    .i_reg_func7_ext_std_code      ( cfg_reg_func_ext_std_code[7]      ),
    .i_reg_func7_cis_ptr           ( cfg_reg_func_cis_ptr[7]           ),

/*  input     wire   [7:0]   */ .i_reg_func1_isdio_interface_code ( cfg_reg_func_isdio_interface_code[1] ), // Func1 iSDIO Interface code
/*  input     wire   [7:0]   */ .i_reg_func2_isdio_interface_code ( cfg_reg_func_isdio_interface_code[2] ), // Func2 iSDIO Interface code
/*  input     wire   [7:0]   */ .i_reg_func3_isdio_interface_code ( cfg_reg_func_isdio_interface_code[3] ), // Func3 iSDIO Interface code
/*  input     wire   [7:0]   */ .i_reg_func4_isdio_interface_code ( cfg_reg_func_isdio_interface_code[4] ), // Func4 iSDIO Interface code
/*  input     wire   [7:0]   */ .i_reg_func5_isdio_interface_code ( cfg_reg_func_isdio_interface_code[5] ), // Func5 iSDIO Interface code
/*  input     wire   [7:0]   */ .i_reg_func6_isdio_interface_code ( cfg_reg_func_isdio_interface_code[6] ), // Func6 iSDIO Interface code
/*  input     wire   [7:0]   */ .i_reg_func7_isdio_interface_code ( cfg_reg_func_isdio_interface_code[7] ), // Func7 iSDIO Interface code
/*  input     wire   [15:0]  */ .i_reg_func1_manufact_code        ( cfg_reg_func_manufact_code[1]        ), // Func1 SDIO card manufacturer code
/*  input     wire   [15:0]  */ .i_reg_func2_manufact_code        ( cfg_reg_func_manufact_code[2]        ), // Func2 SDIO card manufacturer code
/*  input     wire   [15:0]  */ .i_reg_func3_manufact_code        ( cfg_reg_func_manufact_code[3]        ), // Func3 SDIO card manufacturer code
/*  input     wire   [15:0]  */ .i_reg_func4_manufact_code        ( cfg_reg_func_manufact_code[4]        ), // Func4 SDIO card manufacturer code
/*  input     wire   [15:0]  */ .i_reg_func5_manufact_code        ( cfg_reg_func_manufact_code[5]        ), // Func5 SDIO card manufacturer code
/*  input     wire   [15:0]  */ .i_reg_func6_manufact_code        ( cfg_reg_func_manufact_code[6]        ), // Func6 SDIO card manufacturer code
/*  input     wire   [15:0]  */ .i_reg_func7_manufact_code        ( cfg_reg_func_manufact_code[7]        ), // Func7 SDIO card manufacturer code
/*  input     wire   [15:0]  */ .i_reg_func1_manufact_info        ( cfg_reg_func_manufact_info[1]        ), // Func1 Manufacturer Information
/*  input     wire   [15:0]  */ .i_reg_func2_manufact_info        ( cfg_reg_func_manufact_info[2]        ), // Func2 Manufacturer Information
/*  input     wire   [15:0]  */ .i_reg_func3_manufact_info        ( cfg_reg_func_manufact_info[3]        ), // Func3 Manufacturer Information
/*  input     wire   [15:0]  */ .i_reg_func4_manufact_info        ( cfg_reg_func_manufact_info[4]        ), // Func4 Manufacturer Information
/*  input     wire   [15:0]  */ .i_reg_func5_manufact_info        ( cfg_reg_func_manufact_info[5]        ), // Func5 Manufacturer Information
/*  input     wire   [15:0]  */ .i_reg_func6_manufact_info        ( cfg_reg_func_manufact_info[6]        ), // Func6 Manufacturer Information
/*  input     wire   [15:0]  */ .i_reg_func7_manufact_info        ( cfg_reg_func_manufact_info[7]        ), // Func7 Manufacturer Information
/*  input     wire   [7:0]   */ .i_reg_func1_isdio_type_sup_code  ( cfg_reg_func_isdio_type_sup_code[1]  ), // Func1 iSDIO Type support code
/*  input     wire   [7:0]   */ .i_reg_func2_isdio_type_sup_code  ( cfg_reg_func_isdio_type_sup_code[2]  ), // Func2 iSDIO Type support code
/*  input     wire   [7:0]   */ .i_reg_func3_isdio_type_sup_code  ( cfg_reg_func_isdio_type_sup_code[3]  ), // Func3 iSDIO Type support code
/*  input     wire   [7:0]   */ .i_reg_func4_isdio_type_sup_code  ( cfg_reg_func_isdio_type_sup_code[4]  ), // Func4 iSDIO Type support code
/*  input     wire   [7:0]   */ .i_reg_func5_isdio_type_sup_code  ( cfg_reg_func_isdio_type_sup_code[5]  ), // Func5 iSDIO Type support code
/*  input     wire   [7:0]   */ .i_reg_func6_isdio_type_sup_code  ( cfg_reg_func_isdio_type_sup_code[6]  ), // Func6 iSDIO Type support code
/*  input     wire   [7:0]   */ .i_reg_func7_isdio_type_sup_code  ( cfg_reg_func_isdio_type_sup_code[7]  ), // Func7 iSDIO Type support code

/*  input     wire   [15:0]  */ .i_reg_func1_info                 ( cfg_reg_func_info[1] ), // Memmory card func1 info
/*  input     wire   [15:0]  */ .i_reg_func2_info                 ( cfg_reg_func_info[2] ), // Memmory card func2 info
/*  input     wire   [15:0]  */ .i_reg_func3_info                 ( cfg_reg_func_info[3] ), // Memmory card func3 info
/*  input     wire   [15:0]  */ .i_reg_func4_info                 ( cfg_reg_func_info[4] ), // Memmory card func4 info
/*  input     wire   [15:0]  */ .i_reg_func5_info                 ( cfg_reg_func_info[5] ), // Memmory card func5 info
/*  input     wire   [15:0]  */ .i_reg_func6_info                 ( cfg_reg_func_info[6] ), // Memmory card func6 info



/*  input     wire   [7:0]   */ .i_reg_uhs_1_support              ( cfg_reg_uhs_1_support       ), // UHS1 support register in CCCR
/*  input     wire   [7:0]   */ .i_reg_data_strc_version          ( cfg_reg_data_strc_version   ), // Data structure version of switch function
/*  input     wire   [15:0]  */ .i_reg_max_current                ( cfg_reg_max_current         ), // Maximum current in switch func

//    .i_irq                         ( '0                    ),

    .i_ahb_slv_addr                ( ahbs.haddr[11:0]      ),
    .i_ahb_slv_trans               ( ahbs.htrans           ),
    .i_ahb_slv_write               ( ahbs.hwrite           ),
    .i_ahb_slv_burst               ( ahbs.hburst           ),
    .i_ahb_slv_size                ( ahbs.hsize            ),
    .i_ahb_slv_wdata               ( ahbs.hwdata           ),
    .i_ahb_slv_sel                 ( ahbs.hsel             ),
    .i_ahb_slv_ready               ( ahbs.hreadym          ),
    .o_ahb_slv_rdata               ( ahbs.hrdata           ),
    .o_ahb_slv_ready               ( ahbs.hready           ),
    .o_ahb_slv_resp                ( ahbs_hresp2           ),

    .o_irq                         ( irq                   ),

    .o_ahb_mst_addr                ( ahbm_haddr[31:0]      ),
    .o_ahb_mst_trans               ( ahbm.htrans           ),
    .o_ahb_mst_write               ( ahbm.hwrite           ),
    .o_ahb_mst_size                ( ahbm.hsize            ),
    .o_ahb_mst_burst               ( ahbm.hburst           ),
    .o_ahb_mst_prot                ( ahbm.hprot            ),
    .o_ahb_mst_wdata               ( ahbm.hwdata           ),
    .o_ahb_mst_busreq              (                       ),
    .o_ahb_mst_lock                ( ahbm.hmasterlock      ),
    .i_ahb_mst_rdata               ( ahbm.hrdata           ),
    .i_ahb_mst_ready               ( ahbm.hready           ),
    .i_ahb_mst_resp                ( ahbm.hresp | 2'h0      ),
    .i_ahb_mst_grant               ( 1'b1                  ),

    .i_scan_clk                   ('0), // Scan - Scan clock
    .i_scan_rst                   ('1), // Scan - Scan reset
    .i_scan_mode                  (cmsatpg), // Scan - Scan mode
    .i_scan_in                    ('0), // Scan - Scan serial data in
    .o_scan_out                   (), // Scan - Scan serial data out

    .*
  );


endmodule

module dummytb_sddc ();
    parameter CFGBAAW = 32;

    bit   clk;
    bit   pclk;
    bit   resetn;
    bit   cmsatpg;
    bit   cmsbist;
    ahbif  #(.AW(12))  ahbs();
    ahbif    ahbm();
    apbif  #(.PAW(12))  apbs();

    ioif sddc_clk();
    ioif sddc_cmd();
    ioif sddc_dat0();
    ioif sddc_dat1();
    ioif sddc_dat2();
    ioif sddc_dat3();

    wire irq;

    sddc u(.apbs(apbs),.apbx(apbs),.*);

endmodule

