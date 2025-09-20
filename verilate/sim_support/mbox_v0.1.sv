
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: BSD-2-Clause

// Integration wrapper for mbox_client

`ifdef XVLOG // required for compatibility with xsim
`include "template.sv"
`include "apb_sfr_v0.1.sv"
`endif

module mbox_apb #(
)(
    input logic         aclk,
    input logic         pclk,
    input logic         resetn,
    input logic cmatpg, cmbist,
    input logic [2:0]   sramtrm,

    output logic [31:0] mbox_w_dat,
    output logic        mbox_w_valid,
    input  logic        mbox_w_ready,
    output logic        mbox_w_done,
    input  logic [31:0] mbox_r_dat,
    input  logic        mbox_r_valid,
    output logic        mbox_r_ready,
    input  logic        mbox_r_done,
    output logic        mbox_w_abort,
    input  logic        mbox_r_abort,

    output logic        irq_available,
    output logic        irq_abort_init,
    output logic        irq_abort_done,
    output logic        irq_error,

    apbif.slavein       apbs,
    apbif.slave         apbx
);

    logic [31:0] wdata;
    logic        wdata_written;
    logic [31:0] rdata;
    logic        rdata_read;
    logic        status_read;
    logic        rx_avail;
    logic        tx_free;
    logic        abort_in_progress;
    logic        abort_ack;
    logic        rx_err;
    logic        tx_err;
    logic        abort;
    logic        done;

    mbox_client mbox_client(
        .aclk_reset_n(resetn),
        .pclk_reset_n(resetn),
        .aclk(aclk),
        .pclk(pclk),

        .mbox_w_dat,
        .mbox_w_valid,
        .mbox_w_ready,
        .mbox_w_done,
        .mbox_r_dat,
        .mbox_r_valid,
        .mbox_r_ready,
        .mbox_r_done,
        .mbox_w_abort,
        .mbox_r_abort,

        .sfr_cr_wdata(wdata),
        .sfr_cr_wdata_written(wdata_written),
        .sfr_sr_rdata(rdata),
        .sfr_sr_rdata_read(rdata_read),
        .sfr_int_available(irq_available),
        .sfr_int_abort_init(irq_abort_init),
        .sfr_int_abort_done(irq_abort_done),
        .sfr_int_error(irq_error),
        .sfr_sr_read(status_read),
        .sfr_sr_rx_avail(rx_avail),
        .sfr_sr_tx_free(tx_free),
        .sfr_sr_abort_in_progress(abort_in_progress),
        .sfr_sr_abort_ack(abort_ack),
        .sfr_sr_rx_err(tx_err),
        .sfr_sr_tx_err(rx_err),
        .sfr_ar_abort(abort),
        .sfr_ar_done(done)
    );

    // ---- SFR bank ----
    logic apbrd, apbwr, sfrlock;
    assign sfrlock = '0;
    `apbs_common;
    assign  apbx.prdata = '0 |
            sfr_wdata         .prdata32 |
            sfr_rdata         .prdata32 |
            sfr_status        .prdata32;

    apb_acr #(.A('h0), .DW(32))      sfr_wdata             (.cr(wdata), .ar(wdata_written), .prdata32(),.*);
    apb_asr #(.A('h4), .DW(32))      sfr_rdata             (.sr(rdata), .ar(rdata_read), .prdata32(),.*);
    apb_asr #(.A('h8), .DW(6) )      sfr_status            (.sr({rx_err, tx_err, abort_ack, abort_in_progress, tx_free, rx_avail}), .ar(status_read), .prdata32(),.*);
    apb_ar  #(.A('h18), .AR(32'h1))  sfr_abort             (.ar(abort),.*);
    apb_ar  #(.A('h1C), .AR(32'h1))  sfr_done              (.ar(done),.*);
endmodule

`ifdef NO_GLOBAL
// action + control register. Any write to this register will cause a pulse that
// can trigger an action, while also updating the value of the register
module apb_acr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16,
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
        output logic [0:SFRCNT-1][DW-1:0]   cr          ,
        output bit                          ar
);


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
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .sfrsr       ('0             ),
            .sfrfr       ('0             ),
            .sfrprdata   (prdata         ),
            .sfrdata     (cr             )
         );

    logic sfrapbwr;
    apb_sfrop2 #(
            .AW          ( AW            )
         )apb_sfrop(
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .apbrd       (               ),
            .apbwr       (sfrapbwr       )
         );
    `theregfull(pclk, resetn, ar, '0) <= sfrapbwr;
endmodule

// action + status register. Any read to this register will cause a pulse that
// can trigger an action.
module apb_asr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16,
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
        input  logic [0:SFRCNT-1][DW-1:0]   sr          ,
        output bit                          ar
);


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
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .sfrsr       (sr             ),
            .sfrfr       ('0             ),
            .sfrprdata   (prdata         ),
            .sfrdata     (               )
         );

    logic sfrapbrd;
    apb_sfrop2 #(
            .AW          ( AW            )
         )apb_sfrop(
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .apbrd       (sfrapbrd       ),
            .apbwr       (               )
         );
    `theregfull(pclk, resetn, ar, '0) <= sfrapbrd;
endmodule
`endif