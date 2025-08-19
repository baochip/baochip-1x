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

module axitrans_axi2pulp (
    axiif.slave     axis,
    AXI_BUS.Master  axim
);

/*  id_t             */ assign axim.aw_id       = axis.awid     ;
/*  addr_t           */ assign axim.aw_addr     = axis.awaddr   ;
/*  axi_pkg::len_t   */ assign axim.aw_len      = axis.awlen  | 8'h0  ;
/*  axi_pkg::size_t  */ assign axim.aw_size     = axis.awsize   ;
/*  axi_pkg::burst_t */ assign axim.aw_burst    = axis.awburst  ;
/*  logic            */ assign axim.aw_lock     = axis.awlock   ;
/*  axi_pkg::cache_t */ assign axim.aw_cache    = axis.awcache  ;
/*  axi_pkg::prot_t  */ assign axim.aw_prot     = axis.awprot   ;
/*  axi_pkg::qos_t   */ assign axim.aw_qos      = '0 ;  
/*  axi_pkg::region_t*/ assign axim.aw_region   = '0 ;
/*  axi_pkg::atop_t  */ assign axim.aw_atop     = '0 ;
/*  user_t           */ assign axim.aw_user     = axis.awuser   ;
/*  logic            */ assign axim.aw_valid    = axis.awvalid  ;

/*  data_t           */ assign axim.w_data      = axis.wdata    ;
/*  strb_t           */ assign axim.w_strb      = axis.wstrb    ;
/*  logic            */ assign axim.w_last      = axis.wlast    ;
/*  user_t           */ assign axim.w_user      = axis.wuser    ;
/*  logic            */ assign axim.w_valid     = axis.wvalid   ;

/*  id_t             */ assign axis.bid         = axim.b_id      ;
/*  axi_pkg::resp_t  */ assign axis.bresp       = axim.b_resp    ;
/*  user_t           */ assign axis.buser       = axim.b_user    ;
/*  logic            */ assign axis.bvalid      = axim.b_valid   ;

/*  id_t             */ assign axim.ar_id       = axis.arid      ;
/*  addr_t           */ assign axim.ar_addr     = axis.araddr    ;
/*  axi_pkg::len_t   */ assign axim.ar_len      = axis.arlen   | 8'h0  ;
/*  axi_pkg::size_t  */ assign axim.ar_size     = axis.arsize    ;
/*  axi_pkg::burst_t */ assign axim.ar_burst    = axis.arburst   ;
/*  logic            */ assign axim.ar_lock     = axis.arlock    ;
/*  axi_pkg::cache_t */ assign axim.ar_cache    = axis.arcache   ;
/*  axi_pkg::prot_t  */ assign axim.ar_prot     = axis.arprot    ;
/*  axi_pkg::qos_t   */ assign axim.ar_qos      = '0 ;
/*  axi_pkg::region_t*/ assign axim.ar_region   = '0 ;
/*  user_t           */ assign axim.ar_user     = axis.aruser    ;
/*  logic            */ assign axim.ar_valid    = axis.arvalid   ;

/*  id_t             */ assign axis.rid        = axim.r_id      ;
/*  data_t           */ assign axis.rdata      = axim.r_data    ;
/*  axi_pkg::resp_t  */ assign axis.rresp      = axim.r_resp    ;
/*  logic            */ assign axis.rlast      = axim.r_last    ;
/*  user_t           */ assign axis.ruser      = axim.r_user    ;
/*  logic            */ assign axis.rvalid     = axim.r_valid   ;

/*  logic            */ assign axis.awready     = axim.aw_ready  ;
/*  logic            */ assign axis.wready      = axim.w_ready   ;
/*  logic            */ assign axim.b_ready     = axis.bready    ;
/*  logic            */ assign axis.arready     = axim.ar_ready  ;
/*  logic            */ assign axim.r_ready     = axis.rready    ;



endmodule

module axitrans_pulp2axi (
    AXI_BUS.Slave  axis,
    axiif.master     axim
);

/*  id_t             */ assign axim.awid       = axis.aw_id       ;
/*  addr_t           */ assign axim.awaddr     = axis.aw_addr     ;
/*  axi_pkg::len_t   */ assign axim.awlen      = axis.aw_len      ;
/*  axi_pkg::size_t  */ assign axim.awsize     = axis.aw_size     ;
/*  axi_pkg::burst_t */ assign axim.awburst    = axis.aw_burst    ;
/*  logic            */ assign axim.awlock     = axis.aw_lock     ;
/*  axi_pkg::cache_t */ assign axim.awcache    = axis.aw_cache    ;
/*  axi_pkg::prot_t  */ assign axim.awprot     = axis.aw_prot     ;
                        assign axim.awinner    = '0;
                        assign axim.awmaster   = '0;
                        assign axim.awshare    = '0;
                        assign axim.awsparse   = '1;

///*  axi_pkg::qos_t   */ assign axim.           = axis.aw_qos        
///*  axi_pkg::region_t*/ assign axim.           = axis.aw_region    
///*  axi_pkg::atop_t  */ assign axim.           = axis.aw_atop      
/*  user_t           */ assign axim.awuser     = axis.aw_user     ;
/*  logic            */ assign axim.awvalid    = axis.aw_valid    ;
/*  data_t           */ assign axim.wid        = '0 ;
/*  data_t           */ assign axim.wdata      = axis.w_data      ;
/*  strb_t           */ assign axim.wstrb      = axis.w_strb      ;
/*  logic            */ assign axim.wlast      = axis.w_last      ;
/*  user_t           */ assign axim.wuser      = axis.w_user      ;
/*  logic            */ assign axim.wvalid     = axis.w_valid     ;
/*  id_t             */ assign axim.arid       = axis.ar_id       ;
/*  addr_t           */ assign axim.araddr     = axis.ar_addr     ;
/*  axi_pkg::len_t   */ assign axim.arlen      = axis.ar_len      ;
/*  axi_pkg::size_t  */ assign axim.arsize     = axis.ar_size     ;
/*  axi_pkg::burst_t */ assign axim.arburst    = axis.ar_burst    ;
/*  logic            */ assign axim.arlock     = axis.ar_lock     ;
/*  axi_pkg::cache_t */ assign axim.arcache    = axis.ar_cache    ;
/*  axi_pkg::prot_t  */ assign axim.arprot     = axis.ar_prot     ;
                        assign axim.arinner    = '0;
                        assign axim.armaster   = '0;
                        assign axim.arshare    = '0;

///*  axi_pkg::qos_t   */ assign axim.           = axis.ar_qos         
///*  axi_pkg::region_t*/ assign axim.           = axis.ar_region      
/*  user_t           */ assign axim.aruser     = axis.ar_user     ;
/*  logic            */ assign axim.arvalid    = axis.ar_valid    ;
/*  id_t             */ assign axis.b_id       = axim.bid         ;
/*  axi_pkg::resp_t  */ assign axis.b_resp     = axim.bresp       ;
/*  user_t           */ assign axis.b_user     = axim.buser       ;
/*  logic            */ assign axis.b_valid    = axim.bvalid      ;
/*  id_t             */ assign axis.r_id       = axim.rid         ;
/*  data_t           */ assign axis.r_data     = axim.rdata       ;
/*  axi_pkg::resp_t  */ assign axis.r_resp     = axim.rresp       ;
/*  logic            */ assign axis.r_last     = axim.rlast       ;
/*  user_t           */ assign axis.r_user     = axim.ruser       ;
/*  logic            */ assign axis.r_valid    = axim.rvalid      ;

/*  logic            */ assign axis.aw_ready     = axim.awready  ;
/*  logic            */ assign axis.w_ready      = axim.wready   ;
/*  logic            */ assign axis.ar_ready     = axim.arready  ;
/*  logic            */ assign axim.bready     = axis.b_ready    ;
/*  logic            */ assign axim.rready     = axis.r_ready    ;

endmodule


module axithru_pulp (
    AXI_BUS.Slave  axis,
    AXI_BUS.Master  axim
);

/*  id_t             */ assign axim.aw_id       = axis.aw_id       ; // axis.awid     ;
/*  addr_t           */ assign axim.aw_addr     = axis.aw_addr     ; // axis.awaddr   ;
/*  axi_pkg::len_t   */ assign axim.aw_len      = axis.aw_len      ; // axis.awlen  | 8'h0  ;
/*  axi_pkg::size_t  */ assign axim.aw_size     = axis.aw_size     ; // axis.awsize   ;
/*  axi_pkg::burst_t */ assign axim.aw_burst    = axis.aw_burst    ; // axis.awburst  ;
/*  logic            */ assign axim.aw_lock     = axis.aw_lock     ; // axis.awlock   ;
/*  axi_pkg::cache_t */ assign axim.aw_cache    = axis.aw_cache    ; // axis.awcache  ;
/*  axi_pkg::prot_t  */ assign axim.aw_prot     = axis.aw_prot     ; // axis.awprot   ;
/*  axi_pkg::qos_t   */ assign axim.aw_qos      = axis.aw_qos      ; // '0 ;  
/*  axi_pkg::region_t*/ assign axim.aw_region   = axis.aw_region   ; // '0 ;
/*  axi_pkg::atop_t  */ assign axim.aw_atop     = axis.aw_atop     ; // '0 ;
/*  user_t           */ assign axim.aw_user     = axis.aw_user     ; // axis.awuser   ;
/*  logic            */ assign axim.aw_valid    = axis.aw_valid    ; // axis.awvalid  ;

/*  data_t           */ assign axim.w_data      = axis.w_data      ; //axis.wdata    ;
/*  strb_t           */ assign axim.w_strb      = axis.w_strb      ; //axis.wstrb    ;
/*  logic            */ assign axim.w_last      = axis.w_last      ; //axis.wlast    ;
/*  user_t           */ assign axim.w_user      = axis.w_user      ; //axis.wuser    ;
/*  logic            */ assign axim.w_valid     = axis.w_valid     ; //axis.wvalid   ;

/*  id_t             */ assign axim.ar_id       = axis.ar_id       ; //axis.arid      ;
/*  addr_t           */ assign axim.ar_addr     = axis.ar_addr     ; //axis.araddr    ;
/*  axi_pkg::len_t   */ assign axim.ar_len      = axis.ar_len      ; //axis.arlen   | 8'h0  ;
/*  axi_pkg::size_t  */ assign axim.ar_size     = axis.ar_size     ; //axis.arsize    ;
/*  axi_pkg::burst_t */ assign axim.ar_burst    = axis.ar_burst    ; //axis.arburst   ;
/*  logic            */ assign axim.ar_lock     = axis.ar_lock     ; //axis.arlock    ;
/*  axi_pkg::cache_t */ assign axim.ar_cache    = axis.ar_cache    ; //axis.arcache   ;
/*  axi_pkg::prot_t  */ assign axim.ar_prot     = axis.ar_prot     ; //axis.arprot    ;
/*  axi_pkg::qos_t   */ assign axim.ar_qos      = axis.ar_qos      ; //'0 ;
/*  axi_pkg::region_t*/ assign axim.ar_region   = axis.ar_region   ; //'0 ;
/*  user_t           */ assign axim.ar_user     = axis.ar_user     ; //axis.aruser    ;
/*  logic            */ assign axim.ar_valid    = axis.ar_valid    ; //axis.arvalid   ;

/*  logic            */ assign axim.b_ready     = axis.b_ready    ;
/*  logic            */ assign axim.r_ready     = axis.r_ready    ;

/*  id_t             */ assign axis.b_id       = axim.b_id       ; //bid         ;
/*  axi_pkg::resp_t  */ assign axis.b_resp     = axim.b_resp     ; //bresp       ;
/*  user_t           */ assign axis.b_user     = axim.b_user     ; //buser       ;
/*  logic            */ assign axis.b_valid    = axim.b_valid    ; //bvalid      ;
/*  id_t             */ assign axis.r_id       = axim.r_id       ; //rid         ;
/*  data_t           */ assign axis.r_data     = axim.r_data     ; //rdata       ;
/*  axi_pkg::resp_t  */ assign axis.r_resp     = axim.r_resp     ; //rresp       ;
/*  logic            */ assign axis.r_last     = axim.r_last     ; //rlast       ;
/*  user_t           */ assign axis.r_user     = axim.r_user     ; //ruser       ;
/*  logic            */ assign axis.r_valid    = axim.r_valid    ; //rvalid      ;

/*  logic            */ assign axis.aw_ready     = axim.aw_ready  ;
/*  logic            */ assign axis.w_ready      = axim.w_ready   ;
/*  logic            */ assign axis.ar_ready     = axim.ar_ready  ;

endmodule


module dummytb_axitrans ();
    axiif axi0(),axi1();
    AXI_BUS #(
        .AXI_ADDR_WIDTH     ( 32     ),
        .AXI_DATA_WIDTH     ( 32     ),
        .AXI_ID_WIDTH       ( 8   ),
        .AXI_USER_WIDTH     ( 8   )
      ) axipulp0(),axipulp1();
    axitrans_axi2pulp   u1(axi0,axipulp0);
    axithru_pulp        u2(axipulp0,axipulp1);
    axitrans_pulp2axi   u3(axipulp1,axi1);
endmodule
