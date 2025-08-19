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
// Description: udma_traffic_gen_rx
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Pasquale Davide Schiavone (pschiavo@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////

module udma_traffic_gen_rx (
     input  logic            clk_i,
     input  logic            rstn_i,
     output logic            busy_o,
     input  logic  [31:0]    cfg_setup_i,
     output logic  [31:0]    rx_data_o,
     output logic            rx_valid_o,
     input  logic            rx_ready_i
);

    enum logic [1:0] {IDLE, GENERATE_DATA, WAIT_CLEAR} CS,NS;

    logic [31:0] reg_data;
    logic [31:0] reg_data_next;
    logic [15:0] initial_value;

    logic [2:0]  reg_rx_sync;

    logic [7:0]  reg_count;
    logic [7:0]  reg_count_next;

    logic [7:0]  s_target_word;
    logic        cfg_en;

    logic       sampleData;

    assign busy_o = (CS == GENERATE_DATA);
    assign cfg_en = cfg_setup_i[0];

    assign s_target_word = 0; //COMPLETE THE CODE HERE
    assign initial_value = 0; //COMPLETE THE CODE HERE

     always_comb
     begin
        NS                 = CS;
        sampleData         = 1'b0;
        reg_count_next     = reg_count;
        reg_data_next      = reg_data;
        rx_valid_o         = 1'b0;

        case(CS)

            IDLE:
            begin
                 if (cfg_en)
                 begin
                     NS = GENERATE_DATA;
                     reg_data_next = $unsigned(initial_value);
                 end
            end

            GENERATE_DATA:
            begin
                /*USE HERE THE VALID AND READY SIGNAL TO NOTIFY A NEW DATA*/
            end

            WAIT_CLEAR:
            begin
                if(~cfg_en)
                    NS = IDLE;
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
            reg_count      <= '0;
          end
          else
          begin
            reg_data       <= reg_data_next;
            reg_count      <= reg_count_next;
            CS             <= NS;
          end
     end

    assign rx_data_o = reg_data;

endmodule
