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


module cm7sys_tcm
  #(
    parameter bit itcm = 0,
    parameter sram_pkg::sramcfg_t thecfg={
        AW: 13,
        DW: 32,
        KW: 32,
        PW: 4,
        WCNT: 2**13,
        AWX: 5,
        isBWEN: '1,
        isSCMB: '0,
        isPRT:  '1,
        EVITVL: 15
    },
    parameter RC=1,
    parameter RDW = 2 // ready_counter/wait_cyc width
   )
   (input  logic                     clk,
    input  logic                     clktop,
    input  logic                     clken,
    input  logic                     cmsatpg,
    input  logic                     cmsbist,

    input  logic [RDW-1:0]           waitcyc,
    input  logic [2:0]               sramtrm,
    input  logic                     even,
    input  logic                     resetn,
    rbif.slave              rbs[0:RC-1],

    input  logic [thecfg.AW-1:0]     addr_i,
    input  logic [thecfg.DW-1:0]     wd_i,
    input  logic                     cs_i,
    input  logic [thecfg.DW/8-1:0]   we_i,
    output logic [thecfg.DW-1:0]     rd_o,
    output logic                     wait_o,
    output logic                     err_o,
    output logic                    retry_o
   );

    logic [thecfg.DW-1:0]     ramm_ramrdata, tcmdout;

    ramif #(.RAW(thecfg.AW),.DW(thecfg.DW))rams();

    logic verifyerr, prerr, ramready;

    wire2ramm #(.AW(thecfg.AW),.DW(thecfg.DW)) RM(
        .ramm_ramen      (1'b1),
        .ramm_ramcs      (cs_i),
        .ramm_ramaddr    (addr_i),
        .ramm_ramwr      (we_i),
        .ramm_ramwdata   (wd_i),
        .ramm_ramrdata   (ramm_ramrdata),
        .ramm_ramready   (ramready),
        .ramm (rams)
    );

    assign wait_o = ~ramready;
    assign err_o = verifyerr | prerr;
    assign retry_o = 1'b0;

`ifdef FPGA

    assign rd_o = ramm_ramrdata;
    assign {verifyerr,prerr}='0;
    generate
    if(itcm) begin: genitcm
        uram_cas #( .XX (1), .YY (8)) tcmram (
          .clk          (clk),
          .resetn,
          .waitcyc      (waitcyc|4'h0),
          .rams         (rams)
        );
    end
    else begin:gendtcm
        uram_none tcmram (
          .clk          (clk),
          .resetn,
          .waitcyc      (waitcyc|4'h0),
          .rams         (rams)
        );
    end
    endgenerate

`else
    ramif #(.RAW(thecfg.AW),.DW(thecfg.DW+thecfg.PW),.BW(9))tcmrams();

    logic fastmode;
    `theregrn(fastmode) <= fastmode | sramtrm[0];// | 1;

//    gnrl_sramc #(
    tcmramc #(
        .thecfg(thecfg)
    )uramc(
        .clk,
        .resetn,
        .cmsatpg,
        .cmsbist,
        .fastmode   (fastmode),
        .scmben     ('0       ),
        .scmbkey    ('0       ),
        .even       ( even    ),
        .prerr      (prerr    ),
        .verifyerr  (verifyerr),
        .ramslave   (rams     ),
        .rammaster  (tcmrams  )
    );

    assign rd_o = cmsatpg ? '0 : tcmdout;

    tcmram #(.itcm(itcm),.thecfg(thecfg),.RC(RC))tcm
    (
        .clk    (clktop),
        .clken  (clken),
        .resetn (resetn),
        .cmsatpg(cmsatpg),
        .cmsbist,
        .rbs(rbs),
        .waitcyc(waitcyc),
        .sramtrm(sramtrm),
        .tcmdout    (tcmdout),
        .rams   (tcmrams)
    );

`endif

endmodule : cm7sys_tcm

`ifndef FPGA

module tcmramc
#(
    parameter sram_pkg::sramcfg_t thecfg=sram_pkg::samplecfg
)(
    input logic             clk,
    input logic             resetn,
    input logic             cmsatpg,
    input logic             cmsbist,
    input logic             fastmode,
    input logic             scmben,
    input logic [thecfg.KW-1:0] scmbkey,
    input logic             even,
    output logic            prerr,
    output logic            verifyerr,

    ramif.slave             ramslave,
    ramif.master            rammaster
);

    logic prerr0;
    logic verifyerr0;
    ramif #(.RAW(thecfg.AW),.DW(thecfg.DW))     rama0(),rama1();
    ramif #(.RAW(thecfg.AW),.DW(thecfg.DW+thecfg.PW),.BW(9))ramb0(),ramb1();

// 1)
// ramslave ==> rama0, rama1

    ram1sto2m u0 (.sel(fastmode),.rams(ramslave),.ramm0(rama0),.ramm1(rama1));


// 2, fast)
//     rama1 -> ramb1

    assign verifyerr = fastmode ? 1'b0 : verifyerr0;
    assign prerr = fastmode ? 1'b0 : prerr0;

    tcmramc_thru #(
        .thecfg(thecfg)
    )ramc1(
        .ramslave   (rama1  ),
        .rammaster  (ramb1  )
    );

// 2, slow)
//    rama0 -> ramb0

    logic clk1;
    ICG ramc0_icg ( .CK (clk), .EN ( ~fastmode ),.SE(cmsatpg), .CKG ( clkramc0 ));
    gnrl_sramc #(
        .thecfg(thecfg)
    )ramc0(
        .clk (clkramc0),
        .resetn,
        .cmsatpg,
        .cmsbist,
        .scmben,
        .scmbkey,
        .even,
        .prerr      (prerr0),
        .verifyerr  (verifyerr0),
        .ramslave   (rama0     ),
        .rammaster  (ramb0  )
    );

// 3)
//   ramb0/ramb1 => rammaster

    ram2sto1m u1 (.sel(fastmode),.rams0(ramb0),.rams1(ramb1),.ramm(rammaster));

endmodule : tcmramc

module tcmramc_thru
#(
    parameter sram_pkg::sramcfg_t thecfg=sram_pkg::samplecfg
)(
    ramif.slave             ramslave,
    ramif.master            rammaster
);

    localparam DW   = thecfg.DW   ; // 32,

    assign rammaster.ramen    = ramslave.ramen    ;
    assign rammaster.ramcs    = ramslave.ramcs    ;
    assign rammaster.ramaddr  = ramslave.ramaddr  ;
    assign rammaster.ramwr    = ramslave.ramwr    ;
    assign ramslave.ramready  = rammaster.ramready ;

    generate
        for(genvar gvi=0; gvi<DW/8; gvi++) begin : gg
            assign rammaster.ramwdata[gvi*9+8:gvi*9] = { ramslave.ramwdata[gvi*8+7:gvi*8], 1'b0 };
            assign ramslave.ramrdata[gvi*8+7:gvi*8] = rammaster.ramrdata[gvi*9+8:gvi*9+1];
        end
    endgenerate

endmodule

`endif

/*
module dummytb_cm7sys_tcm();


  assign clkcm7in = fclken;

  cm7sys_tcm
   #(
      .itcm   ('1),
      .thecfg (daric_cfg::itcmcfg),
      .RC     (daric_cfg::itcmrc)
    )
  u_itcm_ram
    (.clk        (clkcm7in),
     .clktop     (clktop),
     .clken      (fclken),
     .cmsatpg    (cmsatpg),
     .cmsbist    (cmsbist),
     .waitcyc    (cm7cfg_itcmwaitcyc),
     .resetn     (resetn),

     .addr_i     (sys_itcmaddr[daric_cfg::itcmcfg.AW+3-1:3]),
     .wd_i       (sys_itcmwdata[63:0]),
     .cs_i       (sys_itcmcs),
     .we_i       (sys_itcmbytewr[7:0]),
     .rd_o       (sys_itcmrdata0[63:0]),
     .wait_o     (sys_itwait),
     .err_o      (sys_iterr),
     .retry_o    (sys_itretry)
     );

  cm7_ik_tcm_ram
   #(
      .itcm   ('0),
      .thecfg (daric_cfg::dtcmcfg),
      .RC     (daric_cfg::dtcmrc)
    )
  u_d0tcm_ram
    (.clk        (clkcm7in),
     .clktop     (clktop),
     .clken      (fclken),
     .cmsatpg    (cmsatpg),
     .cmsbist    (cmsbist),
     .waitcyc    (cm7cfg_dtcmwaitcyc),
     .resetn     (resetn),

     .addr_i     (sys_d0tcmaddr[daric_cfg::dtcmcfg.AW+3-1:3]),
     .wd_i       (sys_d0tcmwdata[31:0]),
     .cs_i       (sys_d0tcmcs),
     .we_i       (sys_d0tcmbytewr[3:0]),
     .rd_o       (sys_d0tcmrdata[31:0]),
     .wait_o     (sys_d0wait),
     .err_o      (sys_d0err),
     .retry_o    (sys_d0retry)
     );

    `maintest(dummytb_cm7sys_tcm,dummytb_cm7sys_tcm)
        #105 ;

        #(1 `MS);
    `maintestend

endmodule
*/

