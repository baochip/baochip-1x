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



import axi_pkg::*;


package daric_cfg;


// bist read
// ==

    parameter BRC  = 32;
    parameter BRCW = $clog2(BRC);
    parameter BRDW = 256;

    parameter BRNUM_CMS = 1;        // number of cms data
    parameter BRNUM_IPM = 3;        // number of IP trimming
    parameter BRNUM_CFG = 28;       // number of syscfg trimming
    parameter BRNUM_ACV = 240;      // number of access control vector of keyslot





// memory mapping
// ==

    typedef axi_pkg::xbar_rule_32_t       rule32_t; // Has to be the same width as axi addr


  // core ahb mapping
    localparam rule32_t [6:0] coreahb_demux_map = '{
   //        '{idx: 32'd7 , start_addr: 32'h5000_0000, end_addr: 32'h5100_0000}, // apb3-always
        '{idx: 32'd6 , start_addr: 32'h4006_0000, end_addr: 32'h4007_0000}, // apb3-always
        '{idx: 32'd5 , start_addr: 32'h4005_0000, end_addr: 32'h4006_0000}, // apb2-security
        '{idx: 32'd4 , start_addr: 32'h4004_0000, end_addr: 32'h4005_0000}, // apb1-system
        '{idx: 32'd3 , start_addr: 32'h4003_0000, end_addr: 32'h4004_0000}, // mdma
        '{idx: 32'd2 , start_addr: 32'h4002_0000, end_addr: 32'h4003_0000}, // sce
        '{idx: 32'd1 , start_addr: 32'h4001_0000, end_addr: 32'h4002_0000}, // qfc
        '{idx: 32'd0 , start_addr: 32'h4000_0000, end_addr: 32'h4001_0000}  // rrc
    };


  // code memory
    localparam CODEMEMCNT = 4;

    localparam rule32_t [CODEMEMCNT-1:0] code_mem_map = '{
        '{idx: 32'd3 , start_addr: 32'h6100_0000, end_addr: 32'h6120_0000}, // sram
        '{idx: 32'd2 , start_addr: 32'h6000_0000, end_addr: 32'h6040_0000}, // reram // 4MB
        '{idx: 32'd1 , start_addr: 32'h2000_0000, end_addr: 32'h4000_0000}, // dtcm
        '{idx: 32'd0 , start_addr: 32'h0000_0000, end_addr: 32'h2000_0000}  // itcm
    };

// AXIM ID
// ==

    localparam bit [3:0] AMBAID4_CM7A = 4'h2;
    localparam bit [3:0] AMBAID4_VEXI = 4'h3;
    localparam bit [3:0] AMBAID4_VEXD = 4'h4;
    localparam bit [3:0] AMBAID4_SCEA = 4'h5;
    localparam bit [3:0] AMBAID4_SCES = 4'h6;
    localparam bit [3:0] AMBAID4_MDMA = 4'h7;

    localparam bit [3:0] AMBAID4_CM7P = 4'h8;
    localparam bit [3:0] AMBAID4_CM7D = 4'h9;
    localparam bit [3:0] AMBAID4_VEXP = 4'hD;
    localparam bit [3:0] AMBAID4_UDMA = 4'hA;
    localparam bit [3:0] AMBAID4_UDCA = 4'hB;
    localparam bit [3:0] AMBAID4_SDDC = 4'hC;


// M7 config
// ==

    typedef struct{
        int         FPU         ;
        int         ICACHE      ;
        int         DCACHE      ;
        int         CACHEECC    ;
        int         MPU         ;
        int         IRQNUM      ;
        int         IRQLVL      ;
        int         ICACHESIZE  ;
        int         DCACHESIZE  ;
    }cm7cfg_t;

`ifdef FPGA
    localparam CM7CFG_CACHEECC = 0;
`else
    localparam CM7CFG_CACHEECC = 1;
`endif

`ifdef FPGA
    localparam CM7CFG_FPU = 2;
`else
    localparam CM7CFG_FPU = 2;
`endif

    localparam IRQCNT = 256;
    localparam ERRCNT = 16;
    /*
    localparam cm7cfg_t CM7CFG = {
        FPU         : CM7CFG_FPU     ,
        ICACHE      : 1     ,
        DCACHE      : 1     ,
        CACHEECC    : CM7CFG_CACHEECC     ,
        MPU         : 16    ,
        IRQNUM      : IRQCNT-16 ,
        IRQLVL      : 3     ,
        ICACHESIZE  : 16    ,
        DCACHESIZE  : 16
    };
    */

//  tcm cfg:
//  -- dtcm cfg is for 1 of the macro, there are 2 in total.
//  -- rc is ramcount, means the ram entity count in parallel.
    /*
    localparam CFGITCMSZ = 4'b1001; // 256KB
    localparam CFGDTCMSZ = 4'b0111; // 64 KB

    localparam dtcmrc = 1;
    localparam sram_pkg::sramcfg_t dtcmcfg = {
        AW: 13,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 2**13,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '0,
        isPRT:  '1,
        EVITVL: 15
    };

    localparam itcmrc = 4;
    localparam sram_pkg::sramcfg_t itcmcfg = {
        AW: 15,
        DW: 64,
        KW: 64,
        PW: 8,
        WCNT: 2**15,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '0,
        isPRT:  '1,
        EVITVL: 15
    };

//  core sram
//  this is for 1 bank. there are 2 banks attached in total

// 32kx72 * 4
    parameter coresrammacrocnt0 = 4;
    parameter sram_pkg::sramcfg_t coresramcfg0 = {
        AW: 20-3,       // 17b: 1M
        DW: 64,
        KW: 64,
        PW: 8,
        WCNT: 2**(20-3),
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    };

// 8kx72 * 16
    parameter coresrammacrocnt1 = 4*4;
    parameter sram_pkg::sramcfg_t coresramcfg1 = {
        AW: 20-3,       // 17b: 1M
        DW: 64,
        KW: 64,
        PW: 8,
        WCNT: 2**(20-3),
        AWX: 5,
        isBWEN: '1,
        isSCMB: '1,
        isPRT:  '1,
        EVITVL:  15
    };
    */

// ░▒▓██▓▒░  ■■■■■■■■■■
// ░▒▓██▓▒░    secsub
// ░▒▓██▓▒░  ■■■■■■■■■■

        parameter MESHLC    = 64;
        parameter MESHPC    = 32;
        parameter SENSORVDC = 6;
        parameter SENSORLDC = 2;

`ifdef MPW
        parameter GLCX      = 2;
        parameter GLCY      = 32;
`else
        parameter GLCX      = 64;
        parameter GLCY      = 32;
`endif



// ░▒▓██▓▒░  ■■■■■■■■■■
// ░▒▓██▓▒░    dft
// ░▒▓██▓▒░  ■■■■■■■■■■


    parameter DFT_AOTRM_BW = 64;
    parameter DFT_AOTRM_IV = 64'h0;


endpackage : daric_cfg
