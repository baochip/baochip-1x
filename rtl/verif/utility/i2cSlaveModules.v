//////////////////////////////////////////////////////////////////////
////                                                              ////
//// i2cSlaveTop.v                                                ////
////                                                              ////
//// This file is part of the i2cSlave opencores effort.
//// <http://www.opencores.org/cores//>                           ////
////                                                              ////
//// Module Description:                                          ////
//// Merged version of model/rtl/LGPL/i2cslave designs.
////                                                              ////
//// To Do:                                                       ////
////
////                                                              ////
//// Author(s):                                                   ////
//// - Steve Fielding, sfielding@base2designs.com                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008 Steve Fielding and OPENCORES.ORG          ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE. See the GNU Lesser General Public License for more  ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from <http://www.opencores.org/lgpl.shtml>                   ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
`include "i2cSlave_define.v"

module i2cSlaveTop (
  clk,
  rst,
  sda,
  scl
  //myReg0
);
input clk;
input rst;
inout sda;
input scl;
//output [7:0] myReg0;

parameter DEVICE_ADDR = 7'h34;

i2cSlave #(DEVICE_ADDR)
u_i2cSlave(
  .clk(clk),
  .rst(rst),
  .sda(sda),
  .scl(scl)
  //.myReg0(myReg0),
  //.myReg1(),
  //.myReg2(),
  //.myReg3(),
  //.myReg4(8'h12),
  //.myReg5(8'h34),
  //.myReg6(8'h56),
  //.myReg7(8'h78)

);

endmodule


module i2cSlave (
  clk,
  rst,
  sda,
  scl
  //myReg0,
  //myReg1,
  //myReg2,
  //myReg3,
  //myReg4,
  //myReg5,
  //myReg6,
  //myReg7
);

input clk;
input rst;
inout sda;
input scl;
//output [7:0] myReg0;
//output [7:0] myReg1;
//output [7:0] myReg2;
//output [7:0] myReg3;
//input [7:0] myReg4;
//input [7:0] myReg5;
//input [7:0] myReg6;
//input [7:0] myReg7;

parameter DEVICE_ADDR = 7'h34;

// local wires and regs
reg sdaDeb;
reg sclDeb;
reg [`DEB_I2C_LEN-1:0] sdaPipe;
reg [`DEB_I2C_LEN-1:0] sclPipe;

reg [`SCL_DEL_LEN-1:0] sclDelayed;
reg [`SDA_DEL_LEN-1:0] sdaDelayed;
reg [1:0] startStopDetState;
wire clearStartStopDet;
wire sdaOut;
wire sdaIn;
wire [7:0] regAddr;
wire [7:0] dataToRegIF;
wire writeEn;
wire [7:0] dataFromRegIF;
reg [1:0] rstPipe;
wire rstSyncToClk;
reg startEdgeDet;

assign sda = (sdaOut == 1'b0) ? 1'b0 : 1'bz;
assign sdaIn = sda;

// sync rst rsing edge to clk
always @(posedge clk) begin
  if (rst == 1'b1)
    rstPipe <= 2'b11;
  else
    rstPipe <= {rstPipe[0], 1'b0};
end

assign rstSyncToClk = rstPipe[1];

// debounce sda and scl
always @(posedge clk) begin
  if (rstSyncToClk == 1'b1) begin
    sdaPipe <= {`DEB_I2C_LEN{1'b1}};
    sdaDeb <= 1'b1;
    sclPipe <= {`DEB_I2C_LEN{1'b1}};
    sclDeb <= 1'b1;
  end
  else begin
    sdaPipe <= {sdaPipe[`DEB_I2C_LEN-2:0], sdaIn};
    sclPipe <= {sclPipe[`DEB_I2C_LEN-2:0], scl};
    if (&sclPipe[`DEB_I2C_LEN-1:1] == 1'b1)
      sclDeb <= 1'b1;
    else if (|sclPipe[`DEB_I2C_LEN-1:1] == 1'b0)
      sclDeb <= 1'b0;
    if (&sdaPipe[`DEB_I2C_LEN-1:1] == 1'b1)
      sdaDeb <= 1'b1;
    else if (|sdaPipe[`DEB_I2C_LEN-1:1] == 1'b0)
      sdaDeb <= 1'b0;
  end
end


// delay scl and sda
// sclDelayed is used as a delayed sampling clock
// sdaDelayed is only used for start stop detection
// Because sda hold time from scl falling is 0nS
// sda must be delayed with respect to scl to avoid incorrect
// detection of start/stop at scl falling edge. 
always @(posedge clk) begin
  if (rstSyncToClk == 1'b1) begin
    sclDelayed <= {`SCL_DEL_LEN{1'b1}};
    sdaDelayed <= {`SDA_DEL_LEN{1'b1}};
  end
  else begin
    sclDelayed <= {sclDelayed[`SCL_DEL_LEN-2:0], sclDeb};
    sdaDelayed <= {sdaDelayed[`SDA_DEL_LEN-2:0], sdaDeb};
  end
end

// start stop detection
always @(posedge clk) begin
  if (rstSyncToClk == 1'b1) begin
    startStopDetState <= `NULL_DET;
    startEdgeDet <= 1'b0;
  end
  else begin
    if (sclDeb == 1'b1 && sdaDelayed[`SDA_DEL_LEN-2] == 1'b0 && sdaDelayed[`SDA_DEL_LEN-1] == 1'b1)
      startEdgeDet <= 1'b1;
    else
      startEdgeDet <= 1'b0;
    if (clearStartStopDet == 1'b1)
      startStopDetState <= `NULL_DET;
    else if (sclDeb == 1'b1) begin
      if (sdaDelayed[`SDA_DEL_LEN-2] == 1'b1 && sdaDelayed[`SDA_DEL_LEN-1] == 1'b0) 
        startStopDetState <= `STOP_DET;
      else if (sdaDelayed[`SDA_DEL_LEN-2] == 1'b0 && sdaDelayed[`SDA_DEL_LEN-1] == 1'b1)
        startStopDetState <= `START_DET;
    end
  end
end


registerInterface u_registerInterface(
  .clk(clk),
  .rst(rstSyncToClk), 
  .addr(regAddr),
  .dataIn(dataToRegIF),
  .writeEn(writeEn),
  .dataOut(dataFromRegIF)
  //.myReg0(myReg0),
  //.myReg1(myReg1),
  //.myReg2(myReg2),
  //.myReg3(myReg3),
  //.myReg4(myReg4),
  //.myReg5(myReg5),
  //.myReg6(myReg6),
  //.myReg7(myReg7)
);

serialInterface #(DEVICE_ADDR)
u_serialInterface (
  .clk(clk), 
  .rst(rstSyncToClk | startEdgeDet), 
  .dataIn(dataFromRegIF), 
  .dataOut(dataToRegIF), 
  .writeEn(writeEn),
  .regAddr(regAddr), 
  .scl(sclDelayed[`SCL_DEL_LEN-1]), 
  .sdaIn(sdaDeb), 
  .sdaOut(sdaOut), 
  .startStopDetState(startStopDetState),
  .clearStartStopDet(clearStartStopDet) 
);


endmodule


module registerInterface (
  clk,
  rst,
  addr,
  dataIn,
  writeEn,
  dataOut
  //myReg0,
  //myReg1,
  //myReg2,
  //myReg3,
  //myReg4,
  //myReg5,
  //myReg6,
  //myReg7

);
input clk;
input rst;
input [7:0] addr;
input [7:0] dataIn;
input writeEn;
output [7:0] dataOut;
//output [7:0] myReg0;
//output [7:0] myReg1;
//output [7:0] myReg2;
//output [7:0] myReg3;
//input [7:0] myReg4;
//input [7:0] myReg5;
//input [7:0] myReg6;
//input [7:0] myReg7;

reg [7:0] dataOut;
reg [7:0] myReg0;
reg [7:0] myReg1;
reg [7:0] myReg2;
reg [7:0] myReg3;
reg [7:0] myReg4;
reg [7:0] myReg5;
reg [7:0] myReg6;
reg [7:0] myReg7;
reg [7:0] myReg8;
reg [7:0] myReg9;
reg [7:0] myReg10;
reg [7:0] myReg11;
reg [7:0] myReg12;
reg [7:0] myReg13;
reg [7:0] myReg14;
reg [7:0] myReg15;

// --- I2C Read
always @(posedge clk) begin
  case (addr)
    8'h00: dataOut <= myReg0;  
    8'h01: dataOut <= myReg1;  
    8'h02: dataOut <= myReg2;  
    8'h03: dataOut <= myReg3;  
    8'h04: dataOut <= myReg4;  
    8'h05: dataOut <= myReg5;  
    8'h06: dataOut <= myReg6;  
    8'h07: dataOut <= myReg7;  
    8'h08: dataOut <= myReg8;  
    8'h09: dataOut <= myReg9;  
    8'h0A: dataOut <= myReg10;  
    8'h0B: dataOut <= myReg11;  
    8'h0C: dataOut <= myReg12;  
    8'h0D: dataOut <= myReg13;  
    8'h0E: dataOut <= myReg14;  
    8'h0F: dataOut <= myReg15;  
    default: dataOut <= 8'hxx;
  endcase
end

// --- I2C Write
always @(posedge clk) begin
  if (rst) begin
      myReg0  <= 8'h0;  
      myReg1  <= 8'h0;  
      myReg2  <= 8'h0;  
      myReg3  <= 8'h0;  
      myReg4  <= 8'h0;  
      myReg5  <= 8'h0;  
      myReg6  <= 8'h0;  
      myReg7  <= 8'h0;  
      myReg8  <= 8'h0;  
      myReg9  <= 8'h0;  
      myReg10 <= 8'h0;  
      myReg11 <= 8'h0;  
      myReg12 <= 8'h0;  
      myReg13 <= 8'h0;  
      myReg14 <= 8'h0;  
      myReg15 <= 8'h0;  
  end
  else if (writeEn == 1'b1) begin
    case (addr)
      8'h00: myReg0 <= dataIn;  
      8'h01: myReg1 <= dataIn;
      8'h02: myReg2 <= dataIn;
      8'h03: myReg3 <= dataIn;
      8'h04: myReg4 <= dataIn;
      8'h05: myReg5 <= dataIn;
      8'h06: myReg6 <= dataIn;
      8'h07: myReg7 <= dataIn;
      8'h08: myReg8 <= dataIn;
      8'h09: myReg9 <= dataIn;
      8'h0A: myReg10 <= dataIn;
      8'h0B: myReg11 <= dataIn;
      8'h0C: myReg12 <= dataIn;
      8'h0D: myReg13 <= dataIn;
      8'h0E: myReg14 <= dataIn;
      8'h0F: myReg15 <= dataIn;
    endcase
  end
end

endmodule


module serialInterface (clearStartStopDet, clk, dataIn, dataOut, regAddr, rst, scl, sdaIn, sdaOut, startStopDetState, writeEn);
input   clk;
input   [7:0]dataIn;
input   rst;
input   scl;
input   sdaIn;
input   [1:0]startStopDetState;
output  clearStartStopDet;
output  [7:0]dataOut;
output  [7:0]regAddr;
output  sdaOut;
output  writeEn;

parameter DEVICE_ADDR = 7'h34;

reg     clearStartStopDet, next_clearStartStopDet;
wire    clk;
wire    [7:0]dataIn;
reg     [7:0]dataOut, next_dataOut;
reg     [7:0]regAddr, next_regAddr;
wire    rst;
wire    scl;
wire    sdaIn;
reg     sdaOut, next_sdaOut;
wire    [1:0]startStopDetState;
reg     writeEn, next_writeEn;

// diagram signals declarations
reg  [2:0]bitCnt, next_bitCnt;
reg  [7:0]rxData, next_rxData;
reg  [1:0]streamSt, next_streamSt;
reg  [7:0]txData, next_txData;

// BINARY ENCODED state machine: SISt
// State codes definitions:
`define START 4'b0000
`define CHK_RD_WR 4'b0001
`define READ_RD_LOOP 4'b0010
`define READ_WT_HI 4'b0011
`define READ_CHK_LOOP_FIN 4'b0100
`define READ_WT_LO 4'b0101
`define READ_WT_ACK 4'b0110
`define WRITE_WT_LO 4'b0111
`define WRITE_WT_HI 4'b1000
`define WRITE_CHK_LOOP_FIN 4'b1001
`define WRITE_LOOP_WT_LO 4'b1010
`define WRITE_ST_LOOP 4'b1011
`define WRITE_WT_LO2 4'b1100
`define WRITE_WT_HI2 4'b1101
`define WRITE_CLR_WR 4'b1110
`define WRITE_CLR_ST_STOP 4'b1111

reg [3:0]CurrState_SISt, NextState_SISt;

reg [8*20:0] cstate_name;
always @ * begin
  case (CurrState_SISt)
    `START: cstate_name = "START";
    `CHK_RD_WR: cstate_name = "CHK_RD_WR";
    `READ_RD_LOOP: cstate_name = "READ_RD_LOOP";
    `READ_WT_HI: cstate_name = "READ_WT_HI";
    `READ_CHK_LOOP_FIN: cstate_name = "READ_CHK_LOOP_FIN";
    `READ_WT_LO: cstate_name = "READ_WT_LO";
    `READ_WT_ACK: cstate_name = "READ_WT_ACK";
    `WRITE_WT_LO: cstate_name = "WRITE_WT_LO";
    `WRITE_WT_HI: cstate_name = "WRITE_WT_HI";
    `WRITE_CHK_LOOP_FIN: cstate_name = "WRITE_CHK_LOOP_FIN";
    `WRITE_LOOP_WT_LO: cstate_name = "WRITE_LOOP_WT_LO";
    `WRITE_ST_LOOP: cstate_name = "WRITE_ST_LOOP";
    `WRITE_WT_LO2: cstate_name = "WRITE_WT_LO2";
    `WRITE_WT_HI2: cstate_name = "WRITE_WT_HI2";
    `WRITE_CLR_WR: cstate_name = "WRITE_CLR_WR";
    `WRITE_CLR_ST_STOP: cstate_name = "WRITE_ST_STOP";
  endcase
end

// Diagram actions (continuous assignments allowed only: assign ...)
// diagram ACTION


// Machine: SISt

// NextState logic (combinatorial)
always @ (startStopDetState or streamSt or scl or txData or bitCnt or rxData or sdaIn or regAddr or dataIn or sdaOut or writeEn or dataOut or clearStartStopDet or CurrState_SISt)
begin
  NextState_SISt <= CurrState_SISt;
  // Set default values for outputs and signals
  next_streamSt <= streamSt;
  next_txData <= txData;
  next_rxData <= rxData;
  next_sdaOut <= sdaOut;
  next_writeEn <= writeEn;
  next_dataOut <= dataOut;
  next_bitCnt <= bitCnt;
  next_clearStartStopDet <= clearStartStopDet;
  next_regAddr <= regAddr;
  case (CurrState_SISt)  // synopsys parallel_case full_case
    `START:
    begin
      next_streamSt <= `STREAM_IDLE;
      next_txData <= 8'h00;
      next_rxData <= 8'h00;
      next_sdaOut <= 1'b1;
      next_writeEn <= 1'b0;
      next_dataOut <= 8'h00;
      next_bitCnt <= 3'b000;
      next_clearStartStopDet <= 1'b0;
      NextState_SISt <= `CHK_RD_WR;
    end
    `CHK_RD_WR:
    begin
      if (streamSt == `STREAM_READ)
      begin
        NextState_SISt <= `READ_RD_LOOP;
        next_txData <= dataIn;
        next_regAddr <= regAddr + 1'b1;
        next_bitCnt <= 3'b001;
      end
      else
      begin
        NextState_SISt <= `WRITE_WT_HI;
        next_rxData <= 8'h00;
      end
    end
    `READ_RD_LOOP:
    begin
      if (scl == 1'b0)
      begin
        NextState_SISt <= `READ_WT_HI;
        next_sdaOut <= txData [7];
        next_txData <= {txData [6:0], 1'b0};
      end
    end
    `READ_WT_HI:
    begin
      if (scl == 1'b1)
      begin
        NextState_SISt <= `READ_CHK_LOOP_FIN;
      end
    end
    `READ_CHK_LOOP_FIN:
    begin
      if (bitCnt == 3'b000)
      begin
        NextState_SISt <= `READ_WT_LO;
      end
      else
      begin
        NextState_SISt <= `READ_RD_LOOP;
        next_bitCnt <= bitCnt + 1'b1;
      end
    end
    `READ_WT_LO:
    begin
      if (scl == 1'b0)
      begin
        NextState_SISt <= `READ_WT_ACK;
        next_sdaOut <= 1'b1;
      end
    end
    `READ_WT_ACK:
    begin
      if (scl == 1'b1)
      begin
        NextState_SISt <= `CHK_RD_WR;
        if (sdaIn == `I2C_NAK)
        next_streamSt <= `STREAM_IDLE;
      end
    end
    `WRITE_WT_LO:
    begin
      if ((scl == 1'b0) && (startStopDetState == `STOP_DET || 
        (streamSt == `STREAM_IDLE && startStopDetState == `NULL_DET)))
      begin
        NextState_SISt <= `WRITE_CLR_ST_STOP;
        case (startStopDetState)
        `NULL_DET:
        next_bitCnt <= bitCnt + 1'b1;
        `START_DET: begin
        next_streamSt <= `STREAM_IDLE;
        next_rxData <= 8'h00;
        end
        default: ;
        endcase
        next_streamSt <= `STREAM_IDLE;
        next_clearStartStopDet <= 1'b1;
      end
      else if (scl == 1'b0)
      begin
        NextState_SISt <= `WRITE_ST_LOOP;
        case (startStopDetState)
        `NULL_DET:
        next_bitCnt <= bitCnt + 1'b1;
        `START_DET: begin
        next_streamSt <= `STREAM_IDLE;
        next_rxData <= 8'h00;
        end
        default: ;
        endcase
      end
    end
    `WRITE_WT_HI:
    begin
      if (scl == 1'b1)
      begin
        NextState_SISt <= `WRITE_WT_LO;
        next_rxData <= {rxData [6:0], sdaIn};
        next_bitCnt <= 3'b000;
      end
    end
    `WRITE_CHK_LOOP_FIN:
    begin
      if (bitCnt == 3'b111)
      begin
        NextState_SISt <= `WRITE_CLR_WR;
        next_sdaOut <= `I2C_ACK;
        case (streamSt)
        `STREAM_IDLE: begin
        //if (rxData[7:1] == `I2C_ADDRESS &&
        if (rxData[7:1] == DEVICE_ADDR &&
        startStopDetState == `START_DET) begin
        if (rxData[0] == 1'b1)
        next_streamSt <= `STREAM_READ;
        else
        next_streamSt <= `STREAM_WRITE_ADDR;
        end
        else
        next_sdaOut <= `I2C_NAK;
        end
        `STREAM_WRITE_ADDR: begin
        next_streamSt <= `STREAM_WRITE_DATA;
        next_regAddr <= rxData;
        end
        `STREAM_WRITE_DATA: begin
        next_dataOut <= rxData;
        next_writeEn <= 1'b1;
        end
        default:
        next_streamSt <= streamSt;
        endcase
      end
      else
      begin
        NextState_SISt <= `WRITE_ST_LOOP;
        next_bitCnt <= bitCnt + 1'b1;
      end
    end
    `WRITE_LOOP_WT_LO:
    begin
      if (scl == 1'b0)
      begin
        NextState_SISt <= `WRITE_CHK_LOOP_FIN;
      end
    end
    `WRITE_ST_LOOP:
    begin
      if (scl == 1'b1)
      begin
        NextState_SISt <= `WRITE_LOOP_WT_LO;
        next_rxData <= {rxData [6:0], sdaIn};
      end
    end
    `WRITE_WT_LO2:
    begin
      if (scl == 1'b0)
      begin
        NextState_SISt <= `CHK_RD_WR;
        next_sdaOut <= 1'b1;
      end
    end
    `WRITE_WT_HI2:
    begin
      next_clearStartStopDet <= 1'b0;
      if (scl == 1'b1)
      begin
        NextState_SISt <= `WRITE_WT_LO2;
      end
    end
    `WRITE_CLR_WR:
    begin
      if (writeEn == 1'b1)
      next_regAddr <= regAddr + 1'b1;
      next_writeEn <= 1'b0;
      next_clearStartStopDet <= 1'b1;
      NextState_SISt <= `WRITE_WT_HI2;
    end
    `WRITE_CLR_ST_STOP:
    begin
      next_clearStartStopDet <= 1'b0;
      NextState_SISt <= `CHK_RD_WR;
    end
  endcase
end

// Current State Logic (sequential)
always @ (posedge clk)
begin
  if (rst == 1'b1)
    CurrState_SISt <= `START;
  else
    CurrState_SISt <= NextState_SISt;
end

// Registered outputs logic
always @ (posedge clk)
begin
  if (rst == 1'b1)
  begin
    sdaOut <= 1'b1;
    writeEn <= 1'b0;
    dataOut <= 8'h00;
    clearStartStopDet <= 1'b0;
    // regAddr <=     // Initialization in the reset state or default value required!!
    streamSt <= `STREAM_IDLE;
    txData <= 8'h00;
    rxData <= 8'h00;
    bitCnt <= 3'b000;
  end
  else 
  begin
    sdaOut <= next_sdaOut;
    writeEn <= next_writeEn;
    dataOut <= next_dataOut;
    clearStartStopDet <= next_clearStartStopDet;
    regAddr <= next_regAddr;
    streamSt <= next_streamSt;
    txData <= next_txData;
    rxData <= next_rxData;
    bitCnt <= next_bitCnt;
  end
end

endmodule
