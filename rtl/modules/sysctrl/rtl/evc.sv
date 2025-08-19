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


module evc#(
    parameter CM7EVCNT = 8,
    parameter ERRCNT = 32,
    parameter EVCNT = 256,
    parameter IRQCNT = EVCNT,
    parameter RRCEVCNT = 16
)(
    input logic   hclk,
    input logic   pclk,
    input logic   resetn,
    apbif.slavein apbs,
    apbif.slave   apbx,

    input logic [EVCNT-1:0] evin,
    input logic [ERRCNT-1:0] errin,

    // m7
    output logic [IRQCNT-1:0] cm7irq,
    output logic              cm7ev,
    output logic              cm7nmi,

    // ifsub
    output logic              ifev_vld,
    output logic [7:0]        ifev_dat,
    input  logic              ifev_rdy,
    output logic              ifev_err,

    // timer
    output logic [1:0]          tmr_ev,
    output logic [RRCEVCNT-1:0] rrc_ev

    // mdma

);

    logic [ERRCNT-1:0] erren;
    logic apbrd, apbwr;
    logic clk;
    assign clk = hclk;

// m7
    localparam EVCNTW = $clog2(EVCNT);

    logic [CM7EVCNT-1:0]              cm7evs, cm7even;
    logic [CM7EVCNT-1:0][EVCNTW-1:0]  cm7evsel;

    `theregrn( cm7irq ) <= evin;
    generate
        for (genvar i = 0; i < CM7EVCNT; i++) begin: gencm7ev
             `theregrn( cm7evs[i] ) <= cm7even[i] & evin[cm7evsel[i]];
        end
    endgenerate

    assign cm7ev = |cm7evs;
    assign cm7nmi = |(errin&erren);

// mdma

// timer

    logic [1:0]               tmr_even;
    logic [1:0][EVCNTW-1:0]   tmr_evsel;


      `theregrn( tmr_ev[0] ) <= tmr_even[0] & evin[tmr_evsel[0]];
      `theregrn( tmr_ev[1] ) <= tmr_even[1] & evin[tmr_evsel[1]];

// rrc
    logic [RRCEVCNT-1:0]               rrc_even;
    logic [RRCEVCNT-1:0][EVCNTW-1:0]   rrc_evsel;

    generate
        for (genvar m= 0; m< RRCEVCNT; m++) begin: genrrcev
             `theregrn( rrc_ev[m] ) <= rrc_even[m] & evin[rrc_evsel[m]];
        end
    endgenerate

// ifsub

    logic [EVCNT-1:0]     ifeven, ifev_errs, s_req, s_ack, s_grant;
    logic                 s_event_ready, s_event_valid;
    assign ifev_err = |(ifev_errs);
    assign ifev_vld = |( s_grant & ifeven );
    assign s_event_ready = ifev_vld ? ifev_rdy : 1'b1;

//    assign s_events = {s_ls_rise,r_apb_events,per_events_i};

    assign s_ack = s_grant & {EVCNT{s_event_ready}};

    generate
        for (genvar j=0;j<EVCNT;j++) begin: genqueue
            soc_event_queue u_soc_event_queue (
                .clk_i       ( clk        ),
                .rstn_i      ( resetn     ),
                .event_i     ( evin[j] & ifeven[j] ),
                .err_o       ( ifev_errs[j]    ),
                .event_o     ( s_req[j]    ),
                .event_ack_i ( s_ack[j]    )
            );
        end
    endgenerate

    soc_event_arbiter #(.EVNT_NUM(EVCNT)) u_arbiter (
        .clk_i       ( clk           ),
        .rstn_i      ( resetn        ),
        .req_i       ( s_req         ),
        .grant_o     ( s_grant       ),
        .grant_ack_i ( s_event_ready ),
        .anyGrant_o  ( s_event_valid )
    );

    always_comb begin : proc_data_o
        ifev_dat = 'h0;
        for (int k=0;k<EVCNT;k++)
            if(s_grant[k])
                ifev_dat = k;
    end

// sfr
// ==

    `apbs_common;
    logic sfrlock;
    assign sfrlock = '0;
    assign apbx.prdata = '0
                | sfr_cm7evsel.prdata32 |  sfr_cm7even.prdata32 | sfr_cm7evfr.prdata32 | sfr_cm7errfr.prdata32
                | sfr_tmrevsel.prdata32 | sfr_rrcevsel.prdata32 | sfr_tmreven.prdata32 | sfr_rrceven.prdata32
                | sfr_ifeven.prdata32   | sfr_ifeverrfr.prdata32 | sfr_cm7errcr.prdata32
                ;

apb_cr #(.A('h00), .DW(EVCNTW), .REVY(1), .SFRCNT(CM7EVCNT))  sfr_cm7evsel  (.cr(cm7evsel),   .prdata32(),.*);
apb_cr #(.A('h20), .DW(CM7EVCNT)                 )  sfr_cm7even   (.cr(cm7even),    .prdata32(),.*);
apb_fr #(.A('h24), .DW(CM7EVCNT)                 )  sfr_cm7evfr   (.fr(cm7evs),     .prdata32(),.*);

apb_cr #(.A('h30), .DW(EVCNTW*2)                 )  sfr_tmrevsel  (.cr(tmr_evsel),  .prdata32(),.*);
apb_cr #(.A('h34), .DW(2)                        )  sfr_tmreven  (.cr(tmr_even),  .prdata32(),.*);

apb_cr #(.A('h40), .DW(32), .REVY(1), .SFRCNT(EVCNT/32))  sfr_ifeven    (.cr(ifeven ),    .prdata32(),.*);
apb_fr #(.A('h60), .DW(32), .REVY(1), .SFRCNT(EVCNT/32))  sfr_ifeverrfr (.fr(ifev_errs),  .prdata32(),.*);

apb_fr #(.A('h80), .DW(ERRCNT)                   )  sfr_cm7errfr  (.fr(errin),      .prdata32(),.*);
apb_cr #(.A('h84), .DW(ERRCNT), .IV(0)           )  sfr_cm7errcr  (.cr(erren),      .prdata32(),.*);

apb_cr #(.A('h90), .DW(EVCNTW*4), .REVY(1), .SFRCNT(RRCEVCNT/4))  sfr_rrcevsel  (.cr(rrc_evsel),   .prdata32(),.*);
apb_cr #(.A('hA0), .DW(RRCEVCNT)                )  sfr_rrceven  (.cr(rrc_even),  .prdata32(),.*);




endmodule : evc
