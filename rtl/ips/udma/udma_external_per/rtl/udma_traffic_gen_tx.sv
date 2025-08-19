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
// Description: udma_traffic_gen_tx
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Pasquale Davide Schiavone (pschiavo@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module udma_traffic_gen_tx (
     input  logic            clk_i,
     input  logic            rstn_i,
     output logic  [31:0]    tx_o,
     output logic            busy_o,
     input  logic  [31:0]    cfg_setup_i,
     input  logic  [31:0]    tx_data_i,
     input  logic            tx_valid_i,
     output logic            tx_ready_o
 );

    enum logic {IDLE,TRANSMIT_DATA} CS,NS;

    logic         cfg_en;

    logic [31:0] reg_data;
    logic [31:0] reg_data_next;

    logic [2:0] s_target_bits;


    assign cfg_en   = cfg_setup_i[1];

    assign busy_o = (CS != IDLE);

    always_comb
    begin
        NS                  = CS;
        tx_o                = '0;
        tx_ready_o          = 1'b0;
        reg_data_next = tx_data_i;

        case(CS)

           IDLE:
           begin
               if (cfg_en)
                  tx_ready_o = 1'b1;
               if (tx_valid_i)
               begin
                  NS = TRANSMIT_DATA;
               end
           end


           TRANSMIT_DATA:
           begin
               tx_o = reg_data;
               NS   = IDLE;
           end

           default:
           NS = IDLE;

        endcase
    end

    always_ff @(posedge clk_i or negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            CS             <= IDLE;
            reg_data       <= '0;
        end
        else
        begin
          reg_data <= reg_data_next;
        if(cfg_en)
           CS <= NS;
        else
           CS <= IDLE;
        end
    end

endmodule
