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
//`include "amba_interface_def_v0.2.sv"

    `define apbs_common \
    assign apbx.pready = 1'b1; \
    assign apbx.pslverr = 1'b0; \
    assign apbrd = apbs.psel & apbs.penable & ~apbs.pwrite; \
    assign apbwr = apbs.psel & apbs.penable & apbs.pwrite
//    apbif #(.PAW(12),.DW(32))apbs(); \
//    apb_thru a0(.apbslave(apbs0),.apbmaster(apbs));\



/*
    logic apbrd, apbwr, sfrlock;
    `apbs_common;

    assign sfrlock = 1'b0;
    assign apbx.prdata =
                sfr_cr.prdata32 |
                sfr_sr.prdata32 |
                sfr_fr.prdata32 ;

    bit [15:0] sfrcr, sfrsr, sfrfr;
    logic sfrar;

    apb_cr #(.A('h10), .DW(16), .IV('hff))  sfr_cr    (.cr(sfrcr),  .prdata32(),.*);
    apb_sr #(.A('h14), .DW(16)           )  sfr_sr    (.sr(sfrsr),  .prdata32(),.*);
    apb_fr #(.A('h18), .DW(16)           )  sfr_fr    (.fr(sfrfr),  .prdata32(),.*);
    apb_ar #(.A('h1c), .AR('h32)         )  sfr_ar    (.ar(sfrar),              .*);
*/

module sfrdatrev
    #(
        parameter DW=16,
        parameter SFRCNT=4,
        parameter REVX=0,
        parameter REVY=0
    )(
        input  logic [0:SFRCNT-1][DW-1:0]   din,
        output logic [0:SFRCNT-1][DW-1:0]   dout
    );

    genvar x,y;

    generate
        for ( y = 0; y < SFRCNT ; y++ ) begin:gy
            for ( x = 0; x < DW ; x++ ) begin:gx
                assign dout[y][x] = ( {REVY,REVX} == 2'b01 ) ? din[         y][DW-1-x] :
                                    ( {REVY,REVX} == 2'b10 ) ? din[SFRCNT-1-y][     x] :
                                    ( {REVY,REVX} == 2'b11 ) ? din[SFRCNT-1-y][DW-1-x] :
                                                               din[         y][     x] ;
            end
        end
    endgenerate

endmodule

module apb_cr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16,
      parameter REVX=0,
      parameter REVY=0,
      parameter IV=32'h0,
      parameter SFRCNT=1,
//      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'hffff_ffff        // read mask to remove undefined bit
//      parameter REXTMASK=32'h0              // read ext mask
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrpaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrprdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        output logic [31:0]                 prdata32    ,
        output logic [0:SFRCNT-1][DW-1:0]   cr
);

    logic [0:SFRCNT-1][DW-1:0]   cr0;
    logic[DW-1:0] prdata;
    assign prdata32 = prdata | 32'h0;

    apb_sfr2 #(
            .AW          ( AW            ),
            .DW          ( DW            ),
            .IV          ( IV            ),
            .SFRCNT      ( SFRCNT        ),
            .RMASK       ( RMASK         ),      // read mask to remove undefined bit
            .FRMASK      ( 32'h0         ),      // set write 1 to clr ( for status reg )
            .SRMASK      ( 32'h0         )       // read ext mask
         )apb_sfr(
            .pclk        (pclk           ),
            .resetn      (resetn         ),
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock | '0   ),
            .sfrpaddr    (A[AW-1:0]      ),
            .sfrsr       ('0             ),
            .sfrfr       ('0             ),
            .sfrprdata   (prdata         ),
            .sfrdata     (cr0            )
         );

    sfrdatrev #(.DW(DW),.SFRCNT(SFRCNT),.REVX(REVX), .REVY(REVY)) dx(.din(cr0),.dout(cr));

endmodule

module apb_sr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16,
      parameter REVX=0,
      parameter REVY=0,
//      parameter IV=32'h0,                   // useless
      parameter SFRCNT=1,
//      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'hffff_ffff,        // read mask to remove undefined bit
      parameter SRMASK=32'hffff_ffff              // read ext mask
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrpaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrprdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        output logic [31:0]                 prdata32    ,
        input  logic [0:SFRCNT-1][DW-1:0]   sr
);


    logic [0:SFRCNT-1][DW-1:0]   sr0;
    logic[DW-1:0] prdata;
    assign prdata32 = prdata | 32'h0;

    apb_sfr2 #(
            .AW          ( AW            ),
            .DW          ( DW            ),
            .IV          ( '0            ),
            .SFRCNT      ( SFRCNT        ),
            .RMASK       ( RMASK         ),      // read mask to remove undefined bit
            .FRMASK      ( 32'h0         ),      // set write 1 to clr ( for status reg )
            .SRMASK      ( SRMASK        )       // read ext mask
         )apb_sfr(
            .pclk        (pclk           ),
            .resetn      (resetn         ),
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock|'0     ),
            .sfrpaddr    (A[AW-1:0]      ),
            .sfrsr       (sr0            ),
            .sfrfr       ('0             ),
            .sfrprdata   (prdata         ),
            .sfrdata     (               )
         );

    sfrdatrev #(.DW(DW),.SFRCNT(SFRCNT),.REVX(REVX), .REVY(REVY)) dx(.din(sr),.dout(sr0));

endmodule


module apb_fr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16,
      parameter REVX=0,
      parameter REVY=0,
//      parameter IV=32'h0,                   // useless
      parameter SFRCNT=1,
//      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'hffff_ffff,        // read mask to remove undefined bit
      parameter FRMASK=32'hffff_ffff              // read ext mask
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrpaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrprdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        output logic [31:0]                 prdata32    ,
        input  logic [0:SFRCNT-1][DW-1:0]   fr
);


    logic [0:SFRCNT-1][DW-1:0]   fr0;
    logic[DW-1:0] prdata;
    assign prdata32 = prdata | 32'h0;

    apb_sfr2 #(
            .AW          ( AW            ),
            .DW          ( DW            ),
            .IV          ( '0            ),
            .SFRCNT      ( SFRCNT        ),
            .RMASK       ( RMASK         ),      // read mask to remove undefined bit
            .FRMASK      ( FRMASK        ),      // set write 1 to clr ( for status reg )
            .SRMASK      ( '0            )       // read ext mask
         )apb_sfr(
            .pclk        (pclk           ),
            .resetn      (resetn         ),
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock|'0     ),
            .sfrpaddr    (A[AW-1:0]      ),
            .sfrsr       ('0             ),
            .sfrfr       (fr0            ),
            .sfrprdata   (prdata         ),
            .sfrdata     (               )
         );

    sfrdatrev #(.DW(DW),.SFRCNT(SFRCNT),.REVX(REVX), .REVY(REVY)) dx(.din(fr),.dout(fr0));

endmodule


module apb_ar
#(
      parameter A=0,
      parameter AW=12,
      parameter AR=32'h5a
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                          sfrlock     ,
        output bit                          ar
);


    logic sfrapbwr;
    apb_sfrop2 #(
            .AW          ( AW            )
         )apb_sfrop(
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock|'0     ),
            .sfrpaddr    (A[AW-1:0]      ),
            .apbrd       (               ),
            .apbwr       (sfrapbwr       )
         );

    `theregfull(pclk, resetn, ar, '0) <= sfrapbwr & ( apbs.pwdata == AR );

endmodule


    module apbm_null2( apbif.master apbmaster );
        assign apbmaster.psel      = 0 ;
        assign apbmaster.paddr     = 0 ;
        assign apbmaster.penable   = 0 ;
        assign apbmaster.pwrite    = 0 ;
        assign apbmaster.pstrb     = 0 ;
        assign apbmaster.pprot     = 0 ;
        assign apbmaster.pwdata    = 0 ;
        assign apbmaster.apbactive = 0 ;
    endmodule



module dummytb_apbsfr();

/*
    logic apbrd, apbwr, sfrlock;
    `apbs_common

    assign sfrlock = 1'b0;
    assign apbs.prdata =
                sfr_cr.prdata32 |
                sfr_sr.prdata32 |
                sfr_fr.prdata32 ;
*/
    apbif apbs();
    bit pclk, resetn, sfrlock;

    bit [15:0] sfrcr, sfrsr, sfrfr;
    logic sfrar;

    apb_cr #(.A('h10), .DW(16), .IV('hff))  sfr_cr    (.cr(sfrcr),  .prdata32(),.*);
    apb_sr #(.A('h14), .DW(16)           )  sfr_sr    (.sr(sfrsr),  .prdata32(),.*);
    apb_fr #(.A('h18), .DW(16)           )  sfr_fr    (.fr(sfrfr),  .prdata32(),.*);
    apb_ar #(.A('h1c), .AR('h32)         )  sfr_ar    (.ar(sfrar),              .*);
    apbm_null2 u0(apbs);
endmodule


// chg sr to fr.

    module apb_sfr2 #(
      parameter AW=12,
      parameter DW=32,
      parameter [DW-1:0] IV='0,
      parameter SFRCNT=1,
      parameter RMASK=32'hffff_ffff,    // read mask to remove undefined bit
      parameter FRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter SRMASK=32'h0              // read ext mask
     )(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbslave    ,
        input  bit                          sfrlock     ,
        input  bit   [AW-1:0]               sfrpaddr    ,
        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr,
        input  bit   [0:SFRCNT-1][DW-1:0]   sfrfr       ,
//        output logic [0:SFRCNT-1]           sfrsel      ,
        output logic [DW-1:0]               sfrprdata   ,
        output logic [0:SFRCNT-1][DW-1:0]   sfrdata

     );

    bit [0:SFRCNT-1][DW-1:0] sfrprdata0, sfrprdatas;
    bit [0:SFRCNT-1][DW-1:0] sfrdatarr;//={SFRCNT{IV}};
    bit [0:SFRCNT-1][DW-1:0] sfrdatasr;//{SFRCNT{IV}};
    bit [0:SFRCNT-1]           sfrsel ;
    logic apbrd, apbwr;
    assign apbrd = apbslave.psel & apbslave.penable & ~apbslave.pwrite;
    assign apbwr = ~sfrlock & apbslave.psel & apbslave.penable & apbslave.pwrite;
    bit [DW-1:0]    sIV = IV;

    genvar i;
    generate
    for( i = 0; i < SFRCNT; i = i + 1) begin: GenRnd
        `theregfull( pclk, resetn, sfrdatarr[i], IV ) <= ( sfrsel[i] & apbwr ) ? apbslave.pwdata : sfrdatarr[i];
        `theregfull( pclk, resetn, sfrdatasr[i], '0 ) <= ( sfrsel[i] & apbwr ) ? ( ~apbslave.pwdata & sfrdatasr[i] ) : ( sfrdatasr[i] | sfrfr[i] );
        assign sfrdata[i] = ~FRMASK & sfrdatarr[i] | FRMASK & sfrdatasr[i];
        assign sfrsel[i] = ( apbslave.paddr == sfrpaddr[AW-1:0] + 4*i );
        assign sfrprdata0[i] = sfrdata[i] & ~SRMASK |  sfrsr[i] & SRMASK;
        assign sfrprdatas[i] = apbrd & sfrsel[i] ? sfrprdata0[i] & RMASK : 0;
    end
    endgenerate

    assign sfrprdata = fnsfrprdata(sfrprdatas);

    function bit[DW-1:0]    fnsfrprdata ( bit [0:SFRCNT-1][DW-1:0] fnsfrprdatas );
        bit [DW-1:0] fnvalue;
        int i;
        fnvalue = 0;
        for( i = 0; i <  SFRCNT ; i = i + 1) begin
            fnvalue = fnvalue | fnsfrprdatas[i];
        end
        fnsfrprdata = fnvalue;
    endfunction


    endmodule


    module apb_sfrop2 #(
      parameter AW=12
     )(
        apbif.slavein                         apbslave    ,
        input  bit                          sfrlock     ,
        input  bit   [AW-1:0]               sfrpaddr    ,
        output logic                        apbrd       ,
        output logic                        apbwr

     );
    localparam  SFRCNT = 1;
    logic       sfrsel ;
    assign sfrsel = ( apbslave.paddr == sfrpaddr[AW-1:0] );
    assign apbrd = apbslave.psel & apbslave.penable & ~apbslave.pwrite & sfrsel;
    assign apbwr = ~sfrlock & apbslave.psel & apbslave.penable & apbslave.pwrite & sfrsel;

    endmodule