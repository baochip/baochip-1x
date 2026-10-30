// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// Cycle-accurate equivalence testbench between the closed Arm CMSDK
// cmsdk_ahb_master_mux and the open-source re-implementation
// oss_ahb_master_mux.
//
// Method: three constrained-random AHB masters and one shared randomized
// slave (wait states + two-cycle ERROR responses) drive BOTH muxes from
// identical inputs. Each master holds its address phase unchanged until its
// own port ready (the original's HREADYOUTSx) comes back high, and the same
// value is fed to the re-implementation; every mux output (master port and
// the three slave-side ports) is compared every cycle, so any divergence in
// arbitration, hold-stage timing, burst/lock/error stickiness, or response
// steering is a $fatal.
//
// Parameters (override with -G):
//   P0/P1/P2 : PORT0/1/2_ENABLE instantiations
//   DW       : data bus width (HSIZE truncation at DW>64)
//   CYCLES   : test length in HCLK cycles

`timescale 1ns/1ps

module tb_ahb_master_mux_equiv #(
    parameter integer P0     = 1,
    parameter integer P1     = 1,
    parameter integer P2     = 1,
    parameter integer DW     = 32,
    parameter integer ERRPCT = 15,   // slave error probability on announced xfer
    parameter integer CYCLES = 200000
);
    // max legal HSIZE index for the data width (original truncation rule)
    localparam int HSIZE_HI = (DW >= 128) ? 3 : 2;

    logic hclk;
    logic hresetn;

    localparam logic [2:0] P_EN = {P2 != 0, P1 != 0, P0 != 0};

    // master-side pins (shared by both DUTs), indexed by port
    logic          hsels        [3];
    logic [31:0]   haddrs       [3];
    logic [1:0]    htranss      [3];
    logic [2:0]    hsizes       [3];
    logic          hwrites      [3];
    logic          hreadys      [3];  // = original HREADYOUTSx
    logic [3:0]    hprots       [3];
    logic [2:0]    hbursts      [3];
    logic          hmasterlocks [3];
    logic [DW-1:0] hwdatas      [3];

    // original slave-side outputs
    logic          hreadyouts_o [3];
    logic          hresps_o     [3];
    logic [DW-1:0] hrdatas_o    [3];

    // original master-port outputs
    logic          hselm_o, hwrite_m_o, hready_m_o, hmasterlock_m_o;
    logic [31:0]   haddrm_o;
    logic [1:0]    htransm_o, hmasterm_o;
    logic [2:0]    hsizem_o, hburstm_o;
    logic [3:0]    hprotm_o;
    logic [DW-1:0] hwdatam_o;

    // re-implementation slave-side outputs
    logic          hreadyouts_n [3];
    logic          hresps_n     [3];
    logic [DW-1:0] hrdatas_n    [3];

    // re-implementation master-port outputs
    logic          hselm_n, hwrite_m_n, hready_m_n, hmasterlock_m_n;
    logic [31:0]   haddrm_n;
    logic [1:0]    htransm_n, hmasterm_n;
    logic [2:0]    hsizem_n, hburstm_n;
    logic [3:0]    hprotm_n;
    logic [DW-1:0] hwdatam_n;

    // shared slave response on the original's master port
    logic          hreadyoutm;
    logic          hrespom;
    logic [DW-1:0] hrdatamn;

    // ---- original ----------------------------------------------------
    cmsdk_ahb_master_mux #(.PORT0_ENABLE(P0), .PORT1_ENABLE(P1),
        .PORT2_ENABLE(P2), .DW(DW)) u_orig (
        .HCLK(hclk), .HRESETn(hresetn),
        .HSELS0(hsels[0]),       .HADDRS0(haddrs[0]),       .HTRANSS0(htranss[0]),
        .HSIZES0(hsizes[0]),     .HWRITES0(hwrites[0]),     .HREADYS0(hreadys[0]),
        .HPROTS0(hprots[0]),     .HBURSTS0(hbursts[0]),     .HMASTLOCKS0(hmasterlocks[0]),
        .HWDATAS0(hwdatas[0]),
        .HREADYOUTS0(hreadyouts_o[0]), .HRESPS0(hresps_o[0]), .HRDATAS0(hrdatas_o[0]),
        .HSELS1(hsels[1]),       .HADDRS1(haddrs[1]),       .HTRANSS1(htranss[1]),
        .HSIZES1(hsizes[1]),     .HWRITES1(hwrites[1]),     .HREADYS1(hreadys[1]),
        .HPROTS1(hprots[1]),     .HBURSTS1(hbursts[1]),     .HMASTLOCKS1(hmasterlocks[1]),
        .HWDATAS1(hwdatas[1]),
        .HREADYOUTS1(hreadyouts_o[1]), .HRESPS1(hresps_o[1]), .HRDATAS1(hrdatas_o[1]),
        .HSELS2(hsels[2]),       .HADDRS2(haddrs[2]),       .HTRANSS2(htranss[2]),
        .HSIZES2(hsizes[2]),     .HWRITES2(hwrites[2]),     .HREADYS2(hreadys[2]),
        .HPROTS2(hprots[2]),     .HBURSTS2(hbursts[2]),     .HMASTLOCKS2(hmasterlocks[2]),
        .HWDATAS2(hwdatas[2]),
        .HREADYOUTS2(hreadyouts_o[2]), .HRESPS2(hresps_o[2]), .HRDATAS2(hrdatas_o[2]),
        .HSELM(hselm_o),   .HADDRM(haddrm_o),   .HTRANSM(htransm_o),
        .HSIZEM(hsizem_o), .HWRITEM(hwrite_m_o), .HREADYM(hready_m_o),
        .HPROTM(hprotm_o), .HBURSTM(hburstm_o), .HMASTLOCKM(hmasterlock_m_o),
        .HWDATAM(hwdatam_o),
        .HREADYOUTM(hreadyoutm), .HRESPM(hrespom), .HRDATAM(hrdatamn),
        .HMASTERM(hmasterm_o)
    );

    // ---- re-implementation --------------------------------------------
    oss_ahb_master_mux #(.PORT0_ENABLE(P0), .PORT1_ENABLE(P1),
        .PORT2_ENABLE(P2), .DW(DW)) u_new (
        .HCLK(hclk), .HRESETn(hresetn),
        .HSELS0(hsels[0]),       .HADDRS0(haddrs[0]),       .HTRANSS0(htranss[0]),
        .HSIZES0(hsizes[0]),     .HWRITES0(hwrites[0]),     .HREADYS0(hreadys[0]),
        .HPROTS0(hprots[0]),     .HBURSTS0(hbursts[0]),     .HMASTLOCKS0(hmasterlocks[0]),
        .HWDATAS0(hwdatas[0]),
        .HREADYOUTS0(hreadyouts_n[0]), .HRESPS0(hresps_n[0]), .HRDATAS0(hrdatas_n[0]),
        .HSELS1(hsels[1]),       .HADDRS1(haddrs[1]),       .HTRANSS1(htranss[1]),
        .HSIZES1(hsizes[1]),     .HWRITES1(hwrites[1]),     .HREADYS1(hreadys[1]),
        .HPROTS1(hprots[1]),     .HBURSTS1(hbursts[1]),     .HMASTLOCKS1(hmasterlocks[1]),
        .HWDATAS1(hwdatas[1]),
        .HREADYOUTS1(hreadyouts_n[1]), .HRESPS1(hresps_n[1]), .HRDATAS1(hrdatas_n[1]),
        .HSELS2(hsels[2]),       .HADDRS2(haddrs[2]),       .HTRANSS2(htranss[2]),
        .HSIZES2(hsizes[2]),     .HWRITES2(hwrites[2]),     .HREADYS2(hreadys[2]),
        .HPROTS2(hprots[2]),     .HBURSTS2(hbursts[2]),     .HMASTLOCKS2(hmasterlocks[2]),
        .HWDATAS2(hwdatas[2]),
        .HREADYOUTS2(hreadyouts_n[2]), .HRESPS2(hresps_n[2]), .HRDATAS2(hrdatas_n[2]),
        .HSELM(hselm_n),   .HADDRM(haddrm_n),   .HTRANSM(htransm_n),
        .HSIZEM(hsizem_n), .HWRITEM(hwrite_m_n), .HREADYM(hready_m_n),
        .HPROTM(hprotm_n), .HBURSTM(hburstm_n), .HMASTLOCKM(hmasterlock_m_n),
        .HWDATAM(hwdatam_n),
        .HREADYOUTM(hreadyoutm), .HRESPM(hrespom), .HRDATAM(hrdatamn),
        .HMASTERM(hmasterm_n)
    );

    initial hclk = 1'b0;
    always #5 hclk = ~hclk;

    ///////////////////////////////////////////////////////////////////////
    // shared randomized slave off the original's master port: random wait
    // states and two-cycle ERROR responses on announced transfers.
    ///////////////////////////////////////////////////////////////////////
    typedef enum logic [1:0] {SL_READY, SL_WAIT, SL_ERR1, SL_ERR2} sl_e;
    sl_e    sl_st;
    integer sl_wait_n;

    always @(posedge hclk) begin
        if (!hresetn) begin
            sl_st     <= SL_READY;
            sl_wait_n <= 0;
        end else begin
            unique case (sl_st)
                SL_READY: if (hselm_o && htransm_o[1]) begin
                    if      ($urandom_range(0, 99) < ERRPCT) sl_st <= SL_ERR1;
                    else if ($urandom_range(0, 99) < 40) begin
                        sl_wait_n <= $urandom_range(1, 3);
                        sl_st     <= SL_WAIT;
                    end
                end
                SL_WAIT:  if (sl_wait_n <= 1) sl_st <= SL_READY;
                          else                sl_wait_n <= sl_wait_n - 1;
                SL_ERR1:  sl_st <= SL_ERR2;
                SL_ERR2:  sl_st <= SL_READY;
            endcase
        end
    end

    assign hreadyoutm = (sl_st == SL_READY) || (sl_st == SL_ERR2);
    assign hrespom    = (sl_st == SL_ERR1)  || (sl_st == SL_ERR2);
    assign hrdatamn   = 32'hC0FFEE00 ^ {16'h0, haddrm_o[15:0]}
                      ^ {28'h0, hmasterm_o} ^ {8'h5A, 24'h0};

    ///////////////////////////////////////////////////////////////////////
    // scoreboard: every mux output, every cycle
    ///////////////////////////////////////////////////////////////////////
    integer cmp_cycles = 0;
    logic   fail = 1'b0;
    always @(negedge hclk) begin
        if (hresetn) begin
            if ((hselm_n !== hselm_o) || (haddrm_n !== haddrm_o) ||
                (htransm_n !== htransm_o) || (hsizem_n !== hsizem_o) ||
                (hwrite_m_n !== hwrite_m_o) || (hready_m_n !== hready_m_o) ||
                (hprotm_n !== hprotm_o) || (hburstm_n !== hburstm_o) ||
                (hmasterlock_m_n !== hmasterlock_m_o) ||
                (hwdatam_n !== hwdatam_o) || (hmasterm_n !== hmasterm_o) ||
                (hreadyouts_n[0] !== hreadyouts_o[0]) ||
                (hreadyouts_n[1] !== hreadyouts_o[1]) ||
                (hreadyouts_n[2] !== hreadyouts_o[2]) ||
                (hresps_n[0] !== hresps_o[0]) || (hresps_n[1] !== hresps_o[1]) ||
                (hresps_n[2] !== hresps_o[2]) ||
                (hrdatas_n[0] !== hrdatas_o[0]) || (hrdatas_n[1] !== hrdatas_o[1]) ||
                (hrdatas_n[2] !== hrdatas_o[2])) begin
                $display("MISMATCH t=%0t", $time);
                $display("  o: sel %b tr %b addr %08x sz %b wr %b rdym %b lock %b burst %b mst %b hwd %08x",
                         hselm_o, htransm_o, haddrm_o, hsizem_o, hwrite_m_o, hready_m_o,
                         hmasterlock_m_o, hburstm_o, hmasterm_o, hwdatam_o);
                $display("  n: sel %b tr %b addr %08x sz %b wr %b rdym %b lock %b burst %b mst %b hwd %08x",
                         hselm_n, htransm_n, haddrm_n, hsizem_n, hwrite_m_n, hready_m_n,
                         hmasterlock_m_n, hburstm_n, hmasterm_n, hwdatam_n);
                $display("  o: port rdy %b%b%b resp %b%b%b  n: port rdy %b%b%b resp %b%b%b",
                         hreadyouts_o[2], hreadyouts_o[1], hreadyouts_o[0],
                         hresps_o[2], hresps_o[1], hresps_o[0],
                         hreadyouts_n[2], hreadyouts_n[1], hreadyouts_n[0],
                         hresps_n[2], hresps_n[1], hresps_n[0]);
                fail = 1'b1;
                $fatal(1, "oss_ahb_master_mux diverged from cmsdk_ahb_master_mux");
            end
            cmp_cycles++;
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // masters. Each: idle gap, then a burst (NSEQ + SEQ beats) with random
    // burst type (INCR/INCR4/INCR8/fixed-4/fixed-8/undefined), random lock,
    // holding the phase unchanged until its own port ready high. After an
    // ERROR response the burst is abandoned to IDLE, the case the mux's
    // error-cancel stickiness exists for.
    ///////////////////////////////////////////////////////////////////////
    genvar gp;
    generate
        for (gp = 0; gp < 3; gp++) begin : g_mst
            initial begin : mst
                bit        sel, wr, lock, err_abort;
                bit [31:0] addr, wdata;
                bit [1:0]  trans;
                bit [2:0]  size, burst;
                bit [3:0]  prot;
                int        beats;
                int        idle_cnt;

                hsels[gp] = 1'b0; hmasterlocks[gp] = 1'b0;
                if (!P_EN[gp]) begin
                    htranss[gp] = 2'b00; haddrs[gp] = '0; hsizes[gp] = '0;
                    hwrites[gp] = 1'b0;  hbursts[gp] = '0; hprots[gp] = '0;
                    hwdatas[gp] = '0;
                end else begin
                    sel = 1'b1; trans = 2'b00; addr = '0; size = 3'b010;
                    wr = 1'b0; burst = 3'b000; prot = 4'b0011; wdata = '0;
                    lock = 1'b0; beats = 0; err_abort = 1'b0;

                    @(negedge hclk);
                    while (!hresetn) @(negedge hclk);

                    forever begin
                        bit rdy, valid;
                        @(negedge hclk);
                        rdy   = hreadys[gp];
                        valid = sel && trans[1];

                        // present the pending phase for this cycle
                        hsels[gp]         = sel;
                        htranss[gp]       = trans;
                        haddrs[gp]        = addr;
                        hsizes[gp]        = size;
                        hwrites[gp]       = wr;
                        hbursts[gp]       = burst;
                        hprots[gp]        = prot;
                        hmasterlocks[gp]  = lock && valid;
                        hwdatas[gp]       = wdata;

                        if (rdy && valid && hresps_o[gp]) err_abort = 1'b1;

                        if (rdy) begin
                            // pending phase sampled (or idle advanced); choose next
                            if (idle_cnt != 0) begin
                                // cmsdk masters drain a fixed-length burst
                                // after an error with IDLE beats: stay off
                                // the bus while the error-cancel window drains
                                idle_cnt = idle_cnt - 1;
                                trans  = 2'b00;
                                beats  = 0;
                            end else if (valid && beats > 1 && !err_abort) begin
                                beats  = beats - 1;
                                trans  = 2'b11;                       // SEQ
                                addr   = addr + (32'h1 << size);
                                wdata  = $urandom;
                            end else if (valid && (beats > 1) && err_abort) begin
                                beats = 1; err_abort = 1'b0; lock = 1'b0;
                                idle_cnt = 2;
                                trans = 2'b00;                        // abandon burst
                            end else if (valid && trans[1] && $urandom_range(0, 2) == 0) begin
                                trans = 2'b00; beats = 0; lock = 1'b0; // mid-burst idle
                            end else begin
                                // rest, then pick a fresh item
                                beats = 0; lock = 1'b0; err_abort = 1'b0;
                                if ($urandom_range(0, 3) == 0) begin
                                    trans = 2'b00;                    // idle beat
                                end else begin
                                    int bsel;
                                    trans  = 2'b10;                   // NSEQ
                                    bsel   = $urandom_range(0, 9);
                                    size   = 3'($urandom_range(0, HSIZE_HI));
                                    addr   = 32'($urandom & ~((32'h1 << (size + 1)) - 32'h1));
                                    if ($urandom_range(0, 15) == 0) addr = 32'($urandom); // unaligned
                                    wr     = $urandom_range(0, 1);
                                    wdata  = $urandom;
                                    prot   = 4'($urandom_range(0, 15));
                                    lock   = ($urandom_range(0, 9) == 0);
                                    case (bsel)
                                        9:      begin burst = 3'b000; beats = $urandom_range(2, 8); end
                                        8:      begin burst = 3'b001; beats = 4; end
                                        7:      begin burst = 3'b010; beats = 4; end
                                        6:      begin burst = 3'b011; beats = 8; end
                                        5:      begin burst = 3'b101; beats = 8; end
                                        default: begin burst = 3'b000; beats = $urandom_range(1, 4); end
                                    endcase
                                end
                            end
                        end
                        // rdy low: hold everything unchanged
                    end
                end
            end
        end
    endgenerate

    // the original's port ready is the bus ready seen by both DUTs' masters
    assign hreadys[0] = hreadyouts_o[0];
    assign hreadys[1] = hreadyouts_o[1];
    assign hreadys[2] = hreadyouts_o[2];

    ///////////////////////////////////////////////////////////////////////
    // finish
    ///////////////////////////////////////////////////////////////////////
    initial begin
        hresetn = 1'b0;
        repeat (8) @(negedge hclk);
        hresetn = 1'b1;
        repeat (CYCLES) @(negedge hclk);
        if (!fail)
            $display("PASS tb_ahb_master_mux_equiv P=%b%b%b DW=%0d (%0d compared cycles)",
                     P2, P1, P0, DW, cmp_cycles);
        $finish(0);
    end
endmodule
