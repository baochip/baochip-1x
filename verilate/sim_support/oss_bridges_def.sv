// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: CERN-OHL-W-2.0
//
// This documentation and source code is licensed under the CERN Open Hardware
// License Version 2 - Weakly Reciprocal (http://ohwr.org/cernohl; the
// "License"). Your use of any source code herein is governed by the License.
//
// You may redistribute and modify this documentation under the terms of the
// License. This documentation and source code is distributed WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
// PARTICULAR PURPOSE. Please see the License for the specific language governing
// permissions and limitations under the License.

// Selects the open-source re-implementations of the ARM CMSDK bus bridges
// (oss_ahb_to_apb, oss_ahb_to_ahb_sync, oss_ahb_to_ahb_sync_err_canc,
// oss_ahb_to_sram, oss_ahb_master_mux) inside amba_components.sv, pke.sv
// and ahbsramc.sv for sim builds, replacing the closed cmsdk_* models.
// Added ahead of the RTL file list by deps/soc_oss/sce_adapter.py so the
// define is visible where the bridges are instantiated (Verilator scopes
// `define across the whole compilation unit). ASIC flows omit this file
// and keep the cmsdk models. Equivalence: tb/oss_equiv/run_equiv.sh.
`define USE_OSS_BRIDGE
