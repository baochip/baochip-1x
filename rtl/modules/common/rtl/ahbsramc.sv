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

module ahbsramc32 #(
    parameter HAW = 32,
    parameter RAW = 16
  )  (
    input logic     clk,
    input logic     resetn,
    ahbif.slave     ahbslave,
    ramif.master    rammaster
  );

  localparam DW = 32;
  localparam UW = 8;
  localparam IDW = 8;

    wire            ahbmaster_hsel;           // Slave Select
    wire  [HAW-1:0] ahbmaster_haddr;          // Address bus
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

    assign ahbmaster_hsel        = ahbslave.hsel        ;
    assign ahbmaster_haddr       = ahbslave.haddr       ;
    assign ahbmaster_htrans      = ahbslave.htrans      ;
    assign ahbmaster_hwrite      = ahbslave.hwrite      ;
    assign ahbmaster_hsize       = ahbslave.hsize       ;
    assign ahbmaster_hburst      = ahbslave.hburst      ;
    assign ahbmaster_hprot       = ahbslave.hprot       ;
    assign ahbmaster_hmaster     = ahbslave.hmaster     ;
    assign ahbmaster_hwdata      = ahbslave.hwdata      ;
    assign ahbmaster_hmasterlock = ahbslave.hmasterlock ;
    assign ahbmaster_hreadym     = ahbslave.hreadym     ;
    assign ahbmaster_hauser      = ahbslave.hauser      ;
    assign ahbmaster_hwuser      = ahbslave.hwuser      ;
    assign ahbslave.hrdata       = ahbmaster_hrdata     ;
    assign ahbslave.hready       = ahbmaster_hready     ;
    assign ahbslave.hresp        = ahbmaster_hresp      ;
    assign ahbslave.hruser       = ahbmaster_hruser     ;

cmsdk_ahb_to_sram #(
   .AW       ( RAW+2))
 u(
   .HCLK      (clk     ),
   .HRESETn   (resetn  ),
   .HSEL      (ahbmaster_hsel     ),
   .HREADY    (ahbmaster_hreadym  ),
   .HTRANS    (ahbmaster_htrans   ),
   .HSIZE     (ahbmaster_hsize    ),
   .HWRITE    (ahbmaster_hwrite   ),
   .HADDR     (ahbmaster_haddr[RAW+2-1:0]    ),
   .HWDATA    (ahbmaster_hwdata   ),
   .HREADYOUT (ahbmaster_hready   ),
   .HRESP     (ahbmaster_hresp    ),
   .HRDATA    (ahbmaster_hrdata   ),

   .SRAMRDATA (rammaster.ramrdata    ),
   .SRAMADDR  (rammaster.ramaddr    ),
   .SRAMWEN   (rammaster.ramwr),
   .SRAMWDATA (rammaster.ramwdata    ),
   .SRAMCS    (rammaster.ramcs   )
   );


    assign rammaster.ramen = '1;

endmodule : ahbsramc32

