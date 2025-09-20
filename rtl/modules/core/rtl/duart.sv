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

module duart (
    input logic     clk,
    input logic     sclk,
    input logic     resetn,
    apbif.slavein     apbs,
    apbif.slave     apbx,
    output logic    txd
);

    localparam INITETU = 'd32;

    logic pclk;
    assign pclk = clk;
    logic apbrd, apbwr, sfrlock;
    assign sfrlock = '0;

    `apbs_common;
    assign apbx.prdata = '0 |
                sfr_cr.prdata32 |
                sfr_sr.prdata32 |
                sfr_etuc.prdata32 |
                sfr_txd.prdata32;

    logic [7:0] sfrtxd, txdata;
    logic sfrcr, sfrsr, txbusy, sfrcr_txen, txstart_pclk, txstart, txdone, txdone_pclk, txen, etuhit, txbusy0, txdonereg;
    logic [15:0] sfretu, etunum, etucnt;
    logic [2:0] txenregs;

    apb_cr #(.A('h00), .DW(8 ),    .IV('0))   sfr_txd      (.cr(sfrtxd),   .prdata32(),.*);
    apb_cr #(.A('h04), .DW(1),     .IV('1))   sfr_cr       (.cr(sfrcr),    .prdata32(),.*);
    apb_sr #(.A('h08), .DW(1)             )   sfr_sr       (.sr(sfrsr),    .prdata32(),.*);
    apb_cr #(.A('h0C), .DW(16),   .IV(INITETU))  sfr_etuc     (.cr(sfretu),   .prdata32(),.*);

    `theregrn( txbusy ) <= txstart_pclk ? '1 : txdone_pclk ? '0 : txbusy;
`ifdef SIM
    assign sfrsr = '0;
`else
    assign sfrsr = txbusy;
`endif
    assign sfrcr_txen = sfrcr;

// sync

    `theregrn( txstart_pclk ) <= apbwr & sfrcr_txen & ( apbs.paddr == '0 ) & ~txbusy;
        sync_pulse s0(
            .clka       (pclk),
            .resetn     (resetn),
            .pulsea     (txstart_pclk),
            .clkb       (sclk),
            .pulseb     (txstart)
            );

        sync_pulse s1(
            .clka       (sclk),
            .resetn     (resetn),
            .pulsea     (txdone),
            .clkb       (pclk),
            .pulseb     (txdone_pclk)
            );

    assign txdata = sfrtxd;

    `theregfull( sclk, resetn, txenregs, '1 ) <= { txenregs, sfrcr_txen };
    assign txen = txenregs[2];

`ifdef SIM
    `theregfull( sclk, resetn, etunum, INITETU ) <= 2;
`else
    `theregfull( sclk, resetn, etunum, INITETU ) <= ( ~txenregs[2] & txenregs[1] ) ? sfretu : etunum ;

`endif

// etu


    `theregfull(sclk, resetn, etucnt, '0) <=  txdone || ( etucnt == etunum ) || ~txen ? 0 : etucnt + txbusy0;
    `theregfull(sclk, resetn, etuhit, '0) <=  ( etucnt == etunum );

//  fsm

    bit [3:0] txfsm;
    bit [11:0] txstreamdata;

    `theregfull(sclk, resetn, txfsm, '0) <= txdone ? 4'h0 : etuhit ? ( txfsm + 4'h1 ) : txfsm;
    `theregfull(sclk, resetn, txdonereg, '0) <= txdone;
    `theregfull(sclk, resetn, txbusy0, '0 ) <= txstart ? 1'b1 : txdone ? '0 : txbusy0;
      assign txdone = ( txfsm == 4'ha ) & etuhit;

    `theregfull(sclk, resetn, txstreamdata, '1 ) <= txstart ? { 1'b1, txdata, 1'b0,1'b1, 1'b1} : etuhit ? { 1'b1, txstreamdata[ 11:1] }: txstreamdata;

    assign txd = txstreamdata[0];




// print to simulation

`ifdef SIM
    localparam CHARLEN = 256;
    logic                       charbufwr, charbuffill, charbufclr;
    bit [$clog2(CHARLEN)-1:0]   charbufidx;
    bit [0:CHARLEN-1][7:0]      charbufdat;
    string charbufstring;
    assign charbufwr = apbwr & ( apbs.paddr == '0 );
    assign charbuffill = charbufwr & ~(( apbs.pwdata[7:0] == 'h0d ) | ( apbs.pwdata[7:0] == 'h0a ));
    assign charbufclr  = charbufwr &  (( apbs.pwdata[7:0] == 'h0d ) | ( apbs.pwdata[7:0] == 'h0a ));

    `theregrn( charbufidx ) <= charbufclr ? '0 : charbuffill ? charbufidx + 1 : charbufidx;
    `theregrn( charbufdat[charbufidx] ) <= charbuffill ? apbs.pwdata[7:0] : charbufdat[charbufidx];

    always@( negedge clk )
    if( apbwr )  begin
        if( charbufclr ) begin
            charbufstring = charbufdat;
            if (charbufidx != 0) // this causes lone '\n' or '\r' to be skipped, effectively collapsing '\n\r' sequences to just '\n'
                $display("[duart] %s", charbufstring );
            charbufdat = '0;
        end
    end
`endif

endmodule
