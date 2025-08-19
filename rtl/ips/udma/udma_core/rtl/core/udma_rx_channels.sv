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
// Description: RX channels for uDMA IP
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////


module udma_rx_channels
  #(
    parameter TRANS_SIZE        = 16,
    parameter L2_DATA_WIDTH     = 64,
    parameter L2_AWIDTH_NOAL    = 16,
    parameter DATA_WIDTH        = 32,
    parameter DEST_SIZE         = 2,
    parameter STREAM_ID_WIDTH    = 2,
    parameter N_STREAMS         = 4,
    parameter N_LIN_CHANNELS    = 8,
    parameter N_EXT_CHANNELS    = 8
    )
   (
    input  logic	                         clk_i,
    input  logic                           rstn_i,
    input  logic [3:0]                     sw_rstn_uart_i,
    input  logic [3:0]                     sw_rstn_spim_i,
    input  logic [3:0]                     sw_rstn_i2c_i,
    input  logic                           sw_rstn_sdio_i,
    input  logic                           sw_rstn_i2s_i,
    input  logic                           sw_rstn_cam_i,
    input  logic                           sw_rstn_scif_i,
    input  logic [1:0]                     sw_rstn_spis_i,
    input  logic                           sw_rstn_adc_i,
    
    output logic                           l2_req_o,
    input  logic                           l2_gnt_i,
    output logic  [L2_DATA_WIDTH/8-1 : 0]  l2_be_o,
    output logic                 [31 : 0]  l2_addr_o,
    output logic    [L2_DATA_WIDTH-1 : 0]  l2_wdata_o,

    output logic [N_STREAMS-1:0]          [DATA_WIDTH-1 : 0] stream_data_o,
    output logic [N_STREAMS-1:0]                     [1 : 0] stream_datasize_o,
    output logic [N_STREAMS-1:0]                             stream_valid_o,
    output logic [N_STREAMS-1:0]                             stream_sot_o,
    output logic [N_STREAMS-1:0]                             stream_eot_o,
    input  logic [N_STREAMS-1:0]                             stream_ready_i,

    output logic [N_STREAMS-1:0]                             tx_ch_req_o,
    output logic [N_STREAMS-1:0]      [L2_AWIDTH_NOAL-1 : 0] tx_ch_addr_o,
    output logic [N_STREAMS-1:0]                     [1 : 0] tx_ch_datasize_o,
    input  logic [N_STREAMS-1:0]                             tx_ch_gnt_i,
    input  logic [N_STREAMS-1:0]                             tx_ch_valid_i,
    input  logic [N_STREAMS-1:0]          [DATA_WIDTH-1 : 0] tx_ch_data_i,
    output logic [N_STREAMS-1:0]                             tx_ch_ready_o,

    input  logic [N_LIN_CHANNELS-1:0]                        lin_ch_valid_i,
    input  logic [N_LIN_CHANNELS-1:0]     [DATA_WIDTH-1 : 0] lin_ch_data_i,
    input  logic [N_LIN_CHANNELS-1:0]                [1 : 0] lin_ch_datasize_i,
    input  logic [N_LIN_CHANNELS-1:0]      [DEST_SIZE-1 : 0] lin_ch_destination_i,      
    output logic [N_LIN_CHANNELS-1:0]                        lin_ch_ready_o,
    output logic [N_LIN_CHANNELS-1:0]                        lin_ch_events_o,
    output logic [N_LIN_CHANNELS-1:0]                        lin_ch_en_o,
    output logic [N_LIN_CHANNELS-1:0]                        lin_ch_pending_o,
    output logic [N_LIN_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] lin_ch_curr_addr_o,
    output logic [N_LIN_CHANNELS-1:0]     [TRANS_SIZE-1 : 0] lin_ch_bytes_left_o,
    input  logic [N_LIN_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] lin_ch_cfg_startaddr_i,
    input  logic [N_LIN_CHANNELS-1:0]     [TRANS_SIZE-1 : 0] lin_ch_cfg_size_i,
    input  logic [N_LIN_CHANNELS-1:0]                        lin_ch_cfg_continuous_i,
    input  logic [N_LIN_CHANNELS-1:0]                        lin_ch_cfg_en_i,
    input  logic [N_LIN_CHANNELS-1:0]                [1 : 0] lin_ch_cfg_stream_i,
    input  logic [N_LIN_CHANNELS-1:0] [STREAM_ID_WIDTH-1 : 0] lin_ch_cfg_stream_id_i,
    input  logic [N_LIN_CHANNELS-1:0]                        lin_ch_cfg_clr_i,

    input  logic [N_EXT_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] ext_ch_addr_i,
    input  logic [N_EXT_CHANNELS-1:0]                [1 : 0] ext_ch_datasize_i,
    input  logic [N_EXT_CHANNELS-1:0]      [DEST_SIZE-1 : 0] ext_ch_destination_i,
    input  logic [N_EXT_CHANNELS-1:0]                [1 : 0] ext_ch_stream_i,
    input  logic [N_EXT_CHANNELS-1:0] [STREAM_ID_WIDTH-1 : 0] ext_ch_stream_id_i,
    input  logic [N_EXT_CHANNELS-1:0]                        ext_ch_sot_i,
    input  logic [N_EXT_CHANNELS-1:0]                        ext_ch_eot_i,
    input  logic [N_EXT_CHANNELS-1:0]                        ext_ch_valid_i,
    input  logic [N_EXT_CHANNELS-1:0]     [DATA_WIDTH-1 : 0] ext_ch_data_i,
    output logic [N_EXT_CHANNELS-1:0]                        ext_ch_ready_o

    );

    localparam ALIGN_BITS          = $clog2(L2_DATA_WIDTH/8);
    localparam N_CHANNELS_RX       = N_LIN_CHANNELS + N_EXT_CHANNELS;
    localparam LOG_N_CHANNELS      = $clog2(N_CHANNELS_RX);

    localparam DATASIZE_BITS       = 2;
    localparam SOT_EOT_BITS        = 2;
    localparam CURR_BYTES_BITS     = 2;

    localparam INTFIFO_L2_SIZE     = DATA_WIDTH + L2_AWIDTH_NOAL + DATASIZE_BITS + DEST_SIZE     + CURR_BYTES_BITS + STREAM_ID_WIDTH + 1;
    localparam INTFIFO_FILTER_SIZE = DATA_WIDTH + DATASIZE_BITS  + DEST_SIZE     + SOT_EOT_BITS;

    integer i;
   
   // Internal signals

    logic [N_LIN_CHANNELS-1:0] [L2_AWIDTH_NOAL-1:0] s_curr_addr;
    logic [N_LIN_CHANNELS-1:0]                [1:0] s_curr_bytes;
    logic [N_LIN_CHANNELS-1:0] [STREAM_ID_WIDTH-1:0] s_stream_id_cfg;

    logic                   [N_CHANNELS_RX-1:0] s_grant;
    logic                   [N_CHANNELS_RX-1:0] r_grant;
    logic                   [N_CHANNELS_RX-1:0] s_req;

    logic                  [LOG_N_CHANNELS-1:0] s_grant_log;

    logic                  [N_LIN_CHANNELS-1:0] s_ch_en;

    logic                                       s_anygrant;
    logic                                       r_anygrant;

    logic                                [31:0] s_data;
    logic                                [31:0] r_data;

    logic                       [DEST_SIZE-1:0] s_dest;
    logic                       [DEST_SIZE-1:0] r_dest;

    logic                  [L2_AWIDTH_NOAL-1:0] s_addr;

    logic                                 [1:0] s_bytes;
    logic                                 [1:0] s_default_bytes;

    logic                  [L2_AWIDTH_NOAL-1:0] r_ext_addr;
    logic                                 [1:0] r_ext_stream;
    logic                  [STREAM_ID_WIDTH-1:0] r_ext_stream_id;
    logic                                       r_ext_sot;
    logic                                       r_ext_eot;

    logic                                 [1:0] s_size;
    logic                                 [1:0] r_size;

    logic                                 [1:0] s_l2_transf_size;
    logic                      [DATA_WIDTH-1:0] s_l2_data;
    logic                       [DEST_SIZE-1:0] s_l2_dest;
    logic                 [L2_DATA_WIDTH/8-1:0] s_l2_be;
    logic                  [L2_AWIDTH_NOAL-1:0] s_l2_addr;
    logic       [L2_AWIDTH_NOAL-ALIGN_BITS-1:0] s_l2_addr_na;
    logic                 [STREAM_ID_WIDTH-1:0] s_l2_stream_id;
    logic                                 [1:0] s_l2_bytes;

    logic                 [INTFIFO_L2_SIZE-1:0] s_fifoin;
    logic                 [INTFIFO_L2_SIZE-1:0] s_fifoout;

    logic             [INTFIFO_FILTER_SIZE-1:0] s_fifoin_stream;
    logic             [INTFIFO_FILTER_SIZE-1:0] s_fifoout_stream;

    logic                                       s_sample_indata;
    logic                                       s_sample_indata_l2;
    logic                                       s_sample_indata_stream;

    logic            [N_LIN_CHANNELS-1:0] [1:0] s_stream_cfg;
    logic                                       s_is_stream;
    logic                                       s_stream_use_buff;
    logic                  [STREAM_ID_WIDTH-1:0] s_stream_id;

    logic                       [N_STREAMS-1:0] s_stream_ready;
    logic                      [DATA_WIDTH-1:0] s_stream_data;
    logic                  [STREAM_ID_WIDTH-1:0] s_stream_dest;
    logic                                 [1:0] s_stream_size;
    logic                                       s_stream_sot;
    logic                                       s_stream_eot;
    logic                                       s_stream_ready_demux;

    logic                                       s_stream_storel2;

    logic                  [N_LIN_CHANNELS-1:0] s_ch_events;
    logic                  [N_LIN_CHANNELS-1:0] s_ch_sot;

    logic                                       s_eot;
    logic                                       s_sot;

    logic                                       s_push_l2;
    logic                                       s_push_filter;

    logic                                       s_l2_req;
    logic                                       s_l2_gnt;

    logic                                       s_is_na;
    logic                                       s_detect_na;
    logic                                       s_l2_is_stream;
    logic s_stream_direct, s_target_l2, s_target_stream,s_l2_req_stream,s_stream_valid;

    logic [18:0] s_combo_rstn;

    enum logic {RX_IDLE,RX_NON_ALIGNED} r_rx_state,s_rx_state_next;

    assign lin_ch_events_o    = s_ch_events;
    assign lin_ch_curr_addr_o = s_curr_addr;
    assign lin_ch_en_o        = s_ch_en;

    assign s_fifoin        = {s_bytes,s_stream_storel2,s_stream_id,r_dest,r_size,s_addr[L2_AWIDTH_NOAL-1:0],r_data};
    assign s_fifoin_stream = {s_sot,s_eot,r_dest,r_size,r_data};

    assign s_l2_data        = s_fifoout[DATA_WIDTH-1:0];
    assign s_l2_addr        = s_fifoout[DATA_WIDTH+L2_AWIDTH_NOAL-1:DATA_WIDTH];
    assign s_l2_transf_size = s_fifoout[DATA_WIDTH+L2_AWIDTH_NOAL+DATASIZE_BITS-1:L2_AWIDTH_NOAL+DATA_WIDTH];
    assign s_l2_dest        = s_fifoout[DATA_WIDTH+L2_AWIDTH_NOAL+DATASIZE_BITS+DEST_SIZE-1:L2_AWIDTH_NOAL+DATA_WIDTH+DATASIZE_BITS]; 
    assign s_l2_stream_id   = s_fifoout[DATA_WIDTH+L2_AWIDTH_NOAL+DATASIZE_BITS+DEST_SIZE+STREAM_ID_WIDTH-1:DATA_WIDTH+L2_AWIDTH_NOAL+DATASIZE_BITS+DEST_SIZE]; 
    assign s_l2_is_stream   = s_fifoout[DATA_WIDTH+L2_AWIDTH_NOAL+DATASIZE_BITS+DEST_SIZE+STREAM_ID_WIDTH];
    assign s_l2_bytes       = s_fifoout[INTFIFO_L2_SIZE-1:INTFIFO_L2_SIZE-CURR_BYTES_BITS];
                                      
    assign s_req[N_LIN_CHANNELS-1:0]             = lin_ch_valid_i & s_ch_en;
    assign s_req[N_CHANNELS_RX-1:N_LIN_CHANNELS] = ext_ch_valid_i;

    assign l2_be_o   = s_l2_be;

    assign s_stream_sot  = s_fifoout_stream[INTFIFO_FILTER_SIZE-1];
    assign s_stream_eot  = s_fifoout_stream[INTFIFO_FILTER_SIZE-2];
    assign s_stream_dest = s_fifoout_stream[DATA_WIDTH+DATASIZE_BITS+STREAM_ID_WIDTH-1:DATA_WIDTH+DATASIZE_BITS];
    assign s_stream_size = s_fifoout_stream[DATA_WIDTH+DATASIZE_BITS-1:DATA_WIDTH];
    assign s_stream_data = s_fifoout_stream[DATA_WIDTH-1:0];
    assign s_stream_ready_demux = s_stream_ready[s_stream_dest];

    assign s_stream_storel2 = s_is_stream & s_stream_use_buff;  //stream is going to L2 buffer
    assign s_stream_direct  = s_is_stream & !s_stream_use_buff; //stream is going directly to streaming unit

    assign s_target_l2     = s_stream_storel2 | ~s_is_stream; //push to L2 when not a stream or when a stream and L2 buffer is used
    assign s_target_stream = s_stream_direct;                 //push to stream fifo only when is stream and not using L2 buffer

    assign s_sample_indata = s_sample_indata_stream & s_sample_indata_l2; //sample only when there is space on output fifos. 
                                                                          //Both have to be free since we do not know where we'll push

    assign s_push_l2     = r_anygrant & s_target_l2;     //push to L2 when regular transfer of stream transfer but L2 buffer used
    assign s_push_filter = r_anygrant & s_target_stream; //push directly to filter only when not using L2 buffer

    assign l2_req_o = s_l2_req;
    assign s_l2_req_stream = s_l2_req & s_l2_is_stream; //used to spoof the transactions in the streaming unit and update the wr pointer for the L2 buffer

    assign s_l2_addr_na = s_l2_addr[L2_AWIDTH_NOAL-1:ALIGN_BITS] + 1; //ask for following word

    always_comb 
    begin
      if(!s_is_na)
        l2_addr_o  = {{(32-L2_AWIDTH_NOAL){1'b0}},s_l2_addr[L2_AWIDTH_NOAL-1:ALIGN_BITS],{ALIGN_BITS{1'b0}}};
      else
        l2_addr_o  = {{(32-L2_AWIDTH_NOAL){1'b0}},s_l2_addr_na,{ALIGN_BITS{1'b0}}};

      case(s_l2_dest)
        2'b00:
            l2_addr_o[31:24]  = 8'h1C;
        2'b01:
            l2_addr_o[31:20]  = 12'h1A1;
        2'b10:
            l2_addr_o[31:24]  = 8'h10;
        default:
            l2_addr_o[31:24]  = 8'h1C;
        endcase // s_fifo_l2_destination    
    end

    udma_arbiter #(
      .N(N_CHANNELS_RX),
      .S(LOG_N_CHANNELS)
      ) u_arbiter (
        .clk_i       ( clk_i           ),
        .rstn_i      ( rstn_i          ),
        .req_i       ( s_req           ),
        .grant_o     ( s_grant         ),
        .grant_ack_i ( s_sample_indata ),
        .anyGrant_o  ( s_anygrant      )
      );

    io_generic_fifo #(
      .DATA_WIDTH(INTFIFO_L2_SIZE),
      .BUFFER_DEPTH(4)
      ) u_fifo (
        .clk_i      ( clk_i              ),
        .rstn_i     ( rstn_i             ),
        .elements_o ( ),
        .clr_i      ( 1'b0               ),
        .data_o     ( s_fifoout          ),
        .valid_o    ( s_l2_req           ),
        .ready_i    ( s_l2_gnt           ),
        .valid_i    ( s_push_l2          ),
        .data_i     ( s_fifoin           ),
        .ready_o    ( s_sample_indata_l2 )
        );

    io_generic_fifo #(
      .DATA_WIDTH(INTFIFO_FILTER_SIZE),
      .BUFFER_DEPTH(4)
      ) u_filter_fifo (
        .clk_i      ( clk_i                  ),
        .rstn_i     ( rstn_i                 ),
        .elements_o ( ),
        .clr_i      ( 1'b0                   ),
        .data_o     ( s_fifoout_stream       ),
        .valid_o    ( s_stream_valid         ),
        .ready_i    ( s_stream_ready_demux   ),
        .valid_i    ( s_push_filter          ),
        .data_i     ( s_fifoin_stream        ),
        .ready_o    ( s_sample_indata_stream )
        );

    always_comb begin
      s_combo_rstn[0]  = rstn_i & sw_rstn_uart_i[0];
      s_combo_rstn[1]  = rstn_i & sw_rstn_uart_i[1];
      s_combo_rstn[2]  = rstn_i & sw_rstn_uart_i[2];
      s_combo_rstn[3]  = rstn_i & sw_rstn_uart_i[3];
      s_combo_rstn[4]  = rstn_i & sw_rstn_spim_i[0];
      s_combo_rstn[5]  = rstn_i & sw_rstn_spim_i[1];
      s_combo_rstn[6]  = rstn_i & sw_rstn_spim_i[2];
      s_combo_rstn[7]  = rstn_i & sw_rstn_spim_i[3];
      s_combo_rstn[8]  = rstn_i & sw_rstn_i2c_i[0];
      s_combo_rstn[9]  = rstn_i & sw_rstn_i2c_i[1];
      s_combo_rstn[10] = rstn_i & sw_rstn_i2c_i[2];
      s_combo_rstn[11] = rstn_i & sw_rstn_i2c_i[3];
      s_combo_rstn[12] = rstn_i & sw_rstn_sdio_i;
      s_combo_rstn[13] = rstn_i & sw_rstn_i2s_i;
      s_combo_rstn[14] = rstn_i & sw_rstn_cam_i;
      s_combo_rstn[15] = rstn_i & sw_rstn_scif_i;
      s_combo_rstn[16] = rstn_i & sw_rstn_spis_i[0];
      s_combo_rstn[17] = rstn_i & sw_rstn_spis_i[1];
      s_combo_rstn[18] = rstn_i & sw_rstn_adc_i;
    end

    genvar j;
    generate
      for (j=0;j<N_LIN_CHANNELS;j++)
      begin
        udma_ch_addrgen #(
          .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
          .TRANS_SIZE(TRANS_SIZE),
          .STREAM_ID_WIDTH(STREAM_ID_WIDTH)
        ) u_rx_ch_ctrl (
          .clk_i               ( clk_i                      ),
          .rstn_i              ( s_combo_rstn[j]            ),
          .cfg_startaddr_i     ( lin_ch_cfg_startaddr_i[j]  ),
          .cfg_size_i          ( lin_ch_cfg_size_i[j]       ),
          .cfg_continuous_i    ( lin_ch_cfg_continuous_i[j] ),
          .cfg_stream_i        ( lin_ch_cfg_stream_i[j]     ),
          .cfg_stream_id_i     ( lin_ch_cfg_stream_id_i[j]  ),
          .cfg_en_i            ( lin_ch_cfg_en_i[j]         ),
          .cfg_clr_i           ( lin_ch_cfg_clr_i[j]        ),
          .int_datasize_i      ( r_size                     ),
          .int_not_stall_i     ( s_sample_indata            ),
          .int_ch_curr_addr_o  ( s_curr_addr[j]             ),
          .int_ch_curr_bytes_o ( s_curr_bytes[j]            ),
          .int_ch_bytes_left_o ( lin_ch_bytes_left_o[j]     ),
          .int_ch_grant_i      ( r_grant[j]                 ),
          .int_ch_en_o         ( ),
          .int_ch_en_prev_o    ( s_ch_en[j]                 ),
          .int_ch_pending_o    ( lin_ch_pending_o[j]        ),
          .int_ch_sot_o        ( s_ch_sot[j]                ),
          .int_ch_events_o     ( s_ch_events[j]             ),
          .int_stream_o        ( s_stream_cfg[j]            ),
          .int_stream_id_o     ( s_stream_id_cfg[j]         )
        );
      end
    endgenerate

    genvar k;
    generate
      for (k=0;k<N_STREAMS;k++)
      begin
        udma_stream_unit #(
          .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
          .STREAM_ID_WIDTH(STREAM_ID_WIDTH),
          .INST_ID(k)
        ) i_stream_unit (
          .clk_i                 ( clk_i                ),
          .rstn_i                ( rstn_i               ),
          .cmd_clr_i             ( 1'b0 ),
          .tx_ch_req_o           ( tx_ch_req_o[k]       ),
          .tx_ch_addr_o          ( tx_ch_addr_o[k]      ),
          .tx_ch_datasize_o      ( tx_ch_datasize_o[k]  ),
          .tx_ch_gnt_i           ( tx_ch_gnt_i[k]       ),
          .tx_ch_valid_i         ( tx_ch_valid_i[k]     ),
          .tx_ch_data_i          ( tx_ch_data_i[k]      ),
          .tx_ch_ready_o         ( tx_ch_ready_o[k]     ),
          .in_stream_dest_i      ( s_stream_dest        ),
          .in_stream_data_i      ( s_stream_data        ),
          .in_stream_datasize_i  ( s_stream_size        ),
          .in_stream_valid_i     ( s_stream_valid       ),
          .in_stream_sot_i       ( s_stream_sot         ),
          .in_stream_eot_i       ( s_stream_eot         ),
          .in_stream_ready_o     ( s_stream_ready[k]    ),
          .out_stream_data_o     ( stream_data_o[k]     ),
          .out_stream_datasize_o ( stream_datasize_o[k] ),
          .out_stream_valid_o    ( stream_valid_o[k]    ),
          .out_stream_sot_o      ( stream_sot_o[k]      ),
          .out_stream_eot_o      ( stream_eot_o[k]      ),
          .out_stream_ready_i    ( stream_ready_i[k]    ),
          .spoof_addr_i          ( s_l2_addr            ),
          .spoof_dest_i          ( s_l2_stream_id       ),
          .spoof_datasize_i      ( s_l2_transf_size     ),
          .spoof_req_i           ( s_l2_req_stream      ),
          .spoof_gnt_i           ( s_l2_gnt             )
        );
      end
    endgenerate


    always_comb 
    begin
      s_grant_log = 0;
      for(int i=0;i<N_CHANNELS_RX;i++)
        if(r_grant[i])
          s_grant_log = i;    
    end
    
    always_comb 
    begin: default_bytes
        case(r_size)
        2'b00:
          s_default_bytes = 'h0;
        2'b01:
          s_default_bytes = 'h1;
        2'b10:
          s_default_bytes = 'h3;        
        default : 
          s_default_bytes = 'h0;
        endcase
    end

    always_comb 
    begin: inside_mux
      s_addr      =  'h0;
      s_bytes     =  'h0;
      s_stream_id =  'h0;
      s_is_stream = 1'b0;
      s_stream_use_buff  = 1'b0;
      s_eot       = 1'b0;
      s_sot       = 1'b0;
      for(int i=0;i<N_LIN_CHANNELS;i++)
      begin
        if(r_grant[i])
        begin
          s_addr      = s_curr_addr[i];
          s_bytes     = s_curr_bytes[i];
          s_is_stream = s_stream_cfg[i][1];
          s_stream_use_buff  = s_stream_cfg[i][0];
          s_stream_id = s_stream_id_cfg[i];
          s_eot       = s_ch_events[i];
          s_sot       = s_ch_sot[i];
        end
      end
      for(int i=0;i<N_EXT_CHANNELS;i++)
      begin
        if(r_grant[N_LIN_CHANNELS+i])
        begin
          s_addr      = r_ext_addr;
          s_bytes     = s_default_bytes;
          s_is_stream = r_ext_stream[1];
          s_stream_use_buff  = r_ext_stream[0];
          s_stream_id = r_ext_stream_id;
          s_sot       = r_ext_sot;
          s_eot       = r_ext_eot;
        end
      end
    end

    always_comb
    begin: input_mux
      s_size = 0;
      s_data = 0;
      s_dest = 0;
      for(int i=0;i<N_LIN_CHANNELS;i++)
      begin
        if(s_grant[i])
        begin
          s_size = lin_ch_datasize_i[i];
          s_data = lin_ch_data_i[i];
          s_dest = lin_ch_destination_i[i];
          lin_ch_ready_o[i] = s_sample_indata;
        end
        else
          lin_ch_ready_o[i] = 1'b0; 
      end
      for(int i=0;i<N_EXT_CHANNELS;i++) 
      begin
        if(s_grant[N_LIN_CHANNELS+i])
        begin
          ext_ch_ready_o[i] = s_sample_indata;
          s_size = ext_ch_datasize_i[i];
          s_data = ext_ch_data_i[i];
          s_dest = ext_ch_destination_i[i];
        end
        else
          ext_ch_ready_o[i] = 1'b0;
      end
    end

    always_comb
    begin
      s_detect_na = 1'b0;
      case (s_l2_transf_size)
      2'h1:
            begin
               if     (s_l2_addr[1:0] == 2'b11) s_detect_na = 1'b1;
            end
      2'h2:
            begin
               if     (s_l2_addr[0] || s_l2_addr[1]) s_detect_na = 1'b1;
            end
      endcase 
    end

    always_comb begin : proc_RX_SM
      s_rx_state_next       = r_rx_state;
      s_l2_gnt = 1'b0;
      s_is_na  = 1'b0;
      case(r_rx_state)
        RX_IDLE:
        begin
          if(s_detect_na)
          begin
            s_l2_gnt = 1'b0;
            if(l2_gnt_i)
              s_rx_state_next = RX_NON_ALIGNED;
          end
          else
            s_l2_gnt = l2_gnt_i;
        end
        RX_NON_ALIGNED:
        begin
          s_is_na = 1'b1;
          s_l2_gnt = l2_gnt_i;
          if(l2_gnt_i)
            s_rx_state_next = RX_IDLE;
        end
      endcase
    end

      
    always_ff @(posedge clk_i or negedge rstn_i) 
    begin : ff_data
      if(~rstn_i) begin
         r_data       <=  'h0;
         r_grant      <=  'h0;
         r_anygrant   <=  'h0;
         r_size       <=  'h0;
         r_dest       <=  'h0;
         r_ext_addr   <=  'h0;
         r_ext_stream <=  'h0;
         r_ext_stream_id <=  'h0;
         r_ext_sot    <=  'h0;
         r_ext_eot    <=  'h0;
         r_rx_state   <=  RX_IDLE;
      end else begin
        r_rx_state <= s_rx_state_next;
         if (s_sample_indata)
         begin
              r_data     <= s_data;
              r_size     <= s_size;
              r_grant    <= s_grant;
              r_anygrant <= s_anygrant;
              r_dest     <= s_dest;
              for(int i=0; i<N_EXT_CHANNELS;i++)
                if(s_grant[N_LIN_CHANNELS+i])
                begin
                  r_ext_addr   <= ext_ch_addr_i[i];
                  r_ext_stream <= ext_ch_stream_i[i];
                  r_ext_stream_id <= ext_ch_stream_id_i[i];
                  r_ext_sot    <= ext_ch_sot_i[i];
                  r_ext_eot    <= ext_ch_eot_i[i];
                end
         end
      end
    end
   
    generate
      if (L2_DATA_WIDTH == 64)
      begin   
        always_comb
        begin
          case (s_l2_transf_size)
          2'h0:
                begin
                   if     (s_l2_addr[2:0] == 3'b000) s_l2_be = 8'b00000001;
                   else if(s_l2_addr[2:0] == 3'b001) s_l2_be = 8'b00000010;
                   else if(s_l2_addr[2:0] == 3'b010) s_l2_be = 8'b00000100;
                   else if(s_l2_addr[2:0] == 3'b011) s_l2_be = 8'b00001000;
                   else if(s_l2_addr[2:0] == 3'b100) s_l2_be = 8'b00010000;
                   else if(s_l2_addr[2:0] == 3'b101) s_l2_be = 8'b00100000;
                   else if(s_l2_addr[2:0] == 3'b110) s_l2_be = 8'b01000000;
                   else                              s_l2_be = 8'b10000000;
                end
          2'h1:
                begin
                   if(s_l2_addr[2:1] == 2'b00)      s_l2_be = 8'b00000011;
                   else if(s_l2_addr[2:1] == 2'b01) s_l2_be = 8'b00001100;
                   else if(s_l2_addr[2:1] == 2'b10) s_l2_be = 8'b00110000;
                   else                             s_l2_be = 8'b11000000;
                end
          2'h2: 
                begin
                   if(s_l2_addr[2] == 1'b0)         s_l2_be = 8'b00001111;
                   else                             s_l2_be = 8'b11110000;
                end
          default:                                  s_l2_be = 8'b00000000;  // default to 64-bit access
          endcase 
        end
        always_comb
        begin
          case (s_l2_be)
            8'b00001111: l2_wdata_o = {32'h0, s_l2_data[31:0]       };
            8'b11110000: l2_wdata_o = {       s_l2_data[31:0], 32'h0};
            8'b00000011: l2_wdata_o = {48'h0, s_l2_data[15:0]       };
            8'b00001100: l2_wdata_o = {32'h0, s_l2_data[15:0], 16'h0};
            8'b00110000: l2_wdata_o = {16'h0, s_l2_data[15:0], 32'h0};
            8'b11000000: l2_wdata_o = {       s_l2_data[15:0], 48'h0};
            8'b00000001: l2_wdata_o = {56'h0, s_l2_data[7:0]        };
            8'b00000010: l2_wdata_o = {48'h0, s_l2_data[7:0],   8'h0};
            8'b00000100: l2_wdata_o = {40'h0, s_l2_data[7:0],  16'h0};
            8'b00001000: l2_wdata_o = {32'h0, s_l2_data[7:0],  24'h0};
            8'b00010000: l2_wdata_o = {24'h0, s_l2_data[7:0],  32'h0};
            8'b00100000: l2_wdata_o = {16'h0, s_l2_data[7:0],  40'h0};
            8'b01000000: l2_wdata_o = { 8'h0, s_l2_data[7:0],  48'h0};
            8'b10000000: l2_wdata_o = {       s_l2_data[7:0],  56'h0};
            default: l2_wdata_o = 64'hDEADABBADEADBEEF;  // Shouldn't be possible
          endcase
        end
    end
    else if (L2_DATA_WIDTH == 32)
    begin
        always_comb
        begin
          case (s_l2_transf_size)
          2'h0:
                begin
                   if     (s_l2_addr[1:0] == 2'b00) s_l2_be = 4'b0001;
                   else if(s_l2_addr[1:0] == 2'b01) s_l2_be = 4'b0010;
                   else if(s_l2_addr[1:0] == 2'b10) s_l2_be = 4'b0100;
                   else                             s_l2_be = 4'b1000;
                end
          2'h1:
                begin
                    if(s_l2_bytes == 2'h0)
                    begin
                        if     (s_l2_addr[1:0] == 2'b00) s_l2_be = 4'b0001;
                        else if(s_l2_addr[1:0] == 2'b01) s_l2_be = 4'b0010;
                        else if(s_l2_addr[1:0] == 2'b10) s_l2_be = 4'b0100;
                        else                             s_l2_be = s_is_na ? 4'b0000 : 4'b1000;
                    end
                    else
                    begin
                        if     (s_l2_addr[1:0] == 2'b00) s_l2_be = 4'b0011;
                        else if(s_l2_addr[1:0] == 2'b01) s_l2_be = 4'b0110;
                        else if(s_l2_addr[1:0] == 2'b10) s_l2_be = 4'b1100;
                        else                             s_l2_be = s_is_na ? 4'b0001 : 4'b1000;
                    end
                end
          2'h2: 
                begin
                    if(s_l2_bytes == 2'h0)
                    begin
                        if     (s_l2_addr[1:0] == 2'b00) s_l2_be = 4'b0001;
                        else if(s_l2_addr[1:0] == 2'b01) s_l2_be = s_is_na ? 4'b0000 : 4'b0010;
                        else if(s_l2_addr[1:0] == 2'b10) s_l2_be = s_is_na ? 4'b0000 : 4'b0100;
                        else                             s_l2_be = s_is_na ? 4'b0000 : 4'b1000;
                    end
                    else if(s_l2_bytes == 2'h1)
                    begin
                        if     (s_l2_addr[1:0] == 2'b00) s_l2_be = 4'b0011;
                        else if(s_l2_addr[1:0] == 2'b01) s_l2_be = s_is_na ? 4'b0000 : 4'b0110;
                        else if(s_l2_addr[1:0] == 2'b10) s_l2_be = s_is_na ? 4'b0000 : 4'b1100;
                        else                             s_l2_be = s_is_na ? 4'b0001 : 4'b1000;
                    end
                    else if(s_l2_bytes == 2'h2)
                    begin
                        if     (s_l2_addr[1:0] == 2'b00) s_l2_be = 4'b0111;
                        else if(s_l2_addr[1:0] == 2'b01) s_l2_be = s_is_na ? 4'b0000 : 4'b1110;
                        else if(s_l2_addr[1:0] == 2'b10) s_l2_be = s_is_na ? 4'b0001 : 4'b1100;
                        else                             s_l2_be = s_is_na ? 4'b0011 : 4'b1000;
                    end
                    else
                    begin
                        if     (s_l2_addr[1:0] == 2'b00) s_l2_be = 4'b1111;
                        else if(s_l2_addr[1:0] == 2'b01) s_l2_be = s_is_na ? 4'b0001 : 4'b1110;
                        else if(s_l2_addr[1:0] == 2'b10) s_l2_be = s_is_na ? 4'b0011 : 4'b1100;
                        else                             s_l2_be = s_is_na ? 4'b0111 : 4'b1000;
                    end
                end
          default:                                  s_l2_be = 4'b0000; 
          endcase 
      end
      
      always_comb
      begin
        case (s_l2_transf_size)
        2'h0:
                begin
                   if     (s_l2_addr[1:0] == 2'b00) l2_wdata_o = {24'h0, s_l2_data[7:0]        };
                   else if(s_l2_addr[1:0] == 2'b01) l2_wdata_o = {16'h0, s_l2_data[7:0],   8'h0};
                   else if(s_l2_addr[1:0] == 2'b10) l2_wdata_o = { 8'h0, s_l2_data[7:0],  16'h0};
                   else                             l2_wdata_o = {       s_l2_data[7:0],  24'h0};
                end
        2'h1:
                begin
                   if     (s_l2_addr[1:0] == 2'b00) l2_wdata_o = {16'h0, s_l2_data[15:0]       };
                   else if(s_l2_addr[1:0] == 2'b01) l2_wdata_o = { 8'h0, s_l2_data[15:0],  8'h0};
                   else if(s_l2_addr[1:0] == 2'b10) l2_wdata_o = {       s_l2_data[15:0], 16'h0};
                   else                             l2_wdata_o = s_is_na ? {24'h0, s_l2_data[15:8] } : {s_l2_data[7:0], 24'h0 };
                end
        2'h2: 
                begin
                   if     (s_l2_addr[1:0] == 2'b00) l2_wdata_o = s_l2_data[31:0];
                   else if(s_l2_addr[1:0] == 2'b01) l2_wdata_o = s_is_na ? {24'h0, s_l2_data[31:24] } : {s_l2_data[23:0],  8'h0 };
                   else if(s_l2_addr[1:0] == 2'b10) l2_wdata_o = s_is_na ? {16'h0, s_l2_data[31:16] } : {s_l2_data[15:0], 16'h0 };
                   else                             l2_wdata_o = s_is_na ? { 8'h0, s_l2_data[31:8]  } : {s_l2_data[7:0] , 24'h0 };
                end
        default:                                    l2_wdata_o = 32'hDEADBEEF;  // Shouldn't be possible
        endcase 
      end
    end
  endgenerate
endmodule
