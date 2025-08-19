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
// Description: APB plug for uDMA configuration interface
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////



module udma_apb4k_if
#(
    parameter APB_ADDR_WIDTH = 17,
    parameter N_PERIPHS = 8
)
(
    input  logic    [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic                  [31:0] PWDATA,
    input  logic                         PWRITE,
    input  logic                         PSEL,
    input  logic                         PENABLE,
    output logic                  [31:0] PRDATA,
    output logic                         PREADY,
    output logic                         PSLVERR,

    output logic                  [31:0] periph_data_o,
    output logic                   [4:0] periph_addr_o,
    input  logic  [N_PERIPHS-1:0] [31:0] periph_data_i,
    input  logic  [N_PERIPHS-1:0]        periph_ready_i,
    output logic  [N_PERIPHS-1:0]        periph_valid_o,
    output logic                         periph_rwn_o

);

    logic [4:0] s_periph_sel;
    logic       s_periph_valid;

    assign periph_addr_o  = PADDR[6:2];
    assign periph_rwn_o   = ~PWRITE;
    assign periph_data_o  = PWDATA;

    assign s_periph_sel   = PADDR[APB_ADDR_WIDTH-1:12];
    assign s_periph_valid = PSEL & PENABLE & ( PADDR[11:7] == '0 );

    assign PSLVERR = 1'b0;

    always_comb begin : proc_PRDATA
        PRDATA = 'h0;
        PREADY = 1'b0;
        for (int i=0;i<N_PERIPHS;i++)
        begin
            if (s_periph_sel == i)
            begin
                PRDATA = periph_data_i[i];
                PREADY = periph_ready_i[i];
            end
        end
    end
    
    always_comb begin : proc_periph_valid
        periph_valid_o = 'h0;
        for(int i=0;i<N_PERIPHS;i++)
        begin
            if(s_periph_valid && (s_periph_sel == i))
                periph_valid_o[i] = 1'b1;
        end
    end


endmodule

