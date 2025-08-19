// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

///////////////////////////////////////////////////////////////////////////////
//
// Description: Top level of uDMA filtering block
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

`define CONN_MODE_0   0
`define CONN_MODE_1   1
`define CONN_MODE_2   2
`define CONN_MODE_3   3
`define CONN_MODE_4   4
`define CONN_MODE_5   5
`define CONN_MODE_6   6
`define CONN_MODE_7   7
`define CONN_MODE_8   8
`define CONN_MODE_9   9
`define CONN_MODE_10 10
`define CONN_MODE_11 11
`define CONN_MODE_12 12
`define CONN_MODE_13 13
`define CONN_MODE_14 14
`define CONN_MODE_15 15

module udma_filter
  #(
    parameter DATA_WIDTH     = 32,
    parameter FILTID_WIDTH   = 8,
    parameter L2_AWIDTH_NOAL = 15,
    parameter TRANS_SIZE     = 16
    )
   (
    input  logic                             clk_i,
    input  logic                             resetn_i,

    input  logic                      [31:0] cfg_data_i,
    input  logic                       [4:0] cfg_addr_i,
    input  logic                             cfg_valid_i,
    input  logic                             cfg_rwn_i,
    output logic                      [31:0] cfg_data_o,
    output logic                             cfg_ready_o,

    output logic                             eot_event_o,
    output logic                             act_event_o,

    output logic                             filter_tx_ch0_req_o,
    output logic        [L2_AWIDTH_NOAL-1:0] filter_tx_ch0_addr_o,
    output logic                       [1:0] filter_tx_ch0_datasize_o,
    input  logic                             filter_tx_ch0_gnt_i,

    input  logic                             filter_tx_ch0_valid_i,
    input  logic            [DATA_WIDTH-1:0] filter_tx_ch0_data_i,
    output logic                             filter_tx_ch0_ready_o,

    output logic                             filter_tx_ch1_req_o,
    output logic        [L2_AWIDTH_NOAL-1:0] filter_tx_ch1_addr_o,
    output logic                       [1:0] filter_tx_ch1_datasize_o,
    input  logic                             filter_tx_ch1_gnt_i,

    input  logic                             filter_tx_ch1_valid_i,
    input  logic            [DATA_WIDTH-1:0] filter_tx_ch1_data_i,
    output logic                             filter_tx_ch1_ready_o,

    output logic        [L2_AWIDTH_NOAL-1:0] filter_rx_ch_addr_o,
    output logic                       [1:0] filter_rx_ch_datasize_o,
    output logic                             filter_rx_ch_valid_o,
    output logic            [DATA_WIDTH-1:0] filter_rx_ch_data_o,
    input  logic                             filter_rx_ch_ready_i,

    input  logic          [FILTID_WIDTH-1:0] filter_id_i,
    input  logic            [DATA_WIDTH-1:0] filter_data_i,
    input  logic                       [1:0] filter_datasize_i,
    input  logic                             filter_valid_i,
    input  logic                             filter_sof_i,
    input  logic                             filter_eof_i,
    output logic                             filter_ready_o

    );
   logic [DATA_WIDTH-1:0] s_porta_data;
   logic            [1:0] s_porta_datasize;
   logic                  s_porta_valid;
   logic                  s_porta_sof;
   logic                  s_porta_eof;
   logic                  s_porta_ready;

   logic [DATA_WIDTH-1:0] s_portb_data;
   logic            [1:0] s_portb_datasize;
   logic                  s_portb_valid;
   logic                  s_portb_sof;
   logic                  s_portb_eof;
   logic                  s_portb_ready;

   logic [DATA_WIDTH-1:0] s_operanda_data;
   logic            [1:0] s_operanda_datasize;
   logic                  s_operanda_valid;
   logic                  s_operanda_sof;
   logic                  s_operanda_eof;
   logic                  s_operanda_ready;

   logic [DATA_WIDTH-1:0] s_operandb_data;
   logic            [1:0] s_operandb_datasize;
   logic                  s_operandb_valid;
   logic                  s_operandb_ready;

   logic [DATA_WIDTH-1:0] s_au_out_data;
   logic            [1:0] s_au_out_datasize;
   logic                  s_au_out_valid;
   logic                  s_au_out_ready;

   logic [DATA_WIDTH-1:0] s_bincu_in_data;
   logic            [1:0] s_bincu_in_datasize;
   logic                  s_bincu_in_valid;
   logic                  s_bincu_in_ready;

   logic [DATA_WIDTH-1:0] s_bincu_out_data;
   logic                  s_bincu_out_valid;
   logic                  s_bincu_out_ready;
   logic                  s_bincu_outenable;

   logic [DATA_WIDTH-1:0] s_udma_out_data;
   logic                  s_udma_out_valid;
   logic                  s_udma_out_ready;

   logic s_sel_out;       //1 output is from AU, 0 output is from BINCU
   logic s_sel_out_valid; //1 enables output

   logic s_sel_opa;       //1 input is from OPAPORT, 0 input is from BINCU
   logic s_sel_opa_valid; //1 enables output
   logic s_sel_opb_valid; //1 enables output

   logic s_sel_bincu;       //1 input  is from AU, 0 input  is from STREAM
   logic s_sel_bincu_valid; //1 enables output

   logic s_start_cha;
   logic s_start_chb;
   logic s_start_out;
   logic s_start_bcu;

  logic [2:0] s_status;
  logic [2:0] r_status;

  logic       s_done_cha;
  logic       s_done_chb;
  logic       s_done_out;
  logic       s_done;
  logic       r_done;

  logic       s_event;

  logic       s_filter_ready;

  logic                       [3:0] s_cfg_filter_mode;
  logic                             s_cfg_filter_start;

  logic [1:0]  [L2_AWIDTH_NOAL-1:0] s_cfg_filter_tx_start_addr;
  logic [1:0]                 [1:0] s_cfg_filter_tx_datasize;
  logic [1:0]                 [1:0] s_cfg_filter_tx_mode;
  logic [1:0]      [TRANS_SIZE-1:0] s_cfg_filter_tx_len0;
  logic [1:0]      [TRANS_SIZE-1:0] s_cfg_filter_tx_len1;
  logic [1:0]      [TRANS_SIZE-1:0] s_cfg_filter_tx_len2;

  logic        [L2_AWIDTH_NOAL-1:0] s_cfg_filter_rx_start_addr;
  logic                       [1:0] s_cfg_filter_rx_datasize;
  logic                       [1:0] s_cfg_filter_rx_mode;
  logic            [TRANS_SIZE-1:0] s_cfg_filter_rx_len0;
  logic            [TRANS_SIZE-1:0] s_cfg_filter_rx_len1;
  logic            [TRANS_SIZE-1:0] s_cfg_filter_rx_len2;

  logic                             s_cfg_au_use_signed;
  logic                             s_cfg_au_bypass;
  logic                       [3:0] s_cfg_au_mode;
  logic                       [4:0] s_cfg_au_shift;
  logic                      [31:0] s_cfg_au_reg0;
  logic                      [31:0] s_cfg_au_reg1;

  logic                      [31:0] s_cfg_bincu_threshold;
  logic                       [1:0] s_cfg_bincu_datasize;
  logic            [TRANS_SIZE-1:0] s_cfg_bincu_counter;
  logic            [TRANS_SIZE-1:0] s_cfg_bincu_counter_val;
  logic                             s_cfg_bincu_en_cnt;
  
   assign s_start_out = s_cfg_filter_start & s_sel_out_valid;
   assign s_start_cha = s_cfg_filter_start & s_sel_opa_valid;
   assign s_start_chb = s_cfg_filter_start & s_sel_opb_valid;
   assign s_start_bcu = s_cfg_filter_start & s_sel_bincu_valid;

   assign s_udma_out_data  =                    s_sel_out ? s_au_out_data  : s_bincu_out_data;
   assign s_udma_out_valid = s_sel_out_valid & (s_sel_out ? s_au_out_valid : s_bincu_out_valid);

   assign s_bincu_in_data  =                      s_sel_bincu ? s_au_out_data  : filter_data_i;
   assign s_bincu_in_valid = s_sel_bincu_valid & (s_sel_bincu ? s_au_out_valid : filter_valid_i);
   assign s_bincu_in_datasize =                   s_sel_bincu ? s_au_out_datasize : filter_datasize_i;

   assign s_operanda_data  =                    s_sel_opa ? s_porta_data  : filter_data_i;
   assign s_operanda_datasize  =                s_sel_opa ? s_porta_datasize  : filter_datasize_i;
   assign s_operanda_sof  =                     s_sel_opa ? s_porta_sof   : filter_sof_i;
   assign s_operanda_eof  =                     s_sel_opa ? s_porta_eof   : filter_eof_i;
   assign s_operanda_valid = s_sel_opa_valid & (s_sel_opa ? s_porta_valid : filter_valid_i);

   assign s_operandb_data = s_portb_data;
   assign s_operandb_valid = s_portb_valid;
   assign s_operandb_datasize = s_portb_datasize;

   assign s_au_out_ready   = (s_sel_out_valid   & s_sel_out   & s_udma_out_ready) | 
                             (s_sel_bincu_valid & s_sel_bincu & s_bincu_in_ready);

   assign s_porta_ready = (s_sel_opa_valid & s_sel_opa & s_operanda_ready);
   assign s_portb_ready = s_operandb_ready;

   assign s_filter_ready = (s_sel_opa_valid   & !s_sel_opa   & s_operanda_ready) |
                           (s_sel_bincu_valid & !s_sel_bincu & s_bincu_in_ready);

   assign s_bincu_out_ready = (s_sel_out_valid & !s_sel_out & s_udma_out_ready);

   assign filter_ready_o = s_filter_ready;

  assign s_status = r_status | {!s_sel_out_valid,!s_sel_opb_valid,!s_sel_opa_valid}; //mask status of all the channels with their on/off status
  assign s_done   = &s_status;
  assign s_event  = s_done & ~r_done; //when all of them are done then rise the int
  assign eot_event_o = s_event;

  assign s_bincu_outenable = s_sel_out_valid & ~s_sel_out;

  always_comb 
  begin
    s_sel_out         = 1'b0;
    s_sel_out_valid   = 1'b0;
    s_sel_bincu       = 1'b0;
    s_sel_bincu_valid = 1'b0;
    s_sel_opa         = 1'b0;
    s_sel_opa_valid   = 1'b0;
    s_sel_opb_valid   = 1'b0;
    case(s_cfg_filter_mode)         //OperandA OperandB Output TBUnit 
      `CONN_MODE_0:                 //  L2       L2      ON     OFF
      begin
        s_sel_opa       = 1'b1;
        s_sel_opa_valid = 1'b1;
        s_sel_opb_valid = 1'b1;
        s_sel_out       = 1'b1;
        s_sel_out_valid = 1'b1;
      end
      `CONN_MODE_1:                 // STREAM    L2      ON     OFF
      begin
        s_sel_opa       = 1'b0;
        s_sel_opa_valid = 1'b1;
        s_sel_opb_valid = 1'b1;
        s_sel_out       = 1'b1;
        s_sel_out_valid = 1'b1;
      end
      `CONN_MODE_2:                 //  L2       OFF     ON     OFF
      begin
        s_sel_opa       = 1'b1;
        s_sel_opa_valid = 1'b1;
        s_sel_out       = 1'b1;
        s_sel_out_valid = 1'b1;
      end
      `CONN_MODE_3:                 // STREAM    OFF     ON     OFF
      begin
        s_sel_opa       = 1'b0;
        s_sel_opa_valid = 1'b1;
        s_sel_out       = 1'b1;
        s_sel_out_valid = 1'b1;
      end
      `CONN_MODE_4:                 //  L2       L2      OFF    ON
      begin
        s_sel_opa       = 1'b1;
        s_sel_opa_valid = 1'b1;
        s_sel_opb_valid = 1'b1;
        s_sel_bincu       = 1'b1;
        s_sel_bincu_valid = 1'b1;
      end
      `CONN_MODE_5:                 // STREAM    L2      OFF    ON
      begin
        s_sel_opa       = 1'b0;
        s_sel_opa_valid = 1'b1;
        s_sel_opb_valid = 1'b1;
        s_sel_bincu       = 1'b1;
        s_sel_bincu_valid = 1'b1;
      end
      `CONN_MODE_6:                 //  L2       OFF     OFF    ON
      begin
        s_sel_opa       = 1'b1;
        s_sel_opa_valid = 1'b1;
        s_sel_bincu       = 1'b1;
        s_sel_bincu_valid = 1'b1;
      end
      `CONN_MODE_7:                 // STREAM    OFF     OFF    ON
      begin
        s_sel_opa       = 1'b0;
        s_sel_opa_valid = 1'b1;
        s_sel_bincu       = 1'b1;
        s_sel_bincu_valid = 1'b1;
      end
      `CONN_MODE_8:                 //  L2       L2      ON     ON
      begin
        s_sel_opa       = 1'b1;
        s_sel_opa_valid = 1'b1;
        s_sel_opb_valid = 1'b1;
        s_sel_out       = 1'b0;
        s_sel_out_valid = 1'b1;
        s_sel_bincu       = 1'b1;
        s_sel_bincu_valid = 1'b1;
      end
      `CONN_MODE_9:                 // STREAM    L2      ON     ON
      begin
        s_sel_opa       = 1'b0;
        s_sel_opa_valid = 1'b1;
        s_sel_opb_valid = 1'b1;
        s_sel_out       = 1'b0;
        s_sel_out_valid = 1'b1;
        s_sel_bincu       = 1'b1;
        s_sel_bincu_valid = 1'b1;
      end
      `CONN_MODE_10:                //  L2       OFF     ON    ON
      begin
        s_sel_opa       = 1'b1;     
        s_sel_opa_valid = 1'b1;
        s_sel_out       = 1'b0;
        s_sel_out_valid = 1'b1;
        s_sel_bincu       = 1'b1;
        s_sel_bincu_valid = 1'b1;
      end
      `CONN_MODE_11:                // STREAM    OFF     ON     ON
      begin
        s_sel_opa       = 1'b0;
        s_sel_opa_valid = 1'b1;
        s_sel_out       = 1'b0;
        s_sel_out_valid = 1'b1;
        s_sel_bincu       = 1'b1;
        s_sel_bincu_valid = 1'b1;
      end
      `CONN_MODE_12:               //    OFF     OFF     OFF    ON
      begin
        s_sel_bincu       = 1'b0;
        s_sel_bincu_valid = 1'b1;
      end
      `CONN_MODE_13:               //    OFF     OFF     ON     ON
      begin
        s_sel_out       = 1'b0;
        s_sel_out_valid = 1'b1;
        s_sel_bincu       = 1'b0;
        s_sel_bincu_valid = 1'b1;
      end
    endcase // cfg_filter_mode_i
  end

  always_ff @(posedge clk_i or negedge resetn_i) begin : proc_status
    if(~resetn_i) begin
      r_status <= 0;
      r_done   <= 0;
    end else begin
      r_done <= s_done;
      if(s_cfg_filter_start)
        r_status <= 0;
      else
      begin
        if(s_done_cha)
          r_status[0] <= 1'b1;
        if(s_done_chb)
          r_status[1] <= 1'b1;
        if(s_done_out)
          r_status[2] <= 1'b1;
      end
    end
  end

  udma_filter_reg_if #(
      .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
      .TRANS_SIZE    (TRANS_SIZE) 
  ) i_reg_if (
      .clk_i      ( clk_i       ),
      .rstn_i     ( resetn_i    ),

      .cfg_data_i ( cfg_data_i  ),
      .cfg_addr_i ( cfg_addr_i  ),
      .cfg_valid_i( cfg_valid_i ),
      .cfg_rwn_i  ( cfg_rwn_i   ),
      .cfg_data_o ( cfg_data_o  ),
      .cfg_ready_o( cfg_ready_o ),

      .cfg_filter_mode_o         ( s_cfg_filter_mode          ),
      .cfg_filter_start_o        ( s_cfg_filter_start         ),

      .cfg_filter_tx_start_addr_o( s_cfg_filter_tx_start_addr ),
      .cfg_filter_tx_datasize_o  ( s_cfg_filter_tx_datasize   ),
      .cfg_filter_tx_mode_o      ( s_cfg_filter_tx_mode       ),
      .cfg_filter_tx_len0_o      ( s_cfg_filter_tx_len0       ),
      .cfg_filter_tx_len1_o      ( s_cfg_filter_tx_len1       ),
      .cfg_filter_tx_len2_o      ( s_cfg_filter_tx_len2       ),

      .cfg_filter_rx_start_addr_o( s_cfg_filter_rx_start_addr ),
      .cfg_filter_rx_datasize_o  ( s_cfg_filter_rx_datasize   ),
      .cfg_filter_rx_mode_o      ( s_cfg_filter_rx_mode       ),
      .cfg_filter_rx_len0_o      ( s_cfg_filter_rx_len0       ),
      .cfg_filter_rx_len1_o      ( s_cfg_filter_rx_len1       ),
      .cfg_filter_rx_len2_o      ( s_cfg_filter_rx_len2       ),

      .cfg_au_use_signed_o       ( s_cfg_au_use_signed        ),
      .cfg_au_bypass_o           ( s_cfg_au_bypass            ),
      .cfg_au_mode_o             ( s_cfg_au_mode              ),
      .cfg_au_shift_o            ( s_cfg_au_shift             ),
      .cfg_au_reg0_o             ( s_cfg_au_reg0              ),
      .cfg_au_reg1_o             ( s_cfg_au_reg1              ),

      .cfg_bincu_threshold_o     ( s_cfg_bincu_threshold      ),
      .cfg_bincu_datasize_o      ( s_cfg_bincu_datasize       ),
      .cfg_bincu_counter_o       ( s_cfg_bincu_counter        ),
      .cfg_bincu_en_counter_o    ( s_cfg_bincu_en_cnt         ),

      .bincu_counter_i           ( s_cfg_bincu_counter_val    ),

      .filter_done_i             ( s_event                    )
  );

  udma_filter_tx_datafetch #(
      .DATA_WIDTH    (DATA_WIDTH    ),
      .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
      .TRANS_SIZE    (TRANS_SIZE    )
  ) u_tx_ch_opa (
      .clk_i            ( clk_i                   ),
      .resetn_i         ( resetn_i                ),

      .tx_ch_req_o      ( filter_tx_ch0_req_o      ),
      .tx_ch_addr_o     ( filter_tx_ch0_addr_o     ),
      .tx_ch_datasize_o ( filter_tx_ch0_datasize_o ),
      .tx_ch_gnt_i      ( filter_tx_ch0_gnt_i      ),
      .tx_ch_valid_i    ( filter_tx_ch0_valid_i    ),
      .tx_ch_data_i     ( filter_tx_ch0_data_i     ),
      .tx_ch_ready_o    ( filter_tx_ch0_ready_o    ),

      .cmd_start_i      ( s_start_cha ),
      .cmd_done_o       ( s_done_cha  ),

      .cfg_start_addr_i ( s_cfg_filter_tx_start_addr[0] ),
      .cfg_datasize_i   ( s_cfg_filter_tx_datasize[0]   ),
      .cfg_mode_i       ( s_cfg_filter_tx_mode[0]       ),
      .cfg_len0_i       ( s_cfg_filter_tx_len0[0]       ),
      .cfg_len1_i       ( s_cfg_filter_tx_len1[0]       ),
      .cfg_len2_i       ( s_cfg_filter_tx_len2[0]       ),

      .stream_data_o    ( s_porta_data      ),
      .stream_datasize_o( s_porta_datasize  ),
      .stream_sof_o     ( s_porta_sof       ),
      .stream_eof_o     ( s_porta_eof       ),
      .stream_valid_o   ( s_porta_valid     ),
      .stream_ready_i   ( s_porta_ready     )

    );

  udma_filter_tx_datafetch #(
      .DATA_WIDTH    (DATA_WIDTH    ),
      .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
      .TRANS_SIZE    (TRANS_SIZE    )
  ) u_tx_ch_opb (
      .clk_i            ( clk_i                   ),
      .resetn_i         ( resetn_i                ),
      .tx_ch_req_o      ( filter_tx_ch1_req_o      ),
      .tx_ch_addr_o     ( filter_tx_ch1_addr_o     ),
      .tx_ch_datasize_o ( filter_tx_ch1_datasize_o ),
      .tx_ch_gnt_i      ( filter_tx_ch1_gnt_i      ),
      .tx_ch_valid_i    ( filter_tx_ch1_valid_i    ),
      .tx_ch_data_i     ( filter_tx_ch1_data_i     ),
      .tx_ch_ready_o    ( filter_tx_ch1_ready_o    ),
      .cmd_start_i      ( s_start_chb ),
      .cmd_done_o       ( s_done_chb  ),
      .cfg_start_addr_i ( s_cfg_filter_tx_start_addr[1] ),
      .cfg_datasize_i   ( s_cfg_filter_tx_datasize[1]   ),
      .cfg_mode_i       ( s_cfg_filter_tx_mode[1]       ),
      .cfg_len0_i       ( s_cfg_filter_tx_len0[1]       ),
      .cfg_len1_i       ( s_cfg_filter_tx_len1[1]       ),
      .cfg_len2_i       ( s_cfg_filter_tx_len2[1]       ),
      .stream_data_o    ( s_portb_data      ),
      .stream_datasize_o( s_portb_datasize  ),
      .stream_sof_o     ( s_portb_sof       ),
      .stream_eof_o     ( s_portb_eof       ),
      .stream_valid_o   ( s_portb_valid     ),
      .stream_ready_i   ( s_portb_ready     )

    );

    udma_filter_au
    #(
      .DATA_WIDTH(DATA_WIDTH)
    ) u_filter_au (
        .clk_i               ( clk_i                ),
        .resetn_i            ( resetn_i             ),
        .cfg_use_signed_i    ( s_cfg_au_use_signed  ),
        .cfg_bypass_i        ( s_cfg_au_bypass      ),
        .cfg_mode_i          ( s_cfg_au_mode        ),
        .cfg_shift_i         ( s_cfg_au_shift       ),
        .cfg_reg0_i          ( s_cfg_au_reg0        ),
        .cfg_reg1_i          ( s_cfg_au_reg1        ),
        .cmd_start_i         ( s_cfg_filter_start   ),
        .operanda_data_i     ( s_operanda_data      ),
        .operanda_datasize_i ( s_operanda_datasize  ),
        .operanda_valid_i    ( s_operanda_valid     ),
        .operanda_sof_i      ( s_operanda_sof       ),
        .operanda_eof_i      ( s_operanda_eof       ),
        .operanda_ready_o    ( s_operanda_ready     ),
        .operandb_data_i     ( s_operandb_data      ),
        .operandb_datasize_i ( s_operandb_datasize  ),
        .operandb_valid_i    ( s_operandb_valid     ),
        .operandb_ready_o    ( s_operandb_ready     ),
        .output_data_o       ( s_au_out_data        ),
        .output_datasize_o   ( s_au_out_datasize    ),
        .output_valid_o      ( s_au_out_valid       ),
        .output_ready_i      ( s_au_out_ready       )
    );

    udma_filter_bincu
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .TRANS_SIZE(TRANS_SIZE)
    ) u_filter_bincu (
        .clk_i            ( clk_i                 ),
        .resetn_i         ( resetn_i              ),
        .cfg_use_signed_i ( s_cfg_au_use_signed   ),
        .cfg_en_counter_i ( s_cfg_bincu_en_cnt    ),
        .cfg_out_enable_i ( s_bincu_outenable     ),
        .cfg_threshold_i  ( s_cfg_bincu_threshold ),
        .cfg_counter_i    ( s_cfg_bincu_counter   ),
        .cfg_datasize_i   ( s_cfg_bincu_datasize  ),
        .counter_val_o    ( s_cfg_bincu_counter_val ),
        .cmd_start_i      ( s_start_bcu           ),
        .act_event_o      ( act_event_o           ),
        .input_data_i     ( s_bincu_in_data       ),
        .input_datasize_i ( s_bincu_in_datasize   ),
        .input_valid_i    ( s_bincu_in_valid      ),
        .input_sof_i      ( 1'b0                  ),
        .input_eof_i      ( 1'b0                  ),
        .input_ready_o    ( s_bincu_in_ready      ),
        .output_data_o    ( s_bincu_out_data      ),
        .output_datasize_o( ),
        .output_valid_o   ( s_bincu_out_valid     ),
        .output_sof_o     ( ),
        .output_eof_o     ( ),
        .output_ready_i   ( s_bincu_out_ready     )
  );

    udma_filter_rx_dataout #(
      .DATA_WIDTH    ( DATA_WIDTH    ),
      .FILTID_WIDTH  ( FILTID_WIDTH  ),
      .L2_AWIDTH_NOAL( L2_AWIDTH_NOAL),
      .TRANS_SIZE    ( TRANS_SIZE    )
    ) u_rx_ch (
      .clk_i           ( clk_i                      ),
      .resetn_i        ( resetn_i                   ),
      .rx_ch_addr_o    ( filter_rx_ch_addr_o        ),
      .rx_ch_datasize_o( filter_rx_ch_datasize_o    ),
      .rx_ch_valid_o   ( filter_rx_ch_valid_o       ),
      .rx_ch_data_o    ( filter_rx_ch_data_o        ),
      .rx_ch_ready_i   ( filter_rx_ch_ready_i       ),
      .cmd_start_i     ( s_start_out                ),
      .cmd_done_o      ( s_done_out                 ),
      .cfg_start_addr_i( s_cfg_filter_rx_start_addr ),
      .cfg_datasize_i  ( s_cfg_filter_rx_datasize   ),
      .cfg_mode_i      ( s_cfg_filter_rx_mode       ),
      .cfg_len0_i      ( s_cfg_filter_rx_len0       ),
      .cfg_len1_i      ( s_cfg_filter_rx_len1       ),
      .cfg_len2_i      ( s_cfg_filter_rx_len2       ),
      .stream_data_i   ( s_udma_out_data            ),
      .stream_valid_i  ( s_udma_out_valid           ),
      .stream_ready_o  ( s_udma_out_ready           )

    );

endmodule

