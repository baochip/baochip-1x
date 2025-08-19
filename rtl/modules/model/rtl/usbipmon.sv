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

module inno_usb_phy_mon(/*autoarg*/
   // input s
   fss_rxdp_0, fss_rxdm_0, fss_rxrcv_0, utmi_clk_0, utmi_linestat_0,
   utmi_rxactive_0, utmi_rxvalid_l_0, utmi_rxerror_0, utmi_rxdata_0,
   utmi_txready_0, utmi_hostdisc_0, utmi_bistdone_0, utmi_status_0,
   prdata, pready, clk48m, clk60m, clk12m, dft_so_0,
   // inputs
   USB0PN, USB0PP, VCCA3P3, VCCCORE, VDD, VSS, VSSA, VSSD,
   // Inputs
   utmi_refclk, POR_reset, fss_serialmode_0, fss_txenablez_0,
   fss_txdata_0, fss_txsezero_0, utmi_reset_0, utmi_txvalid_l_0,
   utmi_txdata_0, utmi_xcvrselect_0, utmi_termselect_0, utmi_opmode_0,
   utmi_suspendm_0, utmi_dppulldown_0, utmi_dmpulldown_0,
   utmi_biston_0, utmi_testcontrol_0, pclk, penable, psel, pwrite,
   presetn, paddr, pwdata, dft_clk, dft_reset, dft_mode, dft_se,
   dft_si_0
   );
//***********************************************************************//
// USB pll refrence clock 48MHz
//***********************************************************************//
input           utmi_refclk;
//***********************************************************************//
// USB Power-on reset
//***********************************************************************//
input           POR_reset;
//***********************************************************************//
//  7-Wire Interface
//***********************************************************************//
input           fss_serialmode_0;
input           fss_txenablez_0;
input           fss_txdata_0;
input           fss_txsezero_0;
input           fss_rxdp_0;
input           fss_rxdm_0;
input           fss_rxrcv_0;

//***********************************************************************//
// UTMI interface for port0
//***********************************************************************//
input           utmi_reset_0;
input           utmi_clk_0;
input   [1:0]   utmi_linestat_0;
input           utmi_rxactive_0;
input           utmi_rxvalid_l_0;
input           utmi_rxerror_0;
input   [7:0]   utmi_rxdata_0;
input           utmi_txready_0;
input           utmi_hostdisc_0;
input           utmi_txvalid_l_0;
input   [7:0]   utmi_txdata_0;
input   [1:0]   utmi_xcvrselect_0;
input           utmi_termselect_0;
input   [1:0]   utmi_opmode_0;
input           utmi_suspendm_0;
input           utmi_dppulldown_0;
input           utmi_dmpulldown_0;

//***********************************************************************//
//  Bist Test Interface for port0
//***********************************************************************//
input           utmi_biston_0;
input   [1:0]   utmi_testcontrol_0;
input           utmi_bistdone_0;
input   [1:0]   utmi_status_0;

//***********************************************************************//
//  APB Interface
//***********************************************************************//
input                pclk;
input                penable;
input                psel;
input                pwrite;
input                presetn;
input        [31:0]  paddr;
input        [31:0]  pwdata;
input        [31:0]  prdata;
input                pready;
//***********************************************************************//
//free clock
//***********************************************************************//
input                   clk48m;
input                   clk60m;
input                   clk12m;

//***********************************************************************//
//DFT signals
//***********************************************************************//
input                   dft_clk;
input                   dft_reset;
input                   dft_mode;
input                   dft_se;
input       [12:0]      dft_si_0;
input       [12:0]      dft_so_0;

//***********************************************************************//
// USB PHY IO PAD
//***********************************************************************//
input                   USB0PN;
input                   USB0PP;
input                   VCCA3P3;
input                   VCCCORE;
input                   VDD;
input                   VSS;
input                   VSSA;
input                   VSSD;

endmodule


