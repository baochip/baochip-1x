// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// This documentation and source code is licensed under the CERN Open Hardware
// License Version 2 – Weakly Reciprocal (http://ohwr.org/cernohl; the
// “License”). Your use of any source code herein is governed by the License.
//
// You may redistribute and modify this documentation under the terms of the
// License. This documentation and source code is distributed WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
// PARTICULAR PURPOSE. Please see the License for the specific language governing
// permissions and limitations under the License.

module udma_scif_tx (
		input  logic            clk_i,
		input  logic            rstn_i,
		output logic            tx_o,
		output logic            tx_oe,
        output logic            busy_o,
		input  logic            cfg_en_i,
		input  logic [15:0]     cfg_div_i,
		input  logic            cfg_parity_en_i,
		input  logic  [1:0]     cfg_bits_i,
		input  logic            cfg_stop_bits_i,
		input  logic  [7:0]     tx_data_i,
		input  logic            tx_valid_i,
		output logic            tx_ready_o
		);
	
	enum logic [2:0] {IDLE,START_BIT,DATA,PARITY,STOP_BIT_FIRST,STOP_BIT_LAST} CS,NS;
	
	logic [7:0] reg_data;
	logic [7:0] reg_data_next;


	logic [2:0] reg_bit_count;
	logic [2:0] reg_bit_count_next;

	logic [2:0] s_target_bits;
	
	logic       parity_bit;
	logic       parity_bit_next;
	
	logic       sampleData;
	
	logic [15:0] baud_cnt;
	logic        baudgen_en;
	logic        bit_done;
	logic 		 tx_o0;

    assign busy_o = (CS != IDLE);

    always_comb
    begin
        case(cfg_bits_i)
            2'b00:
                s_target_bits = 3'h4;
            2'b01:
                s_target_bits = 3'h5;
            2'b10:
                s_target_bits = 3'h6;
            2'b11:
                s_target_bits = 3'h7;
        endcase
    end
	
	always_comb
	begin
		NS = CS;
		tx_o0 = 1'b1;
		sampleData = 1'b0;
		reg_bit_count_next  = reg_bit_count;
		reg_data_next = {1'b1,reg_data[7:1]};
		tx_ready_o = 1'b0;
		baudgen_en = 1'b0;
		parity_bit_next = parity_bit;
		case(CS)
			IDLE:
            begin
            	if (cfg_en_i)
            		tx_ready_o = 1'b1;
				if (tx_valid_i)
				begin
					NS = START_BIT;
					sampleData = 1'b1;
					reg_data_next = tx_data_i;
				end
            end

			START_BIT:
			begin
				tx_o0 = 1'b0;
				parity_bit_next = 1'b0;
				baudgen_en = 1'b1;
				if (bit_done)
					NS = DATA;
			end

			DATA:
			begin
				tx_o0 = reg_data[0];
				baudgen_en = 1'b1;
				parity_bit_next = parity_bit ^ reg_data[0];
				if (bit_done)
				begin
					if (reg_bit_count == s_target_bits)
					begin
						reg_bit_count_next = 'h0;
						if (cfg_parity_en_i)
						begin
							NS = PARITY;
						end
						else
						begin
							NS = STOP_BIT_FIRST;
						end
					end
					else
					begin
						reg_bit_count_next = reg_bit_count + 1;
						sampleData = 1'b1;
					end
				end
			end

			PARITY:
			begin
				tx_o0 = parity_bit;
				baudgen_en = 1'b1;
				if (bit_done)
    			    NS = STOP_BIT_FIRST;
			end
			STOP_BIT_FIRST:
			begin
				tx_o0 = 1'b1;
				baudgen_en = 1'b1;
				if (bit_done)
				begin
                    if (cfg_stop_bits_i)
					    NS = STOP_BIT_LAST;
                    else
    					NS = IDLE;
				end
			end
			STOP_BIT_LAST:
			begin
				tx_o0 = 1'b1;
				baudgen_en = 1'b1;
				if (bit_done)
				begin
					NS = IDLE;
				end
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
			reg_data       <= 8'hFF;
			reg_bit_count  <=  'h0;
			parity_bit     <= 1'b0;
		end
		else
		begin
            if(bit_done)
            begin
	            parity_bit <= parity_bit_next;
            end

	        if(sampleData)
			begin
				reg_data <= reg_data_next;
			end

			reg_bit_count  <= reg_bit_count_next;
            if(cfg_en_i)
	           CS <= NS;
            else
               CS <= IDLE;
		end
	end

	always_ff @(posedge clk_i or negedge rstn_i)
	begin
		if (rstn_i == 1'b0)
		begin
			baud_cnt <= 'h0;
			bit_done <= 1'b0;
		end
		else
		begin
			if(baudgen_en)
			begin
				if(baud_cnt == cfg_div_i)
				begin
					baud_cnt <= 'h0;
					bit_done <= 1'b1;
				end
				else
				begin
					baud_cnt <= baud_cnt + 1;
					bit_done <= 1'b0;
				end
			end
			else
			begin
				baud_cnt <= 'h0;
				bit_done <= 1'b0;
			end
		end
	end
	

	always_ff @(posedge clk_i or negedge rstn_i)
	begin
		if (rstn_i == 1'b0)
		begin
			tx_oe <= '0;
			tx_o  <= '1;
		end
		else
		begin
			tx_oe <= CS != IDLE;
			tx_o <= tx_o0;
		end
	end

endmodule
