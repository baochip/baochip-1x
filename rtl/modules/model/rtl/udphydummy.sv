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

module inno_usb_phy(
   // Outputs
   fss_rxdp_0, fss_rxdm_0, fss_rxrcv_0, utmi_clk_0, utmi_linestat_0,
   utmi_rxactive_0, utmi_rxvalid_l_0,
   utmi_rxerror_0, utmi_rxdata_0, utmi_txready_0, utmi_hostdisc_0,
   utmi_bistdone_0, utmi_status_0, prdata, pready, clk48m, clk60m, clk12m,
   // Inouts
   USB0PN, USB0PP, VCCA3P3, VCCCORE,VDD,VSS,VSSA, VSSD,
   // Inputs
   utmi_refclk, POR_reset, fss_serialmode_0, fss_txenablez_0,
   fss_txdata_0, fss_txsezero_0, utmi_reset_0, utmi_txvalid_l_0,
   utmi_txdata_0, utmi_xcvrselect_0,
   utmi_termselect_0, utmi_opmode_0, utmi_suspendm_0,
   utmi_dppulldown_0, utmi_dmpulldown_0, utmi_biston_0,
   utmi_testcontrol_0, pclk, penable, psel, pwrite, presetn, paddr,
   pwdata,dft_clk,dft_reset,dft_mode,dft_se,dft_si_0,dft_so_0
   );

//***********************************************************************//
// USB pll refrence clock 24MHz
//***********************************************************************//
input wire          utmi_refclk;
//***********************************************************************//
// USB Power-on reset
//***********************************************************************//
input wire          POR_reset;
//***********************************************************************//
//  7-Wire Interface
//***********************************************************************//
input wire          fss_serialmode_0;
input wire          fss_txenablez_0;
input wire          fss_txdata_0;
input wire          fss_txsezero_0;
output wire         fss_rxdp_0;
output wire         fss_rxdm_0;
output wire         fss_rxrcv_0;

//***********************************************************************//
// UTMI interface for port0
//***********************************************************************//
input wire          utmi_reset_0;
output wire         utmi_clk_0;
output wire [1:0]   utmi_linestat_0;
output wire         utmi_rxactive_0;
output wire         utmi_rxvalid_l_0;
output wire         utmi_rxerror_0;
output wire [7:0]   utmi_rxdata_0;
output wire         utmi_txready_0;
output wire         utmi_hostdisc_0;
input wire          utmi_txvalid_l_0;
input wire  [7:0]   utmi_txdata_0;
input wire  [1:0]   utmi_xcvrselect_0;
input wire          utmi_termselect_0;
input wire  [1:0]   utmi_opmode_0;
input wire          utmi_suspendm_0;
input wire          utmi_dppulldown_0;
input wire          utmi_dmpulldown_0;

//***********************************************************************//
//  Bist Test Interface for port0
//***********************************************************************//
input wire          utmi_biston_0;
input wire  [1:0]   utmi_testcontrol_0;
output wire         utmi_bistdone_0;
output wire [1:0]   utmi_status_0;

//***********************************************************************//
//  APB Interface
//***********************************************************************//
input wire               pclk;
input wire               penable;
input wire               psel;
input wire               pwrite;
input wire               presetn;
input wire       [31:0]  paddr;
input wire       [31:0]  pwdata;
output wire      [31:0]  prdata;
output wire              pready;
//***********************************************************************//
//free clock
//***********************************************************************//
output wire                 clk48m;
output wire                 clk60m;
output wire                 clk12m;

//***********************************************************************//
//DFT signals
//***********************************************************************//
input wire                  dft_clk;
input wire                  dft_reset;
input wire                  dft_mode;
input wire                  dft_se;
input wire      [12:0]      dft_si_0;
output wire     [12:0]      dft_so_0;

//***********************************************************************//
// USB PHY IO PAD
//***********************************************************************//
inout wire                  USB0PN;
inout wire                  USB0PP;
inout wire                  VCCA3P3;
inout wire                  VCCCORE;
inout wire                  VDD;
inout wire                  VSS;
inout wire                  VSSA;
inout wire                  VSSD;




`ifdef SIM
assign fss_rxdp_0 = '0;
assign fss_rxdm_0 = '0;
assign fss_rxrcv_0 = '0;
assign utmi_clk_0 = '0;
assign utmi_linestat_0 = '0;
assign utmi_rxactive_0 = '0;
assign utmi_rxvalid_l_0 = '0;
assign utmi_rxerror_0 = '0;
assign utmi_rxdata_0 = '0;
assign utmi_txready_0 = '0;
assign utmi_hostdisc_0 = '0;
assign utmi_bistdone_0 = '0;
assign utmi_status_0 = '0;
assign prdata = '0;
assign clk48m = '0;
assign clk60m = '0;
assign clk12m = '0;
assign dft_so_0 = '0;
assign pready = '1;

`endif

endmodule : inno_usb_phy
