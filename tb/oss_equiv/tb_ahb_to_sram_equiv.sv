// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// Cycle-accurate equivalence testbench between the closed Arm CMSDK
// cmsdk_ahb_to_sram and the open-source re-implementation oss_ahb_to_sram.
//
// Method: one constrained-random AHB master drives BOTH bridges from
// identical inputs. Each DUT owns a behavioral async-read/sync-write SRAM
// clocked from its own control outputs; every bridge output is compared
// every cycle and the two memory arrays are compared every cycle, so any
// divergence in control, data, byte lanes, or committed contents is a
// $fatal. Stimulus deliberately hammers the read-after-write merge window
// (read of the same word immediately after a write) and byte/half strobes.
//
// Parameters (override with -G):
//   AW     : AHB address width (pke instantiates 13, ahbsramc32 RAW+2=17)
//   CYCLES : test length in HCLK cycles

`timescale 1ns/1ps

module tb_ahb_to_sram_equiv #(
    parameter integer AW     = 13,
    parameter integer CYCLES = 200000
);
    localparam int WORDS = 1 << (AW - 2);

    logic hclk;
    logic hresetn;

    // shared AHB stimulus
    logic          hsel;
    logic [AW-1:0] haddr;
    logic [1:0]    htrans;
    logic [2:0]    hsize;
    logic          hwrite;
    logic [31:0]   hwdata;

    // DUT outputs
    logic          hreadyout_o, hresp_o, hreadyout_n, hresp_n;
    logic [31:0]   hrdata_o, hrdata_n;
    logic [AW-3:0] sramaddr_o, sramaddr_n;
    logic [3:0]    sramwen_o, sramwen_n;
    logic [31:0]   sramwdata_o, sramwdata_n;
    logic          sramcs_o, sramcs_n;

    // per-DUT SRAM read data
    logic [31:0]   sramrdata_o, sramrdata_n;

    cmsdk_ahb_to_sram #(.AW(AW)) u_orig (
        .HCLK(hclk), .HRESETn(hresetn), .HSEL(hsel), .HREADY(1'b1),
        .HTRANS(htrans), .HSIZE(hsize), .HWRITE(hwrite), .HADDR(haddr),
        .HWDATA(hwdata),
        .HREADYOUT(hreadyout_o), .HRESP(hresp_o), .HRDATA(hrdata_o),
        .SRAMRDATA(sramrdata_o), .SRAMADDR(sramaddr_o), .SRAMWEN(sramwen_o),
        .SRAMWDATA(sramwdata_o), .SRAMCS(sramcs_o)
    );

    oss_ahb_to_sram #(.AW(AW)) u_new (
        .HCLK(hclk), .HRESETn(hresetn), .HSEL(hsel), .HREADY(1'b1),
        .HTRANS(htrans), .HSIZE(hsize), .HWRITE(hwrite), .HADDR(haddr),
        .HWDATA(hwdata),
        .HREADYOUT(hreadyout_n), .HRESP(hresp_n), .HRDATA(hrdata_n),
        .SRAMRDATA(sramrdata_n), .SRAMADDR(sramaddr_n), .SRAMWEN(sramwen_n),
        .SRAMWDATA(sramwdata_n), .SRAMCS(sramcs_n)
    );

    initial hclk = 1'b0;
    always #5 hclk = ~hclk;

    ///////////////////////////////////////////////////////////////////////
    // behavioral SRAMs: async read, byte-lane synchronous write
    ///////////////////////////////////////////////////////////////////////
    logic [31:0] mem_o [WORDS];
    logic [31:0] mem_n [WORDS];

    assign sramrdata_o = mem_o[sramaddr_o];
    assign sramrdata_n = mem_n[sramaddr_n];

    always @(posedge hclk) if (hresetn) begin
        if (sramcs_o) begin
            if (sramwen_o[0]) mem_o[sramaddr_o][ 7: 0] <= sramwdata_o[ 7: 0];
            if (sramwen_o[1]) mem_o[sramaddr_o][15: 8] <= sramwdata_o[15: 8];
            if (sramwen_o[2]) mem_o[sramaddr_o][23:16] <= sramwdata_o[23:16];
            if (sramwen_o[3]) mem_o[sramaddr_o][31:24] <= sramwdata_o[31:24];
        end
        if (sramcs_n) begin
            if (sramwen_n[0]) mem_n[sramaddr_n][ 7: 0] <= sramwdata_n[ 7: 0];
            if (sramwen_n[1]) mem_n[sramaddr_n][15: 8] <= sramwdata_n[15: 8];
            if (sramwen_n[2]) mem_n[sramaddr_n][23:16] <= sramwdata_n[23:16];
            if (sramwen_n[3]) mem_n[sramaddr_n][31:24] <= sramwdata_n[31:24];
        end
    end

    // random memory init (same values both sides)
    initial for (int i = 0; i < WORDS; i++) begin
        mem_o[i] = $urandom;
        mem_n[i] = mem_o[i];
    end

    ///////////////////////////////////////////////////////////////////////
    // scoreboard: outputs every cycle, memory contents every cycle
    ///////////////////////////////////////////////////////////////////////
    integer cmp_cycles = 0;
    logic   fail = 1'b0;
    always @(negedge hclk) begin
        if (hresetn) begin
            if ((hreadyout_n !== hreadyout_o) || (hresp_n !== hresp_o) ||
                (hrdata_n !== hrdata_o) ||
                (sramaddr_n !== sramaddr_o) || (sramwen_n !== sramwen_o) ||
                (sramcs_n !== sramcs_o) ||
                ((sramcs_n | (sramwen_n != 0)) && (sramwdata_n !== sramwdata_o))) begin
                $display("MISMATCH t=%0t in{hsel %b addr %08x trans %b size %b wr %b wdata %08x}",
                         $time, hsel, haddr, htrans, hsize, hwrite, hwdata);
                $display("  o: rdy %b resp %b rdata %08x addr %0x wen %b wdata %08x cs %b",
                         hreadyout_o, hresp_o, hrdata_o, sramaddr_o, sramwen_o, sramwdata_o, sramcs_o);
                $display("  n: rdy %b resp %b rdata %08x addr %0x wen %b wdata %08x cs %b",
                         hreadyout_n, hresp_n, hrdata_n, sramaddr_n, sramwen_n, sramwdata_n, sramcs_n);
                fail = 1'b1;
                $fatal(1, "oss_ahb_to_sram diverged from cmsdk_ahb_to_sram");
            end
            for (int i = 0; i < WORDS; i++) begin
                if (mem_n[i] !== mem_o[i]) begin
                    $display("MEM MISMATCH t=%0t word %0d n=%08x o=%08x", $time, i, mem_n[i], mem_o[i]);
                    fail = 1'b1;
                    $fatal(1, "oss_ahb_to_sram memory diverged from cmsdk_ahb_to_sram");
                end
            end
            cmp_cycles++;
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // constrained-random AHB master. HREADY is tied 1, so every presented
    // address phase is consumed; writes alternate with reads aimed at the
    // just-written word (merge window), random words, and idles.
    ///////////////////////////////////////////////////////////////////////
    logic [AW-1:0] last_wr_addr;
    logic          have_last_wr;

    initial begin
        hresetn = 1'b0;
        hsel    = 1'b0;
        htrans  = 2'b00;
        haddr   = '0;
        hsize   = 3'b010;
        hwrite  = 1'b0;
        hwdata  = '0;
        last_wr_addr = '0;
        have_last_wr = 1'b0;
        repeat (5) @(negedge hclk);
        hresetn = 1'b1;

        forever begin
            int op;
            op = $urandom_range(0, 9);
            @(negedge hclk);
            case (op)
                0: begin // idle gap
                    hsel   = 1'b1;
                    htrans = 2'b00;
                end
                1, 2: begin // read of the just-written word (merge window)
                    if (have_last_wr) begin
                        hsel   = 1'b1;
                        htrans = 2'b10;
                        haddr  = last_wr_addr;
                        hsize  = 3'b010;
                        hwrite = 1'b0;
                    end else begin
                        hsel   = 1'b1;
                        htrans = 2'b00;
                    end
                end
                default: begin // random access, random size
                    hsel   = 1'b1;
                    htrans = ($urandom_range(0, 5) == 0) ? 2'b00 : 2'b10; // occasional BUSY/IDLE
                    hsize  = 3'($urandom_range(0, 2));
                    haddr  = AW'($urandom & ~((32'h1 << (hsize + 1)) - 32'h1));
                    if ($urandom_range(0, 9) == 0) haddr = AW'($urandom); // unaligned
                    hwrite = $urandom_range(0, 1);
                    if (hwrite) begin
                        hwdata       = $urandom;
                        last_wr_addr = {haddr[AW-1:2], 2'b00};
                        have_last_wr = 1'b1;
                    end
                end
            endcase
        end
    end

    ///////////////////////////////////////////////////////////////////////
    // finish
    ///////////////////////////////////////////////////////////////////////
    initial begin
        repeat (CYCLES) @(negedge hclk);
        if (!fail)
            $display("PASS tb_ahb_to_sram_equiv AW=%0d (%0d compared cycles)", AW, cmp_cycles);
        $finish(0);
    end
endmodule
