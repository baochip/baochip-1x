// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// Cycle-accurate equivalence testbench between the closed Arm CMSDK
// cmsdk_ahb_to_ahb_sync and the open-source re-implementation
// oss_ahb_to_ahb_sync (which embeds oss_ahb_to_ahb_sync_err_canc when
// BURST=1, exactly as the original embeds cmsdk_ahb_to_ahb_sync_error_canc).
//
// Method: one constrained-random AHB master drives the slave side of BOTH
// bridges from identical inputs (HREADYS is wired to the original's
// HREADYOUTS exactly like a selected-slave bus would); an AHB slave model on
// the master side is driven from the original's M-side outputs and responds
// with random wait states and two-cycle ERROR responses. Every bridge output
// on both sides is compared every cycle; any divergence is a $fatal.
//
// The master exercises: deselected gaps, selected IDLE, singles, 2..4-beat
// bursts, BUSY beat insertion inside bursts, locked transfers followed by
// unlock, mid-burst abandonment (burst early termination after ERROR), and
// back-to-back transactions. The slave model exercises: 0..2 wait states and
// ERROR pairs (HREADY low then high, HRESP high both cycles) on SEQ beats in
// particular - the stimulus the error-cancel gasket exists for.
//
// Parameters (override with -G):
//   BURST    : bridge burst support (1 also activates the err-canc gasket)
//   AW/DW/MW : address/data/master-tag widths

//   CYCLES   : test length in HCLK cycles

`timescale 1ns/1ps

module tb_ahb_to_ahb_sync_equiv #(
    parameter integer BURST  = 1,
    parameter integer AW     = 32,
    parameter integer DW     = 32,
    parameter integer MW     = 4,
        parameter integer CYCLES = 100000
);
    logic hclk;
    logic hresetn;

    // AHB slave-side (upstream) stimulus, shared by both DUTs
    logic           hsels;
    logic [AW-1:0]  haddrs;
    logic [1:0]     htranss;
    logic [2:0]     hsizes;
    logic [3:0]     hprots;
    logic [MW-1:0]  hmasters;
    logic           hmastlocks;
    logic [DW-1:0]  hwdatas;
    logic [2:0]     hbursts;
    logic           hreadys;      // bus ready = original HREADYOUTS

    // original DUT outputs
    logic           hreadyout_o, hresp_o;
    logic [DW-1:0]  hrdata_o;
    logic [AW-1:0]  haddrm_o;
    logic [1:0]     htransm_o;
    logic [2:0]     hsizem_o;
    logic           hwritem_o, hmastlockm_o;
    logic [3:0]     hprotm_o;
    logic [MW-1:0]  hmasterm_o;
    logic [DW-1:0]  hwdatam_o;
    logic [2:0]     hburstm_o;

    // re-implementation DUT outputs
    logic           hreadyout_n, hresp_n;
    logic [DW-1:0]  hrdata_n;
    logic [AW-1:0]  haddrm_n;
    logic [1:0]     htransm_n;
    logic [2:0]     hsizem_n;
    logic           hwritem_n, hmastlockm_n;
    logic [3:0]     hprotm_n;
    logic [MW-1:0]  hmasterm_n;
    logic [DW-1:0]  hwdatam_n;
    logic [2:0]     hburstm_n;

    // downstream AHB slave response (shared)
    logic           hreadym;
    logic           hrespm;
    logic [DW-1:0]  hrdatam;

    cmsdk_ahb_to_ahb_sync #(
        .AW(AW), .DW(DW), .MW(MW), .BURST(BURST)
    ) u_orig (
        .HCLK(hclk), .HRESETn(hresetn),
        .HSELS(hsels), .HADDRS(haddrs), .HTRANSS(htranss), .HSIZES(hsizes),
        .HWRITES(hwrites), .HREADYS(hreadys), .HPROTS(hprots),
        .HMASTERS(hmasters), .HMASTLOCKS(hmastlocks), .HWDATAS(hwdatas),
        .HBURSTS(hbursts),
        .HREADYOUTS(hreadyout_o), .HRESPS(hresp_o), .HRDATAS(hrdata_o),
        .HADDRM(haddrm_o), .HTRANSM(htransm_o), .HSIZEM(hsizem_o),
        .HWRITEM(hwritem_o), .HPROTM(hprotm_o), .HMASTERM(hmasterm_o),
        .HMASTLOCKM(hmastlockm_o), .HWDATAM(hwdatam_o), .HBURSTM(hburstm_o),
        .HREADYM(hreadym), .HRESPM(hrespm), .HRDATAM(hrdatam)
    );

    oss_ahb_to_ahb_sync #(
        .AW(AW), .DW(DW), .MW(MW), .BURST(BURST)
    ) u_new (
        .HCLK(hclk), .HRESETn(hresetn),
        .HSELS(hsels), .HADDRS(haddrs), .HTRANSS(htranss), .HSIZES(hsizes),
        .HWRITES(hwrites), .HREADYS(hreadys), .HPROTS(hprots),
        .HMASTERS(hmasters), .HMASTLOCKS(hmastlocks), .HWDATAS(hwdatas),
        .HBURSTS(hbursts),
        .HREADYOUTS(hreadyout_n), .HRESPS(hresp_n), .HRDATAS(hrdata_n),
        .HADDRM(haddrm_n), .HTRANSM(htransm_n), .HSIZEM(hsizem_n),
        .HWRITEM(hwritem_n), .HPROTM(hprotm_n), .HMASTERM(hmasterm_n),
        .HMASTLOCKM(hmastlockm_n), .HWDATAM(hwdatam_n), .HBURSTM(hburstm_n),
        .HREADYM(hreadym), .HRESPM(hrespm), .HRDATAM(hrdatam)
    );

    // the bridges are the selected slaves: bus ready is the original's ready
    assign hreadys = hreadyout_o;

    initial hclk = 1'b0;
    always #5 hclk = ~hclk;

    ///////////////////////////////////////////////////////////////////////
    // scoreboard: every re-implementation output must equal the original's
    ///////////////////////////////////////////////////////////////////////
    integer cmp_cycles = 0;
    logic   fail = 1'b0;
    always @(negedge hclk) begin
        if (hresetn) begin
            if ((hreadyout_n !== hreadyout_o) || (hresp_n !== hresp_o)     ||
                (hrdata_n   !== hrdata_o)     ||
                (haddrm_n   !== haddrm_o)     || (htransm_n !== htransm_o) ||
                (hsizem_n   !== hsizem_o)     || (hwritem_n !== hwritem_o) ||
                (hprotm_n   !== hprotm_o)     || (hmasterm_n !== hmasterm_o) ||
                (hmastlockm_n !== hmastlockm_o) ||
                (hwdatam_n  !== hwdatam_o)    || (hburstm_n !== hburstm_o)) begin
                $display("MISMATCH t=%0t S: rdy n=%b o=%b resp n=%b o=%b rdata n=%08x o=%08x",
                         $time, hreadyout_n, hreadyout_o, hresp_n, hresp_o, hrdata_n, hrdata_o);
                $display("  M n/o: addr %08x %08x trans %b %b size %b %b wr %b %b prot %b %b mst %b %b lock %b %b wdata %08x %08x burst %b %b",
                         haddrm_n, haddrm_o, htransm_n, htransm_o, hsizem_n, hsizem_o,
                         hwritem_n, hwritem_o, hprotm_n, hprotm_o, hmasterm_n, hmasterm_o,
                         hmastlockm_n, hmastlockm_o, hwdatam_n, hwdatam_o, hburstm_n, hburstm_o);
                fail = 1'b1;
                $fatal(1, "oss_ahb_to_ahb_sync diverged from cmsdk_ahb_to_ahb_sync (BURST=%0d)",
                       BURST);
            end
            cmp_cycles++;
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // downstream AHB slave model.
    // Driven from the original's M-side outputs (identical by comparison).
    //   - captures the address phase on every cycle where the downstream bus
    //     is ready and HTRANSM[1] (pipelined AHB sampling)
    //   - responds with 0..2 wait states, then OKAY, or a two-cycle ERROR:
    //       (HREADY=0,HRESP=1) then (HREADY=1,HRESP=1)
    ///////////////////////////////////////////////////////////////////////
    typedef enum logic [1:0] { PS_IDLE, PS_DATA, PS_ERR1, PS_ERR2 } ps_t;
    ps_t                ps_st;
    integer             ps_cnt;
    logic               ps_err;
    logic [AW-1:0]      ps_addr;
    logic               ps_write;

    assign hreadym = (ps_st == PS_IDLE)  ||
                     ((ps_st == PS_DATA) && (ps_cnt == 0) && !ps_err) ||
                     (ps_st == PS_ERR2);
    assign hrespm  = (ps_st == PS_ERR1) || (ps_st == PS_ERR2);
    localparam logic [63:0] ERR_PAT64 = 64'h5A5A_5A5A_5A5A_5A5A;
    assign hrdatam = ~ps_addr ^ (ps_addr >> 3) ^ ps_cnt
                   ^ (ps_write ? {DW{1'b1}} : {DW{1'b0}})
                   ^ (hrespm ? ERR_PAT64[DW-1:0] : {DW{1'b0}});

    always @(posedge hclk) begin
        if (!hresetn) begin
            ps_st    <= PS_IDLE;
            ps_cnt   <= 0;
            ps_err   <= 1'b0;
            ps_addr  <= '0;
            ps_write <= 1'b0;
        end else if (hreadym && htransm_o[1]) begin
            // last ready cycle of the previous beat: capture the next
            // address phase (also valid while IDLE)
            ps_st    <= PS_DATA;
            ps_addr  <= haddrm_o;
            ps_write <= hwritem_o;
            ps_cnt   <= $urandom_range(0, 2);
            // 20% errors; bias SEQ beats (burst tails) harder - that is the
            // condition that drives the error-cancel gasket
            ps_err   <= ($urandom_range(0, 99) < 20) ||
                        ((htransm_o == 2'b11) && ($urandom_range(0, 99) < 35));
        end else begin
            unique case (ps_st)
                PS_IDLE:   ;
                PS_DATA:   if (ps_cnt != 0) ps_cnt <= ps_cnt - 1;
                           else if (ps_err) ps_st  <= PS_ERR1;
                PS_ERR1:   ps_st <= PS_ERR2;
                PS_ERR2:   ps_st <= PS_IDLE;
            endcase
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // constrained-random AHB master (upstream of the bridges)
    // Stimulus changes at negedge; DUTs sample at posedge. A pending beat
    // must be re-presented unchanged until the (settled) bus ready sampled
    // alongside it consumes its address phase.
    ///////////////////////////////////////////////////////////////////////
    typedef struct {
        bit                 sel;
        bit [1:0]           trans;
        bit                 lock;
        bit [AW-1:0]        addr;
        bit [2:0]           size;
        bit [2:0]           burst;
        bit [3:0]           prot;
        bit                 write;
        bit [31:0]          wdata;
    } phase_t;

    phase_t pend;

    function automatic void fill_beat(ref phase_t p);
        p.size  = 3'($urandom_range(0, 2));
        p.burst = 3'($urandom_range(0, 7));
        p.prot  = 4'($urandom_range(0, 15));
        p.write = $urandom_range(0, 1);
        p.addr  = AW'($urandom & ~((64'h1 << (p.size + 2)) - 64'h1));
        if ($urandom_range(0, 9) == 0) p.addr = AW'($urandom); // unaligned junk
        p.wdata = $urandom;
    endfunction

    initial begin : p_master
        int  len;          // beats left in current burst (valid when bursting)
        int  item;
        int  idle;         // idle cycles to present for an idle item
        int  busy_left;    // BUSY cycles to insert inside the burst
        bit  locked;
        bit  item_done;
        bit  rdy;
        bit  consumed;

        hresetn    = 1'b0;
        hsels      = 1'b0;
        haddrs     = '0;
        htranss    = 2'b00;
        hsizes     = 3'b010;
        hbursts    = 3'b000;
        hprots     = '0;
        hmasters   = '0;
        hmastlocks = 1'b0;
        hwdatas    = '0;
        repeat (5) @(negedge hclk);
        hresetn = 1'b1;
        repeat (2) @(negedge hclk);

        forever begin
            // ---- pick the next item to present
            item   = $urandom_range(0, 11);
            locked = 1'b0;
            len    = 1;
            idle   = 0;
            if (item <= 1) begin                 // deselected gap
                pend.sel   = 1'b0;
                pend.trans = 2'b00;
                idle       = $urandom_range(1, 4);
            end else if (item == 2) begin        // selected IDLE
                pend.sel   = 1'b1;
                pend.trans = 2'b00;
                idle       = $urandom_range(1, 4);
            end else begin                       // single or 2..4-beat burst
                len        = 1 + $urandom_range(0, 3);
                pend.sel   = 1'b1;
                pend.trans = 2'b10;              // NSEQ first beat
                locked     = ($urandom_range(0, 99) < 12);
            end
            fill_beat(pend);
            pend.lock  = locked;
            busy_left  = 0;
            item_done  = 1'b0;

            // ---- idle-type items: present for `idle` settled cycles
            while (idle != 0) begin
                @(negedge hclk);
                hsels      = pend.sel;
                htranss    = 2'b00;
                hmastlocks = 1'b0;
                if (hreadys) idle = idle - 1;
            end
            if (pend.trans == 2'b00) item_done = 1'b1;

            // ---- run a burst/single item to completion
            while (!item_done) begin
                @(negedge hclk);
                rdy = hreadys;                   // settled ready of this cycle

                if (busy_left != 0) begin
                    // BUSY occupies the pipeline slot after a burst beat
                    hsels      = 1'b1;
                    htranss    = 2'b01;
                    hmastlocks = pend.lock;
                    if (rdy) busy_left = busy_left - 1;
                    continue;
                end

                hsels      = pend.sel;
                htranss    = pend.trans;
                haddrs     = pend.addr;
                hsizes     = pend.size;
                hbursts    = pend.burst;
                hprots     = pend.prot;
                hmasters   = MW'($urandom_range(0, 15));
                hmastlocks = pend.lock;
                hwdatas    = pend.wdata;
                consumed   = rdy && pend.sel && pend.trans[1];

                if (consumed) begin
                    if (pend.trans == 2'b10) begin
                        if (len > 1) begin
                            // continue the burst with a SEQ beat...
                            len        = len - 1;
                            busy_left  = ($urandom_range(0, 99) < 25)
                                         ? $urandom_range(1, 2) : 0;
                            pend.trans = 2'b11;
                            fill_beat(pend);
                            pend.lock  = locked;
                            // ...unless the master aborts the rest (what a
                            // real master does when it sees an ERROR)
                            if ($urandom_range(0, 99) < 10) item_done = 1'b1;
                        end else begin
                            item_done = 1'b1;    // burst complete
                        end
                    end else if (pend.trans == 2'b11) begin
                        item_done = 1'b1;        // tail SEQ consumed
                    end
                end
                // else: hold pend unchanged (bus stalled downstream)
            end

            // ---- end a locked sequence the way real masters do: keep the
            // bridge selected and issue the next transfer unlocked. The
            // bridge must then insert its unlock IDLE on the master side
            // (UNLOCK) before granting that transfer.
            if (locked) begin
                fill_beat(pend);
                pend.sel   = 1'b1;
                pend.trans = 2'b10;          // NSEQ
                pend.lock  = 1'b0;
                @(negedge hclk);
                forever begin
                    rdy = hreadys;
                    hsels      = 1'b1;
                    htranss    = pend.trans;
                    haddrs     = pend.addr;
                    hsizes     = pend.size;
                    hbursts    = pend.burst;
                    hprots     = pend.prot;
                    hmasters   = MW'($urandom_range(0, 15));
                    hmastlocks = 1'b0;       // the unlock
                    hwdatas    = pend.wdata;
                    if (rdy) break;          // unlock beat consumed
                    @(negedge hclk);
                end
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // stimulus coverage: prove the hard paths were exercised
    ///////////////////////////////////////////////////////////////////////
    int cov_err;        // ERROR response cycle on the slave side
    int cov_busy;       // BUSY beat sampled on the slave side
    int cov_unlock;     // bridge inserted an unlock IDLE (UNLOCK)
    int cov_seq;        // SEQ beat presented upstream
    always @(negedge hclk) if (hresetn) begin
        if (hresp_o)                                        cov_err++;
        if (hreadyout_o && htranss == 2'b01 && hsels)       cov_busy++;
        if (hreadyout_o && htranss == 2'b11 && hsels)       cov_seq++;
        // UNLOCK: state 4'b0000 entered while not reset/idle-before-first
        if (u_orig.reg_fsm_state == 4'b0000 && cmp_cycles > 1) cov_unlock++;
    end

    ///////////////////////////////////////////////////////////////////////
    // finish
    ///////////////////////////////////////////////////////////////////////
    initial begin
        repeat (CYCLES) @(negedge hclk);
        if (!fail) begin
            if (cov_err == 0 || cov_busy == 0 || cov_unlock == 0 || cov_seq == 0) begin
                $display("FAIL coverage: err=%0d busy=%0d unlock=%0d seq=%0d",
                         cov_err, cov_busy, cov_unlock, cov_seq);
                fail = 1'b1;
            end else begin
                $display("PASS tb_ahb_to_ahb_sync_equiv BURST=%0d AW=%0d DW=%0d MW=%0d (%0d compared cycles) [cov: err=%0d busy=%0d unlock=%0d seq=%0d]",
                         BURST, AW, DW, MW, cmp_cycles,
                         cov_err, cov_busy, cov_unlock, cov_seq);
            end
        end
        $finish(0);
    end
endmodule
