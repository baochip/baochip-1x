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
// Description: I2S configuration interface
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
`define REG_RX_INTCFG    5'b00011 //BASEADDR+0x0C  

`define REG_TX_SADDR     5'b00100 //BASEADDR+0x10
`define REG_TX_SIZE      5'b00101 //BASEADDR+0x14
`define REG_TX_CFG       5'b00110 //BASEADDR+0x18
`define REG_TX_INTCFG    5'b00111 //BASEADDR+0x1C

`define REG_I2S_CLKCFG_SETUP 5'b01000 //BASEADDR+0x20   
`define REG_I2S_SLV_SETUP    5'b01001 //BASEADDR+0x24    
`define REG_I2S_MST_SETUP    5'b01010 //BASEADDR+0x28    
`define REG_I2S_PDM_SETUP    5'b01011 //BASEADDR+0x2C

module udma_i2s_reg_if #(
    parameter L2_AWIDTH_NOAL = 12,
    parameter TRANS_SIZE     = 16
)
(
	input  logic 	                  clk_i,
    input  logic                      periph_clk_i,

	input  logic   	                  sys_rstn_i,
	input  logic   	                  per_rstn_i,

	input  logic               [31:0] cfg_data_i,
	input  logic                [4:0] cfg_addr_i,
	input  logic                      cfg_valid_i,
	input  logic                      cfg_rwn_i,
	output logic               [31:0] cfg_data_o,
	output logic                      cfg_ready_o,

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

    output logic                      cfg_master_clk_en_o,
    output logic                      cfg_slave_clk_en_o,

    output logic                      cfg_pdm_clk_en_o,

    output logic                      cfg_master_sel_num_o,
    output logic                      cfg_master_sel_ext_o,
    output logic                      cfg_slave_sel_num_o,
    output logic                      cfg_slave_sel_ext_o,

    output logic                      cfg_slave_i2s_en_o,
    output logic                      cfg_slave_i2s_lsb_first_o,
    output logic                      cfg_slave_i2s_2ch_o,
    output logic                [4:0] cfg_slave_i2s_bits_word_o,
    output logic                [2:0] cfg_slave_i2s_words_o,

    output logic                      cfg_slave_pdm_en_o,
    output logic                [1:0] cfg_slave_pdm_mode_o,
    output logic                [9:0] cfg_slave_pdm_decimation_o,
    output logic                [2:0] cfg_slave_pdm_shift_o,

    output logic                      cfg_master_i2s_en_o,
    output logic                      cfg_master_i2s_lsb_first_o,
    output logic                      cfg_master_i2s_2ch_o,
    output logic                [4:0] cfg_master_i2s_bits_word_o,
    output logic                [2:0] cfg_master_i2s_words_o,

    output logic                      cfg_slave_gen_clk_en_o,
    input  logic                      cfg_slave_gen_clk_en_i,
    output logic               [15:0] cfg_slave_gen_clk_div_o,

    output logic                      cfg_master_gen_clk_en_o,
    input  logic                      cfg_master_gen_clk_en_i,
    output logic               [15:0] cfg_master_gen_clk_div_o

);

    localparam MAX_CHANNELS = 4;

    logic [L2_AWIDTH_NOAL-1:0] r_rx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_rx_size;
    logic                [1:0] r_rx_datasize;
    logic                      r_rx_continuous;
    logic                      r_rx_en;
    logic                      r_rx_clr;

    logic [L2_AWIDTH_NOAL-1:0] r_tx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_tx_size;
    logic                [1:0] r_tx_datasize;
    logic                      r_tx_continuous;
    logic                      r_tx_en;
    logic                      r_tx_clr;

    logic                      r_master_clk_en;
    logic                      r_slave_clk_en;
    logic                      r_per_master_clk_en;
    logic                      r_per_slave_clk_en;

    logic                      r_master_sel_num;
    logic                      r_master_sel_ext;
    logic                      r_slave_sel_num;
    logic                      r_slave_sel_ext;
    logic                      r_per_master_sel_num;
    logic                      r_per_master_sel_ext;
    logic                      r_per_slave_sel_num;
    logic                      r_per_slave_sel_ext;

    logic                      r_slave_i2s_en;
    logic                      r_slave_i2s_lsb_first;
    logic                      r_slave_i2s_2ch;
    logic                [4:0] r_slave_i2s_bits_word;
    logic                [2:0] r_slave_i2s_words;

    logic                      r_slave_pdm_en;
    logic                [1:0] r_slave_pdm_mode;
    logic                [9:0] r_slave_pdm_decimation;
    logic                [2:0] r_slave_pdm_shift;

    logic                      r_master_i2s_en;
    logic                      r_master_i2s_lsb_first;
    logic                      r_master_i2s_2ch;
    logic                [4:0] r_master_i2s_bits_word;
    logic                [2:0] r_master_i2s_words;

    logic                [7:0] r_common_gen_clk_div;
    logic                [7:0] r_slave_gen_clk_div;
    logic                [7:0] r_master_gen_clk_div;
    logic                [7:0] r_per_common_gen_clk_div;
    logic                [7:0] r_per_slave_gen_clk_div;
    logic                [7:0] r_per_master_gen_clk_div;

    logic                      r_pdm_clk_en;
    //logic                      r_per_pdm_clk_en;

    logic                [4:0] s_wr_addr;
    logic                [4:0] s_rd_addr;

    logic                      s_update_clk;
    logic                      r_update_clk;
    logic cfg_update_clk_o, s_update;

    assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i) ? cfg_addr_i : 5'h0;
    assign s_rd_addr = (cfg_valid_i &  cfg_rwn_i) ? cfg_addr_i : 5'h0;

    assign s_update_clk     = (cfg_valid_i & ~cfg_rwn_i) & (s_wr_addr == `REG_I2S_CLKCFG_SETUP);
    assign cfg_update_clk_o = r_update_clk;

    assign cfg_rx_startaddr_o  = r_rx_startaddr;
    assign cfg_rx_size_o       = r_rx_size;
    assign cfg_rx_datasize_o   = r_rx_datasize;
    assign cfg_rx_continuous_o = r_rx_continuous;
    assign cfg_rx_en_o         = r_rx_en;
    assign cfg_rx_clr_o        = r_rx_clr;

    assign cfg_tx_startaddr_o  = r_tx_startaddr;
    assign cfg_tx_size_o       = r_tx_size;
    assign cfg_tx_datasize_o   = r_tx_datasize;
    assign cfg_tx_continuous_o = r_tx_continuous;
    assign cfg_tx_en_o         = r_tx_en;
    assign cfg_tx_clr_o        = r_tx_clr;

    assign cfg_master_sel_num_o = r_per_master_sel_num;
    assign cfg_master_sel_ext_o = r_per_master_sel_ext;
    assign cfg_slave_sel_num_o  = r_per_slave_sel_num;
    assign cfg_slave_sel_ext_o  = r_per_slave_sel_ext;

    assign cfg_slave_i2s_en_o          = r_slave_i2s_en;
    assign cfg_slave_i2s_lsb_first_o   = r_slave_i2s_lsb_first;
    assign cfg_slave_i2s_2ch_o         = r_slave_i2s_2ch;
    assign cfg_slave_i2s_bits_word_o   = r_slave_i2s_bits_word;
    assign cfg_slave_i2s_words_o       = r_slave_i2s_words;

    assign cfg_slave_pdm_en_o          = r_slave_pdm_en;
    assign cfg_slave_pdm_mode_o        = r_slave_pdm_mode;
    assign cfg_slave_pdm_decimation_o  = r_slave_pdm_decimation;
    assign cfg_slave_pdm_shift_o       = r_slave_pdm_shift;

    assign cfg_master_i2s_en_o         = r_master_i2s_en;
    assign cfg_master_i2s_lsb_first_o  = r_master_i2s_lsb_first;
    assign cfg_master_i2s_2ch_o        = r_master_i2s_2ch;
    assign cfg_master_i2s_bits_word_o  = r_master_i2s_bits_word;
    assign cfg_master_i2s_words_o      = r_master_i2s_words;

    assign cfg_slave_gen_clk_div_o     = {r_per_common_gen_clk_div,r_per_slave_gen_clk_div};
    assign cfg_master_gen_clk_div_o    = {r_per_common_gen_clk_div,r_per_master_gen_clk_div};

    assign cfg_master_clk_en_o = r_per_master_clk_en;
    assign cfg_slave_clk_en_o  = r_per_slave_clk_en;

    assign cfg_pdm_clk_en_o = r_pdm_clk_en; 

    edge_propagator i_edgeprop (
        .clk_tx_i  ( clk_i  ),
        .rstn_tx_i ( sys_rstn_i ),
        .edge_i    ( r_update_clk ),
        .clk_rx_i  ( periph_clk_i ),
        .rstn_rx_i ( per_rstn_i ),
        .edge_o    ( s_update )
    );

    always_ff @(posedge periph_clk_i, negedge per_rstn_i) 
    begin
        if(~per_rstn_i) 
        begin
            r_per_master_clk_en  <= 'h0;
            r_per_slave_clk_en   <= 'h0;
            //r_per_pdm_clk_en     <= 'h0;
            r_per_master_sel_num <= 'h0;
            r_per_master_sel_ext <= 'h0;
            r_per_slave_sel_num  <= 'h0;
            r_per_slave_sel_ext  <= 'h0;
            r_per_common_gen_clk_div <= 'h0;
            r_per_slave_gen_clk_div  <= 'h0;
            r_per_master_gen_clk_div <= 'h0;
        end
        else
        begin
            if(s_update)
            begin
                //r_per_pdm_clk_en     <= r_pdm_clk_en;
                r_per_master_clk_en  <= r_master_clk_en;
                r_per_slave_clk_en   <= r_slave_clk_en;
                r_per_master_sel_num <= r_master_sel_num;
                r_per_master_sel_ext <= r_master_sel_ext;
                r_per_slave_sel_num  <= r_slave_sel_num;
                r_per_slave_sel_ext  <= r_slave_sel_ext;
                r_per_common_gen_clk_div <= r_common_gen_clk_div;
                r_per_slave_gen_clk_div  <= r_slave_gen_clk_div;
                r_per_master_gen_clk_div <= r_master_gen_clk_div;
            end
        end
    end


    always_ff @(posedge clk_i, negedge sys_rstn_i) 
    begin
        if(~sys_rstn_i) 
            r_update_clk <= 1'b0;
        else
            r_update_clk <= s_update_clk;
    end

    always_ff @(posedge clk_i, negedge sys_rstn_i) 
    begin
        if(~sys_rstn_i) 
        begin
            // SPI REGS
            r_rx_startaddr     <= 'h0;
            r_rx_size          <= 'h0;
            r_rx_datasize      <= 'h2;
            r_rx_continuous    <= 'h0;
            r_rx_en            <= 'h0;
            r_rx_clr           <= 'h0;
            r_tx_startaddr     <= 'h0;
            r_tx_size          <= 'h0;
            r_tx_datasize      <= 'h2;
            r_tx_continuous    <= 'h0;
            r_tx_en            <= 'h0;
            r_tx_clr           <= 'h0;
            r_master_sel_num       <= 'h0;
            r_master_sel_ext       <= 'h0;
            r_slave_sel_num        <= 'h0;
            r_slave_sel_ext        <= 'h0;
            r_master_clk_en        <= 'h0;
            r_pdm_clk_en           <= 'h0;
            r_slave_clk_en         <= 'h0;
            r_slave_i2s_en         <= 'h0;
            r_slave_i2s_lsb_first  <= 'h0;
            r_slave_i2s_2ch        <= 'h0;
            r_slave_i2s_bits_word  <= 'h0;
            r_slave_i2s_words      <= 'h0;
            r_slave_pdm_en         <= 'h0;
            r_slave_pdm_mode       <= 'h0;
            r_slave_pdm_decimation <= 'h0;
            r_slave_pdm_shift      <= 'h0;
            r_master_i2s_en        <= 'h0;
            r_master_i2s_lsb_first <= 'h0;
            r_master_i2s_2ch       <= 'h0;
            r_master_i2s_bits_word <= 'h0;
            r_master_i2s_words     <= 'h0;
            r_common_gen_clk_div   <= 'h0;
            r_slave_gen_clk_div    <= 'h0;
            r_master_gen_clk_div   <= 'h0;
        end
        else
        begin
            r_rx_en         <=  'h0;
            r_rx_clr        <=  'h0;
            r_tx_en         <=  'h0;
            r_tx_clr        <=  'h0;

            if (cfg_valid_i & ~cfg_rwn_i)
            begin
                case (s_wr_addr)
                `REG_RX_SADDR:
                    r_rx_startaddr   <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                `REG_RX_SIZE:
                    r_rx_size        <= cfg_data_i[TRANS_SIZE-1:0];
                `REG_RX_CFG:
                begin
                    r_rx_clr         <= cfg_data_i[5];
                    r_rx_en          <= cfg_data_i[4];
                    r_rx_datasize    <= cfg_data_i[2:1];
                    r_rx_continuous  <= cfg_data_i[0];
                end
                `REG_TX_SADDR:
                    r_tx_startaddr   <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
                `REG_TX_SIZE:
                    r_tx_size        <= cfg_data_i[TRANS_SIZE-1:0];
                `REG_TX_CFG:
                begin
                    r_tx_clr         <= cfg_data_i[5];
                    r_tx_en          <= cfg_data_i[4];
                    r_tx_datasize    <= cfg_data_i[2:1];
                    r_tx_continuous  <= cfg_data_i[0];
                end
                `REG_I2S_CLKCFG_SETUP:  
                begin
                    r_master_sel_num       <= cfg_data_i[31];
                    r_master_sel_ext       <= cfg_data_i[30];
                    r_slave_sel_num        <= cfg_data_i[29];
                    r_slave_sel_ext        <= cfg_data_i[28];
                    r_pdm_clk_en           <= cfg_data_i[26];
                    r_master_clk_en        <= cfg_data_i[25];
                    r_slave_clk_en         <= cfg_data_i[24];
                    r_common_gen_clk_div   <= cfg_data_i[23:16];
                    r_slave_gen_clk_div    <= cfg_data_i[15:8];
                    r_master_gen_clk_div   <= cfg_data_i[7:0];
                end
                `REG_I2S_SLV_SETUP:   
                begin
                    if(!r_slave_clk_en)
                    begin
                        r_slave_i2s_en         <= cfg_data_i[31];
                        r_slave_i2s_2ch        <= cfg_data_i[17];
                        r_slave_i2s_lsb_first  <= cfg_data_i[16];
                        r_slave_i2s_bits_word  <= cfg_data_i[12:8];
                        r_slave_i2s_words      <= cfg_data_i[2:0];
                    end
                end
                `REG_I2S_MST_SETUP:   
                begin
                    if(!r_master_clk_en)
                    begin
                        r_master_i2s_en        <= cfg_data_i[31];
                        r_master_i2s_2ch       <= cfg_data_i[17];
                        r_master_i2s_lsb_first <= cfg_data_i[16];
                        r_master_i2s_bits_word <= cfg_data_i[12:8];
                        r_master_i2s_words     <= cfg_data_i[2:0];
                    end
                end
                `REG_I2S_PDM_SETUP:
                begin
                    if(!r_slave_clk_en)
                    begin
                        r_slave_pdm_en         <= cfg_data_i[31];
                        r_slave_pdm_mode       <= cfg_data_i[14:13];
                        r_slave_pdm_decimation <= cfg_data_i[12:3];
                        r_slave_pdm_shift      <= cfg_data_i[2:0];
                    end
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
            cfg_data_o = {26'h0,cfg_rx_pending_i,cfg_rx_en_i,1'b0,r_rx_datasize,r_rx_continuous};
        `REG_TX_SADDR:
            cfg_data_o = cfg_tx_curr_addr_i;
        `REG_TX_SIZE:
            cfg_data_o[TRANS_SIZE-1:0] = cfg_tx_bytes_left_i;
        `REG_TX_CFG:
            cfg_data_o = {26'h0,cfg_tx_pending_i,cfg_tx_en_i,1'b0,r_tx_datasize,r_tx_continuous};
        `REG_I2S_CLKCFG_SETUP:  
            cfg_data_o = {  r_master_sel_num,
                            r_master_sel_ext,
                            r_slave_sel_num,
                            r_slave_sel_ext,
                            2'b00,
                            r_master_clk_en,
                            r_slave_clk_en,
                            r_common_gen_clk_div,
                            r_slave_gen_clk_div,
                            r_master_gen_clk_div };
        `REG_I2S_SLV_SETUP:   
            cfg_data_o = {  r_slave_i2s_en,
                            13'h0,
                            r_slave_i2s_2ch,
                            r_slave_i2s_lsb_first,
                            3'h0,
                            r_slave_i2s_bits_word,
                            5'h0,
                            r_slave_i2s_words };
        `REG_I2S_MST_SETUP:   
            cfg_data_o = {  r_master_i2s_en,
                            13'h0,
                            r_master_i2s_2ch,
                            r_master_i2s_lsb_first,
                            3'h0,
                            r_master_i2s_bits_word,
                            5'h0,
                            r_master_i2s_words };
        `REG_I2S_PDM_SETUP:
            cfg_data_o = {  r_slave_pdm_en,
                            17'h0,
                            r_slave_pdm_mode,
                            r_slave_pdm_decimation,
                            r_slave_pdm_shift };
        default:
            cfg_data_o = 'h0;
        endcase
    end

    assign cfg_ready_o  = 1'b1;

endmodule 
