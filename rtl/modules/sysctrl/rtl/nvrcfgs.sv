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

import cms_pkg::*;

package nvrcfg_pkg;

    localparam RRAW = 22;  //4k
    localparam RRBAW = 8;  //256 blks, 16KB/blk

    typedef bit [RRBAW-1:0] rrblk_adr_t;

    typedef bit [255:0] nvrdat_t;
    localparam nvrdat_t defnvrdat256 = 256'hcf9defc0de;

    typedef struct packed {
        bit [31:16][7:0] rev     ;
        bit [7:0] reram_start    ; //0
        bit [7:0] reram_end      ; //1
        bit [7:0] m7_init        ; //2
        bit [7:0] m7_boot0_start ; //3
        bit [7:0] m7_boot1_start ; //4
        bit [7:0] m7_fw0_start   ; //5
        bit [7:0] m7_fw1_start   ; //6
        bit [7:0] m7_fw1_end     ; //7
        bit [7:0] rv_init        ; //8
        bit [7:0] rv_boot0_start ; //9
        bit [7:0] rv_boot1_start ; //10
        bit [7:0] rv_fw0_start   ; //11
        bit [7:0] rv_fw1_start   ; //12
        bit [7:0] rv_fw1_end     ; //13
        bit [7:0] sramcut        ; //14
        bit [4:0] tkey_en        ; //15-[7:3]
        bit [0:0] rv_def_mm      ; //15-[2]
        bit [1:0] rv_def_user    ; //15-[1:0]
    }cfgrrsub_t;
    localparam cfgrrsub_t defcfgrrsub = '{
        rev            : '0,
        reram_start    : '0,  //0
        reram_end      : '1,  //1
        m7_init        : '0,  //2
        m7_boot0_start : '0,  //3
        m7_boot1_start : '1,  //4
        m7_fw0_start   : '1,  //5
        m7_fw1_start   : '1,  //6
        m7_fw1_end     : '1,  //7
        rv_init        : '0,  //8
        rv_boot0_start : '0,  //9
        rv_boot1_start : '1,  //10
        rv_fw0_start   : '1,  //11
        rv_fw1_start   : '1,  //12
        rv_fw1_end     : '1,  //13
        sramcut        : '0,  //14
        tkey_en        : '0,  //15
        rv_def_mm      : '1,  //15
        rv_def_user    : '0   //15
        };

    typedef struct packed {
        bit [3:0][31:0] rev0 ;
        bit [31:0] devena ;
        bit [31:0] coreselcm7 ;
        bit [31:0] coreselvex ;
        bit [31:16] rev1 ;
        bit [15:8] qfc_disable ;
        bit [7:0] coreuser_filtercyc ;
    }cfgcore_t;
    localparam bit [31:0] cpudevmode = 32'h298ca435;
    localparam bit [31:0] coreselcm7_code = 32'h7e20a453;
    localparam bit [31:0] coreselvex_code = 32'h6a428c82;
    localparam cfgcore_t defcfgcore = '{
        rev0        : '0,
        devena      : cpudevmode,
        coreselcm7  : coreselcm7_code,
        coreselvex  : 31'h00,
        rev1        : '0,
        qfc_disable : '0,  // zero to enable, else to disable
        coreuser_filtercyc : 8'h7
    };




    typedef struct packed {
        cms_pkg::cmsdata_e cmsdata1;
        cms_pkg::cmsdata_e cmsdata0;
    }nvrcms_t;
    localparam nvrcms_t defnvrcms = '{
        cmsdata1: cms_pkg::CMSDAT_USERMODE,
        cmsdata0: cms_pkg::CMSDAT_USERMODE
    };

    typedef struct packed{
        nvrdat_t            ipm0;          //1
        nvrdat_t            ipm1;          //2
        nvrdat_t            ipm2;          //3
    }nvripm_t;
    localparam nvripm_t defnvripm = '{
        ipm0      : defnvrdat256 ,
        ipm1      : defnvrdat256 ,
        ipm2      : defnvrdat256
    };

    typedef struct packed{
        nvrdat_t            cfginfo;       //4
        nvrdat_t            nvrrev05;      //5
        cfgrrsub_t          cfgrrsub;      //6
        nvrdat_t            nvrrev07;      //7
        nvrdat_t            nvrrev08;      //8
        nvrdat_t            nvrrev09;      //9
        nvrdat_t            cfgsce;        //10
        nvrdat_t            nvrrev11;      //11
        cfgcore_t           cfgcore;       //12
        nvrdat_t            nvrrev13;      //13
        nvrdat_t            nvrrev14;      //14
        nvrdat_t            nvrrev15;      //15
        nvrdat_t            nvrrev16;      //16
        nvrdat_t            nvrrev17;      //17
        nvrdat_t            nvrrev18;      //18
        nvrdat_t            nvrrev19;      //19
        nvrdat_t            nvrrev20;      //20
        nvrdat_t            nvrrev21;      //21
        nvrdat_t            nvrrev22;      //22
        nvrdat_t            nvrrev23;      //23
        nvrdat_t            nvrrev24;      //24
        nvrdat_t            nvrrev25;      //25
        nvrdat_t            nvrrev26;      //26
        nvrdat_t            nvrrev27;      //27
        nvrdat_t            nvrrev28;      //28
        nvrdat_t            nvrrev29;      //29
        nvrdat_t            nvrrev30;      //30
        nvrdat_t            nvrrev31;      //31
    }nvrcfg_t;
    localparam nvrcfg_t defnvrcfg = '{
        cfginfo   : 256'hda11ccf9c0de ,
        nvrrev05  : defnvrdat256 ,
        cfgrrsub  : defcfgrrsub  ,
        nvrrev07  : defnvrdat256 ,
        nvrrev08  : defnvrdat256 ,
        nvrrev09  : defnvrdat256 ,
        cfgsce    : defnvrdat256 ,
        nvrrev11  : defnvrdat256 ,
        cfgcore   : defcfgcore   ,
        nvrrev13  : defnvrdat256 ,
        nvrrev14  : defnvrdat256 ,
        nvrrev15  : defnvrdat256 ,
        nvrrev16  : defnvrdat256 ,
        nvrrev17  : defnvrdat256 ,
        nvrrev18  : defnvrdat256 ,
        nvrrev19  : defnvrdat256 ,
        nvrrev20  : defnvrdat256 ,
        nvrrev21  : defnvrdat256 ,
        nvrrev22  : defnvrdat256 ,
        nvrrev23  : defnvrdat256 ,
        nvrrev24  : defnvrdat256 ,
        nvrrev25  : defnvrdat256 ,
        nvrrev26  : defnvrdat256 ,
        nvrrev27  : defnvrdat256 ,
        nvrrev28  : defnvrdat256 ,
        nvrrev29  : defnvrdat256 ,
        nvrrev30  : defnvrdat256 ,
        nvrrev31  : defnvrdat256
    };


endpackage

`define ambarrb(theblx) { 10'b0110_0000_00, theblx, 14'h0 }

