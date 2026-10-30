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

// Open-source replacement for the Arm CMSDK `cmsdk_ahb_to_ahb_sync` registered
// bridge (cmsdk_ahb_to_ahb_sync.v, Cortex-M System Design Kit r1p0-01rel0).
//
// Why this file exists: the sce bus-bridge path used to pull the closed Arm
// model out of cram-nto; this module replaces it in sim builds (see
// deps/soc_oss/sce_adapter.py). Functionally equivalent to the original
// for every reachable state, cycle-for-cycle, with matching reset values, so
// it drops into `ahb_sync` in amba_components.sv unchanged. Verified against
// the original RTL in tb/oss_equiv/tb_ahb_to_ahb_sync_equiv.sv, BURST=1/0.
//
// ---------------------------------------------------------------------------
// Bridge behavior
// ---------------------------------------------------------------------------
// A full-registration AHB bridge for timing isolation: every address-phase
// control signal is sampled into a register, so there is no combinational
// path between the two bus interfaces. Each transferred beat takes:
//
//   cycle 0: address phase on the slave side (IDLE state "sees" the beat)
//   cycle 1: address phase presented on the master side   (ADDR)
//   cycle 2+: data phase on the master side               (WAIT)
//   cycle n+1: data (hrdata / response) returned upstream (DONE / ERR1 / ERR2)
//
// The FSM state encoding is not accidental: bit [2] drives HREADYOUTS and
// bit [3] drives HRESPS directly, so only IDLE/DONE/ERR2 (and the error
// pair's second cycle) release the upstream bus.
//
// On the master side, when BURST=1, beats are handed to
// oss_ahb_to_ahb_sync_err_canc, which cancels the remainder of a burst (and
// answers it with synthesized ERRORs) after the downstream slave has
// signaled ERROR, because a registered bridge cannot know whether the
// upstream master will continue or abort. BUSY beats on the slave side get
// re-issued as BUSY on the master side (address updated from the live input),
// keeping downstream burst pacing intact.
//
// Locked transfers: if the master drops HMASTLOCKS (or HSELS) after a locked
// beat, the bridge inserts one IDLE on the master side before the next
// transfer (UNLOCK), so the downstream bus observes the unlock.
//
// Port list, parameter names, and reset values intentionally keep the Arm
// naming so `ahb_sync` needs no edits beyond the module name.

module oss_ahb_to_ahb_sync #(
    parameter AW    = 32,   // AHB address width (both sides)
    parameter DW    = 32,   // AHB data width (both sides)
    parameter MW    = 4,    // master-tag (HMASTER) width
    parameter BURST = 0     // 1: support burst transactions on the master side
) (
    // Clk / Rst.
    input  logic          HCLK,        // Clock
    input  logic          HRESETn,     // Reset

    // AHB slave interface (upstream, facing the bus master)
    input  logic          HSELS,       // Device select
    input  logic [AW-1:0] HADDRS,      // Address
    input  logic    [1:0] HTRANSS,     // Transfer type
    input  logic    [2:0] HSIZES,      // Transfer size
    input  logic          HWRITES,     // Write control
    input  logic          HREADYS,     // Bus ready (data phase underway)
    input  logic    [3:0] HPROTS,      // Protection control
    input  logic  [MW-1:0] HMASTERS,   // Master tag
    input  logic          HMASTLOCKS,  // Locked transfer
    input  logic [DW-1:0] HWDATAS,     // Write data
    input  logic    [2:0] HBURSTS,     // Burst type

    output logic          HREADYOUTS,  // Device ready
    output logic          HRESPS,      // Transfer response
    output logic [DW-1:0] HRDATAS,     // Read data

    // AHB master interface (downstream, facing slaves)
    output logic [AW-1:0] HADDRM,      // Address
    output logic    [1:0] HTRANSM,     // Transfer type
    output logic    [2:0] HSIZEM,      // Transfer size
    output logic          HWRITEM,     // Write control
    output logic    [3:0] HPROTM,      // Protection control
    output logic  [MW-1:0] HMASTERM,   // Master tag
    output logic          HMASTLOCKM,  // Locked transfer
    output logic [DW-1:0] HWDATAM,     // Write data
    output logic    [2:0] HBURSTM,     // Burst type

    input  logic          HREADYM,     // Downstream bus ready
    input  logic          HRESPM,      // Downstream response
    input  logic [DW-1:0] HRDATAM      // Downstream read data
);
    // Only the bits needed to encode a beat aligned to DW are held (a DW-wide
    // bus never sees HSIZE above log2(DW/8)).
    localparam int SZ_W = (DW > 64) ? 3 : 2;
    localparam int SZ_MSB = SZ_W - 1;

    // HTRANS transfer type encodings.
    localparam logic [1:0] T_IDLE = 2'b00;
    localparam logic [1:0] T_BUSY = 2'b01;
    localparam logic [1:0] T_NSEQ = 2'b10;
    localparam logic [1:0] T_SEQ = 2'b11;

    // HBURST encodings (only SINGLE is decoded by the bridge itself).
    localparam logic [2:0] BUR_SGL = 3'b000;

    // Main FSM; one-hot-ish by construction. Bit [2] == HREADYOUTS,
    // bit [3] == HRESPS.
    localparam logic [3:0] IDLE = 4'b0100;    // both sides idle
    localparam logic [3:0] REQ = 4'b0001;     // master-side address phase
    localparam logic [3:0] UNLOCK = 4'b0000;  // master-side unlock IDLE
    localparam logic [3:0] DATA = 4'b0010;    // master-side data phase
    localparam logic [3:0] RET = 4'b0110;     // slave-side completion
    localparam logic [3:0] ERR1 = 4'b1000;    // slave-side ERROR cycle 1
    localparam logic [3:0] ERR2 = 4'b1100;    // slave-side ERROR cycle 2

    // A valid address phase on the slave side completes when the beat is
    // selected and the bus is in its data phase.
    logic                  addr_done;
    assign addr_done = HSELS & HTRANSS[1] & HREADYS;

    ///////////////////////////////////////////////////////////////////////
    // unlock IDLE insertion
    // Tracks "a locked transfer is outstanding"; once the master drops the
    // lock (or stops selecting the bridge), one IDLE must be squeezed onto
    // the master side before the following transfer.
    ///////////////////////////////////////////////////////////////////////
    logic                  lock_trans_valid_q;
    logic                  unlock_vld;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)                                    lock_trans_valid_q <= 1'b0;
        else if (addr_done & HMASTLOCKS)         lock_trans_valid_q <= 1'b1;
        else if (HREADYS & (HSELS & ~HMASTLOCKS | ~HSELS)) lock_trans_valid_q <= 1'b0;
    end

    assign unlock_vld = HREADYS & lock_trans_valid_q
                             & (~HMASTLOCKS & HSELS | ~HSELS);

    ///////////////////////////////////////////////////////////////////////
    // main FSM
    ///////////////////////////////////////////////////////////////////////
    logic [3:0]            fsm_q;
    logic [3:0]            fsm_d;

    // error-cancel gasket feedback (direct slave wires when BURST=0)
    logic                  hresp_ec;
    logic                  hreadyout_ec;
    logic [1:0]            htrans_ec;

    always_comb begin
        case (fsm_q)
            IDLE:   // waiting for a slave-side address phase
                fsm_d = ~addr_done ? IDLE   :
                          unlock_vld  ? UNLOCK :
                                               REQ;
            UNLOCK: // one IDLE cycle on the master side
                fsm_d = REQ;
            REQ:   // address presented downstream for one cycle
                fsm_d = DATA;
            DATA:   // downstream data phase; gasketed response decides
                fsm_d = hresp_ec     ? ERR1 :
                          hreadyout_ec ? RET :
                                            DATA;
            RET:   // data delivered upstream; chain if another beat is out
                fsm_d = ~addr_done ? IDLE   :
                          unlock_vld  ? UNLOCK :
                                               REQ;
            ERR1:
                fsm_d = ERR2;
            ERR2:
                fsm_d = ~addr_done ? IDLE   :
                          unlock_vld  ? UNLOCK :
                                               REQ;
            default:
                fsm_d = 4'bxxxx; // unreachable; X-propagate
        endcase
    end

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) fsm_q <= IDLE;
        else          fsm_q <= fsm_d;
    end

    ///////////////////////////////////////////////////////////////////////
    // address-phase holding registers
    ///////////////////////////////////////////////////////////////////////
    logic [AW-1:0]         haddr_q;
    logic                  hwrite_q;
    logic [SZ_MSB:0]    hsize_q;
    logic [3:0]            hprot_q;
    logic [MW-1:0]         hmaster_q;
    logic                  hmastlock_q;
    logic [2:0]            hburst_q;
    logic [1:0]            hold_htrans_q; // HTRANSS of the last valid beat
                                          // (replayed after an unlock IDLE)

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            hsize_q        <= '0;
            hwrite_q       <= 1'b0;
            hprot_q        <= '0;
            hmaster_q      <= '0;
            hold_htrans_q  <= T_IDLE;
        end else if (addr_done) begin
            hsize_q        <= HSIZES[SZ_MSB:0];
            hwrite_q       <= HWRITES;
            hprot_q        <= HPROTS;
            hmaster_q      <= HMASTERS;
            hold_htrans_q  <= HTRANSS;
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // write/read data holding register (one register, both directions)
    // writes are captured during REQ (the slave-side data phase is
    // concurrent); read data is captured at the end of the master-side data
    // phase and delivered in the next cycle.
    ///////////////////////////////////////////////////////////////////////
    logic [DW-1:0]         hdata_q;
    logic                  rdata_upd;
    logic                  wdata_upd;

    assign rdata_upd  = (fsm_q == DATA) & ~hwrite_q &  hreadyout_ec;
    assign wdata_upd = (fsm_q == REQ) &  hwrite_q;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)                        hdata_q <= '0;
        else if (rdata_upd | wdata_upd)
            hdata_q <= wdata_upd ? HWDATAS : HRDATAM;
    end

    // Master lock follows the sampled beat; also refreshed on unlock so the
    // inserted IDLE carries the de-asserted lock.
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)                                          hmastlock_q <= 1'b0;
        else if (addr_done | unlock_vld)        hmastlock_q <= HMASTLOCKS;
    end

    // Master-side address/control update strobe.
    logic                  req_load;
    assign req_load = (fsm_d == REQ);

    ///////////////////////////////////////////////////////////////////////
    // master-side transaction generation
    ///////////////////////////////////////////////////////////////////////
    logic [1:0]            htransm_q;
    logic [1:0]            htrans_d;

    generate
    if (BURST == 1) begin : gen_burst
        // Burst cancellation gasket: see oss_ahb_to_ahb_sync_err_canc.
        oss_ahb_to_ahb_sync_err_canc u_err_canc (
            .HCLK       (HCLK),
            .HCLKEN     (1'b1),
            .HRESETn    (HRESETn),
            .HTRANSS    (htransm_q),
            .HREADYOUTS (hreadyout_ec),
            .HRESPS     (hresp_ec),
            .HTRANSM    (htrans_ec),
            .HREADYM    (HREADYM),
            .HRESPM     (HRESPM)
        );

        // An ongoing SEQ/BURST upstream means the next master-side beat is
        // BUSY: the downstream slave must not see the burst beat until the
        // upstream one retires.
        logic            force_busy;
        assign force_busy = HTRANSS[0] & HSELS;

        // IDLE while unlocking; the announced beat when the FSM is about to
        // present it (replaying the held type right after an unlock IDLE);
        // BUSY to hold downstream pacing; else IDLE.
        assign htrans_d = unlock_vld ? T_IDLE     :
                              req_load      ? ((fsm_q == UNLOCK) ? hold_htrans_q
                                                                         : HTRANSS) :
                              force_busy     ? T_BUSY     :
                                                  T_IDLE;

        always_ff @(posedge HCLK or negedge HRESETn) begin
            if (!HRESETn)                   htransm_q <= T_IDLE;
            else if (hreadyout_ec)       htransm_q <= htrans_d;
        end

        assign HTRANSM = htrans_ec;

        // Address updates with a new announced beat, and tracks HADDRS while
        // bouncing BUSY beats (their address phases arrive live).
        logic            addr_load;
        assign addr_load = addr_done |
                                    ((fsm_q == REQ) & force_busy);

        always_ff @(posedge HCLK or negedge HRESETn) begin
            if (!HRESETn)               haddr_q <= '0;
            else if (addr_load) haddr_q <= HADDRS;
        end

        always_ff @(posedge HCLK or negedge HRESETn) begin
            if (!HRESETn)               hburst_q <= BUR_SGL;
            else if (addr_done) hburst_q <= HBURSTS;
        end

        assign HBURSTM = hburst_q;
    end else begin : gen_no_burst
        // Single transfers only: the master side issues NSEQ/IDLE, never
        // SEQ/BUSY, and the slave's response wires pass straight through.
        assign hresp_ec     = HRESPM;
        assign hreadyout_ec = HREADYM;
        assign htrans_ec    = T_IDLE; // unused

        assign htrans_d = unlock_vld ? T_IDLE :
                              req_load      ? ((fsm_q == UNLOCK) ? {hold_htrans_q[1], 1'b0}
                                                                         : {HTRANSS[1], 1'b0}) :
                                                  T_IDLE;

        always_ff @(posedge HCLK or negedge HRESETn) begin
            if (!HRESETn)         htransm_q <= T_IDLE;
            else if (HREADYM)     htransm_q <= htrans_d;
        end

        assign HTRANSM = {htransm_q[1], 1'b0}; // IDLE or NSEQ only

        always_ff @(posedge HCLK or negedge HRESETn) begin
            if (!HRESETn)               haddr_q <= '0;
            else if (addr_done) haddr_q <= HADDRS;
        end

        assign HBURSTM = BUR_SGL; // always single
    end
    endgenerate

    ///////////////////////////////////////////////////////////////////////
    // outputs
    ///////////////////////////////////////////////////////////////////////
    assign HREADYOUTS = fsm_q[2]; // DONE, IDLE and ERR2 release the bus
    assign HRESPS     = fsm_q[3]; // ERR1/ERR2 present ERROR
    assign HRDATAS    = hdata_q;

    assign HADDRM     = haddr_q;
    assign HSIZEM[2]  = (DW > 64) ? hsize_q[SZ_MSB] : 1'b0;
    assign HSIZEM[1:0]= hsize_q[1:0];
    assign HWRITEM    = hwrite_q;
    assign HPROTM     = hprot_q;
    assign HMASTERM   = hmaster_q;
    assign HMASTLOCKM = hmastlock_q;
    assign HWDATAM    = hdata_q;

endmodule
