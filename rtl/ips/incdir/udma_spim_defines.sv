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

`undef REG_STATUS

`define SPI_STD     2'b00
`define SPI_QUAD_TX 2'b10
`define SPI_QUAD_RX 2'b11

`define SPI_CMD_CFG       4'b0000
`define SPI_CMD_SOT       4'b0001
`define SPI_CMD_SEND_CMD  4'b0010

`define SPI_CMD_DUMMY     4'b0100
`define SPI_CMD_WAIT      4'b0101
`define SPI_CMD_TX_DATA   4'b0110
`define SPI_CMD_RX_DATA   4'b0111
`define SPI_CMD_RPT       4'b1000
`define SPI_CMD_EOT       4'b1001
`define SPI_CMD_RPT_END   4'b1010
`define SPI_CMD_RX_CHECK  4'b1011
`define SPI_CMD_FULL_DUPL 4'b1100
`define SPI_CMD_SETUP_UCA 4'b1101
`define SPI_CMD_SETUP_UCS 4'b1110

// SPI Master Registers
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

`define SPI_WAIT_EVT 2'b00
`define SPI_WAIT_CYC 2'b01
`define SPI_WAIT_GP  2'b10
