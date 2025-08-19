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
`undef REG_RX_SADDR
`undef REG_RX_SIZE
`undef REG_RX_CFG
`undef REG_RX_INTCFG

`undef REG_TX_SADDR
`undef REG_TX_SIZE
`undef REG_TX_CFG
`undef REG_TX_INTCFG

`undef REG_CMD_SADDR
`undef REG_CMD_SIZE
`undef REG_CMD_CFG
`undef REG_CMD_INTCFG

`undef REG_STATUS
`undef REG_SETUP
`undef REG_ACK

// uDMA I2C commands
`undef I2C_CMD_START
`undef I2C_CMD_STOP
`undef I2C_CMD_RD_ACK
`undef I2C_CMD_RD_NACK
`undef I2C_CMD_WR
`undef I2C_CMD_WAIT
`undef I2C_CMD_RPT
`undef I2C_CMD_CFG
`undef I2C_CMD_WAIT_EV
`undef I2C_CMD_WRB
`undef I2C_CMD_EOT

// channel selection commands (TX/RX address and enable)
`undef I2C_CMD_SETUP_UCA
`undef I2C_CMD_SETUP_UCS

`undef BUS_CMD_NONE
`undef BUS_CMD_START
`undef BUS_CMD_STOP
`undef BUS_CMD_WRITE
`undef BUS_CMD_READ
`undef BUS_CMD_WAIT
