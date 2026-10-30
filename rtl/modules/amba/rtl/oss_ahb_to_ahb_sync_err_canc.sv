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

// Open-source replacement for the Arm CMSDK `cmsdk_ahb_to_ahb_sync_error_canc`
// burst error-cancel gasket (cmsdk_ahb_to_ahb_sync_error_canc.v, Cortex-M
// System Design Kit r1p0-01rel0), used by oss_ahb_to_ahb_sync when BURST=1.
//
// Functionally equivalent to the original, cycle-for-cycle, for every
// reachable state; verified in tb/oss_equiv/tb_ahb_to_ahb_sync_err_canc_equiv.sv.
//
// ---------------------------------------------------------------------------
// Gasket behavior
// ---------------------------------------------------------------------------
//
//                +-------------+
//   AHB1   +-----+  ErrCancel  +-----+ AHB2
//                +-------------+
//   HCLK                           HCLK
//
// When an AHB master sees ERROR, it may either continue its burst or abort by
// driving IDLE in the second cycle of the error response. A registered bridge
// cannot predict that choice, so this gasket sits between the bridge core and
// AHB2 and assumes the master continues: once an ERROR arrives from the slave
// (control_q == CANC), the gasket
//   - answers every further burst beat arriving on AHB1 with a synthesized
//     two-cycle ERROR response (HREADY low then high, HRESP high), and
//   - drives IDLE on AHB2 (never propagating the master's SEQ beats) until
//     the burst on AHB1 ends,
// then returns to pass-through.
//
// The error-response generator emits the two-phase ERROR (low-HREADY cycle,
// high-HREADY cycle) back-to-back per beat and can chain them without an idle
// gap: IDLE -> ERR1 -> ERR2 -> ERR1 -> ... driven by whether AHB1 keeps
// issuing SEQ beats.

module oss_ahb_to_ahb_sync_err_canc (
    // Clk / Rst.
    input  logic        HCLK,        // bus clock
    input  logic        HCLKEN,      // clock enable
    input  logic        HRESETn,     // reset

    // AHB1 side (bridge core)
    input  logic  [1:0] HTRANSS,     // transfer type in
    output logic        HREADYOUTS,  // transfer done out
    output logic        HRESPS,      // slave response out

    // AHB2 side (downstream slave)
    output logic [1:0]  HTRANSM,     // transfer type out
    input  logic        HREADYM,     // transfer done in
    input  logic        HRESPM       // slave response in
);
    // HTRANS transfer type encodings.
    localparam logic [1:0] T_IDLE = 2'b00;
    localparam logic [1:0] T_BUSY = 2'b01;
    localparam logic [1:0] T_NSEQ = 2'b10;
    localparam logic [1:0] T_SEQ = 2'b11;

    // Control FSM: pass-through vs. error-cancel mode.
    localparam logic       PASS = 1'b0;
    localparam logic       CANC = 1'b1;

    // Error response generator: one-hot-ish encoding so HREADYOUT/HRESP
    // decode off register bits directly.
    localparam logic [1:0] IDLE = 2'b01;
    localparam logic [1:0] ERR1 = 2'b10;
    localparam logic [1:0] ERR2 = 2'b11;

    logic                  control_q;
    logic                  control_d;
    logic [1:0]            gen_q;
    logic [1:0]            gen_d;

    // BUSY or SEQ on AHB1 means "this beat belongs to a burst".
    logic                  beat_on;
    assign beat_on = (HTRANSS == T_BUSY) | (HTRANSS == T_SEQ);

    // Generated responses while in error-cancel mode.
    logic                  err_ready;
    logic                  err_resp;
    assign err_ready = (gen_q == IDLE) | (gen_q == ERR2);
    assign err_resp      = (gen_q == ERR1) | (gen_q == ERR2);

    ///////////////////////////////////////////////////////////////////////
    // control FSM
    // enter error mode when an ERROR comes back during a burst beat; leave
    // when AHB1 has stopped bursting and the synthesized ERROR is complete.
    ///////////////////////////////////////////////////////////////////////
    always_comb begin
        case (control_q)
            PASS:
                control_d = HRESPM & beat_on ? CANC
                                                      : PASS;
            CANC:
                control_d = ~beat_on & err_ready ? PASS
                                                                : CANC;
            default:
                control_d = 1'bx; // unreachable; X-propagate
        endcase
    end

    ///////////////////////////////////////////////////////////////////////
    // error response generator
    // arms on any ERROR seen on AHB2 (jumps straight to the second,
    // HREADY-high half since the upstream bridge already emitted the first),
    // then chains ERROR1/ERROR2 per additional SEQ beat on AHB1.
    ///////////////////////////////////////////////////////////////////////
    always_comb begin
        case (gen_q)
            IDLE:
                gen_d = HRESPM                                                              ? ERR2 :
                          ((HTRANSS == T_SEQ) & (control_q == CANC))           ? ERR1 :
                                                                                               IDLE;
            ERR1:
                gen_d = ERR2;
            ERR2:
                gen_d = (HTRANSS == T_SEQ) ? ERR1   // another burst beat
                                               : IDLE;
            default:
                gen_d = 2'bxx; // unreachable; X-propagate
        endcase
    end

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            control_q <= PASS;
            gen_q     <= IDLE;
        end else if (HCLKEN) begin
            control_q <= control_d;
            gen_q     <= gen_d;
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // outputs
    ///////////////////////////////////////////////////////////////////////
    always_comb begin
        if (control_q == PASS) begin // pass-through
            HREADYOUTS = HREADYM;
            HRESPS     = HRESPM;
        end else begin                          // synthesized ERROR stream
            HREADYOUTS = err_ready;
            HRESPS     = err_resp;
        end
    end

    always_comb begin
        if (control_q == PASS) begin // pass HTRANS downstream
            HTRANSM = HTRANSS;
        end else if (HTRANSS == T_NSEQ) begin // a fresh NSEQ still goes out
            HTRANSM = HTRANSS;
        end else begin                            // burst beats are cancelled
            HTRANSM = T_IDLE;
        end
    end
endmodule
