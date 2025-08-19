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

module ao_peri (
            input logic           pclk   ,
            input logic           presetn,
            input logic           cmsatpg,

            apbif.slave  apbs[0:2],

            input logic clk32k ,
            input logic clk1hz ,

            output logic wdtintr,
            output logic tmrintr ,
            output logic rtcintr,
            output logic wdtrst
);

    localparam PAW = 12;
    logic tmrintrl, tmrintrh;
    logic [4:0] clk1kcnt;
    logic clk1k, clk1ken;

    `theregfull( clk32k, presetn, clk1kcnt, '0 ) <= clk1kcnt + 1;
    `theregfull( clk32k, presetn, clk1ken, '0 ) <= ( clk1kcnt == '1 ) ;

    ICG_hvt uclk1k ( .CK (clk32k), .SE(cmsatpg), .EN (clk1ken), .CKG(clk1k));

  Rtc  urtc (

    .PCLK            (pclk),
    .PRESETn         (presetn),
    .PENABLE         (apbs[0].penable),
    .PSEL            (apbs[0].psel),
    .PADDR           (apbs[0].paddr[11:2]),
    .PWRITE          (apbs[0].pwrite),
    .PWDATA          (apbs[0].pwdata),
    .PRDATA          (apbs[0].prdata),

    .CLK1HZ          (clk1hz),
    .nRTCRST         (presetn),
    .nPOR            (presetn),

    .SCANINPCLK      ('0),
    .SCANINCLK1HZ    ('0),
    .SCANOUTPCLK     (),
    .SCANOUTCLK1HZ   (),
    .SCANENABLE      ('0),

    .RTCINTR         (rtcintr)

    );

  cmsdk_apb_watchdog uwdt (
   // Inputs
    .PCLK            (pclk),
    .PRESETn         (presetn),
    .PENABLE         (apbs[1].penable),
    .PSEL            (apbs[1].psel),
    .PADDR           (apbs[1].paddr[11:2]),
    .PWRITE          (apbs[1].pwrite),
    .PWDATA          (apbs[1].pwdata),
    .PRDATA          (apbs[1].prdata),

    .WDOGCLK           (clk1k),
    .WDOGCLKEN         (1'b1),
    .WDOGRESn          (presetn),
    .ECOREVNUM         (4'h0),// Engineering-change-order revision bits
   // Outputs
    .WDOGINT           (wdtintr),  // connect to NMI
    .WDOGRES           (wdtrst)   // connect to reset generator
  );

    logic ref1k;
    assign ref1k = cmsatpg ? 1'b0 : clk1k;
    apb_timer_unit #(.APB_ADDR_WIDTH(PAW)) utmr (
        .HCLK       ( pclk          ),
        .HRESETn    ( presetn       ),
        .PADDR      ( apbs[2].paddr ),
        .PWDATA     ( apbs[2].pwdata  ),
        .PWRITE     ( apbs[2].pwrite  ),
        .PSEL       ( apbs[2].psel    ),
        .PENABLE    ( apbs[2].penable ),
        .PRDATA     ( apbs[2].prdata  ),
        .PREADY     ( apbs[2].pready),
        .PSLVERR    ( apbs[2].pslverr),
        .ref_clk_i  ( ref1k         ),
        .event_lo_i ( '0 ),
        .event_hi_i ( '0 ),
        .irq_lo_o   ( tmrintrl    ),
        .irq_hi_o   ( tmrintrh    ),
        .busy_o     (            )
    );

    logic tmrintrl_sync, tmrintrh_sync;
    sync_pulse synccell_tmrintrl ( .clka(pclk), .resetn(presetn), .clkb(clk32k), .pulsea (tmrintrl), .pulseb( tmrintrl_sync ) );
    sync_pulse synccell_tmrintrh ( .clka(pclk), .resetn(presetn), .clkb(clk32k), .pulsea (tmrintrh), .pulseb( tmrintrh_sync ) );

    assign tmrintr = tmrintrl_sync | tmrintrh_sync;
    assign apbs[1].pready = '1;
    assign apbs[1].pslverr = '0;
    assign apbs[0].pready = '1;
    assign apbs[0].pslverr = '0;

endmodule : ao_peri
