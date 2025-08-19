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

module axi_ahb_bdg #(
    parameter AW = 32,
    parameter DW = 64
  )  (
    input logic     clk,
    input logic     resetn,
    axiif.slave     axislave,
    ahbif.master    ahbmaster
  );




// axi cfg:
//  .AW     ( 32 ),
//  .DW     ( 64 ),
//  .IDW    ( 8 ),
//  .LENW   ( 8 ),
//  .UW     ( 8 )


  CM7AAB #(
    .DW_64((DW==64)),
    .DW(DW),
    .SW(DW/8)
  )  uaab  (

  .CLK                      (clk),
  .nSYSRESET                (resetn),

/*[31:0]   */.AWADDR         (axislave.awaddr),
/*[1:0]    */.AWBURST        (axislave.awburst),
/*[15:0]   */.AWID           (axislave.awid|16'h0),
/*[7:0]    */.AWLEN          (axislave.awlen|8'h0),
/*[1:0]    */.AWSIZE         (axislave.awsize[1:0]),
/*         */.AWLOCK         (axislave.awlock),
/*[2:0]    */.AWPROT         (axislave.awprot),
/*[3:0]    */.AWCACHE        (axislave.awcache),
/*[15:0]   */.AWUSER         (axislave.awuser|16'h0),
/*         */.AWSPARSE       (axislave.awsparse),
/*         */.AWVALID        (axislave.awvalid),
/*         */.AWREADY        (axislave.awready),

/*[31:0]   */.ARADDR         (axislave.araddr),
/*[1:0]    */.ARBURST        (axislave.arburst),
/*[15:0]   */.ARID           (axislave.arid|16'h0),
/*[7:0]    */.ARLEN          (axislave.arlen|8'h0),
/*[1:0]    */.ARSIZE         (axislave.arsize[1:0]),
/*         */.ARLOCK         (axislave.arlock),
/*[2:0]    */.ARPROT         (axislave.arprot),
/*[3:0]    */.ARCACHE        (axislave.arcache),
/*[15:0]   */.ARUSER         (axislave.aruser|16'h0),
/*         */.ARVALID        (axislave.arvalid),
/*         */.ARREADY        (axislave.arready),

/*         */.WLAST          (axislave.wlast),
/*[SW-1:0] */.WSTRB          (axislave.wstrb),
/*[DW-1:0] */.WDATA          (axislave.wdata),
/*[15:0]   */.WUSER          (axislave.wuser|16'h0),
/*         */.WVALID         (axislave.wvalid),
/*         */.WREADY         (axislave.wready),

/*         */.RREADY         (axislave.rready),
/*         */.RVALID         (axislave.rvalid),
/*[15:0]   */.RID            (),
/*         */.RLAST          (axislave.rlast),
/*[DW-1:0] */.RDATA          (axislave.rdata),
/*[15:0]   */.RUSER          (),
/*[1:0]    */.RRESP          (axislave.rresp),

/*         */.BREADY         (axislave.bready),
/*         */.BVALID         (axislave.bvalid),
/*[15:0]   */.BID            (),
/*[1:0]    */.BRESP          (axislave.bresp),
///*[15:0]   */.BUSER          (),

/*[1:0]    */.HTRANS         (ahbmaster.htrans),
/*[2:0]    */.HBURST         (ahbmaster.hburst),
/*[31:0]   */.HADDR          (ahbmaster.haddr),
/*         */.HWRITE         (ahbmaster.hwrite),
/*[2:0]    */.HSIZE          (ahbmaster.hsize),
/*[DW-1:0] */.HWDATA         (ahbmaster.hwdata),
/*[3:0]    */.HPROT          (ahbmaster.hprot),
/*         */.HMASTLOCK      (ahbmaster.hmasterlock),
/*         */.HREADY         (ahbmaster.hready),
/*[DW-1:0] */.HRDATA         (ahbmaster.hrdata),
/*         */.HRESP          (ahbmaster.hresp),
/*         */.EXREQ          (),
/*         */.EXRESP         (1'b0),
/*[15:0]   */.HAUSER         (),
/*[15:0]   */.HWUSER         (),
/*[15:0]   */.HRUSER         (ahbmaster.hruser|16'h0)
);

  assign axislave.rid   = uaab.RID   ;
  assign axislave.ruser = uaab.RUSER ;
  assign axislave.bid   = uaab.BID   ;
//  assign axislave.buser = uaab.BUSER ;

  assign ahbmaster.hsel = |ahbmaster.htrans;
  assign ahbmaster.hauser = uaab.HAUSER;
  assign ahbmaster.hwuser = uaab.HWUSER;
  assign ahbmaster.hreadym = ahbmaster.hready;//1'b1;

  assign ahbmaster.hmaster = ahbmaster.hauser;

endmodule : axi_ahb_bdg

module tb_aab_intf();
  bit clk, resetn;
  axiif #(.DW(64))  axislave();
  ahbif #(.DW(64))  ahbmaster();

  axi_ahb_bdg  #(
    .AW(32),
    .DW(64)
  )u1(
    .clk,
    .resetn,
    .axislave,
    .ahbmaster
  );




endmodule


