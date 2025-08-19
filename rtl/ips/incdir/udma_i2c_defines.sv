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

// I2C Master Registers
`define REG_RX_SADDR     5'b00000 //BASEADDR+0x00
`define REG_RX_SIZE      5'b00001 //BASEADDR+0x04
`define REG_RX_CFG       5'b00010 //BASEADDR+0x08
`define REG_RX_INTCFG    5'b00011 //BASEADDR+0x0C

`define REG_TX_SADDR     5'b00100 //BASEADDR+0x10
`define REG_TX_SIZE      5'b00101 //BASEADDR+0x14
`define REG_TX_CFG       5'b00110 //BASEADDR+0x18
`define REG_TX_INTCFG    5'b00111 //BASEADDR+0x1C

`define REG_CMD_SADDR    5'b01000 //BASEADDR+0x20
`define REG_CMD_SIZE     5'b01001 //BASEADDR+0x24
`define REG_CMD_CFG      5'b01010 //BASEADDR+0x28
`define REG_CMD_INTCFG   5'b01011 //BASEADDR+0x2C

`define REG_STATUS       5'b01100 //BASEADDR+0x30
`define REG_SETUP        5'b01101 //BASEADDR+0x34
`define REG_ACK          5'b01110 //BASEADDR+0X38

// uDMA I2C commands
`define I2C_CMD_START     4'b0000  //  0x0
`define I2C_CMD_STOP      4'b0010  //  0x2
`define I2C_CMD_RD_ACK    4'b0100  //  0x4 --> Send ACK after reading a byte
`define I2C_CMD_RD_NACK   4'b0110  //  0x6 --> Send NACK to end read transfer
`define I2C_CMD_WR        4'b1000  //  0x8 --> write a byte comming from TX
`define I2C_CMD_WAIT      4'b1010  //  0xA --> wait for a set number of cycles
`define I2C_CMD_RPT       4'b1100  //  0xC --> repeat next command N times
`define I2C_CMD_CFG       4'b1110  //  0xE --> CFG bus (clock divider)
`define I2C_CMD_WAIT_EV   4'b0001  //  0x1
`define I2C_CMD_WRB       4'b0111  //  0x7 --> write a byte on bus
`define I2C_CMD_EOT       4'b1001  //  0x9 --> write a byte on bus

// channel selection commands (TX/RX address and enable)
`define I2C_CMD_SETUP_UCA 4'b0011  // 0x3 --> setup tx/rx address
`define I2C_CMD_SETUP_UCS 4'b0101  // 0x5 --> stup tx/rx size + enable transfer

`define BUS_CMD_NONE  3'b000
`define BUS_CMD_START 3'b001
`define BUS_CMD_STOP  3'b010
`define BUS_CMD_WRITE 3'b011
`define BUS_CMD_READ  3'b100
`define BUS_CMD_WAIT  3'b101
