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

// register map
`define REG_RX_SADDR     5'b00000 //BASEADDR+0x00 
`define REG_RX_SIZE      5'b00001 //BASEADDR+0x04
`define REG_RX_CFG       5'b00010 //BASEADDR+0x08  
`define REG_RX_INTCFG    5'b00011 //BASEADDR+0x0C  
`define REG_CR_ADC       5'b00100 //BASEADDR+0x10  
module udma_adc_ts_reg_if #(
    parameter L2_AWIDTH_NOAL  = 12,
    parameter UDMA_TRANS_SIZE = 16,
    parameter TRANS_SIZE      = 16,
    parameter CRW = 28

) (
    input  logic                       clk_i,
    input  logic                       rstn_i,

    input  logic                [31:0] cfg_data_i,
    input  logic                 [4:0] cfg_addr_i,
    input  logic                       cfg_valid_i,
    input  logic                       cfg_rwn_i,
    output logic                [31:0] cfg_data_o,
    output logic                       cfg_ready_o,

    output logic             [CRW-1:0] cr_adc,
    output logic  [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
    output logic [UDMA_TRANS_SIZE-1:0] cfg_rx_size_o,
    output logic                 [1:0] cfg_rx_datasize_o,
    output logic                       cfg_rx_continuous_o,
    output logic                       cfg_rx_en_o,
    output logic                       cfg_rx_clr_o,
    input  logic                       cfg_rx_en_i,
    input  logic                       cfg_rx_pending_i,
    input  logic  [L2_AWIDTH_NOAL-1:0] cfg_rx_curr_addr_i,
    input  logic [UDMA_TRANS_SIZE-1:0] cfg_rx_bytes_left_i
);

    logic [L2_AWIDTH_NOAL-1:0] r_rx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_rx_size;
    logic                      r_rx_continuous;
    logic                      r_rx_en;
    logic                      r_rx_clr;

    logic                [4:0] s_wr_addr;
    logic                [4:0] s_rd_addr;

    assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i) ? cfg_addr_i : 5'h0;
    assign s_rd_addr = (cfg_valid_i &  cfg_rwn_i) ? cfg_addr_i : 5'h0;

    assign cfg_rx_startaddr_o  = r_rx_startaddr;
    assign cfg_rx_datasize_o   = 2'b10;
    assign cfg_rx_continuous_o = r_rx_continuous;
    assign cfg_rx_en_o         = r_rx_en;
    assign cfg_rx_clr_o        = r_rx_clr;

    generate
      assign cfg_rx_size_o[TRANS_SIZE-1:0] = r_rx_size;
      if (UDMA_TRANS_SIZE > TRANS_SIZE)
        assign cfg_rx_size_o[UDMA_TRANS_SIZE-1:TRANS_SIZE] = '0;
    endgenerate

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
            cr_adc          <=   '0;
        end
        else
        begin
            r_rx_en         <=  'h0;
            r_rx_clr        <=  'h0;

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
                    r_rx_continuous  <= cfg_data_i[0];
                end
                `REG_CR_ADC:
                    cr_adc           <= cfg_data_i[CRW-1:0];
                endcase
            end
        end
    end //always

    always_comb
    begin
        cfg_data_o = '0;
        case (s_rd_addr)
        `REG_RX_SADDR:
            cfg_data_o = cfg_rx_curr_addr_i;
        `REG_RX_SIZE:
            cfg_data_o[UDMA_TRANS_SIZE-1:0] = cfg_rx_bytes_left_i;
        `REG_RX_CFG:
            cfg_data_o = {26'h0,cfg_rx_pending_i,cfg_rx_en_i,1'b0,2'b10,r_rx_continuous};
        `REG_CR_ADC:
            cfg_data_o = cr_adc;
        default:
            cfg_data_o = '0;
        endcase
    end

    assign cfg_ready_o  = 1'b1;

endmodule 
`undef REG_RX_SADDR     
`undef REG_RX_SIZE      
`undef REG_RX_CFG       
`undef REG_RX_INTCFG
`undef REG_CR_ADC       