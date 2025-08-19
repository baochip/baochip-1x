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

module bio #(
)(
    input logic         aclk,
    input logic         pclk,
    input logic         reset_n,
    input logic         cmatpg, cmbist,

    ioif.drive          bio_gpio[31:0],
    output logic  [3:0] irq, // these can double as dma_req/ack effectively for MDMA

    apbif.slavein       apbs,
    apbif.slave         apbx
);
    localparam NUM_MACH = 4;
    localparam MEM_SIZE_BYTES = 32'h1000;
    localparam MEM_SIZE_WORDS = 32'h1000 / 4;
    localparam MEM_ADDR_BITS = $clog2(MEM_SIZE_WORDS);

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

    // Memory interfaces
	// logic [NUM_MACH-1:0]       mem_valid;
	// logic [NUM_MACH-1:0]       mem_instr;
	logic [NUM_MACH-1:0]       mem_ready;

	// logic [31:0] mem_addr   [NUM_MACH];
	// logic [31:0] mem_wdata  [NUM_MACH];
	// logic [ 3:0] mem_wstrb  [NUM_MACH];
	logic [31:0] mem_rdata    [NUM_MACH];

	// Look-Ahead Interface
	logic        mem_la_read  [NUM_MACH];
	logic        mem_la_write [NUM_MACH];
	logic [31:0] mem_la_addr  [NUM_MACH];
	logic [31:0] mem_la_wdata [NUM_MACH];
	logic [ 3:0] mem_la_wstrb [NUM_MACH];

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
    logic [23:0] host_event_clr;
    logic host_event_clr_valid;

    logic [29:0] core_clk_count [NUM_MACH];

    // modes
    logic [NUM_MACH-1:0]   en;
    logic [NUM_MACH-1:0]   en_sync; // enable has to be synchronized to the ar bit so it hits when clkdivreset, restart hits
    logic                  imem_wr_mode;

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
    logic [31:0] fdout      [NUM_MACH];
    logic [3:0] push;
    logic [3:0] pull;
    logic [3:0] fifo_to_reset;
    logic do_fifo_clr;

    /////////////////////// register bank
    // nc fields
    wire ctl_action_sync_ack;
    // synchronizers for .ar pulses
    logic ctl_action_sync;
    logic [3:0] push_sync;
    logic [3:0] pull_sync;
    logic [24:0] pclk_event_set;
    logic pclk_event_set_valid;
    logic [24:0] pclk_event_clr;
    logic pclk_event_clr_valid;
    logic ctl_action;
    logic [3:0] fifo_to_reset_aclk;
    logic do_fifo_clr_aclk;
    logic [31:0] host_mem_rdata_pclk;
    logic [3:0]  pclk_regfifo_level [4];
    always_ff @(posedge pclk) begin
        pclk_regfifo_level <= regfifo_level;
        fdout <= regfifo_rdata;
        pclk_event_status <= aggregated_events;
    end
    always_ff @(posedge aclk) begin
        fdin_sync <= fdin;
        host_fifo_event_level <= fifo_event_level;
        host_fifo_event_eq_mask <= fifo_event_eq_mask;
        host_fifo_event_lt_mask <= fifo_event_lt_mask;
        host_fifo_event_gt_mask <= fifo_event_gt_mask;
        host_event_set <= pclk_event_set;
        host_event_clr <= pclk_event_clr;
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
            host_mem_rdata_pclk
            ;

    apb_ac2r #(.A('h00), .DW(12))    sfr_ctrl             (.cr({clkdiv_restart, restart, en}), .ar(ctl_action), .self_clear(ctl_action_sync_ack), .prdata32(),.*);
    apb_sr  #(.A('h04), .DW(32))     sfr_cfginfo          (.sr({16'd4096, 8'd4, 8'd8}), .prdata32(),.*);
    apb_cr  #(.A('h08), .DW(6))      sfr_config           (.cr({snap_input_to_quantum, snap_input_to_which,
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

    cdc_blinded       ctl_action_cdc     (.reset(reset), .clk_a(pclk), .clk_b(aclk), .in_a(ctl_action            ), .out_b(ctl_action_sync            ));
    cdc_blinded       ctl_action_ack_cdc (.reset(reset), .clk_a(aclk), .clk_b(pclk), .in_a(ctl_action_sync       ), .out_b(ctl_action_sync_ack        ));
    cdc_blinded       push_cdc[3:0]      (.reset(reset), .clk_a(pclk), .clk_b(aclk), .in_a(push                  ), .out_b(push_sync                  ));
    cdc_blinded       pull_cdc[3:0]      (.reset(reset), .clk_a(pclk), .clk_b(aclk), .in_a(pull                  ), .out_b(pull_sync                  ));
    cdc_blinded       event_set_cdc      (.reset(reset), .clk_a(pclk), .clk_b(aclk), .in_a(pclk_event_set_valid  ), .out_b(host_event_set_valid       ));
    cdc_blinded       event_clr_cdc      (.reset(reset), .clk_a(pclk), .clk_b(aclk), .in_a(pclk_event_clr_valid  ), .out_b(host_event_clr_valid       ));
    cdc_blinded       fifo_clr_cdc       (.reset(reset), .clk_a(pclk), .clk_b(aclk), .in_a(do_fifo_clr           ), .out_b(do_fifo_clr_aclk           ));

    /////////////////////// machine instantiation & instruction memory
    assign reset = ~reset_n;
    assign resetn = reset_n;

    logic ram_wr_en;
    logic [3:0] ram_wr_mask;
    logic [MEM_ADDR_BITS-1:0] ram_wr_addr;
    logic [MEM_ADDR_BITS-1:0] ram_rd_addr[NUM_MACH];
    logic [31:0] ram_wr_data;
    logic [31:0] host_mem_wdata_sync[2];
    logic [31:0] host_mem_wdata;
    logic host_mem_wr_stb;
    logic host_mem_wr;
    logic host_mem_wr_d;
    logic host_mem_rd_stb;
    logic host_mem_rd;
    logic host_mem_rd_d;
    logic [1:0] psel_sync;
    logic [1:0] pwrite_sync;
    logic [1:0] penable_sync;
    logic [MEM_ADDR_BITS:0] host_mem_addr_sync[2];
    logic [MEM_ADDR_BITS:0] host_mem_addr;
    logic [31:0] host_mem_rdata_capture;
    logic [31:0] host_mem_rdata;

    logic [31:0] ram_rd_data [NUM_MACH];
    logic ram_rd_enable [NUM_MACH];

    assign imem_wr_mode = en_sync[0]; // when machine 0 is disabled, the host can use its port to read/write
    // mux on port 0 of imem between host and machines
    always_comb begin
        ram_wr_en = 0;
        ram_rd_enable[0] = 0;
        host_mem_wr_d = psel_sync[1] & pwrite_sync[1] & penable_sync[1];
        host_mem_rd_d = psel_sync[1] & !pwrite_sync[1];

        if (imem_wr_mode) begin
            // machine0 is running
            ram_wr_en = mem_la_write[0];
            ram_wr_mask = mem_la_wstrb[0];
            ram_wr_data = mem_la_wdata[0];
            ram_wr_addr = mem_la_addr[0][MEM_ADDR_BITS+2:2];

            ram_rd_addr[0] = mem_la_addr[0][MEM_ADDR_BITS+2:2];
            ram_rd_enable[0] = mem_la_read[0];
        end else begin
            // host can write & read
            if (host_mem_addr_sync[1][MEM_ADDR_BITS] == 1) begin // memory is mapped to page above the register interface
                ram_wr_en = host_mem_wr_stb;
            end
            ram_wr_mask = 4'b1111; // only full 32-bit writes are allowed, anything else is undefined
            ram_wr_data = host_mem_wdata;
            ram_wr_addr = host_mem_addr;

            ram_rd_addr[0] = host_mem_addr;
            if (host_mem_addr_sync[1][MEM_ADDR_BITS] == 1) begin
                ram_rd_enable[0] = host_mem_rd_d;
            end
        end
        ram_rd_addr[1] = mem_la_addr[1][MEM_ADDR_BITS+2:2];
        ram_rd_addr[2] = mem_la_addr[2][MEM_ADDR_BITS+2:2];
        ram_rd_addr[3] = mem_la_addr[3][MEM_ADDR_BITS+2:2];
        ram_rd_enable[1:3] = mem_la_read[1:3];
    end
    // apb<->imem
    always_ff @(posedge aclk) begin
        // cdc syncs
        psel_sync[0] <= apbs.psel;
        psel_sync[1] <= psel_sync[0];
        pwrite_sync[0] <= apbs.pwrite;
        pwrite_sync[1] <= pwrite_sync[0];
        penable_sync[0] <= apbs.penable;
        penable_sync[1] <= penable_sync[0];
        host_mem_wdata_sync[0] <= apbs.pwdata;
        host_mem_wdata_sync[1] <= host_mem_wdata_sync[0];
        host_mem_addr_sync[0] <= apbs.paddr[MEM_ADDR_BITS+2:2]; // extract word-level address here
        host_mem_addr_sync[1] <= host_mem_addr_sync[0];

        host_mem_wr <= host_mem_wr_d;
        host_mem_wr_stb <= host_mem_wr_d & !host_mem_wr;
        host_mem_addr <= host_mem_wr_d & !host_mem_wr ? host_mem_addr_sync[1][MEM_ADDR_BITS-1:0] : host_mem_addr;
        host_mem_wdata <= host_mem_wr_d & !host_mem_wr ? host_mem_wdata_sync[1] : host_mem_wdata;

        host_mem_rd <= host_mem_rd_d;
        host_mem_rd_stb <= host_mem_rd_d & !host_mem_rd;

        host_mem_rdata_capture <= (host_mem_rd_d & !host_mem_rd) ? ram_rd_data[0] : host_mem_rdata_capture;
    end
    // convert rdata to pclk domain
    always_ff @(posedge pclk) begin
        host_mem_rdata <= host_mem_rdata_capture;
    end
    // only assert when selected, and the high bit of the address range is set
    always_comb begin
        host_mem_rdata_pclk = apbs.psel & apbs.penable & ~apbs.pwrite & (apbs.paddr[12] == 1'b1) ? host_mem_rdata : '0;
    end
    // imem
    Ram_1w_4rs #(
        .wordCount(MEM_SIZE_WORDS),
        .wordWidth(32),
        .clockCrossing(1'b0),
        .technology("auto"),
        .readUnderWrite("dontCare"),
        .wrAddressWidth(MEM_ADDR_BITS),
        .wrDataWidth(32),
        .wrMaskWidth(4),
        .wrMaskEnable(1),
        .rdAddressWidth(MEM_ADDR_BITS),
        .rdDataWidth(32),
        .ramname("RAM_QP_1024_32")
    ) imem (
        .wr_clk(aclk),
        .wr_en(ram_wr_en),
        .wr_addr(ram_wr_addr),
        .wr_mask(ram_wr_mask),
        .wr_data(ram_wr_data),
        .rd_clk(aclk),
        .rd_en(ram_rd_enable),
        .rd_addr(ram_rd_addr),
        .rd_data(ram_rd_data),
        .cmbist(cmbist),
        .cmatpg(cmatpg)
    );
    assign mem_rdata = ram_rd_data;
    always_ff @(posedge aclk) begin
        mem_ready[0] <= ram_wr_en || ram_rd_enable[0] || quanta_halt[0] && mem_ready[0];
        mem_ready[1] <= ram_rd_enable[1] || quanta_halt[1] && mem_ready[1];
        mem_ready[2] <= ram_rd_enable[2] || quanta_halt[2] && mem_ready[2];
        mem_ready[3] <= ram_rd_enable[3] || quanta_halt[3] && mem_ready[3];
    end

    // machine stall signal
    generate
        for(genvar j = 0; j < NUM_MACH; j = j + 1) begin: stalls
            always_comb begin
                extclk_selected[j] = gpio_in_cleaned[extclk_gpio_aclk[j]];
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
                extclk_selected_q <= extclk_selected;
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
                    push_sync[k]
                }),
                .data_in({
                    fdin_sync[k],
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
                    push_sync[k]
                }),
                .data_in({
                    push_sync[k],
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
                    pull_sync[k]
                }),
                .data_in({
                    pull_sync[k],
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
    priority_demux #(
        .DATAW(24),
        .LEVELS(5)
    ) event_set_aggregator (
        .stb({event_set_valid, host_event_set_valid}),
        .data_in({host_event_set, event_set[0], event_set[1], event_set[2], event_set[3]}),
        .data_out(event_set_agg)
    );
    priority_demux #(
        .DATAW(24),
        .LEVELS(5)
    ) event_clr_aggregator (
        .stb({event_clr_valid, host_event_clr_valid}),
        .data_in({host_event_clr, event_clr[0], event_clr[1], event_clr[2], event_clr[3]}),
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
    // add metastability hardening, with optional bypass path
    always @(posedge aclk) begin
        gpio_in_sync0 <= gpio_in;
        gpio_in_sync1 <= gpio_in_sync0;
    end
    generate
        for(genvar m = 0; m < 32; m = m + 1) begin: gen_bypass
            assign gpio_in_cleaned[m] = sync_bypass[m] ? gpio_in[m] : gpio_in_sync1[m];
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

    /////////////////////// repeated core units
    `ifdef FPGA
        logic aclk_buf;
        // insert a BUFH to help with clock mux distribution
        BUFH aclk_fixer (
            .I(aclk),
            .O(aclk_buf)
        );
    `endif
    generate
        for(genvar j = 0; j < NUM_MACH; j = j + 1) begin: mach
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
                .reset(reset | clkdiv_restart[j]),
                .div_int(div_int[j]),
                .div_frac(div_frac[j]),
                .penable(penable[j])
            );
            `ifdef FPGA
                ICG icg(.CK(aclk_buf),.EN(~stall[j]),.SE(cmatpg),.CKG(core_clk[j]));
            `else
                ICG icg(.CK(aclk),.EN(~stall[j]),.SE(cmatpg),.CKG(core_clk[j]));
            `endif
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
	            .ENABLE_FAST_MUL(0),
	            .ENABLE_DIV(0),
	            .ENABLE_IRQ(0),
	            .ENABLE_IRQ_QREGS(0),
	            .ENABLE_IRQ_TIMER(0),
	            .ENABLE_TRACE(0),
	            .REGS_INIT_ZERO(0),
	            .MASKED_IRQ(32'h 0000_0000),
	            .LATCHED_IRQ(32'h ffff_ffff),
	            .PROGADDR_RESET(j * 4),
	            .PROGADDR_IRQ(j * 4 + 32'h 0000_0010),
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
                .core_id(j),
                .clk_count(core_clk_count[j]),

                .clk(core_clk[j]),
                .resetn(reset_n & ~a_restart[j]),
                .trap(trap[j]),
                .mem_ready(mem_ready[j]),
                .mem_rdata(mem_rdata[j]),
                .mem_la_read(mem_la_read[j]),
                .mem_la_write(mem_la_write[j]),
                .mem_la_addr(mem_la_addr[j]),
                .mem_la_wdata(mem_la_wdata[j]),
                .mem_la_wstrb(mem_la_wstrb[j]),

                // unused pins
                .mem_valid(),
                .mem_instr(),
                .mem_addr(),
                .mem_wdata(),
                .mem_wstrb(),
                .pcpi_valid(),
                .pcpi_insn(),
                .pcpi_rs1(),
                .pcpi_rs2(),
                .pcpi_wr('0),
                .pcpi_rd('0),
                .pcpi_wait('0),
                .pcpi_ready('0),
	            .irq('0),
	            .eoi(),
                .trace_valid(),
                .trace_data()
            );
        end
    endgenerate
    generate
        for(genvar k = 0; k < 4; k = k + 1) begin: fifos
            regfifo regfifo(
                .reset(reset | fifo_to_reset_aclk[k] & do_fifo_clr_aclk),
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
        event_set = wdata[24:0]; // can't set or clear FIFO events, so they are masked
        event_clr = wdata[24:0];

        stalling_for_event = ((event_mask & aggregated_events) != event_mask) && (event_mask != 0) &&
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
//      parameter IV=32'h0,                   // useless
      parameter SFRCNT=1,
//      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'hffff_ffff,        // read mask to remove undefined bit
      parameter SRMASK=32'hffff_ffff              // read ext mask
)(
        input  logic                          pclk        ,
        input  logic                          resetn      ,
        apbif.slavein                         apbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrpaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrprdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
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
         )apb_sfr(
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
