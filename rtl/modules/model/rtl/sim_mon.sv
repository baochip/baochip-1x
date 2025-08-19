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


module sim_mon (
    input logic     clk,
//    input logic     resetn,
    apbif.slavein   apbs,
    apbif.slave     apbx
);

    logic pclk;
    logic apbrd, apbwr, sfrlock;
    `apbs_common;
    logic resetn = '1;
    assign sfrlock = 1'b0;
    assign apbx.prdata = 
                mondat32.prdata32 |
                mondat16.prdata32 |
                mondat_8.prdata32 ;

    bit [0:15][31:0] mdat32;
    bit [0:15][15:0] mdat16;
    bit [0:15][ 7:0] mdat_8;
    logic mtimer, mdone;
    logic [7:0]     mchar;
    string charbufstring;

    assign pclk = clk;

    apb_cr #(.A('h00), .DW(32), .SFRCNT(16))  mondat32    (.cr(mdat32),  .prdata32(),.*);
    apb_cr #(.A('h40), .DW(16), .SFRCNT(16))  mondat16    (.cr(mdat16),  .prdata32(),.*);
    apb_cr #(.A('h80), .DW( 8), .SFRCNT(16))  mondat_8    (.cr(mdat_8),  .prdata32(),.*);
//    apb_cr #(.A('hC0), .DW( 8)             )  monchar     (.cr(mchar),   .prdata32(),.*);

    localparam CHARLEN = 256;
    logic                       charbufwr, charbuffill, charbufclr;
    bit [$clog2(CHARLEN)-1:0]   charbufidx;
    bit [0:CHARLEN-1][7:0]      charbufdat;

    assign charbufwr = apbwr & ( apbs.paddr == 'hC0 );
    assign charbuffill = charbufwr & ~(( apbs.pwdata[7:0] == 'h0d ) | ( apbs.pwdata[7:0] == 'h0a ));
    assign charbufclr  = charbufwr &  (( apbs.pwdata[7:0] == 'h0d ) | ( apbs.pwdata[7:0] == 'h0a ));

    `theregrn( charbufidx ) <= charbufclr ? '0 : charbuffill ? charbufidx + 1 : charbufidx;
    `theregrn( charbufdat[charbufidx] ) <= charbuffill ? apbs.pwdata[7:0] : charbufdat[charbufidx];


    apb_ar #(.A('hC4), .AW(12)             )  montimer    (.ar(mtimer), .*);
    apb_ar #(.A('hFC), .AW(12)             )  simdone     (.ar(mdone),  .*);

    always@( negedge clk )
    if( apbwr )  begin
        if( mondat32.apb_sfr.apbwr & ~(mondat32.apb_sfr.sfrsel==0) )
            $display("%08t - @i: mondat32[%02d]::%08x",$realtime(),mondat32.apb_sfr.apbslave.paddr[5:2],mondat32.apb_sfr.apbslave.pwdata[31:0]);
        if( mondat16.apb_sfr.apbwr & |mondat16.apb_sfr.sfrsel )
            $display("%08t - @i: mondat16[%02d]::%04x",$realtime(),mondat16.apb_sfr.apbslave.paddr[5:2],mondat16.apb_sfr.apbslave.pwdata[15:0]);
        if( mondat_8.apb_sfr.apbwr & |mondat_8.apb_sfr.sfrsel )
            $display("%08t - @i: mondat_8[%02d]::%02x",$realtime(),mondat_8.apb_sfr.apbslave.paddr[5:2],mondat_8.apb_sfr.apbslave.pwdata[7:0]);
//        if( monchar.apb_sfr.apbwr & |monchar.apb_sfr.sfrsel )
//            $display("%08t - @i: mondat_8[%02d]::%08x",$realtime(),mondat_8.apb_sfr.apbslave.paddr[5:2],mondat_8.apb_sfr.apbslave.pwdata[7:0]);
//            $write("!!!%c", apbs.pwdata[7:0]);
//            $display("!!%c", apbs.pwdata[7:0]);
        if( charbufclr ) begin
            charbufstring = charbufdat;
//            charbufstring = charbufstring.substr(0,charbufidx);
            $display("[console] %s", charbufstring );
            charbufdat = '0;
        end

        if( montimer.apb_sfrop.apbwr & |montimer.apb_sfrop.sfrsel )
            $display("%08t - @i: timemark: %02x", $realtime, montimer.apb_sfrop.apbslave.pwdata[7:0]);
        if( simdone.apb_sfrop.apbwr & |simdone.apb_sfrop.sfrsel ) begin
            $display("%08t - @i: simdone: %02x", $realtime, simdone.apb_sfrop.apbslave.pwdata[7:0]);
            #( 10 `US );
            $finish;
        end
    end

    initial
    begin
    end


endmodule
