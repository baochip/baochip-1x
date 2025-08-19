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

module qfc_aes (
	input logic clk,    // Clock
	input logic resetn, // Clock Enable

	axiif.slave  axis,
	axiif.master axim

);
    assign axim.arvalid =   axis.arvalid ;
    assign axim.araddr =    axis.araddr ;
    assign axim.arid =      axis.arid ;
    assign axim.arburst =   axis.arburst ;
    assign axim.arlen =     axis.arlen ;
    assign axim.arsize =    axis.arsize ;
    assign axim.arlock =    axis.arlock ;
    assign axim.arcache =   axis.arcache ;
    assign axim.arprot =    axis.arprot ;
    assign axim.armaster =  axis.armaster ;
    assign axim.arinner =   axis.arinner ;
    assign axim.arshare =   axis.arshare ;
    assign axim.aruser =    axis.aruser ;
    assign axim.awvalid =   axis.awvalid ;
    assign axim.awaddr =    axis.awaddr ;
    assign axim.awid =      axis.awid ;
    assign axim.awburst =   axis.awburst ;
    assign axim.awlen =     axis.awlen ;
    assign axim.awsize =    axis.awsize ;
    assign axim.awlock =    axis.awlock ;
    assign axim.awcache =   axis.awcache ;
    assign axim.awprot =    axis.awprot ;
    assign axim.awmaster =  axis.awmaster ;
    assign axim.awinner =   axis.awinner ;
    assign axim.awshare =   axis.awshare ;
    assign axim.awsparse =  axis.awsparse ;
    assign axim.awuser =    axis.awuser ;
    assign axim.rready =    axis.rready ;
    assign axim.wvalid =    axis.wvalid ;
    assign axim.wid =       axis.wid ;
    assign axim.wlast =     axis.wlast ;
    assign axim.wstrb =     axis.wstrb ;
    assign axim.wdata =     axis.wdata ;
    assign axim.wuser =     axis.wuser ;
    assign axim. bready =   axis. bready ;

    assign axis.arready =   axim.arready ;
    assign axis.awready =   axim.awready ;
    assign axis.wready =    axim.wready ;

    assign axis.rvalid =    axim.rvalid ;
    assign axis.rid =       axim.rid ;
    assign axis.rlast =     axim.rlast ;
    assign axis.rresp =     axim.rresp ;
    assign axis.rdata =     axim.rdata ;
    assign axis.ruser =     axim.ruser ;

    assign axis.bvalid =    axim.bvalid ;
    assign axis.bid =       axim.bid ;
    assign axis.bresp =     axim.bresp ;
    assign axis.buser =     axim.buser ;

endmodule
