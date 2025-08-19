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

// old `include "ips/udc/Innosilicon_2022_11_17/rtl_u2_dev/design_lib.v"
`include "ips/udc/Innosilicon/rtl_u2_dev/design_lib.v"

`ifdef SYN
	`include "ips/udc/Innosilicon/rtl_u2_dev/xhci_top_syn.vp"
`else
	`include "ips/udc/Innosilicon/rtl_u2_dev/xhci_top.vp"
`endif

`include "modules/ifsub/rtl/utmi_def.sv"
`include "modules/ifsub/rtl/udc.sv"

`ifdef SIM
    `define ARM_UD_MODEL
    `define ARM_DISABLE_EMA_CHECK
    `include "asic_top/lib/arm_sram_macro/udcmem_256x64/udcmem_256x64.v"
	`include "asic_top/lib/arm_sram_macro/udcmem_1088x64/udcmem_1088x64.v"
`endif
