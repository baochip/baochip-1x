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

module wdg_intf (
    input logic     clk,
    input logic     resetn,
    input logic     wdgclk,
    apbif.slave     apbs,
    output logic    wdgintr,
    output logic    wdgrst
);
  cmsdk_apb_watchdog u_apb_watchdog (
   // Inputs
    .PCLK              (clk),
    .PRESETn           (resetn),
    .PENABLE           (apbs.penable),
    .PSEL              (apbs.psel),
    .PADDR             (apbs.paddr[11:2]),
    .PWRITE            (apbs.pwrite),
    .PWDATA            (apbs.pwdata),
    .WDOGCLK           (wdgclk),
    .WDOGCLKEN         (1'b1),
    .WDOGRESn          (resetn),
    .ECOREVNUM         (4'h0),// Engineering-change-order revision bits
   // Outputs
    .PRDATA            (apbs.prdata),
    .WDOGINT           (wdgintr),  // connect to NMI
    .WDOGRES           (wdgrst)   // connect to reset generator
  );

  assign apbs.pready = '1;
  assign apbs.pslverr = '0;

endmodule
/*
module dbguart_intf (
    input logic     clk,
    input logic     clksys,
    input logic     resetn,
    apbif.slave     apbs,
    output logic    txd,
    output logic    duartintr
);
  debuguart u_apb_uart_0 (
    .PCLK              (clk),     // Peripheral clock
    .PCLKG             (clk),    // Gated PCLK for bus
    .PRESETn           (resetn),  // Reset

    .PENABLE           (apbs.penable),
    .PSEL              (apbs.psel),
    .PADDR             (apbs.paddr[11:2]),
    .PWRITE            (apbs.pwrite),
    .PWDATA            (apbs.pwdata),
    .PRDATA            (apbs.prdata),
    .PREADY            (apbs.pready),
    .PSLVERR           (apbs.pslverr),

    .ECOREVNUM         (4'h0),// Engineering-change-order revision bits

    .RXD               ('1),      // Receive data

    .TXD               (txd),      // Transmit data
    .TXEN              (),     // Transmit Enabled

    .BAUDTICK          (),   // Baud rate x16 tick output (for testing)

    .TXINT             (),       // Transmit Interrupt
    .RXINT             (),       // Receive  Interrupt
    .TXOVRINT          (),    // Transmit Overrun Interrupt
    .RXOVRINT          (),    // Receive  Overrun Interrupt
    .UARTINT           (duartintr) // Combined Interrupt
  );
endmodule
*/
module timer_intf #( parameter PAW = 12 ) (
    input logic     clk,
    input logic     resetn,
    apbif.slave     apbs,
    input logic     lclk,
    input logic [1:0] evin,
    output logic [1:0] tmintr
);

    apb_timer_unit #(.APB_ADDR_WIDTH(PAW)) i_apb_timer_unit (
        .HCLK       ( clk          ),
        .HRESETn    ( resetn       ),
        .PADDR      ( apbs.paddr[PAW-1:0]   ),
        .PWDATA     ( apbs.pwdata  ),
        .PWRITE     ( apbs.pwrite  ),
        .PSEL       ( apbs.psel    ),
        .PENABLE    ( apbs.penable ),
        .PRDATA     ( apbs.prdata  ),
        .PREADY     ( apbs.pready  ),
        .PSLVERR    ( apbs.pslverr ),
        .ref_clk_i  ( lclk         ),
        .event_lo_i ( evin[0]      ),
        .event_hi_i ( evin[1]      ),
        .irq_lo_o   ( tmintr[0]    ),
        .irq_hi_o   ( tmintr[1]    ),
        .busy_o     (              )
    );

endmodule 
