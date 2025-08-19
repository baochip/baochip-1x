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

//  Description : AHB Testbench Montior
//                In order to follow the same naming of the interface,
//                ahb_tb_mon starts with the partial copy of 
//                modules/common/rtl/amba_interface_def.sv
//
/////////////////////////////////////////////////////////////////////////// 


interface ahb_tb_mon #(
    parameter AW=32,
    parameter DW=32,
    parameter IDW=4,
    parameter UW=4
)(
    input logic hclk, hresetn,
    ahbif.mon ahbmon
);

    parameter HADDR_SIZE = AW;
    parameter HDATA_SIZE = DW; 
    logic           hsel;           // Slave Select
    logic [AW-1:0]  haddr;          // Address bus
    logic [1:0]     htrans;         // Transfer type
    logic           hwrite;         // Transfer direction
    logic [2:0]     hsize;          // Transfer size
    logic [2:0]     hburst;         // Burst type
    logic [3:0]     hprot;          // Protection control
    logic [IDW-1:0] hmaster;        //Master select
    logic [DW-1:0]  hwdata;         // Write data
    logic           hmasterlock;    // Locked Sequence
    logic           hreadym;       // Transfer done     // old hreadyin
    logic [UW-1:0]  hauser;
    logic [UW-1:0]  hwuser;

    logic [DW-1:0]  hrdata;         // Read data bus    // old hready
    logic           hready;         // HREADY feedback
    logic           hresp;          // Transfer response
    logic  [UW-1:0] hruser;


    assign  hsel        =   ahbmon.hsel;           
    assign  haddr       =   ahbmon.haddr;          
    assign  htrans      =   ahbmon.htrans;         
    assign  hwrite      =   ahbmon.hwrite;         
    assign  hsize       =   ahbmon.hsize;          
    assign  hburst      =   ahbmon.hburst;         
    assign  hprot       =   ahbmon.hprot;           
    assign  hmaster     =   ahbmon.hmaster;        
    assign  hwdata      =   ahbmon.hwdata;         
    assign  hmasterlock =   ahbmon.hmasterlock;  
    assign  hreadym     =   ahbmon.hreadym;       
    assign  hauser      =   ahbmon.hauser;
    assign  hwuser      =   ahbmon.hwuser;
    assign  hrdata      =   ahbmon.hrdata;        
    assign  hready      =   ahbmon.hready;        
    assign  hresp       =   ahbmon.hresp;        
    assign  hruser      =   ahbmon.hruser;       


task wait_for_not_in_reset;
    wait (hresetn == 1'b1);
endtask : wait_for_not_in_reset;

// wait for n clock cycles. Default: 1
task wait_for_clks(int cnt=1);
    if (cnt==0) return;
    repeat (cnt) @(posedge hclk);
endtask : wait_for_clks


endinterface

