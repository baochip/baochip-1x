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
//`include "amba_interface_def_v0.2.sv"

import axi_pkg::*;

module ahb_demux_map #(

    parameter SLVCNT = 2,
    parameter DW=32,
    parameter AW=32,
    parameter UW=32,

    parameter xbar_rule_32_t [16-1:0] ADDRMAP = '{
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 0 , start_addr: 32'h0000_0000, end_addr: 32'h0000_0000},
        '{idx: 1 , start_addr: 32'h8000_0000, end_addr: 32'hc000_0000},
        '{idx: 0 , start_addr: 32'hd000_0000, end_addr: 32'hffff_ffff}
    }
 )
 (

        input bit           hclk,
        input bit           resetn,

        ahbif.slave         ahbslave,
        ahbif.master        ahbmaster[0:SLVCNT-1]

    );

        localparam HTRANS_IDLE = 2'h0;
        localparam HTRANS_NONSEQ = 2'h2;
        localparam HTRANS_SEQ = 2'h3;
        xbar_rule_32_t [SLVCNT-1:0] ssADDRMAP = ADDRMAP;

        bit clk;
        assign clk = hclk;

        logic  [SLVCNT-1:0][31:0] addrmap_a, addrmap_b;
//        assign s_addrmap = ADDRMAP;
      //
      //  ahb phase
      //  ==
      //

        bit                         ahbaddrphase, ahbdataphase;
        bit [0:SLVCNT-1][DW-1:0]    hrdatain;
        bit [0:SLVCNT-1][UW-1:0]    hruserin;
        bit [0:SLVCNT-1]            hreadyall, hseldataphase, hrespall;
        bit [0:SLVCNT-1]            ahbmaster_sel, ahbmaster_sel_0;
//        bit [0:SLVCNT-1][AW-1:0]    pm_SLV_AMSK, pm_SLV_ADDR, ahbslave_haddr_mask;
        bit [AW-1:0]                ahbslave_haddr;

        assign ahbaddrphase = ~( ahbslave.htrans == HTRANS_IDLE ) & ahbslave.hready & ahbslave.hsel & ahbslave.hreadym;
        `theregrn( ahbdataphase ) <= ahbaddrphase ? 1'b1 : ahbslave.hready ? 1'b0 : ahbdataphase;
        assign ahbslave_haddr = ahbslave.haddr;
        bit [31:0]                  pm_AW;
        assign pm_AW = AW;
        genvar i;
        generate
          for( i = 0; i < SLVCNT; i = i + 1) begin: GenRnd
            assign addrmap_a[i] = ADDRMAP[i].start_addr;
            assign addrmap_b[i] = ADDRMAP[i].end_addr;
//            assign pm_SLV_AMSK[i] = ~SLV_AMSK[i];
//            assign pm_SLV_ADDR[i] =  SLV_ADDR[i];
//            assign ahbslave_haddr_mask[i] = ahbslave_haddr & pm_SLV_AMSK[i];
//            assign ahbmaster_sel_0[i] = ( ahbslave_haddr_mask[i] == pm_SLV_ADDR[i] );

            assign ahbmaster_sel_0[i] = ( ahbslave_haddr >= ADDRMAP[i].start_addr ) & ( ahbslave_haddr < ADDRMAP[i].end_addr );
            assign ahbmaster_sel[i] = ahbmaster_sel_0[i] & ahbslave.hsel;
            `theregrn( hseldataphase[i] ) <= ahbaddrphase ? ahbmaster[i].hsel : ahbmaster[i].hready ? 0 : hseldataphase[i];
            assign hrespall[i]  = ahbmaster[i].hresp  & hseldataphase[i];
            assign hreadyall[i] = ahbmaster[i].hready & hseldataphase[i];
            assign hrdatain[i]  = ahbmaster[i].hrdata;
            assign hruserin[i]  = ahbmaster[i].hruser;

            assign ahbmaster[i].hsel        = ahbmaster_sel[i];// ( ahbslave.haddr & ~SLV_AMSK[i] == SLV_ADDR[i] ) & ahbslave.hsel;
            assign ahbmaster[i].haddr       = ahbslave.haddr        ;
            assign ahbmaster[i].htrans      = ahbslave.htrans       ;
            assign ahbmaster[i].hwrite      = ahbslave.hwrite       ;
            assign ahbmaster[i].hsize       = ahbslave.hsize        ;
            assign ahbmaster[i].hburst      = ahbslave.hburst       ;
            assign ahbmaster[i].hprot       = ahbslave.hprot        ;
            assign ahbmaster[i].hmaster     = ahbslave.hmaster      ;
            assign ahbmaster[i].hwdata      = ahbslave.hwdata       ;
            assign ahbmaster[i].hmasterlock = ahbslave.hmasterlock  ;
            assign ahbmaster[i].hreadym     = ahbslave.hreadym      ;
            assign ahbmaster[i].hauser      = ahbslave.hauser       ;
            assign ahbmaster[i].hwuser      = ahbslave.hwuser       ;
          end
        endgenerate

        assign ahbslave.hready = |hseldataphase ? |hreadyall : 1'b1;
//        assign ahbslave.hrdata = fnhrdata( hrdatain, hseldataphase );
//        assign ahbslave.hruser = fnhruser( hruserin, hseldataphase );
        assign ahbslave.hresp  = |hrespall;

        always_comb begin
            ahbslave.hrdata = '0;
            ahbslave.hruser = '0;
            for (int i = 0; i < SLVCNT; i++) begin
                ahbslave.hrdata = ahbslave.hrdata | ( hseldataphase[i] ? hrdatain[i] : '0 );
                ahbslave.hruser = ahbslave.hruser | ( hseldataphase[i] ? hruserin[i] : '0 );
            end
        end


        function bit [DW-1:0] fnhrdata(input bit [0:SLVCNT-1][DW-1:0]    fnhrdatain, input bit [0:SLVCNT-1] fnhseldataphase);
            bit [DW-1:0] fnmux;
            int fni;
            for(fni = 0; fni < SLVCNT; fni = fni + 1 ) fnmux = fnmux | ( fnhrdatain[fni] & {DW{fnhseldataphase[fni]}} );
            fnhrdata = fnmux;
        endfunction

        function bit [UW-1:0] fnhruser(input bit [0:SLVCNT-1][UW-1:0]    fnhruserin, input bit [0:SLVCNT-1] fnhseldataphase);
            bit [UW-1:0] fnmux;
            int fni;
            for(fni = 0; fni < SLVCNT; fni = fni + 1 ) fnmux = fnmux | ( fnhruserin[fni] & {UW{fnhseldataphase[fni]}} );
            fnhruser = fnmux;
        endfunction

    endmodule

module dummytb_ahb_demux ();

    ahbif ahbslave(),ahbmaster[0:2-1]();
    logic hclk,resetn;
    ahb_demux_map u1(
        .hclk,
        .resetn,
        .ahbslave(ahbslave),
        .ahbmaster(ahbmaster[0:2-1])
        );

endmodule

