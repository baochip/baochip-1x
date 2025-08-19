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

module axisramc64 #(
    parameter AW = 32,
    parameter WCW = 1
  )  (
    input logic     clk,
    input logic     resetn,
    axiif.slave     axislave,
    ramif.master    rammaster
  );

  localparam DW = 64;
  localparam UW = 8;
  localparam IDW = 8;

    wire            ahbmaster_hsel;           // Slave Select
    wire  [AW-1:0]  ahbmaster_haddr;          // Address bus
    wire  [1:0]     ahbmaster_htrans;         // Transfer type
    wire            ahbmaster_hwrite;         // Transfer direction
    wire  [2:0]     ahbmaster_hsize;          // Transfer size
    wire  [2:0]     ahbmaster_hburst;         // Burst type
    wire  [3:0]     ahbmaster_hprot;          // Protection control
    wire  [IDW-1:0] ahbmaster_hmaster;        //Master select
    wire  [DW-1:0]  ahbmaster_hwdata;         // Write data
    wire            ahbmaster_hmasterlock;    // Locked Sequence
    wire            ahbmaster_hreadym;       // Transfer done     // old hreadyin
    wire  [UW-1:0]  ahbmaster_hauser;
    wire  [UW-1:0]  ahbmaster_hwuser;
    wire  [DW-1:0]  ahbmaster_hrdata;         // Read data bus    // old hready
    wire            ahbmaster_hready;         // HREADY feedback
    wire            ahbmaster_hresp;          // Transfer response
    wire  [UW-1:0]  ahbmaster_hruser;





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
  )  axibdg  (

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

/*[1:0]    */.HTRANS         (ahbmaster_htrans),
/*[2:0]    */.HBURST         (ahbmaster_hburst),
/*[31:0]   */.HADDR          (ahbmaster_haddr),
/*         */.HWRITE         (ahbmaster_hwrite),
/*[2:0]    */.HSIZE          (ahbmaster_hsize),
/*[DW-1:0] */.HWDATA         (ahbmaster_hwdata),
/*[3:0]    */.HPROT          (ahbmaster_hprot),
/*         */.HMASTLOCK      (ahbmaster_hmasterlock),
/*         */.HREADY         (ahbmaster_hready),
/*[DW-1:0] */.HRDATA         (ahbmaster_hrdata),
/*         */.HRESP          (ahbmaster_hresp),
/*         */.EXREQ          (),
/*         */.EXRESP         (1'b0),
/*[15:0]   */.HAUSER         (),
/*[15:0]   */.HWUSER         (),
/*[15:0]   */.HRUSER         (ahbmaster_hruser|16'h0)
);

  assign axislave.rid   = axibdg.RID   ;
  assign axislave.ruser = axibdg.RUSER ;
  assign axislave.bid   = axibdg.BID   ;
//  assign axislave.buser = uaab.BUSER ;

  assign ahbmaster_hauser = axibdg.HAUSER;
  assign ahbmaster_hwuser = axibdg.HWUSER;


  ahb_sram_bridge_64
   #(.AWIDTH                            (20),
    .WCW   (WCW))
    ramc
    (//Outputs
    .RAMAD                              (rammaster.ramaddr[16:0]),
    .RAMWD                              (rammaster.ramwdata[63:0]),
    .RAMCS                              (rammaster.ramcs),
    .RAMWE                              (rammaster.ramwr[7:0]),
    .RAMRD                              (rammaster.ramrdata[63:0]),
    .RAMRDY                             (rammaster.ramready),
    //Inputs
    .HCLK                               (clk),
    .HRESETn                            (resetn),
    .HADDR                              (ahbmaster_haddr[31:0]),
    .HBURST                             (ahbmaster_hburst[2:0]),
    .HMASTLOCK                          (1'b0),
    .HPROT                              (ahbmaster_hprot[3:0]),
    .HSIZE                              (ahbmaster_hsize[2:0]),
    .HTRANS                             (ahbmaster_htrans[1:0]),
    .HWDATA                             (ahbmaster_hwdata),
    .HWRITE                             (ahbmaster_hwrite),
    .HSEL                               (1'b1),
    .HREADY                             (1'b1),

    .HRDATA                             (ahbmaster_hrdata),
    .HREADYOUT                          (ahbmaster_hready),
    .HRESP                              (ahbmaster_hresp)

  );

    assign rammaster.ramen = '1;


`ifdef SIM
    logic sim_axi_610ffe80_wr;
    `theregrn( sim_axi_610ffe80_wr ) <= ( axislave.awaddr ==  32'h610ffe80 ) & axislave.awready & axislave.awvalid;

`endif





endmodule : axisramc64

