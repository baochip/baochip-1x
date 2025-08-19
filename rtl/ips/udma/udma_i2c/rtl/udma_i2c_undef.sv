// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2015-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

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
