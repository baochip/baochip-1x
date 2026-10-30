// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// Cycle-accurate equivalence testbench between the closed Arm CMSDK
// cmsdk_ahb_to_ahb_sync_error_canc burst error-cancel gasket and the
// open-source re-implementation oss_ahb_to_ahb_sync_err_canc.
//
// The gasket is driven port-for-port at the gasket boundary: HTRANSS tracks
// what the bridge core would put on the gasket's AHB1 side (IDLE/BUSY/SEQ
// streams with a NSEQ occasionally ending a burst), HREADYM/HRESPM model the
// downstream slave (wait states, single-cycle ERROR responses on beats).
// All three outputs are compared every cycle, plus $fatal on any X.
//
// Parameters (override with -G):
//   HCLKEN_MODE : 0 = tied 1, 1 = randomized enable toggling

//   CYCLES      : test length in HCLK cycles

`timescale 1ns/1ps

module tb_ahb_to_ahb_sync_err_canc_equiv #(
    parameter integer HCLKEN_MODE = 0,
        parameter integer CYCLES      = 100000
);
    logic hclk;
    logic hresetn;
    logic hclken;

    // shared stimulus
    logic [1:0] htranss;
    logic       hreadym;
    logic       hrespm;

    // original outputs
    logic       hreadyouts_o, hresps_o;
    logic [1:0] htransm_o;

    // re-implementation outputs
    logic       hreadyouts_n, hresps_n;
    logic [1:0] htransm_n;

    cmsdk_ahb_to_ahb_sync_error_canc u_orig (
        .HCLK(hclk), .HCLKEN(hclken), .HRESETn(hresetn),
        .HTRANSS(htranss),
        .HREADYOUTS(hreadyouts_o), .HRESPS(hresps_o),
        .HTRANSM(htransm_o),
        .HREADYM(hreadym), .HRESPM(hrespm)
    );

    oss_ahb_to_ahb_sync_err_canc u_new (
        .HCLK(hclk), .HCLKEN(hclken), .HRESETn(hresetn),
        .HTRANSS(htranss),
        .HREADYOUTS(hreadyouts_n), .HRESPS(hresps_n),
        .HTRANSM(htransm_n),
        .HREADYM(hreadym), .HRESPM(hrespm)
    );

    initial hclk = 1'b0;
    always #5 hclk = ~hclk;

    ///////////////////////////////////////////////////////////////////////
    // scoreboard
    ///////////////////////////////////////////////////////////////////////
    integer cmp_cycles = 0;
    logic   fail = 1'b0;
    always @(negedge hclk) begin
        if (hresetn) begin
            if ((hreadyouts_n !== hreadyouts_o) || (hresps_n !== hresps_o) ||
                (htransm_n    !== htransm_o)) begin
                $display("MISMATCH t=%0t transs=%b rdy n=%b o=%b resp n=%b o=%b transm n=%b o=%b (clken=%b mrdy=%b mresp=%b)",
                         $time, htranss, hreadyouts_n, hreadyouts_o, hresps_n, hresps_o,
                         htransm_n, htransm_o, hclken, hreadym, hrespm);
                fail = 1'b1;
                $fatal(1, "oss_ahb_to_ahb_sync_err_canc diverged");
            end
            cmp_cycles++;
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // HCLKEN
    ///////////////////////////////////////////////////////////////////////
    initial begin
        if (HCLKEN_MODE == 0) hclken = 1'b1;
        forever begin
            @(negedge hclk);
            hclken <= (HCLKEN_MODE == 0) ? 1'b1 : ($urandom_range(0, 3) != 0);
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // stimulus coverage: the gasket must actually have entered error-cancel
    // mode, generated chained ERRORs, and seen BUSY/SEQ/NSEQ inputs.
    ///////////////////////////////////////////////////////////////////////
    int cov_ctrl_err;   // cycles in error-cancel mode (original's FSM)
    int cov_chain;      // ERROR1 entered while already generated one (chain)
    int cov_nseq;       // NSEQ pass-through
    int cov_busy;       // BUSY beat presented
    int cov_seq;        // SEQ beat presented
    always @(negedge hclk) if (hresetn) begin
        if (u_orig.control_state == 1'b1)                    cov_ctrl_err++;
        // a synthesized ERROR about to start while a SEQ beat is presented:
        // the chained-error path of the generator
        if (u_orig.next_gen_state == 2'b10 && htranss == 2'b11) cov_chain++;
        if (htranss == 2'b10)                                cov_nseq++;
        if (htranss == 2'b01)                                cov_busy++;
        if (htranss == 2'b11)                                cov_seq++;
    end

    ///////////////////////////////////////////////////////////////////////
    // downstream slave model: ready after random stalls; errors only while
    // a burst beat (SEQ/BUSY) or single is being answered.
    ///////////////////////////////////////////////////////////////////////
    typedef enum logic [1:0] { SL_WAIT, SL_OK, SL_ERR } sl_t;
    sl_t    sl_st;
    integer sl_cnt;
    logic   sl_err;

    assign hreadym = (sl_st == SL_OK);
    assign hrespm  = (sl_st == SL_ERR);

    always @(posedge hclk) begin
        if (!hresetn) begin
            sl_st  <= SL_OK;
            sl_cnt <= 0;
            sl_err <= 1'b0;
        end else if (hclken) begin
            unique case (sl_st)
                SL_OK: if (htranss[1] || (htranss == 2'b01)) begin
                    // answer a new beat: NSEQ/SEQ start, or BUSY passthrough
                    sl_cnt <= $urandom_range(0, 2);
                    sl_err <= ($urandom_range(0, 99) < 30);
                    sl_st  <= SL_WAIT;
                end
                SL_WAIT: begin
                    if (sl_cnt != 0) sl_cnt <= sl_cnt - 1;
                    else             sl_st  <= sl_err ? SL_ERR : SL_OK;
                end
                SL_ERR:  sl_st <= SL_OK;   // one-cycle ERROR on the bus
                default: sl_st <= SL_OK;
            endcase
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // bridge-core-side stimulus: bursts of NSEQ followed by SEQ beats, with
    // BUSY insertion and IDLE tails, mirroring what oss_ahb_to_ahb_sync
    // feeds the gasket's HTRANSS register (it only updates when the gasket
    // answers ready, so hold each value until hreadyouts_o).
    ///////////////////////////////////////////////////////////////////////
    initial begin : p_stim
        int len;
        bit [1:0] t;
        hresetn = 1'b0;
        htranss = 2'b00;
        repeat (5) @(negedge hclk);
        hresetn = 1'b1;
        repeat (2) @(negedge hclk);

        forever begin
            // announce a burst
            len = 1 + $urandom_range(0, 4);
            t   = 2'b10;                      // NSEQ
            for (int i = 0; i < len; i++) begin
                htranss = t;
                // hold until the gasket accepts (its registered HREADY)
                do @(negedge hclk); while (!(hreadyouts_o && hclken));
                t = ($urandom_range(0, 99) < 20) ? 2'b01 : 2'b11; // BUSY or SEQ
            end
            // burst tail: the core drives SEQ while the upstream stream is
            // still live, then IDLE when it is not
            if ($urandom_range(0, 99) < 30) begin
                htranss = 2'b11;
                do @(negedge hclk); while (!(hreadyouts_o && hclken));
            end
            htranss = 2'b00;
            repeat ($urandom_range(1, 3)) @(negedge hclk);
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // finish
    ///////////////////////////////////////////////////////////////////////
    initial begin
        repeat (CYCLES) @(negedge hclk);
        if (!fail) begin
            if (cov_ctrl_err == 0 || cov_chain == 0 || cov_nseq == 0 ||
                cov_busy == 0 || cov_seq == 0) begin
                $display("FAIL coverage: ctrl_err=%0d chain=%0d nseq=%0d busy=%0d seq=%0d",
                         cov_ctrl_err, cov_chain, cov_nseq, cov_busy, cov_seq);
                fail = 1'b1;
            end else begin
                $display("PASS tb_ahb_to_ahb_sync_err_canc_equiv HCLKEN_MODE=%0d (%0d compared cycles) [cov: errmode=%0d chain=%0d nseq=%0d busy=%0d seq=%0d]",
                         HCLKEN_MODE, cmp_cycles,
                         cov_ctrl_err, cov_chain, cov_nseq, cov_busy, cov_seq);
            end
        end
        $finish(0);
    end
endmodule
