module axil_axi_adapter # (
    parameter  IDW = 4,
    parameter  DW = 32,
    parameter  AW = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DW/8)
) (
    input  wire               clk,
    input  wire               reset,
    input  wire [IDW-1:0]     axi_id,

    // axi master
    output   wire            axi_awvalid,
    input    wire            axi_awready,
    output   wire [IDW-1:0]  axi_awid,
    output   wire [AW-1:0]   axi_awaddr,
    output   wire [2:0]      axi_awsize,
    output   wire [2:0]      axi_awprot,
    output   wire [7:0]      axi_awlen,
    output   wire [1:0]      axi_awburst,
    output   wire            axi_wvalid,
    input    wire            axi_wready,
    output   wire [DW-1:0]   axi_wdata,
    output   wire [DW/8-1:0] axi_wstrb,
    output   wire            axi_wlast,
    input    wire            axi_bvalid,
    output   wire            axi_bready,
    input    wire [1:0]      axi_bresp,
    input    wire [IDW-1:0]  axi_bid,
    output   wire            axi_arvalid,
    input    wire            axi_arready,
    output   wire [IDW-1:0]  axi_arid,
    output   wire [AW-1:0]   axi_araddr,
    output   wire [2:0]      axi_arsize,
    output   wire [2:0]      axi_arprot,
    output   wire [7:0]      axi_arlen,
    output   wire [1:0]      axi_arburst,
    input    wire            axi_rvalid,
    output   wire            axi_rready,
    input    wire [IDW-1:0]  axi_rid,
    input    wire [DW-1:0]   axi_rdata,
    input    wire [1:0]      axi_rresp,

    // axil slave
    input  wire [AW-1:0]          s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [DW-1:0]          s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [AW-1:0]          s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DW-1:0]          s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready
);
    // connect the signals that can be driven
    assign axi_awaddr  =  s_axil_awaddr ;
    assign axi_awprot  =  s_axil_awprot ;
    assign axi_awvalid =  s_axil_awvalid;
    assign s_axil_awready = axi_awready ;
    assign axi_wdata   =  s_axil_wdata  ;
    assign axi_wstrb   =  s_axil_wstrb  ;
    assign axi_wvalid  =  s_axil_wvalid ;
    assign s_axil_wready =  axi_wready  ;
    assign s_axil_bresp  =  axi_bresp   ;
    assign s_axil_bvalid =  axi_bvalid  ;
    assign axi_bready  =  s_axil_bready ;
    assign axi_araddr  =  s_axil_araddr ;
    assign axi_arprot  =  s_axil_arprot ;
    assign axi_arvalid =  s_axil_arvalid;
    assign s_axil_arready=  axi_arready ;
    assign s_axil_rdata  =  axi_rdata   ;
    assign s_axil_rresp  =  axi_rresp   ;
    assign s_axil_rvalid =  axi_rvalid  ;
    assign axi_rready  =  s_axil_rready ;

    // tie off AXI-master signals not driven by AXI-Lite
    assign axi_awid = axi_id;
    assign axi_awlen = '0;
    assign axi_awsize = 2;  // size = 4 bytes
    assign axi_awburst = 0; // fixed burst
    // assign axi_awlock = '0;
    // assign axi_awcache = '0;
    // assign axi_awmaster = '0;
    // assign axi_awinner = '0;
    // assign axi_awshare = '0;
    // assign axi_awsparse = '1;
//  assign axi_awprot = 2;
//  assign axi_awqos = '0;
//  assign axi_awregion = '0;
//  assign axi_awatop = '0;
    // assign axi_awuser = axi_id|'0;
    assign axi_wlast = '1;
    // assign axi_wuser = '0;
    // assign axi_wid   = axi_id; // ??? does this need to be wired up?
    assign axi_arid = axi_id;
    assign axi_arlen = '0;
    assign axi_arsize = 2; // size = 4 bytes
    assign axi_arburst = 0; // fixed burst
    // assign axi_arlock = '0;
    // assign axi_arcache = '0;
//  assign axi_arprot = 2;
//  assign axi_arqos = '0;
//  assign axi_arregion = '0;
    // assign axi_aruser = axi_id|'0;
    // assign axi_armaster = '0;
    // assign axi_arinner = '0;
    // assign axi_arshare = '0;
    // assign axi_ruser = '0;
    // assign axi_buser = '0;

endmodule
