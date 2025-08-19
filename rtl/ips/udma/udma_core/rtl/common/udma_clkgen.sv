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
// Description: Integer clock divider with async configuration interface
//
///////////////////////////////////////////////////////////////////////////////
//
// Authors    : Antonio Pullini (pullinia@iis.ee.ethz.ch)
//
///////////////////////////////////////////////////////////////////////////////
module udma_clkgen
(
    input  logic                        clk_i,
    input  logic                        rstn_i,
    
    input  logic                        dft_test_mode_i,
    input  logic                        dft_cg_enable_i,
    
    input  logic                        clock_enable_i,
    
    input  logic          [7:0]         clk_div_data_i,
    input  logic                        clk_div_valid_i,
    output logic                        clk_div_ack_o,
    
    output logic                        clk_o
);

   enum                logic [1:0] {IDLE, STOP, WAIT, RELEASE} state, state_next;

   logic               s_clk_out;
   logic               s_clk_out_dft;
   logic               s_clock_enable;
   logic               s_clock_enable_gate;
   logic               s_clk_div_valid;

   logic [7:0]         reg_clk_div;
   logic               s_clk_div_valid_sync;

   logic               r_clockdiv_en;
   logic               s_clockdiv_en;
   logic               r_clockout_mux;
   logic               s_clockout_mux;

   logic               s_clk_out_div;

    assign s_clock_enable_gate =  s_clock_enable & clock_enable_i;


    //handle the handshake with the soc_ctrl. Interface is now async   
    pulp_sync_wedge i_edge_prop
    (
        .clk_i    ( clk_i                ),
        .rstn_i   ( rstn_i               ),
        .en_i     ( 1'b1                 ),
        .serial_i ( clk_div_valid_i      ),
        .serial_o ( clk_div_ack_o        ),
        .r_edge_o ( s_clk_div_valid_sync ),
        .f_edge_o (                      )
    );

    udma_clk_div_cnt i_clkdiv_cnt
    (
        .clk_i           ( clk_i           ),
        .rstn_i          ( rstn_i          ),
        .en_i            ( r_clockdiv_en   ),
        .clk_div_i       ( reg_clk_div     ),
        .clk_div_valid_i ( s_clk_div_valid ),
        .clk_o           ( s_clk_out_div   )
    );

`ifndef PULP_FPGA_EMUL
   pulp_clock_mux2 clk_mux_i 
     (
      .clk0_i    ( s_clk_out_div  ),
      .clk1_i    ( clk_i          ),
      .clk_sel_i ( r_clockout_mux ),
      .clk_o     ( s_clk_out      )
      );
 `ifdef PULP_DFT
   pulp_clock_mux2 clk_mux_dft_i 
     (
      .clk0_i    ( s_clk_out       ),
      .clk1_i    ( clk_i           ),
      .clk_sel_i ( dft_test_mode_i ),
      .clk_o     ( s_clk_out_dft   )
      );
 `else
   assign s_clk_out_dft = s_clk_out;
 `endif
`else
    assign s_clk_out = ~r_clockout_mux ? s_clk_out_div : clk_i;
    assign s_clk_out_dft = s_clk_out;
`endif

    pulp_clock_gating i_clk_gate
    (
        .clk_i     ( s_clk_out_dft       ),
        .en_i      ( s_clock_enable_gate ),
        .test_en_i ( dft_cg_enable_i     ),
        .clk_o     ( clk_o               )
    );

    always_comb
    begin
        s_clockout_mux = r_clockout_mux;
        s_clockdiv_en  = r_clockdiv_en;
        case(state)
        IDLE:
        begin
            s_clock_enable   = 1'b1;
	        s_clockdiv_en    = 1'b1;
            s_clk_div_valid  = 1'b0;
            if (s_clk_div_valid_sync)
                state_next = STOP;
            else
                state_next = IDLE;
        end
        STOP:
        begin
            s_clock_enable   = 1'b0;
            if (reg_clk_div == 0)
            begin
                s_clk_div_valid  = 1'b0;
                s_clockout_mux   = 1'b1;
            end
            else
            begin
                s_clk_div_valid  = 1'b1;
                s_clockout_mux   = 1'b0;
            end
            state_next = WAIT; 
        end

        WAIT:
        begin
            s_clock_enable   = 1'b0;
            s_clk_div_valid  = 1'b0;
            state_next = RELEASE; 
        end

        RELEASE:
        begin
            s_clock_enable   = 1'b0;
            s_clk_div_valid  = 1'b0;
            state_next = IDLE; 
        end
        endcase
    end

    always_ff @(posedge clk_i or negedge rstn_i)
    begin
        if (!rstn_i)
            state <= IDLE;
        else
            state <= state_next;
    end

    always_ff @(posedge clk_i or negedge rstn_i)
    begin
        if (!rstn_i) 
        begin
            r_clockout_mux <= 1;
            r_clockdiv_en  <= 0;
        end
        else
        begin
            r_clockout_mux <= s_clockout_mux;
            r_clockdiv_en  <= s_clockdiv_en;
        end
    end

    //sample the data when valid has been sync and there is a rise edge
    always_ff @(posedge clk_i or negedge rstn_i)
    begin
        if (!rstn_i)
            reg_clk_div <= '0;
        else if (s_clk_div_valid_sync)
                  reg_clk_div <= clk_div_data_i;
    end


endmodule
