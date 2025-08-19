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

`timescale 1 ns/1 ps
`ifndef TIMEOUT
	`define TIMEOUT 50000
`endif
`ifndef VERBOSE
	`define VERBOSE 8'h0
`endif
`ifdef SIM_UPF
    import UPF::*;
`endif

// ======================
// tb index
// ======================

module daric_top_tb ();

    import tb_util_pkg::*;
    import axi_tb_pkg::*;
    import ahb_tb_pkg::*;

    integer i=0, j=0, k=0, errcnt=0, warncnt=0;

    bit         clk,resetn;
    bit         clk1m;
    bit [31:0]  syscnt;
    bit         sim_stop;
    bit [0:2]   cmspad;
    bit         padresetn;
    bit         clkswd;
    bit         dbgtxd;
    wire        PA0wire;
    wire        PA1wire;
    wire        PA2wire;
    wire        PA3wire;
    wire        PA4wire;
    wire        PA5wire;
    wire        PA6wire;
    wire        PA7wire;
    wire        PB11;
    wire        PB12;
    wire        PB13;
    wire        PB0wire;
    wire        PB1wire;
    wire        PB2wire;
    wire        PB3wire;
    wire        PB4wire;
    wire        PB5wire;
    wire        PB6wire;
    wire        PB7wire;
    wire        PB8wire;
    wire        PB9wire;
    wire        PB10wire;
    wire        PB11wire;
    wire        PB12wire;
    wire        PB13wire;
    wire        PB14wire;
    wire        PB15wire;

    wire        PC0wire;
    wire        PC1wire;
    wire        PC2wire;
    wire        PC3wire;
    wire        PC4wire;
    wire        PC5wire;
    wire        PC6wire;
    wire        PC7wire;
    wire        PC8wire;
    wire        PC9wire;
    wire        PC10wire;
    wire        PC11wire;
    wire        PC12wire;
    wire        PC13wire;
    wire        PC14wire;
    wire        PC15wire;
    wire        PD0wire;
    wire        PD1wire;
    wire        PD2wire;
    wire        PD3wire;
    wire        PD4wire;
    wire        PD5wire;
    wire        PD6wire;
    wire        PD7wire;
    wire        PD8wire;
    wire        PD9wire;
    wire        PD10wire;
    wire        PD11wire;
    wire        PD12wire;
    wire        PD13wire;
    wire        PD14wire;
    wire        PD15wire;
    wire        PE0wire;
    wire        PE1wire;
    wire        PE2wire;
    wire        PE3wire;
    wire        PE4wire;
    wire        PE5wire;
    wire        PE6wire;
    wire        PE7wire;
    wire        PE8wire;
    wire        PE9wire;
    wire        PE10wire;
    wire        PE11wire;
    wire        PE12wire;
    wire        PE13wire;
    wire        PE14wire;
    wire        PE15wire;
    wire        PF0wire;
    wire        PF1wire;
    wire        PF2wire;
    wire        PF3wire;
    wire        PF4wire;
    wire        PF5wire;
    wire        PF6wire;
    wire        PF7wire;
    wire        PF8wire;
    wire        PF9wire;
    wire        SDIO_CLK;
    wire        SDIO_CMD;
    wire [3:0]  SDIO_DATA;
    reg         PA0,PA1,PA2,PF0,PB14=0;
    wire        PAD_SWDIO;
    wire        PAD_SWDCK;

// ======================
// io pad initialization
// ======================

    pullup (PA0wire);
    pullup (PA1wire);
    pullup (PB11);
    pullup (PB12);

// ======================
// clock generation
// ======================

    bit clk32k, clk48m;
    bit clk400k, clk3m;

    OSC_SIM #(20.835)       osc48M  ( .EN('1), .CFG('0), .CKO(clk48m));
    OSC_SIM #(31.25*1000)   osc32k  ( .EN('1), .CFG('0), .CKO(clk32k));
    OSC_SIM #(2500)         osc400k ( .EN('1), .CFG('0), .CKO(clk400k));
    OSC_SIM #(270)          osc3M   ( .EN('1), .CFG('0), .CKO(clk3m));

    `genclk(clk, 20)
    `genclk(clk1m, 1000)
    `timemarker2

// ======================
// QFC external model
// ======================

    wire [7:0]  adq;                
    wire        qfc_clk, qfc_clk_n; // Clock signals
    wire        csb;                // Chip select
    wire        flash_csn;          // Chip select to flash mem
    wire        rwds;               // Read/Write Data Strobe
    wire        resetb;             // Reset signal

`ifdef HYPERRAM
    W959D8NFYA 
     hyperram (
        .clk       (qfc_clk),       // Connect to DUT QFC_SCK
        .clk_n     (qfc_clk_n),     // Optional negative clock
        .csb       (csb),           // Connect to DUT QFC_SS0
        .adq       (adq),           // 8-bit data bus
        .rwds      (rwds),          // Data strobe
        .resetb    (resetb)         // Reset signal
    );
`endif

`ifdef QSPI
    pullup (adq[0]);
    pullup (rwds);
    //pulldown (adq[0]);

    W25Q128JVxIM 
     flash_mem (
        .CSn       (flash_csn),     // Connect to DUT QFC_SS0
        .CLK       (qfc_clk),       // Connect to DUT QFC_SCK
        .DIO       (adq[0]),        // Connect to DUT QFC_SIO0
        .DO        (adq[1]),        // Connect to DUT QFC_SIO1
        .WPn       (adq[2]),        // Connect to DUT QFC_SIO2
        .HOLDn     (adq[3])         // Connect to DUT QFC_SIO3
    );
`endif


// ======================
// SPIM external model
// ======================

`ifdef SPIM
    W25Q128JVxIM 
     flash_mem (
        .CSn       (PD5wire),      // Connect to DUT QFC_SS0
        .CLK       (PD4wire),      // Connect to DUT QFC_SCK
        .DIO       (PD0wire),      // Connect to DUT QFC_SIO0
        .DO        (PD1wire),      // Connect to DUT QFC_SIO1
        .WPn       (PD2wire),      // Connect to DUT QFC_SIO2
        .HOLDn     (PD3wire)       // Connect to DUT QFC_SIO3
    );
`endif

`ifdef SPIM1
    wire #1 PC11wire_dly =  PC11wire;
    W25Q128JVxIM 
     flash_mem (
        .CSn       (PC12wire),      // Connect to DUT QFC_SS0
        .CLK       (PC11wire_dly),      // Connect to DUT QFC_SCK
        //.CLK       (PC11wire),      // Connect to DUT QFC_SCK
        .DIO       (PC7wire),      // Connect to DUT QFC_SIO0
        .DO        (PC8wire),      // Connect to DUT QFC_SIO1
        .WPn       (PC9wire),      // Connect to DUT QFC_SIO2
        .HOLDn     (PC10wire)       // Connect to DUT QFC_SIO3
    );
`endif

`ifdef SPIM2
    W25Q128JVxIM 
     flash_mem (
        .CSn       (PB11wire),      // Connect to DUT QFC_SS0
        .CLK       (PB8wire),      // Connect to DUT QFC_SCK
        .DIO       (PB9wire),      // Connect to DUT QFC_SIO0
        .DO        (PB10wire),      // Connect to DUT QFC_SIO1
        .WPn       (),      // Connect to DUT QFC_SIO2
        .HOLDn     ()       // Connect to DUT QFC_SIO3
    );
`endif

`ifdef SPIM3
    W25Q128JVxIM 
     flash_mem (
        .CSn       (PE9wire),      // Connect to DUT QFC_SS0
        .CLK       (PE6wire),      // Connect to DUT QFC_SCK
        .DIO       (PE7wire),      // Connect to DUT QFC_SIO0
        .DO        (PE8wire),      // Connect to DUT QFC_SIO1
        .WPn       (),      // Connect to DUT QFC_SIO2
        .HOLDn     ()       // Connect to DUT QFC_SIO3
    );
`endif

// ======================
// UART test
// ======================
// UART loopback
//`ifdef UART_TEST
//        .PA4 (uartloop),
//        .PD13 (uartloop),
//`endif

`ifdef UART01A_TEST
     // A[0] to A[1]
     assign PD13wire = PA4wire;
`endif
`ifdef UART01B_TEST
     // B[0] to B[1]
     assign PE2wire = PD3wire;
`endif
`ifdef UART10A_TEST
     // A[1] to A[0] 
      assign PA3wire = PD14wire;
`endif
`ifdef UART10B_TEST
     // B[1] to B[0]
     assign PD2wire = PE3wire;
`endif

`ifdef UART32_TEST
     assign PE12wire = PE5wire;
`endif

`ifdef UART23A_TEST
     assign PE4wire = PE13wire;
`endif

`ifdef UART23B_TEST
     assign PE4wire = PB14wire;
`endif

`ifdef UART_RX_IRQ_TEST
     // A[0] to A[0]
     assign PA3wire = PA4wire;
`endif

`ifdef UART_RX_POLLING_TEST
     // A[0] to A[0]
     assign PA3wire = PA4wire;
`endif

// ======================
// ADC test
// ======================
`ifdef ADC
    initial begin
        // force temperature
        #(20385727) force daric_top_tb.dut.soc.soc_ifsub.__gen_udma.dmasub.udma.i_adc_if.t_tsadc_dout[9:0] = 10'd500;
        #(15583)    release daric_top_tb.dut.soc.soc_ifsub.__gen_udma.dmasub.udma.i_adc_if.t_tsadc_dout[9:0];
    end
`endif

// ======================
// GPIO test
// ======================

`ifdef GPIO_IN
    reg PA0reg;
    reg PA1reg;
    reg PA2reg;
    reg PA3reg;
    reg PA4reg;
    reg PA5reg;
    reg PA6reg;
    reg PA7reg;
    assign PA0wire = PA0reg;
    assign PA1wire = PA1reg;
    assign PA2wire = PA2reg;
    assign PA3wire = PA3reg;
    assign PA4wire = PA4reg;
    assign PA5wire = PA5reg;
    assign PA6wire = PA6reg;
    assign PA7wire = PA7reg;

    reg PB0reg;
    reg PB1reg;
    reg PB2reg;
    reg PB3reg;
    reg PB4reg;
    reg PB5reg;
    reg PB6reg;
    reg PB7reg;
    reg PB8reg;
    reg PB9reg;
    reg PB10reg;
    reg PB11reg;
    reg PB12reg;
    reg PB13reg;
    reg PB14reg;
    reg PB15reg;
    assign PB0wire = PB0reg;
    assign PB1wire = PB1reg;
    assign PB2wire = PB2reg;
    assign PB3wire = PB3reg;
    assign PB4wire = PB4reg;
    assign PB5wire = PB5reg;
    assign PB6wire = PB6reg;
    assign PB7wire = PB7reg;
    assign PB8wire = PB8reg;
    assign PB9wire = PB9reg;
    assign PB10wire = PB10reg;
    assign PB11wire = PB11reg;
    assign PB12wire = PB12reg;
    assign PB13wire = PB13reg;
    assign PB14wire = PB14reg;
    assign PB15wire = PB15reg;

    reg PC0reg;
    reg PC1reg;
    reg PC2reg;
    reg PC3reg;
    reg PC4reg;
    reg PC5reg;
    reg PC6reg;
    reg PC7reg;
    reg PC8reg;
    reg PC9reg;
    reg PC10reg;
    reg PC11reg;
    reg PC12reg;
    reg PC13reg;
    reg PC14reg;
    reg PC15reg;
    assign PC0wire = PC0reg;
    assign PC1wire = PC1reg;
    assign PC2wire = PC2reg;
    assign PC3wire = PC3reg;
    assign PC4wire = PC4reg;
    assign PC5wire = PC5reg;
    assign PC6wire = PC6reg;
    assign PC7wire = PC7reg;
    assign PC8wire = PC8reg;
    assign PC9wire = PC9reg;
    assign PC10wire = PC10reg;
    assign PC11wire = PC11reg;
    assign PC12wire = PC12reg;
    assign PC13wire = PC13reg;
    assign PC14wire = PC14reg;
    assign PC15wire = PC15reg;

    reg PD0reg;
    reg PD1reg;
    reg PD2reg;
    reg PD3reg;
    reg PD4reg;
    reg PD5reg;
    reg PD6reg;
    reg PD7reg;
    reg PD8reg;
    reg PD9reg;
    reg PD10reg;
    reg PD11reg;
    reg PD12reg;
    reg PD13reg;
    reg PD14reg;
    reg PD15reg;
    assign PD0wire = PD0reg;
    assign PD1wire = PD1reg;
    assign PD2wire = PD2reg;
    assign PD3wire = PD3reg;
    assign PD4wire = PD4reg;
    assign PD5wire = PD5reg;
    assign PD6wire = PD6reg;
    assign PD7wire = PD7reg;
    assign PD8wire = PD8reg;
    assign PD9wire = PD9reg;
    assign PD10wire = PD10reg;
    assign PD11wire = PD11reg;
    assign PD12wire = PD12reg;
    assign PD13wire = PD13reg;
    assign PD14wire = PD14reg;
    assign PD15wire = PD15reg;

    reg PE0reg;
    reg PE1reg;
    reg PE2reg;
    reg PE3reg;
    reg PE4reg;
    reg PE5reg;
    reg PE6reg;
    reg PE7reg;
    reg PE8reg;
    reg PE9reg;
    reg PE10reg;
    reg PE11reg;
    reg PE12reg;
    reg PE13reg;
    reg PE14reg;
    reg PE15reg;
    assign PE0wire = PE0reg;
    assign PE1wire = PE1reg;
    assign PE2wire = PE2reg;
    assign PE3wire = PE3reg;
    assign PE4wire = PE4reg;
    assign PE5wire = PE5reg;
    assign PE6wire = PE6reg;
    assign PE7wire = PE7reg;
    assign PE8wire = PE8reg;
    assign PE9wire = PE9reg;
    assign PE10wire = PE10reg;
    assign PE11wire = PE11reg;
    assign PE12wire = PE12reg;
    assign PE13wire = PE13reg;
    assign PE14wire = PE14reg;
    assign PE15wire = PE15reg;

    reg PF0reg;
    reg PF1reg;
    reg PF2reg;
    reg PF3reg;
    reg PF4reg;
    reg PF5reg;
    reg PF6reg;
    reg PF7reg;
    reg PF8reg;
    reg PF9reg;
    assign PF0wire = PF0reg;
    assign PF1wire = PF1reg;
    assign PF2wire = PF2reg;
    assign PF3wire = PF3reg;
    assign PF4wire = PF4reg;
    assign PF5wire = PF5reg;
    assign PF6wire = PF6reg;
    assign PF7wire = PF7reg;
    assign PF8wire = PF8reg;
    assign PF9wire = PF9reg;

    integer int_cnt;
    initial begin
        {PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = 8'hzz;
        {PB7reg, PB6reg, PB5reg, PB4reg, PB3reg, PB2reg, PB1reg, PB0reg} = 8'hzz;
        {PB15reg, PB14reg, PB13reg, PB12reg, PB11reg, PB10reg, PB9reg, PB8reg} = 8'hzz;
        {PC7reg, PC6reg, PC5reg, PC4reg, PC3reg, PC2reg, PC1reg, PC0reg} = 8'hzz;
        {PC15reg, PC14reg, PC13reg, PC12reg, PC11reg, PC10reg, PC9reg, PC8reg} = 8'hzz;
        {PD7reg, PD6reg, PD5reg, PD4reg, PD3reg, PD2reg, PD1reg, PD0reg} = 8'hzz;
        {PD15reg, PD14reg, PD13reg, PD12reg, PD11reg, PD10reg, PD9reg, PD8reg} = 8'hzz;
        {PE7reg, PE6reg, PE5reg, PE4reg, PE3reg, PE2reg, PE1reg, PE0reg} = 8'hzz;
        {PE15reg, PE14reg, PE13reg, PE12reg, PE11reg, PE10reg, PE9reg, PE8reg} = 8'hzz;
        {PF9reg, PF8reg, PF7reg, PF6reg, PF5reg, PF4reg, PF3reg, PF2reg, PF1reg, PF0reg} = 10'hzzz;

//        wait (syscnt == 32'h81d2);
//        $display("%t -- %m: INFO: toggle PA0~7 ", $time);
//        {PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = 8'hff;
//        wait (dut.soc.soc_ifsub.u__gen_iomux___iox.sfr_intcr_dx.din[86] === 1);
//        //repeat (1) @(posedge clk1m);
//        repeat (20) @(posedge clk1m);
//        for (i = 0; i < 8; i++) begin
//            //wait (syscnt == (32'd38298 + i*4000));
//            $display("[%t]INFO: Toggling PA[%d] from HOGH to LOW", $time, i);
//            {PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = ~(8'h01 << i);
//            repeat (10) @(posedge clk1m);
//            $display("[%t]INFO: syscnt=", $time, syscnt);
//        end

        $display("%t -- %m: INFO: toggle PA0~7 ", $time);
        {PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = ~(8'h01 << int_cnt);
        end

        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PB0~7 ", $time);
        {PB7reg, PB6reg, PB5reg, PB4reg, PB3reg, PB2reg, PB1reg, PB0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PB7reg, PB6reg, PB5reg, PB4reg, PB3reg, PB2reg, PB1reg, PB0reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PB8~15 ", $time);
        {PB15reg, PB14reg, PB13reg, PB12reg, PB11reg, PB10reg, PB9reg, PB8reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PB15reg, PB14reg, PB13reg, PB12reg, PB11reg, PB10reg, PB9reg, PB8reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PC0~7 ", $time);
        {PC7reg, PC6reg, PC5reg, PC4reg, PC3reg, PC2reg, PC1reg, PC0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PC7reg, PC6reg, PC5reg, PC4reg, PC3reg, PC2reg, PC1reg, PC0reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PC8~15 ", $time);
        {PC15reg, PC14reg, PC13reg, PC12reg, PC11reg, PC10reg, PC9reg, PC8reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PC15reg, PC14reg, PC13reg, PC12reg, PC11reg, PC10reg, PC9reg, PC8reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PD0~7 ", $time);
        {PD7reg, PD6reg, PD5reg, PD4reg, PD3reg, PD2reg, PD1reg, PD0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PD7reg, PD6reg, PD5reg, PD4reg, PD3reg, PD2reg, PD1reg, PD0reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PD8~15 ", $time);
        {PD15reg, PD14reg, PD13reg, PD12reg, PD11reg, PD10reg, PD9reg, PD8reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PD15reg, PD14reg, PD13reg, PD12reg, PD11reg, PD10reg, PD9reg, PD8reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PE0~7 ", $time);
        {PE7reg, PE6reg, PE5reg, PE4reg, PE3reg, PE2reg, PE1reg, PE0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PE7reg, PE6reg, PE5reg, PE4reg, PE3reg, PE2reg, PE1reg, PE0reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PE8~15 ", $time);
        {PE15reg, PE14reg, PE13reg, PE12reg, PE11reg, PE10reg, PE9reg, PE8reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PE15reg, PE14reg, PE13reg, PE12reg, PE11reg, PE10reg, PE9reg, PE8reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PF0~7 ", $time);
        {PF7reg, PF6reg, PF5reg, PF4reg, PF3reg, PF2reg, PF1reg, PF0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PF7reg, PF6reg, PF5reg, PF4reg, PF3reg, PF2reg, PF1reg, PF0reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PF8~9 ", $time);
        {PF9reg, PF8reg} = 2'b11;
        for (int_cnt = 0; int_cnt < 2; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PF9reg, PF8reg} = ~(2'b01 << int_cnt);
        end

    end
`endif

`ifdef GPIO_IN_A
    reg PA0reg;
    reg PA1reg;
    reg PA2reg;
    reg PA3reg;
    reg PA4reg;
    reg PA5reg;
    reg PA6reg;
    reg PA7reg;
    assign PA0wire = PA0reg;
    assign PA1wire = PA1reg;
    assign PA2wire = PA2reg;
    assign PA3wire = PA3reg;
    assign PA4wire = PA4reg;
    assign PA5wire = PA5reg;
    assign PA6wire = PA6reg;
    assign PA7wire = PA7reg;


    integer int_cnt;
    initial begin
        {PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = 8'hzz;
        $display("%t -- %m: INFO: toggle PA0~7 ", $time);
        {PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = ~(8'h01 << int_cnt);
        end
    end
`endif

`ifdef GPIO_IN_BC
    reg PB0reg;
    reg PB1reg;
    reg PB2reg;
    reg PB3reg;
    reg PB4reg;
    reg PB5reg;
    reg PB6reg;
    reg PB7reg;
    reg PB8reg;
    reg PB9reg;
    reg PB10reg;
    reg PB11reg;
    reg PB12reg;
    reg PB13reg;
    reg PB14reg;
    reg PB15reg;
    assign PB0wire = PB0reg;
    assign PB1wire = PB1reg;
    assign PB2wire = PB2reg;
    assign PB3wire = PB3reg;
    assign PB4wire = PB4reg;
    assign PB5wire = PB5reg;
    assign PB6wire = PB6reg;
    assign PB7wire = PB7reg;
    assign PB8wire = PB8reg;
    assign PB9wire = PB9reg;
    assign PB10wire = PB10reg;
    assign PB11wire = PB11reg;
    assign PB12wire = PB12reg;
    assign PB13wire = PB13reg;
    assign PB14wire = PB14reg;
    assign PB15wire = PB15reg;

    reg PC0reg;
    reg PC1reg;
    reg PC2reg;
    reg PC3reg;
    reg PC4reg;
    reg PC5reg;
    reg PC6reg;
    reg PC7reg;
    reg PC8reg;
    reg PC9reg;
    reg PC10reg;
    reg PC11reg;
    reg PC12reg;
    reg PC13reg;
    reg PC14reg;
    reg PC15reg;
    assign PC0wire = PC0reg;
    assign PC1wire = PC1reg;
    assign PC2wire = PC2reg;
    assign PC3wire = PC3reg;
    assign PC4wire = PC4reg;
    assign PC5wire = PC5reg;
    assign PC6wire = PC6reg;
    assign PC7wire = PC7reg;
    assign PC8wire = PC8reg;
    assign PC9wire = PC9reg;
    assign PC10wire = PC10reg;
    assign PC11wire = PC11reg;
    assign PC12wire = PC12reg;
    assign PC13wire = PC13reg;
    assign PC14wire = PC14reg;
    assign PC15wire = PC15reg;

    integer int_cnt;
    initial begin
        {PB7reg, PB6reg, PB5reg, PB4reg, PB3reg, PB2reg, PB1reg, PB0reg} = 8'hzz;
        {PB15reg, PB14reg, PB13reg, PB12reg, PB11reg, PB10reg, PB9reg, PB8reg} = 8'hzz;
        {PC7reg, PC6reg, PC5reg, PC4reg, PC3reg, PC2reg, PC1reg, PC0reg} = 8'hzz;
        {PC15reg, PC14reg, PC13reg, PC12reg, PC11reg, PC10reg, PC9reg, PC8reg} = 8'hzz;
        $display("%t -- %m: INFO: toggle PB0~7 ", $time);
        {PB7reg, PB6reg, PB5reg, PB4reg, PB3reg, PB2reg, PB1reg, PB0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (1) @(posedge clk1m);
            {PB7reg, PB6reg, PB5reg, PB4reg, PB3reg, PB2reg, PB1reg, PB0reg} = ~(8'h01 << int_cnt);
        end
        
        $display("%t -- %m: INFO: toggle PB8~15 ", $time);
        {PB15reg, PB14reg, PB13reg, PB12reg, PB11reg, PB10reg, PB9reg, PB8reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (1) @(posedge clk1m);
            {PB15reg, PB14reg, PB13reg, PB12reg, PB11reg, PB10reg, PB9reg, PB8reg} = ~(8'h01 << int_cnt);
        end
        
        $display("%t -- %m: INFO: toggle PC0~7 ", $time);
        {PC7reg, PC6reg, PC5reg, PC4reg, PC3reg, PC2reg, PC1reg, PC0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (1) @(posedge clk1m);
            {PC7reg, PC6reg, PC5reg, PC4reg, PC3reg, PC2reg, PC1reg, PC0reg} = ~(8'h01 << int_cnt);
        end
        
        $display("%t -- %m: INFO: toggle PC8~15 ", $time);
        {PC15reg, PC14reg, PC13reg, PC12reg, PC11reg, PC10reg, PC9reg, PC8reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (1) @(posedge clk1m);
            {PC15reg, PC14reg, PC13reg, PC12reg, PC11reg, PC10reg, PC9reg, PC8reg} = ~(8'h01 << int_cnt);
        end
    end
`endif
        

`ifdef GPIO_IN_DE
    reg PD0reg;
    reg PD1reg;
    reg PD2reg;
    reg PD3reg;
    reg PD4reg;
    reg PD5reg;
    reg PD6reg;
    reg PD7reg;
    reg PD8reg;
    reg PD9reg;
    reg PD10reg;
    reg PD11reg;
    reg PD12reg;
    reg PD13reg;
    reg PD14reg;
    reg PD15reg;
    assign PD0wire = PD0reg;
    assign PD1wire = PD1reg;
    assign PD2wire = PD2reg;
    assign PD3wire = PD3reg;
    assign PD4wire = PD4reg;
    assign PD5wire = PD5reg;
    assign PD6wire = PD6reg;
    assign PD7wire = PD7reg;
    assign PD8wire = PD8reg;
    assign PD9wire = PD9reg;
    assign PD10wire = PD10reg;
    assign PD11wire = PD11reg;
    assign PD12wire = PD12reg;
    assign PD13wire = PD13reg;
    assign PD14wire = PD14reg;
    assign PD15wire = PD15reg;

    reg PE0reg;
    reg PE1reg;
    reg PE2reg;
    reg PE3reg;
    reg PE4reg;
    reg PE5reg;
    reg PE6reg;
    reg PE7reg;
    reg PE8reg;
    reg PE9reg;
    reg PE10reg;
    reg PE11reg;
    reg PE12reg;
    reg PE13reg;
    reg PE14reg;
    reg PE15reg;
    assign PE0wire = PE0reg;
    assign PE1wire = PE1reg;
    assign PE2wire = PE2reg;
    assign PE3wire = PE3reg;
    assign PE4wire = PE4reg;
    assign PE5wire = PE5reg;
    assign PE6wire = PE6reg;
    assign PE7wire = PE7reg;
    assign PE8wire = PE8reg;
    assign PE9wire = PE9reg;
    assign PE10wire = PE10reg;
    assign PE11wire = PE11reg;
    assign PE12wire = PE12reg;
    assign PE13wire = PE13reg;
    assign PE14wire = PE14reg;
    assign PE15wire = PE15reg;

    integer int_cnt;
    initial begin
        {PD7reg, PD6reg, PD5reg, PD4reg, PD3reg, PD2reg, PD1reg, PD0reg} = 8'hzz;
        {PD15reg, PD14reg, PD13reg, PD12reg, PD11reg, PD10reg, PD9reg, PD8reg} = 8'hzz;
        {PE7reg, PE6reg, PE5reg, PE4reg, PE3reg, PE2reg, PE1reg, PE0reg} = 8'hzz;
        {PE15reg, PE14reg, PE13reg, PE12reg, PE11reg, PE10reg, PE9reg, PE8reg} = 8'hzz;
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PD0~7 ", $time);
        {PD7reg, PD6reg, PD5reg, PD4reg, PD3reg, PD2reg, PD1reg, PD0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PD7reg, PD6reg, PD5reg, PD4reg, PD3reg, PD2reg, PD1reg, PD0reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PD8~15 ", $time);
        {PD15reg, PD14reg, PD13reg, PD12reg, PD11reg, PD10reg, PD9reg, PD8reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PD15reg, PD14reg, PD13reg, PD12reg, PD11reg, PD10reg, PD9reg, PD8reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PE0~7 ", $time);
        {PE7reg, PE6reg, PE5reg, PE4reg, PE3reg, PE2reg, PE1reg, PE0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PE7reg, PE6reg, PE5reg, PE4reg, PE3reg, PE2reg, PE1reg, PE0reg} = ~(8'h01 << int_cnt);
        end
        
        repeat (2) @(posedge clk1m);
        $display("%t -- %m: INFO: toggle PE8~15 ", $time);
        {PE15reg, PE14reg, PE13reg, PE12reg, PE11reg, PE10reg, PE9reg, PE8reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (2) @(posedge clk1m);
            {PE15reg, PE14reg, PE13reg, PE12reg, PE11reg, PE10reg, PE9reg, PE8reg} = ~(8'h01 << int_cnt);
        end
    end
`endif
        
`ifdef GPIO_IN_F
    reg PF0reg;
    reg PF1reg;
    reg PF2reg;
    reg PF3reg;
    reg PF4reg;
    reg PF5reg;
    reg PF6reg;
    reg PF7reg;
    reg PF8reg;
    reg PF9reg;
    assign PF0wire = PF0reg;
    assign PF1wire = PF1reg;
    assign PF2wire = PF2reg;
    assign PF3wire = PF3reg;
    assign PF4wire = PF4reg;
    assign PF5wire = PF5reg;
    assign PF6wire = PF6reg;
    assign PF7wire = PF7reg;
    assign PF8wire = PF8reg;
    assign PF9wire = PF9reg;

    integer int_cnt;
    initial begin
        {PF9reg, PF8reg, PF7reg, PF6reg, PF5reg, PF4reg, PF3reg, PF2reg, PF1reg, PF0reg} = 10'hzzz;
        $display("%t -- %m: INFO: toggle PF0~7 ", $time);
        {PF7reg, PF6reg, PF5reg, PF4reg, PF3reg, PF2reg, PF1reg, PF0reg} = 8'hff;
        for (int_cnt = 0; int_cnt < 8; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (1) @(posedge clk1m);
            {PF7reg, PF6reg, PF5reg, PF4reg, PF3reg, PF2reg, PF1reg, PF0reg} = ~(8'h01 << int_cnt);
        end
        
        $display("%t -- %m: INFO: toggle PF8~9 ", $time);
        {PF9reg, PF8reg} = 2'b11;
        for (int_cnt = 0; int_cnt < 2; int_cnt++) begin
            //@(posedge dut.soc.soc_ifsub.__gen_iomux.__iox.ctl_inten[int_cnt]);
            @(posedge dut.soc.soc_ifsub.u__gen_iomux___iox.ctl_inten[int_cnt]);
            $display("%t -- %m: INFO: ctl_inten[%d] is enabled ", $time, int_cnt);
            repeat (1) @(posedge clk1m);
            {PF9reg, PF8reg} = ~(2'b01 << int_cnt);
        end
    end
`endif


`ifdef GPIO_IRQ
    reg PA3reg;
    assign PA3wire = PA3reg;

    initial begin
        wait (syscnt == 32'd11688);
        $display("%t -- %m: INFO: toggle PA3 ", $time);
        PA3reg = 1'b1;
        wait (syscnt == 32'd11698);
        PA3reg = 1'b0;
    end
`endif

// ======================
// SPIM + SPIS loopback test
// ======================
//SPIS: PD12->SPIS1_SCK, PD13->SPIS1_NCS, PD14->SPIS1_MOSI, PD15->SPIS1_MISO
//SPIM: PB8-CLK, PB9-MOSI,PB10-MISO,PB11-CS
`ifdef SPI_loopback
    assign PD12wire = PB8wire;
    assign PD13wire = PB11wire;
    assign PD14wire = PB9wire;
    assign PB10wire = PD15wire;

    //initial begin
    //  #(59114046) force daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.cm7top.HWDATAP[31:0]= 32'd7;
    //  #(6750)     release daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.cm7top.HWDATAP[31:0];
    //  #(1343)     force daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.cm7top.HWDATAP[31:0]= 32'd7;
    //  #(1250)     release daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.cm7top.HWDATAP[31:0];
    //end

`endif

`ifdef SPIM1_SPIS0_loopback
    assign PD4wire  = PC11wire;
    assign PD5wire  = PC12wire;
    assign PD0wire  = PC7wire;
    assign PC8wire  = PD1wire;
`endif

`ifdef SPIM1_SPIS1_loopback
    assign PD12wire  = PC11wire;
    assign PD13wire  = PC12wire;
    assign PD14wire  = PC7wire;
    assign PC8wire  = PD15wire;
`endif

// ======================
// I2C external model
// ======================

`ifdef SIM_CM7_WFI_WFE
    reg PF0reg;
    assign PF0wire = PF0reg;
    initial begin
        PF0reg = 1'b1;
        wait (syscnt == 3900);
        $display("%t -- %m: INFO: PF0 asserting to 0 -> wake from WFE", $time);
        PF0reg = 1'b0;
        wait (syscnt == 4000);
        PF0reg = 1'b1;

        wait (syscnt == 4300);
        $display("%t -- %m: INFO: PF0 asserting to 0 -> wake from WFI", $time);
        PF0reg = 1'b0;
        wait (syscnt == 4310);
        PF0reg = 1'b1;
    end
`endif

`ifdef SIM_MDMA_EVT
    reg PB9reg;
    assign PB9wire = PB9reg;
    initial begin
        PB9reg = 1'b1;
        wait (syscnt == 8000);
        PB9reg = 1'b0;
        $display("%t -- %m: INFO: PB9 asserting to 0", $time);
    end
`endif

`ifdef SIM_I2C_NACK_NO_SLAVE
    pullup (PA5wire);
    pullup (PA6wire);
    pullup (PC5wire);
    pullup (PC6wire);
    pullup (PE0wire);
    pullup (PE1wire);
    pullup (PE10wire);
    pullup (PE11wire);
    pullup (PE14wire);
    pullup (PE15wire);
    pullup (PF2wire);
    pullup (PF3wire);
`endif

`ifdef USE_I2C_SLAVE
    localparam I2C0_DEVICE_ID = 7'h33;
    localparam I2C1_DEVICE_ID = 7'h34;
    localparam I2C2_DEVICE_ID = 7'h35;
    localparam I2C3_DEVICE_ID = 7'h36;
    wire i2c_slave_rst = ~dut.soc.soc_ifsub.resetn;
    wire i2c_slave_clk = dut.soc.soc_ifsub.perclk;

    initial begin
        $display("%t -- %m: INFO: Using I2C Slave models", $time);
    end

    i2cSlaveTop #(I2C0_DEVICE_ID)
    u_i2c_slave0 (
        .rst (i2c_slave_rst),
        .clk (i2c_slave_clk),
    `ifdef USE_I2C_GRPB
        .scl (PB11),
        .sda (PB12)
    );
    `else // GRPA
        .scl (PA5wire),
        .sda (PA6wire)
    );
    pullup (PA5wire);
    pullup (PA6wire);
    `endif

    i2cSlaveTop #(I2C1_DEVICE_ID)
    u_i2c_slave1 (
        .rst (i2c_slave_rst),
        .clk (i2c_slave_clk),
    `ifdef USE_I2C_GRPB
        .scl (PE0wire),
        .sda (PE1wire)
    );
    pullup (PE0wire);
    pullup (PE1wire);
    `else // GRPA
        .scl (PA0wire),
        .sda (PA1wire)
    );
    `endif

    i2cSlaveTop #(I2C2_DEVICE_ID)
    u_i2c_slave2 (
        .rst (i2c_slave_rst),
        .clk (i2c_slave_clk),
    `ifdef USE_I2C_GRPB
        .scl (PF2wire),
        .sda (PF3wire)
    );
    pullup (PF2wire);
    pullup (PF3wire);
    `else // GRPA
        .scl (PE10wire),
        .sda (PE11wire)
    );
    pullup (PE10wire);
    pullup (PE11wire);
    `endif

    i2cSlaveTop #(I2C3_DEVICE_ID)
    u_i2c_slave3 (
        .rst (i2c_slave_rst),
        .clk (i2c_slave_clk),
    `ifdef USE_I2C_GRPB
        .scl (PC5wire),
        .sda (PC6wire)
    );
    pullup (PC5wire);
    pullup (PC6wire);
    `else // GRPA
        .scl (PE14wire),
        .sda (PE15wire)
    );
    pullup (PE14wire);
    pullup (PE15wire);
    `endif
`endif //USE_I2C_SLAVE

`ifdef SIM_AO_WAKEUP
    reg PF0reg;
    assign PF0wire = PF0reg;
    initial begin
    `ifdef SIM_AO_KEYPAD_WAKEUP
        wakeup_ao(8000, 8400);
    `elsif SIM_AO_BUREG_WAKEUP
        wakeup_ao(12500, 12600);
    `elsif SIM_AO_RAM_WAKEUP
        wakeup_ao(14000, 14100);
    `elsif SIM_AO_GPIO_WAKEUP
        wakeup_ao(5680, 5780);
    `endif
    end
`endif //SIM_AO_WAKEUP

`ifdef SIM_AO_KEYPAD
    reg [4:0] kp_data = 0;
    reg key_pressed = 0;
    reg [4:0] keypad = 'h10;
    wire fifo_wr;

    pullup(PF2wire);
    pullup(PF3wire);
    pullup(PF4wire);
    pullup(PF5wire);
    pullup(PF6wire);
    pullup(PF7wire);
    pullup(PF8wire);
    pullup(PF9wire);

    assign fifo_wr = dut.ao.dkpc.evirq;

    always @(posedge fifo_wr) begin
        #1;
        $display("%t -- %m: INFO: FIFO write", $time);
    end

    always @(keypad) begin
        if (keypad < 16) begin
            $display("%t -- %m: INFO: Keypad = %0d", $time, keypad);
        end
        else begin
            $display("%t -- %m: INFO: Keypad released", $time);
        end
    end

    assign PF2wire = keypad == 5'h0 ? PF6wire
                   : keypad == 5'h4 ? PF7wire
                   : keypad == 5'h8 ? PF8wire
                   : keypad == 5'hC ? PF9wire
                   : 1'bz;

    assign PF3wire = keypad == 5'h1 ? PF6wire
                   : keypad == 5'h5 ? PF7wire
                   : keypad == 5'h9 ? PF8wire
                   : keypad == 5'hD ? PF9wire
                   : 1'bz;

    assign PF4wire = keypad == 5'h2 ? PF6wire
                   : keypad == 5'h6 ? PF7wire
                   : keypad == 5'hA ? PF8wire
                   : keypad == 5'hE ? PF9wire
                   : 1'bz;

    assign PF5wire = keypad == 5'h3 ? PF6wire
                   : keypad == 5'h7 ? PF7wire
                   : keypad == 5'hB ? PF8wire
                   : keypad == 5'hF ? PF9wire
                   : 1'bz;

    initial begin
        @(negedge clk32k);
        @(posedge clk32k);
        wait (syscnt === 5400);

        // Limiting to 4 diagonal key presses due to very long sim time.
        // These are unrealistically precise key presses to reduce GLS runtime.
        @(negedge PF6wire);
        assign keypad = 5'h0F;
        repeat (4) @(posedge PF9wire);
        assign keypad = 5'h10;

        @(negedge PF6wire);
        assign keypad = 5'h0A;
        repeat (4) @(posedge PF9wire);
        assign keypad = 5'h10;

        @(negedge PF6wire);
        assign keypad = 5'h05;
        repeat (4) @(posedge PF9wire);
        assign keypad = 5'h10;

        @(negedge PF6wire);
        assign keypad = 5'h00;
        repeat (4) @(posedge PF9wire);
        assign keypad = 5'h10;
    end
`endif //SIM_AO_KEYPAD

`ifdef SIM_AO_GPIO
    wire mon_clk;
    wire [9:0] pf_value;
    logic [9:0] pf_que [$:12];
    reg [9:0] tb2dut_pf = 0;
    reg [9:0] tb2dut_drive_en = 0;
    event e_pf9;

    assign mon_clk = dut.soc.sysctrl.pclk;

    initial begin
        wait (syscnt === 4256);

        repeat (12) begin
            @(posedge PF9wire);
            #2 $display("%t -- %m: INFO: DUT is driving PF[9:0] = 0x%X\n",
                        $time, pf_value);
            -> e_pf9;
            pf_que.push_front(pf_value);
        end

        repeat (12) begin
            @(posedge PF9wire);
            tb2dut_drive_en = 9'h1FF; //using PF9 as a data strobe output
            tb2dut_pf = pf_que.pop_back();
            #2 $display("%t -- %m: INFO: TB is driving PF[8:0] = 0x%X\n",
                        $time, tb2dut_pf[8:0]);
        end

        @(posedge PF9wire);
        #2 $display("%t -- %m: INFO: TB is driving PF[1:0] high to prevent wakeup IRQ\n", $time);
        tb2dut_pf[1:0] = 2'h3;

        @(negedge PF9wire);
        #2 $display("%t -- %m: INFO: TB is driving PF[1] low to generate wakeup IRQ\n", $time);
        tb2dut_pf[1] = 0;
    end

    assign PF0wire = tb2dut_drive_en[0] ? tb2dut_pf[0] : 1'bz;
    assign PF1wire = tb2dut_drive_en[1] ? tb2dut_pf[1] : 1'bz;
    assign PF2wire = tb2dut_drive_en[2] ? tb2dut_pf[2] : 1'bz;
    assign PF3wire = tb2dut_drive_en[3] ? tb2dut_pf[3] : 1'bz;
    assign PF4wire = tb2dut_drive_en[4] ? tb2dut_pf[4] : 1'bz;
    assign PF5wire = tb2dut_drive_en[5] ? tb2dut_pf[5] : 1'bz;
    assign PF6wire = tb2dut_drive_en[6] ? tb2dut_pf[6] : 1'bz;
    assign PF7wire = tb2dut_drive_en[7] ? tb2dut_pf[7] : 1'bz;
    assign PF8wire = tb2dut_drive_en[8] ? tb2dut_pf[8] : 1'bz;
    assign PF9wire = tb2dut_drive_en[9] ? tb2dut_pf[9] : 1'bz;

    assign pf_value = {PF9wire, PF8wire,
                       PF7wire, PF6wire, PF5wire, PF4wire,
                       PF3wire, PF2wire, PF1wire, PF0wire};
`endif //SIM_AO_GPIO

`ifdef USE_SIM_END_FLAG
    event e_sim_end;
    wire aobureg_pclk = dut.ao.aobureg.pclk;
    wire aobureg_resetn = dut.ao.aobureg.resetn;
    wire aobureg_psel = dut.ao.aobureg.apbs_psel;
    wire aobureg_penable = dut.ao.aobureg.apbs_penable;
    wire aobureg_pwrite = dut.ao.aobureg.apbs_pwrite;
    wire [11:0] aobureg_paddr = dut.ao.aobureg.apbs_paddr;
    wire [31:0] aobureg_pwdata = dut.ao.aobureg.apbs_pwdata;

    // Writing to AO Backup Register @ 0x4006501C = 0xDEADFEED terminates sim.
    always @(posedge aobureg_pclk)
    begin
        if (aobureg_resetn
            && aobureg_pwrite
            && (aobureg_paddr == 12'h1C)
            && (aobureg_pwdata == 32'hDEAD_FEED))
        begin
            $display("%t -- %m: INFO: SIM_END Request Detected!", $time);
            -> e_sim_end;
            $finish;
        end
    end
`endif

// ======================
// SDIO external model
// ======================

//`ifdef SDSIM
//    sdModel sd(
//        .sdClk ( SDIO_CLK ),
//        .cmd   ( SDIO_CMD ),
//        .dat   ( SDIO_DATA)
//    );
//`endif

`ifdef SDSIM
    sdio_emu sdio_emu(.resetn(resetn),
                      .sdclk(PC0wire),
                      .hclk(clk),
                      .cd_i(),
                      .wp_i(),
                      .cmd(PC1wire),
                      .data0(PC2wire),
                      .data1(PC3wire),
                      .data2(PC4wire),
                      .data3(PC5wire));
`endif

// ======================
// SWD external model
// ======================

`ifdef ENABLE_SWD
    swd uswd(
            .clkin(clk1m), 
            .SWCLK(PAD_SWDCK), 
            .SWDIO(PAD_SWDIO)
    );
`endif

// ======================
// dut instantiation
// ======================

    daric_top dut(

        .XTAL48M_IN (clk48m),

`ifndef FPGA
        .XTAL32K_IN (clk32k),
        .PAD_WMS0(cmspad[0]),           //liza
        .PAD_WMS1(cmspad[1]),           //liza
        .PAD_WMS2(cmspad[2]),           //liza
`endif

        .QFC_SCK   (qfc_clk),       // Connect to HyperRAM clock
        .QFC_SCKN  (qfc_clk_n),     // Optional negative clock (if used)
        .QFC_SS1   (csb),           // Connect to HyperRAM chip select
        .QFC_SS0   (flash_csn),     // Connect to flash mem chip select
        .QFC_SIO0  (adq[0]),        // Data bus bit 0
        .QFC_SIO1  (adq[1]),        // Data bus bit 1
        .QFC_SIO2  (adq[2]),        // Data bus bit 2
        .QFC_SIO3  (adq[3]),        // Data bus bit 3
        .QFC_SIO4  (adq[4]),        // Data bus bit 4
        .QFC_SIO5  (adq[5]),        // Data bus bit 5
        .QFC_SIO6  (adq[6]),        // Data bus bit 6
        .QFC_SIO7  (adq[7]),        // Data bus bit 7
        .QFC_QDS   (rwds),          // Data strobe
        .QFC_RSTS0 (resetb),        // Reset signal

        .PA0 (PA0wire),
        .PA1 (PA1wire),
        .PA2 (PA2wire),
        .PA3 (PA3wire),
        .PA4 (PA4wire),
        .PA5 (PA5wire),
        .PA6 (PA6wire),
        .PA7 (PA7wire),

        .PB0 (PB0wire),
        .PB1 (PB1wire),
        .PB2 (PB2wire),
        .PB3 (PB3wire),
        .PB4 (PB4wire),
        .PB5 (PB5wire),
        .PB6 (PB6wire),
        .PB7 (PB7wire),
        .PB8 (PB8wire),
        .PB9 (PB9wire),
        .PB10 (PB10wire),
`ifdef GPIO_IN_BC
        .PB11 (PB11wire),
        .PB12 (PB12wire),
`elsif SPIM2
        .PB11 (PB11wire),
        .PB12 (PB12wire),
`else
        .PB11,
        .PB12,
`endif
        .PB13 (PB13wire),
        .PB14 (PB14wire),
        .PB15 (PB15wire),

//`ifdef SDSIM
        //.PC0 (SDIO_CLK),
        //.PC1 (SDIO_CMD),
        //.PC2 (SDIO_DATA[0]),
        //.PC3 (SDIO_DATA[1]),
        //.PC4 (SDIO_DATA[2]),
        //.PC5 (SDIO_DATA[3]),
//`else
        //.PC5 (PC5wire),
        //.PC6 (PC6wire),
//`endif
        .PC0 (PC0wire),
        .PC1 (PC1wire),
        .PC2 (PC2wire),
        .PC3 (PC3wire),
        .PC4 (PC4wire),
        .PC5 (PC5wire),
        .PC6 (PC6wire),
        .PC7 (PC7wire),
        .PC8 (PC8wire),
        .PC9 (PC9wire),
        .PC10 (PC10wire),
        .PC11 (PC11wire),
        .PC12 (PC12wire),
        .PC13 (PC13wire),
        .PC14 (PC14wire),
        .PC15 (PC15wire),

        .PD0 (PD0wire),
        .PD1 (PD1wire),
        .PD2 (PD2wire),
        .PD3 (PD3wire),
        .PD4 (PD4wire),
        .PD5 (PD5wire),
        .PD6 (PD6wire),
        .PD7 (PD7wire),
        .PD8 (PD8wire),
        .PD9 (PD9wire),
        .PD10 (PD10wire),
        .PD11 (PD11wire),
        .PD12 (PD12wire),
        .PD13 (PD13wire),
        .PD14 (PD14wire),
        .PD15 (PD15wire),

        .PE0 (PE0wire),
        .PE1 (PE1wire),
        .PE2 (PE2wire),
        .PE3 (PE3wire),
        .PE4 (PE4wire),
        .PE5 (PE5wire),
        .PE6 (PE6wire),
        .PE7 (PE7wire),
        .PE8 (PE8wire),
        .PE9 (PE9wire),
        .PE10 (PE10wire),
        .PE11 (PE11wire),
        .PE12 (PE12wire),
        .PE13 (PE13wire),
        .PE14 (PE14wire),
        .PE15 (PE15wire),

        .PF0 (PF0wire),
        .PF1 (PF1wire),
        .PF2 (PF2wire),
        .PF3 (PF3wire),
        .PF4 (PF4wire),
        .PF5 (PF5wire),
        .PF6 (PF6wire),
        .PF7 (PF7wire),
        .PF8 (PF8wire),
        .PF9 (PF9wire),

        .PAD_SWDCK  (PAD_SWDCK),
        .PAD_SWDIO  (PAD_SWDIO),
        .PAD_AOXRSTn  (padresetn)

    );


// ======================
// netlist SDF annotation
// ======================

initial begin

`ifdef GLS0416
    `ifdef TC_0P9V_25C
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/release_data/prdata_20250416/daric_top_func_v0p9_tc.sdf", daric_top_tb.dut, ,"daric_sdf_tc0p9v.log", "MAXIMUM", , );
        sram_set_trim_0p9v;
    `elsif BC_0P9V
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/release_data/prdata_20250416/daric_top_func_v0p9_bc.sdf", daric_top_tb.dut, ,"daric_sdf_bc0p9v.log", "MINIMUM", , );
        sram_set_trim_0p9v;
    `elsif WC_0P9V
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/release_data/prdata_20250416/daric_top_func_v0p9_wc.sdf", daric_top_tb.dut, ,"daric_sdf_wc0p9v.log", "MAXIMUM", , );
        sram_set_trim_0p9v;
    `elsif TC_0P8V_25C
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/release_data/prdata_20250416/daric_top_func_v0p8_tc.sdf", daric_top_tb.dut, ,"daric_sdf_tc0p8v.log", "MAXIMUM", , );
        sram_set_trim_0p8v;
    `elsif BC_0P8V
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/release_data/prdata_20250416/daric_top_func_v0p8_bc.sdf", daric_top_tb.dut, ,"daric_sdf_bc0p8v.log", "MINIMUM", , );
        sram_set_trim_0p8v;
    `elsif WC_0P8V
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/release_data/prdata_20250416/daric_top_func_v0p8_wc.sdf", daric_top_tb.dut, ,"daric_sdf_wc0p8v.log", "MAXIMUM", , );
        sram_set_trim_0p8v;
    `endif
`else // default to GLS0414
    `ifdef TC_0P9V_25C
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/daric_top_func_v0p9_tc.sdf", daric_top_tb.dut, ,"daric_sdf_tc0p9v.log", "MAXIMUM", , );
        sram_set_trim_0p9v;
    `elsif BC_0P9V
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/daric_top_func_v0p9_bc.sdf", daric_top_tb.dut, ,"daric_sdf_bc0p9v.log", "MINIMUM", , );
        sram_set_trim_0p9v;
    `elsif WC_0P9V
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/daric_top_func_v0p9_wc.sdf", daric_top_tb.dut, ,"daric_sdf_wc0p9v.log", "MAXIMUM", , );
        sram_set_trim_0p9v;
    `elsif TC_0P8V_25C
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/daric_top_func_v0p8_tc.sdf", daric_top_tb.dut, ,"daric_sdf_tc0p8v.log", "MAXIMUM", , );
        sram_set_trim_0p8v;
    `elsif BC_0P8V
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/daric_top_func_v0p8_bc.sdf", daric_top_tb.dut, ,"daric_sdf_bc0p8v.log", "MINIMUM", , );
        sram_set_trim_0p8v;
    `elsif WC_0P8V
        $sdf_annotate("/work/daric/repo/frontend_release/asic_top/netlists/daric_top_func_v0p8_wc.sdf", daric_top_tb.dut, ,"daric_sdf_wc0p8v.log", "MAXIMUM", , );
        sram_set_trim_0p8v;
    `endif
`endif

end

// ======================
// netlist initial force
// ======================

/*
initial begin

#100;
force dut.soc.sysctrl.aoclkreg_reg.Q                           = 1'b0;
force dut.soc.sysctrl.clkaoramreg_reg.Q                        = 1'b0;
force dut.soc.sysctrl.clkperreg_reg.Q                          = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_4_.Q            = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_5_.Q            = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_1_.Q            = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_6_4_2_0_.Q      = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_3_.Q            = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_8_.Q            = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_7_.Q            = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_0_.Q            = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_4_1_.Q          = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_8_5_.Q          = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd0cnt_reg_4_1_3_2_.Q      = 1'b0;
force dut.soc.sysctrl.ucgucore.fdu0.fd2cnt_reg_8_5_.Q          = 1'b0;

#100
release;

end

*/


// ======================
// testbench flow control
// ======================

initial begin
    syscnt = 0;
    sim_stop = 0;
    forever begin
        @(posedge clk1m) syscnt += 1;
        if (syscnt == `TIMEOUT) begin
            sim_stop = 1;
            $display("%t -- %m: INFO: Simulation Timeout!", $time);
            $finish;
        end
    end
end



    `maintest(daric_top_tb,daric_top_tb)
        #105 resetn = 0; #(1 `MS) padresetn = 1;

//        #(15 `US) resetn = 0;
        #(1 `US) resetn = 1;

        #(900 `MS);
    `maintestend

`ifdef SIM_UPF
    wire aopdreg = dut.ao.aosc.aopdreg;
    wire pwr_vdd85a = dut.pmu.pwr_VDD85A;
    wire pwr_vdd85d = dut.pmu.pwr_VDD85D;
    wire vdd85aen = dut.pmu.D2A_VDDAO_VR85AENA;
    wire vdd85den = dut.pmu.D2A_VDDAO_VR85DENA;
    event e_vdd85a_on, e_vdd85a_off;
    event e_vdd85d_on, e_vdd85d_off;

    initial begin
        #3;
        supply_on("SS_VDD85D.ground", 0.0);
        supply_on("SS_VDDAO.ground", 0.0);
        supply_on("SS_VDD85A.ground", 0.0);
        supply_on("SS_VDD85A_IP.ground", 0.0);
        supply_on("SS_VDD33.ground", 0.0);
        supply_on("SS_VDDRR0.ground", 0.0);
        supply_on("SS_VDDRR1.ground", 0.0);
        supply_on("SS_VDD25.ground", 0.0);
        supply_on("SS_USBVCC33.ground", 0.0);
        supply_on("SS_USBVCCCORE.ground", 0.0);
        supply_on("SS_ADCAVDD.ground", 0.0);
        supply_on("SS_QFCPAD.ground", 0.0);
        supply_on("SS_APAD.ground", 0.0);
        supply_on("SS_BCPAD.ground", 0.0);
        supply_on("SS_DPAD.ground", 0.0);
        supply_on("SS_EPAD.ground", 0.0);
        supply_on("SS_AOPAD.ground", 0.0);
        supply_on("SS_TESTPAD.ground", 0.0);
        supply_on("SS_PLL09VPAD.ground", 0.0);
        supply_on("SS_PLL25VPAD.ground", 0.0);

        supply_on("SS_VDD85D.power", 0.81);
        supply_on("SS_VDDAO.power", 0.72);
        supply_on("SS_VDD85A.power", 0.81);
        supply_on("SS_VDD85A_IP.power", 0.72);
        supply_on("SS_VDD33.power", 2.97);
        supply_on("SS_VDDRR0.power", 3.63);
        supply_on("SS_VDDRR1.power", 3.63);
        supply_on("SS_VDD25.power", 2.5);
        supply_on("SS_USBVCC33.power", 2.97);
        supply_on("SS_USBVCCCORE.power", 0.81);
        supply_on("SS_ADCAVDD.power", 0.81);
        supply_on("SS_QFCPAD.power", 2.97);
        supply_on("SS_APAD.power", 2.97);
        supply_on("SS_BCPAD.power", 2.97);
        supply_on("SS_DPAD.power", 2.97);
        supply_on("SS_EPAD.power", 2.97);
        supply_on("SS_AOPAD.power", 2.97);
        supply_on("SS_TESTPAD.power", 2.97);
        supply_on("SS_PLL09VPAD.power", 0.72);
        supply_on("SS_PLL25VPAD.power", 2.5);

        wait (syscnt == 500);

        forever begin
            @(aopdreg) begin
                if (aopdreg === 1) begin
                    #3;
                    -> e_vdd85d_off;
                    -> e_vdd85a_off;
                    $display("%t -- %m: INFO: Normal -> Low Power\n", $time);
                    supply_off("SS_VDD85D.power");
                    supply_off("SS_VDD85A.power");
                    supply_off("SS_VDD85A_IP.power");
                    supply_off("SS_USBVCCCORE.power");
                    supply_off("SS_PLL09VPAD.power");
                end
                else if (aopdreg === 0) begin
                    -> e_vdd85d_on;
                    -> e_vdd85a_on;
                    $display("%t -- %m: INFO: Low Power -> Normal\n", $time);
                    supply_on("SS_VDD85D.power", 0.81);
                    supply_on("SS_VDD85A.power", 0.81);
                    supply_on("SS_VDD85A_IP.power", 0.72);
                    supply_on("SS_USBVCCCORE.power", 0.81);
                    supply_on("SS_PLL09VPAD.power", 0.72);

                    #1;
    `ifdef TC_0P9V_25C
                    sram_set_trim_0p9v_wakeup;
    `elsif BC_0P9V
                    sram_set_trim_0p9v_wakeup;
    `elsif WC_0P9V
                    sram_set_trim_0p9v_wakeup;
    `else
                    sram_set_trim_0p8v_wakeup;
    `endif
                end //else if (aopdreg === 0) begin
            end //@(aopdreg) begin
        end //forever
    end
`endif //SIM_UPF


// ======================
// fsdb generation
// ======================

`ifdef QFCFSDB		//module level debug

    initial begin
        $fsdbDumpfile("sdvt_spi_master_core.dumpfile.fsdb");
        $fsdbDumpvars(2, "+all", daric_top_tb.dut.soc.soc_coresub.qfc.u);
        $fsdbDumpflush; 
        $fsdbDumpon; 
 //     #(7.08 `MS) force dut.soc.soc_coresub.__coresys.cm7sys.coreresetn = 1'b0;
 //     #(0.50 `MS) release dut.soc.soc_coresub.__coresys.cm7sys.coreresetn;
 //     #(7.10 `MS) force daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.cm7top.nPORESET = 1'b0;
 //     #(0.01 `MS) force daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.cm7top.nPORESET = 1'b1;
    end

`endif

`ifdef AO_SIM_FSDB
    `ifdef AO_RTC_PWRDWN_FSDB
    initial begin
        $fsdbDumpfile("ao_sim.fsdb");
        $fsdbDumpvars(0, "+all", daric_top_tb);
        $fsdbDumpoff;
        wait (syscnt == 8031);
        $display("%t -- %m: INFO: Starting fsdb dump at syscnt = %d", $time, syscnt);
        $fsdbDumpon;
        wait (syscnt == 10000);
        $display("%t -- %m: INFO: Stopping fsdb dump at syscnt = %d", $time, syscnt);
        $fsdbDumpoff;
    end
    `else
    initial begin
        $fsdbDumpfile("ao_sim.fsdb");
        $fsdbDumpvars(3, "+all", daric_top_tb.dut.ao);
        $fsdbDumpvars(2, "+all", daric_top_tb);
        $fsdbDumpflush;
        $fsdbDumpon;
    end
    `endif //AO_RTC_PWRDWN_FSDB
`endif

`ifdef DUMP_PWR_VCD
    initial begin
        $dumpfile("daric_power.vcd");
        $dumpvars(0, daric_top_tb.dut);
        $dumpoff;
        //wait (syscnt == 2645);
        wait (syscnt == 2357);
        $display("%t -- %m: INFO: Starting vcd dump at syscnt = %d", $time, syscnt);
        $dumpon;
        wait (syscnt == 2358);
        $display("%t -- %m: INFO: Stopping vcd dump at syscnt = %d", $time, syscnt);
        $dumpoff;
    end
`endif

// ======================
// memory initialization
// ======================

    initial resetn = 0;
    initial clk = 0;
    initial clkswd = 0;

    integer fd;
    string MEMFILE = "testdata.bin";
    string MEMFILE_INF1 = "/work/daric/repo/frontend_release/asic_top/testbench/cp_ifren1.txt";

    parameter MEMDEPTH = 2**19;
    parameter DATAWIDTH = 64;
    localparam DATA_BYTES = 8;

    reg  [DATAWIDTH-1:0]    data;
    reg  [63:0]  data0,data1,data2,data3,data_i;
    reg   [63:0] bin_data0,bin_data1,bin_data2,bin_data3;
    reg  [255:0] reram_source;
    bit  [255:0] probe_reram_data;
    bit  [143:0] reram_data0,reram_data1;
    integer r,r0,r1,r2,r3;
    bit [143:0] probe_r0;
    bit [143:0] probe_r1;
    bit [255:0] probe_nvr0, probe_nvr1;

    logic ifmeminitflag=0;
    nvrcfg_pkg::nvrcms_t thenvrcms = nvrcfg_pkg::defnvrcms;
    nvrcfg_pkg::nvripm_t thenvripm = nvrcfg_pkg::defnvripm;
    nvrcfg_pkg::nvrcfg_t thenvrcfg = nvrcfg_pkg::defnvrcfg;
    logic [0:31][255:0] thenvrdat;
    assign thenvrdat = { thenvrcms, thenvripm, thenvrcfg};
    logic [0:31][255:0] thenvrdat0;

`ifndef FPGA

    generate
        for (genvar gvi = 0; gvi < 32; gvi++) begin
        /* code */
        assign thenvrdat0[gvi] = {
                        dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[gvi][144:73],
                        dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[gvi][71:0],
                        dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[gvi][144:73],
                        dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[gvi][71:0]
        };

        end
    endgenerate

`endif

    initial begin

    // nvr cfg customization
    // =========================
        thenvrcms.cmsdata1 = cms_pkg::CMSDAT_TESTMODE;                      // liza cmsdata1 not used
        thenvripm.ipm0 = 256'h190f0000_e7df4435_23d32435_7e20a435_6a428c35_6a428c35_80010203_04050607;
        thenvrcfg.cfgcore.devena = nvrcfg_pkg::cpudevmode;                  // to enable the dev mode

    `ifndef DISABLE_CM7
        thenvrcfg.cfgcore.coreselcm7 = nvrcfg_pkg::coreselcm7_code;         // to enable the cm7
    `else
        thenvrcfg.cfgcore.coreselcm7 = '0;
    `endif

    `ifdef ENABLE_RV32
        thenvrcfg.cfgcore.coreselvex = nvrcfg_pkg::coreselvex_code;
        thenvrcfg.cfgrrsub.m7_init = 'hC0;                                  // boot the CM7 from 0x6030_0000
    `else
        thenvrcfg.cfgcore.coreselvex = '0;                                  // nvrcfg_pkg::coreselvex_code  to enable the rv
    `endif

    //  init rram main
    // =====================
    $display("%t -- %m: INFO: Open MEMFILE = %s", $time, MEMFILE);
    fd = $fopen(MEMFILE,"rb");
    #(10 `US );

//  for(i = 0; (i < MEMDEPTH) && ($fread(data,fd) != -1); i = i + 1)
    for(i = 0; (i < MEMDEPTH ) ; i = i + 1)
    begin
        `ifdef FPGA
            r = $fread(data,fd);
            if( i < 4096 ) begin
                dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[0].FIRST.u0.mem[i] = swizzle(data);
                $display("%d, %016x, %d",i,dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[0].FIRST.u0.mem[i],r);
            end
            else if( i < 4096*2 ) begin
                dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[1].MIDDLE.um.mem[i&4095] = swizzle(data);
                $display("%d, %016x, %d",i,dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[1].MIDDLE.um.mem[i&4095],r);
            end
            else if( i < 4096*3 ) begin
                dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[2].MIDDLE.um.mem[i&4095] = swizzle(data);
                $display("%d, %016x, %d",i,dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[2].MIDDLE.um.mem[i&4095],r);
            end
            else if( i < 4096*4 ) begin
                dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[3].MIDDLE.um.mem[i&4095] = swizzle(data);
                $display("%d, %016x, %d",i,dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[3].MIDDLE.um.mem[i&4095],r);
            end
        `else
            #0.01;
            r0 = $fread(data0,fd);
            #0.01;
            r1 = $fread(data1,fd);
            #0.01;
            r2 = $fread(data2,fd);
            #0.01;
            r3 = $fread(data3,fd);
            #0.01;
            bin_data0 = swizzle(data0);
            #0.01;
            bin_data1 = swizzle(data1);
            #0.01;
            bin_data2 = swizzle(data2);
            #0.01;
            bin_data3 = swizzle(data3);
//          data = {data3,data2,data1,data0};
//          dut.soc.soc_coresub.rrc.emuram.ramdat[i] = swizzle(data);
//          $display("%d, %016x, %d",i,dut.soc.soc_coresub.rrc.emuram.ramdat[i],r);
            #0.01;
            reram_source = {swizzle(data3),swizzle(data2),swizzle(data1),swizzle(data0)};
            #0.01;
            reram_data0 = rram_encoder(reram_source[127:0],1);
            reram_data1 = rram_encoder(reram_source[255:128],1);

            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
            #0.01;
        `endif
    end

    `ifndef FPGA
    //  init rram ifr
    // =====================
    #0.01;
    ifmeminitflag = 1;

    $readmemh(MEMFILE_INF1,dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren1_mem);
    $readmemh(MEMFILE_INF1,dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren1_mem);

    for (int i = 0; i < 32; i++) begin
        #0.01;
        reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
        reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
        #0.01;
        dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
        dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
    end
    ifmeminitflag = 0;

    `endif

    $fclose(fd);
    $write("RAM: image max    = %d lines\n",i);

    `ifdef SIMMODE
        $display("defualt test case - different mode settings scan");
        daric_mode_scan;
		$finish;
    `endif

    `ifdef SIMINF
        rrc_cfg_rrsub_size_rw;
    `endif

    `ifdef SIM_RRAM_DOUT_ERROR
        force dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.DOUT[0] = 1'b0;
        force dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.DOUT[0] = 1'b1;
    `endif

    end //initial

`ifdef SIM_UPF
    event e_init_reram;
    always @(negedge daric_top_tb.dut.ao.aosc.ao_iso_enable) begin
        if (syscnt > 3000) begin
            #1;
            $display("%t -- %m: INFO: syscnt = %d", $time, syscnt);
            -> e_init_reram;
            // nvr cfg customization
            // =========================
                thenvrcms.cmsdata1 = cms_pkg::CMSDAT_TESTMODE;                      // liza cmsdata1 not used
                thenvripm.ipm0 = 256'h190f0000_e7df4435_23d32435_7e20a435_6a428c35_6a428c35_80010203_04050607;
                thenvrcfg.cfgcore.devena = nvrcfg_pkg::cpudevmode;                  // to enable the dev mode

            `ifndef DISABLE_CM7
                thenvrcfg.cfgcore.coreselcm7 = nvrcfg_pkg::coreselcm7_code;         // to enable the cm7
            `else
                thenvrcfg.cfgcore.coreselcm7 = '0;
            `endif

            `ifdef ENABLE_RV32
                thenvrcfg.cfgcore.coreselvex = nvrcfg_pkg::coreselvex_code;
                thenvrcfg.cfgrrsub.m7_init = 'hC0;                                  // boot the CM7 from 0x6030_0000
            `else
                thenvrcfg.cfgcore.coreselvex = '0;                                  // nvrcfg_pkg::coreselvex_code  to enable the rv
            `endif

            //  init rram main
            // =====================
            $display("%t -- %m: INFO: Open MEMFILE = %s", $time, MEMFILE);
            fd = $fopen(MEMFILE,"rb");
            #(10 `US );

            for(i = 0; (i < MEMDEPTH ) ; i = i + 1)
            begin
                `ifdef FPGA
                    r = $fread(data,fd);
                    if( i < 4096 ) begin
                        dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[0].FIRST.u0.mem[i] = swizzle(data);
                        $display("%d, %016x, %d",i,dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[0].FIRST.u0.mem[i],r);
                    end
                    else if( i < 4096*2 ) begin
                        dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[1].MIDDLE.um.mem[i&4095] = swizzle(data);
                        $display("%d, %016x, %d",i,dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[1].MIDDLE.um.mem[i&4095],r);
                    end
                    else if( i < 4096*3 ) begin
                        dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[2].MIDDLE.um.mem[i&4095] = swizzle(data);
                        $display("%d, %016x, %d",i,dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[2].MIDDLE.um.mem[i&4095],r);
                    end
                    else if( i < 4096*4 ) begin
                        dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[3].MIDDLE.um.mem[i&4095] = swizzle(data);
                        $display("%d, %016x, %d",i,dut.soc.soc_coresub.rrc.emuram.gencolmn[0].genrow[3].MIDDLE.um.mem[i&4095],r);
                    end
                `else
                    #0.01;
                    r0 = $fread(data0,fd);
                    #0.01;
                    r1 = $fread(data1,fd);
                    #0.01;
                    r2 = $fread(data2,fd);
                    #0.01;
                    r3 = $fread(data3,fd);
                    #0.01;
                    bin_data0 = swizzle(data0);
                    #0.01;
                    bin_data1 = swizzle(data1);
                    #0.01;
                    bin_data2 = swizzle(data2);
                    #0.01;
                    bin_data3 = swizzle(data3);
                    #0.01;
                    reram_source = {swizzle(data3),swizzle(data2),swizzle(data1),swizzle(data0)};
                    #0.01;
                    reram_data0 = rram_encoder(reram_source[127:0],1);
                    reram_data1 = rram_encoder(reram_source[255:128],1);

                    #0.01;
                    dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
                    dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
                    #0.01;
                `endif
            end

            `ifndef FPGA
            //  init rram ifr
            // =====================
            #0.01;
            ifmeminitflag = 1;

            $readmemh(MEMFILE_INF1,dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren1_mem);
            $readmemh(MEMFILE_INF1,dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren1_mem);

            for (int i = 0; i < 32; i++) begin
                #0.01;
                reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
                reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
                #0.01;
                dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
                dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
            end
            ifmeminitflag = 0;

            `endif

            $fclose(fd);
            $write("RAM: image max    = %d lines\n",i);
        end // if (syscnt > 500) begin
    end // always @(e_pwr_on) begin
`endif //SIM_UPF


// ======================
// function declaration
// ======================

// big endianness of $fread
// ==========================

    function [DATAWIDTH-1:0] swizzle;
        input [DATAWIDTH-1:0] data_in;
        integer i;
        begin
            for (i=0; i<DATA_BYTES; i=i+1)
                swizzle[i*8 +:8] = data_in[(DATA_BYTES-1-i)*8 +:8];
        end
    endfunction


`ifndef  FPGA

    function [143:0] rram_encoder;
        input [127:0] messg;
        input mode;
        bit [15:0] parity;

        parity[0]=    messg[0]^    messg[2]^    messg[3]^    messg[4]^    messg[5]^    messg[6]^    messg[12]^    messg[14]^    messg[15]^
                      messg[16]^    messg[18]^    messg[19]^    messg[20]^    messg[21]^    messg[26]^    messg[28]^    messg[31]^    messg[37]^
        messg[38]^    messg[39]^    messg[40]^    messg[42]^    messg[43]^    messg[44]^    messg[46]^    messg[48]^    messg[49]^    messg[51]^
        messg[52]^    messg[53]^    messg[63]^    messg[65]^    messg[66]^    messg[69]^    messg[70]^    messg[71]^    messg[72]^    messg[73]^
        messg[75]^    messg[76]^    messg[77]^    messg[79]^    messg[82]^    messg[84]^    messg[87]^    messg[89]^    messg[91]^    messg[93]^
        messg[97]^    messg[98]^    messg[101]^    messg[107]^    messg[110]^    messg[111]^    messg[112]^    messg[120]^    messg[121]^
        messg[123]^    messg[124]^    messg[125];

        parity[1]=    messg[0]^    messg[1]^    messg[2]^    messg[7]^    messg[8]^    messg[12]^    messg[13]^    messg[14]^    messg[17]^
        messg[20]^    messg[22]^    messg[24]^    messg[26]^    messg[27]^    messg[28]^    messg[29]^    messg[31]^    messg[32]^    messg[37]^
        messg[41]^    messg[45]^    messg[46]^    messg[47]^    messg[48]^    messg[54]^    messg[57]^    messg[63]^    messg[64]^    messg[65]^
        messg[67]^    messg[73]^    messg[74]^    messg[75]^    messg[78]^    messg[79]^    messg[80]^    messg[82]^    messg[83]^    messg[84]^
        messg[85]^    messg[86]^    messg[87]^    messg[88]^    messg[89]^    messg[90]^    messg[91]^    messg[92]^    messg[93]^    messg[94]^
        messg[96]^    messg[97]^    messg[98]^    messg[99]^    messg[101]^    messg[102]^    messg[107]^    messg[108]^    messg[113]^
        messg[120]^    messg[121]^    messg[122]^    messg[123]^    messg[126]^    messg[127];

        parity[2]=    messg[1]^    messg[2]^    messg[3]^    messg[8]^    messg[9]^    messg[13]^    messg[14]^    messg[15]^    messg[18]^
        messg[20]^    messg[21]^    messg[23]^    messg[27]^    messg[28]^    messg[29]^    messg[30]^    messg[32]^    messg[33]^    messg[38]^
        messg[47]^    messg[48]^    messg[49]^    messg[50]^    messg[51]^    messg[54]^    messg[58]^    messg[64]^    messg[65]^    messg[66]^
        messg[73]^    messg[74]^    messg[75]^    messg[76]^    messg[79]^    messg[80]^    messg[81]^    messg[83]^    messg[86]^    messg[87]^
        messg[89]^    messg[90]^    messg[91]^    messg[92]^    messg[93]^    messg[94]^    messg[95]^    messg[96]^    messg[97]^    messg[99]^
        messg[102]^    messg[103]^    messg[105]^    messg[108]^    messg[109]^    messg[110]^    messg[114]^    messg[122]^    messg[123]^
        messg[124]^    messg[127];

        parity[3]=     messg[2]^    messg[3]^    messg[4]^    messg[8]^    messg[9]^    messg[10]^    messg[14]^    messg[15]^    messg[16]^
        messg[19]^    messg[21]^    messg[22]^    messg[24]^    messg[25]^    messg[28]^    messg[29]^    messg[30]^    messg[32]^    messg[33]^
        messg[34]^    messg[39]^    messg[46]^    messg[48]^    messg[49]^    messg[50]^    messg[52]^    messg[54]^    messg[57]^    messg[59]^
        messg[65]^    messg[66]^    messg[67]^    messg[68]^    messg[69]^    messg[74]^    messg[75]^    messg[76]^    messg[77]^    messg[80]^
        messg[81]^    messg[82]^    messg[84]^    messg[85]^    messg[86]^    messg[87]^    messg[88]^    messg[90]^    messg[91]^    messg[92]^
        messg[93]^    messg[94]^    messg[95]^    messg[97]^    messg[98]^    messg[102]^    messg[103]^    messg[104]^    messg[106]^
        messg[109]^    messg[111]^    messg[114]^    messg[115]^    messg[121]^    messg[123]^    messg[124]^    messg[125]^    messg[127];

        parity[4]=    messg[3]^    messg[4]^    messg[5]^    messg[9]^    messg[10]^    messg[11]^    messg[15]^    messg[16]^    messg[17]^    messg[18]^
        messg[22]^    messg[23]^    messg[26]^    messg[29]^    messg[30]^    messg[33]^    messg[34]^    messg[35]^    messg[40]^    messg[42]^    messg[46]^    messg[47]^
        messg[49]^    messg[50]^    messg[53]^    messg[55]^    messg[58]^    messg[60]^    messg[66]^    messg[67]^    messg[68]^    messg[70]^    messg[73]^
        messg[75]^    messg[76]^    messg[77]^    messg[78]^    messg[81]^    messg[82]^    messg[83]^    messg[84]^    messg[87]^    messg[88]^    messg[89]^
        messg[91]^    messg[92]^    messg[93]^    messg[94]^    messg[95]^    messg[96]^    messg[99]^    messg[102]^    messg[103]^    messg[104]^    messg[105]^
        messg[107]^    messg[110]^    messg[112]^    messg[114]^    messg[115]^    messg[116]^    messg[121]^    messg[122]^    messg[124]^    messg[125]^    messg[126];

        parity[5]=    messg[0]^    messg[2]^    messg[3]^    messg[10]^    messg[11]^    messg[14]^    messg[15]^    messg[17]^    messg[18]^
        messg[20]^    messg[21]^    messg[23]^    messg[24]^    messg[25]^    messg[26]^    messg[27]^    messg[28]^    messg[30]^    messg[32]^
        messg[34]^    messg[35]^    messg[36]^    messg[37]^    messg[38]^    messg[39]^    messg[40]^    messg[42]^    messg[44]^    messg[46]^    messg[47]^
        messg[49]^    messg[52]^    messg[53]^    messg[55]^    messg[56]^    messg[59]^    messg[61]^    messg[63]^    messg[65]^    messg[66]^
        messg[67]^    messg[68]^    messg[70]^    messg[72]^    messg[74]^    messg[75]^    messg[78]^    messg[83]^    messg[84]^    messg[85]^    messg[86]^    messg[87]^
        messg[88]^    messg[90]^    messg[91]^    messg[92]^    messg[94]^    messg[95]^    messg[96]^    messg[100]^    messg[101]^    messg[102]^
        messg[103]^    messg[104]^    messg[105]^    messg[106]^    messg[107]^    messg[108]^    messg[112]^    messg[113]^    messg[115]^    messg[116]^
        messg[117]^    messg[120]^    messg[121]^    messg[122]^    messg[124]^    messg[126];

        parity[6]=    messg[0]^    messg[1]^    messg[2]^    messg[5]^    messg[6]^    messg[8]^    messg[11]^    messg[14]^    messg[22]^    messg[24]^    messg[27]^
        messg[29]^    messg[32]^    messg[33]^    messg[35]^    messg[36]^    messg[45]^    messg[47]^    messg[49]^    messg[50]^    messg[51]^
        messg[52]^    messg[54]^    messg[55]^    messg[56]^    messg[57]^    messg[60]^    messg[62]^    messg[63]^    messg[64]^    messg[65]^
        messg[67]^    messg[69]^    messg[70]^    messg[72]^    messg[73]^    messg[77]^    messg[82]^    messg[86]^    messg[92]^    messg[95]^
        messg[100]^    messg[103]^    messg[104]^    messg[105]^    messg[106]^    messg[108]^    messg[109]^    messg[111]^    messg[112]^    messg[113]^
        messg[116]^    messg[117]^    messg[118]^    messg[120]^    messg[121]^    messg[122]^    messg[124];

        parity[7]=    messg[1]^    messg[2]^    messg[3]^    messg[6]^    messg[7]^    messg[8]^    messg[9]^    messg[12]^    messg[15]^    messg[20]^
        messg[23]^    messg[24]^    messg[25]^    messg[28]^    messg[30]^    messg[31]^    messg[32]^    messg[33]^    messg[34]^    messg[36]^
        messg[37]^    messg[42]^    messg[44]^    messg[48]^    messg[51]^    messg[52]^    messg[53]^    messg[54]^    messg[56]^    messg[58]^    messg[61]^
        messg[63]^    messg[64]^    messg[65]^    messg[66]^    messg[68]^    messg[70]^    messg[71]^    messg[73]^    messg[74]^    messg[78]^
        messg[83]^    messg[84]^    messg[87]^    messg[93]^    messg[98]^    messg[101]^    messg[102]^    messg[104]^    messg[105]^    messg[106]^
        messg[107]^    messg[109]^    messg[110]^    messg[112]^    messg[113]^    messg[114]^    messg[117]^    messg[118]^
        messg[119]^    messg[122]^    messg[123]^    messg[125];

        parity[8]=    messg[0]^    messg[5]^    messg[6]^    messg[7]^    messg[9]^    messg[10]^    messg[12]^    messg[13]^    messg[14]^    messg[15]^    messg[19]^
        messg[25]^    messg[28]^    messg[29]^    messg[32]^    messg[33]^    messg[34]^    messg[35]^    messg[39]^    messg[40]^    messg[44]^    messg[45]^
        messg[48]^    messg[59]^    messg[62]^    messg[63]^    messg[64]^    messg[67]^    messg[70]^    messg[73]^    messg[74]^    messg[76]^    messg[77]^
        messg[82]^    messg[84]^    messg[87]^    messg[89]^    messg[91]^    messg[93]^    messg[94]^    messg[96]^    messg[97]^    messg[99]^    messg[100]^
        messg[101]^    messg[102]^    messg[103]^    messg[106]^    messg[108]^    messg[112]^    messg[113]^    messg[115]^
        messg[118]^    messg[119]^    messg[120]^    messg[125]^    messg[126];

        parity[9]=    messg[0]^    messg[1]^    messg[2]^    messg[3]^    messg[4]^    messg[5]^    messg[7]^    messg[10]^    messg[11]^    messg[12]^    messg[13]^
        messg[19]^    messg[20]^    messg[21]^    messg[24]^    messg[25]^    messg[28]^    messg[29]^    messg[30]^    messg[31]^    messg[33]^    messg[34]^
        messg[35]^    messg[36]^    messg[37]^    messg[38]^    messg[39]^    messg[41]^    messg[43]^    messg[45]^    messg[48]^    messg[50]^
        messg[51]^    messg[52]^    messg[53]^    messg[54]^    messg[55]^    messg[60]^    messg[64]^    messg[66]^    messg[69]^    messg[70]^    messg[72]^
        messg[74]^    messg[76]^    messg[78]^    messg[79]^    messg[82]^    messg[83]^    messg[86]^    messg[87]^    messg[89]^    messg[90]^
        messg[91]^    messg[92]^    messg[93]^    messg[94]^    messg[95]^    messg[96]^    messg[103]^    messg[104]^    messg[105]^    messg[109]^    messg[110]^
        messg[111]^    messg[112]^    messg[113]^    messg[114]^    messg[116]^    messg[119]^    messg[123]^    messg[124]^    messg[125]^    messg[126]^    messg[127];

        parity[10]=    messg[0]^    messg[1]^    messg[11]^    messg[13]^    messg[15]^    messg[16]^    messg[19]^    messg[22]^    messg[24]^    messg[28]^
        messg[29]^    messg[30]^    messg[32]^    messg[34]^    messg[35]^    messg[36]^    messg[42]^    messg[43]^    messg[46]^    messg[48]^    messg[54]^
        messg[55]^    messg[56]^    messg[57]^    messg[61]^    messg[63]^    messg[66]^    messg[67]^    messg[68]^    messg[69]^    messg[72]^    messg[73]^
        messg[76]^    messg[80]^    messg[82]^    messg[83]^    messg[84]^    messg[86]^    messg[89]^    messg[90]^    messg[92]^    messg[94]^    messg[95]^
        messg[96]^    messg[98]^    messg[101]^    messg[104]^    messg[105]^    messg[106]^    messg[107]^    messg[113]^    messg[115]^    messg[117]^
        messg[121]^    messg[123]^    messg[126];

        parity[11]=    messg[0]^    messg[1]^    messg[3]^    messg[4]^    messg[5]^    messg[6]^    messg[15]^    messg[17]^    messg[19]^    messg[20]^    messg[21]^
        messg[23]^    messg[25]^    messg[26]^    messg[28]^    messg[29]^    messg[30]^    messg[31]^    messg[32]^    messg[33]^    messg[35]^
        messg[36]^    messg[38]^    messg[39]^    messg[40]^    messg[41]^    messg[44]^    messg[46]^    messg[47]^    messg[48]^    messg[50]^
        messg[51]^    messg[52]^    messg[53]^    messg[54]^    messg[56]^    messg[58]^    messg[62]^    messg[63]^    messg[64]^    messg[65]^
        messg[66]^    messg[67]^    messg[68]^    messg[69]^    messg[71]^    messg[72]^    messg[74]^    messg[75]^    messg[76]^    messg[79]^
        messg[81]^    messg[82]^    messg[83]^    messg[85]^    messg[86]^    messg[89]^    messg[90]^    messg[95]^    messg[99]^    messg[101]^
        messg[106]^    messg[108]^    messg[110]^    messg[111]^    messg[112]^    messg[116]^    messg[118]^    messg[122]^    messg[123]^    messg[125];

        parity[12]=    messg[1]^    messg[2]^    messg[4]^    messg[5]^    messg[6]^    messg[7]^    messg[8]^    messg[16]^    messg[18]^    messg[21]^
        messg[22]^    messg[25]^    messg[26]^    messg[27]^    messg[29]^    messg[30]^    messg[31]^    messg[33]^    messg[34]^    messg[36]^
        messg[37]^    messg[39]^    messg[40]^    messg[41]^    messg[45]^    messg[46]^    messg[47]^    messg[48]^    messg[49]^    messg[50]^
        messg[52]^    messg[53]^    messg[55]^    messg[59]^    messg[63]^    messg[64]^    messg[65]^    messg[66]^    messg[67]^    messg[70]^
        messg[72]^    messg[75]^    messg[76]^    messg[77]^    messg[80]^    messg[82]^    messg[83]^    messg[84]^    messg[86]^    messg[87]^
        messg[88]^    messg[90]^    messg[91]^    messg[100]^    messg[102]^    messg[105]^    messg[107]^    messg[109]^    messg[110]^    messg[111]^
        messg[112]^    messg[113]^    messg[117]^    messg[119]^    messg[123]^    messg[124]^    messg[126];

        parity[13]=    messg[0]^    messg[4]^    messg[7]^    messg[9]^    messg[12]^    messg[14]^    messg[15]^    messg[16]^    messg[17]^    messg[18]^
        messg[20]^    messg[21]^    messg[22]^    messg[23]^    messg[24]^    messg[27]^    messg[30]^    messg[34]^    messg[35]^    messg[39]^
        messg[41]^    messg[43]^    messg[44]^    messg[46]^    messg[47]^    messg[50]^    messg[52]^    messg[55]^    messg[56]^    messg[60]^
        messg[63]^    messg[64]^    messg[67]^    messg[68]^    messg[70]^    messg[72]^    messg[73]^    messg[75]^    messg[78]^    messg[79]^
        messg[81]^    messg[82]^    messg[83]^    messg[86]^    messg[92]^    messg[93]^    messg[96]^    messg[97]^    messg[103]^    messg[106]^
        messg[107]^    messg[108]^    messg[110]^    messg[113]^    messg[118]^    messg[120]^    messg[121]^    messg[123];

        parity[14]=    messg[0]^    messg[1]^    messg[2]^    messg[3]^    messg[4]^    messg[6]^    messg[10]^    messg[12]^    messg[13]^
        messg[14]^    messg[17]^    messg[18]^    messg[22]^    messg[23]^    messg[26]^    messg[35]^    messg[36]^    messg[37]^    messg[38]^
        messg[39]^    messg[42]^    messg[43]^    messg[45]^    messg[46]^    messg[47]^    messg[49]^    messg[51]^    messg[52]^    messg[55]^
        messg[56]^    messg[61]^    messg[63]^    messg[64]^    messg[66]^    messg[69]^    messg[70]^    messg[72]^    messg[73]^    messg[74]^
        messg[75]^    messg[77]^    messg[80]^    messg[83]^    messg[86]^    messg[89]^    messg[91]^    messg[94]^    messg[96]^    messg[101]^
        messg[104]^    messg[105]^    messg[108]^    messg[109]^    messg[110]^    messg[112]^    messg[119]^    messg[121]^
        messg[122]^    messg[123]^    messg[125];

        parity[15]=    messg[1]^    messg[2]^    messg[3]^    messg[4]^    messg[5]^    messg[7]^    messg[11]^    messg[13]^    messg[14]^    messg[15]^
        messg[18]^    messg[19]^    messg[20]^    messg[23]^    messg[25]^    messg[27]^    messg[31]^    messg[36]^    messg[37]^    messg[38]^
        messg[39]^    messg[40]^    messg[41]^    messg[42]^    messg[43]^    messg[47]^    messg[48]^    messg[50]^    messg[51]^    messg[52]^
        messg[53]^    messg[56]^    messg[62]^    messg[64]^    messg[65]^    messg[67]^    messg[68]^    messg[69]^    messg[70]^    messg[71]^
        messg[74]^    messg[75]^    messg[76]^    messg[78]^    messg[81]^    messg[84]^    messg[85]^    messg[86]^    messg[87]^    messg[88]^
        messg[90]^    messg[92]^    messg[95]^    messg[96]^    messg[97]^    messg[100]^    messg[106]^    messg[109]^    messg[110]^    messg[111]^
        messg[113]^    messg[122]^    messg[123]^    messg[124]^    messg[126]^    messg[127];

        rram_encoder =(mode)?({parity,messg}):(144'd0);

    endfunction

    function ifr_cfg;
        input [4:0]     ifr_index;
        input [255:0]   ifr_data;
        bit   [143:0]   ifr_data0, ifr_data1;

        ifr_data0 = rram_encoder(ifr_data[127:0],1);
        ifr_data1 = rram_encoder(ifr_data[255:128],1);
        
        dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[ifr_index] = {1'b0,ifr_data0[143:72],1'b0,ifr_data0[71:0]};
        dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[ifr_index] = {1'b0,ifr_data1[143:72],1'b0,ifr_data1[71:0]};

    endfunction

// ======================
// debug probe
// ======================

    assign probe_r0 = {dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.main_mem[0][144:73],
                      dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.main_mem[0][71:0]};

    assign probe_r1 = {dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.main_mem[0][144:73],
                      dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.main_mem[0][71:0]};

    assign probe_nvr0 = thenvrdat[0];
    assign probe_nvr1 = thenvrdat[1];

    assign probe_reram_data = {probe_r1[127:0],probe_r0[127:0]};


// ======================
// task declaration
// ======================

task daric_mode_scan;

        #(4 `MS);

        $display("start the virgin mode @ cp life cycle");

        thenvrcms.cmsdata0 = cms_pkg::CMSDAT_VRGNMODE;
        thenvripm.ipm0 = 256'h0;
        cmspad = {1'b1, 1'b1, 1'b0};

        #(1 `US) padresetn = 0;
        #(10 `US) padresetn = 1;

        // IFR region intital
        #0.01;

        ifmeminitflag = 1;
        for (int i = 0; i < 16; i++) begin
            #0.01;
            reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
            reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;

        #(3 `MS);

        $display("start the test mode 1 @ cp life cycle");

        thenvripm.ipm0 = 256'h190f0000_e7df4435_23d32435_7e20a435_6a428c35_6a428c35_80010203_04050607;
        thenvrcms.cmsdata0 = cms_pkg::CMSDAT_TESTMODE;
        cmspad = {1'b1, 1'b1, 1'b0};

        #(1 `US) padresetn = 0;
        #(10 `US) padresetn = 1;

        // IFR region intital
        #0.01;

        ifmeminitflag = 1;
        for (int i = 0; i < 16; i++) begin
            #0.01;
            reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
            reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;

        #(3 `MS);

        $display("start the user mode 1 @ cp life cycle");

        thenvripm.ipm0 = 256'h190f0000_e7df4435_23d32435_7e20a435_6a428c35_6a428c35_80010203_04050607;
        thenvrcms.cmsdata0 = cms_pkg::CMSDAT_USERMODE;
        cmspad = {1'b1, 1'b1, 1'b0};

        #(1 `US) padresetn = 0;
        #(10 `US) padresetn = 1;

        // IFR region intital
        #0.01;

        ifmeminitflag = 1;
        for (int i = 0; i < 16; i++) begin
            #0.01;
            reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
            reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;

        #(3 `MS);

        $display("start the test mode 2 @ sample test life cycle");

        thenvrcms.cmsdata0 = {$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom()};      //not USER Pattern
        cmspad = {1'b0, 1'b0, 1'b1};

        #(1 `US) padresetn = 0; force daric_top_tb.dut.pmu.pwr_VDD = 0;
        #(10 `US) padresetn = 1; force daric_top_tb.dut.pmu.pwr_VDD = 1;

        // IFR region intital
        #0.01;

        ifmeminitflag = 1;
        for (int i = 0; i < 16; i++) begin
            #0.01;
            reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
            reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;

        #(3 `MS);

        $display("start the user mode 2 @ sample test life cycle");

        thenvrcms.cmsdata0 = cms_pkg::CMSDAT_USERMODE;
        cmspad = {1'b0, 1'b0, 1'b1};

        #(1 `US) padresetn = 0; force daric_top_tb.dut.pmu.pwr_VDD = 0;
        #(10 `US) padresetn = 1; force daric_top_tb.dut.pmu.pwr_VDD = 1;

        // IFR region intital
        #0.01;

        ifmeminitflag = 1;
        for (int i = 0; i < 16; i++) begin
            #0.01;
            reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
            reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;

        #(3 `MS);

        $display("start the user mode 3 @ production life cycle");

        thenvrcms.cmsdata0 = {$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom()};      //any Pattern
        cmspad = {1'b0, 1'b0, 1'b0};

        #(1 `US) padresetn = 0;
        #(10 `US) padresetn = 1;

        // IFR region intital
        #0.01;

        ifmeminitflag = 1;
        for (int i = 0; i < 16; i++) begin
            #0.01;
            reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
            reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;

        #(3 `MS);

        $display("start the suicide mode @ production life cycle by attack");

        thenvrcms.cmsdata0 = {$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom()};      //not USER/TEST/VRGN Pattern
        thenvripm.ipm0 = 256'h190f0000_e7df4435_23d32435_7e20a435_6a428c35_6a428c35_80010203_04050607;
        cmspad = {1'b1, 1'b1, 1'b0};

        #(1 `US) padresetn = 0;
        #(10 `US) padresetn = 1;

        // IFR region intital
        #0.01;

        ifmeminitflag = 1;
        for (int i = 0; i < 16; i++) begin
            #0.01;
            reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
            reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;

        #(30 `MS);

        $display("start none mode @ life cycle");

        thenvrcms.cmsdata0 = {$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom()};      //not USER/TEST/VRGN Pattern
        thenvripm.ipm0 = 256'h190f0000_e7df4435_23d32435_7e20a435_6a428c35_6a428c35_80010203_04050607;
        cmspad = {1'b0, 1'b0, 1'b0};                                                                                         //not test wms pad settings

        #(1 `US) padresetn = 0;
        #(10 `US) padresetn = 1;

        // IFR region intital
        #0.01;

        ifmeminitflag = 1;
        for (int i = 0; i < 16; i++) begin
            #0.01;
            reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
            reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;

        #(3 `MS);

        $display("start the atpg mode @ cp life cycle");

        thenvrcms.cmsdata0 = cms_pkg::CMSDAT_TESTMODE;
        thenvripm.ipm0 = 256'h190f0000_e7df4435_23d32435_7e20a435_6a428c35_6a428c35_80010203_04050607;
        cmspad = {1'b1, 1'b0, 1'b0};

        #(1 `US) padresetn = 0;
        #(10 `US) padresetn = 1;

        // IFR region intital
        #0.01;

        ifmeminitflag = 1;
        for (int i = 0; i < 16; i++) begin
            #0.01;
            reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
            reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
            #0.01;
            dut.soc.soc_coresub.greram_0__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram_1__reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;
		wait(daric_top_tb.dut.soc.cms.u_atpgmode_buf.Z);
		$display("::::::::  CMS  :::::::::: CMS_ATPG (5b)");

        #(4 `MS);

//		$reset;

endtask : daric_mode_scan

task rrc_cfg_rrsub_size_rw;

        #(4 `MS);

        $display("start reram inf region reram user size configuration!");

        ifr_cfg(5'd06, {128'h0,128'h00ff_0000_ffff_ffff_0000_ffff_ffff_0000});
        ifr_cfg(5'd20, {128'h0, 8'h3a,8'h96,8'hff,104'h0});                             // boot0: 6000->600F
        ifr_cfg(5'd21, {128'h0, 8'h3a,8'h96,8'hff,104'h0});                             // boot1: 6010->601F
        ifr_cfg(5'd22, {128'h0, 8'h3a,8'h96,8'hff,104'h0});                             // fw0  : 6020->602F
        ifr_cfg(5'd23, {8'h3a,8'h96,112'h0, 8'h3a,8'h96,8'hff,104'h0});                 // fw1  : 6030->603D, disabled test OEM access

        #(1 `US) padresetn = 0;
        #(10 `US) padresetn = 1;

        #(3 `MS);

        $display("sreram inf region reram user size configuration is done!");
//		$reset;

endtask : rrc_cfg_rrsub_size_rw

task sram_set_trim_0p9v;
        #(1 `MS);
        $display("testbench change sram trimmings @ 0.9V turbo mode!");
        ifr_cfg(5'd02, {64'h0000280061406140, 64'h6140614060004045, 64'h6000600061006100, 64'h6100610060006140});           // set all srams
        ifr_cfg(5'd03, {64'h00000fffffff8048, 64'h6140280028002800, 64'h2800280028006100, 64'h2800280028002800});           // enable trimmings

endtask : sram_set_trim_0p9v

task sram_set_trim_0p8v;
        #(1 `MS);
        $display("testbench change sram trimmings @ 0.8V regular mode!");
        ifr_cfg(5'd02, {64'h0000700080488048, 64'h804880488140804f, 64'h8140814081488148, 64'h8148814881408045});           // set all srams
        ifr_cfg(5'd03, {64'h00000fffffff8048, 64'h8045700070007000, 64'h7000700070008148, 64'h7000700070007000});           // enable trimmings 

endtask : sram_set_trim_0p8v

event e_wakeup_sram_trim;
task sram_set_trim_0p9v_wakeup;
        $display("testbench change sram trimmings @ 0.9V turbo mode (wakeup)!");
        ifr_cfg(5'd02, {64'h0000280061406140, 64'h6140614060004045, 64'h6000600061006100, 64'h6100610060006140});           // set all srams
        ifr_cfg(5'd03, {64'h00000fffffff8048, 64'h6140280028002800, 64'h2800280028006100, 64'h2800280028002800});           // enable trimmings
        -> e_wakeup_sram_trim;
endtask : sram_set_trim_0p9v_wakeup

task sram_set_trim_0p8v_wakeup;
        $display("testbench change sram trimmings @ 0.8V regular mode (wakeup)!");
        ifr_cfg(5'd02, {64'h0000700080488048, 64'h804880488140804f, 64'h8140814081488148, 64'h8148814881408045});           // set all srams
        ifr_cfg(5'd03, {64'h00000fffffff8048, 64'h8045700070007000, 64'h7000700070008148, 64'h7000700070007000});           // enable trimmings
        -> e_wakeup_sram_trim;
endtask : sram_set_trim_0p8v_wakeup

`endif //`ifndef  FPGA

`ifdef SIM_AO_WAKEUP
task automatic wakeup_ao (
    input int assert_lo_cnt,
    input int assert_hi_cnt
    );
    PF0reg = 1'b1;
    wait (syscnt == assert_lo_cnt);
    $display("\n%t -- %m: INFO: PF0 asserting to 0 -> wakeup\n", $time);
    PF0reg = 1'b0;
    wait (syscnt == assert_hi_cnt);
    PF0reg = 1'b1;
endtask : wakeup_ao
`endif


`ifndef SIM_NETLIST
// ======================
// axi behavioral model
// ======================
    wire                        hclk;
    wire                        axi_clk;
    wire                        axi_clken;
    wire                        axi_awready;
    wire [AXI_ID_WIDTH-1:0]	    axi_awid;
    wire [AXI_ADDR_WIDTH-1:0]   axi_awaddr;
    wire [AXI_LEN_WIDTH-1:0]    axi_awlen;    // Write Burst Length
    wire [2:0]                  axi_awsize;	  // Write Burst size
    wire [1:0]                  axi_awburst;  // Write Burst type
    wire [0:0]                  axi_awlock;   // Write lock type
    wire [3:0]                  axi_awcache;  // Write Cache type
    wire [2:0]                  axi_awprot;   // Write Protection type
    wire [3:0]                  axi_awqos;    // Write Quality of Svc
    wire                        axi_awvalid;  // Write address valid
    
// AXI write data channel signals
    wire                        axi_wready;   // Write data ready
    wire [AXI_DATA_WIDTH-1:0]   axi_wdata;    // Write data
    wire [AXI_DATA_WIDTH/8-1:0] axi_wstrb;    // Write strobes
    wire                        axi_wlast;    // Last write transaction
    wire                        axi_wvalid;   // Write valid
    
// AXI write response channel signals
    wire [AXI_ID_WIDTH-1:0]     axi_bid;      // Response ID
    wire [1:0]                  axi_bresp;    // Write response
    wire                        axi_bvalid;   // Write reponse valid
    wire                        axi_bready;   // Response ready
    
 // AXI read address channel signals
    wire                        axi_arready;  // Read address ready
    wire [AXI_ID_WIDTH-1:0]     axi_arid;     // Read ID
    wire [AXI_ADDR_WIDTH-1:0]   axi_araddr;   // Read address
    wire [AXI_LEN_WIDTH-1:0]    axi_arlen;    // Read Burst Length
    wire [2:0]                  axi_arsize;   // Read Burst size
    wire [1:0]                  axi_arburst;  // Read Burst type
    wire [0:0]                  axi_arlock;   // Read lock type
    wire [3:0]                  axi_arcache;  // Read Cache type
    wire [2:0]                  axi_arprot;   // Read Protection type
    wire [3:0]                  axi_arqos;    // Read Protection type
    wire                        axi_arvalid;  // Read address valid

// AXI read data channel signals
    wire [AXI_ID_WIDTH-1:0]     axi_rid;     // Response ID
    wire [1:0]		            axi_rresp;   // Read response
    wire                        axi_rvalid;  // Read reponse valid
    wire [AXI_DATA_WIDTH-1:0]   axi_rdata;   // Read data
    wire                        axi_rlast;   // Read last
    wire                        axi_rready;  // Read Response ready
    wire				        reset;
//  wire                        o_reset;
    wire                        wb_cyc;
    wire                        wb_stb;
    wire                        wb_we;
    wire [(AXI_ADDR_WIDTH-1):0]     wb_addr;
    wire [(AXI_DATA_WIDTH-1):0]     wb_indata;
    wire [(AXI_DATA_WIDTH-1):0]     wb_outdata;
    wire [(AXI_DATA_WIDTH/8-1):0]   wb_sel;
    wire                            wb_ack;
    wire                            wb_stall;
    wire                            wb_err;
    wire                            coreresetn;

    assign  axi_awready = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awready;
    assign  axi_awid = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awid;
    assign  axi_awaddr = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awaddr;
    assign  axi_awlen = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awlen;
    assign  axi_awsize = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awsize;
    assign  axi_awburst = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awburst;
    assign  axi_awlock = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awlock;
    assign  axi_awcache = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awcache;
    assign  axi_awprot = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awprot;
    assign  axi_awqos = 0;
    assign  axi_awvalid = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.awvalid;
    assign  axi_wready = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.wready;
    assign  axi_wdata = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.wdata;
    assign  axi_wstrb = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.wstrb;
    assign  axi_wlast = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.wlast;
    assign  axi_wvalid = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.wvalid;
    assign  axi_bid = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.bid;
    assign  axi_bresp = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.bresp;
    assign  axi_bvalid = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.bvalid;
    assign  axi_bready = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.bready;
    assign  axi_arready = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.arready;
    assign  axi_arid = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.arid;
    assign  axi_araddr = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.araddr;
    assign  axi_arlen = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.arlen;
    assign  axi_arsize = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.arsize;
    assign  axi_arburst = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.arburst;
    assign  axi_arlock = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.arlock;
    assign  axi_arcache = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.arcache;
    assign  axi_arprot = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.arprot;
    assign  axi_arqos = 0; 
    assign  axi_arvalid = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.arvalid;
    assign  axi_rid = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.rid;
    assign  axi_rresp = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.rresp;
    assign  axi_rvalid = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.rvalid;
    assign  axi_rdata = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.rdata;
    assign  axi_rlast = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.rlast;
    assign  axi_rready = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.axim.rready;
    assign  reset = !resetn;
    assign  axi_clk = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.cm7top.u_cortexm7.CLK;
    assign  axi_clken = daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.cm7top.u_cortexm7.ACLKEN;
    assign  coreresetn   = daric_top_tb.dut.soc.soc_coresub.coreresetn; 
    assign  hclk = daric_top_tb.dut.soc.soc_coresub.hclk;

// axi_if_bfm instantiation
    axi_if_bfm #(.AXI_ID_WIDTH (AXI_ID_WIDTH),
               .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
               .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
               .AXI_LEN_WIDTH  (AXI_LEN_WIDTH)
            ) axi_vif_mon (.clk   (axi_clk),
               .reset (reset),
               .clken (axi_clken),
               .aw_ready(axi_awready),
               .aw_id(axi_awid),
               .aw_addr(axi_awaddr),
               .aw_len(axi_awlen),
               .aw_size(axi_awsize),
               .aw_burst(axi_awburst),
               .aw_lock(axi_awlock),
               .aw_cache(axi_awcache),
               .aw_prot(axi_awprot),
               .aw_qos(axi_awqos),
               .aw_valid(axi_awvalid),

               .w_ready(axi_wready),
               .w_data(axi_wdata),
               .w_strb(axi_wstrb),
               .w_last(axi_wlast),
               .w_valid(axi_wvalid),

               .b_id(axi_bid),
               .b_resp(axi_bresp),
               .b_valid(axi_bvalid),
               .b_ready(axi_bready),

               .ar_ready(axi_arready),
               .ar_id(axi_arid),
               .ar_addr(axi_araddr),
               .ar_len(axi_arlen),
               .ar_size(axi_arsize),
               .ar_burst(axi_arburst),
               .ar_lock(axi_arlock),
               .ar_cache(axi_arcache),
               .ar_prot(axi_arprot),
               .ar_qos(axi_arqos),
               .ar_valid(axi_arvalid),

               .r_id(axi_rid),
               .r_resp(axi_rresp),
               .r_valid(axi_rvalid),
               .r_data(axi_rdata),
               .r_last(axi_rlast),
               .r_ready(axi_rready)
    );

    parameter int unsigned TbAxiUserWidth        = 8;
    parameter [7:0]        VERBOSE               = `VERBOSE;
    parameter time TbTestTime                    = 1ns;

    axi_seq_item_aw_vector_s aw_s;
    axi_seq_item_w_vector_s w_s;
    axi_seq_item_b_vector_s b_s;
    axi_seq_item_ar_vector_s ar_s;
    axi_seq_item_r_vector_s r_s;

    initial begin : axi_monitor
        static axi_tb_pkg::axi_dw_monitor #(
            .AXI_ID_WIDTH      (AXI_ID_WIDTH),                                                                       
            .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
            .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
            .AXI_LEN_WIDTH  (AXI_LEN_WIDTH),
            .AxiUserWidth       (TbAxiUserWidth       ),
            .verbose            (VERBOSE[0]           ),
            .TimeTest           (TbTestTime           )
        ) monitor = new (daric_top_tb.axi_vif_mon);
    
        axi_vif_mon.wait_for_not_in_reset();
        $display("%t -- %m:: INFO :: Reset released...", $time);        
        axi_vif_mon.wait_for_clks(10);
        $display("%t -- %m:: INFO :: CM7 clock toggled...", $time);        
        axi_vif_mon.detected_clken_toggled;
        fork
          axi_vif_mon.detected_clken_toggled;
          monitor.run();
        join

    end : axi_monitor

    ahbif cm7_ahbp();
    assign  cm7_ahbp.hsel         =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hsel;          
    assign  cm7_ahbp.haddr        =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.haddr;         
    assign  cm7_ahbp.htrans       =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.htrans;        
    assign  cm7_ahbp.hwrite       =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hwrite;        
    assign  cm7_ahbp.hsize        =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hsize;         
    assign  cm7_ahbp.hburst       =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hburst;        
    assign  cm7_ahbp.hprot        =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hprot;          
    assign  cm7_ahbp.hmaster      =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hmaster;       
    assign  cm7_ahbp.hwdata       =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hwdata;        
    assign  cm7_ahbp.hmasterlock  =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hmasterlock;
    assign  cm7_ahbp.hreadym      =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hreadym;      
    assign  cm7_ahbp.hauser       =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hauser;
    assign  cm7_ahbp.hwuser       =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hwuser;
    assign  cm7_ahbp.hrdata       =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hrdata;       
    assign  cm7_ahbp.hready       =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hready;       
    assign  cm7_ahbp.hresp        =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hresp;       
    assign  cm7_ahbp.hruser       =  daric_top_tb.dut.soc.soc_coresub.__coresys.cm7sys.ahbp.hruser;     
    
    parameter AW = 32;
    parameter DW = 32;
    
    ahb_tb_mon #(.AW(AW),.DW(DW),.IDW(4),.UW(4) 
    ) ahb_vif_cm7_ahbp (
        .hclk(hclk),
        .hresetn(resetn),
        .ahbmon(cm7_ahbp)
    );

    initial begin : tb_ahb_monitor
        static ahb_tb_pkg::tb_ahb_monitor #(
        .AW            ( AW          ),
        .DW            ( DW          ),
        .verbose            (VERBOSE[0]           ),
        .TimeTest           (TbTestTime           )
        ) ahbp_mon = new (daric_top_tb.ahb_vif_cm7_ahbp);
      wait (coreresetn);

      $display("%t -- %m:: INFO :: coreresetn released...", $time);
      ahb_vif_cm7_ahbp.wait_for_not_in_reset();
      $display("%t -- %m:: INFO :: hresetn released...", $time);
      ahb_vif_cm7_ahbp.wait_for_clks(10);
      $display("%t -- %m:: INFO :: hclk toggled...", $time);
      fork
        ahbp_mon.run();
      join

    end : tb_ahb_monitor

`endif

endmodule
