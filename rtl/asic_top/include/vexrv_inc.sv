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

`include "template.sv"

`ifndef FPGA
`define ASIC_TARGET
`endif

`include "modules/vexriscv/lib/arbiter.v"
//`include "ips/vexriscv/cram-soc/candidate/axi_adapter_rd.v"
//`include "ips/vexriscv/cram-soc/candidate/axi_adapter.v"
//`include "ips/vexriscv/cram-soc/candidate/axi_adapter_wr.v"
`include "modules/vexriscv/lib/axi_axil_adapter_rd.v"
`include "modules/vexriscv/lib/axi_axil_adapter.v"
`include "modules/vexriscv/lib/axi_axil_adapter_wr.v"
`include "modules/vexriscv/lib/axi_crossbar_addr.v"
`include "modules/vexriscv/lib/axi_crossbar_rd.v"
`include "modules/vexriscv/lib/axi_crossbar.v"
`include "modules/vexriscv/lib/axi_crossbar_wr.v"
//`include "ips/vexriscv/cram-soc/candidate/axi_ram.v"
`include "modules/vexriscv/lib/axi_register_rd.v"
`include "modules/vexriscv/lib/axi_register_wr.v"
`include "modules/vexriscv/rtl/cram_axi.sv"
`include "modules/vexriscv/lib/priority_encoder.v"
//`include "ips/vexriscv/cram-soc/candidate/ram_1w_1ra.v"
//`include "ips/vexriscv/cram-soc/candidate/ram_1w_1rs.v"
`include "modules/vexriscv/lib/VexRiscv_CramSoC.sv"
`include "modules/vexriscv/lib/fdre_cosim.v"

`include "modules/vexriscv/lib/memory_AesZknPlugin_rom_storage_Rom_1rs.v"


`include "modules/core/rtl/vexram.sv"
`include "modules/core/rtl/vexsys.sv"

//ifdef SYN
// `include "ips/vexriscv/cram-soc/candidate/mbox_blackbox_v0.1.sv"
//`else
 `include "modules/mbox/rtl/mbox_client.v"
 `include "modules/mbox/rtl/mbox.sv"
//`endif

`ifdef SIM
    `define ARM_UD_MODEL
    `define ARM_DISABLE_EMA_CHECK
	`include "asic_top/lib/arm_sram_macro/rdram128x22_srm/rdram128x22.v"
	`include "asic_top/lib/arm_sram_macro/rdram1kx32_srm/rdram1kx32.v"
	`include "asic_top/lib/arm_sram_macro/rdram512x64_srm/rdram512x64.v"
`endif
