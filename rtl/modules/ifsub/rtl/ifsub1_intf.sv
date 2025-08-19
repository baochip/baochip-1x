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

module ifsub1#(
	    parameter DW             = 32,
	    parameter AW             = 18, // 256KB
        parameter AW32           = AW-2,
	    parameter CAM_DW         = 8,
	    parameter PAW            = 17,  //APB slaves are 12bit(4KB) by default
	    parameter TRANS_SIZE     = 20,  //max uDMA transaction size of 1MB
        parameter N_SPIM         = 4,
        parameter N_SPIS         = 2,
	    parameter N_UART         = 4,
	    parameter N_I2C          = 1,
//	    parameter N_I2S     	 = 1,
	    parameter N_CAM     	 = 1,
	    parameter N_SDIO    	 = 1,
	    parameter N_FILTER  	 = 1,
	    parameter N_EXT_PER 	 = 0,
        parameter EVCNT          = 32*4,
        parameter bit[31:0] BA   = 32'h5000_0000,
        parameter bit[3:0]  AXIMID4 = 4'hA
	)(
		input logic 				clk,
		input logic 				resetn,
		input logic 				perclk,
		input logic 				cmsatpg,
        apbif.slave                 apbs,
        axiif.master                axim,
        input  logic              ifev_vld,
        input  logic [7:0]        ifev_dat,
        output logic              ifev_rdy,

        ioif.drive       spim_clk_pad[N_SPIM-1:0],
        ioif.drive       spim_csn0_pad[N_SPIM-1:0],
        ioif.drive       spim_csn1_pad[N_SPIM-1:0],
        ioif.drive       spim_csn2_pad[N_SPIM-1:0],
        ioif.drive       spim_csn3_pad[N_SPIM-1:0],
        ioif.drive       spim_sd0_pad[N_SPIM-1:0],
        ioif.drive       spim_sd1_pad[N_SPIM-1:0],
        ioif.drive       spim_sd2_pad[N_SPIM-1:0],
        ioif.drive       spim_sd3_pad[N_SPIM-1:0],

        ioif.drive      i2c_scl_pad[N_I2C-1:0] ,
        ioif.drive      i2c_sda_pad[N_I2C-1:0] ,

        ioif.drive      cam_clk_pad            ,
        ioif.drive      cam_data_pad[CAM_DW-1:0],
        ioif.drive      cam_hsync_pad            ,
        ioif.drive      cam_vsync_pad            ,

        ioif.drive      uart_rx_pad[N_UART-1:0],
        ioif.drive      uart_tx_pad[N_UART-1:0],

        ioif.drive      sdio_clk_pad            ,
        ioif.drive      sdio_cmd_pad            ,
        ioif.drive      sdio_data_pad[3:0]       ,

        ioif.drive      i2ss_sd_pad    ,
        ioif.drive      i2ss_ws_pad    ,
        ioif.drive      i2ss_sck_pad    ,
        ioif.drive      i2sm_sd_pad    ,
        ioif.drive      i2sm_ws_pad    ,
        ioif.drive      i2sm_sck_pad    ,

        ioif.drive      scif_sck_pad    ,
        ioif.drive      scif_dat_pad    ,

        ioif.drive      spis_clk_pad[N_SPIS-1:0]    ,
        ioif.drive      spis_csn_pad[N_SPIS-1:0]    ,
        ioif.drive      spis_mosi_pad[N_SPIS-1:0]    ,
        ioif.drive      spis_miso_pad[N_SPIS-1:0],

        input wire [3:0] ana_adcsrc,
//        //input logic clk16m,

//        ioif.drive [N_I2S-1:0]      i2s_ck_pad,
//        ioif.drive [N_I2S-1:0]      i2s_ws_pad,
//        ioif.drive [N_I2S-1:0]      i2s_sd_pad,

		output logic [EVCNT-1:0]	intr
	);

    parameter N_SPI = N_SPIM;

    logic                       L2_ro_wen    ;
    logic                       L2_ro_req    ;
    logic                       L2_ro_gnt    ;
    logic                [31:0] L2_ro_addr   ;
    logic [DW/8-1:0]            L2_ro_be     ;
    logic   [DW-1:0]            L2_ro_wdata  ;
    logic                       L2_ro_rvalid ;
    logic   [DW-1:0]            L2_ro_rdata  ;
    logic                       L2_wo_wen    ;
    logic                       L2_wo_req    ;
    logic                       L2_wo_gnt    ;
    logic                [31:0] L2_wo_addr   ;
    logic   [DW-1:0]            L2_wo_wdata  ;
    logic [DW/8-1:0]            L2_wo_be     ;
    logic                       L2_wo_rvalid ;
    logic   [DW-1:0]            L2_wo_rdata  ;

    logic     [N_SPIM-1:0]       spim_clk;
    logic     [N_SPIM-1:0] [3:0] spim_csn;
    logic     [N_SPIM-1:0] [3:0] spim_oen;
    logic     [N_SPIM-1:0] [3:0] spim_sdo;
    logic     [N_SPIM-1:0] [3:0] spim_sdi;
    logic     [3:0] [N_SPIM-1:0] spim_csnx;
    logic     [3:0] [N_SPIM-1:0] spim_oenx;
    logic     [3:0] [N_SPIM-1:0] spim_sdox;
    logic     [3:0] [N_SPIM-1:0] spim_sdix;
    logic           [N_I2C-1:0] i2c_scl_i;
    logic           [N_I2C-1:0] i2c_scl_o;
    logic           [N_I2C-1:0] i2c_scl_oe;
    logic           [N_I2C-1:0] i2c_sda_i;
    logic           [N_I2C-1:0] i2c_sda_o;
    logic           [N_I2C-1:0] i2c_sda_oe;
    logic                       cam_clk_i;
    logic  [CAM_DW-1:0]         cam_data_i;
    logic                       cam_hsync_i;
    logic                       cam_vsync_i;
    logic          [N_UART-1:0] uart_rx;
    logic          [N_UART-1:0] uart_tx;
    logic                       sdio_clk_o;
    logic                       sdio_cmd_o;
    logic                       sdio_cmd_i;
    logic                       sdio_cmd_oen_o;
    logic                 [3:0] sddata_o;
    logic                 [3:0] sddata_i;
    logic                 [3:0] sddata_oen_o;
    logic                       i2s_slave_sd0_i;
    logic                       i2s_slave_sd1_i;
    logic                       i2s_slave_ws_i;
    logic                       i2s_slave_ws_o;
    logic                       i2s_slave_ws_oe;
    logic                       i2s_slave_sck_i;
    logic                       i2s_slave_sck_o;
    logic                       i2s_slave_sck_oe;
    logic                       i2s_master_sd0_o  ;
    logic                       i2s_master_sd1_o  ;
    logic                       i2s_master_sck_i  ;
    logic                       i2s_master_sck_o  ;
    logic                       i2s_master_sck_oe ;
    logic                       i2s_master_ws_i   ;
    logic                       i2s_master_ws_o   ;
    logic                       i2s_master_ws_oe  ;
    logic                       scif_sck_i   ;
    logic                       scif_sck_o   ;
    logic                       scif_sck_oe  ;
    logic                       scif_dat_i   ;
    logic                       scif_dat_o   ;
    logic                       scif_dat_oe  ;
    logic   [N_SPIS-1:0]        spis_clk_i   ;
    logic   [N_SPIS-1:0]        spis_cs_i    ;
    logic   [N_SPIS-1:0]        spis_mosi_i  ;
    logic   [N_SPIS-1:0]        spis_miso_o  ;
    logic   [N_SPIS-1:0]        spis_miso_oe ;

    logic [31:0] axim_awaddr0, axim_araddr0;

    assign axim.awaddr = BA + axim_awaddr0[AW-1:0];
    assign axim.araddr = BA + axim_araddr0[AW-1:0];
    assign axim.arid = AXIMID4 * 16;
    assign axim.awid = AXIMID4 * 16;

    assign axim.aruser = AXIMID4|'0;
    assign axim.awuser = AXIMID4|'0;

// lint_2_axi

    lint_2_axi #(
        .ADDR_WIDTH       ( 32              ),
        .DATA_WIDTH       ( DW              ),
        .BE_WIDTH         ( DW/8            ),
        .ID_WIDTH         ( 8               ),
        .USER_WIDTH       ( 8               ),
        .AUX_WIDTH        ( 0               ),
        .AXI_ID_WIDTH     ( 8               ),
        .REGISTERED_GRANT ( "FALSE"           )  // "TRUE"|"FALSE"
    ) lab_ro (
        // Clock and Reset
        .clk_i         ( clk                            ),
        .rst_ni        ( resetn                          ),

        .data_req_i    ( L2_ro_req ),
        .data_addr_i   ( L2_ro_addr ),
        .data_we_i     ( ~L2_ro_wen ),
        .data_wdata_i  ( L2_ro_wdata ),
        .data_be_i     ( L2_ro_be ),
        .data_aux_i    ( '0 ),
        .data_ID_i     ( '0 ),
        .data_gnt_o    ( L2_ro_gnt ),

        .data_rvalid_o ( L2_ro_rvalid ),
        .data_rdata_o  ( L2_ro_rdata ),
        .data_ropc_o   (  ),
        .data_raux_o   (  ),
        .data_rID_o    (  ),
        // ---------------------------------------------------------
        // AXI TARG Port Declarations ------------------------------
        // ---------------------------------------------------------
        //AXI write address bus -------------- // USED// -----------
        .aw_id_o       (    ),
        .aw_addr_o     (    ),
        .aw_len_o      (    ),
        .aw_size_o     (    ),
        .aw_burst_o    (    ),
        .aw_lock_o     (    ),
        .aw_cache_o    (    ),
        .aw_prot_o     (    ),
        .aw_region_o   (    ),
        .aw_user_o     (    ),
        .aw_qos_o      (    ),
        .aw_valid_o    (    ),
        .aw_ready_i    ( '1 ),
        // ---------------------------------------------------------

        //AXI write data bus -------------- // USED// --------------
        .w_data_o      (    ),
        .w_strb_o      (    ),
        .w_last_o      (    ),
        .w_user_o      (    ),
        .w_valid_o     (    ),
        .w_ready_i     ( '1 ),
        // ---------------------------------------------------------

        //AXI write response bus -------------- // USED// ----------
        .b_id_i        ( '0 ),
        .b_resp_i      ( '0 ),
        .b_valid_i     ( '0 ),
        .b_user_i      ( '0 ),
        .b_ready_o     (    ),
        // ---------------------------------------------------------

        //AXI read address bus -------------------------------------
        .ar_id_o       (            ),
        .ar_addr_o     ( axim_araddr0          ),
        .ar_len_o      ( axim.arlen            ),
        .ar_size_o     ( axim.arsize           ),
        .ar_burst_o    ( axim.arburst          ),
        .ar_lock_o     ( axim.arlock           ),
        .ar_cache_o    ( axim.arcache          ),
        .ar_prot_o     ( axim.arprot           ),
        .ar_region_o   (                       ),
        .ar_user_o     (                       ),
        .ar_qos_o      (                       ),
        .ar_valid_o    ( axim.arvalid          ),
        .ar_ready_i    ( axim.arready          ),
        // ---------------------------------------------------------

        //AXI read data bus ----------------------------------------
        .r_id_i        ( axim.rid              ),
        .r_data_i      ( axim.rdata            ),
        .r_resp_i      ( axim.rresp            ),
        .r_last_i      ( axim.rlast            ),
        .r_user_i      ( axim.ruser            ),
        .r_valid_i     ( axim.rvalid           ),
        .r_ready_o     ( axim.rready           )
        // ---------------------------------------------------------
    );


    lint_2_axi #(
        .ADDR_WIDTH       ( 32              ),
        .DATA_WIDTH       ( DW              ),
        .BE_WIDTH         ( DW/8            ),
        .ID_WIDTH         ( 8               ),
        .USER_WIDTH       ( 8               ),
        .AUX_WIDTH        ( 0               ),
        .AXI_ID_WIDTH     ( 8               ),
        .REGISTERED_GRANT ( "FALSE"           )  // "TRUE"|"FALSE"
    ) lab_wo (
        // Clock and Reset
        .clk_i         ( clk                            ),
        .rst_ni        ( resetn                          ),

        .data_req_i    ( L2_wo_req ),
        .data_addr_i   ( L2_wo_addr ),
        .data_we_i     ( ~L2_wo_wen ),
        .data_wdata_i  ( L2_wo_wdata ),
        .data_be_i     ( L2_wo_be ),
        .data_aux_i    ( '0 ),
        .data_ID_i     ( '0 ),
        .data_gnt_o    ( L2_wo_gnt ),

        .data_rvalid_o ( L2_wo_rvalid ),
        .data_rdata_o  ( L2_wo_rdata ),
        .data_ropc_o   (  ),
        .data_raux_o   (  ),
        .data_rID_o    (  ),
        // ---------------------------------------------------------
        // AXI TARG Port Declarations ------------------------------
        // ---------------------------------------------------------
        //AXI write address bus -------------- // USED// -----------
        .aw_id_o       (    ),
        .aw_addr_o     ( axim_awaddr0          ),
        .aw_len_o      ( axim.awlen            ),
        .aw_size_o     ( axim.awsize           ),
        .aw_burst_o    ( axim.awburst          ),
        .aw_lock_o     ( axim.awlock           ),
        .aw_cache_o    ( axim.awcache          ),
        .aw_prot_o     ( axim.awprot           ),
        .aw_region_o   (                       ),
        .aw_user_o     (                       ),
        .aw_qos_o      (                       ),
        .aw_valid_o    ( axim.awvalid          ),
        .aw_ready_i    ( axim.awready          ),
        // ---------------------------------------------------------

        //AXI write data bus -------------- // USED// --------------
        .w_data_o      ( axim.wdata            ),
        .w_strb_o      ( axim.wstrb            ),
        .w_last_o      ( axim.wlast            ),
        .w_user_o      ( axim.wuser            ),
        .w_valid_o     ( axim.wvalid           ),
        .w_ready_i     ( axim.wready           ),
        // ---------------------------------------------------------

        //AXI write response bus -------------- // USED// ----------
        .b_id_i        ( axim.bid              ),
        .b_resp_i      ( axim.bresp            ),
        .b_valid_i     ( axim.bvalid           ),
        .b_user_i      ( axim.buser            ),
        .b_ready_o     ( axim.bready           ),
        // ---------------------------------------------------------

        //AXI read address bus -------------------------------------
        .ar_id_o       (    ),
        .ar_addr_o     (    ),
        .ar_len_o      (    ),
        .ar_size_o     (    ),
        .ar_burst_o    (    ),
        .ar_lock_o     (    ),
        .ar_cache_o    (    ),
        .ar_prot_o     (    ),
        .ar_region_o   (    ),
        .ar_user_o     (    ),
        .ar_qos_o      (    ),
        .ar_valid_o    (    ),
        .ar_ready_i    ( '1 ),
        // ---------------------------------------------------------

        //AXI read data bus ----------------------------------------
        .r_id_i        ( '0 ),
        .r_data_i      ( '0 ),
        .r_resp_i      ( '0 ),
        .r_last_i      ( '0 ),
        .r_user_i      ( '0 ),
        .r_valid_i     ( '0 ),
        .r_ready_o     (    )
        // ---------------------------------------------------------
    );
    assign axim.awsparse = 1'b1;
    assign intr = udma.events_o[EVCNT-1:0];

    udma_sub #(
        .APB_ADDR_WIDTH     ( PAW       ),
        .L2_ADDR_WIDTH      ( AW32       ),
        .N_SPI (N_SPIM),
        .N_UART(N_UART),
        .N_I2C (N_I2C),
        .N_SPIS(N_SPIS)
    ) udma (
        .L2_ro_req_o      ( L2_ro_req     ),
        .L2_ro_gnt_i      ( L2_ro_gnt     ),
        .L2_ro_wen_o      ( L2_ro_wen     ),
        .L2_ro_addr_o     ( L2_ro_addr    ),
        .L2_ro_wdata_o    ( L2_ro_wdata   ),
        .L2_ro_be_o       ( L2_ro_be      ),
        .L2_ro_rdata_i    ( L2_ro_rdata   ),
        .L2_ro_rvalid_i   ( L2_ro_rvalid  ),

        .L2_wo_req_o      ( L2_wo_req     ),
        .L2_wo_gnt_i      ( L2_wo_gnt     ),
        .L2_wo_wen_o      ( L2_wo_wen     ),
        .L2_wo_addr_o     ( L2_wo_addr    ),
        .L2_wo_wdata_o    ( L2_wo_wdata   ),
        .L2_wo_be_o       ( L2_wo_be      ),
        .L2_wo_rdata_i    ( L2_wo_rdata   ),
        .L2_wo_rvalid_i   ( L2_wo_rvalid  ),

        .dft_test_mode_i  ( cmsatpg	 	         ),
        .dft_cg_enable_i  ( cmsatpg              ),

        .sys_clk_i        ( clk                  ),
        .periph_clk_i     ( perclk               ),
        .sys_resetn_i     ( resetn               ),

        .udma_apb_paddr   ( apbs.paddr     ),
        .udma_apb_pwdata  ( apbs.pwdata    ),
        .udma_apb_pwrite  ( apbs.pwrite    ),
        .udma_apb_psel    ( apbs.psel      ),
        .udma_apb_penable ( apbs.penable   ),
        .udma_apb_prdata  ( apbs.prdata    ),
        .udma_apb_pready  ( apbs.pready    ),
        .udma_apb_pslverr ( apbs.pslverr   ),

        .events_o         (         ),

        .event_valid_i    ( ifev_vld     ),
        .event_data_i     ( ifev_dat     ),
        .event_ready_o    ( ifev_rdy     ),

        .spi_clk          ( spim_clk              ),
        .spi_csn          ( spim_csn              ),
        .spi_oen          ( spim_oen              ),
        .spi_sdo          ( spim_sdo              ),
        .spi_sdi          ( spim_sdi              ),

        .sdio_clk_o       ( sdio_clk_pad.po       ),
        .sdio_cmd_o       ( sdio_cmd_pad.po       ),
        .sdio_cmd_i       ( sdio_cmd_pad.pi          ),
        .sdio_cmd_oen_o   (                      ),
        .sdio_data_o      ( sddata_o             ),
        .sdio_data_i      ( sddata_i             ),
        .sdio_data_oen_o  ( sddata_oen_o         ),

        .cam_clk_i        ( cam_clk_pad.pi            ),
        .cam_hsync_i      ( cam_hsync_pad.pi          ),
        .cam_vsync_i      ( cam_vsync_pad.pi          ),
        .cam_data_i       ( cam_data_i                ),

        .i2s_slave_sd0_i  ( /*i2s_slave_sd0_i */  i2ss_sd_pad.pi   ),
        .i2s_slave_sd1_i  ( /*i2s_slave_sd1_i */  '0               ),
        .i2s_slave_ws_i   ( /*i2s_slave_ws_i  */  i2ss_ws_pad.pi   ),
        .i2s_slave_ws_o   ( /*i2s_slave_ws_o  */  i2ss_ws_pad.po   ),
        .i2s_slave_ws_oe  ( /*i2s_slave_ws_oe */  i2ss_ws_pad.oe   ),
        .i2s_slave_sck_i  ( /*i2s_slave_sck_i */  i2ss_sck_pad.pi  ),
        .i2s_slave_sck_o  ( /*i2s_slave_sck_o */  i2ss_sck_pad.po  ),
        .i2s_slave_sck_oe ( /*i2s_slave_sck_oe*/  i2ss_sck_pad.oe  ),

        .i2s_master_sd0_o  (  i2sm_sd_pad.po     ),
        .i2s_master_sd1_o  (                     ),
        .i2s_master_ws_i  (  i2sm_ws_pad.pi     ),
        .i2s_master_ws_o  (  i2sm_ws_pad.po     ),
        .i2s_master_ws_oe (  i2sm_ws_pad.oe     ),
        .i2s_master_sck_i   (  i2sm_sck_pad.pi    ),
        .i2s_master_sck_o   (  i2sm_sck_pad.po    ),
        .i2s_master_sck_oe  (  i2sm_sck_pad.oe    ),

        .uart_rx_i        ( uart_rx[N_UART-1:0]              ),
        .uart_tx_o        ( uart_tx[N_UART-1:0]              ),

        .i2c_scl_i        ( i2c_scl_i            ),
        .i2c_scl_o        ( i2c_scl_o            ),
        .i2c_scl_oe       ( i2c_scl_oe           ),
        .i2c_sda_i        ( i2c_sda_i            ),
        .i2c_sda_o        ( i2c_sda_o            ),
        .i2c_sda_oe       ( i2c_sda_oe           ),

        .scif_sck_i       ( scif_sck_pad.pi  ),
        .scif_sck_o       ( scif_sck_pad.po  ),
        .scif_sck_oe      ( scif_sck_pad.oe  ),
        .scif_dat_i       ( scif_dat_pad.pi  ),
        .scif_dat_o       ( scif_dat_pad.po  ),
        .scif_dat_oe      ( scif_dat_pad.oe  ),

        .ana_adcsrc,
//        .clk16m,
        .*
    );

    generate
        for (genvar i = 0; i < N_SPI; i++) begin
            assign spim_csnx[0][i] = spim_csn[i][0];
            assign spim_csnx[1][i] = spim_csn[i][1];
            assign spim_csnx[2][i] = spim_csn[i][2];
            assign spim_csnx[3][i] = spim_csn[i][3];
            assign spim_oenx[0][i] = spim_oen[i][0];
            assign spim_oenx[1][i] = spim_oen[i][1];
            assign spim_oenx[2][i] = spim_oen[i][2];
            assign spim_oenx[3][i] = spim_oen[i][3];
            assign spim_sdox[0][i] = spim_sdo[i][0];
            assign spim_sdox[1][i] = spim_sdo[i][1];
            assign spim_sdox[2][i] = spim_sdo[i][2];
            assign spim_sdox[3][i] = spim_sdo[i][3];
            assign spim_sdi[i][0] = spim_sdix[0][i];
            assign spim_sdi[i][1] = spim_sdix[1][i];
            assign spim_sdi[i][2] = spim_sdix[2][i];
            assign spim_sdi[i][3] = spim_sdix[3][i];
        end
    endgenerate

    wire2ioif #(N_SPIM) wspimclk (.ioout(spim_clk),.iooe('1),.iopu('1),.ioin(),.ioifdrv(spim_clk_pad));
    wire2ioif #(N_SPIM) wspimcs0 (.ioout(spim_csnx[0]),.iooe('1),.iopu('1),.ioin(),.ioifdrv(spim_csn0_pad));
    wire2ioif #(N_SPIM) wspimcs1 (.ioout(spim_csnx[1]),.iooe('1),.iopu('1),.ioin(),.ioifdrv(spim_csn1_pad));
    wire2ioif #(N_SPIM) wspimcs2 (.ioout(spim_csnx[2]),.iooe('1),.iopu('1),.ioin(),.ioifdrv(spim_csn2_pad));
    wire2ioif #(N_SPIM) wspimcs3 (.ioout(spim_csnx[3]),.iooe('1),.iopu('1),.ioin(),.ioifdrv(spim_csn3_pad));
    wire2ioif #(N_SPIM) wspimsd0 (.ioout(spim_sdox[0]),.iooe(~spim_oenx[0]),.iopu('1),.ioin(spim_sdix[0]),.ioifdrv(spim_sd0_pad));
    wire2ioif #(N_SPIM) wspimsd1 (.ioout(spim_sdox[1]),.iooe(~spim_oenx[1]),.iopu('1),.ioin(spim_sdix[1]),.ioifdrv(spim_sd1_pad));
    wire2ioif #(N_SPIM) wspimsd2 (.ioout(spim_sdox[2]),.iooe(~spim_oenx[2]),.iopu('1),.ioin(spim_sdix[2]),.ioifdrv(spim_sd2_pad));
    wire2ioif #(N_SPIM) wspimsd3 (.ioout(spim_sdox[3]),.iooe(~spim_oenx[3]),.iopu('1),.ioin(spim_sdix[3]),.ioifdrv(spim_sd3_pad));

    wire2ioif #(N_I2C)  wi2cscl  (.ioout(i2c_scl_o),.iooe(i2c_scl_oe),.iopu('1),.ioin(i2c_scl_i),.ioifdrv(i2c_scl_pad));
    wire2ioif #(N_I2C)  wi2csda  (.ioout(i2c_sda_o),.iooe(i2c_sda_oe),.iopu('1),.ioin(i2c_sda_i),.ioifdrv(i2c_sda_pad));

    assign { cam_clk_pad.pu, cam_hsync_pad.pu, cam_vsync_pad.pu } = '1;
    assign { cam_clk_pad.oe, cam_hsync_pad.oe, cam_vsync_pad.oe } = '0;
    assign { cam_clk_pad.po, cam_hsync_pad.po, cam_vsync_pad.po } = '0;
    wire2ioif #(CAM_DW) wcamdata (.ioout('0),.iooe('0),.iopu('1),.ioin(cam_data_i),.ioifdrv(cam_data_pad));

    wire2ioif #(N_UART)  wurx  (.ioout('0     ),.iooe('0),.iopu('1),.ioin(uart_rx[N_UART-1:0]),.ioifdrv(uart_rx_pad[N_UART-1:0]));
    wire2ioif #(N_UART)  wutx  (.ioout(uart_tx[N_UART-1:0]),.iooe('1),.iopu('1),.ioin(       ),.ioifdrv(uart_tx_pad[N_UART-1:0]));

    assign sdio_clk_pad.oe = '1;
    assign sdio_clk_pad.pu = '1;
    assign sdio_cmd_pad.oe = ~udma.sdio_cmd_oen_o;
    assign sdio_cmd_pad.pu = '1;
    wire2ioif #(4)  wsdiodat (.ioout(sddata_o),.iooe(~sddata_oen_o),.iopu('1),.ioin(sddata_i),.ioifdrv(sdio_data_pad));

    assign i2ss_sd_pad.po = '0;
    assign i2ss_sd_pad.oe  = '0;
    assign i2ss_sd_pad.pu  = '1;
    assign i2ss_ws_pad.pu = '1;
    assign i2ss_sck_pad.pu = '1;

    assign i2sm_sd_pad.oe  = '1;
    assign i2sm_sd_pad.pu  = '1;
    assign i2sm_ws_pad.pu = '1;
    assign i2sm_sck_pad.pu = '1;

//    wire2ioif wi2sssd (.ioout('0),.iooe('0),.iopu('1),.ioin(i2s_slave_sd0_i),.ioifdrv(i2ss_sd_pad));
//    wire2ioif wi2ssws (.ioout(i2s_slave_ws_o),.iooe(i2s_slave_ws_oe),.iopu('1),.ioin(i2s_slave_ws_i),.ioifdrv(i2ss_ws_pad));
//    wire2ioif wi2sssck (.ioout(i2s_slave_sck_o),.iooe(i2s_slave_sck_oe),.iopu('1),.ioin(i2s_slave_sck_i),.ioifdrv(i2ss_sck_pad));

//    wire2ioif wi2smsd (.ioout(i2s_master_sd0_o),.iooe('1),.iopu('1),.ioin(),.ioifdrv(i2sm_sd_pad));
//    wire2ioif wi2smws (.ioout(i2s_master_ws_o),.iooe(i2s_master_ws_oe),.iopu('1),.ioin(i2s_master_ws_i),.ioifdrv(i2sm_ws_pad));
//    wire2ioif wi2smsck (.ioout(i2s_master_sck_o),.iooe(i2s_master_sck_oe),.iopu('1),.ioin(i2s_master_sck_i),.ioifdrv(i2sm_sck_pad));

    assign scif_sck_pad.pu = '1;
    assign scif_dat_pad.pu = '1;
//    wire2ioif wscifsck (.ioout(scif_sck_o),.iooe(scif_sck_oe),.iopu('1),.ioin(scif_sck_i),.ioifdrv(scif_sck_pad));
//    wire2ioif wscifdat (.ioout(scif_dat_o),.iooe(scif_dat_oe),.iopu('1),.ioin(scif_dat_i),.ioifdrv(scif_dat_pad));

    wire2ioif #(N_SPIS) wspisclk (.ioout('0),.iooe('0),.iopu('1),.ioin(spis_clk_i),.ioifdrv(spis_clk_pad));
    wire2ioif #(N_SPIS) wspiscs (.ioout('0),.iooe('0),.iopu('1),.ioin(spis_cs_i),.ioifdrv(spis_csn_pad));
    wire2ioif #(N_SPIS) wspismosi (.ioout('0),.iooe('0),.iopu('1),.ioin(spis_mosi_i),.ioifdrv(spis_mosi_pad));
    wire2ioif #(N_SPIS) wspismiso (.ioout(spis_miso_o),.iooe(spis_miso_oe),.iopu('1),.ioin(),.ioifdrv(spis_miso_pad));

endmodule


module dummytb_ifsub1_intf ();
        parameter DW             = 32;
        parameter AW             = 18; // 256KB
        parameter AW32           = AW-2;
        parameter CAM_DW         = 8;
        parameter PAW            = 17;  //APB slaves are 4KB by default
        parameter TRANS_SIZE     = 20;  //max uDMA transaction size of 1MB
        parameter N_SPIM         = 4;
        parameter N_UART         = 4;
        parameter N_I2C          = 1;
//      parameter N_I2S          = 1;
        parameter N_CAM          = 1;
        parameter N_SDIO         = 1;
        parameter N_FILTER       = 1;
        parameter N_EXT_PER      = 1;
        parameter EVCNT          = 32*4;
        parameter N_SPIS         = 2;
         logic                 clk;
         logic                 resetn;
         logic                 perclk;
         logic                 cmsatpg;
         logic [EVCNT-1:0]    intr;
         logic              ifev_vld;
         logic [7:0]        ifev_dat;
         logic              ifev_rdy;
        apbif #(.PAW(PAW))                apbs();
        axiif #(.DW(32))               axim();
        ioif       spim_clk_pad[N_SPIM-1:0]();
        ioif       spim_csn0_pad[N_SPIM-1:0]();
        ioif       spim_csn1_pad[N_SPIM-1:0]();
        ioif       spim_csn2_pad[N_SPIM-1:0]();
        ioif       spim_csn3_pad[N_SPIM-1:0]();
        ioif       spim_sd0_pad[N_SPIM-1:0]();
        ioif       spim_sd1_pad[N_SPIM-1:0]();
        ioif       spim_sd2_pad[N_SPIM-1:0]();
        ioif       spim_sd3_pad[N_SPIM-1:0]();
        ioif      i2c_scl_pad[N_I2C-1:0] ();
        ioif      i2c_sda_pad[N_I2C-1:0] ();
        ioif      cam_clk_pad            ();
        ioif      cam_data_pad[CAM_DW-1:0]();
        ioif      cam_hsync_pad            ();
        ioif      cam_vsync_pad            ();
        ioif      uart_rx_pad[N_UART-1:0]();
        ioif      uart_tx_pad[N_UART-1:0]();
        ioif      sdio_clk_pad            ();
        ioif      sdio_cmd_pad            ();
        ioif      sdio_data_pad[3:0]       ();
        ioif      i2ss_sd_pad();
        ioif      i2ss_ws_pad();
        ioif      i2ss_sck_pad();
        ioif      i2sm_sd_pad();
        ioif      i2sm_ws_pad();
        ioif      i2sm_sck_pad();

        ioif      scif_sck_pad();
        ioif      scif_dat_pad();

        ioif      spis_clk_pad[N_SPIS-1:0]();
        ioif      spis_csn_pad[N_SPIS-1:0]();
        ioif      spis_mosi_pad[N_SPIS-1:0]();
        ioif      spis_miso_pad[N_SPIS-1:0]();
        wire [3:0] ana_adcsrc;
        wire clk16m;

ifsub1 u1(.*);

endmodule

