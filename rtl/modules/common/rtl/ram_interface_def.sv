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

`ifndef _RAM_INTERFACE_DEFINE

interface ramif #(
    parameter RAW=14,
    parameter BW=8,
    parameter DW=32
)();

    wire            ramen       ;
    wire            ramcs       ;
    wire  [RAW-1:0]  ramaddr     ;
    wire  [DW/BW-1:0]          ramwr       ;
    wire  [DW-1:0]  ramwdata    ;
    wire  [DW-1:0]  ramrdata    ;
    wire            ramready    ;

  modport slave (
    input  ramen      ,
    input  ramcs      ,
    input  ramaddr    ,
    input  ramwr      ,
    input  ramwdata   ,
    output ramrdata   ,
    output ramready
    );

  modport master (
    output ramen      ,
    output ramcs      ,
    output ramaddr    ,
    output ramwr      ,
    output ramwdata   ,
    input  ramrdata   ,
    input  ramready
    );

endinterface

module rams2wire
#(
    parameter AW=14,
    parameter DW=32,
    parameter BW=8
)(
    ramif.slave                  rams            ,
    output logic                 rams_ramen      ,
    output logic                 rams_ramcs      ,
    output logic [AW-1:0] rams_ramaddr    ,
    output logic [DW/BW-1:0]               rams_ramwr      ,
    output logic [DW-1:0] rams_ramwdata   ,
    input  logic [DW-1:0] rams_ramrdata   ,
    input  logic                 rams_ramready
);

    assign rams_ramen    = rams.ramen    ;
    assign rams_ramcs    = rams.ramcs    ;
    assign rams_ramaddr  = rams.ramaddr  ;
    assign rams_ramwr    = rams.ramwr    ;
    assign rams_ramwdata = rams.ramwdata ;
    assign rams.ramrdata = rams_ramrdata ;
    assign rams.ramready = rams_ramready ;

endmodule : rams2wire

module wire2ramm
#(
    parameter AW=14,
    parameter DW=32,
    parameter BW=8
)(
    input  logic                  ramm_ramen      ,
    input  logic                  ramm_ramcs      ,
    input  logic [AW-1:0]  ramm_ramaddr    ,
    input  logic [DW/BW-1:0]                 ramm_ramwr      ,
    input  logic [DW-1:0]  ramm_ramwdata   ,
    output logic [DW-1:0]  ramm_ramrdata   ,
    output logic                  ramm_ramready   ,
    ramif.master                  ramm
);

    assign ramm.ramen    = ramm_ramen    ;
    assign ramm.ramcs    = ramm_ramcs    ;
    assign ramm.ramaddr  = ramm_ramaddr  ;
    assign ramm.ramwr    = ramm_ramwr    ;
    assign ramm.ramwdata = ramm_ramwdata ;
    assign ramm_ramrdata = ramm.ramrdata ;
    assign ramm_ramready = ramm.ramready ;

endmodule : wire2ramm

module ramcut
#(
    parameter AW = 14
)(
    input [AW:0]                  ramaddrcut,
    input logic                   cuten,
    ramif.slave                   rams,
    ramif.master                  ramm
);

    logic ramcpvld;

    assign ramm.ramen    = rams.ramen    ;
    assign ramm.ramaddr  = rams.ramaddr  ;
    assign ramm.ramwdata = rams.ramwdata ;
    assign ramm.ramcs    = ramcpvld ? rams.ramcs : '0   ;
    assign ramm.ramwr    = ramcpvld ? rams.ramwr : '0   ;
    assign rams.ramrdata = ramm.ramrdata ;
    assign rams.ramready = ramm.ramready ;

    assign ramcpvld = cuten ? ( rams.ramaddr < ramaddrcut ):1;

endmodule : ramcut


module ram1sto2m(
    input logic                   sel,
    ramif.slave                   rams,
    ramif.master                  ramm0,
    ramif.master                  ramm1
);

    assign ramm0.ramen    = rams.ramen    ;
    assign ramm0.ramaddr  = rams.ramaddr  ;
    assign ramm0.ramwdata = rams.ramwdata ;
    assign ramm0.ramcs    = rams.ramcs    ;
    assign ramm0.ramwr    = rams.ramwr    ;

    assign ramm1.ramen    = rams.ramen    ;
    assign ramm1.ramaddr  = rams.ramaddr  ;
    assign ramm1.ramwdata = rams.ramwdata ;
    assign ramm1.ramcs    = rams.ramcs    ;
    assign ramm1.ramwr    = rams.ramwr    ;

    assign rams.ramrdata = sel ? ramm1.ramrdata : ramm0.ramrdata ;
    assign rams.ramready = sel ? ramm1.ramready : ramm0.ramready ;

endmodule : ram1sto2m

module ram2sto1m(
    input logic                   sel,
    ramif.slave                   rams0,
    ramif.slave                   rams1,
    ramif.master                  ramm
);

    assign ramm.ramen    = sel ? rams1.ramen    : rams0.ramen    ;
    assign ramm.ramaddr  = sel ? rams1.ramaddr  : rams0.ramaddr  ;
    assign ramm.ramwdata = sel ? rams1.ramwdata : rams0.ramwdata ;
    assign ramm.ramcs    = sel ? rams1.ramcs    : rams0.ramcs    ;
    assign ramm.ramwr    = sel ? rams1.ramwr    : rams0.ramwr    ;

    assign rams0.ramrdata = ramm.ramrdata ;
    assign rams0.ramready = ramm.ramready ;
    assign rams1.ramrdata = ramm.ramrdata ;
    assign rams1.ramready = ramm.ramready ;

endmodule : ram2sto1m

module __dummytb_ramif#(
    parameter AW=14,
    parameter DW=32
)();

//    parameter sram_pkg::sramcfg_t thecfg=sram_pkg::samplecfg;

    bit                    ramm_ramen    , rams_ramen    ;
    bit                    ramm_ramcs    , rams_ramcs    ;
    bit   [AW-1:0]  ramm_ramaddr  , rams_ramaddr  ;
    bit   [DW/8-1:0]                 ramm_ramwr    , rams_ramwr    ;
    bit   [DW-1:0]  ramm_ramwdata , rams_ramwdata ;
    bit   [DW-1:0]  ramm_ramrdata , rams_ramrdata ;
    bit                    ramm_ramready , rams_ramready ;
    ramif                  theramif(),  theramifa(), theramifb()     ;

    wire2ramm #(.AW(AW),.DW(DW)) u0(.ramm(theramif),.*);
    rams2wire #(.AW(AW),.DW(DW)) u1(.rams(theramif),.*);
    ramcut #(.AW(AW)        ) u2(.ramaddrcut('0),.cuten('0),.rams(theramifa),.ramm(theramifb));

    ramif                  ramm(), ramm0(), ramm1(), rams(), rams0(), rams1()     ;
    bit sel;
    ram1sto2m u5(.*);
    ram2sto1m u6(.*);


endmodule

`endif //`ifndef _INTERFACE_DEFINE

`define _RAM_INTERFACE_DEFINE

