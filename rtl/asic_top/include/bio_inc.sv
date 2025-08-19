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

`default_nettype wire
`include "modules/bio_bdma/rtl/bio_bdma.sv"
`include "modules/bio_bdma/rtl/picorv32.v"
`include "modules/pio/rtl/pio_divider.v"
`include "modules/bio_bdma/rtl/ram_1rw_s.sv"
`include "modules/bio_bdma/rtl/regfifo.v"

`include "modules/bio_bdma/lib/cdc_blinded.v"
`include "modules/bio_bdma/lib/cdc_level_to_pulse.sv"

`include "modules/bio_bdma/lib/axil_crossbar.v"
`include "modules/bio_bdma/lib/axil_crossbar_addr.v"
`include "modules/bio_bdma/lib/axil_crossbar_rd.v"
`include "modules/bio_bdma/lib/axil_crossbar_wr.v"
`include "modules/bio_bdma/lib/axil_register_wr.v"
`include "modules/bio_bdma/lib/axil_register_rd.v"
`include "modules/bio_bdma/lib/axil_reg_if.v"
`include "modules/bio_bdma/lib/axil_reg_if_rd.v"
`include "modules/bio_bdma/lib/axil_reg_if_wr.v"
`include "modules/bio_bdma/lib/axil_cdc.v"
`include "modules/bio_bdma/lib/axil_cdc_wr.v"
`include "modules/bio_bdma/lib/axil_cdc_rd.v"

`ifdef SIM
`include "asic_top/lib/arm_sram_macro/bioram1kx32_srm/bioram1kx32.v"
`endif
