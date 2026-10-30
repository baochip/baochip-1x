// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// This documentation and source code is licensed under the CERN Open Hardware
// License Version 2 - Weakly Reciprocal (http://ohwr.org/cernohl; the
// "License"). Your use of any source code herein is governed by the License.
//
// You may redistribute and modify this documentation under the terms of the
// License. This documentation and source code is distributed WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
// PARTICULAR PURPOSE. Please see the License for the specific language governing
// permissions and limitations under the License.

// Open-source replacement for the Arm CMSDK `cmsdk_ahb_to_sram` on-chip RAM
// bridge (cmsdk_ahb_to_sram.v, Cortex-M System Design Kit r1p0-00rel0,
// svn 223062).
//
// Why this file exists: the AHB-to-SRAM path used to pull the closed Arm
// model out of cram-nto / soc_mpw; this module replaces it in sim builds
// (see deps/soc_oss/sce_adapter.py). It is functionally equivalent to the
// original for every reachable state, cycle-for-cycle, with matching reset
// values, so it drops into `ahb_mux3`/`ahbsramc32`/`pke` unchanged.
// Behavioral equivalence is verified against the original RTL in
// tb/oss_equiv/tb_ahb_to_sram_equiv.sv (randomized AHB master + behavioral
// SRAM, both bridges wired in parallel, every bridge output compared every
// cycle).
//
// ---------------------------------------------------------------------------
// Bridge behavior
// ---------------------------------------------------------------------------
// The bridge never inserts wait states: HREADYOUT is tied 1, HRESP tied 0.
// The AHB address phase of a selected transfer (HSEL & HTRANS[1] & HREADY)
// is sampled into a write buffer, and the SRAM sees the transfer on the
// following (data phase) cycle:
//   - write address phase: addr/byte-lane strobes are buffered; the SRAM
//     write happens in the data phase. If another write address phase
//     follows, its data is still held on HWDATA, so it writes through; if
//     a read address phase follows instead, the buffered write is still
//     pending (wr_pend_q) and its data is served from wr_data_q while the
//     SRAM read of the new address proceeds.
//   - read address phase: SRAMCS/SRAMADDR/SRAMRDATA are presented
//     combinationally in the same cycle (async-read SRAM), so read data
//     lands on HRDATA during the data phase.
// read-after-write to the same word merges the still-buffered write bytes
// over the SRAM read (wr_hit & wr_stb_q per byte lane), covering the
// one-cycle window before the buffered write reaches the SRAM.
//
// Port list, parameter names, and reset values intentionally keep the Arm
// naming so the instantiating modules need no edits beyond the module name.

module oss_ahb_to_sram #(
    parameter integer AW = 16            // AHB address width (>= 4)
) (
    input  logic          HCLK,          // system bus clock
    input  logic          HRESETn,       // system bus reset (low active)
    input  logic          HSEL,          // AHB peripheral select
    input  logic          HREADY,        // AHB ready input
    input  logic    [1:0] HTRANS,        // AHB transfer type
    input  logic    [2:0] HSIZE,         // AHB transfer size
    input  logic          HWRITE,        // AHB write direction
    input  logic [AW-1:0] HADDR,         // AHB address bus
    input  logic   [31:0] HWDATA,        // AHB write data bus

    output logic          HREADYOUT,     // AHB ready output to S->M mux
    output logic          HRESP,         // AHB response (never asserted)
    output logic   [31:0] HRDATA,        // AHB read data bus

    input  logic   [31:0] SRAMRDATA,     // SRAM read data (async)
    output logic [AW-3:0] SRAMADDR,      // SRAM word address
    output logic    [3:0] SRAMWEN,       // SRAM byte write enable (high)
    output logic   [31:0] SRAMWDATA,     // SRAM write data
    output logic          SRAMCS         // SRAM chip select (high)
);
    // -----------------------------------------------------------------------
    // Address-phase qualifiers
    // -----------------------------------------------------------------------
    logic ahb_access;                    // selected NSEQ/SEQ address phase
    logic ahb_write;
    logic ahb_read;
    assign ahb_access = HTRANS[1] & HSEL & HREADY;
    assign ahb_write  = ahb_access &  HWRITE;
    assign ahb_read   = ahb_access & ~HWRITE;

    // -----------------------------------------------------------------------
    // Write buffer state
    // -----------------------------------------------------------------------
    logic [AW-3:0] wr_addr_q;             // buffered write word address
    logic [3:0]    wr_stb_q;               // buffered byte strobes (data phase)
    logic [31:0]   wr_data_q;             // buffered write data
    logic          wr_data_vld;          // data phase of a new AHB write
    logic          wr_pend_q;             // buffered write awaiting SRAM
    logic          wr_hit;              // read targets the buffered word

    // -----------------------------------------------------------------------
    // Read/write control
    // -----------------------------------------------------------------------
    // A buffered write stays pending across a string of reads: it is set by
    // the write's data phase and cleared only when the SRAM can take it
    // (i.e. when the address phase is not a read).
    logic wr_pend_d;
    logic sram_wr;
    assign wr_pend_d = (wr_pend_q | wr_data_vld) & ahb_read;
    assign sram_wr    = (wr_pend_q | wr_data_vld) & ~ahb_read;

    // SRAM control: reads present HADDR in the address phase, writes use the
    // buffered address in the data phase.
    assign SRAMWEN   = {4{sram_wr}} & wr_stb_q;
    assign SRAMADDR = ahb_read ? HADDR[AW-1:2] : wr_addr_q;
    assign SRAMCS    = ahb_read | sram_wr;

    // -----------------------------------------------------------------------
    // Byte lane decoder (address phase)
    // -----------------------------------------------------------------------
    logic tx_byte, tx_half, tx_word;
    assign tx_byte = ~HSIZE[1] & ~HSIZE[0];
    assign tx_half = ~HSIZE[1] &  HSIZE[0];
    assign tx_word =  HSIZE[1];

    logic        half_at_00, half_at_10;
    logic        byte_at_00, byte_at_01, byte_at_10, byte_at_11;
    assign half_at_00 = tx_half & ~HADDR[1];
    assign half_at_10 = tx_half &  HADDR[1];
    assign byte_at_00 = tx_byte & ~HADDR[1] & ~HADDR[0];
    assign byte_at_01 = tx_byte & ~HADDR[1] &  HADDR[0];
    assign byte_at_10 = tx_byte &  HADDR[1] & ~HADDR[0];
    assign byte_at_11 = tx_byte &  HADDR[1] &  HADDR[0];

    logic [3:0] wr_stb_d;
    assign wr_stb_d = { tx_word | half_at_10 | byte_at_11,
                          tx_word | half_at_10 | byte_at_10,
                          tx_word | half_at_00 | byte_at_01,
                          tx_word | half_at_00 | byte_at_00
                        } & {4{ahb_write}};

    // -----------------------------------------------------------------------
    // Write buffer registers
    // -----------------------------------------------------------------------
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) wr_data_vld <= 1'b0;
        else          wr_data_vld <= ahb_write;
    end

    // Data capture is gated by the *previous* cycle's byte strobes: HWDATA
    // still carries the write data during the write's data phase.
    always_ff @(posedge HCLK) if (wr_stb_q[3] & wr_data_vld) wr_data_q[31:24] <= HWDATA[31:24];
    always_ff @(posedge HCLK) if (wr_stb_q[2] & wr_data_vld) wr_data_q[23:16] <= HWDATA[23:16];
    always_ff @(posedge HCLK) if (wr_stb_q[1] & wr_data_vld) wr_data_q[15: 8] <= HWDATA[15: 8];
    always_ff @(posedge HCLK) if (wr_stb_q[0] & wr_data_vld) wr_data_q[ 7: 0] <= HWDATA[ 7: 0];

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)       wr_stb_q   <= 4'b0000;
        else if (ahb_write) wr_stb_q   <= wr_stb_d;
    end

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)       wr_addr_q <= '0;
        else if (ahb_write) wr_addr_q <= HADDR[AW-1:2];
    end

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) wr_pend_q <= 1'b0;
        else          wr_pend_q <= wr_pend_d;
    end

    // -----------------------------------------------------------------------
    // Read merge: a read whose word matches the buffered write takes the
    // buffered bytes until the buffered write commits to the SRAM.
    // -----------------------------------------------------------------------
    logic wr_hit_d;
    assign wr_hit_d = (HADDR[AW-1:2] == wr_addr_q);

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)      wr_hit <= 1'b0;
        else if (ahb_read) wr_hit <= wr_hit_d;
    end

    logic [3:0] merge1;
    assign merge1 = {4{wr_hit}} & wr_stb_q;

    assign HRDATA = { merge1[3] ? wr_data_q[31:24] : SRAMRDATA[31:24],
                      merge1[2] ? wr_data_q[23:16] : SRAMRDATA[23:16],
                      merge1[1] ? wr_data_q[15: 8] : SRAMRDATA[15: 8],
                      merge1[0] ? wr_data_q[ 7: 0] : SRAMRDATA[ 7: 0] };

    // With a write pending the SRAM data comes from the buffer; otherwise
    // HWDATA passes through the data phase directly.
    assign SRAMWDATA = wr_pend_q ? wr_data_q : HWDATA;

    // -----------------------------------------------------------------------
    // Constant slave responses
    // -----------------------------------------------------------------------
    assign HREADYOUT = 1'b1;
    assign HRESP     = 1'b0;

endmodule : oss_ahb_to_sram
