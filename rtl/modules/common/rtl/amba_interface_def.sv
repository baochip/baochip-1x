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

`include "template.sv"

`ifndef _AMBA_INTERFACE_DEFINE

interface axiif #(
    parameter AW=32,
    parameter DW=64,
    parameter IDW=8,
    parameter LENW=8,
    parameter UW=8
)();
//    wire         	ACLKEN;

    wire         	arvalid;
    wire            arready;
    wire [AW-1:0]  	araddr;
    wire [IDW-1:0] 	arid;
    wire [ 1:0]  	arburst;
    wire [LENW-1:0] arlen;
    wire [ 2:0]  	arsize;
    wire         	arlock;
    wire [ 3:0]  	arcache;
    wire [ 2:0]  	arprot;
    wire         	armaster;
    wire [ 3:0]  	arinner;
    wire         	arshare;
    wire [UW-1:0]   aruser;

    wire         	awvalid;
    wire            awready;
    wire [AW-1:0] 	awaddr;
    wire [IDW-1:0]  awid;
    wire [ 1:0]  	awburst;
    wire [LENW-1:0] awlen;
    wire [ 2:0]  	awsize;
    wire         	awlock;
    wire [ 3:0]  	awcache;
    wire [ 2:0]  	awprot;
    wire         	awmaster;
    wire [ 3:0]  	awinner;
    wire         	awshare;
    wire         	awsparse;
    wire [UW-1:0]   awuser;

    wire         	rvalid;
    wire            rready;
    wire [IDW-1:0]  rid;
    wire         	rlast;
    wire [ 1:0]     rresp;
    bit  [DW-1:0]  	rdata;
    wire [UW-1:0]   ruser;

    wire         	wvalid;
    wire            wready;
    wire [IDW-1:0]  wid;
    wire            wlast;
    wire [DW/8-1:0] wstrb;
    bit  [DW-1:0]  	wdata;
    wire [UW-1:0]   wuser;

    wire            bvalid;
    wire         	bready;
    wire [IDW-1:0]  bid;
    wire [ 1:0]  	bresp;
    wire [UW-1:0]   buser;

  modport slave (
    output  arready,
    input   arvalid,
    input   araddr,
    input   arid,
    input   arburst,
    input   arlen,
    input   arsize,
    input   arlock,
    input   arcache,
    input   arprot,
    input   armaster,
    input   arinner,
    input   arshare,
    input   aruser,

    output  awready,
    input   awvalid,
    input   awaddr,
    input   awid,
    input   awburst,
    input   awlen,
    input   awsize,
    input   awlock,
    input   awcache,
    input   awprot,
    input   awmaster,
    input   awinner,
    input   awshare,
    input   awsparse,
    input   awuser,

    input   rready,
    output  rvalid,
    output  rid,
    output  rlast,
    output  rresp,
    output  rdata,
    output  ruser,

    output  wready,
    input   wvalid,
    input   wid,
    input   wlast,
    input   wstrb,
    input   wdata,
    input   wuser,

    input    bready,
    output   bvalid,
    output   bid,
    output   bresp,
    output   buser
    );


  modport master (
    input    arready,
    output   arvalid,
    output   araddr,
    output   arid,
    output   arburst,
    output   arlen,
    output   arsize,
    output   arlock,
    output   arcache,
    output   arprot,
    output   armaster,
    output   arinner,
    output   arshare,
    output   aruser,

    input    awready,
    output   awvalid,
    output   awaddr,
    output   awid,
    output   awburst,
    output   awlen,
    output   awsize,
    output   awlock,
    output   awcache,
    output   awprot,
    output   awmaster,
    output   awinner,
    output   awshare,
    output   awsparse,
    output   awuser,

    output rready,
    input  rvalid,
    input  rid,
    input  rlast,
    input  rresp,
    input  rdata,
    input  ruser,

    input    wready,
    output   wvalid,
    output   wid,
    output   wlast,
    output   wstrb,
    output   wdata,
    output   wuser,

    output  bready,
    input   bvalid,
    input   bid,
    input   bresp,
    input   buser
    );

  modport mon (
    input    arready,
    input   arvalid,
    input   araddr,
    input   arid,
    input   arburst,
    input   arlen,
    input   arsize,
    input   arlock,
    input   arcache,
    input   arprot,
    input   armaster,
    input   arinner,
    input   arshare,
    input   aruser,

    input    awready,
    input   awvalid,
    input   awaddr,
    input   awid,
    input   awburst,
    input   awlen,
    input   awsize,
    input   awlock,
    input   awcache,
    input   awprot,
    input   awmaster,
    input   awinner,
    input   awshare,
    input   awsparse,
    input   awuser,

    input rready,
    input  rvalid,
    input  rid,
    input  rlast,
    input  rresp,
    input  rdata,
    input  ruser,

    input    wready,
    input   wvalid,
    input   wid,
    input   wlast,
    input   wstrb,
    input   wdata,
    input   wuser,

    input  bready,
    input   bvalid,
    input   bid,
    input   bresp,
    input   buser
    );

endinterface

interface ahbif #(
    parameter AW=32,
    parameter DW=32,
    parameter IDW=4,
    parameter UW=4
)();

    wire            hsel;           // Slave Select
    wire  [AW-1:0]  haddr;          // Address bus
    wire  [1:0]     htrans;         // Transfer type
    wire            hwrite;         // Transfer direction
    wire  [2:0]     hsize;          // Transfer size
    wire  [2:0]     hburst;         // Burst type
    wire  [3:0]     hprot;          // Protection control
    wire  [IDW-1:0] hmaster;        //Master select
    bit   [DW-1:0]  hwdata;         // Write data
    wire            hmasterlock;    // Locked Sequence
    wire            hreadym;       // Transfer done     // old hreadyin
    wire  [UW-1:0]  hauser;
    wire  [UW-1:0]  hwuser;

    bit   [DW-1:0]  hrdata;         // Read data bus    // old hready
    wire            hready;         // HREADY feedback
    wire            hresp;          // Transfer response
    logic  [UW-1:0]  hruser;

  modport slave (
    input  hsel,
    input  haddr,
    input  htrans,
    input  hwrite,
    input  hsize,
    input  hburst,
    input  hprot,
    input  hmaster,
    input  hwdata,
    input  hmasterlock,
    input  hreadym,
    input  hauser,
    input  hwuser,

    output  hrdata,
    output  hready,
    output  hresp,
    output  hruser
    );

  modport master (
    output  hsel,
    output  haddr,
    output  htrans,
    output  hwrite,
    output  hsize,
    output  hburst,
    output  hprot,
    output  hmaster,
    output  hwdata,
    output  hmasterlock,
    output  hreadym,
    output  hauser,
    output  hwuser,

    input  hrdata,
    input  hready,
    input  hresp,
    input  hruser
    );


  modport mon (
    input  hsel,
    input  haddr,
    input  htrans,
    input  hwrite,
    input  hsize,
    input  hburst,
    input  hprot,
    input  hmaster,
    input  hwdata,
    input  hmasterlock,
    input  hreadym,
    input  hauser,
    input  hwuser,

    input  hrdata,
    input  hready,
    input  hresp,
    input  hruser
    );

  modport slavein (
    input  hsel,
    input  haddr,
    input  htrans,
    input  hwrite,
    input  hsize,
    input  hburst,
    input  hprot,
    input  hmaster,
    input  hwdata,
    input  hmasterlock,
    input  hreadym,
    input  hauser,
    input  hwuser,

    input  hrdata,
    input  hready,
    input  hresp,
    input  hruser
    );



endinterface

interface apbif #(
    parameter PAW=16,
    parameter DW=32
)();

    wire               psel;
    wire   [PAW-1:0]    paddr;
    wire               penable;
    wire               pwrite;
    wire   [3:0]       pstrb;
    wire   [2:0]       pprot;
    bit    [31:0]      pwdata;
    wire               apbactive;
    bit    [DW-1:0]    prdata;
    wire               pready;
    wire               pslverr;

  modport slave (
    input   psel,
    input   paddr,
    input   penable,
    input   pwrite,
    input   pstrb,
    input   pprot,
    input   pwdata,
    input   apbactive,

    output  prdata,
    output  pready,
    output  pslverr
    );

   modport slavein (
    input   psel,
    input   paddr,
    input   penable,
    input   pwrite,
    input   pstrb,
    input   pprot,
    input   pwdata,
    input   apbactive,

    input   prdata,
    input   pready,
    input   pslverr
    );

  modport master (
    output  psel,
    output  paddr,
    output  penable,
    output  pwrite,
    output  pstrb,
    output  pprot,
    output  pwdata,
    output  apbactive,

    input   prdata,
    input   pready,
    input   pslverr
    );

endinterface


module monitor_axi(
    input logic clk,
    axiif.mon aximon
);
bit rerr, berr;
`thereg( rerr ) <= aximon.rvalid & aximon.rready & |aximon.rresp;
`thereg( berr ) <= aximon.bvalid & aximon.bready & |aximon.bresp;

`ifdef SIM
always@(negedge clk) begin
    if(aximon.rvalid & aximon.rready & |aximon.rresp) begin
      $display("@ERR!: (%08t) -  %m",$realtime());
      $display("       AXI RRESP  = [%1d]",aximon.rresp);
      $display("       AXI ARADDR = [%08x]",aximon.araddr);
    end
    if(aximon.bvalid & aximon.bready & |aximon.bresp) begin
      $display("@ERR!: (%08t) -  %m",$realtime());
      $display("       AXI BRESP  = [%1d]",aximon.bresp);
      $display("       AXI AWADDR = [%08x]",aximon.awaddr);
    end
end
`endif


endmodule : monitor_axi

module monitor_ahb(
    input logic clk,
    ahbif.mon ahbmon
);
bit herr;
`thereg( herr ) <= ahbmon.hready & |ahbmon.hresp;

`ifdef SIM
always@(negedge clk) begin
    if(ahbmon.hready & |ahbmon.hresp) begin
      $display("@ERR!: (%08t) -  %m",$realtime());
      $display("       AHB HRESP  = [%1d]", ahbmon.hresp);
      $display("       AHB HADDR  = [%08x]",ahbmon.haddr);
    end
end
`endif
endmodule : monitor_ahb

module dummytb_mon ();
    ahbif ahbmon();
    axiif aximon();
    bit clk;
    monitor_axi u0(.*);
    monitor_ahb u1(.*);

endmodule





`endif //`ifndef _INTERFACE_DEFINE

`define _AMBA_INTERFACE_DEFINE

