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
// Description: TX channels for uDMA IP
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////


module udma_tx_channels
  #(
    parameter L2_AWIDTH_NOAL = 20,
    parameter L2_DATA_WIDTH  = 64,
    parameter DATA_WIDTH     = 32,
    parameter N_LIN_CHANNELS     = 8,
    parameter N_EXT_CHANNELS = 8,
    parameter TRANS_SIZE     = 16,
    parameter STREAM_ID_WIDTH = 1
    )
   (
    input  logic	                        clk_i,
    input  logic                          rstn_i,
    input  logic [3:0]                    sw_rstn_uart_i,
    input  logic [3:0]                    sw_rstn_spim_i,
    input  logic [3:0]                    sw_rstn_i2c_i,
    input  logic                          sw_rstn_sdio_i,
    input  logic                          sw_rstn_i2s_i,
    input  logic                          sw_rstn_scif_i,
    input  logic [1:0]                    sw_rstn_spis_i,
    
    output logic                           l2_req_o,
    input  logic                           l2_gnt_i,
    output logic                 [31 : 0]  l2_addr_o,

    input  logic    [L2_DATA_WIDTH-1 : 0]  l2_rdata_i,
    input  logic                           l2_rvalid_i,

    input  logic [N_EXT_CHANNELS-1:0]                        ext_req_i,
    input  logic [N_EXT_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] ext_addr_i,
    input  logic [N_EXT_CHANNELS-1:0]                [1 : 0] ext_datasize_i,
    input  logic [N_EXT_CHANNELS-1:0]                [1 : 0] ext_destination_i,
    output logic [N_EXT_CHANNELS-1:0]                        ext_gnt_o,
    output logic [N_EXT_CHANNELS-1:0]                        ext_valid_o,
    output logic [N_EXT_CHANNELS-1:0]     [DATA_WIDTH-1 : 0] ext_data_o,
    input  logic [N_EXT_CHANNELS-1:0]                        ext_ready_i,

    input  logic [N_LIN_CHANNELS-1:0]                [1 : 0] lin_datasize_i,
    input  logic [N_LIN_CHANNELS-1:0]                [1 : 0] lin_destination_i,
    input  logic [N_LIN_CHANNELS-1:0]                        lin_req_i,
    output logic [N_LIN_CHANNELS-1:0]                        lin_gnt_o,
    output logic [N_LIN_CHANNELS-1:0]                        lin_valid_o,
    output logic [N_LIN_CHANNELS-1:0]     [DATA_WIDTH-1 : 0] lin_data_o,
    input  logic [N_LIN_CHANNELS-1:0]                        lin_ready_i,
    output logic [N_LIN_CHANNELS-1:0]                        lin_events_o,
    output logic [N_LIN_CHANNELS-1:0]                        lin_en_o,
    output logic [N_LIN_CHANNELS-1:0]                        lin_pending_o,
    output logic [N_LIN_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] lin_curr_addr_o,
    output logic [N_LIN_CHANNELS-1:0]     [TRANS_SIZE-1 : 0] lin_bytes_left_o,

    input  logic [N_LIN_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] lin_cfg_startaddr_i,
    input  logic [N_LIN_CHANNELS-1:0]     [TRANS_SIZE-1 : 0] lin_cfg_size_i,
    input  logic [N_LIN_CHANNELS-1:0]                        lin_cfg_continuous_i,
    input  logic [N_LIN_CHANNELS-1:0]                        lin_cfg_en_i,
    input  logic [N_LIN_CHANNELS-1:0]                        lin_cfg_clr_i

    );

    localparam  DATASIZE_WIDTH = 2;
    localparam  DEST_WIDTH     = 2;

    localparam N_CHANNELS_TX  = N_LIN_CHANNELS+N_EXT_CHANNELS;
    localparam ALIGN_BITS     = $clog2(L2_DATA_WIDTH/8);
    localparam LOG_N_CHANNELS = $clog2(N_CHANNELS_TX);
    localparam INTFIFO_SIZE   = L2_AWIDTH_NOAL + LOG_N_CHANNELS + DATASIZE_WIDTH + DEST_WIDTH;//store addr_data and size and request

    integer i;
   
   // Internal signals

    logic        [N_CHANNELS_TX-1:0] s_grant;
    logic        [N_CHANNELS_TX-1:0] r_grant;
    logic        [N_CHANNELS_TX-1:0] s_req;
    logic        [N_CHANNELS_TX-1:0] s_gnt;
    logic       [LOG_N_CHANNELS-1:0] s_grant_log;
    logic        [N_CHANNELS_TX-1:0] s_ch_ready;
    logic       [N_LIN_CHANNELS-1:0] s_ch_en;
    logic       [LOG_N_CHANNELS-1:0] r_resp;
    logic       [LOG_N_CHANNELS-1:0] r_resp_dly;

    logic                        r_valid;

    logic                        s_anygrant;
    logic                        r_anygrant;

    logic                        s_send_req;

    logic                      [L2_AWIDTH_NOAL-1:0] s_addr;
    logic [N_CHANNELS_TX-1:0]  [L2_AWIDTH_NOAL-1:0] s_curr_addr;
    logic                      [L2_AWIDTH_NOAL-1:0] r_in_addr;

    logic                  [1:0] s_size;
    logic       [DATA_WIDTH-1:0] s_data;
    logic                  [1:0] r_size;
    logic       [DATA_WIDTH-1:0] r_data;
    logic       [ALIGN_BITS-1:0] r_addr;

    logic                  [1:0] s_in_size;
    logic                  [1:0] r_in_size;
    logic                  [1:0] s_in_dest;
    logic                  [1:0] r_in_dest;

    logic         [INTFIFO_SIZE-1:0] s_fifoin;
    logic         [INTFIFO_SIZE-1:0] s_fifoout;

    logic       [ALIGN_BITS-1:0] s_fifo_addr_lsb;
    logic   [L2_AWIDTH_NOAL-1:0] s_fifo_l2_addr;
    logic       [DEST_WIDTH-1:0] s_fifo_l2_dest;
    logic                  [1:0] s_fifo_trans_size;
    logic   [LOG_N_CHANNELS-1:0] s_fifo_resp;

    logic [L2_AWIDTH_NOAL-ALIGN_BITS-1:0] s_l2_addr_na; //used for non aligned transfers

    logic s_l2_req;
    logic s_l2_gnt;

    logic s_stall;
    logic s_sample_indata;

    logic s_is_na;
    logic r_is_na;
    logic s_detect_na;

    logic [24:0] s_combo_rstn;

    enum logic {TX_IDLE,TX_NON_ALIGNED} r_tx_state,s_tx_state_next;

    assign lin_curr_addr_o = s_curr_addr;
    assign lin_en_o = s_ch_en;
    assign s_fifoin = {r_in_dest,s_grant_log,r_in_size,s_addr[L2_AWIDTH_NOAL-1:0]};

    assign s_fifo_l2_addr    = s_fifoout[L2_AWIDTH_NOAL-1:0];
    assign s_fifo_addr_lsb   = s_fifoout[ALIGN_BITS-1:0];
    assign s_fifo_trans_size = s_fifoout[L2_AWIDTH_NOAL+DATASIZE_WIDTH-1:L2_AWIDTH_NOAL];
    assign s_fifo_resp       = s_fifoout[L2_AWIDTH_NOAL+DATASIZE_WIDTH+LOG_N_CHANNELS-1:L2_AWIDTH_NOAL+DATASIZE_WIDTH];
    assign s_fifo_l2_dest    = s_fifoout[INTFIFO_SIZE-1:L2_AWIDTH_NOAL+DATASIZE_WIDTH+LOG_N_CHANNELS];

    assign s_l2_addr_na = s_fifo_l2_addr[L2_AWIDTH_NOAL-1:ALIGN_BITS] + 1; //ask for following word

    assign s_req[N_LIN_CHANNELS-1:0] = lin_req_i & s_ch_en;
    assign s_req[N_CHANNELS_TX-1:N_LIN_CHANNELS] = ext_req_i;

    assign s_gnt = s_sample_indata ? s_grant : 'h0;

    assign s_send_req = r_anygrant;

    assign l2_req_o = s_l2_req & ~s_stall;

    assign lin_gnt_o = s_gnt[N_LIN_CHANNELS-1:0];
    assign ext_gnt_o = s_gnt[N_CHANNELS_TX-1:N_LIN_CHANNELS];

    always_comb 
    begin
      if(!s_is_na)
        l2_addr_o  = {{(32-L2_AWIDTH_NOAL){1'b0}},s_fifo_l2_addr[L2_AWIDTH_NOAL-1:ALIGN_BITS],{ALIGN_BITS{1'b0}}};
      else
        l2_addr_o  = {{(32-L2_AWIDTH_NOAL){1'b0}},s_l2_addr_na,{ALIGN_BITS{1'b0}}};

      case(s_fifo_l2_dest)
        2'b00:
        begin
            l2_addr_o[31:24]  = 8'h1C;
        end
        2'b01:
        begin
            l2_addr_o[31:20]  = 12'h1A1;
        end
        2'b10:
        begin
            l2_addr_o[31:24]  = 8'h10;
        end
        default:
        begin
            l2_addr_o[31:24]  = 8'h1C;
        end
        endcase // s_fifo_l2_destination    
    end

    udma_arbiter #(
      .N(N_CHANNELS_TX),
      .S(LOG_N_CHANNELS)
      ) u_arbiter (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .req_i(s_req),
        .grant_o(s_grant),
        .grant_ack_i(s_sample_indata),
        .anyGrant_o(s_anygrant)
      );

    io_generic_fifo #(
      .DATA_WIDTH(INTFIFO_SIZE),
      .BUFFER_DEPTH(4)
      ) u_fifo (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .elements_o(),
        .clr_i(1'b0),
        .data_o(s_fifoout),
        .valid_o(s_l2_req),
        .ready_i(s_l2_gnt),
        .valid_i(s_send_req),
        .data_i(s_fifoin),
        .ready_o(s_sample_indata)
        );

    always_comb begin
      s_combo_rstn[0]  = rstn_i & sw_rstn_uart_i[0];
      s_combo_rstn[1]  = rstn_i & sw_rstn_uart_i[1];
      s_combo_rstn[2]  = rstn_i & sw_rstn_uart_i[2];
      s_combo_rstn[3]  = rstn_i & sw_rstn_uart_i[3];
      s_combo_rstn[4]  = rstn_i & sw_rstn_spim_i[0]; // tx
      s_combo_rstn[5]  = rstn_i & sw_rstn_spim_i[1];
      s_combo_rstn[6]  = rstn_i & sw_rstn_spim_i[2];
      s_combo_rstn[7]  = rstn_i & sw_rstn_spim_i[3];
      s_combo_rstn[8]  = rstn_i & sw_rstn_spim_i[0]; // cmd
      s_combo_rstn[9]  = rstn_i & sw_rstn_spim_i[1];
      s_combo_rstn[10] = rstn_i & sw_rstn_spim_i[2];
      s_combo_rstn[11] = rstn_i & sw_rstn_spim_i[3];
      s_combo_rstn[12] = rstn_i & sw_rstn_i2c_i[0]; // tx
      s_combo_rstn[13] = rstn_i & sw_rstn_i2c_i[1];
      s_combo_rstn[14] = rstn_i & sw_rstn_i2c_i[2];
      s_combo_rstn[15] = rstn_i & sw_rstn_i2c_i[3];
      s_combo_rstn[16] = rstn_i & sw_rstn_i2c_i[0]; // cmd
      s_combo_rstn[17] = rstn_i & sw_rstn_i2c_i[1];
      s_combo_rstn[18] = rstn_i & sw_rstn_i2c_i[2];
      s_combo_rstn[19] = rstn_i & sw_rstn_i2c_i[3];
      s_combo_rstn[20] = rstn_i & sw_rstn_sdio_i;
      s_combo_rstn[21] = rstn_i & sw_rstn_i2s_i;
      s_combo_rstn[22] = rstn_i & sw_rstn_scif_i;
      s_combo_rstn[23] = rstn_i & sw_rstn_spis_i[0];
      s_combo_rstn[24] = rstn_i & sw_rstn_spis_i[1];
    end

    genvar j;
    generate
      for (j=0;j<N_LIN_CHANNELS;j++)
      begin
        udma_ch_addrgen #(
          .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
          .TRANS_SIZE(TRANS_SIZE),
          .STREAM_ID_WIDTH(STREAM_ID_WIDTH)
        ) u_tx_ch_ctrl (
          .clk_i(clk_i),
          .rstn_i(s_combo_rstn[j]),
          .cfg_startaddr_i(lin_cfg_startaddr_i[j]),
          .cfg_size_i(lin_cfg_size_i[j]),
          .cfg_continuous_i(lin_cfg_continuous_i[j]),
          .cfg_stream_i(2'b00),
          .cfg_stream_id_i({STREAM_ID_WIDTH{1'b0}}),
          .cfg_en_i(lin_cfg_en_i[j]),
          .cfg_clr_i(lin_cfg_clr_i[j]),
          .int_datasize_i(r_in_size),
          .int_not_stall_i(s_sample_indata),
          .int_ch_curr_addr_o(s_curr_addr[j]),
          .int_ch_bytes_left_o(lin_bytes_left_o[j]),
          .int_ch_grant_i(r_grant[j]),
          .int_ch_curr_bytes_o(),
          .int_ch_en_o(),
          .int_ch_sot_o(),
          .int_ch_en_prev_o(s_ch_en[j]),
          .int_ch_pending_o(lin_pending_o[j]),
          .int_ch_events_o(lin_events_o[j]),
          .int_stream_o(),
          .int_stream_id_o()
        );
      end
    endgenerate

    always_comb 
    begin
      s_grant_log = 0;
      for(int i=0;i<N_CHANNELS_TX;i++)
        if(r_grant[i])
          s_grant_log = i;    
    end

    always_comb 
    begin: inside_mux
      s_addr      =  'h0;
      for(int i=0;i<N_LIN_CHANNELS;i++)
      begin
        if(r_grant[i])
        begin
          s_addr      = s_curr_addr[i];
        end
      end
      for(int i=0;i<N_EXT_CHANNELS;i++)
      begin
        if(r_grant[N_LIN_CHANNELS+i])
        begin
          s_addr      = r_in_addr;
        end
      end
    end


    always_comb
    begin: gen_size
      s_in_size = 0;
      s_in_dest = 0;
      for(int i=0;i<N_LIN_CHANNELS;i++)
        if(s_grant[i])
        begin
          s_in_size = lin_datasize_i[i];
          s_in_dest = lin_destination_i[i];
        end
      for(int i=0;i<N_EXT_CHANNELS;i++)
        if(s_grant[N_LIN_CHANNELS+i])
        begin
          s_in_size = ext_datasize_i[i];
          s_in_dest = ext_destination_i[i];
        end
    end

    always_comb
    begin: demux_data
      for(int i=0;i<N_LIN_CHANNELS;i++)
      begin
        if(r_resp_dly == i)
        begin
          lin_valid_o[i] = r_valid;
          lin_data_o[i]  = r_data;
        end
        else
        begin
          lin_valid_o[i] = 1'b0;
          lin_data_o[i]  = 'hDEADBEEF;
        end
      end
      for(int i=0;i<N_EXT_CHANNELS;i++)
      begin
        if(r_resp_dly == (N_LIN_CHANNELS+i))
        begin
          ext_valid_o[i] = r_valid;
          ext_data_o[i]  = r_data;
        end
        else
        begin
          ext_valid_o[i] = 1'b0;
          ext_data_o[i]  = 'hDEADBEEF;
        end
      end
    end
      
    assign s_ch_ready[N_LIN_CHANNELS-1:0] = lin_ready_i;
    assign s_ch_ready[N_CHANNELS_TX-1:N_LIN_CHANNELS] = ext_ready_i;

    //this may happen only in burst mode when multiple reads are pipelined
    assign s_stall = |(~s_ch_ready & r_resp) & r_valid;    

    always_ff @(posedge clk_i or negedge rstn_i) 
    begin : ff_data
      if(~rstn_i) begin
        r_grant     <=  '0;
        r_anygrant  <=  '0;
        r_resp      <=  '0;
        r_resp_dly  <=  '0;
        r_valid     <=  '0;
        r_in_size   <=  '0;
        r_in_dest   <=  '0;
        r_size      <=  '0;
        r_addr      <=  '0; 
        r_data      <=  '0;
        r_in_addr   <=  '0;
        r_is_na     <=  '0;
        r_tx_state  <= TX_IDLE;
      end else begin
          r_tx_state  <= s_tx_state_next;
          r_valid     <= l2_rvalid_i & ~s_is_na;
          r_resp_dly  <= r_resp;
          r_is_na     <= s_is_na;

          if (l2_rvalid_i)
            r_data <= s_data;
          if (s_l2_req && l2_gnt_i && !s_is_na)
          begin
            r_resp     <= s_fifo_resp;
            r_size     <= s_fifo_trans_size;
            r_addr     <= s_fifo_addr_lsb;
          end
          
         if (s_sample_indata)
         begin
              r_in_size  <= s_in_size;
              r_in_dest  <= s_in_dest;
              r_grant    <= s_grant;
              r_anygrant <= s_anygrant;
              for(int i=0;i<N_EXT_CHANNELS;i++)
                if(s_grant[N_LIN_CHANNELS+i])
                  r_in_addr <= ext_addr_i[i];
         end
      end
    end

    always_comb begin : proc_TX_SM
      s_tx_state_next       = r_tx_state;
      s_l2_gnt = 1'b0;
      s_is_na  = 1'b0;
      case(r_tx_state)
        TX_IDLE:
        begin
          if(s_detect_na)
          begin
            s_l2_gnt = 1'b0;
            if(l2_gnt_i)
              s_tx_state_next = TX_NON_ALIGNED;
          end
          else
            s_l2_gnt = l2_gnt_i;
        end
        TX_NON_ALIGNED:
        begin
          s_is_na = 1'b1;
          s_l2_gnt = l2_gnt_i;
          if(l2_gnt_i)
            s_tx_state_next = TX_IDLE;
        end
      endcase
    end

    always_comb
    begin
      s_detect_na = 1'b0;
      case (s_fifo_trans_size)
      2'h1:
            begin
               if     (s_fifo_addr_lsb == 2'b11) s_detect_na = 1'b1;
            end
      2'h2:
            begin
               if     (s_fifo_addr_lsb[0] || s_fifo_addr_lsb[1]) s_detect_na = 1'b1;
            end
      endcase 
    end

    generate
      if (L2_DATA_WIDTH == 64)
      begin
        always_comb
        begin
          case (r_size)
          2'h0:
                begin
                   if     (r_addr == 3'b000) s_data = {24'h0,l2_rdata_i[7:0]};
                   else if(r_addr == 3'b001) s_data = {24'h0,l2_rdata_i[15:8]};
                   else if(r_addr == 3'b010) s_data = {24'h0,l2_rdata_i[23:16]};
                   else if(r_addr == 3'b011) s_data = {24'h0,l2_rdata_i[31:24]};
                   else if(r_addr == 3'b100) s_data = {24'h0,l2_rdata_i[39:32]};
                   else if(r_addr == 3'b101) s_data = {24'h0,l2_rdata_i[47:40]};
                   else if(r_addr == 3'b110) s_data = {24'h0,l2_rdata_i[55:48]};
                   else                      s_data = {24'h0,l2_rdata_i[63:56]};
                end
          2'h1:
                begin
                   if(r_addr[2:1] == 2'b00)      s_data = {16'h0,l2_rdata_i[15:0]};
                   else if(r_addr[2:1] == 2'b01) s_data = {16'h0,l2_rdata_i[31:16]};
                   else if(r_addr[2:1] == 2'b10) s_data = {16'h0,l2_rdata_i[47:32]};
                   else                          s_data = {16'h0,l2_rdata_i[63:48]};
                end
          2'h2: 
                begin
                   if(r_addr[2] == 1'b0)         s_data = l2_rdata_i[31:0];
                   else                          s_data = l2_rdata_i[63:32];
                end
          default:                               s_data = 32'hDEADBEEF;  // default to 32-bit access
          endcase 
        end
      end
      else if (L2_DATA_WIDTH == 32)
      begin
        always_comb
        begin
          s_data = r_data;
          case (r_size)
          2'h0:
                begin
                   if     (r_addr[1:0] == 2'b00) s_data = {24'h0,l2_rdata_i[7:0]};
                   else if(r_addr[1:0] == 2'b01) s_data = {24'h0,l2_rdata_i[15:8]};
                   else if(r_addr[1:0] == 2'b10) s_data = {24'h0,l2_rdata_i[23:16]};
                   else                          s_data = {24'h0,l2_rdata_i[31:24]};
                end
          2'h1:
                begin
                    if(s_is_na)
                                                  s_data = {24'h0,l2_rdata_i[31:24]};
                    else if(r_is_na)
                                                  s_data[15:8] = l2_rdata_i[7:0];
                    else
                    begin
                      if     (r_addr[1:0] == 2'b00) s_data = {16'h0,l2_rdata_i[15:0]};
                      else if(r_addr[1:0] == 2'b01) s_data = {16'h0,l2_rdata_i[23:8]};
                      else                          s_data = {16'h0,l2_rdata_i[31:16]};
                    end
                end
          2'h2: 
                begin
                    if(s_is_na)
                    begin
                        if     (r_addr[1:0] == 2'b01) s_data = {8'h0,l2_rdata_i[31:8]};
                        else if(r_addr[1:0] == 2'b10) s_data = {16'h0,l2_rdata_i[31:16]};
                        else                          s_data = {24'h0,l2_rdata_i[31:24]}; //(r_addr[1:0] == 2'b11)
                    end
                    else if(r_is_na)
                    begin
                        if     (r_addr[1:0] == 2'b01) s_data[31:24] = l2_rdata_i[7:0];
                        else if(r_addr[1:0] == 2'b10) s_data[31:16] = l2_rdata_i[15:0];
                        else                          s_data[31:8]  = l2_rdata_i[23:0]; //(r_addr[1:0] == 2'b11)
                    end
                    else
                      s_data = l2_rdata_i;
                end
          default:                               s_data = 32'hDEADBEEF;  // default to 32-bit access
          endcase 
        end
      end
    endgenerate



endmodule
