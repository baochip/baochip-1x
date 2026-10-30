// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// Simulation stand-ins for the ASIC dual-port RAM glue used by the PKE
// MIMM (mimm_dpram.sv). The golden RTL instantiates a wrapped memory
// macro (`sce_mimmdpram), a read-back mux (rbdpmux) and the HD-cell
// port-list macro (`rf_2p_hdc_inst); none of these exist in the
// open sim tree, so mimm_dpram.sv fails to close. Added ahead of the
// RTL file list by deps/soc_oss/sce_adapter.py, alongside the
// behavioral single-port cells in verilate/sim_support/cryptorams.v.
// ASIC flows omit this file and keep the library cells.

// Port-list macro splicing the low-power sideband pins of the memory
// macro into the `sce_mimmdpram instance in mimm_dpram.sv (mirrors
// `sram_sp_hde_inst in cryptoram_verilate.sv: tied inactive).
`define rf_2p_hdc_inst              \
         .STOV   ( 1'b0    ),       \
         .EMAA   ( 3'b000  ),       \
         .EMASA  ( 1'b0    ),       \
         .EMAB   ( 3'b000  ),       \
         .RET1N  ( 1'b1    )

// Behavioral 72-bit-wide true dual-port RAM (synchronous read port A,
// synchronous read/write port B, per-bit active-low write and read
// strobes). Parity bits are stored/returned verbatim like the macro.
module sce_mimmdpram #(parameter AW = 8, parameter DW = 64)(
    input  wire              clka,
    input  wire              cena,
    input  wire [AW-1:0]     aa,
    output reg  [DW-1:0]     qa,
    input  wire              clkb,
    input  wire              cenb,
    input  wire [DW-1:0]     wenb,
    input  wire [AW-1:0]     ab,
    input  wire [DW-1:0]     db,
    input  wire              STOV,
    input  wire [2:0]        EMAA,
    input  wire              EMASA,
    input  wire [2:0]        EMAB,
    input  wire              RET1N
);
  reg [DW-1:0] mem [(2**AW)-1:0];

  always @(posedge clkb) begin
      if (!cenb) begin
          for (int j = 0; j < DW; j = j + 1)
              if (!wenb[j]) mem[ab][j] <= db[j];
      end
  end
  always @(posedge clka) begin
      if (!cena) qa <= mem[aa];
  end
endmodule

// Read-back mux: in sim the rb_* debug ports pass straight through to the
// memory ports (mirrors rbspmux for the single-port RAMs, which elaborates
// to a passthrough when cmsatpg/cmsbist are tied 0).
module rbdpmux #(parameter AW = 8, parameter DW = 64)(
    input  wire              cmsatpg,
    input  wire              cmsbist,
    input  wire              clka,
    input  wire              clkb,
    output wire [DW-1:0]     qa,
    output wire [DW-1:0]     qb,
    input  wire              cena,
    input  wire              cenb,
    input  wire [DW-1:0]     gwena,
    input  wire [DW-1:0]     gwenb,
    input  wire [DW-1:0]     wena,
    input  wire [DW-1:0]     wenb,
    input  wire [AW-1:0]     aa,
    input  wire [AW-1:0]     ab,
    input  wire [DW-1:0]     da,
    input  wire [DW-1:0]     db,
    output wire              rb_clka,
    output wire              rb_clkb,
    input  wire [DW-1:0]     rb_qa,
    input  wire [DW-1:0]     rb_qb,
    output wire              rb_cena,
    output wire              rb_cenb,
    output wire [DW-1:0]     rb_gwena,
    output wire [DW-1:0]     rb_gwenb,
    output wire [DW-1:0]     rb_wena,
    output wire [DW-1:0]     rb_wenb,
    output wire [AW-1:0]     rb_aa,
    output wire [AW-1:0]     rb_ab,
    output wire [DW-1:0]     rb_da,
    output wire [DW-1:0]     rb_db,
    rbif.slavedp             rbs
);
  assign rb_clka  = clka;
  assign rb_clkb  = clkb;
  assign rb_cena  = cena;
  assign rb_cenb  = cenb;
  assign rb_gwena = gwena;
  assign rb_gwenb = gwenb;
  assign rb_wena  = wena;
  assign rb_wenb  = wenb;
  assign rb_aa    = aa;
  assign rb_ab    = ab;
  assign rb_da    = da;
  assign rb_db    = db;
  assign qa       = rb_qa;
  assign qb       = rb_qb;
endmodule
