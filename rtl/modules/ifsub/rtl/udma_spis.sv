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

module udma_spis #(
    parameter L2_AWIDTH_NOAL = 12,
    parameter TRANS_SIZE     = 16
) (
    input  logic                      sys_clk_i,
    //input  logic                      periph_clk_i, // not used
	input  logic   	                  rstn_i,
    input  logic                      cmsatpg,
    input  logic                      spis_clk_i   ,
    input  logic                      spis_cs_i    ,
    input  logic                      spis_mosi_i  ,
    output logic                      spis_miso_o  ,
    output logic                      spis_miso_oe ,

    output logic                      seot_event_o,
//    output logic                      rx_char_event_o,
//    output logic                      err_event_o,

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
// dummy
    logic                      spis_rx_i;
    logic                      spis_tx_o;
    logic                      rx_char_event_o;

    assign spis_rx_i = '1;
//    logic                      spis_clk_i   ;
//    logic                      spis_cs_i    ;
//    logic                      spis_mosi_i  ;
//    logic                      spis_miso_o  ;
//    logic                      spis_miso_oe ;

//    assign spis_miso_o = '1;
//    assign spis_miso_oe = '0;

// dummy end

    logic               [1:0]  s_spis_status;
    logic                      s_spis_stop_bits;
    logic                      s_spis_parity_en;
    logic              [15:0]  s_spis_div;
    logic               [1:0]  s_spis_bits;
    logic                      s_spis_rx_clean_fifo;
    logic                      s_spis_rx_polling_en;
    logic                      s_spis_rx_irq_en;
    logic                      s_spis_err_irq_en;
    logic                      s_spis_en_rx;
    logic                      s_spis_en_tx;
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

    logic         r_spis_stop_bits;
    logic         r_spis_parity_en;
    logic [15:0]  r_spis_div;
    logic  [1:0]  r_spis_bits;

    logic  [2:0]  r_spis_en_rx_sync;
    logic  [2:0]  r_spis_en_tx_sync;

    logic         s_spis_tx_sample;
    logic         s_spis_rx_sample;

    logic [1:0] [1:0] r_status_sync;

    logic         s_err_rx_overflow;
    logic         s_err_rx_overflow_sync;
    logic         s_err_rx_parity;
    logic         s_err_rx_parity_sync;
    logic         s_rx_char_event;
    logic         s_seot_sync;

        logic            cfgcpol;
        logic            cfgcpha;

        logic [15:0]     cfgrxcnt;
        logic [15:0]     cfgtxcnt;
        logic [15:0]     cfgdmcnt;
        logic seot_irq_en;
        logic seot;

    assign cfg_tx_datasize_o  = 2'b00;
    assign cfg_rx_datasize_o  = 2'b00;
    assign data_tx_datasize_o = 2'b00;
    assign data_rx_datasize_o = 2'b00;

    assign seot_event_o = s_seot_sync & seot_irq_en;

    udma_spis_reg_if #(
        .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
        .TRANS_SIZE(TRANS_SIZE)
    ) u_reg_if (
        .clk_i              ( sys_clk_i           ),
        .rstn_i             ( rstn_i              ),

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

//        .rx_data_i          ( data_rx_o[7:0]      ),
//        .rx_valid_i         ( data_rx_valid_o     ), // Pay attention to clock domain
//        .rx_ready_o         ( s_data_rx_ready     ), // Pay attention to clock domain

//        .status_i           ( '0   ),
//        .err_parity_i       ( '0   ),
//        .err_overflow_i     ( '0   ),

        .cfgcpol        (cfgcpol),
        .cfgcpha        (cfgcpha),
        .cfgrxcnt    (cfgrxcnt),
        .cfgtxcnt    (cfgtxcnt),
        .cfgdmcnt    (cfgdmcnt),

        .seot_irq_i  (s_seot_sync),
        .seot_irq_en (seot_irq_en)
//        .stop_bits_o        ( s_spis_stop_bits    ),
//        .parity_en_o        ( s_spis_parity_en    ),
//        .divider_o          ( s_spis_div          ),
//        .num_bits_o         ( s_spis_bits         ),
//        .rx_clean_fifo_o    ( s_spis_rx_clean_fifo ),
//        .rx_polling_en_o    ( s_spis_rx_polling_en ),
//        .rx_irq_en_o        ( s_spis_rx_irq_en    ),
//        .err_irq_en_o       ( s_spis_err_irq_en   ),
//        .en_rx_o			( s_spis_en_rx        ),
//        .en_tx_o			( s_spis_en_tx        )
    );

    logic periph_clk;
    assign periph_clk = sys_clk_i;

    logic fiforesetn, data_tx_req_o0;
    logic [2:0] data_tx_reqen;
    assign fiforesetn = cmsatpg ? rstn_i : rstn_i & ~spis_cs_i;

    `theregfull( sys_clk_i, fiforesetn, data_tx_reqen, '0 ) <= { data_tx_reqen , 1'b1 };
    assign data_tx_req_o = data_tx_req_o0 & data_tx_reqen[2];

    io_tx_fifo #(
      .DATA_WIDTH(8),
      .BUFFER_DEPTH(2)
      ) u_fifo (
        .clk_i   ( sys_clk_i       ),
        .rstn_i  ( fiforesetn          ),
        .clr_i   ( 1'b0            ),
        .data_o  ( s_data_tx       ),
        .valid_o ( s_data_tx_valid ),
        .ready_i ( s_data_tx_ready ),
        .req_o   ( data_tx_req_o0   ),
        .gnt_i   ( data_tx_gnt_i   ),
        .valid_i ( data_tx_valid_i ),
        .data_i  ( data_tx_i[7:0]  ),
        .ready_o ( data_tx_ready_o )
    );
/*
    udma_dc_fifo #(8,4) u_dc_fifo_tx
    (
        .src_clk_i    ( sys_clk_i          ),
        .src_rstn_i   ( fiforesetn             ),
        .src_data_i   ( s_data_tx          ),
        .src_valid_i  ( s_data_tx_valid    ),
        .src_ready_o  ( s_data_tx_ready    ),
        .dst_clk_i    ( periph_clk       ),
        .dst_rstn_i   ( fiforesetn             ),
        .dst_data_o   ( s_data_tx_dc       ),
        .dst_valid_o  ( s_data_tx_dc_valid ),
        .dst_ready_i  ( s_data_tx_dc_ready )
    );
*/

    assign s_data_tx_dc = s_data_tx;
    assign s_data_tx_dc_valid = s_data_tx_valid;
    assign s_data_tx_ready = s_data_tx_dc_ready;

    udma_spis_txrx utxrx
    (
        .clk         (periph_clk),
        .resetn      (rstn_i),
        .cmsatpg     (cmsatpg),
        .cpol        (cfgcpol),
        .cpha        (cfgcpha),
        .cfgrxcnt    (cfgrxcnt),
        .cfgtxcnt    (cfgtxcnt),
        .cfgdmcnt    (cfgdmcnt),
        .sclk        (spis_clk_i),
        .scsn        (spis_cs_i),
        .smosi       (spis_mosi_i),
        .smiso       (spis_miso_o),
        .smisooe     (spis_miso_oe),
        .seot        (seot),
        .tx_fifo_i   (s_data_tx_dc),
        .tx_fifo_rd  (s_data_tx_dc_ready),
        .rx_fifo_o   (s_data_rx_dc),
        .rx_fifo_wr  (s_data_rx_dc_valid)
    );

    udma_dc_fifo #(8,4) u_dc_fifo_rx
    (
        .src_clk_i    ( periph_clk       ),
        .src_rstn_i   ( fiforesetn  ),
        .src_data_i   ( s_data_rx_dc       ),
        .src_valid_i  ( s_data_rx_dc_valid ),
        .src_ready_o  ( s_data_rx_dc_ready ),
        .dst_clk_i    ( sys_clk_i          ),
        .dst_rstn_i   ( fiforesetn  ),
        .dst_data_o   ( data_rx_o[7:0]     ),
        .dst_valid_o  ( data_rx_valid_o    ),
        .dst_ready_i  ( data_rx_ready_i    )
    );

/*
    udma_uart_tx u_spis_tx(
        .clk_i           ( periph_clk       ),
        .rstn_i          ( rstn_i             ),
		.tx_o            ( spis_tx_o          ),
        .busy_o          ( s_spis_status[0]   ),
        .cfg_en_i        ( r_spis_en_tx_sync[2] ),
		.cfg_div_i       ( r_spis_div         ),
		.cfg_parity_en_i ( r_spis_parity_en   ),
		.cfg_bits_i      ( r_spis_bits        ),
		.cfg_stop_bits_i ( r_spis_stop_bits   ),
		.tx_data_i       ( s_data_tx_dc       ),
		.tx_valid_i      ( s_data_tx_dc_valid ),
		.tx_ready_o      ( s_data_tx_dc_ready )
    );

    udma_uart_rx u_spis_rx(
        .clk_i           ( periph_clk       ),
        .rstn_i          ( rstn_i             ),
		.rx_i            ( spis_rx_i          ),
        .busy_o          ( s_spis_status[1]   ),
        .cfg_en_i        ( r_spis_en_rx_sync[2] ),
		.cfg_div_i       ( r_spis_div         ),
		.cfg_parity_en_i ( r_spis_parity_en   ),
		.cfg_bits_i      ( r_spis_bits        ),
		.cfg_stop_bits_i ( r_spis_stop_bits   ),
        .err_parity_o    ( s_err_rx_parity    ),
        .err_overflow_o  ( s_err_rx_overflow  ),
        .char_event_o    ( s_rx_char_event    ),
		.rx_data_o       ( s_data_rx_dc       ),
		.rx_valid_o      ( s_data_rx_dc_valid ),
		.rx_ready_i      ( s_data_rx_dc_ready )
    );
*/
//   assign s_data_rx_ready_mux = (s_spis_rx_irq_en | s_spis_rx_polling_en) ? s_data_rx_ready : data_rx_ready_i;
/*
    edge_propagator i_ep_err_overflow (
        .clk_tx_i(periph_clk),
        .rstn_tx_i(rstn_i),
        .edge_i(s_err_rx_overflow),
        .clk_rx_i(sys_clk_i),
        .rstn_rx_i(rstn_i),
        .edge_o(s_err_rx_overflow_sync)
    );

    edge_propagator i_ep_err_parity (
        .clk_tx_i(periph_clk),
        .rstn_tx_i(rstn_i),
        .edge_i(s_err_rx_parity),
        .clk_rx_i(sys_clk_i),
        .rstn_rx_i(rstn_i),
        .edge_o(s_err_rx_parity_sync)
    );
*/
    edge_propagator i_ep_event (
        .clk_tx_i(periph_clk),
        .rstn_tx_i(rstn_i),
        .edge_i(seot),
        .clk_rx_i(sys_clk_i),
        .rstn_rx_i(rstn_i),
        .edge_o(s_seot_sync)
    );


    assign data_rx_o[31:8] = 'h0;

endmodule // udma_spis_top
