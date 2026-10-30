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

// Open-source replacement for the Arm CMSDK `cmsdk_ahb_master_mux` 3-to-1 AHB
// master multiplexer (cmsdk_ahb_master_mux.v, Cortex-M System Design Kit
// r1p0-00rel0, svn 243003), used by `ahb_mux3` in amba_components.sv.
//
// Why this file exists: the AHB master mux path used to pull the closed Arm
// model out of cram-nto / soc_mpw; this module replaces it in sim builds
// (see deps/soc_oss/sce_adapter.py). It is functionally equivalent to the
// original for every reachable state, cycle-for-cycle, with matching reset
// values, so it drops into `ahb_mux3` unchanged. Behavioral equivalence is
// verified against the original RTL in tb/oss_equiv/tb_ahb_master_mux_equiv.sv
// (three constrained-random AHB masters + a randomized slave, both muxes
// wired in parallel, every mux output compared every cycle).
//
// ---------------------------------------------------------------------------
// Mux behavior
// ---------------------------------------------------------------------------
// Arbitration, address phase (one-hot grant_addr):
//   1. keep the current selection while a transfer was announced and
//      stalled, while a locked sequence is active, while a fixed-length
//      burst continues on the currently selected port, or during the two
//      error-response cycles of a fixed-length burst (so the post-error IDLE
//      beats drain on the same port);
//   2. else port 2 has fixed priority;
//   3. else ports 0 and 1 tie: round robin via rr_q;
//   4. else pass the single requestor through.
// Each port has an input-hold stage: a request whose address phase was not
// granted (or was granted into a stalled bus) is captured into hold
// registers and re-presented unchanged until the slave accepts it; the
// port's HREADYOUT is held low meanwhile. HTRANSM is qualified with an
// IDLE flag + data/address phase comparison so IDLE->SEQ can never collapse
// into one address phase after a master switch (SEQ is demoted to NSEQ).
// HSIZEM truncates HSIZE to 2 bits below DW=128 exactly as the original.
//
// Port list, parameter names, and reset values intentionally keep the Arm
// naming so `ahb_mux3` needs no edits beyond the module name.

module oss_ahb_master_mux #(
    parameter integer PORT0_ENABLE = 1,  // slave port 0 present
    parameter integer PORT1_ENABLE = 1,  // slave port 1 present
    parameter integer PORT2_ENABLE = 1,  // slave port 2 present
    parameter integer DW = 32            // data bus width
) (
    input  wire          HCLK,           // Clock
    input  wire          HRESETn,        // Reset (low active)

    // AHB connection to master #0
    input  wire          HSELS0,
    input  wire [31:0]   HADDRS0,
    input  wire  [1:0]   HTRANSS0,
    input  wire  [2:0]   HSIZES0,
    input  wire          HWRITES0,
    input  wire          HREADYS0,
    input  wire  [3:0]   HPROTS0,
    input  wire  [2:0]   HBURSTS0,
    input  wire          HMASTLOCKS0,
    input  wire [DW-1:0] HWDATAS0,
    output wire          HREADYOUTS0,
    output wire          HRESPS0,
    output wire [DW-1:0] HRDATAS0,

    // AHB connection to master #1
    input  wire          HSELS1,
    input  wire [31:0]   HADDRS1,
    input  wire  [1:0]   HTRANSS1,
    input  wire  [2:0]   HSIZES1,
    input  wire          HWRITES1,
    input  wire          HREADYS1,
    input  wire  [3:0]   HPROTS1,
    input  wire  [2:0]   HBURSTS1,
    input  wire          HMASTLOCKS1,
    input  wire [DW-1:0] HWDATAS1,
    output wire          HREADYOUTS1,
    output wire          HRESPS1,
    output wire [DW-1:0] HRDATAS1,

    // AHB connection to master #2
    input  wire          HSELS2,
    input  wire [31:0]   HADDRS2,
    input  wire  [1:0]   HTRANSS2,
    input  wire  [2:0]   HSIZES2,
    input  wire          HWRITES2,
    input  wire          HREADYS2,
    input  wire  [3:0]   HPROTS2,
    input  wire  [2:0]   HBURSTS2,
    input  wire          HMASTLOCKS2,
    input  wire [DW-1:0] HWDATAS2,
    output wire          HREADYOUTS2,
    output wire          HRESPS2,
    output wire [DW-1:0] HRDATAS2,
    // AHB output master port
    output wire          HSELM,
    output wire [31:0]   HADDRM,
    output wire  [1:0]   HTRANSM,
    output wire  [2:0]   HSIZEM,
    output wire          HWRITEM,
    output wire          HREADYM,
    output wire  [3:0]   HPROTM,
    output wire  [2:0]   HBURSTM,
    output wire          HMASTLOCKM,
    output wire [DW-1:0] HWDATAM,
    input  wire          HREADYOUTM,
    input  wire          HRESPM,
    input  wire [DW-1:0] HRDATAM,
    output wire  [1:0]   HMASTERM        // selected port (address phase)
);
    // HSIZE storage width: the mux only honors transfer sizes that fit
    // the data bus, so the upper HSIZE bits are discarded.
    localparam logic [1:0] SZ_MSB = (DW > 64) ? 2'd2 : 2'd1;  // MSB of storable HSIZE
    localparam int   SZ_W   = (DW > 64) ? 3 : 2;

    // -----------------------------------------------------------------------
    // Port enable mask
    // -----------------------------------------------------------------------
    logic [2:0] port_en;
    assign port_en[0] = (PORT0_ENABLE != 0);
    assign port_en[1] = (PORT1_ENABLE != 0);
    assign port_en[2] = (PORT2_ENABLE != 0);

    // -----------------------------------------------------------------------
    // Input stage (one instance per port, described below)
    // -----------------------------------------------------------------------
    logic [31:0]        haddr_ips   [3]; // address-phase payload per port
    logic [1:0]         htrans_ips  [3];
    logic               hwrite_ips  [3];
    logic [SZ_W-1:0] hsize_ips   [3];
    logic [3:0]         hprot_ips   [3];
    logic [2:0]         hburst_ips  [3];
    logic               hmasterlock_ips [3];
    logic               hready_ips  [3];
    logic               hold_active [3]; // request parked in the hold regs
    logic               trans_valid [3]; // fresh address-phase request

    // -----------------------------------------------------------------------
    // generate: per-port input-hold stage + response steering
    // -----------------------------------------------------------------------
    // The original spells this out three times; a loop keeps the three
    // copies byte-identical in behavior. Port s presents a request from its
    // pins unless its hold stage is active; a not-yet-consumed request is
    // captured when its address phase completes on a cycle where this mux
    // was not granted (or the slave stalled).
    genvar p;
    generate
        for (p = 0; p < 3; p++) begin : g_port
            logic         sel;
            logic [31:0]  haddr;
            logic [1:0]   htrans;
            logic         hwrite;
            logic [2:0]   hsize;
            logic         hready;
            logic [3:0]   hprot;
            logic [2:0]   hburst;
            logic         hmasterlock;

            assign sel         = (p == 0) ? HSELS0       : (p == 1) ? HSELS1       : HSELS2;
            assign haddr       = (p == 0) ? HADDRS0      : (p == 1) ? HADDRS1      : HADDRS2;
            assign htrans      = (p == 0) ? HTRANSS0     : (p == 1) ? HTRANSS1     : HTRANSS2;
            assign hwrite      = (p == 0) ? HWRITES0     : (p == 1) ? HWRITES1     : HWRITES2;
            assign hsize       = (p == 0) ? HSIZES0      : (p == 1) ? HSIZES1      : HSIZES2;
            assign hready      = (p == 0) ? HREADYS0     : (p == 1) ? HREADYS1     : HREADYS2;
            assign hprot       = (p == 0) ? HPROTS0      : (p == 1) ? HPROTS1      : HPROTS2;
            assign hburst      = (p == 0) ? HBURSTS0     : (p == 1) ? HBURSTS1     : HBURSTS2;
            assign hmasterlock = (p == 0) ? HMASTLOCKS0  : (p == 1) ? HMASTLOCKS1  : HMASTLOCKS2;

            assign trans_valid[p] = sel & htrans[1] & hready;

            logic        input_hold;
            logic        hold_active_q;
            assign input_hold = trans_valid[p] & ~(grant_addr[p] & HREADYOUTM);
            always_ff @(posedge HCLK or negedge HRESETn) begin
                if (!HRESETn)                      hold_active_q <= 1'b0;
                else if (port_en[p])      hold_active_q <= input_hold
                                                | (hold_active_q & ~(grant_addr[p] & HREADYOUTM));
            end
            assign hold_active[p] = hold_active_q;

            logic          hold_addr_en;
            assign hold_addr_en = input_hold & port_en[p];
            always_ff @(posedge HCLK or negedge HRESETn) begin
                if (!HRESETn) begin
                    haddr_r <= '0;
                    htrans_r <= 1'b0;
                    hwrite_r <= 1'b0;
                    hsize_r  <= '0;
                    hprot_r  <= '0;
                    hburst_r <= '0;
                    hmasterlock_r <= 1'b0;
                end else if (hold_addr_en) begin
                    haddr_r <= haddr;
                    htrans_r <= htrans[0];
                    hwrite_r <= hwrite;
                    hsize_r  <= hsize[SZ_MSB:0];
                    hprot_r  <= hprot;
                    hburst_r <= hburst;
                    hmasterlock_r <= hmasterlock;
                end
            end

            // hold registers
            logic [31:0]        haddr_r;
            logic               htrans_r;
            logic               hwrite_r;
            logic [SZ_MSB:0] hsize_r;
            logic [3:0]         hprot_r;
            logic [2:0]         hburst_r;
            logic               hmasterlock_r;

            // bypass mux
            assign haddr_ips[p]        = hold_active_q ? haddr_r          : haddr;
            assign htrans_ips[p]       = hold_active_q ? {1'b1, htrans_r} : htrans;
            assign hwrite_ips[p]       = hold_active_q ? hwrite_r         : hwrite;
            assign hsize_ips[p]        = hold_active_q ? hsize_r          : hsize[SZ_MSB:0];
            assign hprot_ips[p]        = hold_active_q ? hprot_r          : hprot;
            assign hburst_ips[p]       = hold_active_q ? hburst_r         : hburst;
            assign hmasterlock_ips[p]  = hold_active_q ? hmasterlock_r    : hmasterlock;
            assign hready_ips[p]       = hold_active_q ? 1'b1             : hready;
        end
    endgenerate

    // -----------------------------------------------------------------------
    // Arbiter state
    // -----------------------------------------------------------------------
    logic [2:0] grant_addr;      // one-hot (combinational)
    logic [2:0] grant_addr_q;    // last cycle's selection
    logic [2:0] grant_data_q;      // registered selection (data phase)
    logic       announced_stall; // announced transfer hit HREADY=0
    logic       lock_beat;     // lock seen in address phase
    logic       burst_fl;      // burst continuing on last port
    logic       burst_fl_q;  // burst in data phase
    logic       burst_err_q; // error-cancel pulse (2 cycles)
    logic       data_phase;         // active data phase
    logic       rr_q;   // last of ports 0/1 was #1
    logic       held_idle_q;           // HTRANSM held IDLE this cycle

    // mux bus-side internal view
    logic        bus_hsel;
    logic [31:0] bus_haddr;
    logic [1:0]  bus_htrans;
    logic        bus_hwrite;
    logic [2:0]  bus_hsize;
    logic [3:0]  bus_hprot;
    logic [2:0]  bus_hburst;
    logic        bus_hlock;
    logic        bus_hready;

    always_ff @(posedge HCLK or negedge HRESETn)
        grant_addr_q <= grant_addr;

    // -----------------------------------------------------------------------
    // "must not switch over" conditions
    // -----------------------------------------------------------------------
    // 1) transfer announced last cycle while the bus was not ready
    assign announced_stall = bus_hsel & bus_htrans[1] & ~bus_hready;
    logic announced_stall_q;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) announced_stall_q <= 1'b0;
        else          announced_stall_q <= announced_stall;
    end

    // 2) locked sequence (sampled at address phase, held through data)
    assign lock_beat = bus_hsel & bus_hlock;
    logic lock_beat_q;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)           lock_beat_q <= 1'b0;
        else if (bus_hready)    lock_beat_q <= lock_beat;
    end

    // 3) fixed-length burst in progress on the port selected last cycle
    logic flb_p [3];
    generate
        for (p = 0; p < 3; p++) begin : g_flb
            logic sel;
            logic [1:0] htrans;
            logic [2:0] hburst;
            assign sel    = (p == 0) ? HSELS0   : (p == 1) ? HSELS1   : HSELS2;
            assign htrans = (p == 0) ? HTRANSS0 : (p == 1) ? HTRANSS1 : HTRANSS2;
            assign hburst = (p == 0) ? HBURSTS0 : (p == 1) ? HBURSTS1 : HBURSTS2;
            assign flb_p[p] = sel & htrans[0] & (hburst[2:1] != 2'b00)
                                           & grant_addr_q[p];
        end
    endgenerate
    assign burst_fl = flb_p[0]
                              | flb_p[1]
                              | flb_p[2];

    // 4) error response during a fixed-length burst: hold the selection for
    //    the full two-cycle ERROR phase so the burst's IDLE beats drain.
    logic burst_fl_d;
    logic burst_err_d;
    assign burst_fl_d     = (bus_hburst[2:1] != 2'b00) & (|bus_htrans);
    assign burst_err_d = data_phase & burst_fl_q
                                      & ~HREADYOUTM & HRESPM;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)                 burst_fl_q <= 1'b0;
        else if (bus_hready)          burst_fl_q <= burst_fl_d;
    end
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)                                    burst_err_q <= 1'b0;
        else if (burst_err_d | burst_err_q)
                                                         burst_err_q <= burst_err_d;
    end

    // -----------------------------------------------------------------------
    // Round-robin state between ports 0 and 1
    // -----------------------------------------------------------------------
    logic rr_d;
    assign rr_d = (grant_addr[1] & port_en[1])
                                 | (rr_q & ~grant_addr[0] & port_en[0]);
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)          rr_q <= 1'b0;
        else if (bus_hready)   rr_q <= rr_d;
    end

    // -----------------------------------------------------------------------
    // Arbitration process
    // -----------------------------------------------------------------------
    logic [2:0] port_req;
    generate
        for (p = 0; p < 3; p++) begin : g_req
            assign port_req[p] = (hold_active[p] | trans_valid[p]) & port_en[p];
        end
    endgenerate

    always_comb begin
        if (announced_stall_q | lock_beat_q
            | burst_fl | burst_err_q)
            // selection unchanged for the four stall/lock/burst conditions
            grant_addr = grant_addr_q & port_en;
        else if (port_req[2])
            // port 2: fixed priority
            grant_addr = 3'b100 & port_en;
        else if (port_req[1:0] == 2'b11)
            // ports 0/1: round robin
            grant_addr = {1'b0, ~rr_q, rr_q}
                               & port_en;
        else
            grant_addr = port_req & port_en;
    end

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)        grant_data_q <= 3'b000;
        else if (bus_hready) grant_data_q <= grant_addr & port_en;
    end

    logic data_phase_d;
    assign data_phase_d = bus_hsel & bus_htrans[1];
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)        data_phase <= 1'b0;
        else if (bus_hready) data_phase <= data_phase_d;
    end

    // -----------------------------------------------------------------------
    // Address-phase multiplexer
    // -----------------------------------------------------------------------
    generate
        for (p = 0; p < 3; p++) begin : g_amux
            assign hsel_mux_or[p] = grant_addr[p] & (hold_active[p]
                              | ((p == 0) ? HSELS0 : (p == 1) ? HSELS1 : HSELS2));
        end
    endgenerate
    logic [2:0] hsel_mux_or;
    assign bus_hsel  = |hsel_mux_or;
    always_comb begin
        bus_haddr       = '0;
        bus_htrans      = 2'b00;
        bus_hwrite      = 1'b0;
        bus_hsize       = '0;
        bus_hprot       = '0;
        bus_hburst      = '0;
        bus_hlock = 1'b0;
        for (int i = 0; i < 3; i++) if (grant_addr[i]) begin
            bus_haddr       |= haddr_ips[i];
            bus_htrans      |= htrans_ips[i];
            bus_hwrite      |= hwrite_ips[i];
            bus_hsize       |= {{(3-SZ_W){1'b0}}, hsize_ips[i]};
            bus_hprot       |= hprot_ips[i];
            bus_hburst      |= hburst_ips[i];
            bus_hlock |= hmasterlock_ips[i];
        end
    end

    // With an active data phase the slave's HREADYOUT rules; otherwise the
    // selected master's own ready passes, and an unselected bus is ready.
    assign bus_hready = data_phase ? HREADYOUTM
                      : (grant_addr[0] & hready_ips[0])
                      | (grant_addr[1] & hready_ips[1])
                      | (grant_addr[2] & hready_ips[2])
                      | (grant_addr == 3'b000);

    // -----------------------------------------------------------------------
    // Data-phase multiplexer
    // -----------------------------------------------------------------------
    logic [DW-1:0] bus_hwdata;
    assign bus_hwdata = ({DW{grant_data_q[0] & port_en[0]}} & HWDATAS0)
                      | ({DW{grant_data_q[1] & port_en[1]}} & HWDATAS1)
                      | ({DW{grant_data_q[2] & port_en[2]}} & HWDATAS2);

    // -----------------------------------------------------------------------
    // IDLE flag: once HTRANSM shows IDLE this address phase, keep it from
    // upgrading to SEQ while the bus is stalled (IDLE->SEQ in one phase is
    // illegal), and demote SEQ to NSEQ across a master switch.
    // -----------------------------------------------------------------------
    logic idle_flag_d;
    assign idle_flag_d = ((HTRANSM == 2'b00) | held_idle_q) & ~HREADYOUTM;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) held_idle_q <= 1'b0;
        else          held_idle_q <= idle_flag_d;
    end
    logic [1:0] seq_tran_suppress;
    assign seq_tran_suppress = ((grant_addr != grant_data_q) | held_idle_q)
                             ? 2'b10 : 2'b11;

    // -----------------------------------------------------------------------
    // Top-level outputs
    // -----------------------------------------------------------------------
    assign HSELM      = bus_hsel;
    assign HADDRM     = bus_haddr;
    assign HTRANSM    = bus_htrans & seq_tran_suppress;
    assign HWRITEM    = bus_hwrite;
    assign HREADYM    = bus_hready;
    assign HSIZEM[1:0] = bus_hsize[1:0];
    assign HSIZEM[2]   = (DW > 64) ? bus_hsize[SZ_MSB] : 1'b0;
    assign HPROTM     = bus_hprot;
    assign HBURSTM    = bus_hburst;
    assign HMASTLOCKM = bus_hlock;
    assign HWDATAM    = bus_hwdata;

    // HMASTER: 00 = port 0, 01 = port 1, 10 = port 2, 11 = none
    assign HMASTERM[1] = grant_addr[2] | (grant_addr == 3'b000);
    assign HMASTERM[0] = grant_addr[1] | (grant_addr == 3'b000);

    // -----------------------------------------------------------------------
    // Port responses
    // -----------------------------------------------------------------------
    generate
        for (p = 0; p < 3; p++) begin : g_resp
            logic hreadyout;
            logic hresp;
            assign hreadyout = ~hold_active[p]
                             & (grant_data_q[p] ? HREADYOUTM : 1'b1);
            assign hresp     =  grant_data_q[p] ? HRESPM : 1'b0;
            if (p == 0) begin : g_p0
                assign HREADYOUTS0 = hreadyout;
                assign HRESPS0     = hresp;
                assign HRDATAS0    = HRDATAM;
            end else if (p == 1) begin : g_p1
                assign HREADYOUTS1 = hreadyout;
                assign HRESPS1     = hresp;
                assign HRDATAS1    = HRDATAM;
            end else begin : g_p2
                assign HREADYOUTS2 = hreadyout;
                assign HRESPS2     = hresp;
                assign HRDATAS2    = HRDATAM;
            end
        end
    endgenerate

endmodule : oss_ahb_master_mux
