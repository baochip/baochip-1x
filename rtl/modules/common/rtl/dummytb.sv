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

module dummytb_axi_xbar ();

    parameter XIDW  = 8;     // axi id width
    parameter XUDW  = 8;     // axi userdata width
    parameter XLENW = 8;     // axi len width

    parameter HIDW  = 4;     // axi id width
    parameter HUDW  = 4;     // axi userdata width

    typedef axi_pkg::xbar_rule_32_t       rule32_t; // Has to be the same width as axi addr

    localparam axi_pkg::xbar_cfg_t sce_axi_demux_cfg = '{
         NoSlvPorts:         2,
         NoMstPorts:         2,
         MaxMstTrans:        1,
         MaxSlvTrans:        1,
         FallThrough:        1'b0,
         LatencyMode:        axi_pkg::NO_LATENCY,
         AxiIdWidthSlvPorts: XIDW+1,
         AxiIdUsedSlvPorts:  XIDW,
         UniqueIds:          1'b0,
         AxiAddrWidth:       32,
         AxiDataWidth:       32,
         NoAddrRules:        2
    };

    logic hclk,resetn,cmsatpg;
    localparam rule32_t [sce_axi_demux_cfg.NoAddrRules-1:0] sce_axi_demux_map = '{
        '{idx: 32'd1 , start_addr: 32'h0000_0000, end_addr: 32'h6000_0000}, // to ahb_bmx33
        '{idx: 32'd0 , start_addr: 32'h6000_0000, end_addr: 32'ha000_0000}  // to nic_1
    };

     AXI_BUS #(
        .AXI_ADDR_WIDTH     ( 32     ),
        .AXI_DATA_WIDTH     ( 32     ),
        .AXI_ID_WIDTH       ( XIDW   ),
        .AXI_USER_WIDTH     ( XUDW   )
      ) sce_axi32_pulp[1:0](), sce_axidemux_pulp[0:1] ();

    axi_xbar_intf #(
      .AXI_USER_WIDTH         ( 8  ),
      .Cfg                    ( sce_axi_demux_cfg ),
      .ATOPS                  ( 1'b0 ),
      .rule_t                 ( rule32_t   )
    ) sce_axi_demux (
      .clk_i                  ( hclk     ),
      .rst_ni                 ( resetn  ),
      .test_i                 ( cmsatpg    ),
      .slv_ports              ( sce_axi32_pulp  ),
      .mst_ports              ( sce_axidemux_pulp   ),
      .addr_map_i             ( sce_axi_demux_map ),
      .en_default_mst_port_i  ( '0      ),
      .default_mst_port_i     ( '0      )
    );

endmodule

module dummytb_axi_mux ();
    parameter XIDW  = 8;     // axi id width
    parameter XUDW  = 8;     // axi userdata width
    parameter XLENW = 8;     // axi len width

    parameter HIDW  = 4;     // axi id width
    parameter HUDW  = 4;     // axi userdata width

    logic hclk = 0;
    logic resetn = 0;
    logic cmsatpg = 0;

    AXI_BUS #(
        .AXI_ADDR_WIDTH     ( 32     ),
        .AXI_DATA_WIDTH     ( 32     ),
        .AXI_ID_WIDTH       ( XIDW   ),
        .AXI_USER_WIDTH     ( XUDW   )
      )  nic_s2_pulp(),aximux_slave_pulp[0:1]();

    axi_mux_intf #(
      .SLV_AXI_ID_WIDTH       (8),
      .MST_AXI_ID_WIDTH       (8+1),
      .AXI_ADDR_WIDTH         (32),
      .AXI_DATA_WIDTH         (32),
      .AXI_USER_WIDTH         (8),
      .NO_SLV_PORTS           (2),
      .MAX_W_TRANS            (1),
      .FALL_THROUGH           (1'b0),
      .SPILL_AW               (1'b0),
      .SPILL_W                (1'b0),
      .SPILL_B                (1'b0),
      .SPILL_AR               (1'b0),
      .SPILL_R                (1'b0)
    ) axi_mux (
      .clk_i                  ( hclk    ),
      .rst_ni                 ( resetn  ),
      .test_i                 ( cmsatpg    ),
      .slv                    ( aximux_slave_pulp ),
      .mst                    ( nic_s2_pulp )
    );
/*
    AXI_BUS axis(), axim[2:0]();


    axi_demux_intf  axi_demux (
      .clk_i                  ( hclk    ),
      .rst_ni                 ( resetn  ),
      .test_i                 ( cmsatpg    ),
      .slv_aw_select_i        ( '0 ),
      .slv_ar_select_i        ( '0 ),
      .slv                    ( axis ),
      .mst                    ( axim )
    );
*/
bit clk_i;
AXI_BUS_DV #(8,8,8,8)ifa(.*);
AXI_BUS_ASYNC  #(8,8,8,8,8)ifb();
AXI_BUS_ASYNC_GRAY  #(8,8,8,8,8) ifc();
AXI_LITE_DV  #(8,8) ifd(.*);
AXI_LITE #(8,8) ife();
AXI_LITE_ASYNC_GRAY #(8,8,8) ifx();

    dummytb_instantiate_pulpaxiif dut_dummytb_instantiate_pulpaxiif(.*);

endmodule

module dummytb_instantiate_pulpaxiif(
    AXI_BUS_DV.Master ifa,
    AXI_BUS_ASYNC.Master ifb,
    AXI_BUS_ASYNC_GRAY.Master ifc,
    AXI_LITE_DV.Master ifd,
    AXI_LITE.Master ife,
    AXI_LITE_ASYNC_GRAY.Master ifx
    );
endmodule

