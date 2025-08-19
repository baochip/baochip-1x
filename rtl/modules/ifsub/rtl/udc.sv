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


module udc #(
        parameter bit[31:0] BA   = 32'h5000_0000,
        parameter bit [3:0] AHBMID4 = 4'hb
    )(
    input bit   clk,
    input bit   clkao25m,
    input bit   resetn,
    input bit   cmsatpg,
    input bit   cmsbist,
    rbif.slavedp    rbif_udcmem_share  [0:0] ,
    rbif.slavedp    rbif_udcmem_odb    [0:0] ,
    rbif.slavedp    rbif_udcmem_256x64 [0:0] ,

    ahbif.master    ahbm,
    ahbif.slave     ahbs,

    `UTMI_IF_DEF

    output logic irq
);

    parameter   SS_ODB_SIZE = 4;
    parameter   HS_ODB_SIZE = 2;
    parameter   SS_IDB_SIZE = 2;
    parameter   HS_IDB_SIZE = 1;
    parameter   DBC_EP1_ODB_SIZE = 2;
    parameter   DEV_EP0_ODB_SIZE  = 3;
    parameter   DEV_EP1_ODB_SIZE  = 5;
    parameter   DEV_EP2_ODB_SIZE  = 5;
    parameter   DEV_EP3_ODB_SIZE  = 5;
    parameter   DEV_EP4_ODB_SIZE  = 5;
    parameter   DEV_EP5_ODB_SIZE  = 5;
    parameter   DEV_EP6_ODB_SIZE  = 5;
    parameter   DEV_EP7_ODB_SIZE  = 5;
    parameter   DEV_EP8_ODB_SIZE  = 5;
    parameter   DEV_EP9_ODB_SIZE  = 5;
    parameter   DEV_EP10_ODB_SIZE = 5;
    parameter   DEV_EP11_ODB_SIZE = 5;
    parameter   DEV_EP12_ODB_SIZE = 5;
    parameter   DEV_EP13_ODB_SIZE = 5;
    parameter   DEV_EP14_ODB_SIZE = 5;
    parameter   DEV_EP15_ODB_SIZE = 5;
    parameter   DEV_EP0_ODB_OFFSET  = 0;
    parameter   DEV_EP1_ODB_OFFSET  = 8;
    parameter   DEV_EP2_ODB_OFFSET  = 40;
    parameter   DEV_EP3_ODB_OFFSET  = 72;
    parameter   DEV_EP4_ODB_OFFSET  = 104;
    parameter   DEV_EP5_ODB_OFFSET  = 0;
    parameter   DEV_EP6_ODB_OFFSET  = 0;
    parameter   DEV_EP7_ODB_OFFSET  = 0;
    parameter   DEV_EP8_ODB_OFFSET  = 0;
    parameter   DEV_EP9_ODB_OFFSET  = 0;
    parameter   DEV_EP10_ODB_OFFSET = 0;
    parameter   DEV_EP11_ODB_OFFSET = 0;
    parameter   DEV_EP12_ODB_OFFSET = 0;
    parameter   DEV_EP13_ODB_OFFSET = 0;
    parameter   DEV_EP14_ODB_OFFSET = 0;
    parameter   DEV_EP15_ODB_OFFSET = 0;
    parameter   ODB_RAM_DEPTH = 1088;
    parameter ODB_ADDR_WIDTH = $clog2(ODB_RAM_DEPTH);
    parameter SS_ODB_LOG = $clog2(SS_ODB_SIZE);
    parameter HS_ODB_LOG = $clog2(HS_ODB_SIZE);
    parameter SS_IDB_LOG = $clog2(SS_IDB_SIZE);
    parameter HS_IDB_LOG = $clog2(HS_IDB_SIZE);

    parameter ODB_MEM_LOG = $clog2(ODB_RAM_DEPTH) - 7;

    parameter IDB_MEM_LOG = $clog2( (SS_IDB_SIZE==1 ? 0 : SS_IDB_SIZE) + (HS_IDB_SIZE==1 ? 0 : HS_IDB_SIZE) );
    parameter IDB_ADDR_WIDTH = IDB_MEM_LOG+7;
    parameter MPDBC_MEM_LOG = $clog2(DBC_EP1_ODB_SIZE+1);
    parameter DBC_EP1_ODB_LOG = $clog2(DBC_EP1_ODB_SIZE );
    parameter SS_IN_BUF_WIDTH = $clog2(SS_IDB_SIZE+1);

    parameter HS_ODB_RAM_DEPTH = HS_ODB_SIZE*64;
    parameter HS_IDB_RAM_DEPTH = HS_IDB_SIZE*64;


    localparam   IDB_RAM_DEPTH = ( (SS_IDB_SIZE==1 ? 0 : SS_IDB_SIZE) + (HS_IDB_SIZE==1 ? 0 : HS_IDB_SIZE) ) * 128;
    localparam   SHARE_MEM_DEPTH = 928;
    localparam   SHARE_MEM_ADDR_WIDTH = 10;

    parameter AXI_AW   = 32;
    parameter AXI_IDW  = 9;
    parameter AXI_LENW = 4;
    parameter HAW = 16;

    axiif #(.IDW(AXI_IDW),.LENW(AXI_LENW))axim();
    ahbif #(.DW(64)) ahbm64();

    logic [63:0]    axim_awaddr_64, axim_araddr_64;
    logic [1:0]     ahbs_hresp;

    assign axim.awaddr = BA + axim_awaddr_64[17:0] ;
    assign axim.araddr = BA + axim_araddr_64[17:0] ;
    assign ahbs.hresp = ahbs_hresp[0];

    wire                                share_mem_ren;
    wire [9:0]                          share_mem_raddr;

    wire [63:0]                         share_mem_rdata;
    wire                                share_mem_wen;
    wire [9:0]                          share_mem_waddr;
    wire [63:0]                         share_mem_wdata;
    wire                                odb_mem_ren;
    wire [ODB_ADDR_WIDTH-1:0]           odb_mem_raddr;
    wire [63:0]                         odb_mem_rdata;
    wire                                odb_mem_wen;
    wire [ODB_ADDR_WIDTH-1:0]           odb_mem_waddr;
    wire [63:0]                         odb_mem_wdata;

    wire                                idb_mem_ren;
    wire [IDB_ADDR_WIDTH-1:0]           idb_mem_raddr;
    wire [63:0]                         idb_mem_rdata;
    wire                                idb_mem_wen;
    wire [IDB_ADDR_WIDTH-1:0]           idb_mem_waddr;
    wire [63:0]                         idb_mem_wdata;
    wire host_sys_err_out, device_mode_en, u2p0_utmi_databus16_8, u2p0_utmi_drvvbus;

    wire xhci_clk ;
    wire mst_clk  ;
    wire slv_clk  ;
    wire buf_clk  ;
    wire xhci_rst_n;
    wire buf_rst_n;
    wire mst_rst_n;
    wire pwr_rst_n;
    assign xhci_clk = clk;
    assign mst_clk  = clk;
    assign slv_clk  = clk;
    assign buf_clk  = clk;

//    assign xhci_rst_n = resetn;
//    assign buf_rst_n = resetn;
//    assign mst_rst_n = resetn;
    assign pwr_rst_n = resetn;

    logic [1:0] axim_awlock2, axim_arlock2;
    assign axim.awlock = axim_awlock2;
    assign axim.arlock = axim_arlock2;

    logic scanmode_rst;
    assign scanmode_rst = cmsatpg & resetn;

xhci_top  #(
    .SS_ODB_SIZE         ( SS_ODB_SIZE ),
    .HS_ODB_SIZE         ( HS_ODB_SIZE ),
    .SS_IDB_SIZE         ( SS_IDB_SIZE ),
    .HS_IDB_SIZE         ( HS_IDB_SIZE ),
    .DBC_EP1_ODB_SIZE    ( DBC_EP1_ODB_SIZE ),
    .DEV_EP0_ODB_SIZE    ( DEV_EP0_ODB_SIZE  ),
    .DEV_EP1_ODB_SIZE    ( DEV_EP1_ODB_SIZE  ),
    .DEV_EP2_ODB_SIZE    ( DEV_EP2_ODB_SIZE  ),
    .DEV_EP3_ODB_SIZE    ( DEV_EP3_ODB_SIZE  ),
    .DEV_EP4_ODB_SIZE    ( DEV_EP4_ODB_SIZE  ),
    .DEV_EP5_ODB_SIZE    ( DEV_EP5_ODB_SIZE  ),
    .DEV_EP6_ODB_SIZE    ( DEV_EP6_ODB_SIZE  ),
    .DEV_EP7_ODB_SIZE    ( DEV_EP7_ODB_SIZE  ),
    .DEV_EP8_ODB_SIZE    ( DEV_EP8_ODB_SIZE  ),
    .DEV_EP9_ODB_SIZE    ( DEV_EP9_ODB_SIZE  ),
    .DEV_EP10_ODB_SIZE   ( DEV_EP10_ODB_SIZE ),
    .DEV_EP11_ODB_SIZE   ( DEV_EP11_ODB_SIZE ),
    .DEV_EP12_ODB_SIZE   ( DEV_EP12_ODB_SIZE ),
    .DEV_EP13_ODB_SIZE   ( DEV_EP13_ODB_SIZE ),
    .DEV_EP14_ODB_SIZE   ( DEV_EP14_ODB_SIZE ),
    .DEV_EP15_ODB_SIZE   ( DEV_EP15_ODB_SIZE ),
    .DEV_EP0_ODB_OFFSET  (DEV_EP0_ODB_OFFSET  ),
    .DEV_EP1_ODB_OFFSET  (DEV_EP1_ODB_OFFSET  ),
    .DEV_EP2_ODB_OFFSET  (DEV_EP2_ODB_OFFSET  ),
    .DEV_EP3_ODB_OFFSET  (DEV_EP3_ODB_OFFSET  ),
    .DEV_EP4_ODB_OFFSET  (DEV_EP4_ODB_OFFSET  ),
    .DEV_EP5_ODB_OFFSET  (DEV_EP5_ODB_OFFSET  ),
    .DEV_EP6_ODB_OFFSET  (DEV_EP6_ODB_OFFSET  ),
    .DEV_EP7_ODB_OFFSET  (DEV_EP7_ODB_OFFSET  ),
    .DEV_EP8_ODB_OFFSET  (DEV_EP8_ODB_OFFSET  ),
    .DEV_EP9_ODB_OFFSET  (DEV_EP9_ODB_OFFSET  ),
    .DEV_EP10_ODB_OFFSET (DEV_EP10_ODB_OFFSET ),
    .DEV_EP11_ODB_OFFSET (DEV_EP11_ODB_OFFSET ),
    .DEV_EP12_ODB_OFFSET (DEV_EP12_ODB_OFFSET ),
    .DEV_EP13_ODB_OFFSET (DEV_EP13_ODB_OFFSET ),
    .DEV_EP14_ODB_OFFSET (DEV_EP14_ODB_OFFSET ),
    .DEV_EP15_ODB_OFFSET (DEV_EP15_ODB_OFFSET ),
    .ODB_RAM_DEPTH      ( ODB_RAM_DEPTH )
)u (
    .xhci_clk           (xhci_clk),
    .mst_clk            (mst_clk),
    .slv_clk            (slv_clk),
    .buf_clk            (buf_clk),
    .aon_clk            (clkao25m),
    .pwr_rst_n          (pwr_rst_n),
    .buf_rst_n          (buf_rst_n),
    .xhci_rst_n         (xhci_rst_n),
    .mst_rst_n          (mst_rst_n),
    .device_mode_en     (device_mode_en),
    .u3_sstx_sel        (),
    .u3_ssrx_sel        (),
    .mst_awvalid        (axim.awvalid),
    .mst_awid           (axim.awid[AXI_IDW-1:0]),
    .mst_awaddr         (axim_awaddr_64),
    .mst_awlen          (axim.awlen[AXI_LENW-1:0]),
    .mst_awsize         (axim.awsize),
    .mst_awburst        (axim.awburst),
    .mst_awlock         (axim_awlock2),
    .mst_awcache        (axim.awcache),
    .mst_awprot         (axim.awprot),
    .mst_awready        (axim.awready),
    .mst_arid           (axim.arid[AXI_IDW-1:0]),
    .mst_araddr         (axim_araddr_64),
    .mst_arlen          (axim.arlen[AXI_LENW-1:0]),
    .mst_arsize         (axim.arsize),
    .mst_arburst        (axim.arburst),
    .mst_arlock         (axim_arlock2),
    .mst_arcache        (axim.arcache),
    .mst_arprot         (axim.arprot),
    .mst_arvalid        (axim.arvalid),
    .mst_arready        (axim.arready),
    .mst_wdata          (axim.wdata),
    .mst_wstrb          (axim.wstrb),
    .mst_wlast          (axim.wlast),
    .mst_wvalid         (axim.wvalid),
    .mst_wready         (axim.wready),
    .mst_rid            (axim.rid[AXI_IDW-1:0]),
    .mst_rdata          (axim.rdata),
    .mst_rresp          (axim.rresp),
    .mst_rlast          (axim.rlast),
    .mst_rvalid         (axim.rvalid),
    .mst_rready         (axim.rready),
    .mst_bid            (axim.bid[AXI_IDW-1:0]),
    .mst_bresp          (axim.bresp),
    .mst_bvalid         (axim.bvalid),
    .mst_bready         (axim.bready),

    .slv_hselx          (ahbs.hsel),
    .slv_haddr          (ahbs.haddr[HAW-1:0]),
    .slv_hwrite         (ahbs.hwrite),
    .slv_hsize          (ahbs.hsize),
    .slv_hburst         (ahbs.hburst),
    .slv_htrans         (ahbs.htrans),
    .slv_hmastlock      (ahbs.hmasterlock),
    .slv_hready         (ahbs.hreadym),
    .slv_hwdata         (ahbs.hwdata),
    .slv_hreadyout      (ahbs.hready),
    .slv_hresp          (ahbs_hresp),
    .slv_hrdata         (ahbs.hrdata),

    .int_legacy0         (irq     ),
    .share_mem_ren       (share_mem_ren),
    .share_mem_raddr     (share_mem_raddr),
    .share_mem_rdata     (share_mem_rdata),
    .share_mem_wen       (share_mem_wen),
    .share_mem_waddr     (share_mem_waddr),
    .share_mem_wdata     (share_mem_wdata),
    .odb_mem_ren         (odb_mem_ren),
    .odb_mem_raddr       (odb_mem_raddr),
    .odb_mem_rdata       (odb_mem_rdata),
    .odb_mem_wen         (odb_mem_wen),
    .odb_mem_waddr       (odb_mem_waddr),
    .odb_mem_wdata       (odb_mem_wdata),

    .idb_mem_ren         (idb_mem_ren),
    .idb_mem_raddr       (idb_mem_raddr),
    .idb_mem_rdata       (idb_mem_rdata),
    .idb_mem_wen         (idb_mem_wen),
    .idb_mem_waddr       (idb_mem_waddr),
    .idb_mem_wdata       (idb_mem_wdata),

	.host_sys_err_out      (host_sys_err_out),
    .scanmode_rst          (scanmode_rst),
	.scanmode_clk		   (clk),
    .scanmode_lp		   (1'b0),

    .force_dev_mode        (1'b0),

    .utmi0_clk          (utmi_clk),
    .u2p0_external_rst  (u2p0_external_rst   ),
    .u2p0_utmi_xcvrselect      (utmi_xcvrselect),
    .u2p0_utmi_termselect      (utmi_termselect),
    .u2p0_utmi_suspendm        (utmi_suspendm),
    .u2p0_utmi_linestate       (utmi_linestate),
    .u2p0_utmi_opmode          (utmi_opmode),
    .u2p0_utmi_datain7_0       (utmi_datain7_0),
    .u2p0_utmi_datain15_8      (),
    .u2p0_utmi_txvalid         (utmi_txvalid),
    .u2p0_utmi_txvalidh        (),
    .u2p0_utmi_txready         (utmi_txready),
    .u2p0_utmi_dataout7_0      (utmi_dataout7_0),
    .u2p0_utmi_dataout15_8     ('0),
    .u2p0_utmi_rxvalid         (utmi_rxvalid),
    .u2p0_utmi_rxvalidh        ('0),
    .u2p0_utmi_rxactive        (utmi_rxactive),
    .u2p0_utmi_rxerror         (utmi_rxerror),
    .u2p0_utmi_databus16_8     (u2p0_utmi_databus16_8),
    .u2p0_utmi_drvvbus         (u2p0_utmi_drvvbus),
    .u2p0_utmi_dppulldown      (utmi_dppulldown),
    .u2p0_utmi_dmpulldown      (utmi_dmpulldown),
    .u2p0_utmi_hostdisconnect  (utmi_hostdisconnect),

    .u2p0_pb_oca               ('0),
    .ltssm_st(),
    .present_st()
);


    assign axim.awsparse = '1;
    assign axim.armaster = '0;
    assign axim.arinner  = '0;
    assign axim.arshare  = '0;
    assign axim.aruser   = AHBMID4 | '0;
    assign axim.awmaster = '0;
    assign axim.awinner  = '0;
    assign axim.awshare  = '0;
    assign axim.awuser   = AHBMID4 | '0;
    assign axim.wuser    = '0;

axi_ahb_bdg #(
    .AW( 32 ),
    .DW( 64 )
  ) aab (
    .clk,
    .resetn,
    .axislave(axim),
    .ahbmaster(ahbm64)
  );


  ahb_downsizer ahbds(.ahbslave(ahbm64),.ahbmaster(ahbm),.hclk(clk),.resetn(resetn));

two_ports_async_mem2 #(
        .MEM_WIDTH(64),
        .MEM_ADDR_WIDTH(SHARE_MEM_ADDR_WIDTH+1),
        .MEM_DEPTH(SHARE_MEM_DEPTH)
        )
        share_mem(
          .cmsbist (cmsbist),
          .cmsatpg (cmsatpg),
          .rbs(rbif_udcmem_share[0]),
          .rd_clk(xhci_clk),
          .rd_rst_n(xhci_rst_n),
          .rd_en(share_mem_ren),
          .rd_addr(share_mem_raddr|11'h0),
          .rd_data(share_mem_rdata),

          .wr_clk(xhci_clk),
          .wr_rst_n(xhci_rst_n),
          .wr_en(share_mem_wen),
          .wr_addr(share_mem_waddr|11'h0),
          .wr_data(share_mem_wdata)
        );


two_ports_async_mem2 #(

        .MEM_WIDTH(64),
        .MEM_ADDR_WIDTH(ODB_ADDR_WIDTH),
        .MEM_DEPTH(ODB_RAM_DEPTH)       )
        odb_mem(
          .cmsbist (cmsbist),
          .cmsatpg (cmsatpg),
          .rbs(rbif_udcmem_odb[0]),
        .rd_clk  (buf_clk),
        .rd_rst_n(buf_rst_n),
        .rd_en   (odb_mem_ren),
        .rd_addr (odb_mem_raddr),
        .rd_data (odb_mem_rdata),


        .wr_clk(mst_clk),
        .wr_rst_n(mst_rst_n),
        .wr_en   (odb_mem_wen),
        .wr_addr (odb_mem_waddr),
        .wr_data (odb_mem_wdata));

two_ports_async_mem2 #(

        .MEM_WIDTH(64),
        .MEM_ADDR_WIDTH(IDB_ADDR_WIDTH),
        .MEM_DEPTH(IDB_RAM_DEPTH)
        )
        idb_mem(
          .cmsbist (cmsbist),
          .cmsatpg (cmsatpg),
          .rbs(rbif_udcmem_256x64[0]),
        .rd_clk(mst_clk),
        .rd_rst_n(mst_rst_n),
        .rd_en(idb_mem_ren),
        .rd_addr(idb_mem_raddr),
        .rd_data(idb_mem_rdata),


        .wr_clk(buf_clk),
        .wr_rst_n(buf_rst_n),
        .wr_en(idb_mem_wen),
        .wr_addr(idb_mem_waddr),
        .wr_data(idb_mem_wdata)
        );

endmodule


//`include "rtl/model/artisan_ram_def_v0.1.svh"
module two_ports_async_mem2(
        cmsatpg,
        cmsbist,
        rbs,
        rd_clk,
        rd_rst_n,
        rd_en,
        rd_addr,
        rd_data,

        wr_clk,
        wr_rst_n,
        wr_en,
        wr_addr,
        wr_data
        );
parameter MEM_WIDTH = 64;
parameter MEM_ADDR_WIDTH = 10;
parameter MEM_DEPTH = 1<<MEM_ADDR_WIDTH;

    input   wire    cmsatpg;
    input   wire    cmsbist;
    rbif.slavedp    rbs;
    input    wire    rd_clk;
    input    wire    rd_rst_n;
    input    wire    rd_en;
    input    wire    [MEM_ADDR_WIDTH-1:0] rd_addr;
    output           [MEM_WIDTH-1:0] rd_data;

    input    wire    wr_clk;
    input    wire    wr_rst_n;
    input    wire    wr_en;
    input    wire    [MEM_ADDR_WIDTH-1:0] wr_addr;
    input    wire    [MEM_WIDTH-1:0] wr_data;

    reg          [MEM_WIDTH-1:0] rd_data;

    localparam AW = MEM_ADDR_WIDTH;
    localparam DW = MEM_WIDTH;

`ifdef FPGA
generate
    for (genvar i = 0; i < 4; i++) begin:gbram
    bramdp #(.AW(11),.DW(16))u(
        .rclk(rd_clk),
        .wclk(wr_clk),
        .rramaddr(rd_addr|11'h0),
        .wramaddr(wr_addr|11'h0),
        .rramrd(rd_en),
        .wramwr(wr_en),
        .rramrdata(rd_data[i*16+15:i*16]),
        .wramwdata(wr_data[i*16+15:i*16])
        );
    end
endgenerate
`else
/*
reg          [MEM_WIDTH-1:0] mem_array [MEM_DEPTH-1:0];
integer i;

always@(posedge wr_clk or negedge wr_rst_n)
begin
  if(!wr_rst_n)
    for(i=0;i<MEM_DEPTH;i=i+1)
    begin
      mem_array[i]<={MEM_WIDTH{1'b0}};
    end
  else if(wr_en)
    mem_array[wr_addr]<=wr_data;
end

always@(posedge rd_clk or negedge rd_rst_n)
begin
  if(!rd_rst_n)
    rd_data<={MEM_WIDTH{1'b0}};
  else if(rd_en)
    rd_data<= mem_array[rd_addr];
end
*/

    logic clka, clkb, cena, cenb;

    ICG icga(.CK(rd_clk),.EN(~cena),.SE(cmsatpg),.CKG(clka));
    ICG icgb(.CK(wr_clk),.EN(~cenb),.SE(cmsatpg),.CKG(clkb));
    assign #0.5 cena = ~( rd_en );
    assign #0.5 cenb = ~( wr_en );

generate
    logic rb_clka, rb_cena, rb_clkb, rb_cenb;
    logic [AW-1:0] rb_aa, rb_ab;
    logic [DW-1:0] rb_wenb, rb_qa, rb_db;


    rbdpmux #(.AW(AW),.DW(DW))rbmux(
         .cmsatpg   ,
         .cmsbist   ,
            .clka     (clka     ),.clkb      (clkb     ),
            .qa       (rd_data  ),.qb        (         ),
            .cena     (cena     ),.cenb      (cenb     ),
            .gwena    ('1       ),.gwenb     (cenb     ),
            .wena     ('1       ),.wenb      ('1       ),
            .aa       (rd_addr  ),.ab        (wr_addr  ),
            .da       ('0       ),.db        (wr_data  ),
            .rb_clka  (rb_clka  ),.rb_clkb   (rb_clkb  ),
            .rb_qa    (rb_qa    ),.rb_qb     ('0       ),
            .rb_cena  (rb_cena  ),.rb_cenb   (rb_cenb  ),
            .rb_gwena (         ),.rb_gwenb  (         ),
            .rb_wena  (         ),.rb_wenb   (rb_wenb  ),
            .rb_aa    (rb_aa    ),.rb_ab     (rb_ab    ),
            .rb_da    (         ),.rb_db     (rb_db    ),
         .rbs         (rbs)
       );


    if(MEM_DEPTH>256) begin: g1088
        udcmem_1088x64 m(
            .clka   (rb_clka   ),
            .cena   (rb_cena   ),
            .aa     (rb_aa     ),
            .qa     (rb_qa     ),
            .clkb   (rb_clkb   ),
            .cenb   (rb_cenb   ),
            .ab     (rb_ab     ),
            .db     (rb_db     ),
            `rf_2p_hdc_inst
        );
    end
    else begin: g256
        udcmem_256x64 m(
            .clka   (rb_clka   ),
            .cena   (rb_cena   ),
            .aa     (rb_aa     ),
            .qa     (rb_qa     ),
            .clkb   (rb_clkb   ),
            .cenb   (rb_cenb   ),
            .ab     (rb_ab     ),
            .db     (rb_db     ),
            `rf_2p_hdc_inst
        );
    end

endgenerate


`endif

endmodule


module dummytb_udc ();
    bit   clk;
    bit   clkao25m;
    bit   resetn;
    bit   cmsatpg;
    bit   cmsbist;
    ahbif    ahbm();
    ahbif     ahbs();
    wire            VCCA3P3;
    wire            VCCCORE;
    wire            VDD;
    wire            VSS;
    wire            VSSA;
    wire            VSSD;
    logic irq;
    logic            utmi_clk;
    logic            u2p0_external_rst;
    logic  [1:0]     utmi_xcvrselect;
    logic            utmi_termselect;
    logic            utmi_suspendm;
    logic  [1:0]     utmi_linestate;
    logic  [1:0]     utmi_opmode;
    logic  [7:0]     utmi_datain7_0;
    logic            utmi_txvalid;
    logic            utmi_txready;
    logic  [7:0]     utmi_dataout7_0;
    logic            utmi_rxvalid;
    logic            utmi_rxactive;
    logic            utmi_rxerror;
    logic            utmi_dppulldown;
    logic            utmi_dmpulldown;
    logic            utmi_hostdisconnect;
    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_share   [0:0]   ();
    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_odb     [0:0]   ();
    rbif #(.AW(8    ),      .DW(64))    rbif_udcmem_256x64  [0:0]   ();
    udc u(.*);

endmodule
