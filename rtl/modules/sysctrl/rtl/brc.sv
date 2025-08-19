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
import nvrcfg_pkg::*;

module brc#(
    parameter BRC  = 128,
    parameter BRCW = $clog2(BRC),
    parameter BRDW = 256,
    parameter BRNUM_CMS = 1,
    parameter BRNUM_IPM = 3,
    parameter BRNUM_CFG = 12,
    parameter CW = 32,
    parameter SCFGWC = BRDW/CW,
    parameter IPMDC = BRNUM_IPM * BRDW / CW,
    parameter CFGDC = BRNUM_CFG * BRDW / CW,
    parameter type CMSD_t = logic
)(
    input logic     clk,
    input logic     resetn,

    input  logic                brvld,
    input  logic [BRCW-1:0]     bridx,
    input  logic [BRDW-1:0]     brdat,
    input  logic                brdone,
    output logic [3:0]          brready,

// cms
//    output logic cmsdatavld
    output nvrcfg_pkg::nvrcms_t     nvrcmsdata,
    output logic                    cmsdatavld,
    input  logic                    cmsdone,

// ipc
//
//    output logic [IPMDC-1:0][31:0]  iptrim32,
    output nvrcfg_pkg::nvripm_t     nvripmdata,
    output logic                    iptrimdatavld,
    output logic                    iptrimdataset,
    input  logic                    iptrimready,

// syscfg
//
//    output logic [CFGDC-1:0][31:0]  syscfg32
    output nvrcfg_pkg::nvrcfg_t     nvrcfgdata

//    output logic            syscfgdatavld
//    input  logic            iptrimready,

);

    logic                brvld_reg;
    logic                brvld_pl1, brvld_pl2;
    logic [BRCW-1:0]     bridx_pl1, bridx_pl2;


 //  `theregrn( brvld_reg ) <= brvld | brvld_reg;
    `theregrn( brvld_pl1 ) <= brvld;   // ( brvld_reg & brvld );
    `theregrn( brvld_pl2 ) <= brvld_pl1;
    `theregrn( bridx_pl1 ) <= bridx; //brvld ? bridx : bridx_pl1;
    `theregrn( bridx_pl2 ) <= bridx_pl1;


    bit [0:BRNUM_IPM-1][BRDW-1:0] iptrimdata;
    generate
        for (genvar i = 0; i < BRNUM_IPM; i++) begin
        `theregrn( iptrimdata[i] ) <= ( bridx_pl2 == i + BRNUM_CMS ) & brvld_pl2 ? brdat : iptrimdata[i];
        end
    endgenerate

    bit [0:BRNUM_CFG-1][BRDW-1:0] syscfgdata;
    generate
        for (genvar i = 0; i < BRNUM_CFG; i++) begin
        `theregrn( syscfgdata[i] ) <= ( bridx_pl2 == i + BRNUM_IPM + BRNUM_CMS ) & brvld_pl2 ? brdat : syscfgdata[i];
        end
    endgenerate
/*
   `theregrn( brvld_reg ) <= brvld | brvld_reg;
//    assign brvld_pl1 = ( brvld_reg & brvld );
    assign brvld_pl1 = brvld ;
    `theregrn( brvld_pl2 ) <= brvld_pl1;
    `theregrn( bridx_pl1 ) <= brvld ? bridx : bridx_pl1;
    `theregrn( bridx_pl2 ) <= bridx_pl1;


    bit [0:BRNUM_IPM-1][BRDW-1:0] iptrimdata;
    generate
        for (genvar i = 0; i < BRNUM_IPM; i++) begin
        `theregrn( iptrimdata[i] ) <= ( bridx_pl2 == i + BRNUM_CMS ) & brvld_pl2 ? brdat : iptrimdata[i];
        end
    endgenerate

    bit [0:BRNUM_CFG-1][BRDW-1:0] syscfgdata;
    generate
        for (genvar i = 0; i < BRNUM_CFG; i++) begin
        `theregrn( syscfgdata[i] ) <= ( bridx_pl2 == i + BRNUM_IPM + BRNUM_CMS ) & brvld_pl2 ? brdat : syscfgdata[i];
        end
    endgenerate
*/
    logic iptrimdatavldreg;

`ifdef FPGA
    assign cmsdatavld = '1;
    `theregrn( iptrimdatavld ) <= '1;
    assign nvrcmsdata = nvrcfg_pkg::defnvrcms;
    assign nvripmdata = nvrcfg_pkg::defnvripm;
    assign nvrcfgdata = nvrcfg_pkg::defnvrcfg;
    assign brready[3:0] = '1;
    assign iptrimdataset = '0;
`else
    assign cmsdatavld = ( bridx_pl2 == BRNUM_CMS - 1 ) & brvld_pl2;
    `theregrn( iptrimdatavld ) <=  ( bridx_pl2 == BRNUM_IPM + BRNUM_CMS -1 ) & brvld_pl2;
    assign brready[0] = cmsdone;
    assign brready[1] = iptrimready;
    assign brready[3:2] = '1;
    assign nvrcmsdata = {brdat};
    assign nvripmdata = iptrimdata;
    assign nvrcfgdata = syscfgdata;
    `theregrn( iptrimdatavldreg ) <= iptrimdatavld;
    `theregrn( iptrimdataset ) <= iptrimdatavld & ~iptrimdatavldreg;
`endif


endmodule : brc
