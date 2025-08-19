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

// synopsys translate_off
//`include "timescale.v"
// synopsys translate_on

// Define IDCODE Value
`define IDCODE_VALUE  32'h10102001
// 0001             version
// 0000000000000001 part number (IQ)
//                  0001 PULPissimo
//                  0002 PULP
//                  0003 bigPULP
//                  0102 Vincent Vega(derived from PULP)
// 00000000001      manufacturer id
//                  1 ETH
//                  2 Greenwaves
// 1                required by standard

// Length of the Instruction register
`define	IR_LENGTH	5

// Supported Instructions
`define IDCODE          5'b00010
`define REG1            5'b00100
`define REG2            5'b00101
`define REG3            5'b00110
`define REG_CLK_BYP     5'b00111
`define REG_OBSERV      5'b01000
`define REG6            5'b01001
`define BYPASS          5'b11111

// Top module
module tap_top (
  // JTAG pads
  tms_i,
  tck_i,
  rst_ni,
  td_i,
  td_o,

  // TAP states
  shift_dr_o,
  update_dr_o,
  capture_dr_o,

  // Select signals for boundary scan or mbist
  memory_sel_o,
  fifo_sel_o,
  confreg_sel_o,
  clk_byp_sel_o,
  observ_sel_o,

  // TDO signal that is connected to TDI of sub-modules.
  scan_in_o,

  // TDI signals from sub-modules
  memory_out_i,     // from reg1 module
  fifo_out_i,       // from reg2 module
  confreg_out_i,     // from reg3 module
  clk_byp_out_i,
  observ_out_i
);


// JTAG pins
input   tms_i;      // JTAG test mode select pad
input   tck_i;      // JTAG test clock pad
input   rst_ni;     // JTAG test reset pad
input   td_i;      // JTAG test data input pad
output  td_o;      // JTAG test data output pad
//output  tdo_padoe_o;    // Output enable for JTAG test data output pad

// TAP states
output  shift_dr_o;
output  update_dr_o;
output  capture_dr_o;

// Select signals for boundary scan or mbist
output  memory_sel_o;
output  fifo_sel_o;
output  confreg_sel_o;
output  clk_byp_sel_o;
output  observ_sel_o;

// TDO signal that is connected to TDI of sub-modules.
output  scan_in_o;

// TDI signals from sub-modules
input   memory_out_i;      // from reg1 module
input   fifo_out_i;    // from reg2 module
input   confreg_out_i;     // from reg4 module
input   clk_byp_out_i;
input   observ_out_i;


// Registers
reg     test_logic_reset;
reg     run_test_idle;
reg     sel_dr_scan;
reg     capture_dr;
reg     shift_dr;
reg     exit1_dr;
reg     pause_dr;
reg     exit2_dr;
reg     update_dr;
reg     sel_ir_scan;
reg     capture_ir;
reg     shift_ir, shift_ir_neg;
reg     exit1_ir;
reg     pause_ir;
reg     exit2_ir;
reg     update_ir;
reg     idcode_sel;
reg     memory_sel;
reg     fifo_sel;
reg     confreg_sel;
reg     bypass_sel;

reg     clk_byp_sel;
reg     observ_sel;

reg     tdo_comb;
reg     td_o;
//reg     tdo_padoe_o;
reg     tms_q1, tms_q2, tms_q3, tms_q4;
wire    tms_reset;

assign scan_in_o = td_i;
assign shift_dr_o = shift_dr;
assign update_dr_o = update_dr;
assign capture_dr_o = capture_dr;

assign memory_sel_o = memory_sel;
assign fifo_sel_o = fifo_sel;
assign confreg_sel_o = confreg_sel;

assign clk_byp_sel_o  = clk_byp_sel;
assign observ_sel_o   = observ_sel;


always @ (posedge tck_i)
begin
  tms_q1 <=  tms_i;
  tms_q2 <=  tms_q1;
  tms_q3 <=  tms_q2;
  tms_q4 <=  tms_q3;
end


assign tms_reset = tms_q1 & tms_q2 & tms_q3 & tms_q4 & tms_i;    // 5 consecutive TMS=1 causes reset


/**********************************************************************************
*                                                                                 *
*   TAP State Machine: Fully JTAG compliant                                       *
*                                                                                 *
**********************************************************************************/

// test_logic_reset state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    test_logic_reset<= 1'b1;
  else if (tms_reset)
    test_logic_reset<= 1'b1;
  else
    begin
      if(tms_i & (test_logic_reset | sel_ir_scan))
        test_logic_reset<= 1'b1;
      else
        test_logic_reset<= 1'b0;
    end
end

// run_test_idle state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    run_test_idle<= 1'b0;
  else if (tms_reset)
    run_test_idle<= 1'b0;
  else
  if(~tms_i & (test_logic_reset | run_test_idle | update_dr | update_ir))
    run_test_idle<= 1'b1;
  else
    run_test_idle<= 1'b0;
end

// sel_dr_scan state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    sel_dr_scan<= 1'b0;
  else if (tms_reset)
    sel_dr_scan<= 1'b0;
  else
  if(tms_i & (run_test_idle | update_dr | update_ir))
    sel_dr_scan<= 1'b1;
  else
    sel_dr_scan<= 1'b0;
end

// capture_dr state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    capture_dr<= 1'b0;
  else if (tms_reset)
    capture_dr<= 1'b0;
  else
  if(~tms_i & sel_dr_scan)
    capture_dr<= 1'b1;
  else
    capture_dr<= 1'b0;
end

// shift_dr state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    shift_dr<= 1'b0;
  else if (tms_reset)
    shift_dr<= 1'b0;
  else
  if(~tms_i & (capture_dr | shift_dr | exit2_dr))
    shift_dr<= 1'b1;
  else
    shift_dr<= 1'b0;
end

// exit1_dr state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    exit1_dr<= 1'b0;
  else if (tms_reset)
    exit1_dr<= 1'b0;
  else
  if(tms_i & (capture_dr | shift_dr))
    exit1_dr<= 1'b1;
  else
    exit1_dr<= 1'b0;
end

// pause_dr state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    pause_dr<= 1'b0;
  else if (tms_reset)
    pause_dr<= 1'b0;
  else
  if(~tms_i & (exit1_dr | pause_dr))
    pause_dr<= 1'b1;
  else
    pause_dr<= 1'b0;
end

// exit2_dr state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    exit2_dr<= 1'b0;
  else if (tms_reset)
    exit2_dr<= 1'b0;
  else
  if(tms_i & pause_dr)
    exit2_dr<= 1'b1;
  else
    exit2_dr<= 1'b0;
end

// update_dr state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    update_dr<= 1'b0;
  else if (tms_reset)
    update_dr<= 1'b0;
  else
  if(tms_i & (exit1_dr | exit2_dr))
    update_dr<= 1'b1;
  else
    update_dr<= 1'b0;
end

// sel_ir_scan state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    sel_ir_scan<= 1'b0;
  else if (tms_reset)
    sel_ir_scan<= 1'b0;
  else
  if(tms_i & sel_dr_scan)
    sel_ir_scan<= 1'b1;
  else
    sel_ir_scan<= 1'b0;
end

// capture_ir state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    capture_ir<= 1'b0;
  else if (tms_reset)
    capture_ir<= 1'b0;
  else
  if(~tms_i & sel_ir_scan)
    capture_ir<= 1'b1;
  else
    capture_ir<= 1'b0;
end

// shift_ir state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    shift_ir<= 1'b0;
  else if (tms_reset)
    shift_ir<= 1'b0;
  else
  if(~tms_i & (capture_ir | shift_ir | exit2_ir))
    shift_ir<= 1'b1;
  else
    shift_ir<= 1'b0;
end

// exit1_ir state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    exit1_ir<= 1'b0;
  else if (tms_reset)
    exit1_ir<= 1'b0;
  else
  if(tms_i & (capture_ir | shift_ir))
    exit1_ir<= 1'b1;
  else
    exit1_ir<= 1'b0;
end

// pause_ir state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    pause_ir<= 1'b0;
  else if (tms_reset)
    pause_ir<= 1'b0;
  else
  if(~tms_i & (exit1_ir | pause_ir))
    pause_ir<= 1'b1;
  else
    pause_ir<= 1'b0;
end

// exit2_ir state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    exit2_ir<= 1'b0;
  else if (tms_reset)
    exit2_ir<= 1'b0;
  else
  if(tms_i & pause_ir)
    exit2_ir<= 1'b1;
  else
    exit2_ir<= 1'b0;
end

// update_ir state
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    update_ir<= 1'b0;
  else if (tms_reset)
    update_ir<= 1'b0;
  else
  if(tms_i & (exit1_ir | exit2_ir))
    update_ir<= 1'b1;
  else
    update_ir<= 1'b0;
end

/**********************************************************************************
*                                                                                 *
*   End: TAP State Machine                                                        *
*                                                                                 *
**********************************************************************************/



/**********************************************************************************
*                                                                                 *
*   jtag_ir:  JTAG Instruction Register                                           *
*                                                                                 *
**********************************************************************************/
reg [`IR_LENGTH-1:0]  jtag_ir;          // Instruction register
reg [`IR_LENGTH-1:0]  latched_jtag_ir, latched_jtag_ir_neg;
wire                  instruction_tdo;

always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    jtag_ir[`IR_LENGTH-1:0] <=  `IR_LENGTH'b0;
  else if(capture_ir)
    jtag_ir <=  5'b00101;          // This value is fixed for easier fault detection
  else if(shift_ir)
    jtag_ir[`IR_LENGTH-1:0] <=  {td_i, jtag_ir[`IR_LENGTH-1:1]};
end

assign  instruction_tdo =  jtag_ir[0];
/**********************************************************************************
*                                                                                 *
*   End: jtag_ir                                                                  *
*                                                                                 *
**********************************************************************************/



/**********************************************************************************
*                                                                                 *
*   idcode logic                                                                  *
*                                                                                 *
**********************************************************************************/
reg [31:0] idcode_reg;
wire       idcode_tdo;

always @ (posedge tck_i  or negedge rst_ni)
begin
  if (~rst_ni)
    idcode_reg <=  `IDCODE_VALUE;
  else if(idcode_sel & shift_dr)
    idcode_reg <=  {td_i, idcode_reg[31:1]};
  else if(idcode_sel & (capture_dr | exit1_dr))
    idcode_reg <=  `IDCODE_VALUE;
end

assign idcode_tdo = idcode_reg[0];

/**********************************************************************************
*                                                                                 *
*   End: idcode logic                                                             *
*                                                                                 *
**********************************************************************************/


/**********************************************************************************
*                                                                                 *
*   Bypass logic                                                                  *
*                                                                                 *
**********************************************************************************/
wire bypassed_tdo;
reg  bypass_reg;

always @ (posedge tck_i or negedge rst_ni)
begin
  if (~rst_ni)
    bypass_reg<= 1'b0;
  else if(shift_dr)
    bypass_reg<= td_i;
end

assign bypassed_tdo = bypass_reg;
/**********************************************************************************
*                                                                                 *
*   End: Bypass logic                                                             *
*                                                                                 *
**********************************************************************************/


/**********************************************************************************
*                                                                                 *
*   Activating Instructions                                                       *
*                                                                                 *
**********************************************************************************/
// Updating jtag_ir (Instruction Register)
always @ (posedge tck_i or negedge rst_ni)
begin
  if(~rst_ni)
    latched_jtag_ir <= `IDCODE;   // IDCODE seled after reset
  else if (tms_reset)
    latched_jtag_ir <= `IDCODE;   // IDCODE seled after reset
  else if(update_ir)
    latched_jtag_ir <= jtag_ir;
end

/**********************************************************************************
*                                                                                 *
*   End: Activating Instructions                                                  *
*                                                                                 *
**********************************************************************************/


// Updating jtag_ir (Instruction Register)
always @ (latched_jtag_ir)
begin
  idcode_sel           = 1'b0;
  memory_sel           = 1'b0;
  fifo_sel             = 1'b0;
  confreg_sel          = 1'b0;
  bypass_sel           = 1'b0;
  clk_byp_sel          = 1'b0;
  observ_sel           = 1'b0;

  case(latched_jtag_ir)    /* synthesis parallel_case */
    `IDCODE:            idcode_sel           = 1'b1;    // ID Code
    `REG1:              memory_sel           = 1'b1;    // REG1
    `REG2:              fifo_sel             = 1'b1;    // REG2
    `REG3:              confreg_sel          = 1'b1;    // REG3
    `REG_CLK_BYP:       clk_byp_sel          = 1'b1;    // REG4
    `REG_OBSERV:        observ_sel           = 1'b1;    // REG5
    `BYPASS:            bypass_sel           = 1'b1;    // BYPASS
    default:            bypass_sel           = 1'b1;    // BYPASS
  endcase
end



/**********************************************************************************
*                                                                                 *
*   Multiplexing TDO data                                                         *
*                                                                                 *
**********************************************************************************/
always @ (*)
begin
  if(shift_ir_neg)
    tdo_comb = instruction_tdo;
  else
    begin
      case(latched_jtag_ir_neg)    // synthesis parallel_case
        `IDCODE:            tdo_comb = idcode_tdo;        // Reading ID code
        `REG1:              tdo_comb = memory_out_i;      // REG1
        `REG2:              tdo_comb = fifo_out_i;        // REG2
        `REG3:              tdo_comb = confreg_out_i;     // REG3
        `REG_CLK_BYP:       tdo_comb = confreg_out_i;     // REG4
        `REG_OBSERV:        tdo_comb = clk_byp_out_i;     // REG5
        `BYPASS:            tdo_comb = bypassed_tdo;     // BYPASS
        default:            tdo_comb = bypassed_tdo;      // BYPASS instruction
      endcase
    end
end


// Tristate control for td_o pin
always @ (negedge tck_i)
begin
  td_o   <=  tdo_comb;
//  tdo_padoe_o <=  shift_ir | shift_dr ;
end
/**********************************************************************************
*                                                                                 *
*   End: Multiplexing TDO data                                                    *
*                                                                                 *
**********************************************************************************/


always @ (negedge tck_i)
begin
  shift_ir_neg <=  shift_ir;
  latched_jtag_ir_neg <=  latched_jtag_ir;
end

endmodule
