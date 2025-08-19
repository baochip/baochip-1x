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

//  Description : AHB Testbench Master module
//                can be used to drive the AHB bus read/write transactions
//
/////////////////////////////////////////////////////////////////////////// 

                                                                                    
interface ahb_tb_mst #(
    parameter AW=32,DW=32)
(
    input logic          hclk, resetn,
    ahbif.master    mst 
);

    logic            hsel;           // Slave Select
    logic  [AW-1:0]  haddr;          // Address bus
    logic  [1:0]     htrans;         // Transfer type
    logic            hwrite;         // Transfer direction
    logic  [2:0]     hsize;          // Transfer size
    logic  [2:0]     hburst;         // Burst type
    logic  [3:0]     hprot;          // Protection control
    logic  [3:0] hmaster;        //Master select
    logic  [DW-1:0]  hwdata;         // Write data
    logic            hmasterlock;    // Locked Sequence
    logic            hreadym;       // Transfer done     // old hreadyin
    logic  [3:0]  hauser;
    logic  [3:0]  hwuser;

    logic  [DW-1:0]  hrdata;         // Read data bus    // old hready
    logic            hready;         // HREADY feedback
    logic            hresp;          // Transfer response
    logic  [3:0]  hruser;

    assign  mst.hsel        =  hsel; 
    assign  mst.haddr       =  haddr;          
    assign  mst.htrans      =  htrans;         
    assign  mst.hwrite      =  hwrite;         
    assign  mst.hsize       =  hsize;         
    assign  mst.hburst      =  hburst;         
    assign  mst.hprot       =  hprot;           
    assign  mst.hmaster     =  hmaster;        
    assign  mst.hwdata      =  hwdata;         
    assign  mst.hmasterlock =  hmasterlock;
    assign  mst.hreadym     =  hreadym & mst.hready;
    assign  mst.hauser      =  hauser;
    assign  mst.hwuser      =  hwuser;

    assign  hrdata           =  mst.hrdata;        
    assign  hready           =  mst.hready;        
    assign  hresp            =  mst.hresp;        
    assign  hruser           =  mst.hruser;      


endinterface
