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


module ahb_axi_bdg #(
      parameter AW  = 32,
      parameter DW  = 32,
      parameter IDW = 8,
      parameter UW  = 8
)(
      input logic   clk,
      input logic   resetn,
      ahbif.slave   ahbs,
      axiif.master  axim
);

    assign axim.awid = '0;
    assign axim.awmaster = '0;
    assign axim.awinner = '0;
    assign axim.awshare = '0;
    assign axim.awsparse = '1;
    assign axim.awuser = ahbs.hmaster | 8'h0;

    assign axim.arid = '0;
    assign axim.armaster = '0;
    assign axim.arinner = '0;
    assign axim.arshare = '0;
    assign axim.aruser = ahbs.hmaster | 8'h0;

    assign axim.wid = '0;
    assign axim.wuser = '0;

    assign ahbs.hruser = '0;

nic400_hxb32 u(
/*output [31:0] */ .AWADDR_axim     ( axim.awaddr   ),
/*output [7:0]  */ .AWLEN_axim      ( axim.awlen    ),
/*output [2:0]  */ .AWSIZE_axim     ( axim.awsize   ),
/*output [1:0]  */ .AWBURST_axim    ( axim.awburst  ),
/*output        */ .AWLOCK_axim     ( axim.awlock   ),
/*output [3:0]  */ .AWCACHE_axim    ( axim.awcache  ),
/*output [2:0]  */ .AWPROT_axim     ( axim.awprot   ),
/*output        */ .AWVALID_axim    ( axim.awvalid  ),
/*input         */ .AWREADY_axim    ( axim.awready  ),
/*output [31:0] */ .WDATA_axim      ( axim.wdata    ),
/*output [3:0]  */ .WSTRB_axim      ( axim.wstrb    ),
/*output        */ .WLAST_axim      ( axim.wlast    ),
/*output        */ .WVALID_axim     ( axim.wvalid   ),
/*input         */ .WREADY_axim     ( axim.wready   ),
/*input  [1:0]  */ .BRESP_axim      ( axim.bresp    ),
/*input         */ .BVALID_axim     ( axim.bvalid   ),
/*output        */ .BREADY_axim     ( axim.bready   ),
/*output [31:0] */ .ARADDR_axim     ( axim.araddr   ),
/*output [7:0]  */ .ARLEN_axim      ( axim.arlen    ),
/*output [2:0]  */ .ARSIZE_axim     ( axim.arsize   ),
/*output [1:0]  */ .ARBURST_axim    ( axim.arburst  ),
/*output        */ .ARLOCK_axim     ( axim.arlock   ),
/*output [3:0]  */ .ARCACHE_axim    ( axim.arcache  ),
/*output [2:0]  */ .ARPROT_axim     ( axim.arprot   ),
/*output        */ .ARVALID_axim    ( axim.arvalid  ),
/*input         */ .ARREADY_axim    ( axim.arready  ),
/*input  [31:0] */ .RDATA_axim      ( axim.rdata    ),
/*input  [1:0]  */ .RRESP_axim      ( axim.rresp    ),
/*input         */ .RLAST_axim      ( axim.rlast    ),
/*input         */ .RVALID_axim     ( axim.rvalid   ),
/*output        */ .RREADY_axim     ( axim.rready   ),
/*input  [31:0] */ .HADDR_ahbs      ( ahbs.haddr    ),
/*input  [1:0]  */ .HTRANS_ahbs     ( ahbs.htrans   ),
/*input         */ .HWRITE_ahbs     ( ahbs.hwrite   ),
/*input  [2:0]  */ .HSIZE_ahbs      ( ahbs.hsize    ),
/*input  [2:0]  */ .HBURST_ahbs     ( ahbs.hburst   ),
/*input  [3:0]  */ .HPROT_ahbs      ( ahbs.hprot    ),
/*input  [31:0] */ .HWDATA_ahbs     ( ahbs.hwdata   ),
/*input         */ .HSELx_ahbs      ( ahbs.hsel     ),
/*output [31:0] */ .HRDATA_ahbs     ( ahbs.hrdata   ),
/*input         */ .HREADY_ahbs     ( ahbs.hreadym & ahbs.hready  ),
/*output        */ .HREADYOUT_ahbs  ( ahbs.hready   ),
/*output        */ .HRESP_ahbs      ( ahbs.hresp    ),
/*input         */ .clk0clk         (clk),
/*input         */ .clk0resetn      (resetn)
);


endmodule : ahb_axi_bdg

module tb_ahbaxi_bdg_intf();
  bit clk, resetn;
  axiif #(.DW(32)) axim();
  ahbif ahbs();

  ahb_axi_bdg u1(
    .clk,
    .resetn,
    .ahbs,
    .axim
  );

endmodule


