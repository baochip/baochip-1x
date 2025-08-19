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

//  Description : Daric Global Definition used in testbench
//
/////////////////////////////////////////////////////////////////////////// 

`ifndef SIM_NETLIST
	`define ARM_UD_MODEL
	`define ARM_DISABLE_EMA_CHECK
`endif

`define AHB_PACKET 8'h80
`define AXI_WD_PACKET 8'h81
`define AXI_AR_PACKET 8'h82
`define REGISTER 8'h83
`define TXBYCNT 8'h84
`define FORLWORD 8'h85
`define FORWORD 8'h86
`define FORBYTE 8'h87
`define MEM_DATA 8'h88
`define SIO_DATA 8'h89
`define GENSTART 8'h8a
`define AXID 8'h8b
`define AXPROT 8'h8c
`define AHBPROT 8'h8d
`define RDADDR 8'h8e
`define RXBYCNT 8'h8f
`define SLAVE_START 8'h90
`define SCK_DIV 8'h91
`define WS_DIV 8'h92
`define IIS_EXT_MODE 8'h93
`define RXMODE 8'h94
`define OUT_DELAY 8'h95
`define SIO_DATA 8'h96
`define EVERBOSE 8'h97
`define FORUBYTE 8'h98
`define INTERVAL 8'h99
`define CD_TSTEN 8'h9a
`define PRT_TSTEN 8'h9b
`define SDIO_INTEN 8'h9c
`define SDIO_INTTYP 8'h9d
`define RSP_DELAY 8'h9e
`define BUSYTIME 8'h9f
`define START_BYTE 8'ha0
`define GET_SCND 8'ha1
`define OCR_SET 8'ha2
`define CSD_SET 8'ha3
`define SCR_SET 8'ha4
`define CID_SET 8'ha5
`define RCA_SET 8'ha6
`define CAR_STA 8'ha7
`define SD_STATUS 8'ha8
`define JUMP_STATE 8'ha9
`define RSPCRCERR_TEST 8'haa
`define DATCRCERR_TEST 8'hab
`define CRCSTAERR_TEST 8'hac
`define GET_WORD_DONE 8'had
`define GEN_WORD_DONE 8'hae
`define BUSY_TEST 8'haf
`define SDCLK_SET 8'hb0
`define RX_TX_EDGE 8'hb1
`define CAPTURE 8'hb2
`define MARKER 8'hb3
`define DAT_FMT 8'hb4
`define V_POL 8'hb5
`define H_POL 8'hb6
`define CLK_POL 8'hb7
`define YUV_ORDER 8'hb8
`define IMAGE_WIDTH 8'hb9
`define IMAGE_HEIGHT 8'hba
`define IMAGE_DATANUM 8'hbb
`define SERVON 8'hbc
`define IFSUB_MASK 8'hbd
`define INT_CAMIF 8'hbe
`define DONE 8'hbf
`define GET 8'hc0
`define PUT 8'hc1
`define TASK_ON 8'hc2
`define SUMMARY 8'hc3
`define MDMAEN 8'hc4
`define INT_MDMA 8'hc5
`define CORE_MASK 8'hc6
`define CONTINUE 8'hc7
`define USB_CTRL 8'hc8
`define USB_IN 8'hc9
`define USB_OUT 8'hca
`define USB_SETUPW 8'hcb
`define USB_SETUPR 8'hcc
`define USB_SOF 8'hcd


///-------------------------------------------
//
//// Macro define for SDIO Emulator and Testcases
//
////--------------------------------------------

`define RESPLEN0     3'b000
`define RESPLEN48    3'b001
`define RESPLEN48NC  3'b010
`define RESPLEN136   3'b011
`define RESPLEN48BSY 3'b100

`define CMD0         6'h00
`define CMD1         6'h01
`define CMD2         6'h02
`define CMD3         6'h03
`define CMD4         6'h04
`define CMD6         6'h06
`define CMD7         6'h07
`define CMD9         6'h09
`define CMD10        6'h0a
`define CMD11        6'h0b
`define CMD12        6'h0c
`define CMD13        6'h0d //Addressed card status (different to ACMD6)
`define CMD15        6'h0f
`define CMD16        6'h10
`define CMD17        6'h11
`define CMD18        6'h12
`define CMD20        6'h14
`define CMD24        6'h18
`define CMD25        6'h19
`define CMD26        6'h1a
`define CMD27        6'h1b
`define CMD28        6'h1c
`define CMD29        6'h1d
`define CMD30        6'h1e
`define CMD32        6'h20
`define CMD33        6'h21
`define CMD34        6'h22
`define CMD35        6'h23
`define CMD36        6'h24
`define CMD37        6'h25
`define CMD38        6'h26
`define CMD42        6'h2a  // Set password
`define CMD55        6'h37
`define CMD56        6'h38

`define ACMD6        6'h06 
`define ACMD13       6'h0d // SD_Status
`define ACMD22       6'h16
`define ACMD23       6'h17
`define ACMD41       6'h29
`define ACMD42       6'h2a //Connect pull-up resister on DAT3
`define ACMD51       6'h33

// For SDIO
`define CMD5         6'd05
`define CMD52        6'h34
`define CMD53        6'h35

