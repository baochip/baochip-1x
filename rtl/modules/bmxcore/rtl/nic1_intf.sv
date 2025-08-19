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

module nic1_intf(

    input logic clk0,
    input logic clk1,
    input logic resetn,
    axiif.slave       s0,
    axiif.slave       s2,
    axiif.slave       s3,
    axiif.slave       s4,
    axiif.master      m0,
    axiif.master      m1,
    axiif.master      m2,
    axiif.master      m3
    );
  logic [9:0] nic1_AWID_m0;
  logic [9:0] nic1_ARID_m0;
  logic [9:0] nic1_AWID_m1;
  logic [9:0] nic1_ARID_m1;
  logic [9:0] nic1_AWID_m2;
  logic [9:0] nic1_ARID_m2;
  logic [9:0] nic1_AWID_m3;
  logic [9:0] nic1_ARID_m3;

  logic [7:0] nic1_BID_s2;
  logic [7:0] nic1_RID_s2;

// m0, m1, m2, m3
// axi cfg:
//  .AW     (32),
//  .DW     (64),
//  .IDW    (8),
//  .LENW   (8),
//  .UW     (8)

// s0,
// axi cfg:
//  .AW     (32),
//  .DW     (64),
//  .IDW    (9),
//  .LENW   (8),
//  .UW     (8)

// s2
// axi cfg:
//  .AW     (32),
//  .DW     (32),
//  .IDW    (8),
//  .LENW   (8),
//  .UW     (8)
  assign m0.awid = nic1_AWID_m0|'0;
  assign m0.arid = nic1_ARID_m0|'0;
  assign m1.awid = nic1_AWID_m1|'0;
  assign m1.arid = nic1_ARID_m1|'0;
  assign m2.awid = nic1_AWID_m2|'0;
  assign m2.arid = nic1_ARID_m2|'0;
  assign m3.awid = nic1_AWID_m3|'0;
  assign m3.arid = nic1_ARID_m3|'0;

  assign m0.arinner = '0;
  assign m1.arinner = '0;
  assign m2.arinner = '0;
  assign m3.arinner = '0;

  assign m0.armaster = '0;
  assign m1.armaster = '0;
  assign m2.armaster = '0;
  assign m3.armaster = '0;

  assign m0.arshare = '0;
  assign m1.arshare = '0;
  assign m2.arshare = '0;
  assign m3.arshare = '0;

  assign m0.awinner = '0;
  assign m1.awinner = '0;
  assign m2.awinner = '0;
  assign m3.awinner = '0;

  assign m0.awmaster = '0;
  assign m1.awmaster = '0;
  assign m2.awmaster = '0;
  assign m3.awmaster = '0;

  assign m0.awshare = '0;
  assign m1.awshare = '0;
  assign m2.awshare = '0;
  assign m3.awshare = '0;

  assign m0.awsparse = '1;
  assign m1.awsparse = '1;
  assign m2.awsparse = '1;
  assign m3.awsparse = '1;

  assign m0.wid = '0;
  assign m1.wid = '0;
  assign m2.wid = '0;
  assign m3.wid = '0;

  assign s2.bid = nic1_BID_s2;
  assign s2.rid = nic1_RID_s2;

nic400_1 nic1(

  .AWID_m0         (nic1_AWID_m0),
  .AWADDR_m0       (m0.awaddr),
  .AWLEN_m0        (m0.awlen),
  .AWSIZE_m0       (m0.awsize),
  .AWBURST_m0      (m0.awburst),
  .AWLOCK_m0       (m0.awlock),
  .AWCACHE_m0      (m0.awcache),
  .AWPROT_m0       (m0.awprot),
  .AWVALID_m0      (m0.awvalid),
  .AWREADY_m0      (m0.awready),
  .WDATA_m0        (m0.wdata),
  .WSTRB_m0        (m0.wstrb),
  .WLAST_m0        (m0.wlast),
  .WVALID_m0       (m0.wvalid),
  .WREADY_m0       (m0.wready),
  .BID_m0          (m0.bid|10'h0),
  .BRESP_m0        (m0.bresp),
  .BVALID_m0       (m0.bvalid),
  .BREADY_m0       (m0.bready),
  .ARID_m0         (nic1_ARID_m0),
  .ARADDR_m0       (m0.araddr),
  .ARLEN_m0        (m0.arlen),
  .ARSIZE_m0       (m0.arsize),
  .ARBURST_m0      (m0.arburst),
  .ARLOCK_m0       (m0.arlock),
  .ARCACHE_m0      (m0.arcache),
  .ARPROT_m0       (m0.arprot),
  .ARVALID_m0      (m0.arvalid),
  .ARREADY_m0      (m0.arready),
  .RID_m0          (m0.rid|10'h0),
  .RDATA_m0        (m0.rdata),
  .RRESP_m0        (m0.rresp),
  .RLAST_m0        (m0.rlast),
  .RVALID_m0       (m0.rvalid),
  .RREADY_m0       (m0.rready),
  .AWUSER_m0       (m0.awuser),
  .WUSER_m0        (m0.wuser),
  .BUSER_m0        (m0.buser|8'h0),
  .ARUSER_m0       (m0.aruser),
  .RUSER_m0        (m0.ruser|8'h0),

  .AWID_m1         (nic1_AWID_m1),
  .AWADDR_m1       (m1.awaddr),
  .AWLEN_m1        (m1.awlen),
  .AWSIZE_m1       (m1.awsize),
  .AWBURST_m1      (m1.awburst),
  .AWLOCK_m1       (m1.awlock),
  .AWCACHE_m1      (m1.awcache),
  .AWPROT_m1       (m1.awprot),
  .AWVALID_m1      (m1.awvalid),
  .AWREADY_m1      (m1.awready),
  .WDATA_m1        (m1.wdata),
  .WSTRB_m1        (m1.wstrb),
  .WLAST_m1        (m1.wlast),
  .WVALID_m1       (m1.wvalid),
  .WREADY_m1       (m1.wready),
  .BID_m1          (m1.bid|10'h0),
  .BRESP_m1        (m1.bresp),
  .BVALID_m1       (m1.bvalid),
  .BREADY_m1       (m1.bready),
  .ARID_m1         (nic1_ARID_m1),
  .ARADDR_m1       (m1.araddr),
  .ARLEN_m1        (m1.arlen),
  .ARSIZE_m1       (m1.arsize),
  .ARBURST_m1      (m1.arburst),
  .ARLOCK_m1       (m1.arlock),
  .ARCACHE_m1      (m1.arcache),
  .ARPROT_m1       (m1.arprot),
  .ARVALID_m1      (m1.arvalid),
  .ARREADY_m1      (m1.arready),
  .RID_m1          (m1.rid|10'h0),
  .RDATA_m1        (m1.rdata),
  .RRESP_m1        (m1.rresp),
  .RLAST_m1        (m1.rlast),
  .RVALID_m1       (m1.rvalid),
  .RREADY_m1       (m1.rready),
  .AWUSER_m1       (m1.awuser),
  .WUSER_m1        (m1.wuser),
  .BUSER_m1        (m1.buser|8'h0),
  .ARUSER_m1       (m1.aruser),
  .RUSER_m1        (m1.ruser|8'h0),

  .AWID_m2         (nic1_AWID_m2),
  .AWADDR_m2       (m2.awaddr),
  .AWLEN_m2        (m2.awlen),
  .AWSIZE_m2       (m2.awsize),
  .AWBURST_m2      (m2.awburst),
  .AWLOCK_m2       (m2.awlock),
  .AWCACHE_m2      (m2.awcache),
  .AWPROT_m2       (m2.awprot),
  .AWVALID_m2      (m2.awvalid),
  .AWREADY_m2      (m2.awready),
  .WDATA_m2        (m2.wdata),
  .WSTRB_m2        (m2.wstrb),
  .WLAST_m2        (m2.wlast),
  .WVALID_m2       (m2.wvalid),
  .WREADY_m2       (m2.wready),
  .BID_m2          (m2.bid|10'h0),
  .BRESP_m2        (m2.bresp),
  .BVALID_m2       (m2.bvalid),
  .BREADY_m2       (m2.bready),
  .ARID_m2         (nic1_ARID_m2),
  .ARADDR_m2       (m2.araddr),
  .ARLEN_m2        (m2.arlen),
  .ARSIZE_m2       (m2.arsize),
  .ARBURST_m2      (m2.arburst),
  .ARLOCK_m2       (m2.arlock),
  .ARCACHE_m2      (m2.arcache),
  .ARPROT_m2       (m2.arprot),
  .ARVALID_m2      (m2.arvalid),
  .ARREADY_m2      (m2.arready),
  .RID_m2          (m2.rid|10'h0),
  .RDATA_m2        (m2.rdata),
  .RRESP_m2        (m2.rresp),
  .RLAST_m2        (m2.rlast),
  .RVALID_m2       (m2.rvalid),
  .RREADY_m2       (m2.rready),
  .AWUSER_m2       (m2.awuser),
  .WUSER_m2        (m2.wuser),
  .BUSER_m2        (m2.buser|8'h0),
  .ARUSER_m2       (m2.aruser),
  .RUSER_m2        (m2.ruser|8'h0),

  .AWID_m3         (nic1_AWID_m3),
  .AWADDR_m3       (m3.awaddr),
  .AWLEN_m3        (m3.awlen),
  .AWSIZE_m3       (m3.awsize),
  .AWBURST_m3      (m3.awburst),
  .AWLOCK_m3       (m3.awlock),
  .AWCACHE_m3      (m3.awcache),
  .AWPROT_m3       (m3.awprot),
  .AWVALID_m3      (m3.awvalid),
  .AWREADY_m3      (m3.awready),
  .WDATA_m3        (m3.wdata),
  .WSTRB_m3        (m3.wstrb),
  .WLAST_m3        (m3.wlast),
  .WVALID_m3       (m3.wvalid),
  .WREADY_m3       (m3.wready),
  .BID_m3          (m3.bid|10'h0),
  .BRESP_m3        (m3.bresp),
  .BVALID_m3       (m3.bvalid),
  .BREADY_m3       (m3.bready),
  .ARID_m3         (nic1_ARID_m3),
  .ARADDR_m3       (m3.araddr),
  .ARLEN_m3        (m3.arlen),
  .ARSIZE_m3       (m3.arsize),
  .ARBURST_m3      (m3.arburst),
  .ARLOCK_m3       (m3.arlock),
  .ARCACHE_m3      (m3.arcache),
  .ARPROT_m3       (m3.arprot),
  .ARVALID_m3      (m3.arvalid),
  .ARREADY_m3      (m3.arready),
  .RID_m3          (m3.rid|10'h0),
  .RDATA_m3        (m3.rdata),
  .RRESP_m3        (m3.rresp),
  .RLAST_m3        (m3.rlast),
  .RVALID_m3       (m3.rvalid),
  .RREADY_m3       (m3.rready),
  .AWUSER_m3       (m3.awuser),
  .WUSER_m3        (m3.wuser),
  .BUSER_m3        (m3.buser|8'h0),
  .ARUSER_m3       (m3.aruser),
  .RUSER_m3        (m3.ruser|8'h0),

  .AWID_s0         (s0.awid|8'h0),
  .AWADDR_s0       (s0.awaddr),
  .AWLEN_s0        (s0.awlen|8'h0),
  .AWSIZE_s0       (s0.awsize),
  .AWBURST_s0      (s0.awburst),
  .AWLOCK_s0       (s0.awlock),
  .AWCACHE_s0      (s0.awcache),
  .AWPROT_s0       (s0.awprot),
  .AWVALID_s0      (s0.awvalid),
  .AWREADY_s0      (s0.awready),
  .WDATA_s0        (s0.wdata),
  .WSTRB_s0        (s0.wstrb),
  .WLAST_s0        (s0.wlast),
  .WVALID_s0       (s0.wvalid),
  .WREADY_s0       (s0.wready),
  .BID_s0          (s0.bid),
  .BRESP_s0        (s0.bresp),
  .BVALID_s0       (s0.bvalid),
  .BREADY_s0       (s0.bready),
  .ARID_s0         (s0.arid|8'h0),
  .ARADDR_s0       (s0.araddr),
  .ARLEN_s0        (s0.arlen|8'h0),
  .ARSIZE_s0       (s0.arsize),
  .ARBURST_s0      (s0.arburst),
  .ARLOCK_s0       (s0.arlock),
  .ARCACHE_s0      (s0.arcache),
  .ARPROT_s0       (s0.arprot),
  .ARVALID_s0      (s0.arvalid),
  .ARREADY_s0      (s0.arready),
  .RID_s0          (s0.rid),
  .RDATA_s0        (s0.rdata),
  .RRESP_s0        (s0.rresp),
  .RLAST_s0        (s0.rlast),
  .RVALID_s0       (s0.rvalid),
  .RREADY_s0       (s0.rready),
  .AWUSER_s0       (s0.awuser|8'h0),
  .WUSER_s0        (s0.wuser|8'h0),
  .BUSER_s0        (s0.buser),
  .ARUSER_s0       (s0.aruser|8'h0),
  .RUSER_s0        (s0.ruser),

  .AWID_s2         (s2.awid|8'h0),
  .AWADDR_s2       (s2.awaddr),
  .AWLEN_s2        (s2.awlen|8'h0),
  .AWSIZE_s2       (s2.awsize),
  .AWBURST_s2      (s2.awburst),
  .AWLOCK_s2       (s2.awlock),
  .AWCACHE_s2      (s2.awcache),
  .AWPROT_s2       (s2.awprot),
  .AWVALID_s2      (s2.awvalid),
  .AWREADY_s2      (s2.awready),
  .WDATA_s2        (s2.wdata),
  .WSTRB_s2        (s2.wstrb),
  .WLAST_s2        (s2.wlast),
  .WVALID_s2       (s2.wvalid),
  .WREADY_s2       (s2.wready),
  .BID_s2          (nic1_BID_s2),
  .BRESP_s2        (s2.bresp),
  .BVALID_s2       (s2.bvalid),
  .BREADY_s2       (s2.bready),
  .ARID_s2         (s2.arid|8'h0),
  .ARADDR_s2       (s2.araddr),
  .ARLEN_s2        (s2.arlen|8'h0),
  .ARSIZE_s2       (s2.arsize),
  .ARBURST_s2      (s2.arburst),
  .ARLOCK_s2       (s2.arlock),
  .ARCACHE_s2      (s2.arcache),
  .ARPROT_s2       (s2.arprot),
  .ARVALID_s2      (s2.arvalid),
  .ARREADY_s2      (s2.arready),
  .RID_s2          (nic1_RID_s2),
  .RDATA_s2        (s2.rdata),
  .RRESP_s2        (s2.rresp),
  .RLAST_s2        (s2.rlast),
  .RVALID_s2       (s2.rvalid),
  .RREADY_s2       (s2.rready),
  .AWUSER_s2       (s2.awuser|8'h0),
  .WUSER_s2        (s2.wuser|8'h0),
  .BUSER_s2        (s2.buser),
  .ARUSER_s2       (s2.aruser|8'h0),
  .RUSER_s2        (s2.ruser),

  .AWID_s3         (s3.awid|8'h0),
  .AWADDR_s3       (s3.awaddr),
  .AWLEN_s3        (s3.awlen|8'h0),
  .AWSIZE_s3       (s3.awsize),
  .AWBURST_s3      (s3.awburst),
  .AWLOCK_s3       (s3.awlock),
  .AWCACHE_s3      (s3.awcache),
  .AWPROT_s3       (s3.awprot),
  .AWVALID_s3      (s3.awvalid),
  .AWREADY_s3      (s3.awready),
  .WDATA_s3        (s3.wdata),
  .WSTRB_s3        (s3.wstrb),
  .WLAST_s3        (s3.wlast),
  .WVALID_s3       (s3.wvalid),
  .WREADY_s3       (s3.wready),
  .BID_s3          (s3.bid),
  .BRESP_s3        (s3.bresp),
  .BVALID_s3       (s3.bvalid),
  .BREADY_s3       (s3.bready),
  .ARID_s3         (s3.arid|8'h0),
  .ARADDR_s3       (s3.araddr),
  .ARLEN_s3        (s3.arlen|8'h0),
  .ARSIZE_s3       (s3.arsize),
  .ARBURST_s3      (s3.arburst),
  .ARLOCK_s3       (s3.arlock),
  .ARCACHE_s3      (s3.arcache),
  .ARPROT_s3       (s3.arprot),
  .ARVALID_s3      (s3.arvalid),
  .ARREADY_s3      (s3.arready),
  .RID_s3          (s3.rid),
  .RDATA_s3        (s3.rdata),
  .RRESP_s3        (s3.rresp),
  .RLAST_s3        (s3.rlast),
  .RVALID_s3       (s3.rvalid),
  .RREADY_s3       (s3.rready),
  .AWUSER_s3       (s3.awuser|8'h0),
  .WUSER_s3        (s3.wuser|8'h0),
  .BUSER_s3        (s3.buser),
  .ARUSER_s3       (s3.aruser|8'h0),
  .RUSER_s3        (s3.ruser),

  .AWID_s4         (s4.awid|8'h0),
  .AWADDR_s4       (s4.awaddr),
  .AWLEN_s4        (s4.awlen|8'h0),
  .AWSIZE_s4       (s4.awsize),
  .AWBURST_s4      (s4.awburst),
  .AWLOCK_s4       (s4.awlock),
  .AWCACHE_s4      (s4.awcache),
  .AWPROT_s4       (s4.awprot),
  .AWVALID_s4      (s4.awvalid),
  .AWREADY_s4      (s4.awready),
  .WDATA_s4        (s4.wdata),
  .WSTRB_s4        (s4.wstrb),
  .WLAST_s4        (s4.wlast),
  .WVALID_s4       (s4.wvalid),
  .WREADY_s4       (s4.wready),
  .BID_s4          (s4.bid),
  .BRESP_s4        (s4.bresp),
  .BVALID_s4       (s4.bvalid),
  .BREADY_s4       (s4.bready),
  .ARID_s4         (s4.arid|8'h0),
  .ARADDR_s4       (s4.araddr),
  .ARLEN_s4        (s4.arlen|8'h0),
  .ARSIZE_s4       (s4.arsize),
  .ARBURST_s4      (s4.arburst),
  .ARLOCK_s4       (s4.arlock),
  .ARCACHE_s4      (s4.arcache),
  .ARPROT_s4       (s4.arprot),
  .ARVALID_s4      (s4.arvalid),
  .ARREADY_s4      (s4.arready),
  .RID_s4          (s4.rid),
  .RDATA_s4        (s4.rdata),
  .RRESP_s4        (s4.rresp),
  .RLAST_s4        (s4.rlast),
  .RVALID_s4       (s4.rvalid),
  .RREADY_s4       (s4.rready),
  .AWUSER_s4       (s4.awuser|8'h0),
  .WUSER_s4        (s4.wuser|8'h0),
  .BUSER_s4        (s4.buser),
  .ARUSER_s4       (s4.aruser|8'h0),
  .RUSER_s4        (s4.ruser),




  .clk0clk         (clk0),
  .clk0resetn      (resetn),
  .clk1clk         (clk1),
  .clk1resetn      (resetn),
  .*
);

endmodule : nic1_intf

module dummytb_nic1_intf();

    logic clk0;
    logic clk1;
    logic resetn;
    axiif #(.AW(32),.DW(64),.IDW(8),.LENW(8),.UW(8)) s0();
    axiif #(.AW(32),.DW(32),.IDW(8),.LENW(8),.UW(8)) s2();
    axiif #(.AW(32),.DW(64),.IDW(8),.LENW(8),.UW(8)) s3();
    axiif #(.AW(32),.DW(32),.IDW(8),.LENW(8),.UW(8)) s4();
    axiif #(.AW(32),.DW(64),.IDW(8),.LENW(8),.UW(8)) m0();
    axiif #(.AW(32),.DW(64),.IDW(8),.LENW(8),.UW(8)) m1();
    axiif #(.AW(32),.DW(64),.IDW(8),.LENW(8),.UW(8)) m2();
    axiif #(.AW(32),.DW(64),.IDW(8),.LENW(8),.UW(8)) m3();

    nic1_intf u(.*);

endmodule:dummytb_nic1_intf

