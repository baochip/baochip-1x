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

package trc_pkg;

  typedef enum logic [3:0] {
    TRC_IDLE        = 4'h0 ,
    TRC_READ        = 4'h1 ,
    TRC_LOAD        = 4'h2 ,
    TRC_WRITE       = 4'h3 ,
    TRC_CLR_LOAD    = 4'h4 ,
    TRC_WRT_CONFIG  = 4'h5 ,
    TRC_READ_CONFIG = 4'h6 ,
    TRC_RECALL      = 4'h7 ,
    TRC_RST_REG     = 4'h8 ,
    TRC_DMA         = 4'h9 ,
    TRC_REWRITE     = 4'ha
  } trc_cmd_e;

endpackage


package rrc_pkg;

    localparam RRAW = 16;   // rerma AW for 256b
    localparam RRDW = 144;  // rerma DW 144
    localparam RRCW = 210;  // rerma CW 210

    typedef bit[RRAW-5:0] rrxadr_t;
    typedef bit[4:0]      rryadr_t;    
    typedef bit[RRDW-1:0] rrdat_t;
    typedef bit[RRCW-1:0] rrcfg_t;

  // reram port
    typedef struct packed {
        bit             SET         ;                                
        bit             RESET       ;                
        bit             RST         ;      
        bit             NAP         ;    
        bit             REDEN       ;   
        bit             IFREN1      ;   
        bit             IFREN       ;   
        bit             XE          ;   
        bit             YE          ;   
        bit             READ        ;   
        bit             PCH_EXT     ;   
        bit             AE          ;       
        bit             CE          ;     
        rrxadr_t        XADR        ;   
        rryadr_t        YADR        ;   
        rrcfg_t         CFG_MACRO   ;     
//      bit             POC_IO      ;          
        rrdat_t         DIN         ;     
        bit [1:0]       DIN_CR      ;
    }rri_t; 

    typedef struct packed {
        rrdat_t         DOUT        ;         
        bit [1:0]       DOUT_CR     ;       
        bit             RDONE       ; 
    }rro_t; 

//  typedef struct packed {
//      bit             ANALOG_0    ;
//  }rrio_t;

endpackage: rrc_pkg

/*
module rrc(
        output rrc_pkg::rri_t [1:0] rri,
        input  rrc_pkg::rro_t [1:0] rro
    );
endmodule

module coretop1(
        output rrc_pkg::rri_t [1:0] rri,
        input  rrc_pkg::rro_t [1:0] rro
    );
    rrc rrc(.rri, .rro);
endmodule

module coretop2(
        output rrc_pkg::rri_t [1:0] rri,
        input  rrc_pkg::rro_t [1:0] rro
    );
    coretop1 coretop1(.rri, .rro);
endmodule

module top();
        rrc_pkg::rri_t [1:0] rri;
        rrc_pkg::rro_t [1:0] rro;
    generate
        for (genvar i = 0; i < 2; i++) begin:r
            rerammacro r(.rri(rri[i]),.rro(rro[i]));
        end
    endgenerate
    coretop1 coretop1(.rri, .rro);

endmodule


// from tsmc
module rerammacro(
        input  rrc_pkg::rri_t rri,
        output rrc_pkg::rro_t rro
    );
endmodule

*/

