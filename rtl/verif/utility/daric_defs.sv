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

//  Description : The DARIC registers definition
//
/////////////////////////////////////////////////////////////////////////// 


`define SRAM0BASE                        32'h61000000
`define SRAM1BASE                        32'h61100000
`define IFRAM0BASE                       32'h50000000
`define IFRAM1BASE                       32'h50020000

`define QFCREGBASE                       32'h40010000
`define MDMAREGBASE                      32'h40011000
`define MDMARQREGBASE                    32'h40012000
`define SCEMEMBASE                       32'h40020000
`define SCEREGBASE                       32'h40028000
`define SDMAREGBASE                      32'h40029000
`define ALUREGBASE                       32'h4002A000
`define HASHREGBASE                      32'h4002B000
`define PKEREGBASE                       32'h4002C000
`define AESREGBASE                       32'h4002D000
`define TMGREGBASE                       32'h4002E000
`define UDMAREGBASE                      32'h50100000
`define SPIM0REGBASE                     32'h50105000
`define SPIM1REGBASE                     32'h50106000
`define SPIM2REGBASE                     32'h50107000
`define SPIM3REGBASE                     32'h50108000
`define SDIOREGBASE                      32'h5010D000
`define I2SREGBASE                       32'h5010E000
`define CAMIFREGBASE                     32'h5010F000
`define SPIS0REGBASE                     32'h50112000
`define SPIS1REGBASE                     32'h50113000
`define ADCREGBASE                       32'h50114000
`define PWMREGBASE                       32'h50120000
`define GPIOREGBASE                      32'h5012F000
`define USBDPREGBASE                     32'h50200000

// `define MDMAREGBASE                      32'h40011000
`define MDMA_STAT                     (`MDMAREGBASE + 32'h0)
`define MDMA_CFG                      (`MDMAREGBASE + 32'h4)
`define MDMA_CTRL_BASE_PTR            (`MDMAREGBASE + 32'h8)
`define MDMA_ALT_BASE_PTR             (`MDMAREGBASE + 32'hC)
`define MDMA_CH_WREQ_STAT             (`MDMAREGBASE + 32'h10)
`define MDMA_CH_SW_REQ                (`MDMAREGBASE + 32'h14)
`define MDMA_CH_REQMASK_SET           (`MDMAREGBASE + 32'h20)
`define MDMA_CH_REQMASK_CLR           (`MDMAREGBASE + 32'h24)
`define MDMA_CH_ENSET                 (`MDMAREGBASE + 32'h28)
`define MDMA_CH_ENCLR                 (`MDMAREGBASE + 32'h2C)
`define MDMA_CH_PRIALT_SET            (`MDMAREGBASE + 32'h30)
`define MDMA_CH_PRIALT_CLR            (`MDMAREGBASE + 32'h34)
`define MDMA_CH_PRIO_SET              (`MDMAREGBASE + 32'h38)
`define MDMA_CH_PRIO_CLR              (`MDMAREGBASE + 32'h3C)
`define MDMA_CH_EVSEL0                (`MDMARQREGBASE + 32'h0)
`define MDMA_CH_EVSEL1                (`MDMARQREGBASE + 32'h4)
`define MDMA_CH_EVSEL2                (`MDMARQREGBASE + 32'h8)
`define MDMA_CH_EVSEL3                (`MDMARQREGBASE + 32'hC)
`define MDMA_CH_EVSEL4                (`MDMARQREGBASE + 32'h10)
`define MDMA_CH_EVSEL5                (`MDMARQREGBASE + 32'h14)
`define MDMA_CH_EVSEL6                (`MDMARQREGBASE + 32'h18)
`define MDMA_CH_EVSEL7                (`MDMARQREGBASE + 32'h1C)
`define MDMA_CH_REQ0                  (`MDMARQREGBASE + 32'h20)
`define MDMA_CH_REQ1                  (`MDMARQREGBASE + 32'h24)
`define MDMA_CH_REQ2                  (`MDMARQREGBASE + 32'h28)
`define MDMA_CH_REQ3                  (`MDMARQREGBASE + 32'h2C)
`define MDMA_CH_REQ4                  (`MDMARQREGBASE + 32'h30)
`define MDMA_CH_REQ5                  (`MDMARQREGBASE + 32'h34)
`define MDMA_CH_REQ6                  (`MDMARQREGBASE + 32'h38)
`define MDMA_CH_REQ7                  (`MDMARQREGBASE + 32'h3C)
`define MDMA_CH_SR_REQ0               (`MDMARQREGBASE + 32'h40)
`define MDMA_CH_SR_REQ1               (`MDMARQREGBASE + 32'h44)
`define MDMA_CH_SR_REQ2               (`MDMARQREGBASE + 32'h48)
`define MDMA_CH_SR_REQ3               (`MDMARQREGBASE + 32'h4C)
`define MDMA_CH_SR_REQ4               (`MDMARQREGBASE + 32'h50)
`define MDMA_CH_SR_REQ5               (`MDMARQREGBASE + 32'h54)
`define MDMA_CH_SR_REQ6               (`MDMARQREGBASE + 32'h58)
`define MDMA_CH_SR_REQ7               (`MDMARQREGBASE + 32'h5C)


`define GPIO_AFSELAL              (`GPIOREGBASE + 32'h0)
`define GPIO_AFSELAH              (`GPIOREGBASE + 32'h4)
`define GPIO_AFSELBL              (`GPIOREGBASE + 32'h8)
`define GPIO_AFSELBH              (`GPIOREGBASE + 32'hC)
`define GPIO_AFSELCL              (`GPIOREGBASE + 32'h10)
`define GPIO_AFSELCH              (`GPIOREGBASE + 32'h14)
`define GPIO_AFSELDL              (`GPIOREGBASE + 32'h18)
`define GPIO_AFSELDH              (`GPIOREGBASE + 32'h1C)
`define GPIO_AFSELEL              (`GPIOREGBASE + 32'h20)
`define GPIO_AFSELEH              (`GPIOREGBASE + 32'h24)
`define GPIO_AFSELFL              (`GPIOREGBASE + 32'h28)
`define GPIO_AFSELFH              (`GPIOREGBASE + 32'h2C)
`define GPIO_INTCR0               (`GPIOREGBASE + 32'h100)
`define GPIO_INTCR1               (`GPIOREGBASE + 32'h104)
`define GPIO_INTCR2               (`GPIOREGBASE + 32'h108)
`define GPIO_INTCR3               (`GPIOREGBASE + 32'h10C)
`define GPIO_INTCR4               (`GPIOREGBASE + 32'h110)
`define GPIO_INTCR5               (`GPIOREGBASE + 32'h114)
`define GPIO_INTCR6               (`GPIOREGBASE + 32'h118)
`define GPIO_INTCR7               (`GPIOREGBASE + 32'h11C)
`define GPIO_INTFR                (`GPIOREGBASE + 32'h120)
`define GPIO_OUT0                 (`GPIOREGBASE + 32'h130)
`define GPIO_OUT1                 (`GPIOREGBASE + 32'h134)
`define GPIO_OUT2                 (`GPIOREGBASE + 32'h138)
`define GPIO_OUT3                 (`GPIOREGBASE + 32'h13C)
`define GPIO_OUT4                 (`GPIOREGBASE + 32'h140)
`define GPIO_OUT5                 (`GPIOREGBASE + 32'h144)
`define GPIO_OE0                  (`GPIOREGBASE + 32'h148)
`define GPIO_OE1                  (`GPIOREGBASE + 32'h14C)
`define GPIO_OE2                  (`GPIOREGBASE + 32'h150)
`define GPIO_OE3                  (`GPIOREGBASE + 32'h154)
`define GPIO_OE4                  (`GPIOREGBASE + 32'h158)
`define GPIO_OE5                  (`GPIOREGBASE + 32'h15C)
`define GPIO_PU0                  (`GPIOREGBASE + 32'h160)
`define GPIO_PU1                  (`GPIOREGBASE + 32'h164)
`define GPIO_PU2                  (`GPIOREGBASE + 32'h168)
`define GPIO_PU3                  (`GPIOREGBASE + 32'h16C)
`define GPIO_PU4                  (`GPIOREGBASE + 32'h170)
`define GPIO_PU5                  (`GPIOREGBASE + 32'h174)
`define GPIO_IN0                  (`GPIOREGBASE + 32'h178)
`define GPIO_IN1                  (`GPIOREGBASE + 32'h17C)
`define GPIO_IN2                  (`GPIOREGBASE + 32'h180)
`define GPIO_IN3                  (`GPIOREGBASE + 32'h184)
`define GPIO_IN4                  (`GPIOREGBASE + 32'h188)
`define GPIO_IN5                  (`GPIOREGBASE + 32'h18C)
`define GPIO_CFG_SHM0             (`GPIOREGBASE + 32'h230)
`define GPIO_CFG_SHM1             (`GPIOREGBASE + 32'h234)
`define GPIO_CFG_SHM2             (`GPIOREGBASE + 32'h238)
`define GPIO_CFG_SHM3             (`GPIOREGBASE + 32'h23C)
`define GPIO_CFG_SHM4             (`GPIOREGBASE + 32'h240)
`define GPIO_CFG_SHM5             (`GPIOREGBASE + 32'h244)
`define GPIO_CFG_RATE0            (`GPIOREGBASE + 32'h248)
`define GPIO_CFG_RATE1            (`GPIOREGBASE + 32'h24C)
`define GPIO_CFG_RATE2            (`GPIOREGBASE + 32'h250)
`define GPIO_CFG_RATE3            (`GPIOREGBASE + 32'h254)
`define GPIO_CFG_RATE4            (`GPIOREGBASE + 32'h258)
`define GPIO_CFG_RATE5            (`GPIOREGBASE + 32'h25C)
`define GPIO_CFG_DRVSEL0          (`GPIOREGBASE + 32'h260)
`define GPIO_CFG_DRVSEL1          (`GPIOREGBASE + 32'h264)
`define GPIO_CFG_DRVSEL2          (`GPIOREGBASE + 32'h268)
`define GPIO_CFG_DRVSEL3          (`GPIOREGBASE + 32'h26C)
`define GPIO_CFG_DRVSEL4          (`GPIOREGBASE + 32'h270)
`define GPIO_CFG_DRVSEL5          (`GPIOREGBASE + 32'h274)

`define USB_CAPABILITY                        (`USBDPREGBASE + 32'h2400)
`define USB_CONFIG_0                          (`USBDPREGBASE + 32'h2410)
`define USB_CONFIG_1                          (`USBDPREGBASE + 32'h2414)
`define USB_CONTROL                           (`USBDPREGBASE + 32'h2420)
`define USB_STATUS                            (`USBDPREGBASE + 32'h2424)
`define USB_DCBAPLO                           (`USBDPREGBASE + 32'h2428)
`define USB_DCBAPHI                           (`USBDPREGBASE + 32'h242C)
`define USB_PORTSC                            (`USBDPREGBASE + 32'h2430)
`define USB_U3PORTPMSC                        (`USBDPREGBASE + 32'h2434)
`define USB_U2PORTPMSC                        (`USBDPREGBASE + 32'h2438)
`define USB_U3PORTLI                          (`USBDPREGBASE + 32'h243C)
`define USB_DOORBELL                          (`USBDPREGBASE + 32'h2440)
`define USB_MFINDEX                           (`USBDPREGBASE + 32'h2444)
`define USB_PTM_CONTROL                       (`USBDPREGBASE + 32'h2448)
`define USB_PTM_STATUS                        (`USBDPREGBASE + 32'h244C)
`define USB_EP_ENABLED                        (`USBDPREGBASE + 32'h2460)
`define USB_EP_RUNNING                        (`USBDPREGBASE + 32'h2464)
`define USB_COMMAND_PARAMETER_0               (`USBDPREGBASE + 32'h2470)
`define USB_COMMAND_PARAMETER_1               (`USBDPREGBASE + 32'h2474)
`define USB_COMMAND_CONTROL                   (`USBDPREGBASE + 32'h2478)
`define USB_ODB_CAPABILITY                    (`USBDPREGBASE + 32'h2480)
`define USB_DEBUG_0                           (`USBDPREGBASE + 32'h24B0)
`define USB_STREAM_INFO                       (`USBDPREGBASE + 32'h24B4)
`define USB_ODB_CONFIG_EP01                   (`USBDPREGBASE + 32'h2490)
`define USB_ODB_CONFIG_EP23                   (`USBDPREGBASE + 32'h2494)
`define USB_ODB_CONFIG_EP45                   (`USBDPREGBASE + 32'h2498)
`define USB_ODB_CONFIG_EP67                   (`USBDPREGBASE + 32'h249C)
`define USB_IRS_IMAN_0                        (`USBDPREGBASE + 32'h2500)
`define USB_IRS_IMOD_0                        (`USBDPREGBASE + 32'h2504)
`define USB_IRS_ERSTSZ_0                      (`USBDPREGBASE + 32'h2508)
`define USB_IRS_ERSTBALO_0                    (`USBDPREGBASE + 32'h2510)
`define USB_IRS_ERSTBAHI_0                    (`USBDPREGBASE + 32'h2514)
`define USB_IRS_ERDPLO_0                      (`USBDPREGBASE + 32'h2518)
`define USB_IRS_ERDPHI_0                      (`USBDPREGBASE + 32'h251C)
`define USB_IRS_IMAN_1                        (`USBDPREGBASE + 32'h2520)
`define USB_IRS_IMOD_1                        (`USBDPREGBASE + 32'h2524)
`define USB_IRS_ERSTSZ_1                      (`USBDPREGBASE + 32'h2528)
`define USB_IRS_ERSTBALO_1                    (`USBDPREGBASE + 32'h2530)
`define USB_IRS_ERSTBAHI_1                    (`USBDPREGBASE + 32'h2534)
`define USB_IRS_ERDPLO_1                      (`USBDPREGBASE + 32'h2538)
`define USB_IRS_ERDPHI_1                      (`USBDPREGBASE + 32'h253C)
`define USB_IRS_IMAN_2                        (`USBDPREGBASE + 32'h2540)
`define USB_IRS_IMOD_2                        (`USBDPREGBASE + 32'h2544)
`define USB_IRS_ERSTSZ_2                      (`USBDPREGBASE + 32'h2548)
`define USB_IRS_ERSTBALO_2                    (`USBDPREGBASE + 32'h2550)
`define USB_IRS_ERSTBAHI_2                    (`USBDPREGBASE + 32'h2554)
`define USB_IRS_ERDPLO_2                      (`USBDPREGBASE + 32'h2558)
`define USB_IRS_ERDPHI_2                      (`USBDPREGBASE + 32'h255C)
`define USB_IRS_IMAN_3                        (`USBDPREGBASE + 32'h2560)
`define USB_IRS_IMOD_3                        (`USBDPREGBASE + 32'h2564)
`define USB_IRS_ERSTSZ_3                      (`USBDPREGBASE + 32'h2568)
`define USB_IRS_ERSTBALO_3                    (`USBDPREGBASE + 32'h2570)
`define USB_IRS_ERSTBAHI_3                    (`USBDPREGBASE + 32'h2574)
`define USB_IRS_ERDPLO_3                      (`USBDPREGBASE + 32'h2578)
`define USB_IRS_ERDPHI_3                      (`USBDPREGBASE + 32'h257C)

`define UDMACTRL_CFG_CG            (`UDMAREGBASE + 32'h0)
`define UDMACTRL_CFG_EVENT         (`UDMAREGBASE + 32'h4)
`define UDMACTRL_CFG_RST           (`UDMAREGBASE + 32'h8)
`define SDIO_RX_SADDR              (`SDIOREGBASE + 32'h0)
`define SDIO_RX_SIZE               (`SDIOREGBASE + 32'h4)
`define SDIO_RX_CFG                (`SDIOREGBASE + 32'h8)
`define SDIO_TX_SADDR              (`SDIOREGBASE + 32'h10)
`define SDIO_TX_SIZE               (`SDIOREGBASE + 32'h14)
`define SDIO_TX_CFG                (`SDIOREGBASE + 32'h18)
`define SDIO_CMD_OP                (`SDIOREGBASE + 32'h20)
`define SDIO_CMD_ARG               (`SDIOREGBASE + 32'h24)
`define SDIO_DATA_SETUP            (`SDIOREGBASE + 32'h28)
`define SDIO_START                 (`SDIOREGBASE + 32'h2C)
`define SDIO_RSP0                  (`SDIOREGBASE + 32'h30)
`define SDIO_RSP1                  (`SDIOREGBASE + 32'h34)
`define SDIO_RSP2                  (`SDIOREGBASE + 32'h38)
`define SDIO_RSP3                  (`SDIOREGBASE + 32'h3C)
`define SDIO_CLK_DIV               (`SDIOREGBASE + 32'h40)
`define SDIO_STATUS                (`SDIOREGBASE + 32'h44)
`define SDIO_TIMEOUT               (`SDIOREGBASE + 32'h48)
`define I2S_RX_SADDR               (`I2SREGBASE + 32'h0)
`define I2S_RX_SIZE                (`I2SREGBASE + 32'h4)
`define I2S_RX_CFG                 (`I2SREGBASE + 32'h8)
`define I2S_TX_SADDR               (`I2SREGBASE + 32'h10)
`define I2S_TX_SIZE                (`I2SREGBASE + 32'h14)
`define I2S_TX_CFG                 (`I2SREGBASE + 32'h18)
`define I2S_CLKCFG_SETUP           (`I2SREGBASE + 32'h20)
`define I2S_SLV_SETUP              (`I2SREGBASE + 32'h24)
`define I2S_MST_SETUP              (`I2SREGBASE + 32'h28)
`define I2S_PDM_SETUP              (`I2SREGBASE + 32'h2C)
`define CAM_RX_SADDR               (`CAMIFREGBASE + 32'h0)
`define CAM_RX_SIZE                (`CAMIFREGBASE + 32'h4)
`define CAM_RX_CFG                 (`CAMIFREGBASE + 32'h8)
`define CAM_CFG_GLOB               (`CAMIFREGBASE + 32'h20)
`define CAM_CFG_LL                 (`CAMIFREGBASE + 32'h24)
`define CAM_CFG_UR                 (`CAMIFREGBASE + 32'h28)
`define CAM_CFG_SIZE               (`CAMIFREGBASE + 32'h2C)
`define CAM_CFG_FILTER             (`CAMIFREGBASE + 32'h30)
`define CAM_VSYNC_POLARITY         (`CAMIFREGBASE + 32'h34)


// SCE Memory Region Definition
`define SCE_SEG_LKEY                     (`SCEMEMBASE + 32'h000)
`define SCE_SEG_KEY                      (`SCEMEMBASE + 32'h100)
`define SCE_SEG_SKEY                     (`SCEMEMBASE + 32'h200)
`define SCE_SEG_SCRT                     (`SCEMEMBASE + 32'h300)
`define SCE_SEG_MSG                      (`SCEMEMBASE + 32'h400)
`define SCE_SEG_HOUT                     (`SCEMEMBASE + 32'h600)
`define SCE_SEG_SOB                      (`SCEMEMBASE + 32'h700)
`define SCE_SEG_PCON                     (`SCEMEMBASE + 32'h800)
`define SCE_SEG_PKB                      (`SCEMEMBASE + 32'h800)
`define SCE_SEG_PIB                      (`SCEMEMBASE + 32'hC00)
`define SCE_SEG_PSIB                     (`SCEMEMBASE + 32'h1000)
`define SCE_SEG_POB                      (`SCEMEMBASE + 32'h1400)
`define SCE_SEG_PSOB                     (`SCEMEMBASE + 32'h1800)
`define SCE_SEG_AKEY                     (`SCEMEMBASE + 32'h1C00)
`define SCE_SEG_AIB                      (`SCEMEMBASE + 32'h1D00)
`define SCE_SEG_AOB                      (`SCEMEMBASE + 32'h1E00)
`define SCE_SEG_RNGA                     (`SCEMEMBASE + 32'h1F00)
`define SCE_SEG_RNGB                     (`SCEMEMBASE + 32'h2300)

// QFC
`define QFC_SFR_IO                       (`QFCREGBASE + 32'h0 )
`define QFC_SFR_AR                       (`QFCREGBASE + 32'h4 )
`define QFC_SFR_IODRV                    (`QFCREGBASE + 32'h8 )
`define QFC_CR_XIP_ADDRMODE              (`QFCREGBASE + 32'h10)
`define QFC_CR_XIP_OPCODE                (`QFCREGBASE + 32'h14)
`define QFC_CR_XIP_WIDTH                 (`QFCREGBASE + 32'h18)
`define QFC_CR_XIP_SSEL                  (`QFCREGBASE + 32'h1C)
`define QFC_CR_XIP_DUMCYC                (`QFCREGBASE + 32'h20)
`define QFC_CR_XIP_CFG                   (`QFCREGBASE + 32'h24)
`define QFC_CONTROL                      (`QFCREGBASE + 32'h0200)
`define QFC_CMD_CONTROL                  (`QFCREGBASE + 32'h0204)
`define QFC_FIFO_FLUSH                   (`QFCREGBASE + 32'h0208)
`define QFC_FIFO_THRESHOLD               (`QFCREGBASE + 32'h020C)
`define QFC_DATA_FIFO_STAT               (`QFCREGBASE + 32'h0210)
`define QFC_CMD_FIFO_STAT                (`QFCREGBASE + 32'h0214)
`define QFC_IRQ_ENABLE                   (`QFCREGBASE + 32'h0218)
`define QFC_IRQ_STAT                     (`QFCREGBASE + 32'h021C)
`define QFC_IRQ_ENABLE2                  (`QFCREGBASE + 32'h0220)
`define QFC_IRQ_STAT2                    (`QFCREGBASE + 32'h0224)
`define QFC_TX_FIFO                      (`QFCREGBASE + 32'h0228)
`define QFC_RX_FIFO                      (`QFCREGBASE + 32'h022C)
`define QFC_CMD_FIFO                     (`QFCREGBASE + 32'h0230)

// SCE
`define SCE_SCEMODE                  (`SCEREGBASE + 32'h0)                             
`define SCE_SUBEN                    (`SCEREGBASE + 32'h4)
`define SCE_AHBSOPT                  (`SCEREGBASE + 32'h8)
`define SCE_SRBUSY                   (`SCEREGBASE + 32'h10)
`define SCE_FRDONE                   (`SCEREGBASE + 32'h14)
`define SCE_FRERR                    (`SCEREGBASE + 32'h18)
`define SCE_SCE_AR                   (`SCEREGBASE + 32'h1C)
`define SCE_TICKCYC                  (`SCEREGBASE + 32'h20)
`define SCE_TICKCNT                  (`SCEREGBASE + 32'h24)
`define SCE_FFEN                     (`SCEREGBASE + 32'h30)
`define SCE_FFCLR                    (`SCEREGBASE + 32'h34)
`define SCE_FFCNT0                   (`SCEREGBASE + 32'h40)
`define SCE_FFCNT1                   (`SCEREGBASE + 32'h44)
`define SCE_FFCNT2                   (`SCEREGBASE + 32'h48)
`define SCE_FFCNT3                   (`SCEREGBASE + 32'h4C)
`define SCE_FFCNT4                   (`SCEREGBASE + 32'h50)
`define SCE_FFCNT5                   (`SCEREGBASE + 32'h54)
`define SCE_FRACERR                  (`SCEREGBASE + 32'h60)
`define SCE_TS                       (`SCEREGBASE + 32'hFC)

// SDMA
`define SDMA_CHSTART_AR              (`SDMAREGBASE + 32'h0)
`define SDMA_XCHCR_FUNC              (`SDMAREGBASE + 32'h10)
`define SDMA_XCHCR_OPT               (`SDMAREGBASE + 32'h14)
`define SDMA_XCHCR_AXSTART           (`SDMAREGBASE + 32'h18)
`define SDMA_XCHCR_SEGID             (`SDMAREGBASE + 32'h1C)
`define SDMA_XCHCR_SEGSTART          (`SDMAREGBASE + 32'h20)
`define SDMA_XCHCR_TRANSIZE          (`SDMAREGBASE + 32'h24)
`define SDMA_SCHCR_FUNC              (`SDMAREGBASE + 32'h30)
`define SDMA_SCHCR_OPT               (`SDMAREGBASE + 32'h34)
`define SDMA_SCHCR_AXSTART           (`SDMAREGBASE + 32'h38)
`define SDMA_SCHCR_SEGID             (`SDMAREGBASE + 32'h3C)
`define SDMA_SCHCR_SEGSTART          (`SDMAREGBASE + 32'h40)
`define SDMA_SCHCR_TRANSIZE          (`SDMAREGBASE + 32'h44)
`define SDMA_ICHCR_OPT               (`SDMAREGBASE + 32'h50)
`define SDMA_ICHCR_SEGID             (`SDMAREGBASE + 32'h54)
`define SDMA_ICHCR_RPSTART           (`SDMAREGBASE + 32'h58)
`define SDMA_ICHCR_WPSTART           (`SDMAREGBASE + 32'h5C)
`define SDMA_ICHCR_TRANSIZE          (`SDMAREGBASE + 32'h60)

// ALU
`define ALU_CRFUNC                   (`ALUREGBASE + 32'h0)
`define ALU_AR                       (`ALUREGBASE + 32'h4)
`define ALU_SRMFSM                   (`ALUREGBASE + 32'h8)
`define ALU_FR                       (`ALUREGBASE + 32'hC)
`define ALU_CRDIVLEN                 (`ALUREGBASE + 32'h10)
`define ALU_SRDIVLEN                 (`ALUREGBASE + 32'h14)
`define ALU_OPT                      (`ALUREGBASE + 32'h18)
`define ALU_OPTLTX                   (`ALUREGBASE + 32'h1C)
`define ALU_SEGPTR_DE_A              (`ALUREGBASE + 32'h30)
`define ALU_SEGPTR_DS_B              (`ALUREGBASE + 32'h34)
`define ALU_SEGPTR_QT_RESULT         (`ALUREGBASE + 32'h38)
`define ALU_SEGPTR_RM                (`ALUREGBASE + 32'h3C)

// HASH
`define HASH_CRFUNC                  (`HASHREGBASE + 32'h0)
`define HASH_AR                      (`HASHREGBASE + 32'h4)
`define HASH_SRMFSM                  (`HASHREGBASE + 32'h8)
`define HASH_FR                      (`HASHREGBASE + 32'hC)
`define HASH_OPT1                    (`HASHREGBASE + 32'h10)
`define HASH_OPT2                    (`HASHREGBASE + 32'h14)
`define HASH_OPT3                    (`HASHREGBASE + 32'h18)
`define HASH_CFG_BLKT0               (`HASHREGBASE + 32'h1C)
`define HASH_SEGPTR_LKEY             (`HASHREGBASE + 32'h20)
`define HASH_SEGPTR_KEY              (`HASHREGBASE + 32'h24)
`define HASH_SEGPTR_SKEY             (`HASHREGBASE + 32'h28)
`define HASH_SEGPTR_SCRT             (`HASHREGBASE + 32'h2C)
`define HASH_SEGPTR_MSG              (`HASHREGBASE + 32'h30)
`define HASH_SEGPTR_HOUT             (`HASHREGBASE + 32'h34)
`define HASH_SEGPTR_SOB              (`HASHREGBASE + 32'h38)
`define HASH_SEGPTR_HASH_RESULT      (`HASHREGBASE + 32'h3C)


// PKE
`define PKE_CRFUNC                   (`PKEREGBASE + 32'h0)
`define PKE_AR                       (`PKEREGBASE + 32'h4)
`define PKE_SR                       (`PKEREGBASE + 32'h8)
`define PKE_FR                       (`PKEREGBASE + 32'hC)
`define PKE_OPTNW                    (`PKEREGBASE + 32'h10)
`define PKE_OPTEW                    (`PKEREGBASE + 32'h14)
`define PKE_OPTRW                    (`PKEREGBASE + 32'h18)
`define PKE_OPTLTX                   (`PKEREGBASE + 32'h1C)
`define PKE_OPTMASK                  (`PKEREGBASE + 32'h20)
`define PKE_MIMMCR                   (`PKEREGBASE + 32'h24)
`define PKE_SEGPTR_PCON              (`PKEREGBASE + 32'h30)
`define PKE_SEGPTR_PIB0              (`PKEREGBASE + 32'h34)
`define PKE_SEGPTR_PIB1              (`PKEREGBASE + 32'h38)
`define PKE_SEGPTR_PKB               (`PKEREGBASE + 32'h3C)
`define PKE_SEGPTR_POB               (`PKEREGBASE + 32'h40)


// AES
`define AES_CRFUNC                   (`AESREGBASE + 32'h0)
`define AES_AR                       (`AESREGBASE + 32'h4)
`define AES_SRMFSM                   (`AESREGBASE + 32'h8)
`define AES_FR                       (`AESREGBASE + 32'hC)
`define AES_OPT                      (`AESREGBASE + 32'h10)
`define AES_OPT1                     (`AESREGBASE + 32'h14)
`define AES_OPTLTX                   (`AESREGBASE + 32'h18)
`define AES_SEGPTR_IV                (`AESREGBASE + 32'h30)
`define AES_SEGPTR_AKEY              (`AESREGBASE + 32'h34)
`define AES_SEGPTR_AIB               (`AESREGBASE + 32'h38)
`define AES_SEGPTR_AOB               (`AESREGBASE + 32'h3C)
`define AES_MASKSEED                 (`AESREGBASE + 32'h20)
`define AES_MASKSEEDAR               (`AESREGBASE + 32'h24)


// TMG
`define TMG_CRSRC                    (`TMGREGBASE + 32'h0)
`define TMG_CRANA                    (`TMGREGBASE + 32'h4)
`define TMG_POSTPROC                 (`TMGREGBASE + 32'h8)
`define TMG_OPT                      (`TMGREGBASE + 32'hC)
`define TMG_SR                       (`TMGREGBASE + 32'h10)
`define TMG_AR                       (`TMGREGBASE + 32'h14)
`define TMG_FR                       (`TMGREGBASE + 32'h18)
`define TMG_DRPSZ                    (`TMGREGBASE + 32'h20)
`define TMG_DRGEN                    (`TMGREGBASE + 32'h24)
`define TMG_DRRESEED                 (`TMGREGBASE + 32'h28)
`define TMG_BUF                      (`TMGREGBASE + 32'h30)
`define TMG_CHAIN0                   (`TMGREGBASE + 32'h40)
`define TMG_CHAIN1                   (`TMGREGBASE + 32'h44)                            

// SPIS0
`define SPIS0_RX_SADDR               (`SPIS0REGBASE + 32'h0)
`define SPIS0_RX_SIZE                (`SPIS0REGBASE + 32'h4)
`define SPIS0_RX_CFG                 (`SPIS0REGBASE + 32'h8)
`define SPIS0_TX_SADDR               (`SPIS0REGBASE + 32'h10)
`define SPIS0_TX_SIZE                (`SPIS0REGBASE + 32'h14)
`define SPIS0_TX_CFG                 (`SPIS0REGBASE + 32'h18)
`define SPIS0_SETUP                  (`SPIS0REGBASE + 32'h20)
`define SPIS0_EOT_CNT                (`SPIS0REGBASE + 32'h24)
`define SPIS0_IRQ_EN                 (`SPIS0REGBASE + 32'h28)
`define SPIS0_RXCNT                  (`SPIS0REGBASE + 32'h2C)
`define SPIS0_TXCNT                  (`SPIS0REGBASE + 32'h30)
`define SPIS0_DMCNT                  (`SPIS0REGBASE + 32'h34)

// SPIS1
`define SPIS1_RX_SADDR               (`SPIS1REGBASE + 32'h0)
`define SPIS1_RX_SIZE                (`SPIS1REGBASE + 32'h4)
`define SPIS1_RX_CFG                 (`SPIS1REGBASE + 32'h8)
`define SPIS1_TX_SADDR               (`SPIS1REGBASE + 32'h10)
`define SPIS1_TX_SIZE                (`SPIS1REGBASE + 32'h14)
`define SPIS1_TX_CFG                 (`SPIS1REGBASE + 32'h18)
`define SPIS1_SETUP                  (`SPIS1REGBASE + 32'h20)
`define SPIS1_EOT_CNT                (`SPIS1REGBASE + 32'h24)
`define SPIS1_IRQ_EN                 (`SPIS1REGBASE + 32'h28)
`define SPIS1_RXCNT                  (`SPIS1REGBASE + 32'h2C)
`define SPIS1_TXCNT                  (`SPIS1REGBASE + 32'h30)
`define SPIS1_DMCNT                  (`SPIS1REGBASE + 32'h34)

// SPIM0
`define SPIM0_RX_SADDR               (`SPIM0REGBASE + 32'h0)
`define SPIM0_RX_SIZE                (`SPIM0REGBASE + 32'h4)
`define SPIM0_RX_CFG                 (`SPIM0REGBASE + 32'h8)
`define SPIM0_TX_SADDR               (`SPIM0REGBASE + 32'h10)
`define SPIM0_TX_SIZE                (`SPIM0REGBASE + 32'h14)
`define SPIM0_TX_CFG                 (`SPIM0REGBASE + 32'h18)
`define SPIM0_CMD_SADDR              (`SPIM0REGBASE + 32'h20)
`define SPIM0_CMD_SIZE               (`SPIM0REGBASE + 32'h24)
`define SPIM0_CMD_CFG                (`SPIM0REGBASE + 32'h28)

// SPIM1
`define SPIM1_RX_SADDR               (`SPIM1REGBASE + 32'h0)
`define SPIM1_RX_SIZE                (`SPIM1REGBASE + 32'h4)
`define SPIM1_RX_CFG                 (`SPIM1REGBASE + 32'h8)
`define SPIM1_TX_SADDR               (`SPIM1REGBASE + 32'h10)
`define SPIM1_TX_SIZE                (`SPIM1REGBASE + 32'h14)
`define SPIM1_TX_CFG                 (`SPIM1REGBASE + 32'h18)
`define SPIM1_CMD_SADDR              (`SPIM1REGBASE + 32'h20)
`define SPIM1_CMD_SIZE               (`SPIM1REGBASE + 32'h24)
`define SPIM1_CMD_CFG                (`SPIM1REGBASE + 32'h28)

// SPIM2
`define SPIM2_RX_SADDR               (`SPIM2REGBASE + 32'h0)
`define SPIM2_RX_SIZE                (`SPIM2REGBASE + 32'h4)
`define SPIM2_RX_CFG                 (`SPIM2REGBASE + 32'h8)
`define SPIM2_TX_SADDR               (`SPIM2REGBASE + 32'h10)
`define SPIM2_TX_SIZE                (`SPIM2REGBASE + 32'h14)
`define SPIM2_TX_CFG                 (`SPIM2REGBASE + 32'h18)
`define SPIM2_CMD_SADDR              (`SPIM2REGBASE + 32'h20)
`define SPIM2_CMD_SIZE               (`SPIM2REGBASE + 32'h24)
`define SPIM2_CMD_CFG                (`SPIM2REGBASE + 32'h28)

// SPIM3
`define SPIM3_RX_SADDR               (`SPIM3REGBASE + 32'h0)
`define SPIM3_RX_SIZE                (`SPIM3REGBASE + 32'h4)
`define SPIM3_RX_CFG                 (`SPIM3REGBASE + 32'h8)
`define SPIM3_TX_SADDR               (`SPIM3REGBASE + 32'h10)
`define SPIM3_TX_SIZE                (`SPIM3REGBASE + 32'h14)
`define SPIM3_TX_CFG                 (`SPIM3REGBASE + 32'h18)
`define SPIM3_CMD_SADDR              (`SPIM3REGBASE + 32'h20)
`define SPIM3_CMD_SIZE               (`SPIM3REGBASE + 32'h24)
`define SPIM3_CMD_CFG                (`SPIM3REGBASE + 32'h28)

//`define ADCREGBASE                       32'h50114000
// ADC
`define ADC_RX_SADDR                 (`ADCREGBASE + 32'h0)
`define ADC_RX_SIZE                  (`ADCREGBASE + 32'h4)
`define ADC_RX_CFG                   (`ADCREGBASE + 32'h8)
`define ADC_CR_CFG                   (`ADCREGBASE + 32'h10)

//`define PWMREGBASE                       32'h50120000
// PWM
`define PWM_T0_CMD                   (`PWMREGBASE + 32'h0000)
`define PWM_T0_CONFIG                (`PWMREGBASE + 32'h0004)
`define PWM_T0_THRESHOLD             (`PWMREGBASE + 32'h0008)
`define PWM_T0_TH_CHANNEL0           (`PWMREGBASE + 32'h000c)
`define PWM_T0_TH_CHANNEL1           (`PWMREGBASE + 32'h0010)
`define PWM_T0_TH_CHANNEL2           (`PWMREGBASE + 32'h0014)
`define PWM_T0_TH_CHANNEL3           (`PWMREGBASE + 32'h0018)
`define PWM_T1_CMD                   (`PWMREGBASE + 32'h0040)
`define PWM_T1_CONFIG                (`PWMREGBASE + 32'h0044)
`define PWM_T1_THRESHOLD             (`PWMREGBASE + 32'h0048)
`define PWM_T1_TH_CHANNEL0           (`PWMREGBASE + 32'h004c)
`define PWM_T1_TH_CHANNEL1           (`PWMREGBASE + 32'h0050)
`define PWM_T1_TH_CHANNEL2           (`PWMREGBASE + 32'h0054)
`define PWM_T1_TH_CHANNEL3           (`PWMREGBASE + 32'h0058)
`define PWM_T2_CMD                   (`PWMREGBASE + 32'h0080)
`define PWM_T2_CONFIG                (`PWMREGBASE + 32'h0084)
`define PWM_T2_THRESHOLD             (`PWMREGBASE + 32'h0088)
`define PWM_T2_TH_CHANNEL0           (`PWMREGBASE + 32'h008c)
`define PWM_T2_TH_CHANNEL1           (`PWMREGBASE + 32'h0090)
`define PWM_T2_TH_CHANNEL2           (`PWMREGBASE + 32'h0094)
`define PWM_T2_TH_CHANNEL3           (`PWMREGBASE + 32'h0098)
`define PWM_T3_CMD                   (`PWMREGBASE + 32'h00c0)
`define PWM_T3_CONFIG                (`PWMREGBASE + 32'h00c4)
`define PWM_T3_THRESHOLD             (`PWMREGBASE + 32'h00c8)
`define PWM_T3_TH_CHANNEL0           (`PWMREGBASE + 32'h00cc)
`define PWM_T3_TH_CHANNEL1           (`PWMREGBASE + 32'h00d0)
`define PWM_T3_TH_CHANNEL2           (`PWMREGBASE + 32'h00d4)
`define PWM_T3_TH_CHANNEL3           (`PWMREGBASE + 32'h00d8)
`define PWM_CG                       (`PWMREGBASE + 32'h0104)
`define PWM_T0_PREFD                 (`PWMREGBASE + 32'h0140)
`define PWM_T1_PREFD                 (`PWMREGBASE + 32'h0144)
`define PWM_T2_PREFD                 (`PWMREGBASE + 32'h0148)
`define PWM_T3_PREFD                 (`PWMREGBASE + 32'h014c)

// coresub interrupt events --- bit[31:0] --- 32bits
`define CORE_QFCIRQ_EVENT            32'h00010000
`define CORE_MDMA_EVENT              32'h00020000


// ifsub interrupt events --- bit[191:64] --- 128bits
`define UDMA_UART0_EVENT             128'h0000000000000000000000000000000F
`define UDMA_UART1_EVENT             128'h000000000000000000000000000000F0
`define UDMA_UART2_EVENT             128'h00000000000000000000000000000F00
`define UDMA_UART3_EVENT             128'h0000000000000000000000000000F000
`define UDMA_SPIM0_EVENT             128'h000000000000000000000000000F0000
`define UDMA_SPIM1_EVENT             128'h00000000000000000000000000F00000
`define UDMA_SPIM2_EVENT             128'h0000000000000000000000000F000000
`define UDMA_SPIM3_EVENT             128'h000000000000000000000000F0000000
`define UDMA_I2C0_EVENT              128'h00000000000000000000000F00000000
`define UDMA_I2C1_EVENT              128'h0000000000000000000000F000000000
`define UDMA_I2C2_EVENT              128'h000000000000000000000F0000000000
`define UDMA_I2C3_EVENT              128'h00000000000000000000F00000000000
`define UDMA_SDIO_EVENT              128'h0000000000000000000F000000000000
`define UDMA_I2S_EVENT               128'h000000000000000000F0000000000000
`define UDMA_CAMIF_EVENT             128'h00000000000000000100000000000000
`define UDMA_ADC_EVENT               128'h00000000000000000200000000000000
`define UDMA_FLTR_EVENT              128'h0000000000000000F000000000000000
`define UDMA_SCIF_EVENT              128'h000000000000000F0000000000000000
`define UDMA_SPIS0_EVENT             128'h00000000000000F00000000000000000
`define UDMA_SPIS1_EVENT             128'h0000000000000F000000000000000000
`define UDMA_PWM_EVENT               128'h000000000000F0000000000000000000
`define UDMA_GPIO_EVENT              128'h00000000000100000000000000000000
`define UDMA_USB_EVENT               128'h00000000000200000000000000000000
