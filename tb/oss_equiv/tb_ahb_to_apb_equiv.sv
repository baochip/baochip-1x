// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// Cycle-accurate equivalence testbench between the closed Arm CMSDK
// cmsdk_ahb_to_apb and the open-source re-implementation oss_ahb_to_apb.
//
// Method: one constrained-random AHB master + APB peripheral model drives
// BOTH bridges from identical inputs (bus HREADY is wired to the original's
// HREADYOUT exactly like `apb_bdg` does, and the APB peripheral state machine
// is clocked off the original's APB-side outputs, which are themselves
// checked against the re-implementation every cycle). Every bridge output is
// compared every cycle; any divergence is a $fatal.
//
// Parameters (override with -G):
//   RDATA / WDATA : REGISTER_RDATA / REGISTER_WDATA instantiations
//   ADDRWIDTH     : APB address width (sce uses 15)
//   PCLKEN_MODE   : 0 = PCLKEN tied 1 (PCLK == HCLK)
//                   1 = PCLKEN HCLK/2 square enable
//                   2 = PCLKEN randomized

//   CYCLES        : test length in HCLK cycles

`timescale 1ns/1ps

module tb_ahb_to_apb_equiv #(
    parameter integer RDATA       = 1,
    parameter integer WDATA       = 0,
    parameter integer ADDRWIDTH   = 15,
    parameter integer PCLKEN_MODE = 0,
        parameter integer CYCLES      = 200000
);
    logic hclk;
    logic hresetn;

    // AHB slave-side stimulus (shared by both DUTs)
    logic                  hselen;
    logic [ADDRWIDTH-1:0]  haddr;
    logic [1:0]            htrans;
    logic [2:0]            hsize;
    logic [3:0]            hprot;
    logic                  hwrite;
    logic                  hready;      // bus ready = original HREADYOUT
    logic [31:0]           hwdata;
    logic [2:0]            hburst;      // not consumed, exercised anyway

    // original DUT
    logic                  hreadyout_o, hresp_o;
    logic [31:0]           hrdata_o;
    logic [ADDRWIDTH-1:0]  paddr_o;
    logic                  penable_o, pwrite_o, psel_o, apbactive_o;
    logic [3:0]            pstrb_o;
    logic [2:0]            pprot_o;
    logic [31:0]           pwdata_o;

    // re-implementation DUT
    logic                  hreadyout_n, hresp_n;
    logic [31:0]           hrdata_n;
    logic [ADDRWIDTH-1:0]  paddr_n;
    logic                  penable_n, pwrite_n, psel_n, apbactive_n;
    logic [3:0]            pstrb_n;
    logic [2:0]            pprot_n;
    logic [31:0]           pwdata_n;

    // shared APB peripheral response
    logic [31:0]           prdata;
    logic                  pready;
    logic                  pslverr;

    logic                  pclken;

    cmsdk_ahb_to_apb #(
        .ADDRWIDTH(ADDRWIDTH), .REGISTER_RDATA(RDATA), .REGISTER_WDATA(WDATA)
    ) u_orig (
        .HCLK(hclk), .HRESETn(hresetn), .PCLKEN(pclken),
        .HSEL(hselen), .HADDR(haddr), .HTRANS(htrans), .HSIZE(hsize),
        .HPROT(hprot), .HWRITE(hwrite), .HREADY(hready), .HWDATA(hwdata),
        .HREADYOUT(hreadyout_o), .HRDATA(hrdata_o), .HRESP(hresp_o),
        .PADDR(paddr_o), .PENABLE(penable_o), .PWRITE(pwrite_o),
        .PSTRB(pstrb_o), .PPROT(pprot_o), .PWDATA(pwdata_o), .PSEL(psel_o),
        .APBACTIVE(apbactive_o),
        .PRDATA(prdata), .PREADY(pready), .PSLVERR(pslverr)
    );

    oss_ahb_to_apb #(
        .ADDRWIDTH(ADDRWIDTH), .REGISTER_RDATA(RDATA), .REGISTER_WDATA(WDATA)
    ) u_new (
        .HCLK(hclk), .HRESETn(hresetn), .PCLKEN(pclken),
        .HSEL(hselen), .HADDR(haddr), .HTRANS(htrans), .HSIZE(hsize),
        .HPROT(hprot), .HWRITE(hwrite), .HREADY(hready), .HWDATA(hwdata),
        .HREADYOUT(hreadyout_n), .HRDATA(hrdata_n), .HRESP(hresp_n),
        .PADDR(paddr_n), .PENABLE(penable_n), .PWRITE(pwrite_n),
        .PSTRB(pstrb_n), .PPROT(pprot_n), .PWDATA(pwdata_n), .PSEL(psel_n),
        .APBACTIVE(apbactive_n),
        .PRDATA(prdata), .PREADY(pready), .PSLVERR(pslverr)
    );

    // like apb_bdg: bridge ready is the bus ready fed back to itself
    assign hready = hreadyout_o;

    initial hclk = 1'b0;
    always #5 hclk = ~hclk;

    ///////////////////////////////////////////////////////////////////////
    // PCLKEN: one shared source for both DUTs
    ///////////////////////////////////////////////////////////////////////
    integer pclken_cnt;
    logic   pclken_rand;
    initial pclken_cnt = 0;
    always @(posedge hclk) pclken_cnt <= pclken_cnt + 1;
    always @(negedge hclk) pclken_rand <= ($urandom_range(0, 3) != 0);
    always_comb begin
        unique case (PCLKEN_MODE)
            0:       pclken = 1'b1;
            1:       pclken = pclken_cnt[0];
            default: pclken = pclken_rand;
        endcase
    end

    ///////////////////////////////////////////////////////////////////////
    // scoreboard: every re-implementation output must equal the original's
    ///////////////////////////////////////////////////////////////////////
    integer cmp_cycles = 0;
    logic   fail = 1'b0;
    always @(negedge hclk) begin
        if (hresetn) begin
            if ((hreadyout_n !== hreadyout_o) || (hresp_n !== hresp_o) ||
                (hrdata_n !== hrdata_o) ||
                (paddr_n !== paddr_o) || (penable_n !== penable_o) ||
                (pwrite_n !== pwrite_o) || (pstrb_n !== pstrb_o) ||
                (pprot_n !== pprot_o) || (pwdata_n !== pwdata_o) ||
                (psel_n !== psel_o)   || (apbactive_n !== apbactive_o)) begin
                $display("MISMATCH t=%0t hreadyout n=%b o=%b hresp n=%b o=%b hrdata n=%08x o=%08x",
                         $time, hreadyout_n, hreadyout_o, hresp_n, hresp_o, hrdata_n, hrdata_o);
                $display("  apb n/o: paddr %08x %08x psel %b %b pen %b %b pwr %b %b pstrb %b %b pprot %b %b pwdata %08x %08x act %b %b",
                         paddr_n, paddr_o, psel_n, psel_o, penable_n, penable_o,
                         pwrite_n, pwrite_o, pstrb_n, pstrb_o, pprot_n, pprot_o,
                         pwdata_n, pwdata_o, apbactive_n, apbactive_o);
                fail = 1'b1;
                $fatal(1, "oss_ahb_to_apb diverged from cmsdk_ahb_to_apb");
            end
            cmp_cycles++;
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // APB peripheral model: random wait states, random PSLVERR.
    // Driven from the original's APB outputs; identical by comparison.
    ///////////////////////////////////////////////////////////////////////
    logic               ps_access;
    integer             ps_wait;
    logic               ps_err;
    logic [ADDRWIDTH-1:0] ps_addr;
    logic               ps_write;

    assign pready  = ps_access && (ps_wait == 0);
    assign pslverr = ps_access && (ps_wait == 0) && ps_err;
    assign prdata  = {17'h0, ~ps_addr} ^ {24'h0, ps_addr[7:0]} ^ {ps_write, 31'h0}
                   ^ ps_wait[31:0] ^ (ps_err ? 32'hDEAD_BEEF : 32'h0);

    always @(posedge hclk) begin
        if (!hresetn) begin
            ps_access <= 1'b0;
            ps_wait   <= 0;
            ps_err    <= 1'b0;
            ps_addr   <= '0;
            ps_write  <= 1'b0;
        end else if (pclken) begin
            if (!ps_access) begin
                if (psel_o && penable_o) begin
                    ps_access <= 1'b1;
                    ps_wait   <= $urandom_range(0, 3);
                    ps_err    <= ($urandom_range(0, 99) < 15);
                    ps_addr   <= paddr_o;
                    ps_write  <= pwrite_o;
                end
            end else if (psel_o && penable_o) begin
                if (ps_wait == 0) ps_access <= 1'b0;
                else              ps_wait   <= ps_wait - 1;
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // constrained-random AHB master
    // Phase pipeline: stimulus changes at negedge, DUTs sample at posedge.
    // A pending beat must be re-presented unchanged until a cycle whose
    // (settled) HREADY is 1 samples its valid address phase.
    ///////////////////////////////////////////////////////////////////////
    typedef struct {
        bit                 sel;
        bit [1:0]           trans;
        bit [ADDRWIDTH-1:0] addr;
        bit [2:0]           size;
        bit [2:0]           burst;
        bit [3:0]           prot;
        bit                 write;
        bit [31:0]          wdata;
    } phase_t;

    phase_t pend;

    initial begin
        hresetn = 1'b0;
        hselen  = 1'b1;
        htrans  = 2'b00;
        haddr   = '0;
        hsize   = 3'b010;
        hburst  = 3'b000;
        hprot   = '0;
        hwrite  = 1'b0;
        hwdata  = '0;
        repeat (5) @(negedge hclk);
        hresetn = 1'b1;
        repeat (2) @(negedge hclk);

        forever begin
            int len;
            // pick the next thing to present
            case ($urandom_range(0, 9))
                0, 1: begin // idle gap
                    pend.sel   = 1'b1;
                    pend.trans = 2'b00;
                end
                default: begin // burst of 1..4 beats
                    len = 1 + $urandom_range(0, 3);
                    pend.sel   = 1'b1;
                    pend.trans = 2'b10;              // NSEQ first beat
                    break;
                end
            endcase
            // random fields for every non-idle beat; idle beats get fresh
            // junk too (bridge must ignore them)
            pend.size  = 3'($urandom_range(0, 2));
            pend.burst = 3'($urandom_range(0, 7));
            pend.prot  = 4'($urandom_range(0, 15));
            pend.write = $urandom_range(0, 1);
            pend.addr  = ADDRWIDTH'($urandom & ~((32'h1 << (pend.size + 1)) - 32'h1));
            if ($urandom_range(0, 7) == 0) pend.addr = ADDRWIDTH'($urandom); // unaligned
            pend.wdata = $urandom;

            // present pend until consumed; then continue burst or return to idle
            forever begin
                bit rdy;
                bit consumed;
                @(negedge hclk);
                rdy = hready;                    // settled HREADY of this cycle
                // drive it
                hselen = pend.sel;
                htrans = pend.trans;
                haddr  = pend.addr;
                hsize  = pend.size;
                hburst = pend.burst;
                hprot  = pend.prot;
                hwrite = pend.write;
                hwdata = pend.wdata;
                consumed = rdy && pend.sel && pend.trans[1];
                if (consumed) begin
                    if (pend.trans == 2'b10) begin
                        if (len > 1) begin       // continue burst
                            len = len - 1;
                            pend.trans = 2'b11;  // SEQ
                            pend.size  = 3'($urandom_range(0, 2));
                            pend.addr  = ADDRWIDTH'($urandom & ~((32'h1 << (pend.size + 1)) - 32'h1));
                            pend.write = $urandom_range(0, 1);
                            pend.wdata = $urandom;
                        end else begin
                            break;               // burst done -> pick new item
                        end
                    end else begin
                        break;                   // idle or single done
                    end
                end
                // else: hold pend unchanged (retry)
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // finish
    ///////////////////////////////////////////////////////////////////////
    initial begin
        repeat (CYCLES) @(negedge hclk);
        if (!fail)
            $display("PASS tb_ahb_to_apb_equiv RDATA=%0d WDATA=%0d AW=%0d PCLKEN_MODE=%0d (%0d compared cycles)",
                     RDATA, WDATA, ADDRWIDTH, PCLKEN_MODE, cmp_cycles);
        $finish(0);
    end
endmodule
