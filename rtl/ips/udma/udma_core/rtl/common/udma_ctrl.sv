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
// Description: Configuration IP for uDMA and filtering block
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

// SPI Master Registers
`define REG_CG      5'b00000 //BASEADDR+0x00 
`define REG_CFG_EVT 5'b00001 //BASEADDR+0x04
`define REG_RST     5'b00010 //BASEADDR+0x08
`define REG_RFU     5'b00011 //BASEADDR+0x0C

module udma_ctrl
  #(
    parameter L2_AWIDTH_NOAL = 15,
    parameter TRANS_SIZE     = 15,
    parameter N_PERIPHS      = 6 
    )
   (
	input  logic 	                         clk_i,
	input  logic   	                         rstn_i,

	input  logic                      [31:0] cfg_data_i,
	input  logic                       [4:0] cfg_addr_i,
	input  logic                             cfg_valid_i,
	input  logic                             cfg_rwn_i,
    output logic                      [31:0] cfg_data_o,
	output logic                             cfg_ready_o,

    output logic             [N_PERIPHS-1:0] sw_rst_o,
    output logic             [N_PERIPHS-1:0] cg_value_o,
    output logic                             cg_core_o,

    input  logic                             event_valid_i,
    input  logic                       [7:0] event_data_i,
    output logic                             event_ready_o,

    output logic                       [3:0] event_o
);

    logic [N_PERIPHS-1:0]       r_cg;
    logic [N_PERIPHS-1:0]       r_rst;
    logic           [3:0] [7:0] r_cmp_evt;


    logic                [4:0] s_wr_addr;
    logic                [4:0] s_rd_addr;

    logic s_sample_commit;
    logic s_set_pending;
    logic s_clr_pending;
    logic r_pending;

    enum logic [1:0] { ST_IDLE, ST_SAMPLE, ST_BUSY} r_state,s_state;

    assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i) ? cfg_addr_i : 5'h0;
    assign s_rd_addr = (cfg_valid_i &  cfg_rwn_i) ? cfg_addr_i : 5'h0;

    assign cg_value_o  = r_cg;
    assign cg_core_o   = |r_cg; //if any peripheral enabled then enable the top

    assign sw_rst_o = r_rst;

    assign event_ready_o = 1'b1;

    always_comb begin : proc_event_o
        event_o = 4'h0;
        for (int i=0;i<4;i++)
        begin   
            event_o[i] = event_valid_i & (event_data_i == r_cmp_evt[i]);
        end
    end


    always_ff @(posedge clk_i, negedge rstn_i) 
    begin
        if(~rstn_i) 
        begin
            r_cg      <= 'h0;
            r_cmp_evt <= 'h0;
            r_rst     <= 'h0;
        end
        else
        begin

            if (cfg_valid_i & ~cfg_rwn_i)
            begin
                case (s_wr_addr)
                `REG_CG:
                    r_cg   <= cfg_data_i[N_PERIPHS-1:0];
                `REG_RST:
                    r_rst  <= cfg_data_i[N_PERIPHS-1:0];
                `REG_CFG_EVT:
                begin
                    r_cmp_evt[0] <= cfg_data_i[7:0];
                    r_cmp_evt[1] <= cfg_data_i[15:8];
                    r_cmp_evt[2] <= cfg_data_i[23:16];
                    r_cmp_evt[3] <= cfg_data_i[31:24];
                end
                endcase
            end
        end
    end //always

    always_comb
    begin
        cfg_data_o = 32'h0;
        case (s_rd_addr)
        `REG_CG:
            cfg_data_o[N_PERIPHS-1:0] = r_cg;
        `REG_RST:
            cfg_data_o[N_PERIPHS-1:0] = r_rst;
        `REG_CFG_EVT:
            cfg_data_o = {r_cmp_evt[3],r_cmp_evt[2],r_cmp_evt[1],r_cmp_evt[0]};
        default:
            cfg_data_o = 'h0;
        endcase
    end

    assign cfg_ready_o  = 1'b1;


endmodule 
