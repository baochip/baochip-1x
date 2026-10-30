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

// Open-source replacement for the Arm CMSDK `cmsdk_ahb_to_apb` bridge
// (cmsdk_ahb_to_apb.v, Cortex-M System Design Kit r1p0-00rel0).
//
// Why this file exists: the sce bus-bridge path used to pull the closed Arm
// model out of cram-nto; this module replaces it in sim builds (see
// deps/soc_oss/sce_adapter.py). It is functionally equivalent to the
// original for every reachable state, cycle-for-cycle, with matching
// reset values, so it drops into `apb_bdg` in amba_components.sv unchanged.
// Behavioral equivalence is verified against the original RTL in
// tb/oss_equiv/tb_ahb_to_apb_equiv.sv (randomized AHB master + APB slave,
// both bridges wired in parallel, every bridge output compared every cycle).
//
// ---------------------------------------------------------------------------
// Bridge behavior
// ---------------------------------------------------------------------------
// The AHB address phase of a selected transfer (HSEL & HTRANS[1] & HREADY) is
// sampled into registers; from then on the transfer is played out on APB:
//   - one APB setup cycle (PSEL=1, PENABLE=0)
//   - then access cycles (PSEL=1, PENABLE=1) until the slave returns PREADY
//     while PCLKEN is high (PCLKEN qualifies the APB clock domain: PCLK may be
//     a HCLK/2 derivation, in which case PCLKEN is a one-cycle pulse).
// A clean completion returns OKAY on the final cycle; PSLVERR produces the
// two-cycle ERROR response (HREADY=0 then HREADY=1, HRESP=1 both cycles).
//
// REGISTER_RDATA (default 1): HRDATA comes from a copy of PRDATA captured at
// the end of the APB access phase, one HCLK before HREADYOUT asserts.
// REGISTER_WDATA (default 0): HWDATA is captured into a register when the
// address phase is sampled (and PCLKEN is high before the APB access phase),
// instead of being passed through combinationally.
//
// Worst-case single-transfer latency (PCLKEN high, slave ready at first
// access cycle): address phase → SETUP → ACCESS → OKAY = 3 HCLK of stall,
// matching the closed bridge.
//
// Port list, parameter names, and reset values intentionally keep the Arm
// naming so `apb_bdg` needs no edits beyond the module name.

module oss_ahb_to_apb #(
    parameter ADDRWIDTH = 16,       // 2^ADDRWIDTH-byte APB address space
    parameter REGISTER_RDATA = 1,   // register PRDATA into HRDATA
    parameter REGISTER_WDATA = 0    // register HWDATA into PWDATA
) (
    // Clk / Rst.
    input  logic                  HCLK,      // Clock
    input  logic                  HRESETn,   // Reset
    input  logic                  PCLKEN,    // APB clock enable

    // AHB slave interface
    input  logic                  HSEL,      // Device select
    input  logic [ADDRWIDTH-1:0]  HADDR,     // Address
    input  logic [1:0]            HTRANS,    // Transfer control
    input  logic [2:0]            HSIZE,     // Transfer size
    input  logic [3:0]            HPROT,     // Protection control
    input  logic                  HWRITE,    // Write control
    input  logic                  HREADY,    // Transfer phase done
    input  logic [31:0]           HWDATA,    // Write data

    output logic                  HREADYOUT, // Device ready
    output logic [31:0]           HRDATA,    // Read data output
    output logic                  HRESP,     // Transfer response

    // APB master interface
    output logic [ADDRWIDTH-1:0]  PADDR,     // APB Address
    output logic                  PENABLE,   // APB Enable
    output logic                  PWRITE,    // APB Write
    output logic [3:0]            PSTRB,     // APB Byte Strobe
    output logic [2:0]            PPROT,     // APB Prot
    output logic [31:0]           PWDATA,    // APB write data
    output logic                  PSEL,      // APB Select
    output logic                  APBACTIVE, // APB bus active (clock gating)

    input  logic [31:0]           PRDATA,    // APB read data
    input  logic                  PREADY,    // APB slave ready
    input  logic                  PSLVERR    // APB slave error
);
    // Bridge FSM.
    localparam logic [2:0] IDLE = 3'b000;    // Idle, waiting for a transfer
    localparam logic [2:0] WAIT = 3'b001;    // Transfer announced, PCLKEN was low
    localparam logic [2:0] SETUP = 3'b010;   // First APB cycle (setup)
    localparam logic [2:0] ACCESS = 3'b011;  // Second+ APB cycle (access)
    localparam logic [2:0] OKAY = 3'b100;    // OKAY response cycle (registered rdata)
    localparam logic [2:0] ERR1 = 3'b101;    // ERROR response cycle 1 (HREADY=0)
    localparam logic [2:0] ERR2 = 3'b110;    // ERROR response cycle 2 (HREADY=1)

    logic                    rdata_cfg; // REGISTER_RDATA parameter, boolean
    logic                    wdata_cfg; // REGISTER_WDATA parameter, boolean
    assign rdata_cfg = (REGISTER_RDATA != 0);
    assign wdata_cfg = (REGISTER_WDATA != 0);
    // FSM state register.
    logic [2:0]              state_q;

    // Address phase is complete (and its payload is sampled) when the bridge
    // is selected for a NSEQ/SEQ transfer and the bus is ready.
    logic                    slave_sel;
    logic                    apb_end;
    assign slave_sel   = HSEL & HTRANS[1] & HREADY;
    assign apb_end = (state_q == ACCESS) & PREADY;

    ///////////////////////////////////////////////////////////////////////
    // address-phase sampling registers
    ///////////////////////////////////////////////////////////////////////
    logic [ADDRWIDTH-3:0]    addr_q;      // HADDR[ADDRWIDTH-1:2]
    logic                    wr_q;        // HWRITE
    logic [1:0]              pprot_q;     // {instruction, privileged}
    logic [3:0]              pstrb_q;     // byte strobes

    // PPROT maps from HPROT: [0] data/instruction, [1] privileged.
    logic [1:0]              pprot_d;
    assign pprot_d[0] =  HPROT[1];
    assign pprot_d[1] = ~HPROT[0];

    // Byte strobes from HSIZE + HADDR, generated for writes only:
    // - word (HSIZE=2): all lanes
    // - hword (HSIZE=1): pair selected by HADDR[1]
    // - byte (HSIZE=0): lane selected by HADDR[1:0]
    // HSIZE > 2 (up to 128-bit beats on a 32-bit APB) degenerates to "all
    // lanes", exactly as in the original.
    logic [3:0]              pstrb_d;
    assign pstrb_d[0] = HWRITE & ( HSIZE[1] | ( HSIZE[0] & ~HADDR[1]) | (HADDR[1:0] == 2'b00));
    assign pstrb_d[1] = HWRITE & ( HSIZE[1] | ( HSIZE[0] & ~HADDR[1]) | (HADDR[1:0] == 2'b01));
    assign pstrb_d[2] = HWRITE & ( HSIZE[1] | ( HSIZE[0] &  HADDR[1]) | (HADDR[1:0] == 2'b10));
    assign pstrb_d[3] = HWRITE & ( HSIZE[1] | ( HSIZE[0] &  HADDR[1]) | (HADDR[1:0] == 2'b11));

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_q   <= '0;
            wr_q     <= '0;
            pprot_q  <= '0;
            pstrb_q  <= '0;
        end else if (slave_sel) begin
            addr_q   <= HADDR[ADDRWIDTH-1:2];
            wr_q     <= HWRITE;
            pprot_q  <= pprot_d;
            pstrb_q  <= pstrb_d;
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // write-data sampling control
    // set when a write is announced (with REGISTER_WDATA), cleared once the
    // sample happens on a PCLKEN-high cycle
    ///////////////////////////////////////////////////////////////////////
    logic                    sample_wdata_q;
    logic                    sample_wdata_set;
    logic                    sample_wdata_clr;
    assign sample_wdata_set = slave_sel & HWRITE & wdata_cfg;
    assign sample_wdata_clr = sample_wdata_q & PCLKEN;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)              sample_wdata_q <= 1'b0;
        else if (sample_wdata_set | sample_wdata_clr) sample_wdata_q <= sample_wdata_set;
    end

    ///////////////////////////////////////////////////////////////////////
    // main FSM
    // IDLE -> SETUP starts the APB transfer as soon as PCLKEN allows;
    // WAIT parks an announced transfer until PCLKEN goes high;
    // ACCESS waits on PREADY; clean end -> OKAY (registered rdata) or
    // straight back out (unregistered); PSLVERR -> ERR1/ERR2 two-cycle ERROR.
    ///////////////////////////////////////////////////////////////////////
    logic [2:0]              state_d;

    // "a new transfer is being announced right now and may start on the next
    // PCLKEN tick" - the common tail of the IDLE/OKAY/ERR2 decode
    logic                    start_or_wait;
    assign start_or_wait = PCLKEN & slave_sel & ~(wdata_cfg & HWRITE);

    always_comb begin
        case (state_q)
            IDLE: begin
                if (start_or_wait)                     state_d = SETUP;
                else if (slave_sel)                   state_d = WAIT;
                else                                   state_d = IDLE;
            end
            WAIT: begin
                if (PCLKEN)                            state_d = SETUP;
                else                                   state_d = WAIT;
            end
            SETUP: begin
                if (PCLKEN)                            state_d = ACCESS;
                else                                   state_d = SETUP;
            end
            ACCESS: begin
                if (PREADY & PSLVERR & PCLKEN)         state_d = ERR1;
                else if (PREADY & ~PSLVERR & PCLKEN)   state_d = rdata_cfg ? OKAY
                                                                                 : {2'b00, slave_sel};
                else                                   state_d = ACCESS;
            end
            OKAY: begin
                if (start_or_wait)                     state_d = SETUP;
                else if (slave_sel)                   state_d = WAIT;
                else                                   state_d = IDLE;
            end
            ERR1:                               state_d = ERR2;
            ERR2: begin
                if (start_or_wait)                     state_d = SETUP;
                else if (slave_sel)                   state_d = WAIT;
                else                                   state_d = IDLE;
            end
            default:                                   state_d = 3'bxxx; // unreachable; X-propagate
        endcase
    end

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) state_q <= IDLE;
        else          state_q <= state_d;
    end

    ///////////////////////////////////////////////////////////////////////
    // read/write data holding register
    // Write path (REGISTER_WDATA): HWDATA is captured the first PCLKEN-high
    // cycle after the address phase; read path (REGISTER_RDATA): PRDATA is
    // captured when the APB access phase completes.
    ///////////////////////////////////////////////////////////////////////
    logic [31:0]             rwdata_q;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)                                     rwdata_q <= '0;
        else if (sample_wdata_q & wdata_cfg & PCLKEN) rwdata_q <= HWDATA;
        else if (apb_end & rdata_cfg & PCLKEN)   rwdata_q <= PRDATA;
    end

    ///////////////////////////////////////////////////////////////////////
    // outputs
    ///////////////////////////////////////////////////////////////////////
    assign PADDR   = {addr_q, 2'b00};
    assign PWRITE  = wr_q;
    assign PWDATA  = wdata_cfg ? rwdata_q : HWDATA;
    assign PSEL    = (state_q == SETUP) | (state_q == ACCESS);
    assign PENABLE = (state_q == ACCESS);
    assign PPROT   = {pprot_q[1], 1'b0, pprot_q[0]};
    assign PSTRB   = pstrb_q;

    // HREADYOUT: low while the bridge owns the AHB data phase; the OKAY
    // release happens in OKAY when read data is registered, or directly at
    // the end of ACCESS when not.
    always_comb begin
        case (state_q)
            IDLE:                      HREADYOUT = 1'b1;
            WAIT:                  HREADYOUT = 1'b0;
            SETUP:                  HREADYOUT = 1'b0;
            ACCESS:                 HREADYOUT = ~rdata_cfg & PREADY & ~PSLVERR & PCLKEN;
            OKAY:                 HREADYOUT = rdata_cfg;
            ERR1:                  HREADYOUT = 1'b0;
            ERR2:                  HREADYOUT = 1'b1;
            default:                      HREADYOUT = 1'bx;
        endcase
    end

    assign HRDATA   = rdata_cfg ? rwdata_q : PRDATA;
    assign HRESP    = (state_q == ERR1) | (state_q == ERR2);
    assign APBACTIVE = (HSEL & HTRANS[1]) | (|state_q);
endmodule
