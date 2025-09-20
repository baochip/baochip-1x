// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: BSD-2-Clause

// SystemVerilog -> Verilog wrapper

module mbox_wrapper #(
    parameter AW = 12
)(
    input logic aclk,
    input logic pclk,
    input logic resetn,
    input logic cmatpg, cmbist,
    input logic [2:0] sramtrm,

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

    input  wire        [AW-1:0] PADDR,     // APB Address
    input  wire                 PENABLE,   // APB Enable
    input  wire                 PWRITE,    // APB Write
    input  wire           [3:0] PSTRB,     // APB Byte Strobe
    input  wire           [2:0] PPROT,     // APB Prot
    input  wire          [31:0] PWDATA,    // APB write data
    input  wire                 PSEL,      // APB Select
    input  wire                 APBACTIVE, // APB bus is active, for clock gating
                                           // of APB bus
                                           // APB Input
    output wire          [31:0] PRDATA,    // Read data for each APB slave
    output wire                 PREADY,    // Ready for each APB slave
    output wire                 PSLVERR   // Error state for each APB slave
);

    apbif #(.PAW(AW)) theapb();

    apb_wire2ifm #(
      .AW(AW)
     )apbtrans(
        .apbmaster    (theapb),
        .psel         (PSEL),
        .paddr        (PADDR),
        .penable      (PENABLE),
        .pwrite       (PWRITE),
        .pstrb        (PSTRB),
        .pprot        (PPROT),
        .pwdata       (PWDATA),
        .apbactive    (APBACTIVE),
        .prdata       (PRDATA),
        .pready       (PREADY),
        .pslverr      (PSLVERR)
    );
    mbox_apb mbox_apb(
        .aclk     ,
        .pclk    ,
        .resetn  ,
        .cmatpg  ,
        .cmbist  ,
        .sramtrm ,

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
        .irq_available,
        .irq_abort_init,
        .irq_abort_done,
        .irq_error,

        .apbs    (theapb),
        .apbx    (theapb)
    );
endmodule
