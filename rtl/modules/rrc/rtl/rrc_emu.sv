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
import cms_pkg::*;
module rrc #(
    parameter BRC  = 128,
    parameter BRCW = $clog2(BRC),
    parameter BRDW = 256
)(
    input logic     clk,
    input logic     clktop,    // Clock
    input logic     clksys,
    input logic     clktopen,

    input logic     sysresetn,
    input logic     coreresetn,

    axiif.slave     axis,
    ahbif.slave     ahbs,

    input  logic [3:0]          brready,
    output logic                brvld,
    output logic [BRCW-1:0]     bridx,
    output logic [BRDW-1:0]     brdat,
    output logic                brdone,

    output logic    rrcint

);

    ahbs_null urcc_ahbs_null(.ahbslave(ahbs));
    assign rrcint = 0;

// br
    cms_pkg::cmsdata_e cmsdata;

    bit [BRCW-1:0][BRDW-1:0] brdatreg;
    `theregfull(clksys, sysresetn, bridx, '0) <= ( bridx != BRC-1 ) & brvld ? bridx + 1 : bridx;
    assign brdat = brdatreg[bridx];

    bit [3:0] brfsm;
    `theregfull(clksys, sysresetn, brfsm, '0) <=
            ( brfsm == 0 ) & ( bridx == 0  )  & brvld ? 1 :             // cms pattern
            ( brfsm == 1 ) & ( bridx == 3  )  & brvld ? 2 :             // ip trimming
            ( brfsm == 2 ) & ( bridx == 15  ) & brvld ? 3 :             // cfg
            ( brfsm == 3 ) & ( bridx == BRC-1 ) & brvld ? 4 :             // acv
                                                        brfsm;

    `theregfull(clksys, sysresetn, brdone, '0 ) <= brdone | ( brfsm == 4 );

    bit [3:0] bronefsm;
    logic [4:0] brready0;
    assign brready0 = { brready, 1'b1 };
    `theregfull( clksys, sysresetn, bronefsm, '0 ) <= ( brfsm == 4 ) ? 0 :
                                                      ( bronefsm == 0 ) ? ( brready0[brfsm[1:0]] ? 1 : bronefsm ):
                                                      ( bronefsm == 4 ) ? 0 : bronefsm + 1;

    assign brdatreg[0] = cmsdata;

    assign brvld = ( bronefsm == 4 );

//    bit [3:0]   cmsdatavldregs;
//    assign cmsdatavld = cmsdatavldregs[3];
//    assign cmsdata = CMSDAT_USERMODE;
//    `theregfull(clksys, sysresetn, cmsdatavldregs, 4'h1 ) <= cmsdatavldregs * 2;


// axi

    ramif #(.RAW(20-3),.DW(64)) sramc();

    axisramc64 sram0 (
        .clk                    ( clk     ),
        .resetn                 ( sysresetn  ),
        .axislave               ( axis ),
        .rammaster              ( sramc )
    );

`ifdef FPGA
    //2M
    uram_cas #( .XX (8), .YY (8)) emuram (
      .clk,
      .resetn       ( sysresetn  ),
      .waitcyc      (4'h2),
      .rams         (sramc)
    );
`else

`ifdef SIM
`ifndef SYN
    //2M
    rrcram0 #(.AW(20-2),.DW(64)) emuram (  // 18: 256k*64=2M
            .clk,
            .resetn             (sysresetn),
            .sramc
        );
`endif
`endif

`ifdef SYN
    rerammacro_blackbox rerammacro();
`endif


`endif

endmodule

`ifndef FPGA
`ifndef SYN

module rrcram0 #(
    parameter AW = 10,
//    parameter string INITFILE,
    parameter DW = 32
)(
    input   bit             clk,    // Clock
    input   bit             resetn,  // Asynchronous reset active low

    ramif.slave sramc

);
     bit [AW-1:0]    ramaddr;
     bit [DW-1:0]    ramrdat;
     bit             ramwr;
     bit [DW-1:0]    ramwdat;

     assign ramaddr = sramc.ramaddr;
     assign sramc.ramrdata = ramrdat;
     assign ramwr   = sramc.ramwr;
     assign ramwdat = sramc.ramwdata;

     assign sramc.ramready = '1;

    bit [DW-1:0]    ramdat[0:2**AW-1];
    bit [0:2**AW-1][DW-1:0]    vramdat;

//    initial if(INITFILE!="")$readmemh(INITFILE, ramdat);

    always@(posedge clk) if(ramwr) ramdat[ramaddr] <= ramwdat;
    always@(posedge clk) ramrdat <= ramdat[ramaddr];


    genvar i;
//    generate
//        for(i=0;i<2**AW;i++)
//        assign vramdat[i] = ramdat[i];
//    endgenerate
endmodule

`endif
`endif
