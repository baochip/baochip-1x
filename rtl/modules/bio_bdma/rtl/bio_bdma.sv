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

`ifdef XVLOG // required for compatibility with xsim
`include "template_v0.1.sv"
`include "apb_sfr_v0.1.sv"
`endif

// `define FPGA 1

// When this is defined, instructions take an extra cycle
// to execute, but the critical path is shorter.
//   - Impact is significant on IPC, let's start with it off
`define REGISTER_RAM
// Add pipeline stage to AXI read to CPU
//   - The impact of this is minimal on IPC but significant on timing closure
//     so let's start with it enabled
`define PIPELINE_AXI_RD
// Add pipeline stage to AXI write coming from CPU
// `define PIPELINE_AXI_WR // no need to use this; little impact on critical path
// Add a multiplier to the RV32 core
`define ENABLE_MUL // minor impact on critical path & area for significant potential gain in function

// Methodology: run "stack test"
//   - Measure execution time on Core 3
//   - dbg_ascii_instr trace
//   - *not* including the initial wait on first data ("add" instruction holding)
//   - Drop named cursor on front and back, then read out times.
// Methodology: run "aclk test"
//   - Record aclk numbers
// Methodology: run "DMA basic"
//   - Record time from first ack_arvalid rising edge to last ack_arvalid falling edge (ack_arvalid is inside the block)
//   - Use named cursors
//   - Main to main test

// Timing-closure optimized configuration:
//   - REGISTER_RAM + PIPELINE_AXI_RD enabled
//   - ENABLE_MUL also enabled because why not
// Critical path is from mem_valid -> AXI-lite valid/ready -> PCP_MUL -> execute -> mem_rdata
//   - Mostly net delay, minimal logic - so see how ASIC turns out. -1.2ns slack @ 100MHz
// Stack test result:
//   - 103556250 ps - 89472500 ps = 14083750 ps
// ACLK test result:
//   - 29, 32, 36, 43, 46, [54, 64] (last two are snapped to quantum)
// DMA basic m->m result:
//   - 155848750 ps - 149916250 ps = 5932500 ps

// IPC-optimized configuration:
//   - ENABLE_MUL enabled
// Critical path is from mem_wrstb -> mem_ready -> crossbar -> merged_mem_ready -> execute -> dma_owner
//   - About 3x the logic of fully optimized configuration (-4.3ns slack @ 100MHz)
// Stack test result:
//   - 100783750 ps - 89393750 ps = 11390000 ps -> 1.2365x less cycles than REGISTER_RAM
// ACLK test result:
//   - 28, 31, 34, 40, 43, [54, 64] (last two are snapped to quantum)
// DMA basic m->m result:
//   - 153063750 ps - 147841250 ps = 5222500 ps -> 1.13x less cycles than REGISTER_RAM

// Middle config:
//   - PIPELINE_AXI_RD enabled
//   - ENABLE_MUL enabled
// Critical path is from clear_prefetched_high_word -> PCP_MUL -> execute -> la_addr -> dma_owner -> dma_active
//   - About 1.5x the logic of fully-optimized config (-1.6ns slack @ 100MHz)
// Stack test result:
//   - 100783750 ps - 89393750 ps = 11390000 ps -> 1.2365x less cycles than REGISTER_RAM
// ACLK test result:
//   - 28, 31, 34, 40, 43, [54, 64] (last two are snapped to quantum)
// DMA basic m->m result:
//   - 153222500 ps - 147841250 ps = 5381250 ps -> 1.10x less cycles than REGISTER_RAM; 1.03x longer than IPC-optimezed

// Conclusion: if cycle time is improved by more than 30% with REGISTER_RAM + PIPELINE_AXI_RD,
// then we should turn on these options. Question is - are we limited by the VexRV core already?
// If so, then, might as well go with better IPC in favor of faster cycle time.

// This is required to pass a lint that occurs in Synopsys DC2022+
typedef struct packed {
  logic [31:0]    aw_addr;
  axi_pkg::prot_t aw_prot;
  logic           aw_valid;
  logic           aw_ready;

  logic [31:0]    w_data;
  logic [3:0]     w_strb;
  logic           w_valid;
  logic           w_ready;

  axi_pkg::resp_t b_resp;
  logic           b_valid;
  logic           b_ready;

  logic [31:0]    ar_addr;
  axi_pkg::prot_t ar_prot;
  logic           ar_valid;
  logic           ar_ready;

  logic [31:0]    r_data;
  axi_pkg::resp_t r_resp;
  logic           r_valid;
  logic           r_ready;
} bio_axi_lite_t;

module bio_bdma #(
    parameter APW = 12,  // APB address width
    // 0x8000 is offset of the BIO config space
    // 0x9000-0xD000 is offset of RAM
    parameter DW = 32,
    parameter CHNLC = 8,
    parameter EVC = 192,
    parameter AHBMID4 = daric_cfg::AMBAID4_MDMA
)
(
    input logic         aclk,
    input logic         pclk, // APB clock
    input logic         hclk, // AXI clock
    input logic         dmaclk, // AHB clock
    input logic         reset_n,
    input logic         cmatpg, cmbist,
    input logic [2:0]   sramtrm,
    rbif.slave          rbif_bioram1kx32[0:3],

    ioif.drive          bio_gpio[0:31],
    // interrupt sources originating from BIO
    output logic  [3:0] irq,

    // dma request input - every event in the system coming in on an hclk-aligned edge
    // In order to be more logic-efficient, the bottom 16 events, which are accessible
    // only to the CM7, are not routed into this core. Thus any event number in the system
    // maps to a BIO-BDMA event by subtracting 16 from the event number.
    input logic [EVC-1:0] dmareq,

    apbif.slavein       apbs,
    apbif.slave         apbx,

    // memory pages for instruction memory, one per core
    apbif.slavein       apbs_imem[0:3],
    apbif.slave         apbx_imem[0:3],

    // page-mapped FIFO ins/outs/status for easy OS integration
    apbif.slavein       apbs_fifo[0:3],
    apbif.slave         apbx_fifo[0:3],

    // above 0x6000_0000 (inclusive) go to this AXI interface on HCLK. The matrix is AXI-native.
    axiif.master        axim,
    // below 0x6000_0000 go to this AHB interface on HCLK. The matrix is AHB-native.
	ahbif.master        ahbm
);
    localparam NUM_MACH = 4;
    localparam MEM_SIZE_BYTES = 32'h1000;
    localparam MEM_SIZE_WORDS = 32'h1000 / 4;
    // bits to address the RAM macro
    localparam MEM_ADDR_BITS = $clog2(MEM_SIZE_WORDS);
    localparam PC_SIZE_BITS = $clog2(MEM_SIZE_BYTES);
    // number of address filter banks
    localparam FILTER_RANGES = 4;

    /////////////////////// module glue
    logic reset;
    logic resetn;

    /////////////////////// GPIO hookup
    logic [31:0] gpio_in;
    logic [31:0] gpio_out;
    logic [31:0] gpio_dir;
    logic [31:0] oe_invert;
    logic [31:0] out_invert;
    logic [31:0] in_invert;
    logic [31:0] gpio_in_cleaned;
    logic [31:0] gpio_in_snapped;
    logic [31:0] gpio_in_maybe_snapped;
    logic [31:0] gpio_in_sync0;
    logic [31:0] gpio_in_sync1;
    logic [31:0] irqmask0;
    logic [31:0] irqmask1;
    logic [31:0] irqmask2;
    logic [31:0] irqmask3;
    logic [3:0] irq_agg;
    logic [3:0] irq_agg_q;
    logic [3:0] irq_edge;
    logic [31:0] sync_bypass;
    logic snap_output_to_quantum;
    logic [1:0] snap_output_to_which;
    logic snap_input_to_quantum;
    logic [1:0] snap_input_to_which;
    logic [31:0] gpio_out_aclk;
    logic [31:0] gpio_dir_aclk;

    /////////////////////// clocking mode for AXIL CDC
    // 00: asynchronous (two stage synchronizer)
    // 01 or 10: mechronous (one stage synchronizer)
    // 11: isochronous (edge synced but different frequency - no synchronizer)
    // used to tune memory access latency versus actual timing on final chip
    logic [1:0] clocking_mode;

    /////////////////////// machine hookup
    logic [15:0]  div_int      [NUM_MACH];
    logic [7:0]   div_frac     [NUM_MACH];
    logic [7:0]  unused_div    [NUM_MACH];
    logic [NUM_MACH-1:0]       clkdiv_restart;
    logic [NUM_MACH-1:0]       restart;
    logic [NUM_MACH-1:0]       a_restart;
    logic [NUM_MACH-1:0]       a_restart_q[2];
    logic [NUM_MACH-1:0]       penable;
    logic [NUM_MACH-1:0]       core_ena;
    logic [3:0]                use_extclk; // FIXME: for some reason, NUM_MACH-1 syntax doesn't extract automatically in SVD extractor...
    logic [NUM_MACH-1:0]       use_extclk_aclk;
    logic [4:0]                extclk_gpio_0;
    logic [4:0]                extclk_gpio_1;
    logic [4:0]                extclk_gpio_2;
    logic [4:0]                extclk_gpio_3;
    logic [4:0]                extclk_gpio_aclk[NUM_MACH];
    logic [3:0]                extclk_selected;
    logic [3:0]                extclk_selected_q;
    logic [3:0]                quantum;

    logic [NUM_MACH-1:0]       core_clk;
    logic [NUM_MACH-1:0]       stall;
    logic [NUM_MACH-1:0]       trap;
    logic [PC_SIZE_BITS-1:0]   dbg_pc[NUM_MACH];

    // Memory interfaces
	logic [NUM_MACH-1:0]       mem_valid;
	logic [NUM_MACH-1:0]       mem_instr;
	logic [NUM_MACH-1:0]       mem_ready;

	logic [31:0] mem_addr     [NUM_MACH];
	logic [31:0] mem_wdata    [NUM_MACH];
	logic [ 3:0] mem_wstrb    [NUM_MACH];
	logic [31:0] mem_rdata    [NUM_MACH];

	// Look-Ahead Interface
	logic [NUM_MACH-1:0]      mem_la_read;
	logic [NUM_MACH-1:0]      mem_la_write;
	logic [31:0] mem_la_addr  [NUM_MACH];
	logic [31:0] mem_la_wdata [NUM_MACH];
	logic [ 3:0] mem_la_wstrb [NUM_MACH];

    // Tie-offs
	logic [NUM_MACH-1:0] pcpi_valid;
	logic [31:0] pcpi_insn  [NUM_MACH];
	logic [31:0] pcpi_rs1  [NUM_MACH];
	logic [31:0] pcpi_rs2  [NUM_MACH];
	logic [31:0] eoi  [NUM_MACH];
	logic [NUM_MACH-1:0] trace_valid;
	logic [35:0] trace_data [NUM_MACH];

    // Optional pipelining
`ifdef PIPELINE_AXI_WR
    logic [ 3:0] mem_wstrb_pipe [NUM_MACH];
	logic [NUM_MACH-1:0]       mem_valid_pipe;
    logic dma_active_pipe;
    logic dma_ready_d;
    logic [1:0] dma_owner_d;
`endif

    // Support logic for non-lookahead RAM
`ifdef REGISTER_RAM
    reg [NUM_MACH-1:0] mem_valid_d;
    reg [NUM_MACH-1:0] dead_cycle;
`endif

    // lint fixes
    logic [1:0] core_id_from_loop [NUM_MACH];

    // In theory, we could do some overlapping write-over-read with AHB and multiple cores
    // owning different read//write ops, but I think it's not worth the complexity
    // DMA signals in aclk domain
    logic [NUM_MACH-1:0] ext_addr;
    logic [NUM_MACH-1:0] ext_addr_la;
    logic [NUM_MACH-1:0] merged_mem_ready;
	logic [31:0] merged_mem_rdata  [NUM_MACH];
    logic [NUM_MACH-1:0] core_dma_ready;
    logic [1:0] dma_owner;
    logic dma_active;
    logic dma_ready;
    logic [31:0] dma_rdata;
    logic [31:0] dma_addr;
    logic [31:0] dma_wdata;
    logic dma_write;
    logic [0:0] dma_state_aclk [2];
    logic [3:0] dma_wstrb;
    logic [2:0] dma_size;
    logic [1:0] dma_htrans;
    // align with the dma_owner signal, which takes a cycle to resolve
	logic [NUM_MACH-1:0]      mem_la_read_reg;
	logic [NUM_MACH-1:0]      mem_la_write_reg;

    // bodge for AHB size decoding: this relies on a spec-non-compliance of
    // the actual IFRAM core, which gates byte writes with HSIZE
    logic [2:0] ahb_size_bodge;
    logic [31:0] axi_aw_bodge;

    // core AXI-lite endpoints
    bio_axi_lite_t core_axil;

    // memory demux endpoints
    bio_axi_lite_t mem_axil;

    // peripheral demux endpoints
    bio_axi_lite_t peri_axil;

    // memory filter endpoints
    bio_axi_lite_t mem_filtered_axil;

    // peripheral filter endpoints
    bio_axi_lite_t peri_filtered_axil;

    // peripheral clock domain crossing endpoints
    bio_axi_lite_t peri_cdc_axil;

    // address range filter wires
    logic disable_filter_mem;
    logic disable_filter_peri;
    logic [19:0] filter_base[FILTER_RANGES];
    logic [19:0] filter_bounds[FILTER_RANGES];
    logic [31:0] mem_gutter;
    logic [31:0] peri_gutter;

    // high register interfaces
    logic [31:0] mach_regfifo_rdata [NUM_MACH];
    logic [3:0] mach_regfifo_rd [NUM_MACH];
    logic [31:0] mach_regfifo_wdata [NUM_MACH];
    logic [3:0] mach_regfifo_wr [NUM_MACH];

    logic [NUM_MACH-1:0] quanta_halt;

    logic [31:0] gpio_set  [NUM_MACH];
    logic [31:0] gpio_clr  [NUM_MACH];
    logic [31:0] gpdir_set [NUM_MACH];
    logic [31:0] gpdir_clr [NUM_MACH];
    logic [NUM_MACH-1:0] gpio_set_valid;
    logic [NUM_MACH-1:0] gpio_clr_valid;
    logic [NUM_MACH-1:0] gpdir_set_valid;
    logic [NUM_MACH-1:0] gpdir_clr_valid;

    logic [23:0] event_set [NUM_MACH];
    logic [NUM_MACH-1:0] event_set_valid;
    logic [23:0] event_clr [NUM_MACH];
    logic [NUM_MACH-1:0] event_clr_valid;
    logic [31:0] aggregated_events;
    logic [31:0] pclk_event_status;
    logic [NUM_MACH-1:0] stalling_for_event;
    logic [23:0] host_event_set;
    logic host_event_set_valid;
    logic [23:0] host_event_set_p; // retime to relax critical path
    logic host_event_set_valid_p;
    logic [23:0] host_event_clr;
    logic host_event_clr_valid;
    logic [23:0] host_event_clr_p; // retime to relax critical path
    logic host_event_clr_valid_p;
    logic [23:0] host_event_set_alias [NUM_MACH];
    logic host_event_set_valid_alias [NUM_MACH];
    logic [23:0] host_event_clr_alias [NUM_MACH];
    logic host_event_clr_valid_alias [NUM_MACH];
    // dma events
    logic [23:0] dma_event_set;
    logic dma_event_set_valid;

    logic [29:0] core_clk_count [NUM_MACH];

    // modes
    logic [NUM_MACH-1:0]   en;
    logic [NUM_MACH-1:0]   en_sync; // enable has to be synchronized to the ar bit so it hits when clkdivreset, restart hits
    logic [NUM_MACH-1:0]   imem_wr_mode;

    /////////////////////// fifo hookup
    // the signals of the FIFO itself. Note, 4 FIFO regs, 4 machines is just a coincidence. The two
    // are not necessarily the same (machine count is parameterized, FIFO regs is *always* 4).
    logic [31:0]  regfifo_wdata [4];
    logic         regfifo_we [4];
    logic         regfifo_writable[4];
    logic [31:0]  regfifo_rdata [4];
    logic         regfifo_re [4];
    logic         regfifo_readable[4];
    logic [3:0]   regfifo_level [4];

    logic [3:0] fifo_event_level[8];
    logic [3:0] host_fifo_event_level[8];
    logic [7:0] host_fifo_event_eq_mask;
    logic [7:0] host_fifo_event_lt_mask;
    logic [7:0] host_fifo_event_gt_mask;
    logic [7:0] fifo_event_eq_mask;
    logic [7:0] fifo_event_lt_mask;
    logic [7:0] fifo_event_gt_mask;

    logic [31:0] fdin       [NUM_MACH];
    logic [31:0] fdin_sync  [NUM_MACH];
    logic [31:0] fdin_alias [NUM_MACH];
    logic [31:0] fdin_alias_sync [NUM_MACH];
    logic [31:0] fdout      [NUM_MACH];
    logic [3:0] push;
    logic [3:0] pull;
    logic [3:0] push_alias;
    logic [3:0] pull_alias;
    logic [3:0] fifo_to_reset;
    logic do_fifo_clr;

    /////////////////////// register bank
    // nc fields
    wire ctl_action_sync_ack;
    // synchronizers for .ar pulses
    logic ctl_action_sync;
    logic [3:0] push_sync;
    logic [3:0] pull_sync;
    logic [3:0] push_alias_sync;
    logic [3:0] pull_alias_sync;
    logic [23:0] pclk_event_set;
    logic pclk_event_set_valid;
    logic [23:0] pclk_event_set_alias [NUM_MACH];
    logic [NUM_MACH-1:0] pclk_event_set_valid_alias;
    logic [23:0] pclk_event_clr;
    logic pclk_event_clr_valid;
    logic [23:0] pclk_event_clr_alias [NUM_MACH];
    logic [NUM_MACH-1:0] pclk_event_clr_valid_alias;
    logic ctl_action;
    logic [3:0] fifo_to_reset_aclk;
    logic do_fifo_clr_aclk;
    logic [3:0]  pclk_regfifo_level [4];
    always_ff @(posedge pclk) begin
        pclk_regfifo_level <= regfifo_level;
        fdout <= regfifo_rdata;
        pclk_event_status <= aggregated_events;
    end
    always_ff @(posedge aclk) begin
        fdin_sync <= fdin;
        fdin_alias_sync <= fdin_alias;
        host_fifo_event_level <= fifo_event_level;
        host_fifo_event_eq_mask <= fifo_event_eq_mask;
        host_fifo_event_lt_mask <= fifo_event_lt_mask;
        host_fifo_event_gt_mask <= fifo_event_gt_mask;
        host_event_set <= pclk_event_set;
        host_event_clr <= pclk_event_clr;
        host_event_set_alias <= pclk_event_set_alias;
        host_event_clr_alias <= pclk_event_clr_alias;
        a_restart_q[0] <= restart;
        a_restart_q[1] <= a_restart_q[0];
        a_restart <= a_restart_q[1];
        extclk_gpio_aclk[0] <= extclk_gpio_0;
        extclk_gpio_aclk[1] <= extclk_gpio_1;
        extclk_gpio_aclk[2] <= extclk_gpio_2;
        extclk_gpio_aclk[3] <= extclk_gpio_3;
        use_extclk_aclk <= use_extclk;
        fifo_to_reset_aclk <= fifo_to_reset;
    end
    // SFR bank
    logic apbrd, apbwr, sfrlock;
    assign sfrlock = '0;
    `apbs_common;
    assign  apbx.prdata = '0 |
            sfr_ctrl         .prdata32 |
            sfr_config       .prdata32 |
            sfr_cfginfo      .prdata32 |
            sfr_flevel       .prdata32 |
            sfr_txf0         .prdata32 |
            sfr_txf1         .prdata32 |
            sfr_txf2         .prdata32 |
            sfr_txf3         .prdata32 |
            sfr_rxf0         .prdata32 |
            sfr_rxf1         .prdata32 |
            sfr_rxf2         .prdata32 |
            sfr_rxf3         .prdata32 |
            sfr_elevel       .prdata32 |
            sfr_etype        .prdata32 |
            sfr_event_set    .prdata32 |
            sfr_event_clr    .prdata32 |
            sfr_event_status .prdata32 |
            sfr_extclock     .prdata32 |
            sfr_fifo_clr     .prdata32 |
            sfr_qdiv0        .prdata32 |
            sfr_qdiv1        .prdata32 |
            sfr_qdiv2        .prdata32 |
            sfr_qdiv3        .prdata32 |
            sfr_sync_bypass  .prdata32 |
            sfr_io_oe_inv    .prdata32 |
            sfr_io_o_inv     .prdata32 |
            sfr_io_i_inv     .prdata32 |
            sfr_irqmask_0    .prdata32 |
            sfr_irqmask_1    .prdata32 |
            sfr_irqmask_2    .prdata32 |
            sfr_irqmask_3    .prdata32 |
            sfr_irq_edge     .prdata32 |
            sfr_dbg0         .prdata32 |
            sfr_dbg1         .prdata32 |
            sfr_dbg2         .prdata32 |
            sfr_dbg3         .prdata32 |
            sfr_dmareq_map   .prdata32 |
            sfr_dmareq_stat  .prdata32
            ;

    apb_ac2r #(.A('h00), .DW(12))    sfr_ctrl             (.cr({clkdiv_restart, restart, en}), .ar(ctl_action), .self_clear(ctl_action_sync_ack), .prdata32(),.*);
    apb_sr  #(.A('h04), .DW(32))     sfr_cfginfo          (.sr({16'd4096, 8'd4, 8'd8}), .prdata32(),.*);
    apb_cr  #(.A('h08), .DW(10))     sfr_config           (.cr({
                                                            clocking_mode,
                                                            disable_filter_mem, disable_filter_peri,
                                                            snap_input_to_quantum, snap_input_to_which,
                                                            snap_output_to_quantum, snap_output_to_which}), .prdata32(),.*);

    apb_sr  #(.A('h0C), .DW(16))     sfr_flevel           (.sr({
                                                            pclk_regfifo_level[3], pclk_regfifo_level[2],
                                                            pclk_regfifo_level[1], pclk_regfifo_level[0]}), .prdata32(),.*);
    apb_acr #(.A('h10), .DW(32))     sfr_txf0             (.cr(fdin[0]), .ar(push[0]), .prdata32(),.*);
    apb_acr #(.A('h14), .DW(32))     sfr_txf1             (.cr(fdin[1]), .ar(push[1]), .prdata32(),.*);
    apb_acr #(.A('h18), .DW(32))     sfr_txf2             (.cr(fdin[2]), .ar(push[2]), .prdata32(),.*);
    apb_acr #(.A('h1C), .DW(32))     sfr_txf3             (.cr(fdin[3]), .ar(push[3]), .prdata32(),.*);
    apb_asr #(.A('h20), .DW(32))     sfr_rxf0             (.sr(fdout[0]), .ar(pull[0]), .prdata32(),.*);
    apb_asr #(.A('h24), .DW(32))     sfr_rxf1             (.sr(fdout[1]), .ar(pull[1]), .prdata32(),.*);
    apb_asr #(.A('h28), .DW(32))     sfr_rxf2             (.sr(fdout[2]), .ar(pull[2]), .prdata32(),.*);
    apb_asr #(.A('h2C), .DW(32))     sfr_rxf3             (.sr(fdout[3]), .ar(pull[3]), .prdata32(),.*);

    apb_cr  #(.A('h30), .DW(32))     sfr_elevel           (.cr({
                                                            fifo_event_level[7], fifo_event_level[6],
                                                            fifo_event_level[5], fifo_event_level[4],
                                                            fifo_event_level[3], fifo_event_level[2],
                                                            fifo_event_level[1], fifo_event_level[0]}), .prdata32(),.*);
    apb_cr  #(.A('h34), .DW(24))     sfr_etype            (.cr({
                                                            fifo_event_gt_mask, fifo_event_eq_mask,
                                                            fifo_event_lt_mask}), .prdata32(),.*);
    apb_acr #(.A('h38), .DW(24))     sfr_event_set        (.cr(pclk_event_set), .ar(pclk_event_set_valid), .prdata32(),.*);
    apb_acr #(.A('h3C), .DW(24))     sfr_event_clr        (.cr(pclk_event_clr), .ar(pclk_event_clr_valid), .prdata32(),.*);
    apb_sr  #(.A('h40), .DW(32))     sfr_event_status     (.sr(pclk_event_status), .prdata32(), .*);

    apb_cr  #(.A('h44), .DW(24))     sfr_extclock         (.cr({extclk_gpio_3, extclk_gpio_2,
                                                            extclk_gpio_1, extclk_gpio_0, use_extclk}), .prdata32(),.*);
    apb_acr  #(.A('h48), .DW(4))     sfr_fifo_clr         (.cr(fifo_to_reset), .ar(do_fifo_clr), .prdata32(), .*);

    apb_cr #(.A('h50), .DW(32))      sfr_qdiv0            (.cr({div_int[0], div_frac[0], unused_div[0]}), .prdata32(),.*);
    apb_cr #(.A('h54), .DW(32))      sfr_qdiv1            (.cr({div_int[1], div_frac[1], unused_div[1]}), .prdata32(),.*);
    apb_cr #(.A('h58), .DW(32))      sfr_qdiv2            (.cr({div_int[2], div_frac[2], unused_div[2]}), .prdata32(),.*);
    apb_cr #(.A('h5C), .DW(32))      sfr_qdiv3            (.cr({div_int[3], div_frac[3], unused_div[3]}), .prdata32(),.*);

    apb_cr #(.A('h60), .DW(32))      sfr_sync_bypass      (.cr(sync_bypass), .prdata32(),.*);
    apb_cr #(.A('h64), .DW(32))      sfr_io_oe_inv        (.cr(oe_invert), .prdata32(),.*);
    apb_cr #(.A('h68), .DW(32))      sfr_io_o_inv         (.cr(out_invert), .prdata32(),.*);
    apb_cr #(.A('h6C), .DW(32))      sfr_io_i_inv         (.cr(in_invert), .prdata32(),.*);

    apb_cr #(.A('h70), .DW(32))      sfr_irqmask_0        (.cr(irqmask0), .prdata32(),.*);
    apb_cr #(.A('h74), .DW(32))      sfr_irqmask_1        (.cr(irqmask1), .prdata32(),.*);
    apb_cr #(.A('h78), .DW(32))      sfr_irqmask_2        (.cr(irqmask2), .prdata32(),.*);
    apb_cr #(.A('h7C), .DW(32))      sfr_irqmask_3        (.cr(irqmask3), .prdata32(),.*);
    apb_cr #(.A('h80), .DW(4))       sfr_irq_edge         (.cr(irq_edge), .prdata32(),.*);
    apb_sr #(.A('h84), .DW(32))      sfr_dbg_padout       (.sr(gpio_out), .prdata32(),.*);
    apb_sr #(.A('h88), .DW(32))      sfr_dbg_padoe        (.sr(gpio_dir), .prdata32(),.*);

    apb_sr #(.A('h90), .DW(13))      sfr_dbg0             (.sr({trap[0], dbg_pc[0]}), .prdata32(),.*);
    apb_sr #(.A('h94), .DW(13))      sfr_dbg1             (.sr({trap[1], dbg_pc[1]}), .prdata32(),.*);
    apb_sr #(.A('h98), .DW(13))      sfr_dbg2             (.sr({trap[2], dbg_pc[2]}), .prdata32(),.*);
    apb_sr #(.A('h9C), .DW(13))      sfr_dbg3             (.sr({trap[3], dbg_pc[3]}), .prdata32(),.*);

    // this is part of address filtering, but stuck here because we're running out of bits
    apb_cr #(.A('hA0), .DW(32))      sfr_mem_gutter           (.cr(mem_gutter), .prdata32(),.*);
    apb_cr #(.A('hA4), .DW(32))      sfr_peri_gutter          (.cr(peri_gutter), .prdata32(),.*);

    cdc_level_to_pulse   ctl_action_cdc     (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(ctl_action            ), .out_b(ctl_action_sync            ));
    cdc_blinded          ctl_action_ack_cdc (.reset(reset), .clk_a(aclk), .clk_b     (pclk), .in_a(ctl_action_sync       ), .out_b(ctl_action_sync_ack        ));
    cdc_level_to_pulse   push_cdc[3:0]      (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(push                  ), .out_b(push_sync                  ));
    cdc_level_to_pulse   pull_cdc[3:0]      (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(pull                  ), .out_b(pull_sync                  ));
    cdc_level_to_pulse   event_set_cdc      (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(pclk_event_set_valid  ), .out_b(host_event_set_valid       ));
    cdc_level_to_pulse   event_clr_cdc      (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(pclk_event_clr_valid  ), .out_b(host_event_clr_valid       ));
    cdc_level_to_pulse   fifo_clr_cdc       (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(do_fifo_clr           ), .out_b(do_fifo_clr_aclk           ));

    /////////////////////// dma request
    // The DMA request interface maps one of up to 192 sources to one of the 24 event bits.
    //
    // When an event comes in, it will set the event bit. A core can halt and wait on the event
    // by setting x27 to mask for the event bit, and then accessing x30.
    //
    // The 192 sources are masked with a control register, and then muxed 8:1 down to each event bit.
    // The mask is configured by a bank of 6x 32-bit registers.
    //
    // If the event goes high, it will set the event bit. The event bit setting is only level sensitive:
    // the responding core is repsonible for clearing the event generating condition before waiting
    // on the event register again (it can do this because it has access to the peripheral bus).
    //
    // In order to help differentiate which bit was set in a multi-bit event scenario, the incoming
    // events are also readable as a bank of status registers, mapped again 1:1 into 6x 32-bit registers.
    //
    // NOTE NOTE NOTE: the ordering of the SFR registers to word position is reversed, so the higher-number
    // register maps to the lower-numbered 32-bit word of the event map.
    localparam EVC_REGS = EVC / 32;

    logic [0:EVC_REGS-1][31:0] cr_evmap;
    logic [0:EVC_REGS-1][31:0] sr_evstat;
    logic [23:0] muxed_events[3]; // also sychronize into aclk-domain
    logic [EVC-1:0] gated_dmareq;

	apb_cr #(.A('hB0),              .DW(32), .SFRCNT(EVC_REGS))  sfr_dmareq_map   (.cr(cr_evmap  ), .prdata32(),.*);
	apb_sr #(.A('hB0 + EVC_REGS*4), .DW(32), .SFRCNT(EVC_REGS))  sfr_dmareq_stat  (.sr(sr_evstat ), .prdata32(),.*);
	generate
		for (genvar e = 0; e < EVC_REGS; e++) begin: dmagen
            for (genvar g = 0; g < 32; g++) begin: dmagate
                assign gated_dmareq[e*32 + g] = dmareq[e*32 + g] & cr_evmap[EVC_REGS - 1 - e][g];
                assign sr_evstat[e][g] = gated_dmareq[(EVC_REGS - 1 - e)*32 + g];
            end
		end
        for (genvar c = 0; c < 24; c++) begin: reduce
            assign muxed_events[2][c] = |gated_dmareq[(c+1)*8-1:c*8];
        end
	endgenerate
    always_ff @(posedge aclk) begin
        muxed_events[1] <= muxed_events[2];
        muxed_events[0] <= muxed_events[1];
    end
    assign dma_event_set = muxed_events[0];
    // any bit set here will perennially cause the bit to be set in the event register
    assign dma_event_set_valid = |muxed_events[0];

    /////////////////////// address filtering
    apb_cr #(.A('hE0), .DW(20))      sfr_filter_base_0        (.cr(filter_base[0]), .prdata32(),.*);
    apb_cr #(.A('hE4), .DW(20))      sfr_filter_bounds_0      (.cr(filter_bounds[0]), .prdata32(),.*);
    apb_cr #(.A('hE8), .DW(20))      sfr_filter_base_1        (.cr(filter_base[1]), .prdata32(),.*);
    apb_cr #(.A('hEC), .DW(20))      sfr_filter_bounds_1      (.cr(filter_bounds[1]), .prdata32(),.*);
    apb_cr #(.A('hF0), .DW(20))      sfr_filter_base_2        (.cr(filter_base[2]), .prdata32(),.*);
    apb_cr #(.A('hF4), .DW(20))      sfr_filter_bounds_2      (.cr(filter_bounds[2]), .prdata32(),.*);
    apb_cr #(.A('hF8), .DW(20))      sfr_filter_base_3        (.cr(filter_base[3]), .prdata32(),.*);
    apb_cr #(.A('hFC), .DW(20))      sfr_filter_bounds_3      (.cr(filter_bounds[3]), .prdata32(),.*);

    /////////////////////// page maps for FIFO endpoints
    generate
        for(genvar p = 0; p < NUM_MACH; p = p + 1) begin: pages
            apb_sr  #(.A('h0C), .DW(16))     sfr_flevel_alias       (.apbs(apbs_fifo[p]), .sr({
                                                                    pclk_regfifo_level[3], pclk_regfifo_level[2],
                                                                    pclk_regfifo_level[1], pclk_regfifo_level[0]}), .prdata32(),.*);
            // Note: the .A() contents here must reflect what is in daric_to_svd.py BIO FIFO alias special case (line 2768 or so) for register extraction to function properly
            apb_acr #(.A('h10+4*p), .DW(32)) sfr_txf_alias          (.apbs(apbs_fifo[p]), .cr(fdin_alias[p]), .ar(push_alias[p]), .prdata32(),.*);
            apb_asr #(.A('h20+4*p), .DW(32)) sfr_rxf_alias          (.apbs(apbs_fifo[p]), .sr(fdout[p]), .ar(pull_alias[p]), .prdata32(),.*);
            apb_acr #(.A('h38), .DW(24))     sfr_event_set_alias    (.apbs(apbs_fifo[p]), .cr(pclk_event_set_alias[p]), .ar(pclk_event_set_valid_alias[p]), .prdata32(),.*);
            apb_acr #(.A('h3C), .DW(24))     sfr_event_clr_alias    (.apbs(apbs_fifo[p]), .cr(pclk_event_clr_alias[p]), .ar(pclk_event_clr_valid_alias[p]), .prdata32(),.*);
            apb_sr  #(.A('h40), .DW(32))     sfr_event_status_alias (.apbs(apbs_fifo[p]), .sr(pclk_event_status), .prdata32(), .*);

            cdc_level_to_pulse   event_set_cdc      (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(pclk_event_set_valid_alias[p]), .out_b(host_event_set_valid_alias[p] ));
            cdc_level_to_pulse   event_clr_cdc      (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(pclk_event_clr_valid_alias[p]), .out_b(host_event_clr_valid_alias[p] ));
            assign apbx_fifo[p]          .prdata = '0 |
                   sfr_flevel_alias       .prdata32 |
                   sfr_txf_alias         .prdata32 |
                   sfr_rxf_alias         .prdata32 |
                   sfr_event_set_alias   .prdata32 |
                   sfr_event_clr_alias   .prdata32 |
                   sfr_event_status_alias.prdata32;
            assign apbx_fifo[p].pready = 1'b1;
            assign apbx_fifo[p].pslverr = 1'b0;
        end
    endgenerate
    cdc_level_to_pulse   push_cdc_alias[3:0]      (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(push_alias       ), .out_b(push_alias_sync   ));
    cdc_level_to_pulse   pull_cdc_alias[3:0]      (.reset(reset), .clk_a(pclk), .clk_faster(aclk), .in_a(pull_alias       ), .out_b(pull_alias_sync   ));

    /////////////////////// machine instantiation & instruction memory
    assign reset = ~reset_n;
    assign resetn = reset_n;

    logic ram_wr_en [NUM_MACH];
    logic [3:0] ram_wr_mask [NUM_MACH];
    logic [MEM_ADDR_BITS-1:0] ram_addr[NUM_MACH];
    logic [31:0] ram_wr_data [NUM_MACH];
    logic host_mem_wr_stb [NUM_MACH];
    logic host_mem_wr [NUM_MACH];
    logic host_mem_wr_d [NUM_MACH];
    logic host_mem_rd [NUM_MACH];
    logic [1:0] psel_sync [NUM_MACH];
    logic [1:0] pwrite_sync [NUM_MACH];
    logic [1:0] penable_sync [NUM_MACH];
    // -2 for word-addressing; -1 because APW is top-exclusive
    logic [APW-1 -2:0] host_mem_addr_sync[NUM_MACH][2];
    // -2 for word-addressing; -1 because APW is top-exclusive
    logic [APW-1 -2:0] host_mem_addr[NUM_MACH];
    logic [31:0] host_mem_rdata_capture[NUM_MACH];

    logic [31:0] host_mem_wdata_sync[NUM_MACH][2];
    logic [31:0] host_mem_wdata[NUM_MACH];
    // this one is shared by all on the read path
    logic [31:0] host_mem_rdata;

    logic [31:0] ram_rd_data [NUM_MACH];

    // machine stall signal
    generate
        for(genvar j = 0; j < NUM_MACH; j = j + 1) begin: stalls
            always_comb begin
                // the external clock *must* go through synchronizers to be used as an edge
                // to trigger the state machine - otherwise we can have big metastability problems
                // and/or timing closure issues
                extclk_selected[j] = gpio_in_sync1[extclk_gpio_aclk[j]];
                // stall is probably critical path...?
                stall[j] = (
                    quanta_halt[j] & ~quantum[j]                        // stall to next quanta
                    | (mach_regfifo_rd[j] &                             // FIFO read but empty
                      ~{regfifo_readable[3], regfifo_readable[2], regfifo_readable[1], regfifo_readable[0]}) != '0
                    | (mach_regfifo_wr[j] &                              // FIFO write but full
                      ~{regfifo_writable[3], regfifo_writable[2], regfifo_writable[1], regfifo_writable[0]}) != '0
                    | stalling_for_event[j]                             // event stall
                ) || ~en_sync[j];                                       // overall machine enable
            end
            always_ff @(posedge aclk) begin
                // register this to reduce critical path to stall
                quantum[j] <= use_extclk_aclk[j] ? (extclk_selected[j] & ~extclk_selected_q[j]) : penable[j];
                extclk_selected_q[j] <= extclk_selected[j];
            end
        end
    endgenerate

    // machine+host -> fifo
    generate
        for(genvar k = 0; k <4; k = k + 1) begin: mach_to_fifo
            priority_demux #(
                .DATAW(32),
                .LEVELS(NUM_MACH + 1)
            ) select_wdata (
                // strobes are modified by en_sync, so that if the core is disabled on a write
                // to fifo instruction, the write doesn't "stick around".
                .stb({
                    mach_regfifo_wr[3][k] & en_sync[3],
                    mach_regfifo_wr[2][k] & en_sync[2],
                    mach_regfifo_wr[1][k] & en_sync[1],
                    mach_regfifo_wr[0][k] & en_sync[0],
                    push_sync[k] | push_alias_sync[k]
                }),
                .data_in({
                    (fdin_sync[k] & {32{push_sync[k]}}) | (fdin_alias_sync[k] & {32{push_alias_sync[k]}}),
                    mach_regfifo_wdata[0],
                    mach_regfifo_wdata[1],
                    mach_regfifo_wdata[2],
                    mach_regfifo_wdata[3]
                }),
                .data_out(regfifo_wdata[k])
            );
            priority_demux #(
                .DATAW(1),
                .LEVELS(NUM_MACH + 1)
            ) select_wr (
                .stb({
                    mach_regfifo_wr[3][k] & en_sync[3],
                    mach_regfifo_wr[2][k] & en_sync[2],
                    mach_regfifo_wr[1][k] & en_sync[1],
                    mach_regfifo_wr[0][k] & en_sync[0],
                    push_sync[k] | push_alias_sync[k]
                }),
                .data_in({
                    push_sync[k] | push_alias_sync[k],
                    mach_regfifo_wr[0][k],
                    mach_regfifo_wr[1][k],
                    mach_regfifo_wr[2][k],
                    mach_regfifo_wr[3][k]
                }),
                .data_out(regfifo_we[k])
            );
            priority_demux #(
                .DATAW(1),
                .LEVELS(NUM_MACH + 1)
            ) select_rd (
                .stb({
                    mach_regfifo_rd[3][k] & en_sync[3],
                    mach_regfifo_rd[2][k] & en_sync[2],
                    mach_regfifo_rd[1][k] & en_sync[1],
                    mach_regfifo_rd[0][k] & en_sync[0],
                    pull_sync[k] | pull_alias_sync[k]
                }),
                .data_in({
                    pull_sync[k] | pull_alias_sync[k],
                    mach_regfifo_rd[0][k],
                    mach_regfifo_rd[1][k],
                    mach_regfifo_rd[2][k],
                    mach_regfifo_rd[3][k]
                }),
                .data_out(regfifo_re[k])
            );
        end
    endgenerate

    /////////////////////// event logic
    logic [7:0] level_eq_result;
    logic [7:0] level_lt_result;
    logic [7:0] level_gt_result;
    logic [23:0] event_set_agg;
    logic [23:0] event_clr_agg;
    generate
        for(genvar i = 0; i < 4; i = i + 1) begin: event_levels
            always_comb begin
                level_eq_result[2*i] = (regfifo_level[i] == host_fifo_event_level[2*i]);
                level_eq_result[2*i+1] = (regfifo_level[i] == host_fifo_event_level[2*i+1]);
                level_lt_result[2*i] = (regfifo_level[i] < host_fifo_event_level[2*i]);
                level_lt_result[2*i+1] = (regfifo_level[i] < host_fifo_event_level[2*i+1]);
                level_gt_result[2*i] = (regfifo_level[i] > host_fifo_event_level[2*i]);
                level_gt_result[2*i+1] = (regfifo_level[i] > host_fifo_event_level[2*i+1]);
            end
        end
    endgenerate
    generate
        for(genvar i = 0; i < 8; i = i + 1) begin: event_levels_hookup
            always_ff @(posedge aclk) begin
                aggregated_events[i + 24] <= host_fifo_event_eq_mask[i] && level_eq_result[i]
                    || host_fifo_event_lt_mask[i] && level_lt_result[i]
                    || host_fifo_event_gt_mask[i] && level_gt_result[i];
            end
        end
    endgenerate
    // retime the event set/clear sources through an aclk pipe stage to relax timing
    // a small delay on this signal should not affect operation since this is an
    // asynchronous software-controlled signal
    always_ff @(posedge aclk) begin
        host_event_set_valid_p <= host_event_set_valid
                | host_event_set_valid_alias[0]
                | host_event_set_valid_alias[1]
                | host_event_set_valid_alias[2]
                | host_event_set_valid_alias[3]
                | dma_event_set_valid; // dma reqs will override everything
        host_event_set_p <= host_event_set & {24{host_event_set_valid}}
            | host_event_set_alias[0] & {24{host_event_set_valid_alias[0]}}
            | host_event_set_alias[1] & {24{host_event_set_valid_alias[1]}}
            | host_event_set_alias[2] & {24{host_event_set_valid_alias[2]}}
            | host_event_set_alias[3] & {24{host_event_set_valid_alias[3]}}
            | dma_event_set & {24{dma_event_set_valid}}; // dma reqs will override everything
        host_event_clr_valid_p <= host_event_clr_valid
                | host_event_clr_valid_alias[0]
                | host_event_clr_valid_alias[1]
                | host_event_clr_valid_alias[2]
                | host_event_clr_valid_alias[3];
        host_event_clr_p <= host_event_clr & {24{host_event_clr_valid}}
            | host_event_clr_alias[0] & {24{host_event_clr_valid_alias[0]}}
            | host_event_clr_alias[1] & {24{host_event_clr_valid_alias[1]}}
            | host_event_clr_alias[2] & {24{host_event_clr_valid_alias[2]}}
            | host_event_clr_alias[3] & {24{host_event_clr_valid_alias[3]}};
    end
    priority_demux #(
        .DATAW(24),
        .LEVELS(5)
    ) event_set_aggregator (
        .stb({event_set_valid, host_event_set_valid_p}),
        .data_in({host_event_set_p,
            event_set[0], event_set[1], event_set[2], event_set[3]}),
        .data_out(event_set_agg)
    );
    priority_demux #(
        .DATAW(24),
        .LEVELS(5)
    ) event_clr_aggregator (
        .stb({event_clr_valid, host_event_clr_valid_p}),
        .data_in({host_event_clr_p,
            event_clr[0], event_clr[1], event_clr[2], event_clr[3]}),
        .data_out(event_clr_agg)
    );
    scc_ff #(
        .RESET(0),
        .WIDTH(24)
    ) event_aggregator (
        .clk(aclk),
        .reset_n(reset_n),
        .set(event_set_agg),
        .clr(event_clr_agg),
        .clobber('0),
        .value('0),
        .q(aggregated_events[23:0])
    );

    /////////////////////// gpio logic
    generate
        for (genvar gp = 0; gp < 32; gp++) begin: gp_iface
            assign bio_gpio[gp].po = gpio_out[gp] ^ out_invert[gp];
            assign bio_gpio[gp].oe = gpio_dir[gp] ^ oe_invert[gp];
            assign gpio_in[gp] = bio_gpio[gp].pi ^ in_invert[gp];
        end
    endgenerate
    // add metastability hardening, with optional reduced path for latency-sensitive ops
    // the decision ways made to not allow total bypass of any clock hardening because
    // the gpio_in signal is an event source, which propagates into all the registers. Any
    // sort of metastability here could lead to really unpredictable outcomes, and the
    // penalty is small (aclk ~ 800MHz => 1.25ns delay, which is typically well within the
    // rise time even of many I/O signals)
    always @(posedge aclk) begin
        gpio_in_sync0 <= gpio_in;
        gpio_in_sync1 <= gpio_in_sync0;
    end
    generate
        for(genvar m = 0; m < 32; m = m + 1) begin: gen_bypass
            assign gpio_in_cleaned[m] = sync_bypass[m] ? gpio_in_sync0[m] : gpio_in_sync1[m];
        end
    endgenerate

    logic [31:0] gpio_set_agg;
    logic [31:0] gpio_clr_agg;
    logic [31:0] gpdir_set_agg;
    logic [31:0] gpdir_clr_agg;
    generate
        for(genvar g = 0; g < 32; g = g + 1) begin: gen_gpio
            priority_demux #(
                .DATAW(1),
                .LEVELS(4)
            ) gpio_set_aggregator (
                .stb({gpio_set[3][g] & gpio_set_valid[3],
                      gpio_set[2][g] & gpio_set_valid[2],
                      gpio_set[1][g] & gpio_set_valid[1],
                      gpio_set[0][g] & gpio_set_valid[0]}),
                .data_in({gpio_set[0][g], gpio_set[1][g], gpio_set[2][g], gpio_set[3][g]}),
                .data_out(gpio_set_agg[g])
            );
            priority_demux #(
                .DATAW(1),
                .LEVELS(4)
            ) gpio_clr_aggregator (
                .stb({gpio_clr[3][g] & gpio_clr_valid[3],
                    gpio_clr[2][g] & gpio_clr_valid[2],
                    gpio_clr[1][g] & gpio_clr_valid[1],
                    gpio_clr[0][g] & gpio_clr_valid[0]}),
                .data_in({gpio_clr[0][g], gpio_clr[1][g], gpio_clr[2][g], gpio_clr[3][g]}),
                .data_out(gpio_clr_agg[g])
            );
            priority_demux #(
                .DATAW(1),
                .LEVELS(4)
            ) gpdir_set_aggregator (
                .stb({gpdir_set[3][g] & gpdir_set_valid[3],
                    gpdir_set[2][g] & gpdir_set_valid[2],
                    gpdir_set[1][g] & gpdir_set_valid[1],
                    gpdir_set[0][g] & gpdir_set_valid[0]}),
                .data_in({gpdir_set[0][g], gpdir_set[1][g], gpdir_set[2][g], gpdir_set[3][g]}),
                .data_out(gpdir_set_agg[g])
            );
            priority_demux #(
                .DATAW(1),
                .LEVELS(4)
            ) gpdir_clr_aggregator (
                .stb({gpdir_clr[3][g] & gpdir_clr_valid[3],
                    gpdir_clr[2][g] & gpdir_clr_valid[2],
                    gpdir_clr[1][g] & gpdir_clr_valid[1],
                    gpdir_clr[0][g] & gpdir_clr_valid[0]}),
                .data_in({gpdir_clr[0][g], gpdir_clr[1][g], gpdir_clr[2][g], gpdir_clr[3][g]}),
                .data_out(gpdir_clr_agg[g])
            );
        end
    endgenerate
    scc_ff #(
        .RESET(0),
        .WIDTH(32)
    ) gpio_aggregator (
        .clk(aclk),
        .reset_n(reset_n),
        .set(gpio_set_agg),
        .clr(gpio_clr_agg),
        .clobber('0),
        .value('0),
        .q(gpio_out_aclk)
    );
    scc_ff #(
        .RESET(0),
        .WIDTH(32)
    ) gpdir_aggregator (
        .clk(aclk),
        .reset_n(reset_n),
        .set(gpdir_set_agg),
        .clr(gpdir_clr_agg),
        .clobber('0),
        .value('0),
        .q(gpio_dir_aclk)
    );
    always_ff @(posedge aclk) begin
        if (snap_output_to_quantum) begin
            case (snap_output_to_which)
                2'b00: begin
                    if (penable[0]) begin
                        gpio_out <= gpio_out_aclk;
                        gpio_dir <= gpio_dir_aclk;
                    end else begin
                        gpio_out <= gpio_out;
                        gpio_dir <= gpio_dir;
                    end
                end
                2'b01: begin
                    if (penable[1]) begin
                        gpio_out <= gpio_out_aclk;
                        gpio_dir <= gpio_dir_aclk;
                    end else begin
                        gpio_out <= gpio_out;
                        gpio_dir <= gpio_dir;
                    end
                end
                2'b10: begin
                    if (penable[2]) begin
                        gpio_out <= gpio_out_aclk;
                        gpio_dir <= gpio_dir_aclk;
                    end else begin
                        gpio_out <= gpio_out;
                        gpio_dir <= gpio_dir;
                    end
                end
                2'b11: begin
                    if (penable[3]) begin
                        gpio_out <= gpio_out_aclk;
                        gpio_dir <= gpio_dir_aclk;
                    end else begin
                        gpio_out <= gpio_out;
                        gpio_dir <= gpio_dir;
                    end
                end
            endcase
        end else begin
            gpio_out <= gpio_out_aclk;
            gpio_dir <= gpio_dir_aclk;
        end
    end
    always_ff @(posedge aclk) begin
        case (snap_input_to_which)
            2'b00: begin
                if (penable[0]) begin
                    gpio_in_snapped <= gpio_in_cleaned;
                end else begin
                    gpio_in_snapped <= gpio_in_snapped;
                end
            end
            2'b01: begin
                if (penable[1]) begin
                    gpio_in_snapped <= gpio_in_cleaned;
                end else begin
                    gpio_in_snapped <= gpio_in_snapped;
                end
            end
            2'b10: begin
                if (penable[2]) begin
                    gpio_in_snapped <= gpio_in_cleaned;
                end else begin
                    gpio_in_snapped <= gpio_in_snapped;
                end
            end
            2'b11: begin
                if (penable[3]) begin
                    gpio_in_snapped <= gpio_in_cleaned;
                end else begin
                    gpio_in_snapped <= gpio_in_snapped;
                end
            end
        endcase
    end
    always_comb begin
        if (snap_input_to_quantum) begin
            gpio_in_maybe_snapped = gpio_in_snapped;
        end else begin
            gpio_in_maybe_snapped = gpio_in_cleaned;
        end
    end

    /////////////////////// irq
    always_comb begin
        irq_agg[0] = (irqmask0 & aggregated_events) != 0;
        irq_agg[1] = (irqmask1 & aggregated_events) != 0;
        irq_agg[2] = (irqmask2 & aggregated_events) != 0;
        irq_agg[3] = (irqmask3 & aggregated_events) != 0;
    end
    always_ff @(posedge pclk) begin
        irq_agg_q <= irq_agg;
    end
    generate
        for(genvar i = 0; i < 4; i = i + 1) begin: IRQs
            always_ff @(posedge pclk or negedge reset_n) begin
                if (~reset_n) begin
                    irq[i] <= '0;
                end else begin
                    if (irq_edge[i]) begin
                        irq[i] <= irq_agg[i] & ~irq_agg_q;
                    end else begin
                        irq[i] <= irq_agg[i];
                    end
                end
            end
        end
    endgenerate

    /////////////////////// DMA control FSM
    always_ff @(posedge aclk) begin
        if (~reset_n) begin
            dma_owner <= '0;
            dma_active <= '0;
        end else begin
`ifndef REGISTER_RAM
            if (dma_active == 0) begin
                if ((mem_la_read[0] | mem_la_write[0] | (mem_valid[0] & !mem_ready[0])) & ext_addr_la[0]) begin
                    dma_owner <= 2'h0;
                    dma_active <= 1;
                end else if ((mem_la_read[1] | mem_la_write[1] | (mem_valid[1] & !mem_ready[1])) & ext_addr_la[1]) begin
                    dma_owner <= 2'h1;
                    dma_active <= 1;
                end else if ((mem_la_read[2] | mem_la_write[2] | (mem_valid[2] & !mem_ready[2])) & ext_addr_la[2]) begin
                    dma_owner <= 2'h2;
                    dma_active <= 1;
                end else if ((mem_la_read[3] | mem_la_write[3] | (mem_valid[3] & !mem_ready[3])) & ext_addr_la[3]) begin
                    dma_owner <= 2'h3;
                    dma_active <= 1;
                end
            end else begin
                if (dma_ready) begin
                    dma_owner <= '0;
                    dma_active <= 0;
                end else begin
                    dma_owner <= dma_owner;
                    dma_active <= dma_active;
                end
            end
`else
            if (dma_active == 0) begin
                if ((mem_valid[0] & !mem_ready[0]) & ext_addr[0]) begin
                    dma_owner <= 2'h0;
                    dma_active <= 1;
                end else if ((mem_valid[1] & !mem_ready[1]) & ext_addr[1]) begin
                    dma_owner <= 2'h1;
                    dma_active <= 1;
                end else if ((mem_valid[2] & !mem_ready[2]) & ext_addr[2]) begin
                    dma_owner <= 2'h2;
                    dma_active <= 1;
                end else if ((mem_valid[3] & !mem_ready[3]) & ext_addr[3]) begin
                    dma_owner <= 2'h3;
                    dma_active <= 1;
                end
            end else begin
                if (dma_ready) begin
                    dma_owner <= '0;
                    dma_active <= 0;
                end else begin
                    dma_owner <= dma_owner;
                    dma_active <= dma_active;
                end
            end
`endif
        end
`ifdef PIPELINE_AXI_WR
        mem_wstrb_pipe <= mem_wstrb;
        dma_active_pipe <= dma_active;
        mem_valid_pipe <= mem_valid;
        dma_ready_d <= dma_ready;
`endif
    end

    /////////////////////// Demux & CDC of datapath for each CPU
    // convert interface to AXIL
    picorv32_axi_adapter #(
`ifdef PIPELINE_AXI_RD
        .PIPELINE_AXI_MEM_READY(1)
`else
        .PIPELINE_AXI_MEM_READY(0)
`endif
    ) prv_axil (
        .clk(aclk),
        .resetn(reset_n),

        // AXI4-lite master memory interface
        .mem_axi_awvalid(core_axil.aw_valid),
        .mem_axi_awready(core_axil.aw_ready),
        .mem_axi_awaddr(core_axil.aw_addr),
        .mem_axi_awprot(core_axil.aw_prot),

        .mem_axi_wvalid(core_axil.w_valid),
        .mem_axi_wready(core_axil.w_ready),
        .mem_axi_wdata(core_axil.w_data),
        .mem_axi_wstrb(core_axil.w_strb),

        .mem_axi_bvalid(core_axil.b_valid),
        .mem_axi_bready(core_axil.b_ready),

        .mem_axi_arvalid(core_axil.ar_valid),
        .mem_axi_arready(core_axil.ar_ready),
        .mem_axi_araddr(core_axil.ar_addr),
        .mem_axi_arprot(core_axil.ar_prot),

        .mem_axi_rvalid(core_axil.r_valid),
        .mem_axi_rready(core_axil.r_ready),
        .mem_axi_rdata(core_axil.r_data),

`ifndef PIPELINE_AXI_WR
        .mem_valid(mem_valid[dma_owner] & dma_active),
        .mem_instr(mem_instr[dma_owner]),
        .mem_ready(dma_ready),
        .mem_addr(mem_addr[dma_owner]),
        .mem_wdata(mem_wdata[dma_owner]),
        .mem_wstrb(mem_wstrb[dma_owner]),
        .mem_rdata(dma_rdata)
`else
        .mem_valid(mem_valid_pipe[dma_owner] & dma_active_pipe & ~dma_ready_d),
        .mem_instr(mem_instr[dma_owner]),
        .mem_ready(dma_ready),
        .mem_addr(mem_addr[dma_owner]),
        .mem_wdata(mem_wdata[dma_owner]),
        .mem_wstrb(mem_wstrb_pipe[dma_owner]),
        .mem_rdata(dma_rdata)
`endif
    );

    // AXIL crossbar to demux address space further
    axil_crossbar #(
        .S_COUNT(1),
        .M_COUNT(2),
        .M_BASE_ADDR({32'h6000_0000,32'h4000_0000}),
        .M_ADDR_WIDTH({32'd29,32'd29})
    ) axil_demux (
        .clk(aclk),
        .rst(~reset_n),
        .s_axil_awaddr(core_axil.aw_addr),
        .s_axil_awprot(core_axil.aw_prot),
        .s_axil_awvalid(core_axil.aw_valid),
        .s_axil_awready(core_axil.aw_ready),
        .s_axil_wdata(core_axil.w_data),
        .s_axil_wstrb(core_axil.w_strb),
        .s_axil_wvalid(core_axil.w_valid),
        .s_axil_wready(core_axil.w_ready),
        .s_axil_bresp(core_axil.b_resp),
        .s_axil_bvalid(core_axil.b_valid),
        .s_axil_bready(core_axil.b_ready),
        .s_axil_araddr(core_axil.ar_addr),
        .s_axil_arprot(core_axil.ar_prot),
        .s_axil_arvalid(core_axil.ar_valid),
        .s_axil_arready(core_axil.ar_ready),
        .s_axil_rdata(core_axil.r_data),
        .s_axil_rresp(core_axil.r_resp),
        .s_axil_rvalid(core_axil.r_valid),
        .s_axil_rready(core_axil.r_ready),

        .m_axil_awaddr({mem_axil.aw_addr, peri_axil.aw_addr}),
        .m_axil_awprot({mem_axil.aw_prot, peri_axil.aw_prot}),
        .m_axil_awvalid({mem_axil.aw_valid, peri_axil.aw_valid}),
        .m_axil_awready({mem_axil.aw_ready, peri_axil.aw_ready}),
        .m_axil_wdata({mem_axil.w_data, peri_axil.w_data}),
        .m_axil_wstrb({mem_axil.w_strb, peri_axil.w_strb}),
        .m_axil_wvalid({mem_axil.w_valid, peri_axil.w_valid}),
        .m_axil_wready({mem_axil.w_ready, peri_axil.w_ready}),
        .m_axil_bresp({mem_axil.b_resp, peri_axil.b_resp}),
        .m_axil_bvalid({mem_axil.b_valid, peri_axil.b_valid}),
        .m_axil_bready({mem_axil.b_ready, peri_axil.b_ready}),
        .m_axil_araddr({mem_axil.ar_addr, peri_axil.ar_addr}),
        .m_axil_arprot({mem_axil.ar_prot, peri_axil.ar_prot}),
        .m_axil_arvalid({mem_axil.ar_valid, peri_axil.ar_valid}),
        .m_axil_arready({mem_axil.ar_ready, peri_axil.ar_ready}),
        .m_axil_rdata({mem_axil.r_data, peri_axil.r_data}),
        .m_axil_rresp({mem_axil.r_resp, peri_axil.r_resp}),
        .m_axil_rvalid({mem_axil.r_valid, peri_axil.r_valid}),
        .m_axil_rready({mem_axil.r_ready, peri_axil.r_ready})
    );

    axil_cdc #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) mem_cdc (
        .s_clk(aclk),
        .s_rst(~reset_n),
        .s_axil_awaddr(mem_axil.aw_addr),
        .s_axil_awprot(mem_axil.aw_prot),
        .s_axil_awvalid(mem_axil.aw_valid),
        .s_axil_awready(mem_axil.aw_ready),
        .s_axil_wdata(mem_axil.w_data),
        .s_axil_wstrb(mem_axil.w_strb),
        .s_axil_wvalid(mem_axil.w_valid),
        .s_axil_wready(mem_axil.w_ready),
        .s_axil_bresp(mem_axil.b_resp),
        .s_axil_bvalid(mem_axil.b_valid),
        .s_axil_bready(mem_axil.b_ready),
        .s_axil_araddr(mem_axil.ar_addr),
        .s_axil_arprot(mem_axil.ar_prot),
        .s_axil_arvalid(mem_axil.ar_valid),
        .s_axil_arready(mem_axil.ar_ready),
        .s_axil_rdata(mem_axil.r_data),
        .s_axil_rresp(mem_axil.r_resp),
        .s_axil_rvalid(mem_axil.r_valid),
        .s_axil_rready(mem_axil.r_ready),

        .clkmode(clocking_mode),

        .m_clk(hclk),
        .m_rst(~reset_n),
        .m_axil_awaddr  (mem_filtered_axil.aw_addr ),
        .m_axil_awprot  (mem_filtered_axil.aw_prot ),
        .m_axil_awvalid (mem_filtered_axil.aw_valid),
        .m_axil_awready (mem_filtered_axil.aw_ready),
        .m_axil_wdata   (mem_filtered_axil.w_data  ),
        .m_axil_wstrb   (mem_filtered_axil.w_strb  ),
        .m_axil_wvalid  (mem_filtered_axil.w_valid ),
        .m_axil_wready  (mem_filtered_axil.w_ready ),
        .m_axil_bresp   (mem_filtered_axil.b_resp  ),
        .m_axil_bvalid  (mem_filtered_axil.b_valid ),
        .m_axil_bready  (mem_filtered_axil.b_ready ),
        .m_axil_araddr  (mem_filtered_axil.ar_addr ),
        .m_axil_arprot  (mem_filtered_axil.ar_prot ),
        .m_axil_arvalid (mem_filtered_axil.ar_valid),
        .m_axil_arready (mem_filtered_axil.ar_ready),
        .m_axil_rdata   (mem_filtered_axil.r_data  ),
        .m_axil_rresp   (mem_filtered_axil.r_resp  ),
        .m_axil_rvalid  (mem_filtered_axil.r_valid ),
        .m_axil_rready  (mem_filtered_axil.r_ready )
    );

    axil_filter #(
        .RANGES(FILTER_RANGES)
    ) mem_filter (
        .clk(hclk),
        .resetn(reset_n),
        .s_axi_awaddr   (mem_filtered_axil.aw_addr ),
        .s_axi_awprot   (mem_filtered_axil.aw_prot ),
        .s_axi_awvalid  (mem_filtered_axil.aw_valid),
        .s_axi_awready  (mem_filtered_axil.aw_ready),
        .s_axi_wdata    (mem_filtered_axil.w_data  ),
        .s_axi_wstrb    (mem_filtered_axil.w_strb  ),
        .s_axi_wvalid   (mem_filtered_axil.w_valid ),
        .s_axi_wready   (mem_filtered_axil.w_ready ),
        .s_axi_bresp    (mem_filtered_axil.b_resp  ),
        .s_axi_bvalid   (mem_filtered_axil.b_valid ),
        .s_axi_bready   (mem_filtered_axil.b_ready ),
        .s_axi_araddr   (mem_filtered_axil.ar_addr ),
        .s_axi_arprot   (mem_filtered_axil.ar_prot ),
        .s_axi_arvalid  (mem_filtered_axil.ar_valid),
        .s_axi_arready  (mem_filtered_axil.ar_ready),
        .s_axi_rdata    (mem_filtered_axil.r_data  ),
        .s_axi_rresp    (mem_filtered_axil.r_resp  ),
        .s_axi_rvalid   (mem_filtered_axil.r_valid ),
        .s_axi_rready   (mem_filtered_axil.r_ready ),

        .m_axi_awaddr   (axim.awaddr ),
        .m_axi_awprot   (axim.awprot ),
        .m_axi_awvalid  (axim.awvalid),
        .m_axi_awready  (axim.awready),
        .m_axi_wdata    (axim.wdata  ),
        .m_axi_wstrb    (axim.wstrb  ),
        .m_axi_wvalid   (axim.wvalid ),
        .m_axi_wready   (axim.wready ),
        .m_axi_bresp    (axim.bresp  ),
        .m_axi_bvalid   (axim.bvalid ),
        .m_axi_bready   (axim.bready ),
        .m_axi_araddr   (axim.araddr ),
        .m_axi_arprot   (axim.arprot ),
        .m_axi_arvalid  (axim.arvalid),
        .m_axi_arready  (axim.arready),
        .m_axi_rdata    (axim.rdata  ),
        .m_axi_rresp    (axim.rresp  ),
        .m_axi_rvalid   (axim.rvalid ),
        .m_axi_rready   (axim.rready ),
        .base           (filter_base),
        .length         (filter_bounds),
        .gutter         (mem_gutter),
        .disable_filter (disable_filter_mem)
    );

    // tie off AXI-master signals not driven by AXI-Lite
    assign axim.awid = AHBMID4;
    assign axim.awlen = '0;
    assign axim.awsize = 2;  // size = 4 bytes
    assign axim.awburst = 0; // fixed burst
    assign axim.awlock = '0;
    assign axim.awcache = '0;
    assign axim.awmaster = '0;
    assign axim.awinner = '0;
    assign axim.awshare = '0;
    assign axim.awsparse = '1;
//  assign axim.awprot = 2;
//  assign axim.awqos = '0;
//  assign axim.awregion = '0;
//  assign axim.awatop = '0;
    assign axim.awuser = AHBMID4|'0;
    assign axim.wlast = '1;
    assign axim.wuser = '0;
    assign axim.wid   = AHBMID4;
    assign axim.arid = AHBMID4;
    assign axim.arlen = '0;
    assign axim.arsize = 2; // size = 4 bytes
    assign axim.arburst = 0; // fixed burst
    assign axim.arlock = '0;
    assign axim.arcache = '0;
//  assign axim.arprot = 2;
//  assign axim.arqos = '0;
//  assign axim.arregion = '0;
    assign axim.aruser = AHBMID4|'0;
    assign axim.armaster = '0;
    assign axim.arinner = '0;
    assign axim.arshare = '0;
    // assign axim.ruser = '0;
    // assign axim.buser = '0;

    axil_cdc #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) peri_cdc (
        .s_clk(aclk),
        .s_rst(~reset_n),
        .s_axil_awaddr(peri_axil.aw_addr),
        .s_axil_awprot(peri_axil.aw_prot),
        .s_axil_awvalid(peri_axil.aw_valid),
        .s_axil_awready(peri_axil.aw_ready),
        .s_axil_wdata(peri_axil.w_data),
        .s_axil_wstrb(peri_axil.w_strb),
        .s_axil_wvalid(peri_axil.w_valid),
        .s_axil_wready(peri_axil.w_ready),
        .s_axil_bresp(peri_axil.b_resp),
        .s_axil_bvalid(peri_axil.b_valid),
        .s_axil_bready(peri_axil.b_ready),
        .s_axil_araddr(peri_axil.ar_addr),
        .s_axil_arprot(peri_axil.ar_prot),
        .s_axil_arvalid(peri_axil.ar_valid),
        .s_axil_arready(peri_axil.ar_ready),
        .s_axil_rdata(peri_axil.r_data),
        .s_axil_rresp(peri_axil.r_resp),
        .s_axil_rvalid(peri_axil.r_valid),
        .s_axil_rready(peri_axil.r_ready),

        .clkmode(clocking_mode),

        .m_clk(dmaclk),
        .m_rst(~reset_n),
        .m_axil_awaddr  (peri_filtered_axil.aw_addr ),
        .m_axil_awprot  (peri_filtered_axil.aw_prot ),
        .m_axil_awvalid (peri_filtered_axil.aw_valid),
        .m_axil_awready (peri_filtered_axil.aw_ready),
        .m_axil_wdata   (peri_filtered_axil.w_data  ),
        .m_axil_wstrb   (peri_filtered_axil.w_strb  ),
        .m_axil_wvalid  (peri_filtered_axil.w_valid ),
        .m_axil_wready  (peri_filtered_axil.w_ready ),
        .m_axil_bresp   (peri_filtered_axil.b_resp  ),
        .m_axil_bvalid  (peri_filtered_axil.b_valid ),
        .m_axil_bready  (peri_filtered_axil.b_ready ),
        .m_axil_araddr  (peri_filtered_axil.ar_addr ),
        .m_axil_arprot  (peri_filtered_axil.ar_prot ),
        .m_axil_arvalid (peri_filtered_axil.ar_valid),
        .m_axil_arready (peri_filtered_axil.ar_ready),
        .m_axil_rdata   (peri_filtered_axil.r_data  ),
        .m_axil_rresp   (peri_filtered_axil.r_resp  ),
        .m_axil_rvalid  (peri_filtered_axil.r_valid ),
        .m_axil_rready  (peri_filtered_axil.r_ready )
    );

    axil_filter #(
        .RANGES(FILTER_RANGES)
    ) peri_filter (
        .clk(dmaclk),
        .resetn(reset_n),
        .s_axi_awaddr   (peri_filtered_axil.aw_addr ),
        .s_axi_awprot   (peri_filtered_axil.aw_prot ),
        .s_axi_awvalid  (peri_filtered_axil.aw_valid),
        .s_axi_awready  (peri_filtered_axil.aw_ready),
        .s_axi_wdata    (peri_filtered_axil.w_data  ),
        .s_axi_wstrb    (peri_filtered_axil.w_strb  ),
        .s_axi_wvalid   (peri_filtered_axil.w_valid ),
        .s_axi_wready   (peri_filtered_axil.w_ready ),
        .s_axi_bresp    (peri_filtered_axil.b_resp  ),
        .s_axi_bvalid   (peri_filtered_axil.b_valid ),
        .s_axi_bready   (peri_filtered_axil.b_ready ),
        .s_axi_araddr   (peri_filtered_axil.ar_addr ),
        .s_axi_arprot   (peri_filtered_axil.ar_prot ),
        .s_axi_arvalid  (peri_filtered_axil.ar_valid),
        .s_axi_arready  (peri_filtered_axil.ar_ready),
        .s_axi_rdata    (peri_filtered_axil.r_data  ),
        .s_axi_rresp    (peri_filtered_axil.r_resp  ),
        .s_axi_rvalid   (peri_filtered_axil.r_valid ),
        .s_axi_rready   (peri_filtered_axil.r_ready ),

        .m_axi_awaddr   (peri_cdc_axil.aw_addr ),
        .m_axi_awprot   (peri_cdc_axil.aw_prot ),
        .m_axi_awvalid  (peri_cdc_axil.aw_valid),
        .m_axi_awready  (peri_cdc_axil.aw_ready),
        .m_axi_wdata    (peri_cdc_axil.w_data  ),
        .m_axi_wstrb    (peri_cdc_axil.w_strb  ),
        .m_axi_wvalid   (peri_cdc_axil.w_valid ),
        .m_axi_wready   (peri_cdc_axil.w_ready ),
        .m_axi_bresp    (peri_cdc_axil.b_resp  ),
        .m_axi_bvalid   (peri_cdc_axil.b_valid ),
        .m_axi_bready   (peri_cdc_axil.b_ready ),
        .m_axi_araddr   (peri_cdc_axil.ar_addr ),
        .m_axi_arprot   (peri_cdc_axil.ar_prot ),
        .m_axi_arvalid  (peri_cdc_axil.ar_valid),
        .m_axi_arready  (peri_cdc_axil.ar_ready),
        .m_axi_rdata    (peri_cdc_axil.r_data  ),
        .m_axi_rresp    (peri_cdc_axil.r_resp  ),
        .m_axi_rvalid   (peri_cdc_axil.r_valid ),
        .m_axi_rready   (peri_cdc_axil.r_ready ),
        .base           (filter_base),
        .length         (filter_bounds),
        .gutter         (peri_gutter),
        .disable_filter (disable_filter_mem)
    );

    // AXIL->AHB bridge for peripheral bus
    // encode address and size into AHB per cmsdk_ahb_to_sram.v spec-abuse
    always_comb begin
        case (peri_cdc_axil.w_strb)
            4'b0001: begin
                ahb_size_bodge = 3'b000;
                axi_aw_bodge = peri_cdc_axil.aw_addr & 32'hFFFF_FFFC;
            end
            4'b0010: begin
                ahb_size_bodge = 3'b000;
                axi_aw_bodge = (peri_cdc_axil.aw_addr & 32'hFFFF_FFFC) + 32'h1;
            end
            4'b0100: begin
                ahb_size_bodge = 3'b000;
                axi_aw_bodge = (peri_cdc_axil.aw_addr & 32'hFFFF_FFFC) + 32'h2;
            end
            4'b1000: begin
                ahb_size_bodge = 3'b000;
                axi_aw_bodge = (peri_cdc_axil.aw_addr & 32'hFFFF_FFFC) + 32'h3;
            end
            4'b0011: begin
                ahb_size_bodge = 3'b001;
                axi_aw_bodge = peri_cdc_axil.aw_addr & 32'hFFFF_FFFC;
            end
            4'b1100: begin
                ahb_size_bodge = 3'b001;
                axi_aw_bodge = (peri_cdc_axil.aw_addr & 32'hFFFF_FFFC) + 32'h2;
            end
            4'b1111: begin
                ahb_size_bodge = 3'b010;
                axi_aw_bodge = peri_cdc_axil.aw_addr;
            end
            // default is coded to write the full word because this is probably least
            // surprising and most compatible behavior. The way the RAM block is coded,
            // a size of '0' still results in a byte being written to the LSB of the address.
            default: begin
                ahb_size_bodge = 3'b010;
                axi_aw_bodge = peri_cdc_axil.aw_addr;
            end
        endcase
    end

    // cleanup lints
`ifdef USE_OSS_BRIDGE
    logic [3:0] axi2ahb_bid_null;
    logic [3:0] axi2ahb_rid_null;
    logic       axi2ahb_rlast_null;
    axi2ahb peri_axi2ahb (
        .clk(dmaclk),
        .reset(~reset_n),
        // tie unused outputs
        .BID(axi2ahb_bid_null),
        .RID(axi2ahb_rid_null),
        .RLAST(axi2ahb_rlast_null),

        .AWID('0),
        .AWADDR(axi_aw_bodge),
        .AWLEN('0),
        .AWSIZE(ahb_size_bodge[1:0]),
        .AWVALID(peri_cdc_axil.aw_valid),
        .AWREADY(peri_cdc_axil.aw_ready),
        .WID('0),
        .WDATA(peri_cdc_axil.w_data),
        .WSTRB(peri_cdc_axil.w_strb),
        .WLAST('1),
        .WVALID(peri_cdc_axil.w_valid),
        .WREADY(peri_cdc_axil.w_ready),
        // .BID('0),
        .BRESP(peri_cdc_axil.b_resp),
        .BVALID(peri_cdc_axil.b_valid),
        .BREADY(peri_cdc_axil.b_ready),
        .ARID('0),
        .ARADDR(peri_cdc_axil.ar_addr),
        .ARLEN('0),
        .ARSIZE(2'b10), // always read full words
        .ARVALID(peri_cdc_axil.ar_valid),
        .ARREADY(peri_cdc_axil.ar_ready),
        // .RID('0),
        .RDATA(peri_cdc_axil.r_data),
        .RRESP(peri_cdc_axil.r_resp),
        // .RLAST(peri_cdc_axil.),
        .RVALID(peri_cdc_axil.r_valid),
        .RREADY(peri_cdc_axil.r_ready),

        .HADDR(ahbm.haddr),
        .HBURST(ahbm.hburst),
        .HSIZE(ahbm.hsize),
        .HTRANS(ahbm.htrans),
        .HWRITE(ahbm.hwrite),
        .HWDATA(ahbm.hwdata),
        .HRDATA(ahbm.hrdata),
        .HREADY(ahbm.hready),
        .HRESP(ahbm.hresp)
    );
    assign ahbm.hprot = '0;
    assign ahbm.hmaster = '0;
    assign ahbm.hmasterlock = '0;
    assign ahbm.hreadym = ahbm.hready;
    assign ahbm.hauser = '0;
    assign ahbm.hwuser = '0;

    // tie off unused pins
    assign ahbm.hsel = '1;
`else
    // tie unused outputs
    logic [15:0] axi2ahb_bid_null;
    logic [15:0] axi2ahb_rid_null;
    logic       axi2ahb_rlast_null;
    logic [15:0] axi2ahb_ruser_null;
    logic [3:0] axi2ahb_hprot_null;
    logic       axi2ahb_hmastlock_null;
    logic       axi2ahb_extreq_null;
    logic [15:0] axi2ahb_hauser_null;
    logic [15:0] axi2ahb_hwuser_null;
    CM7AAB # (
        .DW_64(0)
    ) peri_axi2ahb (
        .CLK(dmaclk),
        .nSYSRESET(reset_n),

        .AWADDR(axi_aw_bodge),
        .AWBURST('0),
        .AWID('0),
        .AWSIZE(ahb_size_bodge[1:0]),
        .AWLOCK('0),
        .AWPROT('0),
        .AWCACHE('0),
        .AWUSER('0),
        .AWLEN('0),
        .AWSPARSE('0),
        .AWVALID(peri_cdc_axil.aw_valid),
        .AWREADY(peri_cdc_axil.aw_ready),

        .ARADDR(peri_cdc_axil.ar_addr),
        .ARBURST('0),
        .ARID('0),
        .ARLEN('0),
        .ARSIZE(2'b10), // always read full words
        .ARLOCK('0),
        .ARPROT('0),
        .ARCACHE('0),
        .ARUSER('0),
        .ARVALID(peri_cdc_axil.ar_valid),
        .ARREADY(peri_cdc_axil.ar_ready),

        .WLAST('1),
        .WSTRB(peri_cdc_axil.w_strb),
        .WDATA(peri_cdc_axil.w_data),
        .WUSER('0),
        .WVALID(peri_cdc_axil.w_valid),
        .WREADY(peri_cdc_axil.w_ready),

        .RREADY(peri_cdc_axil.r_ready),
        .RVALID(peri_cdc_axil.r_valid),
        .RID(axi2ahb_rid_null),
        .RLAST(axi2ahb_rlast_null),
        .RDATA(peri_cdc_axil.r_data),
        .RUSER(axi2ahb_ruser_null),
        .RRESP(peri_cdc_axil.r_resp),

        .BVALID(peri_cdc_axil.b_valid),
        .BREADY(peri_cdc_axil.b_ready),
        .BRESP(peri_cdc_axil.b_resp),
        .BID(axi2ahb_bid_null),

        .HTRANS(ahbm.htrans),
        .HBURST(ahbm.hburst),
        .HADDR(ahbm.haddr),
        .HWRITE(ahbm.hwrite),
        .HSIZE(ahbm.hsize[2:0]),
        .HWDATA(ahbm.hwdata),
        .HPROT(axi2ahb_hprot_null),
        .HMASTLOCK(axi2ahb_hmastlock_null),

        .HREADY(ahbm.hready),
        .HRDATA(ahbm.hrdata),
        .HRESP(ahbm.hresp),

        .EXREQ(axi2ahb_extreq_null),
        .EXRESP('0),

        .HAUSER(axi2ahb_hauser_null),
        .HWUSER(axi2ahb_hwuser_null),
        .HRUSER('0)
    );
    assign ahbm.hprot = '0;
    assign ahbm.hmaster = '0;
    assign ahbm.hmasterlock = '0;
    assign ahbm.hreadym = ahbm.hready;
    assign ahbm.hauser = '0;
    assign ahbm.hwuser = '0;

    // tie off unused pins
    assign ahbm.hsel = '1;
`endif

    /////////////////////// repeated core units
    `ifdef FPGA
        logic aclk_buf;
        // insert a BUFH to help with clock mux distribution
        BUFG aclk_fixer (
            .I(aclk),
            .O(aclk_buf)
        );
    `endif

    assign mem_rdata = ram_rd_data;
    // give a full aclk to mux between the banks
    // host_mem_rdata is in aclk -> which returns on pclk domain
    // Somewhat fragile time: this circuit assumes aclk is >= 2x speed of pclk
    always_ff @(posedge aclk) begin
        if (host_mem_rd[0]) begin
            host_mem_rdata <= host_mem_rdata_capture[0];
        end else if (host_mem_rd[1]) begin
            host_mem_rdata <= host_mem_rdata_capture[1];
        end else if (host_mem_rd[2]) begin
            host_mem_rdata <= host_mem_rdata_capture[2];
        end else if (host_mem_rd[3]) begin
            host_mem_rdata <= host_mem_rdata_capture[3];
        end
    end

    generate
        for(genvar j = 0; j < NUM_MACH; j = j + 1) begin: mach
            // apb<->imem
            assign apbx_imem[j].pready = 1'b1;
            assign apbx_imem[j].pslverr = 1'b0;
            assign apbx_imem[j].prdata = host_mem_rdata;
            always_comb begin
                host_mem_wr_d[j] = psel_sync[j][1] & pwrite_sync[j][1] & penable_sync[j][1];
                host_mem_rd[j] = psel_sync[j][1] & !pwrite_sync[j][1] & penable_sync[j][1];
                // already synchronized below, just pass through
                host_mem_addr[j] = host_mem_addr_sync[j][1][MEM_ADDR_BITS-1:0];
            end

            always_ff @(posedge aclk) begin
                // cdc syncs
                psel_sync[j][0] <= apbs_imem[j].psel;
                psel_sync[j][1] <= psel_sync[j][0];
                pwrite_sync[j][0] <= apbs_imem[j].pwrite;
                pwrite_sync[j][1] <= pwrite_sync[j][0];
                penable_sync[j][0] <= apbs_imem[j].penable;
                penable_sync[j][1] <= penable_sync[j][0];

                host_mem_wdata_sync[j][0] <= apbs_imem[j].pwdata;
                host_mem_wdata_sync[j][1] <= host_mem_wdata_sync[j][0];

                host_mem_addr_sync[j][0] <= apbs_imem[j].paddr[APW-1:2]; // extract word-level address here
                host_mem_addr_sync[j][1] <= host_mem_addr_sync[j][0];

                host_mem_wr[j] <= host_mem_wr_d[j];
                host_mem_wr_stb[j] <= (host_mem_wr_d[j] & !host_mem_wr[j]);
                host_mem_wdata[j] <= host_mem_wr_d[j] & !host_mem_wr[j] ? host_mem_wdata_sync[j][1] : host_mem_wdata[j];

                host_mem_rdata_capture[j] <= ram_rd_data[j];
            end

            assign imem_wr_mode[j] = en_sync[j]; // when machine j is disabled, the host can use its port to read/write
            // mux between host and machines
            always_comb begin
                ram_wr_en[j] = 0;
                if (imem_wr_mode[j]) begin
                    // machine0 is running
`ifndef REGISTER_RAM
                    ram_wr_en[j] = mem_la_write[j];
                    ram_wr_mask[j] = mem_la_wstrb[j];
                    ram_wr_data[j] = mem_la_wdata[j];

                    ram_addr[j] = mem_la_addr[j][MEM_ADDR_BITS+2:2];
`else
                    ram_wr_en[j] = |mem_wstrb[j] & mem_valid[j];
                    ram_wr_mask[j] = mem_wstrb[j];
                    ram_wr_data[j] = mem_wdata[j];

                    ram_addr[j] = mem_addr[j][MEM_ADDR_BITS+2:2];
`endif
                end else begin
                    // host can write & read; machine can't touch
                    ram_wr_en[j] = host_mem_wr_stb[j];
                    ram_wr_mask[j] = 4'b1111; // only full 32-bit writes are allowed, anything else is undefined
                    ram_wr_data[j] = host_mem_wdata[j];
                    ram_addr[j] = host_mem_addr[j];
                end
            end

            // DMA.
            always_comb begin
                // engine select uses look-ahead version. Look-ahead address bounces all over the place
                /// so it must be gated with the rd/wr la strobes for decoding.
                ext_addr_la[j] = mem_la_addr[j][31:28] >= 1; // map everything from 0x1000_0000 and higher
                merged_mem_ready[j] = ext_addr[j] ? dma_ready && (dma_owner == j) : mem_ready[j];
                merged_mem_rdata[j] = ext_addr[j] ? dma_rdata : mem_rdata[j];
            end
            always_ff @(posedge aclk) begin
                // readback path uses the stable clocked ext_addr to avoid combinational cycle on ready
                ext_addr[j] <= ext_addr_la[j];
            end

            // Instruction Memory.
`ifndef REGISTER_RAM
            Ram_1rw_s #(
                .wordCount(MEM_SIZE_WORDS),
                .wordWidth(32),
                .technology("auto"),
                .AddressWidth(MEM_ADDR_BITS),
                .DataWidth(32),
                .wrMaskWidth(4),
                .wrMaskEnable(1),
                .ramname("RAM_SP_1024_32")
            ) imem (
                .clk(aclk),
                .wr_n(~(ram_wr_en[j] & (~ext_addr_la[j] | ~imem_wr_mode[j]))),
                .addr(ram_addr[j]),
                .wr_mask_n(~ram_wr_mask[j]),
                .ce_n(~(
                    mem_la_write[j] || mem_la_read[j] // during run mode, make sure data does not move
                    || (psel_sync[j][1] & ~imem_wr_mode[j]))), // during host mode, access whenever PSEL active
                .d(ram_wr_data[j]),
                .q(ram_rd_data[j]),
                .cmbist(cmbist),
                .cmatpg(cmatpg),
                .rbs(rbif_bioram1kx32[j]),
                .sramtrm(sramtrm)
            );

            always_ff @(posedge aclk) begin
                mem_ready[j] <= mem_la_read[j] || ram_wr_en[j] || quanta_halt[j] && mem_ready[j];
            end
`else
            Ram_1rw_s #(
                .wordCount(MEM_SIZE_WORDS),
                .wordWidth(32),
                .technology("auto"),
                .AddressWidth(MEM_ADDR_BITS),
                .DataWidth(32),
                .wrMaskWidth(4),
                .wrMaskEnable(1),
                .ramname("RAM_SP_1024_32")
            ) imem (
                .clk(aclk),
                .wr_n(~(ram_wr_en[j] & (~ext_addr[j] | ~imem_wr_mode[j]))),
                .addr(ram_addr[j]),
                .wr_mask_n(~ram_wr_mask[j]),
                .ce_n(~(
                    mem_valid[j] // during run mode, make sure data does not move
                    || (psel_sync[j][1] & ~imem_wr_mode[j]))), // during host mode, access whenever PSEL active
                .d(ram_wr_data[j]),
                .q(ram_rd_data[j]),
                .cmbist(cmbist),
                .cmatpg(cmatpg),
                .rbs(rbif_bioram1kx32[j]),
                .sramtrm(sramtrm)
            );
            always_ff @(posedge aclk) begin
                mem_valid_d[j] <= (mem_valid[j] & ~ext_addr[j]) || (quanta_halt[j] && mem_valid_d[j]);
                dead_cycle[j] <= mem_valid_d[j] & mem_ready[j];
            end
            always_comb begin
                mem_ready[j] = mem_valid_d[j] && ~dead_cycle[j] && mem_valid[j]; // de-assert immediately when mem_valid[j] falls
            end
`endif
            always_ff @(posedge aclk) begin
                // this aligns the enable so that it in concurrent with restart/clkdiv_restart
                if (~reset_n) begin
                    en_sync[j] <= 0;
                end else if (ctl_action_sync) begin
                    en_sync[j] <= en[j];
                end
            end
            always_ff @(posedge aclk) begin
                if (en_sync[j] == 0) begin
                    core_clk_count[j] <= '0;
                end else begin
                    core_clk_count[j] <= core_clk_count[j] + 30'h1;
                end
            end
            pio_divider clk_divider (
                .clk(aclk),
                .reset(reset | (clkdiv_restart[j] & ~cmatpg)),
                .div_int(div_int[j]),
                .div_frac(div_frac[j]),
                .penable(penable[j])
            );
            `ifdef FPGA
                ICG icg(.CK(aclk_buf),.EN(~stall[j]),.SE(cmatpg),.CKG(core_clk[j]));
            `else
                ICG icg(.CK(aclk),.EN(~stall[j]),.SE(cmatpg),.CKG(core_clk[j]));
            `endif
            assign core_id_from_loop[j] = j;
            picorv32 #(
                .ENABLE_COUNTERS(0),
                .ENABLE_COUNTERS64(0),
                .ENABLE_REGS_16_31(1),
                .ENABLE_REGS_DUALPORT(1),
	            .LATCHED_MEM_RDATA(0),
	            .TWO_STAGE_SHIFT(1),
	            .BARREL_SHIFTER(1),
	            .TWO_CYCLE_COMPARE(0),
	            .TWO_CYCLE_ALU(0),
	            .COMPRESSED_ISA(1),
	            .CATCH_MISALIGN(0),
	            .CATCH_ILLINSN(1),
	            .ENABLE_PCPI(0),
	            .ENABLE_MUL(0),
`ifdef ENABLE_MUL
	            .ENABLE_FAST_MUL(1),
`else
	            .ENABLE_FAST_MUL(0),
`endif
	            .ENABLE_DIV(0),
	            .ENABLE_IRQ(0),
	            .ENABLE_IRQ_QREGS(0),
	            .ENABLE_IRQ_TIMER(0),
	            .ENABLE_TRACE(0),
	            .REGS_INIT_ZERO(0),
	            .MASKED_IRQ(32'h 0000_0000),
	            .LATCHED_IRQ(32'h ffff_ffff),
	            .PROGADDR_RESET(0),
	            .PROGADDR_IRQ(32'h 0000_0010),
                .PC_SIZE_BITS(PC_SIZE_BITS),
	            .STACKADDR(MEM_SIZE_BYTES - 1)
            ) core
            (
                .regfifo_rdata_0(regfifo_rdata[0]),
                .regfifo_rdata_1(regfifo_rdata[1]),
                .regfifo_rdata_2(regfifo_rdata[2]),
                .regfifo_rdata_3(regfifo_rdata[3]),
                .regfifo_rd(mach_regfifo_rd[j]),
                .regfifo_wdata(mach_regfifo_wdata[j]),
                .regfifo_wr(mach_regfifo_wr[j]),
                .quanta_halt(quanta_halt[j]),
                .gpio_set(gpio_set[j]),
                .gpio_clr(gpio_clr[j]),
                .gpdir_set(gpdir_set[j]),
                .gpdir_clr(gpdir_clr[j]),
                .gpio_set_valid(gpio_set_valid[j]),
                .gpio_clr_valid(gpio_clr_valid[j]),
                .gpdir_set_valid(gpdir_set_valid[j]),
                .gpdir_clr_valid(gpdir_clr_valid[j]),
                .gpio_pins(gpio_in_maybe_snapped),
                .aggregated_events(aggregated_events),
                .stalling_for_event(stalling_for_event[j]),
                .event_set(event_set[j]),
                .event_set_valid(event_set_valid[j]),
                .event_clr(event_clr[j]),
                .event_clr_valid(event_clr_valid[j]),
                .core_id(core_id_from_loop[j]),
                .clk_count(core_clk_count[j]),

                .clk(core_clk[j]),
                .resetn(reset_n & (~a_restart[j] | cmatpg)),
                .trap(trap[j]),
                .mem_ready(merged_mem_ready[j]),
                .mem_rdata(merged_mem_rdata[j]),
                .mem_la_read(mem_la_read[j]),
                .mem_la_write(mem_la_write[j]),
                .mem_la_addr(mem_la_addr[j]),
                .mem_la_wdata(mem_la_wdata[j]),
                .mem_la_wstrb(mem_la_wstrb[j]),
                .mem_valid(mem_valid[j]),
                .mem_addr(mem_addr[j]),
                .mem_wdata(mem_wdata[j]),
                .mem_wstrb(mem_wstrb[j]),
                .mem_instr(mem_instr[j]),

                // custom pins
                .dbg_pc(dbg_pc[j]),

                // unused pins
                .pcpi_valid(pcpi_valid[j]),
                .pcpi_insn(pcpi_insn[j]),
                .pcpi_rs1(pcpi_rs1[j]),
                .pcpi_rs2(pcpi_rs2[j]),
                .pcpi_wr('0),
                .pcpi_rd('0),
                .pcpi_wait('0),
                .pcpi_ready('0),
	            .irq('0),
	            .eoi(eoi[j]),
                .trace_valid(trace_valid[j]),
                .trace_data(trace_data[j])
            );
        end
    endgenerate
    generate
        for(genvar k = 0; k < 4; k = k + 1) begin: fifos
            regfifo regfifo(
                .reset(reset | (
                        (fifo_to_reset_aclk[k] & do_fifo_clr_aclk | a_restart[k])
                        & ~cmatpg
                    )),
                .aclk(aclk),
                .wdata(regfifo_wdata[k]),
                .we(regfifo_we[k]),
                .writable(regfifo_writable[k]),
                .re(regfifo_re[k]),
                .readable(regfifo_readable[k]),
                .rdata(regfifo_rdata[k]),
                .level(regfifo_level[k])
            );
        end
    endgenerate
endmodule

module priority_demux #(
    parameter DATAW = 32,
    parameter LEVELS = 4
) (
    input [LEVELS-1:0]  stb,
    input [DATAW-1:0]   data_in[LEVELS],
    output logic [DATAW-1:0]  data_out
);
    always_comb begin
        data_out = '0;
        for(int i = LEVELS - 1; i >= 0; i = i - 1) begin: priorities
            if (stb[i]) data_out = data_in[i];
        end
    end
endmodule

module scc_ff #( // set-clear-clobber ff
    parameter RESET = '0,
    parameter WIDTH = 1
) (
    input clk,
    input reset_n,
    input [WIDTH-1:0] set,
    input [WIDTH-1:0] clr,
    input [WIDTH-1:0] clobber,
    input [WIDTH-1:0] value,
    output logic [WIDTH-1:0] q
);
    generate
        for(genvar i = 0; i < WIDTH; i = i + 1) begin: scc_gen
            always_ff @(posedge clk or negedge reset_n) begin
                if (!reset_n) begin
                    q[i] <= RESET[i];
                end else begin
                    if (clobber[i]) begin
                        q[i] <= value[i];
                    end else if (set[i] && !clr[i]) begin
                        q[i] <= 1'b1;
                    end else if (!set[i] && clr[i]) begin
                        q[i] <= 1'b0;
                    end else begin
                        q[i] <= q[i];
                    end
                end
            end
        end
    endgenerate
endmodule

module picorv32_regs_bio #(
    parameter NUM_MACH = 4,
    parameter NUM_MACH_BITS = $clog2(NUM_MACH)
)(
    input [31:0]        regfifo_rdata_0,
    input [31:0]        regfifo_rdata_1,
    input [31:0]        regfifo_rdata_2,
    input [31:0]        regfifo_rdata_3,
    output logic [3:0]  regfifo_rd, // must guarantee one pulse per read, even on successive repeated reads. Machine stalls with pulse asserted if FIFO is empty.
    output logic [31:0] regfifo_wdata,
    output logic [3:0]  regfifo_wr, // must guarantee one pulse per write, even on successive repeated writes. Machine stalls with pulse asserted if FIFO is full.

    output logic  quanta_halt,  // asserted on any write access to r20

    output logic [31:0] gpio_set,
    output logic [31:0] gpio_clr,
    output logic [31:0] gpdir_set,
    output logic [31:0] gpdir_clr,
    output logic  gpio_set_valid,
    output logic  gpio_clr_valid,
    output logic  gpdir_set_valid,
    output logic  gpdir_clr_valid,
    input [31:0]  gpio_pins,

    input [31:0]        aggregated_events,
    output logic        stalling_for_event,
    output logic [23:0] event_set,
    output logic        event_set_valid,
    output logic [23:0] event_clr,
    output logic        event_clr_valid,

    input [NUM_MACH_BITS-1:0]    core_id,
    input [31 - NUM_MACH_BITS:0] clk_count,

	input clk,
    input reset_n,
    input wen,
    input ren1,
    input ren2,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output logic [31:0] rdata1,
	output logic [31:0] rdata2
);
	logic [31:0] regs [0:14];
    logic [31:0] gpio_mask;
    logic [31:0] event_mask;
    logic quanta_wr;
    logic quanta_rd;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) gpio_mask <= 32'hffff_ffff;
        else if (wen & (waddr == 6'd26)) begin
            gpio_mask <= wdata;
        end
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) event_mask <= 32'h0;
        else if (wen & (waddr == 6'd27)) begin
            event_mask <= wdata;
        end
    end
    // register file is X on boot
	always_ff @(posedge clk) begin
		if (wen && (waddr[5:4] == 2'b00)) begin
            regs[~waddr[3:0]] <= wdata;
        end
    end

    assign quanta_halt = quanta_wr || quanta_rd;

    // write path
    always_comb begin
        regfifo_wr = '0;
        quanta_wr = 0;
        gpio_set_valid = 0;
        gpio_clr_valid = 0;
        gpdir_set = '0;
        gpdir_set_valid = 0;
        gpdir_clr_valid = 0;
        event_set_valid = 0;
        event_clr_valid = 0;

        regfifo_wdata = wdata;
        gpio_set = gpio_mask & wdata;
        gpio_clr = gpio_mask & ~wdata; // this is done so we can just bit-shift a stream without inversion to deserialize
        gpdir_set = gpio_mask & wdata;
        gpdir_clr = gpio_mask & wdata; // this is "normal"
        event_set = wdata[23:0]; // can't set or clear FIFO events, so they are masked
        event_clr = wdata[23:0];

        stalling_for_event = ((event_mask & aggregated_events) == 0) && (event_mask != 0) &&
            ((ren1 && (raddr1 == 30)) || (ren2 && (raddr2 == 30)));

        if (wen) begin
            casez (waddr)
                // 0-15 handled in registered path
                6'b0100??: begin // 16-19
                    regfifo_wr[waddr[1:0]] = 1'b1;
                end
                6'b010100: begin // 20
                    quanta_wr = 1;
                end
                6'b010101: begin // 21
                    gpio_set_valid = 1;
                    gpio_clr_valid = 1;
                end
                6'b010110: begin // 22
                    gpio_set_valid = 1;
                end
                6'b010111: begin // 23
                    gpio_clr_valid = 1;
                end
                6'b011000: begin // 24
                    gpdir_set_valid = 1;
                end
                6'b011001: begin // 25
                    gpdir_clr_valid = 1;
                end
                // 26 is handled in registered path
                // 27 is handled in the registered path
                6'b011100: begin // 28
                    event_set_valid = 1;
                end
                6'b011101: begin // 29
                    event_clr_valid = 1;
                end
                // 30 is ignored
                // 31 is ignored
            endcase
        end
    end

    // read path
    always_comb begin
        regfifo_rd = 4'h0;
        rdata1 = 32'h0;
        rdata2 = 32'h0;
        quanta_rd = 0;

        casez (raddr1)
            6'b00????: begin // 0-15
                rdata1 = regs[~raddr1[3:0]];
            end
            6'b010000: begin // 16
                rdata1 = regfifo_rdata_0;
                regfifo_rd[0] = ren1;
            end
            6'b010001: begin // 17
                rdata1 = regfifo_rdata_1;
                regfifo_rd[1] = ren1;
            end
            6'b010010: begin // 18
                rdata1 = regfifo_rdata_2;
                regfifo_rd[2] = ren1;
            end
            6'b010011: begin // 19
                rdata1 = regfifo_rdata_3;
                regfifo_rd[3] = ren1;
            end
            6'b010100: begin // 20
                rdata1 = 0;
                quanta_rd = 1;
            end
            6'b010101: begin // 21
                rdata1 = gpio_pins;
            end
            // 22-25 undefined
            6'b011010: begin // 26
                rdata1 = gpio_mask;
            end
            6'b011011: begin // 27
                rdata1 = event_mask;
            end
            // 28-29 is undefined
            6'b011110: begin // 30
                rdata1 = aggregated_events;
            end
            6'b011111: begin // 31
                rdata1 = {core_id, clk_count};
            end
        endcase

        casez (raddr2)
            6'b00????: begin // 0-15
                rdata2 = regs[~raddr2[3:0]];
            end
            6'b010000: begin // 16
                rdata2 = regfifo_rdata_0;
                regfifo_rd[0] = ren2;
            end
            6'b010001: begin // 17
                rdata2 = regfifo_rdata_1;
                regfifo_rd[1] = ren2;
            end
            6'b010010: begin // 18
                rdata2 = regfifo_rdata_2;
                regfifo_rd[2] = ren2;
            end
            6'b010011: begin // 19
                rdata2 = regfifo_rdata_3;
                regfifo_rd[3] = ren2;
            end
            6'b010100: begin // 20
                rdata2 = 0;
                quanta_rd = 1;
            end
            6'b010101: begin // 21
                rdata2 = gpio_pins;
            end
            // 22-25 undefined
            6'b011010: begin // 26
                rdata2 = gpio_mask;
            end
            6'b011011: begin // 27
                rdata2 = event_mask;
            end
            // 28-29 is undefined
            6'b011110: begin // 30
                rdata2 = aggregated_events;
            end
            6'b011111: begin // 31
                rdata2 = {core_id, clk_count};
            end
        endcase
    end
endmodule

// action + control register. Any write to this register will cause a pulse that
// can trigger an action, while also updating the value of the register
module apb_acr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16,
      parameter IV=32'h0,
      parameter SFRCNT=1,
//      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'hffff_ffff        // read mask to remove undefined bit
//      parameter REXTMASK=32'h0              // read ext mask
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrpaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrprdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        output logic [31:0]                 prdata32    ,
        output logic [0:SFRCNT-1][DW-1:0]   cr          ,
        output bit                          ar
);


    logic[DW-1:0] prdata;
    assign prdata32 = prdata | 32'h0;

    apb_sfr2 #(
            .AW          ( AW            ),
            .DW          ( DW            ),
            .IV          ( IV            ),
            .SFRCNT      ( SFRCNT        ),
            .RMASK       ( RMASK         ),      // read mask to remove undefined bit
            .FRMASK      ( 32'h0         ),      // set write 1 to clr ( for status reg )
            .SRMASK      ( 32'h0         )       // read ext mask
         )apb_sfr(
            .pclk        (pclk           ),
            .resetn      (resetn         ),
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .sfrsr       ('0             ),
            .sfrfr       ('0             ),
            .sfrprdata   (prdata         ),
            .sfrdata     (cr             )
         );

    logic sfrapbwr;
    apb_sfrop2 #(
            .AW          ( AW            )
         )apb_sfrop(
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .apbrd       (               ),
            .apbwr       (sfrapbwr       )
         );
    `theregfull(pclk, resetn, ar, '0) <= sfrapbwr;
endmodule

// action + control register. Any write to this register will cause a pulse that
// can trigger an action, while also updating the value of the register
// this is a "special case" register because the spec requires select bits of one register
// to also be self-clearing, while others are sticky. :-/
module apb_ac2r
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=12,
      parameter IV=32'h0,
      parameter SFRCNT=1,
//      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'h0000_0fff        // read mask to remove undefined bit
//      parameter REXTMASK=32'h0              // read ext mask
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                            sfrlock     ,
        input  bit                            self_clear,
//        input  bit   [AW-1:0]               sfrpaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrprdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        output logic [31:0]                 prdata32    ,
        output logic [0:SFRCNT-1][DW-1:0]   cr          ,
        output bit                          ar
);


    logic[DW-1:0] prdata;
    assign prdata32 = prdata[3:0] | 32'h0;

    logic sfrapbwr;
    logic [7:0] self_clear_bits;
    logic [11:0] regular_bits;
    assign cr = {self_clear_bits[7:0], regular_bits[3:0]};

    always @(posedge pclk or negedge resetn) begin
        if(~resetn)
            self_clear_bits <= 8'h0;
        else begin
            if (self_clear) begin // clear to 0 after the pulse has cleared the synchronizer
                self_clear_bits[7:0] <= 8'h0;
            end else if (ar) begin // load value on write
                self_clear_bits[7:0] <= regular_bits[11:4];
            end else begin // else hold value
                self_clear_bits[7:0] <= self_clear_bits[7:0];
            end
        end
    end

    apb_sfr2 #(
            .AW          ( AW            ),
            .DW          ( DW            ),
            .IV          ( IV            ),
            .SFRCNT      ( SFRCNT        ),
            .RMASK       ( RMASK         ),      // read mask to remove undefined bit
            .FRMASK      ( 32'h0         ),      // set write 1 to clr ( for status reg )
            .SRMASK      ( 32'h0         )       // read ext mask
         )apb_sfr(
            .pclk        (pclk           ),
            .resetn      (resetn         ),
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .sfrsr       ('0             ),
            .sfrfr       ('0             ),
            .sfrprdata   (prdata         ),
            .sfrdata     (regular_bits   )
         );

    apb_sfrop2 #(
            .AW          ( AW            )
         )apb_sfrop(
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .apbrd       (               ),
            .apbwr       (sfrapbwr       )
         );
    `theregfull(pclk, resetn, ar, '0) <= sfrapbwr;
endmodule

// action + status register. Any read to this register will cause a pulse that
// can trigger an action.
module apb_asr
#(
    parameter A=0,
    parameter AW=12,
    parameter DW=16,
    parameter SFRCNT=1,
    parameter RMASK=32'hffff_ffff,        // read mask to remove undefined bit
    parameter SRMASK=32'hffff_ffff              // read ext mask
)(
    input  logic                        pclk        ,
    input  logic                        resetn      ,
    apbif.slavein                       apbs        ,
    input  bit                          sfrlock     ,
    output logic [31:0]                 prdata32    ,
    input  logic [0:SFRCNT-1][DW-1:0]   sr          ,
    output bit                          ar
);
    logic[DW-1:0] prdata;
    assign prdata32 = prdata | 32'h0;

    apb_sfr2 #(
            .AW          ( AW            ),
            .DW          ( DW            ),
            .IV          ( '0            ),
            .SFRCNT      ( SFRCNT        ),
            .RMASK       ( RMASK         ),      // read mask to remove undefined bit
            .FRMASK      ( 32'h0         ),      // set write 1 to clr ( for status reg )
            .SRMASK      ( SRMASK        )       // read ext mask
        ) apb_sfr (
            .pclk        (pclk           ),
            .resetn      (resetn         ),
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .sfrsr       (sr             ),
            .sfrfr       ('0             ),
            .sfrprdata   (prdata         ),
            .sfrdata     (               )
        );

    logic sfrapbrd;
    apb_sfrop2 #(
            .AW          ( AW            )
         )apb_sfrop(
            .apbslave    (apbs           ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (A[AW-1:0]      ),
            .apbrd       (sfrapbrd       ),
            .apbwr       (               )
         );
    `theregfull(pclk, resetn, ar, '0) <= sfrapbrd;
endmodule


/***************************************************************
 * AXI-lite address filter for DMA
 ***************************************************************/

module axil_filter #(
    // number of address ranges to filter
    parameter RANGES=4
)(
	input clk, resetn,

	// AXI4-lite manager interface

	output        m_axi_awvalid,
	input         m_axi_awready,
	output [31:0] m_axi_awaddr,
	output [ 2:0] m_axi_awprot,

	output        m_axi_wvalid,
	input         m_axi_wready,
	output [31:0] m_axi_wdata,
	output [ 3:0] m_axi_wstrb,

	input         m_axi_bvalid,
	output        m_axi_bready,
    input [1:0]   m_axi_bresp,

	output        m_axi_arvalid,
	input         m_axi_arready,
	output [31:0] m_axi_araddr,
	output [ 2:0] m_axi_arprot,

	input         m_axi_rvalid,
	output        m_axi_rready,
	input  [31:0] m_axi_rdata,
    input  [1:0]  m_axi_rresp,

	// AXI4-lite subordinate interface

	input        s_axi_awvalid,
	output       s_axi_awready,
	input [31:0] s_axi_awaddr,
	input [ 2:0] s_axi_awprot,

	input        s_axi_wvalid,
	output       s_axi_wready,
	input [31:0] s_axi_wdata,
	input [ 3:0] s_axi_wstrb,

	output       s_axi_bvalid,
	input        s_axi_bready,
    output [1:0] s_axi_bresp,

	input        s_axi_arvalid,
	output       s_axi_arready,
	input [31:0] s_axi_araddr,
	input [ 2:0] s_axi_arprot,

	output       s_axi_rvalid,
	input        s_axi_rready,
	output [31:0] s_axi_rdata,
    output [1:0] s_axi_rresp,

    // Filter range - these are assumed to be static relative to the AXI data
    // If they are updated during an access, unpredictable things will happen.
    // Granularity of filter is page-level (4096 byte)
    input [19:0] base[RANGES],
    input [19:0] length[RANGES],
    input [31:0] gutter,
    input disable_filter
);
    logic [RANGES-1:0] match_write;
    logic [RANGES-1:0] match_read;
    logic [20:0] bounds_unchecked[RANGES];
    logic [19:0] bounds[RANGES];
    logic allow_write;
    logic allow_read;

    generate
        for(genvar k = 0; k<RANGES; k = k + 1) begin: ranges
            always_comb begin
                // unchecked bounds
                bounds_unchecked[k] = base[k] + length[k];
                // bounds saturated at max_u32
                bounds[k] = bounds_unchecked[k] > 21'h0_FFFF_F ? 20'hFFFF_F : bounds_unchecked[k][19:0];
                match_write[k] = (s_axi_awaddr[31:12] >= base[k]) && (s_axi_awaddr[31:12] < bounds[k]);
                match_read[k] = (s_axi_araddr[31:12] >= base[k]) && (s_axi_araddr[31:12] < bounds[k]);
            end
        end
    endgenerate
    always_comb begin
        allow_write = |match_write | disable_filter;
        allow_read = |match_read | disable_filter;
    end

    assign m_axi_awvalid = s_axi_awvalid;
    assign s_axi_awready = m_axi_awready;
    assign m_axi_awaddr = allow_write ? s_axi_awaddr : gutter;
    assign m_axi_awprot = s_axi_awprot;

    assign m_axi_wvalid = s_axi_wvalid;
    assign s_axi_wready = m_axi_wready;
    assign m_axi_wdata = s_axi_wdata;
    assign m_axi_wstrb = s_axi_wstrb;

    assign s_axi_bvalid = m_axi_bvalid;
    assign m_axi_bready = s_axi_bready;
    assign s_axi_bresp = m_axi_bresp;

    assign m_axi_arvalid = s_axi_arvalid;
    assign s_axi_arready = m_axi_arready;
    assign m_axi_araddr = allow_read ? s_axi_araddr: gutter;
    assign m_axi_arprot = s_axi_arprot;

    assign s_axi_rvalid = m_axi_rvalid;
    assign m_axi_rready = s_axi_rready;
    assign s_axi_rdata = m_axi_rdata;
    assign s_axi_rresp = m_axi_rresp;
endmodule
