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

`include "asic_top/lib/t22sc/dff_reset_pullup.sv"

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
    wire        PF0wire;
    wire        PE0wire;
    wire        PE1wire;
    wire        PE10wire;
    wire        PE11wire;
    wire        PE14wire;
    wire        PE15wire;
    wire        PF2wire;
    wire        PF3wire;
    wire        uartloop;
    wire        SDIO_CLK;
    wire        SDIO_CMD;
    wire [3:0]  SDIO_DATA;
    reg         PA0,PA1,PA2,PF0,PB14=0;
    wire        PAD_SWDIO;
    wire        PAD_SWDCK;
    wire        PB11, PB12;
    wire [31:0] bio_gpio;
    logic [31:0] test;
    wire        rv_jtck;
    wire        rv_jtms;
    wire        rv_jtdi;
    wire        rv_jtdo;
    wire        rv_jtrst;
    reg         rv_jtag_go;

// ======================
// io pad initialization
// ======================

    pullup (PA0wire);
    pullup (PA1wire);

    // stronger pullups for I2C wires
    pullup(bio_gpio[2]);
    pullup(bio_gpio[3]);
    pullup(bio_gpio[11]);
    pullup(bio_gpio[12]);

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
// RV32/BIO test items
// ======================
    bio_tb bio_tb(
        .sim_trace('0),
        .reset(~padresetn),
        .clk(clk48m),
        .test(test),
        .gpio(bio_gpio)
    );

    jtag_rv jtag_rv(
        .tck(rv_jtck),
        .tms(rv_jtms),
        .tdi(rv_jtdi),
        .tdo(rv_jtdo),
        .jtrst(rv_jtrst),
        .jtag_go(rv_jtag_go)
    );

    // jtag initiation timer
    initial begin
        rv_jtag_go = 0;
        #(2.5 `MS);
        rv_jtag_go = 1;
    end

    logic finish_1;
    logic [31:0] last_wtest;
    always @(posedge clk48m) begin
        last_wtest <= test;
        if (test != last_wtest) begin
            $display("[report] %h @ %t", test, $time);
        end
        if (test == 32'hc0ded02e || test == 32'hc0de600d) begin
            if (finish_1 && test == 32'hc0de600d) begin
                $display("Simulation end triggered by CPU magic sequence");
                #1 $finish;
            end
            finish_1 <= 1'b1;
        end else begin
            finish_1 <= 1'b0;
        end
    end

    always @(*) begin
        // access a test mode register buried in the RV32 core
        assign test = dut.soc.soc_coresub.__coresys.vexsys.test;
    end

    AT24C02C i2cflash(
        .SDA(bio_gpio[12]),
        .SCL(bio_gpio[11]),
        .WP(1'b0)
    );

    MX25U12832F spiflash(
        .SCLK(bio_gpio[27]), // PC11
        .CS(bio_gpio[28]), // PC12
        .SI(bio_gpio[23]), // PC7
        .SO(bio_gpio[24]), // PC8
        .WP(bio_gpio[25]), // PC9
        .SIO3(bio_gpio[26]) // PC10
    );

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
        .CSn       (SPIM_CS0),      // Connect to DUT QFC_SS0
        .CLK       (SPIM_SCK),      // Connect to DUT QFC_SCK
        .DIO       (SPIM_SD0),      // Connect to DUT QFC_SIO0
        .DO        (SPIM_SD1),      // Connect to DUT QFC_SIO1
        .WPn       (SPIM_SD2),      // Connect to DUT QFC_SIO2
        .HOLDn     (SPIM_SD3)       // Connect to DUT QFC_SIO3
    );
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
    initial begin
        wait (syscnt == 32'd18285);
        $display("%t -- %m: INFO: toggle PA0~7 ", $time);
        {PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = 8'haa;
        //wait (syscnt == 32'd18278);
        //{PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = 8'h55;
        //wait (syscnt == 32'd18288);
        //{PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = 8'hff;
        //wait (syscnt == 32'd18298);
        //{PA7reg, PA6reg, PA5reg, PA4reg, PA3reg, PA2reg, PA1reg, PA0reg} = 8'h00;

    end
`endif

`ifdef GPIO_IRQ
    reg PA3reg;
    assign PA3wire = PA3reg;

    initial begin
        wait (syscnt == 32'd7278);
        $display("%t -- %m: INFO: toggle PA3 ", $time);
        PA3reg = 1'b1;
        wait (syscnt == 32'd7288);
        PA3reg = 1'b0;
    end
`endif

// ======================
// I2C external model
// ======================

`ifdef SIM_CM7_WFI_WFE
    reg PF0reg;
    assign PF0wire = PF0reg;
    initial begin
        PF0reg = 1'b1;
        wait (syscnt == 6000);
        $display("%t -- %m: INFO: PF0 asserting to 0 -> wake from WFE", $time);
        PF0reg = 1'b0;
        wait (syscnt == 6010);
        PF0reg = 1'b1;

        wait (syscnt == 10000);
        $display("%t -- %m: INFO: PF0 asserting to 0 -> wake from WFI", $time);
        PF0reg = 1'b0;
        wait (syscnt == 10010);
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

`endif

// ======================
// SDIO external model
// ======================

`ifdef SDSIM
    sdModel sd(
        .sdClk ( SDIO_CLK ),
        .cmd   ( SDIO_CMD ),
        .dat   ( SDIO_DATA)
    );
`endif

// ======================
// SWD external model
// ======================

`ifdef FPGA
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

`ifdef GPIO_IN
        .PA0 (PA0wire),
        .PA1 (PA1wire),
        .PA2 (PA2wire),
        .PA3 (PA3wire),
        .PA4 (PA4wire),
        .PA5 (PA5wire),
        .PA6 (PA6wire),
        .PA7 (PA7wire),
`endif

`ifdef GPIO_IRQ
        .PA3 (PA3wire),
`endif

`ifdef UART_TEST
        .PA4 (uartloop),
        .PD13 (uartloop),
`endif
        .PA5 (PA5wire),
        .PA6 (PA6wire),

        .PB0 (bio_gpio[0]),
        .PB1 (bio_gpio[1]),
        .PB2 (bio_gpio[2]),
        .PB3 (bio_gpio[3]),
        .PB4 (bio_gpio[4]),
        .PB5 (bio_gpio[5]),
        .PB6 (bio_gpio[6]),
        .PB7 (bio_gpio[7]),
        .PB8 (bio_gpio[8]),
        .PB9 (bio_gpio[9]),
        .PB10 (bio_gpio[10]),
        .PB11 (bio_gpio[11]),
        .PB12 (bio_gpio[12]),
        .PB13 (bio_gpio[13]),
        .PB14 (bio_gpio[14]),
        .PB15 (bio_gpio[15]),

        .PC0 (bio_gpio[16]),
        .PC1 (bio_gpio[17]),
        .PC2 (bio_gpio[18]),
        .PC3 (bio_gpio[19]),
        .PC4 (bio_gpio[20]),
        .PC5 (bio_gpio[21]),
        .PC6 (bio_gpio[22]),
        .PC7 (bio_gpio[23]),
        .PC8 (bio_gpio[24]),
        .PC9 (bio_gpio[25]),
        .PC10 (bio_gpio[26]),
        .PC11 (bio_gpio[27]),
        .PC12 (bio_gpio[28]),
        .PC13 (bio_gpio[29]),
        .PC14 (bio_gpio[30]),
        .PC15 (bio_gpio[31]),

        .PE0(PE0wire),
        .PE1(PE1wire),
        .PE10(PE10wire),
        .PE11(PE11wire),
        .PE14(PE14wire),
        .PE15(PE15wire),

        .PF0 (PF0wire),
        .PF2 (PF2wire),
        .PF3 (PF3wire),

        .PAD_JTCK(rv_jtck),
        .PAD_JTMS(rv_jtms),
        .PAD_JTDI(rv_jtdi),
        .PAD_JTDO(rv_jtdo),
        .PAD_JTRST(rv_jtrst),

        .PAD_SWDCK  (PAD_SWDCK),
        .PAD_SWDIO  (PAD_SWDIO),
        .PAD_AOXRSTn  (padresetn)

    );


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

        #(300 `MS);
    `maintestend


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

// ======================
// memory initialization
// ======================

    initial resetn = 0;
    initial clk = 0;
    initial clkswd = 0;

    integer fd;
    string MEMFILE = "testdata.bin";
    string MEMFILE_INF1 = "/work/daric/repo/frontend_release/asic_top/testbench/cp_ifren1.txt";
    string ACRAMFILE = "acram.bin";

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
    assign thenvrdat = { thenvrcms, thenvripm, thenvrcfg };
    logic [0:31][255:0] thenvrdat0;

`ifndef FPGA

    generate
        for (genvar gvi = 0; gvi < 32; gvi++) begin
        /* code */
        assign thenvrdat0[gvi] = {
                        dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[gvi][144:73],
                        dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[gvi][71:0],
                        dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[gvi][144:73],
                        dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[gvi][71:0]
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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
            #0.01;
        `endif
    end

    $display("%t -- %m: INFO: Open ACRAMFILE = %s", $time, ACRAMFILE);
    fd = $fopen(ACRAMFILE,"rb");
    #(10 `US );
    // convert ACRAM start offset to RRAM line number
    for(i = 32'h3DC000 / 32; (i < 512 + (32'h3DC000 / 32) ) ; i = i + 1) begin
        #0.01;
        r0 = $fread(data0,fd);
        #0.01;
        r1 = $fread(data1,fd);
        #0.01;
        r2 = $fread(data2,fd);
        #0.01;
        r3 = $fread(data3,fd);
        #0.01;

        #0.01;
        reram_source = {swizzle(data3),swizzle(data2),swizzle(data1),swizzle(data0)};
        #0.01;
        reram_data0 = rram_encoder(reram_source[127:0],1);
        reram_data1 = rram_encoder(reram_source[255:128],1);

        // $display("ACRAM write %08x <- (%036x, %036x) | (%064x)", i, reram_data0, reram_data1, reram_source);
        #0.01;
        dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
        dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        #0.01;
    end

    $display("%t -- %m: INFO: init key region", $time);
    #(10 `US );
    for(i = 32'h3F0000 / 32; i < 2048 + 32'h3F0000 / 32; i = i + 1) begin
        #0.01;
        data0 = i ^ 64'hABCDEF0000000000;
        #0.01;
        data1 = i ^ 64'h1234567800000000;
        #0.01;
        data2 = i ^ 64'h7777888800000000;
        #0.01;
        data3 = i ^ 64'hccccdddd00000000;
        #0.01;

        reram_source = {data3, data2, data1, data0};
        #0.01;
        reram_data0 = rram_encoder(reram_source[127:0],1);
        reram_data1 = rram_encoder(reram_source[255:128],1);

        // $display("ACRAM write %08x <- (%036x, %036x) | (%064x)", i, reram_data0, reram_data1, reram_source);
        #0.01;
        dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
        dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        #0.01;
    end

    $display("%t -- %m: INFO: init data region", $time);
    #(10 `US );
    for(i = 32'h3E0000 / 32; i < 2048 + 32'h3E0000 / 32; i = i + 1) begin
        #0.01;
        data0 = i ^ 64'hFACEFACE00000000;
        #0.01;
        data1 = i ^ 64'hF00DF00D00000000;
        #0.01;
        data2 = i ^ 64'hD00DD00D00000000;
        #0.01;
        data3 = i ^ 64'h600D600D00000000;
        #0.01;
        reram_source = {data3, data2, data1, data0};
        #0.01;
        reram_data0 = rram_encoder(reram_source[127:0],1);
        reram_data1 = rram_encoder(reram_source[255:128],1);

        // $display("ACRAM write %08x <- (%036x, %036x) | (%064x)", i, reram_data0, reram_data1, reram_source);
        #0.01;
        dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
        dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.main_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        #0.01;
    end

    `ifndef FPGA
    //  init rram ifr
    // =====================
    #0.01;
    ifmeminitflag = 1;

    $readmemh(MEMFILE_INF1,dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren1_mem);
    $readmemh(MEMFILE_INF1,dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren1_mem);

    for (int i = 0; i < 32; i++) begin
        #0.01;
        reram_data0 = rram_encoder(thenvrdat[i][127:0],1);
        reram_data1 = rram_encoder(thenvrdat[i][255:128],1);
        #0.01;
        dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
        dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
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

    end //initial



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
        
        dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[ifr_index] = {1'b0,ifr_data0[143:72],1'b0,ifr_data0[71:0]};
        dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[ifr_index] = {1'b0,ifr_data1[143:72],1'b0,ifr_data1[71:0]};

    endfunction

// ======================
// debug probe
// ======================

    assign probe_r0 = {dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.main_mem[0][144:73],
                      dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.main_mem[0][71:0]};

    assign probe_r1 = {dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.main_mem[0][144:73],
                      dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.main_mem[0][71:0]};

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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;

        #(3 `MS);

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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
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
            dut.soc.soc_coresub.greram[0].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data0[143:72],1'b0,reram_data0[71:0]};
            dut.soc.soc_coresub.greram[1].reram.u_rram_wrapper.u_rram.ifren_mem[i] = {1'b0,reram_data1[143:72],1'b0,reram_data1[71:0]};
        end
        ifmeminitflag = 0;
		wait(daric_top_tb.dut.soc.cms.u_atpgmode_buf.Z);
		$display("::::::::  CMS  :::::::::: CMS_ATPG (5b)");

        #(4 `MS);

//		$reset;

endtask : daric_mode_scan


task rrc_prog_only_cfg;

        #(4 `MS);


        #(4 `MS);

//		$reset;

endtask : rrc_prog_only_cfg


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



`endif

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


endmodule
