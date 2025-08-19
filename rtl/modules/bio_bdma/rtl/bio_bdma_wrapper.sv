// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: BSD-2-Clause
//
// This file may have been modified and is redistributed by CrossBar, Inc.
//
// You may redistribute and modify this documentation under the terms of the
// License. This documentation and source code is distributed WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTY, MERCHANTABILITY, SATISFACTORY QUALITY OR FITNESS FOR A
// PARTICULAR PURPOSE. Please see the License for the specific language governing
// permissions and limitations under the License.

// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-FileCopyrightText: 2022 Lawrie Griffiths
// SPDX-License-Identifier: BSD-2-Clause

// Integration wrapper for bio + dma

module bio_bdma_wrapper #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH = 6,
    parameter AXI_USER_WIDTH = 8,
    parameter AXI_STRB_WIDTH = 4,
    parameter AXI_DATA_WIDTH = 32,
    parameter APW = 12,  // APB address width
    parameter DW = 32,
    parameter AHW = 32,  // AHB address width
    parameter IDW = 4,
    parameter UW = 4
)(
    input logic fclk,  // clock of the BIO block itself
    input logic pclk,  // clock of the APB bus
    input logic hclk,  // clock of the AHB bus
    input logic resetn,
    input logic cmatpg, cmbist,
    input logic [2:0] sramtrm,

    input  wire          [31:0] gpio_in,
    output wire          [31:0] gpio_out,
    output wire          [31:0] gpio_dir,
    output wire           [3:0] irq,

    // AHB master DMA inteface (connected wires)
    output wire  [1:0]     htrans,         // Transfer type
    output wire            hwrite,         // Transfer direction
    output wire  [AHW-1:0] haddr,          // Address bus
    output wire  [2:0]     hsize,          // Transfer size
    output wire  [2:0]     hburst,         // Burst type
    output wire            hmasterlock,    // Locked Sequence
    output bit   [DW-1:0]  hwdata,         // Write data

    input  bit   [DW-1:0]  hrdata,         // Read data bus    // old hready
    input  wire            hready,         // HREADY feedback
    input                  hresp,          // Transfer response
    input        [UW-1:0]  hruser,

    // AHB NC wires
    output wire            hsel,           // Slave Select
    output wire  [3:0]     hprot,          // Protection control
    output wire  [IDW-1:0] hmaster,        //Master select
    input  wire            hreadym,       // Transfer done     // old hreadyin
    output wire  [UW-1:0]  hauser,
    output wire  [UW-1:0]  hwuser,

    // AXIM wires
    output [AXI_ADDR_WIDTH-1:0]  aw_addr,
    output [2:0]                 aw_prot,
    output [3:0]                 aw_region,
    output [7:0]                 aw_len,
    output [2:0]                 aw_size,
    output [1:0]                 aw_burst,
    output                       aw_lock,
    output [3:0]                 aw_cache,
    output [3:0]                 aw_qos,
    output [AXI_ID_WIDTH-1:0]    aw_id,
    output [AXI_USER_WIDTH-1:0]  aw_user,
    input                        aw_ready,
    output                       aw_valid,

    output [AXI_ADDR_WIDTH-1:0]  ar_addr,
    output [2:0]                 ar_prot,
    output [3:0]                 ar_region,
    output [7:0]                 ar_len,
    output [2:0]                 ar_size,
    output [1:0]                 ar_burst,
    output                       ar_lock,
    output [3:0]                 ar_cache,
    output [3:0]                 ar_qos,
    output [AXI_ID_WIDTH-1:0]    ar_id,
    output [AXI_USER_WIDTH-1:0]  ar_user,
    input                        ar_ready,
    output                       ar_valid,

    output                       w_valid,
    output [AXI_DATA_WIDTH-1:0]  w_data,
    output [AXI_STRB_WIDTH-1:0]  w_strb,
    output [AXI_USER_WIDTH-1:0]  w_user,
    output                       w_last,
    input                        w_ready,

    input [AXI_DATA_WIDTH-1:0]  r_data,
    input [1:0]                 r_resp,
    input                       r_last,
    input [AXI_ID_WIDTH-1:0]    r_id,
    input [AXI_USER_WIDTH-1:0]  r_user,
    output                      r_ready,
    input                       r_valid,

    input [1:0]                 b_resp,
    input [AXI_ID_WIDTH-1:0]    b_id,
    input [AXI_USER_WIDTH-1:0]  b_user,
    output                      b_ready,
    input                       b_valid,

    // APB configuration interface
    input  wire       [APW-1:0] PADDR,     // APB Address
    input  wire                 PENABLE,   // APB Enable
    input  wire                 PWRITE,    // APB Write
    input  wire           [3:0] PSTRB,     // APB Byte Strobe
    input  wire           [2:0] PPROT,     // APB Prot
    input  wire          [31:0] PWDATA,    // APB write data
    input  wire                 PSEL,      // APB Select
    input  wire                 APBACTIVE, // APB bus is active, for clock gating
                                           // of APB bus
                                           // APB Input
    output wire          [31:0] PRDATA,    // Read data for each APB slave
    output wire                 PREADY,    // Ready for each APB slave
    output wire                 PSLVERR,   // Error state for each APB slave

    input  wire       [APW-1:0] IM0_PADDR     ,
    input  wire                 IM0_PENABLE   ,
    input  wire                 IM0_PWRITE    ,
    input  wire           [3:0] IM0_PSTRB     ,
    input  wire           [2:0] IM0_PPROT     ,
    input  wire          [31:0] IM0_PWDATA    ,
    input  wire                 IM0_PSEL      ,
    input  wire                 IM0_APBACTIVE ,
    output wire          [31:0] IM0_PRDATA    ,
    output wire                 IM0_PREADY    ,
    output wire                 IM0_PSLVERR   ,

    input  wire       [APW-1:0] IM1_PADDR     ,
    input  wire                 IM1_PENABLE   ,
    input  wire                 IM1_PWRITE    ,
    input  wire           [3:0] IM1_PSTRB     ,
    input  wire           [2:0] IM1_PPROT     ,
    input  wire          [31:0] IM1_PWDATA    ,
    input  wire                 IM1_PSEL      ,
    input  wire                 IM1_APBACTIVE ,
    output wire          [31:0] IM1_PRDATA    ,
    output wire                 IM1_PREADY    ,
    output wire                 IM1_PSLVERR   ,

    input  wire       [APW-1:0] IM2_PADDR     ,
    input  wire                 IM2_PENABLE   ,
    input  wire                 IM2_PWRITE    ,
    input  wire           [3:0] IM2_PSTRB     ,
    input  wire           [2:0] IM2_PPROT     ,
    input  wire          [31:0] IM2_PWDATA    ,
    input  wire                 IM2_PSEL      ,
    input  wire                 IM2_APBACTIVE ,
    output wire          [31:0] IM2_PRDATA    ,
    output wire                 IM2_PREADY    ,
    output wire                 IM2_PSLVERR   ,

    input  wire       [APW-1:0] IM3_PADDR     ,
    input  wire                 IM3_PENABLE   ,
    input  wire                 IM3_PWRITE    ,
    input  wire           [3:0] IM3_PSTRB     ,
    input  wire           [2:0] IM3_PPROT     ,
    input  wire          [31:0] IM3_PWDATA    ,
    input  wire                 IM3_PSEL      ,
    input  wire                 IM3_APBACTIVE ,
    output wire          [31:0] IM3_PRDATA    ,
    output wire                 IM3_PREADY    ,
    output wire                 IM3_PSLVERR   ,

    input  wire       [APW-1:0] FP0_PADDR     ,
    input  wire                 FP0_PENABLE   ,
    input  wire                 FP0_PWRITE    ,
    input  wire           [3:0] FP0_PSTRB     ,
    input  wire           [2:0] FP0_PPROT     ,
    input  wire          [31:0] FP0_PWDATA    ,
    input  wire                 FP0_PSEL      ,
    input  wire                 FP0_APBACTIVE ,
    output wire          [31:0] FP0_PRDATA    ,
    output wire                 FP0_PREADY    ,
    output wire                 FP0_PSLVERR   ,

    input  wire       [APW-1:0] FP1_PADDR     ,
    input  wire                 FP1_PENABLE   ,
    input  wire                 FP1_PWRITE    ,
    input  wire           [3:0] FP1_PSTRB     ,
    input  wire           [2:0] FP1_PPROT     ,
    input  wire          [31:0] FP1_PWDATA    ,
    input  wire                 FP1_PSEL      ,
    input  wire                 FP1_APBACTIVE ,
    output wire          [31:0] FP1_PRDATA    ,
    output wire                 FP1_PREADY    ,
    output wire                 FP1_PSLVERR   ,

    input  wire       [APW-1:0] FP2_PADDR     ,
    input  wire                 FP2_PENABLE   ,
    input  wire                 FP2_PWRITE    ,
    input  wire           [3:0] FP2_PSTRB     ,
    input  wire           [2:0] FP2_PPROT     ,
    input  wire          [31:0] FP2_PWDATA    ,
    input  wire                 FP2_PSEL      ,
    input  wire                 FP2_APBACTIVE ,
    output wire          [31:0] FP2_PRDATA    ,
    output wire                 FP2_PREADY    ,
    output wire                 FP2_PSLVERR   ,

    input  wire       [APW-1:0] FP3_PADDR     ,
    input  wire                 FP3_PENABLE   ,
    input  wire                 FP3_PWRITE    ,
    input  wire           [3:0] FP3_PSTRB     ,
    input  wire           [2:0] FP3_PPROT     ,
    input  wire          [31:0] FP3_PWDATA    ,
    input  wire                 FP3_PSEL      ,
    input  wire                 FP3_APBACTIVE ,
    output wire          [31:0] FP3_PRDATA    ,
    output wire                 FP3_PREADY    ,
    output wire                 FP3_PSLVERR
);
    rbif  #(.AW(10   ),      .DW(32))    rbif_bioram1kx32    [0:3]();
    apbif #(.PAW(APW)) theapb();
    ahbif #(.AW(AHW),.DW(DW),.IDW(IDW),.UW(UW)) dma_ahb32();
    apbif #(.PAW(APW)) apb_imem[4](), apb_fifo[4]();
    parameter XUDW  = 8;     // axi userdata width
    parameter XLENW = 8;     // axi len width
    axiif #(
    .AW     ( 32     ),
    .DW     ( 32     ),
    .LENW   ( XLENW  ),
    .IDW    ( 6      ),
    .UW     ( XUDW   )
    ) dma_axi();

    apb_wire2ifm #(
      .AW(APW)
     )apbtrans(
        .apbmaster    (theapb),
        .psel         (PSEL),
        .paddr        (PADDR),
        .penable      (PENABLE),
        .pwrite       (PWRITE),
        .pstrb        (PSTRB),
        .pprot        (PPROT),
        .pwdata       (PWDATA),
        .apbactive    (APBACTIVE),
        .prdata       (PRDATA),
        .pready       (PREADY),
        .pslverr      (PSLVERR)
    );

    apb_wire2ifm #(
      .AW(APW)
    )apbtrans_im0(
        .apbmaster    (apb_imem[0]),
        .psel         (IM0_PSEL       ),
        .paddr        (IM0_PADDR      ),
        .penable      (IM0_PENABLE    ),
        .pwrite       (IM0_PWRITE     ),
        .pstrb        (IM0_PSTRB      ),
        .pprot        (IM0_PPROT      ),
        .pwdata       (IM0_PWDATA     ),
        .apbactive    (IM0_APBACTIVE  ),
        .prdata       (IM0_PRDATA     ),
        .pready       (IM0_PREADY     ),
        .pslverr      (IM0_PSLVERR    )
    );

    apb_wire2ifm #(
      .AW(APW)
    )apbtrans_im1(
        .apbmaster    (apb_imem[1]),
        .psel         (IM1_PSEL       ),
        .paddr        (IM1_PADDR      ),
        .penable      (IM1_PENABLE    ),
        .pwrite       (IM1_PWRITE     ),
        .pstrb        (IM1_PSTRB      ),
        .pprot        (IM1_PPROT      ),
        .pwdata       (IM1_PWDATA     ),
        .apbactive    (IM1_APBACTIVE  ),
        .prdata       (IM1_PRDATA     ),
        .pready       (IM1_PREADY     ),
        .pslverr      (IM1_PSLVERR    )
    );

    apb_wire2ifm #(
      .AW(APW)
    )apbtrans_im2(
        .apbmaster    (apb_imem[2]),
        .psel         (IM2_PSEL       ),
        .paddr        (IM2_PADDR      ),
        .penable      (IM2_PENABLE    ),
        .pwrite       (IM2_PWRITE     ),
        .pstrb        (IM2_PSTRB      ),
        .pprot        (IM2_PPROT      ),
        .pwdata       (IM2_PWDATA     ),
        .apbactive    (IM2_APBACTIVE  ),
        .prdata       (IM2_PRDATA     ),
        .pready       (IM2_PREADY     ),
        .pslverr      (IM2_PSLVERR    )
    );

    apb_wire2ifm #(
      .AW(APW)
    )apbtrans_im3(
        .apbmaster    (apb_imem[3]),
        .psel         (IM3_PSEL       ),
        .paddr        (IM3_PADDR      ),
        .penable      (IM3_PENABLE    ),
        .pwrite       (IM3_PWRITE     ),
        .pstrb        (IM3_PSTRB      ),
        .pprot        (IM3_PPROT      ),
        .pwdata       (IM3_PWDATA     ),
        .apbactive    (IM3_APBACTIVE  ),
        .prdata       (IM3_PRDATA     ),
        .pready       (IM3_PREADY     ),
        .pslverr      (IM3_PSLVERR    )
    );

    apb_wire2ifm #(
      .AW(APW)
    )apbtrans_fp0(
        .apbmaster    (apb_fifo[0]),
        .psel         (FP0_PSEL       ),
        .paddr        (FP0_PADDR      ),
        .penable      (FP0_PENABLE    ),
        .pwrite       (FP0_PWRITE     ),
        .pstrb        (FP0_PSTRB      ),
        .pprot        (FP0_PPROT      ),
        .pwdata       (FP0_PWDATA     ),
        .apbactive    (FP0_APBACTIVE  ),
        .prdata       (FP0_PRDATA     ),
        .pready       (FP0_PREADY     ),
        .pslverr      (FP0_PSLVERR    )
    );

    apb_wire2ifm #(
      .AW(APW)
    )apbtrans_fp1(
        .apbmaster    (apb_fifo[1]),
        .psel         (FP1_PSEL       ),
        .paddr        (FP1_PADDR      ),
        .penable      (FP1_PENABLE    ),
        .pwrite       (FP1_PWRITE     ),
        .pstrb        (FP1_PSTRB      ),
        .pprot        (FP1_PPROT      ),
        .pwdata       (FP1_PWDATA     ),
        .apbactive    (FP1_APBACTIVE  ),
        .prdata       (FP1_PRDATA     ),
        .pready       (FP1_PREADY     ),
        .pslverr      (FP1_PSLVERR    )
    );

    apb_wire2ifm #(
      .AW(APW)
    )apbtrans_fp2(
        .apbmaster    (apb_fifo[2]),
        .psel         (FP2_PSEL       ),
        .paddr        (FP2_PADDR      ),
        .penable      (FP2_PENABLE    ),
        .pwrite       (FP2_PWRITE     ),
        .pstrb        (FP2_PSTRB      ),
        .pprot        (FP2_PPROT      ),
        .pwdata       (FP2_PWDATA     ),
        .apbactive    (FP2_APBACTIVE  ),
        .prdata       (FP2_PRDATA     ),
        .pready       (FP2_PREADY     ),
        .pslverr      (FP2_PSLVERR    )
    );

    apb_wire2ifm #(
      .AW(APW)
    )apbtrans_fp3(
        .apbmaster    (apb_fifo[3]),
        .psel         (FP3_PSEL       ),
        .paddr        (FP3_PADDR      ),
        .penable      (FP3_PENABLE    ),
        .pwrite       (FP3_PWRITE     ),
        .pstrb        (FP3_PSTRB      ),
        .pprot        (FP3_PPROT      ),
        .pwdata       (FP3_PWDATA     ),
        .apbactive    (FP3_APBACTIVE  ),
        .prdata       (FP3_PRDATA     ),
        .pready       (FP3_PREADY     ),
        .pslverr      (FP3_PSLVERR    )
    );

    ahb_ifs2wire_bdma ahbtrans(
        .ahbslave     (dma_ahb32      ),
        .hsel         (hsel           ),
        .haddr        (haddr          ),
        .htrans       (htrans         ),
        .hwrite       (hwrite         ),
        .hsize        (hsize          ),
        .hburst       (hburst         ),
        .hprot        (hprot          ),
        .hmaster      (hmaster        ),
        .hwdata       (hwdata         ),
        .hmasterlock  (hmasterlock    ),
        // .hreadym      (hready         ),
        .hrdata       (hrdata         ),
        .hready       (hready        ),
        .hresp        (hresp          )
    );

    // no off the shelf primitive for this, so we do it by hand.
    assign aw_addr    = dma_axi.awaddr      ;
    assign aw_prot    = dma_axi.awprot      ;
    // assign aw_region  = dma_axi.awregion      ;
    assign aw_len     = dma_axi.awlen      ;
    assign aw_size    = dma_axi.awsize      ;
    assign aw_burst   = dma_axi.awburst      ;
    assign aw_lock    = dma_axi.awlock      ;
    assign aw_cache   = dma_axi.awcache      ;
    // assign aw_qos     = dma_axi.awqos      ;
    assign aw_id      = dma_axi.awid      ;
    assign aw_user    = dma_axi.awuser      ;
    assign dma_axi.awready   = aw_ready      ;
    assign aw_valid   = dma_axi.awvalid      ;

    assign ar_addr    = dma_axi.araddr      ;
    assign ar_prot    = dma_axi.arprot      ;
    // assign ar_region  = dma_axi.arregion      ;
    assign ar_len     = dma_axi.arlen      ;
    assign ar_size    = dma_axi.arsize      ;
    assign ar_burst   = dma_axi.arburst      ;
    assign ar_lock    = dma_axi.arlock      ;
    assign ar_cache   = dma_axi.arcache      ;
    // assign ar_qos     = dma_axi.arqos      ;
    assign ar_id      = dma_axi.arid      ;
    assign ar_user    = dma_axi.aruser      ;
    assign dma_axi.arready   = ar_ready      ;
    assign ar_valid   = dma_axi.arvalid      ;

    assign w_valid    = dma_axi.wvalid      ;
    assign w_data     = dma_axi.wdata      ;
    assign w_strb     = dma_axi.wstrb      ;
    assign w_user     = dma_axi.wuser      ;
    assign w_last     = dma_axi.wlast      ;
    assign dma_axi.wready    = w_ready      ;

    assign dma_axi.rdata     = r_data      ;
    assign dma_axi.rresp     = r_resp      ;
    assign dma_axi.rlast     = r_last      ;
    assign dma_axi.rid       = r_id      ;
    assign dma_axi.ruser     = r_user      ;
    assign r_ready    = dma_axi.rready      ;
    assign dma_axi.rvalid    = r_valid      ;

    assign dma_axi.bresp     = b_resp      ;
    assign dma_axi.bid       = b_id      ;
    assign dma_axi.buser     = b_user      ;
    assign b_ready    = dma_axi.bready      ;
    assign dma_axi.bvalid    = b_valid      ;

    ioif  bio_gpio[0:31]();
    generate
        for (genvar j = 0; j < 32; j++) begin:gp
            assign gpio_out[j] = bio_gpio[j].po;
            assign gpio_dir[j] = bio_gpio[j].oe;
            assign bio_gpio[j].pi = gpio_in[j];
        end
    endgenerate

    // feed our IRQ back as a dmareq - this approximates how the system actually works
    logic [191:0] dmareq;
    always_ff @(posedge pclk) begin
        dmareq = {57'b0,irq[3:0],83'b0,48'b0};
    end

    bio_bdma bio_bdma(
        .aclk    (fclk),
        .pclk    ,
        .hclk    (fclk), // because in verilator this is actually the clock used; we'll hash out the final CDC on the full chip sim
        .dmaclk  (fclk),
        .reset_n (resetn),
        .cmatpg  ,
        .cmbist  ,
        .sramtrm ,
        .bio_gpio,
        .rbif_bioram1kx32,
        .irq     (irq),
        .dmareq  (dmareq),
        .apbs    (theapb),
        .apbx    (theapb),
        .apbs_imem(apb_imem),
        .apbx_imem(apb_imem),
        .apbs_fifo(apb_fifo),
        .apbx_fifo(apb_fifo),
        .ahbm    (dma_ahb32),
        .axim    (dma_axi)
    );
endmodule

//
//  ahb_ifs2wire,ahb_wire2ifm,apb_ifs2wire,apb_wire2ifm
//  ==

module ahb_ifs2wire_bdma #(
    parameter AW=32,
    parameter DW=32
    )(
    ahbif.slave             ahbslave,
    output  logic           hsel,           // Slave Select
    output  logic  [AW-1:0] haddr,          // Address bus
    output  logic  [1:0]    htrans,         // Transfer type
    output  logic           hwrite,         // Transfer direction
    output  logic  [2:0]    hsize,          // Transfer size
    output  logic  [2:0]    hburst,         // Burst type
    output  logic  [3:0]    hprot,          // Protection control
    output  logic  [3:0]    hmaster,        //Master select
    output  logic  [DW-1:0] hwdata,         // Write data
    output  logic           hmasterlock,    // Locked Sequence
    output  logic           hreadym,       // Transfer done
    input   logic  [DW-1:0] hrdata,         // Read data bus
    input   logic           hready,         // HREADY feedback
    input   logic           hresp          // Transfer response
);

    assign hsel        = ahbslave.hsel        ;
    assign haddr       = ahbslave.haddr       ;
    assign htrans      = ahbslave.htrans      ;
    assign hwrite      = ahbslave.hwrite      ;
    assign hsize       = ahbslave.hsize       ;
    assign hburst      = ahbslave.hburst      ;
    assign hprot       = ahbslave.hprot       ;
    assign hmaster     = ahbslave.hmaster     ;
    assign hwdata      = ahbslave.hwdata      ;
    assign hmasterlock = ahbslave.hmasterlock ;
    assign hreadym    = ahbslave.hreadym    ;
    assign ahbslave.hrdata      = hrdata      ;
    assign ahbslave.hready      = hready      ;
    assign ahbslave.hresp       = hresp       ;

endmodule

module ahb_wire2ifm_bdma #(
    parameter AW=32,
    parameter DW=32
    )(
    ahbif.master            ahbmaster,
    input   logic           hsel,           // Slave Select
    input   logic  [AW-1:0] haddr,          // Address bus
    input   logic  [1:0]    htrans,         // Transfer type
    input   logic           hwrite,         // Transfer direction
    input   logic  [2:0]    hsize,          // Transfer size
    input   logic  [2:0]    hburst,         // Burst type
    input   logic  [3:0]    hprot,          // Protection control
    input   logic  [3:0]    hmaster,        //Master select
    input   logic  [DW-1:0] hwdata,         // Write data
    input   logic           hmasterlock,    // Locked Sequence
    input   logic           hreadym,       // Transfer done
    output  logic  [DW-1:0] hrdata,         // Read data bus
    output  logic           hready,         // HREADY feedback
    output  logic           hresp          // Transfer response
);

    assign ahbmaster.hsel        = hsel        ;
    assign ahbmaster.haddr       = haddr       ;
    assign ahbmaster.htrans      = htrans      ;
    assign ahbmaster.hwrite      = hwrite      ;
    assign ahbmaster.hsize       = hsize       ;
    assign ahbmaster.hburst      = hburst      ;
    assign ahbmaster.hprot       = hprot       ;
    assign ahbmaster.hmaster     = hmaster     ;
    assign ahbmaster.hwdata      = hwdata      ;
    assign ahbmaster.hmasterlock = hmasterlock ;
    assign ahbmaster.hreadym    = hreadym    ;
    assign hrdata      = ahbmaster.hrdata      ;
    assign hready      = ahbmaster.hready      ;
    assign hresp       = ahbmaster.hresp       ;

endmodule
