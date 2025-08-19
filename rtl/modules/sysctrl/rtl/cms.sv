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

package cms_pkg;

// cms: chip mode selection
// ==

  typedef enum logic [7:0] {
    CMS_NONE     = 8'h00   ,
    CMS_VRGN     = 8'h37   ,
    CMS_ATPG     = 8'h5B   ,
    CMS_TEST     = 8'hA6   ,
    CMS_USER     = 8'hFB   ,
    CMS_SCDE     = 8'hFF
  } cmscode_e;

  localparam CMSDW = 128;

  typedef enum logic [CMSDW-1:0] {
    CMSDAT_VRGNMODE     = '0                                 ,
    CMSDAT_TESTMODE     = '0 ,
    CMSDAT_ATPGMODE     = '0 ,
    CMSDAT_USERMODE     = '0
  } cmsdata_e;

endpackage

//import cms_pkg::*;


module cms (
    input logic clk,    // Clock
    input logic resetn, // Clock Enable
    input logic chipresetn,
    input logic aocmsuser,

    input logic [0:2]       cmspad,
    input cms_pkg::cmsdata_e         cmsdata,
    input logic             cmsdatavld,

    output logic            cmsatpg,
    output logic            cmstest,
    output logic            cmsuser,
    output logic            cmsvrgn,
    output logic            cmsscde,

    output logic            cmserror,
    output logic            cmsdone,
    output cms_pkg::cmscode_e        cmscode
);
    logic               cmstestreg;   assign cmstest = cmsatpg ? 1'b0: cmstestreg;
    logic               cmsuserreg;   assign cmsuser = cmsatpg ? 1'b0: cmsuserreg;
    logic               cmsvrgnreg;   assign cmsvrgn = cmsatpg ? 1'b0: cmsvrgnreg;
    logic               cmsscdereg;   assign cmsscde = cmsatpg ? 1'b0: cmsscdereg;
    logic               cmsdonereg;   assign cmsdone = cmsatpg ? 1'b1: cmsdonereg;
    cms_pkg::cmscode_e  cmscodereg;   assign cmscode = cmsatpg ? cms_pkg::CMS_ATPG : cmscodereg;

    logic cmsresetn;

    assign cmsresetn = chipresetn & resetn;

// cmspad sample and check

    localparam CMSPADCYC = 128;

    bit [1:0][0:2]  cmspadregs;
    bit             cmspadlock;
    bit [7:0]       cmspadcnt;
    bit             cmspaderror;
    bit [2:0]       cmspadout;
    bit cmsatpg_reg;

    `theregrn( cmspadregs ) <= { cmspadregs, cmspad };
    `theregrn( cmspadlock ) <= ( cmspadcnt == CMSPADCYC );
    `theregrn( cmspadcnt )  <= ( cmspadcnt == CMSPADCYC ) ? cmspadcnt : cmspadcnt+1;

    `theregfull( clk, chipresetn, cmspaderror, '0 ) <= ( cmspadregs[1] != cmspadregs[0] ) & cmspadlock ? 1'b1 : cmspaderror;

//    assign cmspadout = cmspadregs[1];
    `theregrn( cmspadout ) <= ~cmspadlock ? cmspadregs[1] : cmspadout;

// cmsdata pattern

    bit         cmsdataregvld;
    cms_pkg::cmsdata_e   cmsdatareg;

    `theregfull(clk, resetn, cmsdatareg, cms_pkg::CMSDAT_VRGNMODE) <= cmsdatavld ? cmsdata : cmsdatareg;
    `theregrn( cmsdataregvld ) <= cmsdatavld ? 1'b1 :    cmsdataregvld;

// cms
    logic [5:0] cmsfsm;

    `theregfull( clk, resetn, cmsfsm, '0 ) <= ( cmsfsm != '1 ) & cmsdataregvld & cmspadlock ? cmsfsm + 1 : cmsfsm;
    `theregfull( clk, resetn, cmsdonereg, '0 ) <= ( cmsfsm == '1 );

    cms_pkg::cmscode_e   cmscodepre;


    always@(*)
    casex(cmspadout)
        3'bxx1: cmscodepre = ( cmsdatareg == cms_pkg::CMSDAT_USERMODE ) ? cms_pkg::CMS_USER :
                                                                          cms_pkg::CMS_TEST;
        3'b0x0: cmscodepre = cms_pkg::CMS_USER;
        3'b100, //cmscodepre = ( cmsdatareg == cms_pkg::CMSDAT_USERMODE ) ? cms_pkg::CMS_USER :
                //                                                          cms_pkg::CMS_ATPG ;
        3'b110: cmscodepre = ( cmsdatareg == cms_pkg::CMSDAT_VRGNMODE ) ? //cms_pkg::CMS_VRGN :
                                                                    ( cmspadout[1] ?
                                                                          cms_pkg::CMS_VRGN :
                                                                          cms_pkg::CMS_ATPG ) :
                             ( cmsdatareg == cms_pkg::CMSDAT_TESTMODE ) ?
                                                                    ( cmspadout[1] ?
                                                                          cms_pkg::CMS_TEST :
                                                                          cms_pkg::CMS_ATPG ) :
                             ( cmsdatareg == cms_pkg::CMSDAT_USERMODE ) ? cms_pkg::CMS_USER :
                                                                          cms_pkg::CMS_SCDE ;
        default: cmscodepre = cms_pkg::CMS_NONE;
    endcase


`ifdef FPGA
    `theregfull( clk, resetn, cmscodereg, cms_pkg::CMS_NONE ) <= cms_pkg::CMS_USER ;
    `theregfull(clk, cmsresetn, cmsatpg, 1'b0) <= '0;
    `theregrn( cmsvrgnreg ) <= '0;
    `theregrn( cmstestreg ) <= '0;
    `theregrn( cmsuserreg ) <= '1;
    `theregrn( cmsscdereg ) <= '0;
`else
    `ifdef MPW
        `theregfull(clk, cmsresetn, cmsatpg_reg, 1'b0) <= '0;
        `theregrn( cmstestreg ) <=   cmscodereg == cms_pkg::CMS_TEST | cmscodereg == cms_pkg::CMS_VRGN;
    `else
        `theregfull(clk, cmsresetn, cmsatpg_reg, 1'b0) <= ( cmscodereg == cms_pkg::CMS_ATPG ) | cmsatpg_reg;
        `theregrn( cmstestreg ) <=   cmscodereg == cms_pkg::CMS_TEST | cmscodereg == cms_pkg::CMS_VRGN;
    `endif
    `theregfull( clk, resetn, cmscodereg, cms_pkg::CMS_NONE ) <= cmsdataregvld & cmspadlock ? ( aocmsuser ? cms_pkg::CMS_USER : cmscodepre) : cmscode;
    `theregrn( cmsvrgnreg ) <=   cmscodereg == cms_pkg::CMS_VRGN;
    `theregrn( cmsuserreg ) <=   cmscodereg == cms_pkg::CMS_USER;
    `theregrn( cmsscdereg ) <= ( cmscodereg == cms_pkg::CMS_SCDE ) | cmsscdereg;

    DATACELL_BUF u_atpgmode_buf     (.A(cmsatpg_reg),.Z(cmsatpg));

`endif


`ifdef SIM

always@(posedge cmsdonereg)begin
         if( cmsdatareg == cms_pkg::CMSDAT_USERMODE ) $display("::::::::cmscode::::::::::USERMODE ________________",);
    else if( cmsdatareg == cms_pkg::CMSDAT_VRGNMODE ) $display("::::::::cmscode::::::::::VRGNMODE ________________",);
    else if( cmsdatareg == cms_pkg::CMSDAT_TESTMODE ) $display("::::::::cmscode::::::::::TESTMODE ________________",);
    else                                              $display("::::::::cmscode::::::::::SCDEMODE ________________%032x", cmsdatareg);
    $display("::::::::cmspads::::::::::%01x, %01x, %01x ", cmspadout[0], cmspadout[1], cmspadout[2]);
    if( cmscode == cms_pkg::CMS_NONE )$display("::::::::  CMS  :::::::::: CMS_NONE (%02x)", cmscode);
    if( cmscode == cms_pkg::CMS_VRGN )$display("::::::::  CMS  :::::::::: CMS_VRGN (%02x)", cmscode);
    if( cmscode == cms_pkg::CMS_ATPG )$display("::::::::  CMS  :::::::::: CMS_ATPG (%02x)", cmscode);
    if( cmscode == cms_pkg::CMS_TEST )$display("::::::::  CMS  :::::::::: CMS_TEST (%02x)", cmscode);
    if( cmscode == cms_pkg::CMS_USER )$display("::::::::  CMS  :::::::::: CMS_USER (%02x)", cmscode);
    if( cmscode == cms_pkg::CMS_SCDE )$display("::::::::  CMS  :::::::::: CMS_SCDE (%02x)", cmscode);

end

`endif


`ifdef SIM
    initial begin
        // for sim only
        cmsatpg_reg = '0;
        #1; cmsatpg_reg = '0;
    end
`endif


// error

    assign cmserror = cmsatpg? 1'b0 : cmspaderror;

endmodule: cms
