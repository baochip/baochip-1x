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

//  Description : AXI Testbench Master Interface
//                can be used to drive AXI read/write transactions 
//
/////////////////////////////////////////////////////////////////////////// 

                                                                                    
interface axi_if_mst #(
                      parameter AXI_ID_WIDTH   = 6,
                      parameter AXI_ADDR_WIDTH = 32,
                      parameter AXI_DATA_WIDTH = 64,
                      parameter AXI_LEN_WIDTH = 8,
                      parameter AXI_USER_WIDTH = 8
)(
    input logic clk,
    input logic resetn,
    axiif.master axim 
);

  localparam int unsigned AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

  typedef logic [AXI_ID_WIDTH-1:0]   id_t;
  typedef logic [AXI_ADDR_WIDTH-1:0] addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0] data_t;
  typedef logic [AXI_STRB_WIDTH-1:0] strb_t;
  typedef logic [AXI_USER_WIDTH-1:0] user_t;


  import axi_util_pkg::*;
  
  id_t              aw_id;
  addr_t            aw_addr;
  axi_tb_pkg::len_t    aw_len;
  axi_tb_pkg::size_t   aw_size;
  axi_tb_pkg::burst_t  aw_burst;
  logic             aw_lock;
  axi_tb_pkg::cache_t  aw_cache;
  axi_tb_pkg::prot_t   aw_prot;
  axi_tb_pkg::qos_t    aw_qos;
  axi_tb_pkg::region_t aw_region;
  axi_tb_pkg::atop_t   aw_atop;
  user_t            aw_user;
  logic             aw_valid;
  logic             aw_ready;

  id_t              w_id;
  data_t            w_data;
  strb_t            w_strb;
  logic             w_last;
  user_t            w_user;
  logic             w_valid;
  logic             w_ready;

  id_t              b_id;
  axi_tb_pkg::resp_t   b_resp;
  user_t            b_user;
  logic             b_valid;
  logic             b_ready;

  id_t              ar_id;
  addr_t            ar_addr;
  axi_tb_pkg::len_t    ar_len;
  axi_tb_pkg::size_t   ar_size;
  axi_tb_pkg::burst_t  ar_burst;
  logic             ar_lock;
  axi_tb_pkg::cache_t  ar_cache;
  axi_tb_pkg::prot_t   ar_prot;
  axi_tb_pkg::qos_t    ar_qos;
  axi_tb_pkg::region_t ar_region;
  user_t            ar_user;
  logic             ar_valid;
  logic             ar_ready;

  id_t              r_id;
  data_t            r_data;
  axi_tb_pkg::resp_t   r_resp;
  logic             r_last;
  user_t            r_user;
  logic             r_valid;
  logic             r_ready;

  initial begin
     aw_id    = 'z;
     aw_addr  = 'z;
     aw_valid = 'z;
     aw_len   = 'z;
     aw_size  = 'z;
     aw_burst = 'z;
     aw_lock  = 'z;
     aw_cache = 'z;
     aw_prot  = 'z;
     aw_qos   = 'z;

     w_id    = 'z;
     w_data  = 'z;
     w_strb  = 'z;
     w_last  = 'z;
     w_valid = 'z;

     b_ready = 'z;

     ar_id    = 'z;
     ar_addr  = 'z;
     ar_len   = 'z;
     ar_size  = 'z;
     ar_burst = 'z;
     ar_lock  = 'z;
     ar_cache = 'z;
     ar_prot  = 'z;
     ar_qos   = 'z;
     ar_valid = 'z;

     r_ready  = 'z;

  end


/*  id_t             */      assign axim.awid       = aw_id       ;
/*  addr_t           */      assign axim.awaddr     = aw_addr     ;
/*  axi_tb_pkg::len_t   */   assign axim.awlen      = aw_len      ;
/*  axi_tb_pkg::size_t  */   assign axim.awsize     = aw_size     ;
/*  axi_tb_pkg::burst_t */   assign axim.awburst    = aw_burst    ;
/*  logic            */      assign axim.awlock     = aw_lock     ;
/*  axi_tb_pkg::cache_t */   assign axim.awcache    = aw_cache    ;
/*  axi_tb_pkg::prot_t  */   assign axim.awprot     = aw_prot     ;
                             assign axim.awinner    = '0;
                             assign axim.awmaster   = '0;
                             assign axim.awshare    = '0;
                             assign axim.awsparse   = '1;

///*  axi_tb_pkg::qos_t   */ assign axim.           = aw_qos        
///*  axi_tb_pkg::region_t*/ assign axim.           = aw_region    
///*  axi_tb_pkg::atop_t  */ assign axim.           = aw_atop      
/*  user_t           */      assign axim.awuser     = aw_user     ;
/*  logic            */      assign axim.awvalid    = aw_valid    ;
/*  data_t           */      assign axim.wid        = w_id ;
/*  data_t           */      assign axim.wdata      = w_data      ;
/*  strb_t           */      assign axim.wstrb      = w_strb      ;
/*  logic            */      assign axim.wlast      = w_last      ;
/*  user_t           */      assign axim.wuser      = w_user      ;
/*  logic            */      assign axim.wvalid     = w_valid     ;
/*  id_t             */      assign axim.arid       = ar_id       ;
/*  addr_t           */      assign axim.araddr     = ar_addr     ;
/*  axi_tb_pkg::len_t   */   assign axim.arlen      = ar_len      ;
/*  axi_tb_pkg::size_t  */   assign axim.arsize     = ar_size     ;
/*  axi_tb_pkg::burst_t */   assign axim.arburst    = ar_burst    ;
/*  logic            */      assign axim.arlock     = ar_lock     ;
/*  axi_tb_pkg::cache_t */   assign axim.arcache    = ar_cache    ;
/*  axi_tb_pkg::prot_t  */   assign axim.arprot     = ar_prot     ;
                             assign axim.arinner    = '0;
                             assign axim.armaster   = '0;
                             assign axim.arshare    = '0;

///*  axi_tb_pkg::qos_t   */ assign axim.           = ar_qos         
///*  axi_tb_pkg::region_t*/ assign axim.           = ar_region      
/*  user_t           */      assign axim.aruser     = ar_user     ;
/*  logic            */      assign axim.arvalid    = ar_valid    ;
/*  id_t             */      assign b_id       = axim.bid         ;
/*  axi_tb_pkg::resp_t  */   assign b_resp     = axim.bresp       ;
/*  user_t           */      assign b_user     = axim.buser       ;
/*  logic            */      assign b_valid    = axim.bvalid      ;
/*  id_t             */      assign r_id       = axim.rid         ;
/*  data_t           */      assign r_data     = axim.rdata       ;
/*  axi_tb_pkg::resp_t  */   assign r_resp     = axim.rresp       ;
/*  logic            */      assign r_last     = axim.rlast       ;
/*  user_t           */      assign r_user     = axim.ruser       ;
/*  logic            */      assign r_valid    = axim.rvalid      ;

/*  logic            */      assign aw_ready     = axim.awready  ;
/*  logic            */      assign w_ready      = axim.wready   ;
/*  logic            */      assign ar_ready     = axim.arready  ;
/*  logic            */      assign axim.bready     = b_ready    ;
/*  logic            */      assign axim.rready     = r_ready    ;


endinterface
