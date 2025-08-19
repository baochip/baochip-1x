// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2016 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Pullini Antonio - pullinia@iis.ee.ethz.ch                  //
//                                                                            //
// Additional contributions by:                                               //
//                 Igor Loi: igor.loi@greenvawes-technologies.com             //
//                                                                            //
// Design Name:    SPI Master Control State Machine                           //
// Project Name:   SPI Master                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    SPI Master with full QPI support                           //
//                                                                            //
// logs:                                                                      //
// 		   14/12/2018: removed unreachable state WAIT_ADDR                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
`include "udma_spim_defines.sv"

module udma_spim_ctrl
#(
    parameter REPLAY_BUFFER_DEPTH = 5
)
(
    input  logic                          clk_i,
    input  logic                          rstn_i,
    output logic                          eot_o,

    input  logic   [3:0]                  event_i,

    output logic                          cfg_cpol_o,
    output logic                          cfg_cpha_o,

    output logic   [7:0]                  cfg_clkdiv_data_o,
    output logic                          cfg_clkdiv_valid_o,
    input  logic                          cfg_clkdiv_ack_i,

    output logic                          tx_start_o,
    output logic  [15:0]                  tx_size_o,
    output logic   [4:0]                  tx_bitsword_o,
    output logic   [1:0]                  tx_wordtransf_o,
    output logic                          tx_lsbfirst_o,
    output logic                          tx_qpi_o,
    input  logic                          tx_done_i,
    output logic  [31:0]                  tx_data_o,
    output logic                          tx_data_valid_o,
    input  logic                          tx_data_ready_i,

    output logic                          rx_start_o,
    output logic  [15:0]                  rx_size_o,
    output logic   [4:0]                  rx_bitsword_o,
    output logic   [1:0]                  rx_wordtransf_o,
    output logic                          rx_lsbfirst_o,
    output logic                          rx_qpi_o,
    input  logic                          rx_done_i,
    input  logic  [31:0]                  rx_data_i,
    input  logic                          rx_data_valid_i,
    output logic                          rx_data_ready_o,

    input  logic  [31:0]                  udma_cmd_i,
    input  logic                          udma_cmd_valid_i,
    output logic                          udma_cmd_ready_o,

    input  logic  [31:0]                  udma_tx_data_i,
    input  logic                          udma_tx_data_valid_i,
    output logic                          udma_tx_data_ready_o,

    output logic  [31:0]                  udma_rx_data_o,
    output logic                          udma_rx_data_valid_o,
    input  logic                          udma_rx_data_ready_i,

    output logic                          spi_csn0_o,
    output logic                          spi_csn1_o,
    output logic                          spi_csn2_o,
    output logic                          spi_csn3_o,

    output logic   [1:0]                  status_o
);

    enum logic [2:0] {IDLE,WAIT_DONE,WAIT_CHECK,WAIT_EVENT,DO_REPEAT,WAIT_CYCLE,CLEAR_CS /*,WAIT_ADDR*/ } state,state_next;

    enum logic [1:0] {STAT_NONE,STAT_CHECK,STAT_EOL} s_status,r_status;
    logic r_cfg_cpol;
    logic r_cfg_cpha;
    logic [7:0] r_cfg_clkdiv;
    logic s_update_cfg;
    logic r_update_cfg;
    logic s_update_qpi;
    logic s_update_cs;
    logic s_update_evt;
    logic s_update_chk;
    logic s_clear_cs;

    logic s_event;

    logic [1:0] r_evt_sel;

    //command decode signals
    logic  [3:0] s_cmd;
    logic        is_cmd_cfg;
    logic        is_cmd_sot;
    logic        is_cmd_snc;
    logic        is_cmd_dum;
    logic        is_cmd_wai;
    logic        is_cmd_txd;
    logic        is_cmd_rxd;
    logic        is_cmd_rxc;
    logic        is_cmd_rpt;
    logic        is_cmd_rpe;
    logic        is_cmd_eot;
    logic        is_cmd_ful;
    logic        is_cmd_wcy;
    logic        is_cmd_uca;
    logic        is_cmd_ucs;

    //command parameters decode signals
    logic        s_cd_cfg_cpol;
    logic        s_cd_cfg_cpha;
    logic  [7:0] s_cd_cfg_clkdiv;
    logic        s_cd_cfg_lsb;
    logic        s_cd_cfg_qpi;
    logic  [1:0] s_cd_cs;
    logic [15:0] s_cd_cfg_check;
    logic [15:0] s_cd_size_long;
    logic [15:0] s_cd_cmd_data;
    logic  [4:0] s_cd_size;
    logic        s_cd_eot_evt;
    logic        s_cd_eot_keep_cs;
    logic  [1:0] s_cd_cfg_chk_type;
    logic  [7:0] s_cd_cs_wait;
    logic  [1:0] s_cd_wait_typ;
    logic  [1:0] s_cd_wait_evt;
    logic  [7:0] s_cd_wait_cyc;

    logic  [1:0] s_cs;
    logic        s_qpi;
    logic        r_qpi;
    logic [15:0] r_chk;
    logic  [1:0] r_chk_type;
    logic        s_is_dummy;
    logic        r_is_dummy;

    logic [15:0] r_rpt_num;
    logic [15:0] s_rpt_num;
    logic        s_setup_replay;
    logic        s_is_replay;


    logic        s_is_ful;
    logic        r_is_ful;

    logic        s_done;
    logic        r_tx_done;
    logic        r_rx_done;

    logic        s_update_chk_result;
    logic        s_chk_result;
    logic        r_chk_result;

    logic        s_update_status;

    logic [32:0] s_replay_buffer_out;
    logic        s_replay_buffer_out_ready;
    logic        s_replay_buffer_out_valid;
    logic [32:0] s_replay_buffer_in;
    logic        s_replay_buffer_in_ready;
    logic        s_replay_buffer_in_valid;
    logic        s_update_rpt;
    logic        r_is_replay;
    logic        s_clr_rpt_buf;

    logic        s_first_replay;
    logic        r_first_replay;

    logic        s_set_first_reply;
    logic        s_clr_first_reply;

    logic [1:0] s_wordstransf;
    logic [1:0] s_cd_wordstransf;
    logic [4:0] s_cd_wordsize;

    assign s_cmd             = r_is_replay ? s_replay_buffer_out[31:28] : udma_cmd_i[31:28];
    assign s_cd_cfg_cpol     = r_is_replay ? s_replay_buffer_out[9]     : udma_cmd_i[9];
    assign s_cd_cfg_cpha     = r_is_replay ? s_replay_buffer_out[8]     : udma_cmd_i[8];
    assign s_cd_cfg_clkdiv   = r_is_replay ? s_replay_buffer_out[7:0]   : udma_cmd_i[7:0];
    assign s_cd_cs           = r_is_replay ? s_replay_buffer_out[1:0]   : udma_cmd_i[1:0];
    assign s_cd_cs_wait      = r_is_replay ? s_replay_buffer_out[15:8]  : udma_cmd_i[15:8];

    assign s_cd_cfg_qpi      = r_is_replay ? s_replay_buffer_out[27]    : udma_cmd_i[27];
    assign s_cd_cfg_lsb      = r_is_replay ? s_replay_buffer_out[26]    : udma_cmd_i[26];
    assign s_cd_wordstransf  = r_is_replay ? s_replay_buffer_out[22:21] : udma_cmd_i[22:21];
    assign s_cd_wordsize     = r_is_replay ? s_replay_buffer_out[20:16] : udma_cmd_i[20:16];
    assign s_cd_size_long    = r_is_replay ? s_replay_buffer_out[15:0]  : udma_cmd_i[15:0];

    assign s_cd_cmd_data     = r_is_replay ? s_replay_buffer_out[15:0]  : udma_cmd_i[15:0];
    assign s_cd_eot_evt      = r_is_replay ? s_replay_buffer_out[0]     : udma_cmd_i[0];
    assign s_cd_eot_keep_cs  = r_is_replay ? s_replay_buffer_out[1]     : udma_cmd_i[1];
    assign s_cd_cfg_check    = r_is_replay ? s_replay_buffer_out[15:0]  : udma_cmd_i[15:0];
    assign s_cd_cfg_chk_type = r_is_replay ? s_replay_buffer_out[25:24] : udma_cmd_i[25:24];
    assign s_cd_wait_evt     = r_is_replay ? s_replay_buffer_out[1:0]   : udma_cmd_i[1:0];
    assign s_cd_wait_cyc     = r_is_replay ? s_replay_buffer_out[7:0]   : udma_cmd_i[7:0];
    assign s_cd_wait_typ     = r_is_replay ? s_replay_buffer_out[9:8]   : udma_cmd_i[9:8];

    assign s_first_replay    = s_replay_buffer_out[32];

    assign cfg_cpol_o = r_cfg_cpol;
    assign cfg_cpha_o = r_cfg_cpha;

    assign cfg_clkdiv_data_o = r_cfg_clkdiv;

    assign status_o = r_status;

    assign s_done = r_is_ful ? ((tx_done_i | r_tx_done) & (rx_done_i | r_rx_done)) : (tx_done_i | rx_done_i);

    always_comb begin : proc_s_wordstransf
        case(s_cd_wordstransf)
            2'b00:
                s_wordstransf = 2'h0;
            2'b01:
                s_wordstransf = 2'h1;
            2'b10:
                s_wordstransf = 2'h3;
            default:
                s_wordstransf = 2'h0;
        endcase // s_cd_wordstransf
    end
    edge_propagator_tx i_edgeprop
    (
      .clk_i(clk_i),
      .rstn_i(rstn_i),
      .valid_i(r_update_cfg),
      .ack_i(cfg_clkdiv_ack_i),
      .valid_o(cfg_clkdiv_valid_o)
    );

  enum logic [1:0] { S_CNT_IDLE, S_CNT_RUNNING} r_cnt_state,s_cnt_state_next;

  logic            s_cnt_done;
  logic            s_cnt_start;
  logic            s_cnt_update;
  logic      [7:0] s_cnt_target;
  logic      [7:0] r_cnt_target;
  logic      [7:0] r_cnt;
  logic      [7:0] s_cnt_next;

    io_generic_fifo
    #(
        .DATA_WIDTH(33),
        .BUFFER_DEPTH(REPLAY_BUFFER_DEPTH)
    ) i_reply_buffer (
        .clk_i     ( clk_i ),
        .rstn_i    ( rstn_i ),
        .clr_i     ( s_clr_rpt_buf ),
        .elements_o(  ),
        .data_o    ( s_replay_buffer_out       ),
        .valid_o   ( s_replay_buffer_out_valid ),
        .ready_i   ( s_replay_buffer_out_ready ),
        .data_i    ( s_replay_buffer_in        ),
        .valid_i   ( s_replay_buffer_in_valid  ),
        .ready_o   ( s_replay_buffer_in_ready  )
    );

    assign s_replay_buffer_in       = r_is_replay ? s_replay_buffer_out : {r_first_replay,udma_cmd_i};
    assign s_replay_buffer_in_valid = s_setup_replay ? udma_cmd_valid_i : (r_is_replay & (s_replay_buffer_out_ready & s_replay_buffer_out_valid));

  always_ff @(posedge clk_i, negedge rstn_i)
  begin
    if(~rstn_i)
    begin
      r_cnt_state <= S_CNT_IDLE;
      r_cnt <= 'h0;
      r_cnt_target <= 'h0;
    end
    else
    begin
      if (s_cnt_start)
        r_cnt_target <= s_cnt_target;
      if (s_cnt_start || s_cnt_done)
        r_cnt_state <= s_cnt_state_next;
      if (s_cnt_update)
        r_cnt <= s_cnt_next;
    end
  end

  always_comb begin
    s_cnt_update = 1'b0;
    s_cnt_state_next = r_cnt_state;
    s_cnt_done   = 1'b0;
    s_cnt_next   = r_cnt;
    case (r_cnt_state)
      S_CNT_IDLE:
      begin
        if(s_cnt_start)
          s_cnt_state_next = S_CNT_RUNNING;
      end
      S_CNT_RUNNING:
      begin
        s_cnt_update = 1'b1;
        if (r_cnt_target == r_cnt)
        begin
          s_cnt_next =  'h0;
          s_cnt_done = 1'b1;
          if (~s_cnt_start)
            s_cnt_state_next = S_CNT_IDLE;
        end
        else
        begin
          s_cnt_next = r_cnt + 1;
        end
      end
    endcase // r_cnt_state
  end

    // Command decoding logic
    always_comb
    begin
        is_cmd_cfg  = 1'b0;
        is_cmd_sot  = 1'b0;
        is_cmd_snc  = 1'b0;
        is_cmd_dum  = 1'b0;
        is_cmd_wai  = 1'b0;
        is_cmd_txd  = 1'b0;
        is_cmd_rxd  = 1'b0;
        is_cmd_rxc  = 1'b0;
        is_cmd_rpt  = 1'b0;
        is_cmd_eot  = 1'b0;
        is_cmd_rpe  = 1'b0;
        is_cmd_ful  = 1'b0;
        is_cmd_uca  = 1'b0;
        is_cmd_ucs  = 1'b0;
        case(s_cmd)
            `SPI_CMD_CFG:
                is_cmd_cfg = 1'b1;
            `SPI_CMD_SOT:
                is_cmd_sot  = 1'b1;
            `SPI_CMD_SEND_CMD:
                is_cmd_snc  = 1'b1;
            `SPI_CMD_DUMMY:
                is_cmd_dum  = 1'b1;
            `SPI_CMD_WAIT:
                is_cmd_wai  = 1'b1;
            `SPI_CMD_TX_DATA:
                is_cmd_txd  = 1'b1;
            `SPI_CMD_RX_DATA:
                is_cmd_rxd  = 1'b1;
            `SPI_CMD_RX_CHECK:
                is_cmd_rxc  = 1'b1;
            `SPI_CMD_RPT:
                is_cmd_rpt  = 1'b1;
            `SPI_CMD_RPT_END:
                is_cmd_rpe  = 1'b1;
            `SPI_CMD_EOT:
                is_cmd_eot  = 1'b1;
            `SPI_CMD_FULL_DUPL:
                is_cmd_ful  = 1'b1;
            `SPI_CMD_SETUP_UCA:
                is_cmd_uca  = 1'b1;
            `SPI_CMD_SETUP_UCS:
                is_cmd_ucs  = 1'b1;
        endcase
    end

    always_comb begin : proc_s_event
        s_event = 1'b0;
        for(int i=0;i<4;i++)
            if(r_evt_sel == i)
                s_event = event_i[i];
    end

    always_comb
    begin
        state_next           = state;
        udma_tx_data_ready_o = 1'b0;
        udma_cmd_ready_o     = 1'b0;
        udma_rx_data_o       =  'h0;
        udma_rx_data_valid_o = 1'b0;
        rx_data_ready_o      = 1'b0;
        s_update_chk         = 1'b0;
        s_update_cfg         = 1'b0;
        s_update_cs          = 1'b0;
        s_update_qpi         = 1'b0;
        s_update_evt         = 1'b0;
        s_clear_cs           = 1'b0;
        tx_size_o            =  'h0;
        rx_size_o            =  'h0;
        tx_qpi_o             = r_qpi;
        rx_qpi_o             = r_qpi;
        tx_start_o           = 1'b0;
        rx_start_o           = 1'b0;
        tx_data_o            =  'h0;
        tx_data_valid_o      = 1'b0;
        tx_wordtransf_o      = 'h0;
        tx_bitsword_o        = 'h0;
        tx_lsbfirst_o        = 1'b0;
        rx_wordtransf_o      = 'h0;
        rx_bitsword_o        = 'h0;
        rx_lsbfirst_o        = 1'b0;
        eot_o                = 1'b0;
        s_is_dummy           = r_is_dummy;
        s_qpi                = r_qpi;
        s_is_ful             = r_is_ful;
        s_update_chk_result  = 1'b0;
        s_chk_result         = 1'b0;
        s_is_replay          = r_is_replay;
        s_setup_replay       = 1'b0;
        s_rpt_num            = r_rpt_num;
        s_update_rpt         = 1'b0;
        s_clr_rpt_buf        = 1'b0;
        s_cnt_start          = 1'b0;
        s_cnt_target         =  'h0;
        s_replay_buffer_out_ready = 1'b0;
        s_set_first_reply    = 1'b0;
        s_clr_first_reply    = 1'b0;
        s_update_status      = 1'b0;
        s_status             = r_status;
        case(state)
            IDLE:
            begin
                s_is_ful = 1'b0;
                if((r_is_replay && s_replay_buffer_out_valid) || (!r_is_replay && udma_cmd_valid_i))
                begin
                    if(!s_is_replay)
                        udma_cmd_ready_o = 1'b1;
                    else
                    begin
                        s_replay_buffer_out_ready = 1'b1;
                        if(((r_rpt_num == 0) && s_first_replay) || r_chk_result)
                        begin
                            s_update_status = 1'b1;
                            if(r_chk_result)
                                s_status        = STAT_CHECK; //matched
                            else
                                s_status        = STAT_EOL;   //end of loop
                            s_update_chk_result = 1'b1;
                            s_chk_result = 1'b0;
                            s_is_replay  = 1'b0;
                        end
                        else
                        begin
                            if(s_first_replay)
                            begin
                                s_update_rpt = 1'b1;
                                s_rpt_num = r_rpt_num - 1;
                            end
                        end
                    end
                    if(is_cmd_cfg)
                    begin
                        s_update_cfg = 1'b1;
                        s_cnt_start  = 1'b1;
                        s_cnt_target = 8'h1;
                        state_next   = WAIT_CYCLE;
                    end
                    else if (is_cmd_sot)
                    begin
                        s_update_cs  = 1'b1;
                        s_cnt_start  = 1'b1;
                        s_cnt_target = s_cd_wait_cyc;
                        state_next   = WAIT_CYCLE;
                    end
                    else if(is_cmd_snc)
                    begin
                        s_update_qpi    = 1'b1;
                        tx_start_o      = 1'b1;
                        tx_qpi_o        = s_cd_cfg_qpi;
                        s_qpi           = s_cd_cfg_qpi;
                        tx_size_o       = 'h0;
                        tx_wordtransf_o = 'h0;
                        tx_bitsword_o   = s_cd_wordsize;
                        tx_lsbfirst_o   = 1'b0;
                        state_next      = WAIT_DONE;
                        tx_data_valid_o = 1'b1;
                        tx_data_o       = {16'h0,s_cd_cmd_data};
                    end
                    else if(is_cmd_wai)
                    begin
                        if (s_cd_wait_typ == `SPI_WAIT_EVT)
                        begin
                            s_update_evt      = 1'b1;
                            state_next   = WAIT_EVENT;
                        end
                        else if(s_cd_wait_typ == `SPI_WAIT_CYC)
                        begin
                            s_cnt_start  = 1'b1;
                            s_cnt_target = s_cd_wait_cyc;
                            state_next   = WAIT_CYCLE;
                        end
                    end
                    else if(is_cmd_dum)
                    begin
                        s_update_qpi = 1'b1;
                        rx_start_o   = 1'b1;
                        rx_qpi_o     = s_cd_cfg_qpi;
                        s_qpi        = s_cd_cfg_qpi;
                        rx_size_o       = 'h0;
                        rx_wordtransf_o = 'h0;
                        rx_bitsword_o   = s_cd_wordsize;
                        state_next   = WAIT_DONE;
                        s_is_dummy   = 1'b1;
                    end
                    else if(is_cmd_txd)
                    begin
                        s_update_qpi    = 1'b1;
                        tx_start_o      = 1'b1;
                        tx_lsbfirst_o   = s_cd_cfg_lsb;
                        tx_size_o       = s_cd_size_long;
                        tx_wordtransf_o = s_wordstransf;
                        tx_bitsword_o   = s_cd_wordsize;
                        tx_qpi_o        = s_cd_cfg_qpi;
                        s_qpi           = s_cd_cfg_qpi;
                        tx_size_o       = s_cd_size_long;
                        state_next      = WAIT_DONE;
                    end
                    else if(is_cmd_rxd)
                    begin
                        s_update_qpi = 1'b1;
                        rx_start_o   = 1'b1;
                        rx_lsbfirst_o   = s_cd_cfg_lsb;
                        rx_size_o       = s_cd_size_long;
                        rx_wordtransf_o = s_wordstransf;
                        rx_bitsword_o   = s_cd_wordsize;
                        rx_qpi_o     = s_cd_cfg_qpi;
                        s_qpi        = s_cd_cfg_qpi;
                        state_next   = WAIT_DONE;
                    end
                    else if(is_cmd_ful)
                    begin
                        s_is_ful     = 1'b1;
                        s_update_qpi = 1'b1;
                        rx_start_o   = 1'b1;
                        tx_start_o   = 1'b1;
                        s_qpi        = 1'b0;
                        rx_qpi_o     = 1'b0;
                        tx_qpi_o     = 1'b0;
                        rx_size_o    = s_cd_size_long;
                        tx_size_o    = s_cd_size_long;
                        rx_bitsword_o   = s_cd_wordsize;
                        tx_bitsword_o   = s_cd_wordsize;
                        rx_lsbfirst_o = s_cd_cfg_lsb;
                        tx_lsbfirst_o = s_cd_cfg_lsb;
                        rx_wordtransf_o = s_wordstransf;
                        tx_wordtransf_o = s_wordstransf;
                        state_next   = WAIT_DONE;
                    end
                    else if(is_cmd_rxc)
                    begin
                        s_update_qpi = 1'b1;
                        s_update_chk = 1'b1;
                        rx_start_o   = 1'b1;
                        rx_qpi_o     = s_cd_cfg_qpi;
                        s_qpi        = s_cd_cfg_qpi;
                        rx_size_o       = 'h0;
                        rx_wordtransf_o = 'h0;
                        rx_bitsword_o   = {1'b0,s_cd_wordsize[3:0]};
                        rx_lsbfirst_o = s_cd_cfg_lsb;
                        state_next   = WAIT_CHECK;
                    end
                    else if(is_cmd_rpt)
                    begin
                        s_update_rpt = 1'b1;
                        s_clr_rpt_buf = 1'b1;
                        s_rpt_num    = s_cd_size_long;
                        s_set_first_reply = 1'b1;
                        state_next   = DO_REPEAT;
                        s_update_status = 1'b1;
                        s_status = STAT_NONE;
                    end
                    else if(is_cmd_eot)
                    begin
                        eot_o = s_cd_eot_evt;
                        if(s_cd_eot_keep_cs)
                            state_next = IDLE;
                        else
                            state_next = CLEAR_CS;
                    end
                end
            end
            DO_REPEAT:
            begin
                if(udma_cmd_valid_i)
                begin
                    s_clr_first_reply = 1'b1;
                    udma_cmd_ready_o = 1'b1;
                    if(is_cmd_rpe)
                    begin
                        s_setup_replay = 1'b0;
                        s_is_replay    = 1'b1;
                        state_next     = IDLE;
                    end
                    else
                        s_setup_replay = 1'b1;
                end
            end
            WAIT_DONE:
            begin
                if(s_done)
                begin
                    state_next = IDLE;
                    s_is_dummy = 1'b0;
                end

                tx_data_o        = udma_tx_data_i;
                tx_data_valid_o  = udma_tx_data_valid_i;
                udma_tx_data_ready_o = tx_data_ready_i;

                udma_rx_data_o       = rx_data_i;
                udma_rx_data_valid_o = r_is_dummy ? 1'b0 : rx_data_valid_i;
                rx_data_ready_o      = udma_rx_data_ready_i;
            end
            /*
	    WAIT_ADDR:
            begin
                if(udma_cmd_valid_i)
                begin
                    udma_cmd_ready_o = 1'b0;
                    state_next       = IDLE;
                end
            end
	    */
            WAIT_CHECK:
            begin
                if(rx_done_i)
                begin
                    state_next = IDLE;
                    s_is_dummy = 1'b0;
                end

                if (rx_data_valid_i)
                begin
                    s_update_chk_result = 1'b1;
                    case(r_chk_type)
                        2'b00:  //check the whole word
                        begin
                            if (rx_data_i[15:0] == r_chk)
                                s_chk_result = 1'b1;
                        end
                        2'b01:  //check only ones
                        begin
                            if ( (rx_data_i[15:0] & r_chk) == r_chk )
                                s_chk_result = 1'b1;
                        end
                        2'b10:  //check only zeros
                        begin
                            if ( (~rx_data_i[15:0] & ~r_chk) == ~r_chk )
                                s_chk_result = 1'b1;
                        end
                        2'b11:  //check if data is not mask
                        begin
                            if ( (rx_data_i[15:0] & r_chk) != r_chk)
                                s_chk_result = 1'b1;
                        end
                        default:
                            s_chk_result = 1'b0;
                    endcase // r_chk_type
                end
                rx_data_ready_o      = 1'b1;
            end
            WAIT_EVENT:
            begin
                if(s_event)
                begin
                    state_next = IDLE;
                end
            end
            WAIT_CYCLE:
            begin
                if(s_cnt_done)
                begin
                    state_next = IDLE;
                end
            end
            CLEAR_CS:
            begin
                s_clear_cs = 1'b1;
                state_next = IDLE;
            end
            default:
                state_next = IDLE;
        endcase
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_chk_result
        if(~rstn_i) begin
            r_chk_result <= 0;
        end else begin
            if(s_update_chk_result)
                r_chk_result <= s_chk_result;
        end
    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            state      <= IDLE;
        end
        else
        begin
            state      <= state_next;
        end

    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_cfg_cpol <= 1'b0;
            r_cfg_cpha <= 1'b0;
            r_cfg_clkdiv <= 'h0;
        end
        else
        begin
            if(s_update_cfg) begin
                r_cfg_cpol   <= s_cd_cfg_cpol;
                r_cfg_cpha   <= s_cd_cfg_cpha;
                r_cfg_clkdiv <= s_cd_cfg_clkdiv;
            end
        end

    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_r_update_cfg
        if(~rstn_i) begin
            r_update_cfg <= 0;
        end else begin
            r_update_cfg <= s_update_cfg;
        end
    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_qpi       <= 1'b0;
            r_is_dummy  <= 1'b0;
            r_evt_sel   <=  'h0;
            r_is_ful    <= 1'b0;
            r_tx_done   <= 1'b0;
            r_rx_done   <= 1'b0;
            r_chk_type  <= 0;
            r_chk       <= 0;
            r_is_replay <= 0;
            r_first_replay <= 1'b0;
            r_status    <= STAT_NONE;
        end
        else
        begin

            r_is_ful  <= s_is_ful;
            r_tx_done <= tx_done_i;
            r_rx_done <= rx_done_i;
            r_is_replay <= s_is_replay;

            if(s_set_first_reply)
                r_first_replay <= 1'b1;
            if(s_clr_first_reply)
                r_first_replay <= 1'b0;
            if(s_update_status)
                r_status <= s_status;

            if(s_update_chk)
            begin
                r_chk_type   <= s_cd_cfg_chk_type;
                r_chk        <= s_cd_cfg_check;
            end

            if(s_update_qpi)
                r_qpi <= s_qpi;

            if(s_update_evt)
                r_evt_sel <= s_cd_wait_evt;

            r_is_dummy <= s_is_dummy;
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : proc_rpt
        if(~rstn_i) begin
            r_rpt_num       <= 0;
        end else begin
            if(s_update_rpt)
                r_rpt_num      <= s_rpt_num;
        end
    end

    assign s_cs = s_cd_cs;

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            spi_csn0_o <= 1'b1;
            spi_csn1_o <= 1'b1;
            spi_csn2_o <= 1'b1;
            spi_csn3_o <= 1'b1;
        end
        else
        begin
            if(s_update_cs) begin
                case(s_cs)
                    2'b00:
                        spi_csn0_o <= 1'b0;
                    2'b01:
                        spi_csn1_o <= 1'b0;
                    2'b10:
                        spi_csn2_o <= 1'b0;
                    2'b11:
                        spi_csn3_o <= 1'b0;
                endcase
            end
            else if(s_clear_cs) begin
                spi_csn0_o <= 1'b1;
                spi_csn1_o <= 1'b1;
                spi_csn2_o <= 1'b1;
                spi_csn3_o <= 1'b1;
            end
        end

    end


endmodule
