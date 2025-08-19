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

module udma_scif #(
    parameter L2_AWIDTH_NOAL = 12,
    parameter TRANS_SIZE     = 16
) (
    input  logic                      sys_clk_i,
    input  logic                      periph_clk_i,
	input  logic   	                  sys_rstn_i,
	input  logic   	                  per_rstn_i,
    input  logic                      dft_i,

//	input  logic                      scif_rx_i,
//	output logic                      scif_tx_o,

    output logic                      rx_char_event_o,
    output logic                      err_event_o,

    input  logic                      scif_sck_i  ,
    output logic                      scif_sck_o  ,
    output logic                      scif_sck_oe ,
    input  logic                      scif_dat_i  ,
    output logic                      scif_dat_o  ,
    output logic                      scif_dat_oe ,

	input  logic               [31:0] cfg_data_i,
	input  logic                [4:0] cfg_addr_i,
	input  logic                      cfg_valid_i,
	input  logic                      cfg_rwn_i,
	output logic                      cfg_ready_o,
    output logic               [31:0] cfg_data_o,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_rx_size_o,
    output logic                [1:0] cfg_rx_datasize_o,
    output logic                      cfg_rx_continuous_o,
    output logic                      cfg_rx_en_o,
    output logic                      cfg_rx_clr_o,
    input  logic                      cfg_rx_en_i,
    input  logic                      cfg_rx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_rx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_rx_bytes_left_i,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_tx_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_tx_size_o,
    output logic                [1:0] cfg_tx_datasize_o,
    output logic                      cfg_tx_continuous_o,
    output logic                      cfg_tx_en_o,
    output logic                      cfg_tx_clr_o,
    input  logic                      cfg_tx_en_i,
    input  logic                      cfg_tx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_tx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_tx_bytes_left_i,

    output logic                      data_tx_req_o,
    input  logic                      data_tx_gnt_i,
    output logic                [1:0] data_tx_datasize_o,
    input  logic               [31:0] data_tx_i,
    input  logic                      data_tx_valid_i,
    output logic                      data_tx_ready_o,

    output logic                [1:0] data_rx_datasize_o,
    output logic               [31:0] data_rx_o,
    output logic                      data_rx_valid_o,
    input  logic                      data_rx_ready_i

);

    logic               [1:0]  s_scif_status;
    logic                      s_scif_stop_bits;
    logic                      s_scif_parity_en;
    logic              [15:0]  s_scif_div, s_scif_edu;
    logic               [1:0]  s_scif_clksel;
    logic               [1:0]  s_scif_bits;
    logic                      s_scif_rx_clean_fifo;
    logic                      s_scif_rx_polling_en;
    logic                      s_scif_rx_irq_en;
    logic                      s_scif_err_irq_en;
    logic                      s_scif_en_rx;
    logic                      s_scif_en_tx;
    logic                      s_data_rx_ready_mux;
    logic                      s_data_rx_ready;

    logic         s_data_tx_valid;
    logic         s_data_tx_ready;
    logic   [7:0] s_data_tx;
    logic         s_data_tx_dc_valid;
    logic         s_data_tx_dc_ready;
    logic   [7:0] s_data_tx_dc;
    logic         s_data_rx_dc_valid;
    logic         s_data_rx_dc_ready;
    logic   [7:0] s_data_rx_dc;

    logic         r_scif_stop_bits;
    logic         r_scif_parity_en;
    logic [15:0]  r_scif_div, r_scif_etu;
    logic  [1:0]  r_scif_clksel;
    logic  [1:0]  r_scif_bits;

    logic  [2:0]  r_scif_en_rx_sync;
    logic  [2:0]  r_scif_en_tx_sync;

    logic         s_scif_tx_sample;
    logic         s_scif_rx_sample;

    logic [1:0] [1:0] r_status_sync;

    logic         s_err_rx_overflow;
    logic         s_err_rx_overflow_sync;
    logic         s_err_rx_parity;
    logic         s_err_rx_parity_sync;
    logic         s_rx_char_event;
    logic         s_rx_char_event_sync;

    logic         s_sys_combo_rstn;
    logic         s_per_combo_rstn;

    assign cfg_tx_datasize_o  = 2'b00;
    assign cfg_rx_datasize_o  = 2'b00;
    assign data_tx_datasize_o = 2'b00;
    assign data_rx_datasize_o = 2'b00;

    assign err_event_o = (s_err_rx_overflow_sync | s_err_rx_parity_sync) & s_scif_err_irq_en;
    assign rx_char_event_o = s_rx_char_event_sync & s_scif_rx_irq_en & ~s_scif_rx_polling_en;

    udma_scif_reg_if #(
        .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
        .TRANS_SIZE(TRANS_SIZE)
    ) u_reg_if (
        .clk_i              ( sys_clk_i           ),
        .rstn_i             ( sys_rstn_i          ),

        .cfg_data_i         ( cfg_data_i          ),
        .cfg_addr_i         ( cfg_addr_i          ),
        .cfg_valid_i        ( cfg_valid_i         ),
        .cfg_rwn_i          ( cfg_rwn_i           ),
        .cfg_ready_o        ( cfg_ready_o         ),
        .cfg_data_o         ( cfg_data_o          ),

        .cfg_rx_startaddr_o ( cfg_rx_startaddr_o  ),
        .cfg_rx_size_o      ( cfg_rx_size_o       ),
        .cfg_rx_continuous_o( cfg_rx_continuous_o ),
        .cfg_rx_en_o        ( cfg_rx_en_o         ),
        .cfg_rx_clr_o       ( cfg_rx_clr_o        ),
        .cfg_rx_en_i        ( cfg_rx_en_i         ),
        .cfg_rx_pending_i   ( cfg_rx_pending_i    ),
        .cfg_rx_curr_addr_i ( cfg_rx_curr_addr_i  ),
        .cfg_rx_bytes_left_i( cfg_rx_bytes_left_i ),

        .cfg_tx_startaddr_o ( cfg_tx_startaddr_o  ),
        .cfg_tx_size_o      ( cfg_tx_size_o       ),
        .cfg_tx_continuous_o( cfg_tx_continuous_o ),
        .cfg_tx_en_o        ( cfg_tx_en_o         ),
        .cfg_tx_clr_o       ( cfg_tx_clr_o        ),
        .cfg_tx_en_i        ( cfg_tx_en_i         ),
        .cfg_tx_pending_i   ( cfg_tx_pending_i    ),
        .cfg_tx_curr_addr_i ( cfg_tx_curr_addr_i  ),
        .cfg_tx_bytes_left_i( cfg_tx_bytes_left_i ),

        .rx_data_i          ( data_rx_o[7:0]      ),
        .rx_valid_i         ( data_rx_valid_o     ), // Pay attention to clock domain
        .rx_ready_o         ( s_data_rx_ready     ), // Pay attention to clock domain

        .status_i           ( r_status_sync[1]    ),
        .err_parity_i       ( s_err_rx_parity_sync   ),
        .err_overflow_i     ( s_err_rx_overflow_sync ),
        .stop_bits_o        ( s_scif_stop_bits    ),
        .parity_en_o        ( s_scif_parity_en    ),
        .divider_o          ( s_scif_div          ),
        .etu_o              ( s_scif_edu          ),
        .clksel_o           ( s_scif_clksel       ),
        .num_bits_o         ( s_scif_bits         ),
        .rx_clean_fifo_o    ( s_scif_rx_clean_fifo ),
        .rx_polling_en_o    ( s_scif_rx_polling_en ),
        .rx_irq_en_o        ( s_scif_rx_irq_en    ),
        .err_irq_en_o       ( s_scif_err_irq_en   ),
        .en_rx_o			( s_scif_en_rx        ),
        .en_tx_o			( s_scif_en_tx        )
    );


    // clksel = 2'h1, scd mode, use scif_sck_i
    // clksel = 2'h2, scc mode, use periph_clk_i with div

    logic clkscif;
    logic clkscd, clkscc;
    logic [2:0] clksel_scdregs, clksel_sccregs;
    logic clkscden, clksccen;
    logic [15:0] clksccdivcnt;

    logic scif_sck_dft, clkscif_undft, scif_sck_dft_unbuf;
    assign scif_sck_dft_unbuf = dft_i ? periph_clk_i : scif_sck_i;
    CLKCELL_BUF buf_scif_sck_dft(.A(scif_sck_dft_unbuf),.Z(scif_sck_dft));

    always@(posedge scif_sck_dft or negedge per_rstn_i)
    if(~per_rstn_i)
        clksel_scdregs <= '0;
    else
        clksel_scdregs <= { clksel_scdregs, s_scif_clksel[0] };

    assign clkscden = clksel_scdregs[2];

    ICG uclkscd ( .CK (scif_sck_dft), .EN ( clkscden ), .SE(dft_i), .CKG ( clkscd ));
    assign clkscif_undft = clkscc | clkscd;

    CLKCELL_MUX2 u_clkscif (.A(clkscif_undft),.B(periph_clk_i),.S(dft_i),.Z(clkscif));

    always@(posedge periph_clk_i or negedge per_rstn_i)
    if(~per_rstn_i)
        clksel_sccregs <= '0;
    else
        clksel_sccregs <= { clksel_sccregs, s_scif_clksel[1] };

    assign clksccen = clksel_sccregs[2];

    always@(posedge periph_clk_i or negedge per_rstn_i )
    if(~per_rstn_i)begin
        clksccdivcnt <= '0;
        clkscc <= '0;
    end
    else begin
        clksccdivcnt <= ( clksccdivcnt == s_scif_div ) ? '0 : clksccdivcnt + clksccen;
        clkscc <= ( clksccdivcnt == r_scif_div/2 ) & clksccen ? 1'b1 : ( clksccdivcnt == r_scif_div ) ? 1'b0 : clkscc;
    end

    assign scif_sck_o = clksccen & clkscc;
    `theregfull( sys_clk_i, sys_rstn_i, scif_sck_oe, '0 ) <= ( s_scif_clksel == 2'h2 );


    logic s_scif_tx_sample2, s_scif_rx_sample2;
    logic  [2:0]  r_scif_en_rx_sync2;
    logic  [2:0]  r_scif_en_tx_sync2;

    assign s_scif_tx_sample2 = r_scif_en_tx_sync2[1] & ! r_scif_en_tx_sync2[2];
    assign s_scif_rx_sample2 = r_scif_en_rx_sync2[1] & ! r_scif_en_rx_sync2[2];

    always_ff @(posedge periph_clk_i or negedge per_rstn_i)
    begin
        if(~per_rstn_i) begin
            r_scif_en_tx_sync2 <= 0;
            r_scif_en_rx_sync2 <= 0;
            r_scif_div <= '0;
        end else begin
            r_scif_en_tx_sync2 <= {r_scif_en_tx_sync2[1:0],s_scif_en_tx};
            r_scif_en_rx_sync2 <= {r_scif_en_rx_sync2[1:0],s_scif_en_rx};
            if(s_scif_tx_sample2 || s_scif_rx_sample2)
            begin
                r_scif_div        <= s_scif_div;
            end
        end
    end



    io_tx_fifo #(
      .DATA_WIDTH(8),
      .BUFFER_DEPTH(2)
      ) u_fifo (
        .clk_i   ( sys_clk_i       ),
        .rstn_i  ( sys_rstn_i      ),
        .clr_i   ( 1'b0            ),
        .data_o  ( s_data_tx       ),
        .valid_o ( s_data_tx_valid ),
        .ready_i ( s_data_tx_ready ),
        .req_o   ( data_tx_req_o   ),
        .gnt_i   ( data_tx_gnt_i   ),
        .valid_i ( data_tx_valid_i ),
        .data_i  ( data_tx_i[7:0]  ),
        .ready_o ( data_tx_ready_o )
    );

    udma_dc_fifo #(8,4) u_dc_fifo_tx
    (
        .src_clk_i    ( sys_clk_i          ),
        .src_rstn_i   ( sys_rstn_i         ),
        .src_data_i   ( s_data_tx          ),
        .src_valid_i  ( s_data_tx_valid    ),
        .src_ready_o  ( s_data_tx_ready    ),
        .dst_clk_i    ( clkscif            ),
        .dst_rstn_i   ( per_rstn_i         ),
        .dst_data_o   ( s_data_tx_dc       ),
        .dst_valid_o  ( s_data_tx_dc_valid ),
        .dst_ready_i  ( s_data_tx_dc_ready )
    );

    udma_scif_tx u_scif_tx(
        .clk_i           ( clkscif            ),
        .rstn_i          ( per_rstn_i         ),
        .tx_o            ( scif_dat_o         ),
        .tx_oe           ( scif_dat_oe        ),
        .busy_o          ( s_scif_status[0]   ),
        .cfg_en_i        ( r_scif_en_tx_sync[2] ),
		.cfg_div_i       ( r_scif_etu         ),
		.cfg_parity_en_i ( r_scif_parity_en   ),
		.cfg_bits_i      ( r_scif_bits        ),
		.cfg_stop_bits_i ( r_scif_stop_bits   ),
		.tx_data_i       ( s_data_tx_dc       ),
		.tx_valid_i      ( s_data_tx_dc_valid ),
		.tx_ready_o      ( s_data_tx_dc_ready )
    );

    assign s_sys_combo_rstn = dft_i ?  sys_rstn_i : sys_rstn_i & ~s_scif_rx_clean_fifo;
    assign s_per_combo_rstn = dft_i ?  per_rstn_i : per_rstn_i & ~s_scif_rx_clean_fifo;

    udma_dc_fifo #(8,4) u_dc_fifo_rx
    (
        .src_clk_i    ( clkscif            ),
        .src_rstn_i   ( s_per_combo_rstn   ),
        .src_data_i   ( s_data_rx_dc       ),
        .src_valid_i  ( s_data_rx_dc_valid ),
        .src_ready_o  ( s_data_rx_dc_ready ),
        .dst_clk_i    ( sys_clk_i          ),
        .dst_rstn_i   ( s_sys_combo_rstn   ),
        .dst_data_o   ( data_rx_o[7:0]     ),
        .dst_valid_o  ( data_rx_valid_o    ),
        .dst_ready_i  ( s_data_rx_ready_mux    )
    );

   assign s_data_rx_ready_mux = (s_scif_rx_irq_en | s_scif_rx_polling_en) ? s_data_rx_ready : data_rx_ready_i;

    udma_scif_rx u_scif_rx(
        .clk_i           ( clkscif            ),
        .rstn_i          ( per_rstn_i         ),
		.rx_i            ( scif_dat_i         ),
        .busy_o          ( s_scif_status[1]   ),
        .cfg_en_i        ( r_scif_en_rx_sync[2] ),
		.cfg_div_i       ( r_scif_etu         ),
		.cfg_parity_en_i ( r_scif_parity_en   ),
		.cfg_bits_i      ( r_scif_bits        ),
		.cfg_stop_bits_i ( r_scif_stop_bits   ),
        .err_parity_o    ( s_err_rx_parity    ),
        .err_overflow_o  ( s_err_rx_overflow  ),
        .char_event_o    ( s_rx_char_event    ),
		.rx_data_o       ( s_data_rx_dc       ),
		.rx_valid_o      ( s_data_rx_dc_valid ),
		.rx_ready_i      ( s_data_rx_dc_ready )
    );

    edge_propagator i_ep_err_overflow (
        .clk_tx_i(clkscif),
        .rstn_tx_i(per_rstn_i),
        .edge_i(s_err_rx_overflow),
        .clk_rx_i(sys_clk_i),
        .rstn_rx_i(sys_rstn_i),
        .edge_o(s_err_rx_overflow_sync)
    );

    edge_propagator i_ep_err_parity (
        .clk_tx_i(clkscif),
        .rstn_tx_i(per_rstn_i),
        .edge_i(s_err_rx_parity),
        .clk_rx_i(sys_clk_i),
        .rstn_rx_i(sys_rstn_i),
        .edge_o(s_err_rx_parity_sync)
    );

    edge_propagator i_ep_event (
        .clk_tx_i(clkscif),
        .rstn_tx_i(per_rstn_i),
        .edge_i(s_rx_char_event),
        .clk_rx_i(sys_clk_i),
        .rstn_rx_i(sys_rstn_i),
        .edge_o(s_rx_char_event_sync)
    );


    assign s_scif_tx_sample = r_scif_en_tx_sync[1] & ! r_scif_en_tx_sync[2];
    assign s_scif_rx_sample = r_scif_en_rx_sync[1] & ! r_scif_en_rx_sync[2];

    always_ff @(posedge sys_clk_i or negedge sys_rstn_i)
    begin
        if(~sys_rstn_i)
        begin
            r_status_sync <= 0;
        end
        else
        begin
            r_status_sync[0] <= s_scif_status;
            r_status_sync[1] <= r_status_sync[0];
        end
    end

    always_ff @(posedge clkscif or negedge per_rstn_i)
    begin
        if(~per_rstn_i) begin
            r_scif_en_tx_sync <= 0;
            r_scif_en_rx_sync <= 0;
//            r_scif_div        <= 0;
            r_scif_etu        <= 0;
            r_scif_parity_en  <= 0;
            r_scif_bits       <= 0;
            r_scif_stop_bits  <= 0;
        end else begin
            r_scif_en_tx_sync <= {r_scif_en_tx_sync[1:0],s_scif_en_tx};
            r_scif_en_rx_sync <= {r_scif_en_rx_sync[1:0],s_scif_en_rx};
            if(s_scif_tx_sample || s_scif_rx_sample)
            begin
//                r_scif_div        <= s_scif_div;
                r_scif_etu        <= s_scif_edu;
                r_scif_parity_en  <= s_scif_parity_en;
                r_scif_bits       <= s_scif_bits;
                r_scif_stop_bits  <= s_scif_stop_bits;
            end
        end
    end

    assign data_rx_o[31:8] = 'h0;

endmodule // udma_scif_top
