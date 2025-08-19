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


`define SDVT_NO_BLACKBOX

`include "ips/smartdv/spi_flash_controller_iip/hdl/include/sdvt_spi_master_defines.vh"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_apb_slave.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_async_blk_cell.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_async_fifo_ctrl.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_async_fifo_ff.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_axi_slave.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_csr.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_dft_mux_cell.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_fsm.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_nedge_cell.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_prescaler.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_sync_cell.v"
//`include "ips/smartdv/spi_flash_controller_iip.20241028/hdl/src/sdvt_spi_master_sync_dpram.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_sync_fifo.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_xip.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/sdvt_spi_master_core.v"
`include "ips/smartdv/spi_flash_controller_iip/hdl/src/qfc_socbus_aes.sv"

`ifndef __TRNGAES
`include "modules/crypto_trng/rtl/aes_cipher_top.v"
`include "modules/crypto_trng/rtl/aes_key_expand_128.v"
`include "modules/crypto_trng/rtl/aes_rcon.v"
`include "modules/crypto_trng/rtl/aes_sbox.v"
`include "modules/crypto_trng/rtl/aes_update.v"
`include "modules/crypto_trng/rtl/ctr_aes.v"
`define __TRNGAES
`endif

`include "modules/core/rtl/qfc_aes.sv"
`include "modules/core/rtl/qfc.sv"
