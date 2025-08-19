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
// Design Name:    SPI Master TX RX subblock                                  //
// Project Name:   SPI Master                                                 //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Does the S/P and P/S conversion with                       //
//                 support for both STD and QUAD                              //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`include "udma_spim_defines.sv" 

module udma_spim_txrx
(
	input  logic         clk_i,
	input  logic         rstn_i,
        
	input  logic         cfg_cpol_i,
	input  logic         cfg_cpha_i,

	input  logic         tx_start_i,
	input  logic [15:0]  tx_size_i,
    input  logic         tx_qpi_i,
    input  logic  [4:0]  tx_bitsword_i,
    input  logic  [1:0]  tx_wordtransf_i,
    input  logic         tx_lsbfirst_i,
	output logic         tx_done_o,
	input  logic [31:0]  tx_data_i,
	input  logic         tx_data_valid_i,
	output logic         tx_data_ready_o,
        
	input  logic         rx_start_i,
	input  logic [15:0]  rx_size_i,
    input  logic         rx_qpi_i,
    input  logic  [4:0]  rx_bitsword_i,
    input  logic  [1:0]  rx_wordtransf_i,
    input  logic         rx_lsbfirst_i,
	output logic         rx_done_o,
	output logic [31:0]  rx_data_o,
	output logic         rx_data_valid_o,
	input  logic         rx_data_ready_i,
    input  logic         rx_backpressure_i,
        
	output logic         spi_clk_o,
    output logic         spi_oen0_o,
    output logic         spi_oen1_o,
    output logic         spi_oen2_o,
    output logic         spi_oen3_o,
    output logic         spi_sdo0_o,
    output logic         spi_sdo1_o,
    output logic         spi_sdo2_o,
    output logic         spi_sdo3_o,
	input  logic         spi_sdi0_i,
	input  logic         spi_sdi1_i,
	input  logic         spi_sdi2_i,
	input  logic         spi_sdi3_i
);

    enum logic [3:0] {TX_IDLE,TX_SEND,TX_WAIT_DATA} tx_state,tx_state_next;
    enum logic [3:0] {RX_IDLE,RX_RECEIVE} rx_state,rx_state_next;

    logic [15:0] s_tx_counter_hi;
    logic [15:0] s_rx_counter_hi;
    logic [15:0] r_counter_hi;
    logic        s_tx_sample_hi;
    logic        s_rx_sample_hi;

    logic [31:0] s_tx_shift_reg;
    logic [31:0] r_tx_shift_reg;
    logic [31:0] s_rx_shift_reg;
    logic [31:0] r_rx_shift_reg;

	logic        s_tx_clken; 
	logic        s_rx_clken; 
	logic        r_rx_clken;

    logic        r_tx_is_last;
    logic        r_rx_is_last;
    logic        s_tx_is_last;
    logic        s_rx_is_last;

	logic        s_tx_sample_in;
	logic        s_sample_rx_in;

	logic        s_tx_driving;

	logic s_spi_sdo0;
	logic s_spi_sdo1;
	logic s_spi_sdo2;
	logic s_spi_sdo3;

	logic [1:0] s_tx_mode;
	logic [1:0] s_rx_mode;
    logic [1:0] s_spi_mode;
    logic [1:0] r_spi_mode;

	logic s_bits_done;

    logic s_rx_idle;
    logic s_tx_idle;

    logic s_is_ful;
    logic r_is_ful;

    //logic r_is_qpi;

	logic s_spi_clk;
	logic s_spi_clk_inv;
    logic s_clken;

    logic       r_lsbfirst;
    logic [4:0] r_bitsword;
    logic [1:0] r_wordtransf;

    logic [4:0] s_tx_counter_bits;
    logic [4:0] s_rx_counter_bits;
    logic [4:0] r_counter_bits;
    logic       s_tx_sample_bits;
    logic       s_rx_sample_bits;

    logic [1:0] s_tx_counter_transf;
    logic [1:0] s_rx_counter_transf;
    logic [1:0] r_counter_transf;
    logic       s_tx_sample_transf;
    logic       s_rx_sample_transf;

    logic    s_spi_clk_cpha0;
    logic    s_clk_inv;
    logic    s_spi_clk_cpha1;

    logic [4:0] s_bit_index;
    logic [4:0] s_bit_offset_add;
    logic [4:0] r_bit_offset;

    logic [31:0] s_data_rx;

    logic        s_transf_done;

    always_comb begin : proc_spi_mode
        case(r_spi_mode)
            `SPI_QUAD_RX:
            begin
                spi_oen0_o = 1'b1;
                spi_oen1_o = 1'b1;
                spi_oen2_o = 1'b1;
                spi_oen3_o = 1'b1;
            end
            `SPI_QUAD_TX:
            begin
                spi_oen0_o = 1'b0;
                spi_oen1_o = 1'b0;
                spi_oen2_o = 1'b0;
                spi_oen3_o = 1'b0;
            end
            `SPI_STD:
            begin
                spi_oen0_o = 1'b0;
                spi_oen1_o = 1'b1;
                spi_oen2_o = 1'b1;
                spi_oen3_o = 1'b1;
            end
            default:
            begin
                spi_oen0_o = 1'b1;
                spi_oen1_o = 1'b1;
                spi_oen2_o = 1'b1;
                spi_oen3_o = 1'b1;
            end    
        endcase
    end
    always_comb begin : proc_offset
        case(r_wordtransf)
            2'b00:
                s_bit_offset_add=5'h0;
            2'b01:
                s_bit_offset_add=5'h10;
            2'b10:
                s_bit_offset_add=5'h8;
            2'b11:
                s_bit_offset_add=5'h8;
        endcase // r_bitsword[4:3]
    end

    always_comb begin : proc_index
        if(r_lsbfirst)
            s_bit_index = r_bit_offset + r_counter_bits;
        else    
            s_bit_index = r_bit_offset + r_bitsword - r_counter_bits;
    end

    always_comb begin : proc_outputs
       if(s_tx_idle)
         begin
            s_spi_sdo0 = 1'b0;
            s_spi_sdo1 = 1'b0;
            s_spi_sdo2 = 1'b0;
            s_spi_sdo3 = 1'b0;
         end
       else
         begin
            if(tx_qpi_i)
              begin
                 if(r_lsbfirst)
                   begin
                      s_spi_sdo0 = r_tx_shift_reg[s_bit_index-3];
                      s_spi_sdo1 = r_tx_shift_reg[s_bit_index-2];
                      s_spi_sdo2 = r_tx_shift_reg[s_bit_index-1];
                      s_spi_sdo3 = r_tx_shift_reg[s_bit_index];
                   end
                 else
                   begin
                      s_spi_sdo0 = r_tx_shift_reg[s_bit_index];
                      s_spi_sdo1 = r_tx_shift_reg[s_bit_index+1];
                      s_spi_sdo2 = r_tx_shift_reg[s_bit_index+2];
                      s_spi_sdo3 = r_tx_shift_reg[s_bit_index+3];
                   end
              end
            else
              begin
                 s_spi_sdo0 = r_tx_shift_reg[s_bit_index];

                 s_spi_sdo1 = 1'b0;
                 s_spi_sdo2 = 1'b0;
                 s_spi_sdo3 = 1'b0;
              end
         end
    end // block: proc_outputs

    always_comb begin : proc_input
        s_data_rx = r_rx_shift_reg;
        if(rx_qpi_i)
        begin
            if(r_lsbfirst)
            begin
                s_data_rx[s_bit_index]   = spi_sdi0_i;
                s_data_rx[s_bit_index+1] = spi_sdi1_i;
                s_data_rx[s_bit_index+2] = spi_sdi2_i;
                s_data_rx[s_bit_index+3] = spi_sdi3_i;
            end
            else
            begin
                s_data_rx[s_bit_index]   = spi_sdi0_i;
                s_data_rx[s_bit_index+1] = spi_sdi1_i;
                s_data_rx[s_bit_index+2] = spi_sdi2_i;
                s_data_rx[s_bit_index+3] = spi_sdi3_i;
            end
        end
        else
        begin
            s_data_rx[s_bit_index] = spi_sdi1_i;
        end
    end

    assign s_clken = s_is_ful ? s_tx_clken : (s_tx_clken | s_rx_clken);

    assign s_spi_mode = s_tx_driving ? s_tx_mode : s_rx_mode;

    assign s_bits_done   = (r_counter_bits   == r_bitsword);
    assign s_transf_done = (r_counter_transf == r_wordtransf);

    assign s_is_ful = (tx_start_i & rx_start_i) | r_is_ful;

`ifndef PULP_FPGA_EMUL
	pulp_clock_gating u_outclkgte_cpol
	(
    	.clk_i(clk_i),
    	.en_i(s_clken),
    	.test_en_i(1'b0),
    	.clk_o(s_spi_clk_cpha0)
	);
`else
    logic     clk_en_cpha0;
    always_ff @(negedge clk_i)
        clk_en_cpha0 <= s_clken;
    assign s_spi_clk_cpha0 = clk_i & clk_en_cpha0;
`endif

    pulp_clock_inverter u_clkinv_cpha
    (
        .clk_i(clk_i),
        .clk_o(s_clk_inv)
    );
      
`ifndef PULP_FPGA_EMUL
    pulp_clock_gating u_outclkgte_cpha
    (
        .clk_i(s_clk_inv),
        .en_i(s_clken),
        .test_en_i(1'b0),
        .clk_o(s_spi_clk_cpha1)
    );
`else
    logic     clk_en_cpha1;
    always_ff @(negedge s_clk_inv)
        clk_en_cpha1 <= s_clken;
    assign s_spi_clk_cpha1 = s_clk_inv & clk_en_cpha1;
`endif

`ifndef PULP_FPGA_EMUL
    pulp_clock_mux2 u_clockmux_cpha
    (
        .clk0_i(s_spi_clk_cpha0),
        .clk1_i(s_spi_clk_cpha1),
        .clk_sel_i(cfg_cpha_i),
        .clk_o(s_spi_clk)
    );
`else
    assign s_spi_clk = ~cfg_cpha_i ? s_spi_clk_cpha0 : s_spi_clk_cpha1;
`endif

	pulp_clock_inverter u_clkinv_cpol
	(
   		.clk_i(s_spi_clk),
   		.clk_o(s_spi_clk_inv)
    );
      
`ifndef PULP_FPGA_EMUL
	pulp_clock_mux2 u_clockmux_cpol    
  	(
   		.clk0_i(s_spi_clk),
   		.clk1_i(s_spi_clk_inv),
   		.clk_sel_i(cfg_cpol_i),
   		.clk_o(spi_clk_o)
    );
`else
    assign spi_clk_o = ~cfg_cpol_i ? s_spi_clk : s_spi_clk_inv;
`endif

    always_comb begin : proc_TX_SM
    	tx_state_next       = tx_state;
        tx_data_ready_o     = 1'b0;
        tx_done_o           = 1'b0;
    	s_tx_clken          = 1'b0;
    	s_tx_sample_in      = 1'b0;
    	s_tx_shift_reg      = r_tx_shift_reg;
    	s_tx_driving        = 1'b0;
    	s_tx_mode           = `SPI_QUAD_RX;
        s_tx_idle           = 1'b0;
        s_tx_is_last        = r_tx_is_last;
        s_tx_counter_hi     = r_counter_hi;
        s_tx_counter_bits   = r_counter_bits;
        s_tx_counter_transf = r_counter_transf;
        s_tx_sample_hi      = 1'b0;
        s_tx_sample_bits    = 1'b0;
        s_tx_sample_transf  = 1'b0;
    	case(tx_state)
    		TX_IDLE:
    		begin
    			if(tx_start_i)
    			begin
                    s_tx_counter_bits = tx_qpi_i ? 'h3 : 'h0;
                    s_tx_sample_bits  = 1'b1;
                    if (tx_size_i == 0)
                        s_tx_is_last = 1'b1;
                    else
                        s_tx_is_last = 1'b0;
    				s_tx_driving   = 1'b1;
    				s_tx_sample_in = 1'b1;
    				if(tx_data_valid_i)
    				begin
				    	tx_data_ready_o = 1'b1;
    					tx_state_next = TX_SEND; 
    					s_tx_shift_reg   = tx_data_i;
    				end
    				else
    					tx_state_next = TX_WAIT_DATA;
    			end
                else
                    s_tx_idle      = 1'b1;
    		end
    		TX_SEND:
    		begin
		    	s_tx_driving = 1'b1;
    			s_tx_clken   = 1'b1;
    			s_tx_mode = tx_qpi_i ? `SPI_QUAD_TX : `SPI_STD;

                s_tx_sample_bits = 1'b1;

                if(s_bits_done)
                begin
                    if(tx_qpi_i)
                        s_tx_counter_bits = 'h3;
                    else
                        s_tx_counter_bits = 'h0;
                end
                else
                begin
                    if(tx_qpi_i)
                        s_tx_counter_bits = r_counter_bits + 4;
                    else
                        s_tx_counter_bits = r_counter_bits + 1;
                end

                if(s_bits_done)
                begin
                    s_tx_sample_transf = 1'b1;
                    if(s_transf_done)
                        s_tx_counter_transf = 'h0;
                    else
                        s_tx_counter_transf = r_counter_transf + 1;
                end

    			if(s_bits_done && (r_counter_hi==0))
    			begin
                    if (r_tx_is_last)
                    begin
                        s_tx_is_last       = 1'b0; 
        				tx_done_o = 1'b1;
                        if(tx_start_i)
    				    begin
    					   s_tx_sample_in = 1'b1;
    					   if(tx_data_valid_i)
    					   begin
					    	  tx_data_ready_o = 1'b1;
    						  tx_state_next = TX_SEND; 
		  					  s_tx_shift_reg   = tx_data_i;
    					   end
    					   else
    						  tx_state_next = TX_WAIT_DATA;
    				    end
    				    else
    					   tx_state_next = TX_IDLE;
                    end
                    else
                    begin
                        s_tx_is_last       = 1'b1; 
                        if(s_transf_done)
                        begin
                            if(tx_data_valid_i)
                            begin
                                tx_data_ready_o = 1'b1;
                                tx_state_next   = TX_SEND; 
                                s_tx_shift_reg  = tx_data_i;
                            end
                            else
                                tx_state_next = TX_WAIT_DATA;
                        end
                    end
    			end
    			else if (s_bits_done)
    			begin
                    s_tx_sample_hi  = 1'b1;
    				s_tx_counter_hi = r_counter_hi -1;
                    if(s_transf_done)
                    begin
       					if(tx_data_valid_i)
   	    				begin
                            tx_data_ready_o = 1'b1;
                            tx_state_next   = TX_SEND; 
	  	                    s_tx_shift_reg  = tx_data_i;
   					    end
   					    else
   						   tx_state_next = TX_WAIT_DATA;
                    end
    			end
    		end
    		TX_WAIT_DATA:
    		begin
		    	s_tx_driving = 1'b1;
    			s_tx_mode    = tx_qpi_i ? `SPI_QUAD_TX : `SPI_STD;
    			if(tx_data_valid_i)
    			begin
			    	tx_data_ready_o = 1'b1;
    				tx_state_next = TX_SEND;
  					s_tx_shift_reg   = tx_data_i;
  				end
    		end
    	endcase // tx_state
    
    end

    always_comb begin : proc_RX_SM
    	rx_state_next       = rx_state;
    	s_rx_clken          = 1'b0;
		rx_done_o           = 1'b0;
		rx_data_o           =  'h0;
		rx_data_valid_o     = 1'b0;
		s_rx_mode           = `SPI_QUAD_RX;
		s_sample_rx_in      = 1'b0;
		s_rx_counter_hi     = r_counter_hi;
        s_rx_counter_bits   = r_counter_bits;
        s_rx_counter_transf = r_counter_transf;
        s_rx_shift_reg      = r_rx_shift_reg;
        s_rx_idle           = 1'b0;
        s_rx_is_last        = r_rx_is_last;
        s_rx_sample_hi      = 1'b0;
        s_rx_sample_bits    = 1'b0;
        s_rx_sample_transf  = 1'b0;
    	case(rx_state)
    		RX_IDLE:
    		begin
    			if(rx_start_i)
    			begin
                    s_rx_mode      = rx_qpi_i ? `SPI_QUAD_RX : `SPI_STD;
    				s_sample_rx_in = 1'b1;
   					rx_state_next  = RX_RECEIVE;
                    s_rx_shift_reg = r_rx_shift_reg;
                    s_rx_counter_bits = rx_qpi_i ? 'h3 : 'h0;
                    s_rx_sample_bits  = 1'b1;
                    if (rx_size_i == 0)
                        s_rx_is_last = 1'b1;
                    else
                        s_rx_is_last = 1'b0;
    			end
                else
                    s_rx_idle      = 1'b1;
    		end
    		RX_RECEIVE:
    		begin
                s_rx_mode        = rx_qpi_i ? `SPI_QUAD_RX : `SPI_STD;
    			s_rx_clken       = rx_data_ready_i || ~rx_backpressure_i;
                s_rx_sample_bits = 1'b1;
                s_rx_shift_reg   = s_data_rx;
                if ((!s_is_ful || (s_is_ful && s_tx_clken)) && (rx_data_ready_i || ~rx_backpressure_i))
                begin
                    if(s_bits_done)
                        if(rx_qpi_i)
                            s_rx_counter_bits = 'h3;
                        else
                            s_rx_counter_bits = 'h0;
                    else
                    begin
                        if(rx_qpi_i)
                            s_rx_counter_bits = r_counter_bits + 4;
                        else
                            s_rx_counter_bits = r_counter_bits + 1;
                    end

    			    if(r_rx_clken)
    			    begin
	    		    	if(s_bits_done)
    			    	begin
                            s_rx_sample_transf = 1'b1;
                            if(r_counter_transf == r_wordtransf)
                            begin
    			    		   rx_data_o           = s_rx_shift_reg;
    			    		   rx_data_valid_o     = 1'b1;
                               s_rx_counter_transf = 0;
                            end
                            else
                            begin
                                s_rx_counter_transf = r_counter_transf + 1;
                            end
    			    	end
                        
	    		    	if(s_bits_done && (r_counter_hi==0))
    			    	begin
                            if (r_rx_is_last)
                            begin
                                s_rx_is_last = 1'b0;
    			    	        rx_done_o = 1'b1;
	    		    	        if(rx_start_i)
    			    	        begin
    			    	            s_sample_rx_in = 1'b1;
                                    rx_state_next  = RX_RECEIVE; 
                                end
                                else
                                    rx_state_next = RX_IDLE;
                            end
                            else
                            begin
                                s_rx_is_last       = 1'b1; 
                            end
    			    	end
	    		    	else if (s_bits_done)
    			    	begin
                            s_rx_sample_hi  = 1'b1;
    			    		s_rx_counter_hi = r_counter_hi -1;
    			    	end
    			    end
                end
    		end
    	endcase // rx_state
    
    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            rx_state <= RX_IDLE;
            tx_state <= TX_IDLE;
        end
        else
        begin
            rx_state <= rx_state_next;
            tx_state <= tx_state_next;
        end

    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_rx_is_last <= 1'b0;
            r_tx_is_last <= 1'b0;
        end
        else
        begin
            r_rx_is_last <= s_rx_is_last;
            r_tx_is_last <= s_tx_is_last;
        end

    end

    always_ff @(posedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
            r_tx_shift_reg   <=  'h0;
            r_rx_shift_reg   <=  'h0;
            r_counter_hi     <=  'h0;
            r_counter_bits   <=  'h0;
            r_counter_transf <=  'h0;
            r_rx_clken       <= 1'b0;
            r_is_ful         <= 1'b0;
            r_lsbfirst       <= 1'b0;
            r_bitsword       <=  'h0;
            r_wordtransf     <=  'h0;
            r_bit_offset     <=  'h0;
        end
        else
        begin
        	r_rx_clken     <= s_rx_clken;
            r_rx_shift_reg <= s_rx_shift_reg;
            r_tx_shift_reg <= s_tx_shift_reg;

            if(s_tx_sample_bits)
                r_counter_bits <= s_tx_counter_bits;
            else if(s_rx_sample_bits)
                r_counter_bits <= s_rx_counter_bits;

            if(s_tx_sample_transf)
                r_counter_transf <= s_tx_counter_transf;
            else if(s_rx_sample_transf)
                r_counter_transf <= s_rx_counter_transf;

            if(tx_start_i || rx_start_i)
                r_bit_offset <= 'h0;
            else if(s_tx_sample_transf || s_rx_sample_transf)
                r_bit_offset <= r_bit_offset + s_bit_offset_add;

            if (tx_start_i && rx_start_i)
                r_is_ful  <= 1'b1;
            else if (s_tx_idle && s_rx_idle)
                r_is_ful  <= 1'b0;

            if(s_tx_sample_in)
            begin
                r_lsbfirst   <= tx_lsbfirst_i;
                r_wordtransf <= tx_wordtransf_i;
                r_bitsword   <= tx_bitsword_i;
            end
            else if(s_sample_rx_in)
            begin
                r_lsbfirst   <= rx_lsbfirst_i;
                r_wordtransf <= rx_wordtransf_i;
                r_bitsword   <= rx_bitsword_i;
            end

        	if(s_tx_sample_in)
        	begin
                if (tx_size_i == 0)
                    r_counter_hi   <= 'h0;
                else
                    r_counter_hi   <= tx_size_i - 1;
        	end
            else if(s_sample_rx_in)
        	begin
                if (rx_size_i == 0)
                    r_counter_hi   <= 'h0;
                else
                    r_counter_hi   <= rx_size_i - 1;
        	end
        	else
            begin
                if(s_tx_sample_hi)
        		  r_counter_hi <= s_tx_counter_hi;
                else if(s_rx_sample_hi)
                  r_counter_hi <= s_rx_counter_hi;
            end
        end
    end

    always_ff @(negedge clk_i, negedge rstn_i)
    begin
        if (rstn_i == 1'b0)
        begin
        	spi_sdo0_o <= 1'b0;
        	spi_sdo1_o <= 1'b0;
        	spi_sdo2_o <= 1'b0;
        	spi_sdo3_o <= 1'b0;
        	r_spi_mode <= `SPI_STD;
        end
        else
        begin
        	spi_sdo0_o <= s_spi_sdo0;
            if (tx_qpi_i)
            begin
        	   spi_sdo1_o <= s_spi_sdo1;
        	   spi_sdo2_o <= s_spi_sdo2;
        	   spi_sdo3_o <= s_spi_sdo3;
            end
        	r_spi_mode <= s_spi_mode;
        end
    end

endmodule // udma_spim_txrx
