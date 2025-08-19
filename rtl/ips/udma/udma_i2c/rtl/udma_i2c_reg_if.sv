// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2016 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Pullini Antonio - pullinia@iis.ee.ethz.ch                  //
//                                                                            //
// Additional contributions by:                                               //
//                                                                            //
//                                                                            //
// Design Name:    SPI Master Programming Register Interface                  //
// Project Name:   SPI Master                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    SPI Master with full QPI support                           //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`include "udma_i2c_defines.sv"
module udma_i2c_reg_if #(
    parameter L2_AWIDTH_NOAL = 12,
    parameter TRANS_SIZE     = 16
)
(
	input  logic 	                  clk_i,
	input  logic   	                  rstn_i,

	input  logic               [31:0] cfg_data_i,
	input  logic                [4:0] cfg_addr_i,
	input  logic                      cfg_valid_i,
	input  logic                      cfg_rwn_i,
	output logic               [31:0] cfg_data_o,
	output logic                      cfg_ready_o,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_rx_size_o,
    output logic                      cfg_rx_continuous_o,
    output logic                      cfg_rx_en_o,
    output logic                      cfg_rx_clr_o,
    input  logic                      cfg_rx_en_i,
    input  logic                      cfg_rx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_rx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_rx_bytes_left_i,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_tx_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_tx_size_o,
    output logic                      cfg_tx_continuous_o,
    output logic                      cfg_tx_en_o,
    output logic                      cfg_tx_clr_o,
    input  logic                      cfg_tx_en_i,
    input  logic                      cfg_tx_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_tx_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_tx_bytes_left_i,

    output logic [L2_AWIDTH_NOAL-1:0] cfg_cmd_startaddr_o,
    output logic     [TRANS_SIZE-1:0] cfg_cmd_size_o,
    output logic                      cfg_cmd_continuous_o,
    output logic                      cfg_cmd_en_o,
    output logic                      cfg_cmd_clr_o,
    input  logic                      cfg_cmd_en_i,
    input  logic                      cfg_cmd_pending_i,
    input  logic [L2_AWIDTH_NOAL-1:0] cfg_cmd_curr_addr_i,
    input  logic     [TRANS_SIZE-1:0] cfg_cmd_bytes_left_i,

    output logic                      cfg_do_rst_o,

    input  logic                      status_busy_i,
    input  logic                      status_al_i,
    input  logic                      nack_i,

    input  logic               [31:0] udma_cmd_i,
    input  logic                      udma_cmd_valid_i,
    input  logic                      udma_cmd_ready_i
);

    logic [L2_AWIDTH_NOAL-1:0] r_cmd_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_cmd_size;
    logic                      r_cmd_continuous;
    logic                      r_cmd_en;
    //logic                      r_cmd_clr;

    logic [L2_AWIDTH_NOAL-1:0] r_rx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_rx_size;
    logic                      r_rx_continuous;
    logic                      r_rx_en;
    //logic                      r_rx_clr;

    logic [L2_AWIDTH_NOAL-1:0] r_tx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_tx_size;
    logic                      r_tx_continuous;
    logic                      r_tx_en;
    //logic                      r_tx_clr;

    //logic                      r_do_rst;

    logic                [4:0] s_wr_addr;
    logic                [4:0] s_rd_addr;

    logic                      r_al;
    logic                      r_busy;
    logic                      r_nack;

    //command decode signals
    logic                 [3:0] s_cmd;
    logic  [L2_AWIDTH_NOAL-1:0] s_cmd_decode_addr;
    logic    [TRANS_SIZE-1 : 0] s_cmd_decode_size;
    logic                       s_cmd_decode_txrxn;

    logic                       s_is_cmd_uca;
    logic                       s_is_cmd_ucs;
    logic                       s_more_data;

    assign s_cmd              = udma_cmd_i[31:28];
    assign s_cmd_decode_txrxn = udma_cmd_i[27];
    assign s_cmd_decode_size  = udma_cmd_i[TRANS_SIZE-1:0];
    assign s_cmd_decode_addr  = udma_cmd_i[L2_AWIDTH_NOAL-1:0];

    assign s_is_cmd_uca = (s_cmd == `I2C_CMD_SETUP_UCA);
    assign s_is_cmd_ucs = (s_cmd == `I2C_CMD_SETUP_UCS);

    assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i) ? cfg_addr_i : 5'h0;
    assign s_rd_addr = (cfg_valid_i &  cfg_rwn_i) ? cfg_addr_i : 5'h0;

    assign cfg_cmd_startaddr_o  = r_cmd_startaddr;
    assign cfg_cmd_size_o       = r_cmd_size;
    assign cfg_cmd_continuous_o = r_cmd_continuous;
    assign cfg_cmd_en_o         = r_cmd_en;
    assign cfg_cmd_clr_o        = 1'b0; //r_cmd_clr;

    assign cfg_rx_startaddr_o  = r_rx_startaddr;
    assign cfg_rx_size_o       = r_rx_size;
    assign cfg_rx_continuous_o = r_rx_continuous;
    assign cfg_rx_en_o         = r_rx_en;
    assign cfg_rx_clr_o        = 1'b0; //r_rx_clr;

    assign cfg_tx_startaddr_o  = r_tx_startaddr;
    assign cfg_tx_size_o       = r_tx_size;
    assign cfg_tx_continuous_o = r_tx_continuous;
    assign cfg_tx_en_o         = r_tx_en;
    assign cfg_tx_clr_o        = 1'b0; //r_tx_clr;

    assign cfg_do_rst_o        = 1'b0; //r_do_rst;

    always_comb begin
        s_more_data = (|cfg_cmd_bytes_left_i) | (|cfg_rx_bytes_left_i) | (|cfg_tx_bytes_left_i);
    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if(~rstn_i)
        begin
            // I2C REGS
            r_cmd_startaddr  <=  'h0;
            r_cmd_size       <=  'h0;
            r_cmd_continuous <=  'h0;
            r_cmd_en         <=  'h0;
            //r_cmd_clr        <=  'h0;
            r_rx_startaddr   <=  'h0;
            r_rx_size        <=  'h0;
            r_rx_continuous  <=  'h0;
            r_rx_en          <=  'h0;
            //r_rx_clr         <=  'h0;
            r_tx_startaddr   <=  'h0;
            r_tx_size        <=  'h0;
            r_tx_continuous  <=  'h0;
            r_tx_en          <=  'h0;
            //r_tx_clr         <=  'h0;
            //r_do_rst         <= 1'b0;
            r_busy           <= 1'b0;
            r_al             <= 1'b0;
            r_nack           <= 1'b0;
        end
        else
        begin
            r_rx_en         <=  'h0;
            //r_rx_clr        <=  'h0;
            r_tx_en         <=  'h0;
            //r_tx_clr        <=  'h0;
            r_cmd_en        <=  'h0;
            //r_cmd_clr       <=  'h0;
            if (udma_cmd_valid_i && udma_cmd_ready_i && (s_is_cmd_ucs || s_is_cmd_uca))
            begin
                if(s_is_cmd_uca)
                begin
                    if(s_cmd_decode_txrxn)
                        r_tx_startaddr <= s_cmd_decode_addr;
                    else
                        r_rx_startaddr <= s_cmd_decode_addr;
                end
                else
                begin
                    if(s_cmd_decode_txrxn)
                    begin
                        r_tx_size <= s_cmd_decode_size;
                        r_tx_en   <= 1'b1;
                    end
                    else
                    begin
                        r_rx_size <= s_cmd_decode_size;
                        r_rx_en   <= 1'b1;
                    end
                end
            end
            else if (cfg_valid_i & ~cfg_rwn_i)
            begin
                case (s_wr_addr)
                `REG_CMD_SADDR:
                    r_cmd_startaddr   <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                `REG_CMD_SIZE:
                    r_cmd_size        <= cfg_data_i[TRANS_SIZE-1:0];
                `REG_CMD_CFG:
                begin
                    //r_cmd_clr         <= cfg_data_i[6];
                    r_cmd_en          <= cfg_data_i[4];
                    r_cmd_continuous  <= cfg_data_i[0];
                end
                `REG_RX_SADDR:
                    r_rx_startaddr   <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                `REG_RX_SIZE:
                    r_rx_size        <= cfg_data_i[TRANS_SIZE-1:0];
                `REG_RX_CFG:
                begin
                    //r_rx_clr         <= cfg_data_i[6];
                    r_rx_en          <= cfg_data_i[4];
                    r_rx_continuous  <= cfg_data_i[0];
                end
                `REG_TX_SADDR:
                    r_tx_startaddr   <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                `REG_TX_SIZE:
                    r_tx_size        <= cfg_data_i[TRANS_SIZE-1:0];
                `REG_TX_CFG:
                begin
                    //r_tx_clr         <= cfg_data_i[6];
                    r_tx_en          <= cfg_data_i[4];
                    r_tx_continuous  <= cfg_data_i[0];
                end
                //`REG_SETUP:
                //begin
                //    r_do_rst         <= cfg_data_i[0];
                //end

                endcase
            end

            // clear on read
            //if(cfg_valid_i && cfg_rwn_i && (s_rd_addr == `REG_STATUS))
            //begin
            //    r_busy <= 0;
            //    r_al   <= 0;
            //end

            if (status_busy_i || s_more_data)
                r_busy <= 1'b1;
            else
                r_busy <= 1'b0;

            if (status_al_i)
                r_al <= 1'b1;
            else
                r_al <= 1'b0;

            // clear on read
            if(cfg_valid_i && cfg_rwn_i && (s_rd_addr == `REG_ACK))
                r_nack <= 1'b0;

            // sticky when nack, high priority
            if (nack_i)
                r_nack <= 1'b1;

        end
    end //always

    always_comb
    begin
        cfg_data_o = 32'h0;
        case (s_rd_addr)
        `REG_CMD_SADDR:
            cfg_data_o = cfg_cmd_curr_addr_i;
        `REG_CMD_SIZE:
            cfg_data_o[TRANS_SIZE-1:0] = cfg_cmd_bytes_left_i;
        `REG_CMD_CFG:
            cfg_data_o = {26'h0,cfg_cmd_pending_i,cfg_cmd_en_i,1'b0,2'b10,r_cmd_continuous};
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
        //`REG_SETUP:
        //    cfg_data_o = {31'h0,r_do_rst};
        `REG_STATUS:
            cfg_data_o = {30'h0, r_al,r_busy};
        `REG_ACK:
            cfg_data_o = {31'h0, r_nack};
        default:
            cfg_data_o = 'h0;
        endcase
    end

    assign cfg_ready_o  = 1'b1;

endmodule
