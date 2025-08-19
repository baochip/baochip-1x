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

module udma_spis_txrx
(


        input  logic            clk,
        input  logic            resetn,
        input  logic            cmsatpg,
        input  logic            cpol,
        input  logic            cpha,

        input  logic [15:0]     cfgrxcnt,
        input  logic [15:0]     cfgtxcnt,
        input  logic [15:0]     cfgdmcnt,

//      input  logic            cfg_en_i,
//      input  logic            cfg_parity_en_i,??
//      input  logic  [1:0]     cfg_bits_i,
//      input  logic            cfg_stop_bits_i,

        input  logic            sclk,
        input  logic            scsn,
        input  logic            smosi,
        output logic            smiso,
        output logic            smisooe,

        output logic            seot,

        input  logic  [7:0]     tx_fifo_i,
        output logic            tx_fifo_rd,

        output logic  [7:0]     rx_fifo_o,
        output logic            rx_fifo_wr
);

    logic clktx0, clkrx0, spiresetn, clktx, clkrx;
    logic [19:0] sbitcnt;
    logic scsnreg0, scsnreg;
    logic [7:0] txdat, rxdat;
    logic txdatrd, rxdatwr, txdatrd3;
    logic txdatrdtog, rxdatwrtog;
    logic [1:0] txdatrdtogregs, rxdatwrtogregs, rxdatwrregs;
    logic tx_fifo_rd0, rx_fifo_wr0;
    logic [17:0] txcnt, rxcnt;
    logic fsmrx, fsmdm, fsmtx;
    logic txdaten;
    logic ssot;

    assign clktx0 = cpol ^ cpha ?  sclk : ~sclk;
    assign clkrx0 = cpol ^ cpha ? ~sclk :  sclk;

    assign smisooe = ~scsn;

    assign spiresetn = cmsatpg ? resetn : ~scsn;
    assign clktx = cmsatpg ? clk : clktx0;
    assign clkrx = cmsatpg ? clk : clkrx0;

    udma_spis_tx tx(
        .clk      ( clktx ),
        .resetn   ( spiresetn ),
        .cpha     ,
        .txbit    ( smiso ),
        .txdat    ( txdat ),
        .txdatrd  ( txdatrd ),
        .txdatrd3 ( txdatrd3 ),
        .sbitcnt  ( sbitcnt )
    );

    udma_spis_rx rx(
        .clk         ( clkrx ),
        .resetn      ( spiresetn ),
        .rxbit       ( smosi ),
        .rxdat       ( rx_fifo_o ),
        .rxdatwr     ( rxdatwr )
    );

    logic tx_fifo_rd_en, rx_fifo_wr_en;
    logic tx_fifo_rd_en0, rx_fifo_wr_en0;

    `theregrn( scsnreg0 ) <= scsn;
    `theregrn( scsnreg  ) <= scsnreg0;
    `theregrn( seot ) <= scsnreg0 & ~scsnreg;
    `theregrn( ssot ) <= ~scsnreg0 & scsnreg;

    logic [16:0] sbytecnt;
    assign sbytecnt = sbitcnt[19:3];
    `theregfull( clktx, resetn, txdatrdtog, '0) <= txdatrdtog ^ txdatrd3;
    `theregfull( clkrx, resetn, rxdatwrtog, '0) <= rxdatwrtog ^ rxdatwr;
    `theregfull( clktx, spiresetn, txdaten, '0) <= txdatrd ? (
                                                            ( sbytecnt == ( cfgrxcnt + cfgdmcnt - 2 ))&(cfgtxcnt>0) ? 1'b1 :
                                                            ( ( cfgrxcnt + cfgdmcnt ) == 1 )&(cfgtxcnt>0) ? 1'b1 :
                                                            ( sbytecnt == ( cfgrxcnt + cfgdmcnt + cfgtxcnt- 2 )) ? 1'b0 : txdaten
                                                          ): txdaten;
    assign txdat = txdaten ? tx_fifo_i : '1;

    `theregrn( txdatrdtogregs ) <= {txdatrdtogregs, txdatrdtog};
    `theregrn( rxdatwrtogregs ) <= {rxdatwrtogregs, rxdatwrtog};
    `theregrn( rxdatwrregs ) <= {rxdatwrregs, rxdatwr};

    `theregrn( tx_fifo_rd0 ) <= ^txdatrdtogregs;
    `theregrn( rx_fifo_wr0 ) <= ( rxdatwrregs == 'b01 );

    `theregrn( txcnt ) <= seot ? '0 : txcnt + tx_fifo_rd0;
    `theregrn( rxcnt ) <= seot ? '0 : rxcnt + rx_fifo_wr0;
/*
    `theregsn( fsmrx ) <= seot ? '1 :
                            (( rxcnt == cfgrxcnt-1 )|(cfgrxcnt==1)) & tx_fifo_rd0 ? '0 : fsmrx;
    `theregrn( fsmdm ) <= seot ? '0 :
                            (( rxcnt == cfgrxcnt-1 )|(cfgrxcnt==1)) & tx_fifo_rd0 & ~( cfgdmcnt == '0 ) ? '1 :
                            ( rxcnt >= ( cfgrxcnt+cfgdmcnt )-1 ) & tx_fifo_rd0 ? '0 : fsmdm;

    `theregrn( fsmtx ) <= seot ? '0 :
                            ((( cfgrxcnt+cfgdmcnt )>'h2 ) & txcnt == ( cfgrxcnt+cfgdmcnt )-2 ) & tx_fifo_rd0 ? |cfgtxcnt :
                            (( cfgrxcnt+cfgdmcnt )=='h1 ) & tx_fifo_rd0 ? |cfgtxcnt :
                            ((( cfgrxcnt+cfgdmcnt )=='h2 ) & txcnt == 'h1 ) & tx_fifo_rd0 ? |cfgtxcnt :
//                            (( rxcnt == ( cfgrxcnt+cfgdmcnt )-1 ) | (( cfgrxcnt+cfgdmcnt )=='h1) ) & tx_fifo_rd0 ? '1 :
                            fsmtx;
*/
/*
    `theregrn( tx_fifo_rd_en0 ) <= seot ? '0 :
                            ( rxcnt == ( cfgrxcnt+cfgdmcnt )-2 ) & tx_fifo_rd0 &(cfgtxcnt>0) ? '1 :
                            (( cfgrxcnt+cfgdmcnt ) == 1 ) & tx_fifo_rd0&(cfgtxcnt>0) ? '1 :
                            (( cfgrxcnt+cfgdmcnt ) == 2 ) & tx_fifo_rd0 & ( rxcnt == 2 ) &(cfgtxcnt>0) ? '1 :
                            ( rxcnt == ( cfgrxcnt+cfgdmcnt+cfgtxcnt )-2 ) & tx_fifo_rd0 ? '0 :
                                                    tx_fifo_rd_en0;
*/
    `theregsn( rx_fifo_wr_en0 ) <= seot ? '1: ( rxcnt == cfgrxcnt - 1 ) & rx_fifo_wr0 ? '0:  rx_fifo_wr_en0;

//    `theregrn( tx_fifo_rd_en ) <= ssot ? '0 :
//    assign rx_fifo_wr_en = rx_fifo_wr_en0;
    `theregrn( tx_fifo_rd_en ) <= seot ? '0 :
                            ( txcnt == ( cfgrxcnt+cfgdmcnt )-1 ) & tx_fifo_rd0 &(cfgtxcnt>0) ? '1 :
                            ( txcnt == ( cfgrxcnt+cfgdmcnt+cfgtxcnt )-1 ) & tx_fifo_rd0 ? '0 :
                                                    tx_fifo_rd_en;

    assign rx_fifo_wr_en = rx_fifo_wr_en0;



    assign tx_fifo_rd = tx_fifo_rd_en & tx_fifo_rd0;
    assign rx_fifo_wr = rx_fifo_wr_en & rx_fifo_wr0;

endmodule

module udma_spis_tx (
    input  logic        clk,
    input  logic        resetn,
    input  logic        cpha,
    output logic        txbit,
    input  logic [7:0]  txdat,
    output logic        txdatrd,
    output logic        txdatrd3,
    output logic [19:0] sbitcnt
);

    logic txbytedone, txbytemid;
    logic [7:0] txbuf;
    logic txbit_cpha0, txbit_cpha1;

    `theregrn( sbitcnt ) <= sbitcnt + 1;

    assign txbytedone = ( sbitcnt[2:0] == 7 );
    assign txbytemid = ( sbitcnt[2:0] == 3 );

    assign txdatrd = txbytedone;
    assign txdatrd3 = txbytemid;
    `theregsn( txbuf ) <= txdatrd ? txdat : {txbuf,1'b1};

    assign txbit_cpha0 = txbuf[7];
    `theregsn( txbit_cpha1 ) <= txbit_cpha0;
    assign txbit = cpha ? txbit_cpha1 : txbit_cpha0;

endmodule

module udma_spis_rx (
    input  logic        clk,
    input  logic        resetn,
    input  logic        rxbit,

    output logic [7:0]  rxdat,
    output logic        rxdatwr
);

    logic       rxbytedone;
    logic [2:0] rxbitcnt;
    logic [7:0] rxbuf;

    assign rxbytedone = ( rxbitcnt == 7 );
    `theregrn( rxbitcnt ) <= rxbitcnt + 1;
    `theregrn( rxbuf    ) <= { rxbuf , rxbit };

    `theregrn( rxdat ) <= rxbytedone ? { rxbuf , rxbit } : rxdat;
    `theregrn( rxdatwr ) <=  rxbytedone;

endmodule


`ifdef SPISSIM

module spisrxtx_tb();

    bit clk,resetn;
    integer j, k, errcnt=0, warncnt=0;

  //
  //  dut
  //  ==

bit              sclk0, sclkp;
logic[4:0]  midx;
bit [31:0][7:0] mdat;

logic            cmsatpg = '0;
logic [15:0]     cfgrxcnt;
logic [15:0]     cfgtxcnt;
logic [15:0]     cfgdmcnt;
logic            sclk, sclken=0;
logic            scsn=0, scsnp;
logic [0:3]           smosi, cpol, cpha;
logic [0:3]           smiso;
logic  [0:3][7:0]     tx_fifo_i = '0;
logic  [0:3]          tx_fifo_rd;
logic  [0:3][7:0]     rx_fifo_o;
logic  [0:3]          rx_fifo_wr;
logic [0:3][7:0] spimdatbuf, spimdatbuf0;
logic [0:3] smosi_cpha1, smosi_cpha0;
logic [19:0] sbitcnt;

assign sclkp = ~sclk;
assign scsnp = ~scsn;

generate

for (genvar i = 0; i < 4; i++) begin:d
    assign cpol[i] = i[0];
    assign cpha[i] = i[1];
    udma_spis_txrx dut
    (
    .clk           (clk),
    .resetn        (resetn),
    .cmsatpg       (cmsatpg),
    .cfgrxcnt      (cfgrxcnt),
    .cfgtxcnt      (cfgtxcnt),
    .cfgdmcnt      (cfgdmcnt),
    .cpol(cpol[i]),
    .cpha(cpha[i]),
    .sclk(cpol[i]^sclk),
    .scsn(scsn),
    .smosi(smosi[i]),
    .smiso(smiso[i]),
    .tx_fifo_i(tx_fifo_i[i]+8'h5a),
    .tx_fifo_rd(tx_fifo_rd[i]),
    .rx_fifo_o(rx_fifo_o[i]),
    .rx_fifo_wr(rx_fifo_wr[i]),
    .seot      (),
    .smisooe   ()
    );

    `thereg( tx_fifo_i[i] ) <= tx_fifo_rd[i] ? tx_fifo_i[i] + 1 : tx_fifo_i[i];

    `theregfull( sclkp, ~scsn, spimdatbuf[i],  mdat[midx] ) <= ( sbitcnt[2:0]==7 ) ? (( sbitcnt[19:3]<cfgrxcnt-1 ) ? mdat[midx] : '1 )  : spimdatbuf[i]*2;
    `theregfull( sclkp, ~scsn, spimdatbuf0[i], mdat[midx] ) <= ( sbitcnt[2:0]==7 ) ? (( sbitcnt[19:3]<cfgrxcnt-1 ) ? mdat[midx] : '1 )  : spimdatbuf0[i];
    `theregfull( sclk , ~scsn, smosi_cpha1[i], '1  ) <= spimdatbuf[i][7];
    assign smosi_cpha0[i] = spimdatbuf[i][7];
    assign smosi[i] = cpha[i] ? smosi_cpha1[i] : smosi_cpha0[i];
end
endgenerate

    `theregfull( sclk, resetn, midx, '0 ) <= midx + ( sbitcnt[2:0]==7 );
    `theregfull( sclkp, scsnp, sbitcnt, '0 ) <= sbitcnt + 1;
ICG gsclk(.CK (sclk0),.EN (sclken),.SE('0),.CKG(sclk));

  //
  //  monitor and clk
  //  ==

    `genclk( clk, 10 )
    `genclk( sclk0, 101 )
    `timemarker2

  //
  //  subtitle
  //  ==

  logic [19:0] allcnt;
  assign allcnt = cfgrxcnt + cfgdmcnt + cfgtxcnt ;

    `maintest(spisrxtx_tb,spisrxtx_tb)
        for (int i = 0; i < 32; i++) begin
            mdat[i] =$random();
        end
        scsn = '1;
        #105 resetn = 1;
        scsn = '1;
        cfgrxcnt = 4; cfgdmcnt = 2; cfgtxcnt = 4;
        #(10 `US); spim(); midx = '0;
        cfgrxcnt = 4; cfgdmcnt = 0; cfgtxcnt = 4;
        #(10 `US); spim(); midx = '0;
        cfgrxcnt = 1; cfgdmcnt = 0; cfgtxcnt = 8;
        #(10 `US); spim(); midx = '0;
        cfgrxcnt = 8; cfgdmcnt = 0; cfgtxcnt = 0;
        #(10 `US); spim(); midx = '0;
        cfgrxcnt = 1; cfgdmcnt = 0; cfgtxcnt = 1;
        #(10 `US); spim(); midx = '0;
        cfgrxcnt = 1; cfgdmcnt = 0; cfgtxcnt = 0;
        #(10 `US); spim(); midx = '0;
        cfgrxcnt = 1; cfgdmcnt = 1; cfgtxcnt = 0;
        #(10 `US); spim(); midx = '0;
        cfgrxcnt = 1; cfgdmcnt = 1; cfgtxcnt = 1;
        #(10 `US); spim(); midx = '0;

        #(100 `US);
    `maintestend

    task spim();
        midx = 0;
        scsn = '0;
        #(300);
        for (int i = 0; i < allcnt*8; i++) begin
            @(negedge sclk0) sclken = 1;
        end
        @(negedge sclk0) sclken = 0;
        #(300);
        scsn = '1;
        #(1000);
    endtask : spim

endmodule
`endif