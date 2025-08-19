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
// Description: SDIO register interface
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

// SPI Master Registers
`define REG_RX_SADDR     5'b00000 //BASEADDR+0x00
`define REG_RX_SIZE      5'b00001 //BASEADDR+0x04
`define REG_RX_CFG       5'b00010 //BASEADDR+0x08
//`define REG_RX_INTCFG    5'b00011 //BASEADDR+0x0C

`define REG_TX_SADDR     5'b00100 //BASEADDR+0x10
`define REG_TX_SIZE      5'b00101 //BASEADDR+0x14
`define REG_TX_CFG       5'b00110 //BASEADDR+0x18
//`define REG_TX_INTCFG    5'b00111 //BASEADDR+0x1C

`define REG_CMD_OP       5'b01000 //BASEADDR+0x20
`define REG_CMD_ARG      5'b01001 //BASEADDR+0x24
`define REG_DATA_SETUP   5'b01010 //BASEADDR+0x28
`define REG_START        5'b01011 //BASEADDR+0x2C

`define REG_RSP0         5'b01100 //BASEADDR+0x30
`define REG_RSP1         5'b01101 //BASEADDR+0x34
`define REG_RSP2         5'b01110 //BASEADDR+0x38
`define REG_RSP3         5'b01111 //BASEADDR+0x3C

`define REG_CLK_DIV      5'b10000 //BASEADDR+0x40
`define REG_STATUS       5'b10001 //BASEADDR+0x44
`define REG_DATA_TIMEOUT 5'b10010 //BASEADDR+0x48

module udma_sdio_reg_if #(
                          parameter L2_AWIDTH_NOAL = 12,
                          parameter TRANS_SIZE     = 16
                          )
   (
    input logic                       clk_i,
    input logic                       rstn_i,

    input logic [31:0]                cfg_data_i,
    input logic [4:0]                 cfg_addr_i,
    input logic                       cfg_valid_i,
    input logic                       cfg_rwn_i,
    output logic [31:0]               cfg_data_o,
    output logic                      cfg_ready_o,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
    output logic [TRANS_SIZE-1:0]     cfg_rx_size_o,
    output logic                      cfg_rx_continuous_o, // NOT IMPLEMENTED
    output logic                      cfg_rx_en_o,
    output logic                      cfg_rx_clr_o,
    input logic                       cfg_rx_en_i,
    input logic                       cfg_rx_pending_i,
    input logic [L2_AWIDTH_NOAL-1:0]  cfg_rx_curr_addr_i,
    input logic [TRANS_SIZE-1:0]      cfg_rx_bytes_left_i,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_tx_startaddr_o,
    output logic [TRANS_SIZE-1:0]     cfg_tx_size_o,
    output logic                      cfg_tx_continuous_o, // NOT IMPLEMENTED
    output logic                      cfg_tx_en_o,
    output logic                      cfg_tx_clr_o,
    input logic                       cfg_tx_en_i,
    input logic                       cfg_tx_pending_i,
    input logic [L2_AWIDTH_NOAL-1:0]  cfg_tx_curr_addr_i,
    input logic [TRANS_SIZE-1:0]      cfg_tx_bytes_left_i,

    output logic                      cfg_sdio_start_o,

    output logic [7:0]                cfg_clk_div_data_o,
    output logic                      cfg_clk_div_valid_o,
    input logic                       cfg_clk_div_ack_i,

    input logic [15:0]                txrx_status_i,
    input logic                       txrx_eot_i,
    input logic                       txrx_err_i,

    output logic [5:0]                cfg_cmd_op_o,
    output logic [31:0]               cfg_cmd_arg_o,
    output logic [2:0]                cfg_cmd_rsp_type_o,
    output logic [1:0]                cfg_cmd_stopopt,
    input logic [127:0]               cfg_rsp_data_i,
    output logic                      cfg_data_en_o,
    output logic                      cfg_data_rwn_o,
    output logic                      cfg_data_quad_o,
    output logic [9:0]                cfg_data_block_size_o,
    output logic [7:0]                cfg_data_block_num_o,

    output logic [19:0]               cfg_data_timeout_o,
    input  logic [11:0]               cfg_debug_stat_i  // debug, internal state machine
);

    logic [L2_AWIDTH_NOAL-1:0] r_rx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_rx_size;
    logic                      r_rx_continuous;
    logic                      r_rx_en;
    logic                      r_rx_clr;

    logic [L2_AWIDTH_NOAL-1:0] r_tx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_tx_size;
    logic                      r_tx_continuous;
    logic                      r_tx_en;
    logic                      r_tx_clr;

    logic                [4:0] s_wr_addr;
    logic                [4:0] s_rd_addr;

    logic   [5:0] r_cmd_op;
    logic  [31:0] r_cmd_arg;
    logic   [2:0] r_cmd_rsp_type;
    logic [135:0] r_rsp_data;
    logic         r_data_en;
    logic         r_data_rwn;
    logic         r_data_quad;
    logic   [9:0] r_data_block_size;
    logic   [7:0] r_data_block_num;

    logic         r_sdio_start;

    logic         r_clk_div_valid;
    logic   [7:0] r_clk_div_data;

    logic  [15:0] r_status;
    logic         r_eot;
    logic         r_err;
    logic [1:0]   r_cmd_stopopt;
    
    logic [19:0]  r_data_timeout;

    assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i) ? cfg_addr_i : 5'h0;
    assign s_rd_addr = (cfg_valid_i &  cfg_rwn_i) ? cfg_addr_i : 5'h0;

    assign cfg_rx_startaddr_o  = r_rx_startaddr;
    assign cfg_rx_size_o       = r_rx_size;
    assign cfg_rx_continuous_o = r_rx_continuous;
    assign cfg_rx_en_o         = r_rx_en;
    assign cfg_rx_clr_o        = r_rx_clr;

    assign cfg_tx_startaddr_o  = r_tx_startaddr;
    assign cfg_tx_size_o       = r_tx_size;
    assign cfg_tx_continuous_o = r_tx_continuous;
    assign cfg_tx_en_o         = r_tx_en;
    assign cfg_tx_clr_o        = r_tx_clr;

    assign cfg_cmd_op_o          = r_cmd_op;
    assign cfg_cmd_arg_o         = r_cmd_arg;
    assign cfg_cmd_rsp_type_o    = r_cmd_rsp_type;
    assign cfg_cmd_stopopt       = r_cmd_stopopt;
    assign cfg_data_en_o         = r_data_en;
    assign cfg_data_rwn_o        = r_data_rwn;
    assign cfg_data_quad_o       = r_data_quad;
    assign cfg_data_block_size_o = r_data_block_size;
    assign cfg_data_block_num_o  = r_data_block_num;

    assign cfg_sdio_start_o      = r_sdio_start;

    assign cfg_clk_div_data_o    = r_clk_div_data;

    assign cfg_data_timeout_o    = r_data_timeout;

    edge_propagator_tx i_edgeprop_soc
    (
      .clk_i(clk_i),
      .rstn_i(rstn_i),
      .valid_i(r_clk_div_valid),
      .ack_i(cfg_clk_div_ack_i),
      .valid_o(cfg_clk_div_valid_o)
    );

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if(~rstn_i)
        begin
            // SPI REGS
            r_rx_startaddr  <=  'h0;
            r_rx_size       <=  'h0;
            r_rx_continuous <=  'h0;
            r_rx_en         <=  'h0;
            r_rx_clr        <=  'h0;
            r_tx_startaddr  <=  'h0;
            r_tx_size       <=  'h0;
            r_tx_continuous <=  'h0;
            r_tx_en          <=  'h0;
            r_tx_clr         <=  'h0;
            r_cmd_op          <= 'h0;
            r_cmd_arg         <= 'h0;
            r_cmd_rsp_type    <= 'h0;
            r_rsp_data        <= 'h0;
            r_data_en         <= 'h0;
            r_data_rwn        <= 'h0;
            r_data_quad       <= 'h0;
            r_data_block_size <= 'h0;
            r_data_block_num  <= 'h0;
            r_sdio_start      <= 1'b0;
            r_cmd_stopopt     <= '0;

            r_clk_div_valid  <= 1'b0;
            r_clk_div_data   <= 'h0;

            r_data_timeout <= 'd125000; // default timeout, 12.5MHz 10ms, 1Mhz 125 ms

            r_status         <= 'h0;
            r_eot            <= 1'b0;
            r_err            <= 1'b0;
        end
        else
        begin
            r_rx_en        <=  'h0;
            r_rx_clr       <=  'h0;
            r_tx_en        <=  'h0;
            r_tx_clr       <=  'h0;
            r_sdio_start   <= 1'b0;

           if(cfg_clk_div_ack_i)
             r_clk_div_valid <= 1'b0;

           /* Eend of Transfer INT */
           if (txrx_eot_i)
             begin
                r_eot    <= 1'b1;
                r_status <= txrx_status_i;
             end

           /* ERROR INT */
           if (txrx_err_i)
             begin
                r_err    <= 1'b1;
                r_status <= txrx_status_i;
             end

            if (cfg_valid_i & ~cfg_rwn_i)
            begin
                case (s_wr_addr)
                `REG_RX_SADDR:
                    r_rx_startaddr   <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                `REG_RX_SIZE:
                    r_rx_size        <= cfg_data_i[TRANS_SIZE-1:0];
                `REG_RX_CFG:
                begin
                    r_rx_clr         <= cfg_data_i[6];
                    r_rx_en          <= cfg_data_i[4];
                    r_rx_continuous  <= cfg_data_i[0];
                end
                `REG_TX_SADDR:
                    r_tx_startaddr   <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                `REG_TX_SIZE:
                    r_tx_size        <= cfg_data_i[TRANS_SIZE-1:0];
                `REG_TX_CFG:
                begin
                    r_tx_clr         <= cfg_data_i[6];
                    r_tx_en          <= cfg_data_i[4];
                    r_tx_continuous  <= cfg_data_i[0];
                end
                `REG_CMD_OP:
                begin
                    r_cmd_stopopt    <= cfg_data_i[17:16];
                    r_cmd_op         <= cfg_data_i[13:8];
                    r_cmd_rsp_type   <= cfg_data_i[2:0];
                end
                `REG_CMD_ARG:
                begin
                    r_cmd_arg        <= cfg_data_i;
                end
                `REG_DATA_SETUP:
                begin
                    r_data_en         <= cfg_data_i[0];
                    r_data_rwn        <= cfg_data_i[1];
                    r_data_quad       <= cfg_data_i[2];
                    r_data_block_num  <= cfg_data_i[15:8];
                    r_data_block_size <= cfg_data_i[25:16];
                end
                `REG_START:
                begin
                    r_sdio_start      <= cfg_data_i[0];
                end
                `REG_CLK_DIV:
                begin
                    r_clk_div_valid   <= cfg_data_i[8];
                    r_clk_div_data    <= cfg_data_i[7:0];
                end
                `REG_STATUS:
                begin
                   if (cfg_data_i[0])
                     r_eot <= 1'b0;
                   if (cfg_data_i[1])
                     r_err <= 1'b0;
                end
                `REG_DATA_TIMEOUT:
                begin
                    r_data_timeout <= cfg_data_i[19:0];
                end
                endcase
            end
        end
    end //always

    always_comb
    begin
        cfg_data_o = 32'h0;
        case (s_rd_addr)
        `REG_RX_SADDR:
            cfg_data_o = cfg_rx_curr_addr_i;
        `REG_RX_SIZE:
            cfg_data_o[TRANS_SIZE-1:0] = cfg_rx_bytes_left_i;
        `REG_RX_CFG:
            cfg_data_o = {26'h0,cfg_rx_pending_i,cfg_rx_en_i,3'h0,r_rx_continuous};
        `REG_TX_SADDR:
            cfg_data_o = cfg_tx_curr_addr_i;
        `REG_TX_SIZE:
            cfg_data_o[TRANS_SIZE-1:0] = cfg_tx_bytes_left_i;
        `REG_TX_CFG:
            cfg_data_o = {26'h0,cfg_tx_pending_i,cfg_tx_en_i,3'h0,r_tx_continuous};
        `REG_RSP0:
            cfg_data_o = cfg_rsp_data_i[31:0];
        `REG_RSP1:
            cfg_data_o = cfg_rsp_data_i[63:32];
        `REG_RSP2:
            cfg_data_o = cfg_rsp_data_i[95:64];
        `REG_RSP3:
            cfg_data_o = cfg_rsp_data_i[127:96];
        `REG_CLK_DIV:
            cfg_data_o = {23'h0, r_clk_div_valid, r_clk_div_data};
        `REG_STATUS:
            cfg_data_o = { r_status, 14'h0, r_err, r_eot };
        `REG_DATA_TIMEOUT:
            //              6bit cmd + 6bit data status     20bit
            cfg_data_o = {cfg_debug_stat_i,                 r_data_timeout};
        default:
            cfg_data_o = 'h0;
        endcase
    end

    assign cfg_ready_o  = 1'b1;

endmodule

`undef REG_RX_SADDR
`undef REG_RX_SIZE
`undef REG_RX_CFG
//`undef REG_RX_INTCFG
`undef REG_TX_SADDR
`undef REG_TX_SIZE
`undef REG_TX_CFG
//`undef REG_TX_INTCFG
`undef REG_CMD_OP
`undef REG_CMD_ARG
`undef REG_DATA_SETUP
`undef REG_START
`undef REG_RSP0
`undef REG_RSP1
`undef REG_RSP2
`undef REG_RSP3
`undef REG_CLK_DIV
`undef REG_STATUS

