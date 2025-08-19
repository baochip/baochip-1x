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
//`include "icg.v"

module cgucore
    #(
        parameter ICNT = 4,
        parameter OCNT = 6,
        parameter FDW = 8,
        parameter GEARLMT = 2**FDW
    )
    (
        input   logic [0:ICNT-1]    clksrc, // 0:clkosc; 1:clkxtl; 2:clkpll0, 3:clkpll1
        input   logic               cmsatpg,atpg_ascapen,
        input   logic               clkocc1_800m,
        input   logic               clkocc2_400m,
        input   logic               clkocc3_200m,
        input   logic               clkocc4_100m,
        input   logic               clkocc5_50m,
        input   logic               clkocc7_300m,
        input   logic               porresetn,
        input   logic               resetn,
        input   logic               clksyssel,
        input   logic               clktopsel,
        input   logic               clktopselupdate,
        output  logic               clksys,
        output  logic               clksys2,
        output  logic               clksys_undft,
        output  logic               clktop,
        output  logic               clkpke,

        input   logic               clktopenin,
        input   bit   [0:OCNT-1][FDW-1:0]  fd0,
        input   bit   [0:OCNT-1][FDW-1:0]  fd,
        input   bit                 fdload,
        output  logic [0:OCNT-1]    clkout,
        output  logic [0:OCNT-1]    clkouten,
        output  logic [0:OCNT-1]    clkouten_atparent,
        output  bit [0:1]   clksysselen, clktopselen
    );

    bit         clk;
    bit         clksysselreg,  clktopselreg , clkpkeselreg;
    bit         clksysselreg0, clktopselreg0, clkpkeselreg0;
    bit         clksysselreg1, clktopselreg1, clkpkeselreg1;
    bit [0:1]   clksys0, clktop0, clkpkeselen, clkpke0, clksysselen_tmp;
    logic [0:OCNT-1]    clkout_unmux;
    logic clksys_unmux, clkpke_unmux;

//
// clksys select
// ==
// clksys is basic clk should be guaranteed without PLL
// it starts from clkosc, and can be redirected to xtal by software.
// ****usermode reset(resetn here) will not change the selection.****
// ==

    `theregfull(clksys, porresetn, clksysselreg0, 1'b0) <= clksyssel;
    `theregfull(clksys, porresetn, clksysselreg , 1'b0) <= clksysselreg0 ;

    cgudyncswt uclksyssel(
        .clk0   (clksrc[0]),
        .clk1   (clksrc[1]),
        .resetn (porresetn),
        .clksel (clksysselreg),
        .clk0en (clksysselen_tmp[0]),
        .clk1en (clksysselen_tmp[1])
    );

    assign clksysselen[0] = cmsatpg ? 1'b1 : clksysselen_tmp[0];
    assign clksysselen[1] = cmsatpg ? 1'b0 : clksysselen_tmp[1];

    ICG uclksys0 ( .CK (clksrc[0]), .EN ( clksysselen[0] ), .SE(1'b0), .CKG ( clksys0[0] ));
    ICG uclksys1 ( .CK (clksrc[1]), .EN ( clksysselen[1] ), .SE(1'b0), .CKG ( clksys0[1] ));

`ifdef FPGA
    assign clksys = clksrc[1];
    assign clksys2 = clksrc[1];
    assign clksys_undft = clksrc[1];
`else
    logic clksys_unbuf;
    CLKCELL_BUF buf_clksys_cts(.A(clksys_unbuf),.Z(clksys));
    CLKCELL_BUF buf_clksys(.A(clksys_unbuf),.Z(clksys2));
//    assign clksys_unbuf = |clksys0 ;
    assign clksys_unmux = |clksys0 ;
    CLKCELL_BUF buf_clksys_undft(.A(clksys_unmux),.Z(clksys_undft));
    CLKCELL_MUX2 u_scanmux_clksys (.A(clksys_unmux),.B(clkocc5_50m),.S(cmsatpg),.Z(clksys_unbuf));
`endif
// clktop select
// ==

//    assign clk = clktop;

    `theregfull(clktop, resetn, clktopselreg0, 1'b0) <= clktopselupdate ? clktopsel : clktopselreg0;
    `theregfull(clktop, resetn, clktopselreg1,  1'b0) <= clktopselreg0;
    `theregfull(clktop, resetn, clktopselreg ,  1'b0) <= clktopselreg1;

    cgudyncswt uclktopsel(
        .clk0   (clksys2),
        .clk1   (clksrc[2]),
        .resetn (resetn),
        .clksel (clktopselreg),
        .clk0en (clktopselen[0]),
        .clk1en (clktopselen[1])
    );

    ICG uclktop0 ( .CK (clksys2  ), .EN ( clktopselen[0] ), .SE(cmsatpg), .CKG ( clktop0[0] ));
    ICG uclktop1 ( .CK (clksrc[2]), .EN ( clktopselen[1] ), .SE(cmsatpg), .CKG ( clktop0[1] ));
`ifdef FPGA
    assign clktop = clksrc[2];
`else
    logic clktop_unmux;
    logic clktop_unbuf;
    assign clktop_unmux = |clktop0 ;
    CLKCELL_MUX2 u_scanmux_clktop (.A(clktop_unmux),.B(clkocc1_800m),.S(cmsatpg),.Z(clktop_unbuf));
    CLKCELL_BUF buf_clktop(.A(clktop_unbuf),.Z(clktop));
//  assign clktop_unbuf = |clktop0 ;
`endif

    assign clkpkeselreg0 = clktopselreg0;
    `theregfull(clkpke, resetn, clkpkeselreg1,  1'b0) <= clkpkeselreg0;
    `theregfull(clkpke, resetn, clkpkeselreg ,  1'b0) <= clkpkeselreg1;

    cgudyncswt uclkpkesel(
        .clk0   (clksys2),
        .clk1   (clksrc[3]),
        .resetn (resetn),
        .clksel (clkpkeselreg),
        .clk0en (clkpkeselen[0]),
        .clk1en (clkpkeselen[1])
    );

    ICG uclkpke0 ( .CK (clksys2  ), .EN ( clkpkeselen[0] ), .SE(cmsatpg), .CKG ( clkpke0[0] ));
    ICG uclkpke1 ( .CK (clksrc[3]), .EN ( clkpkeselen[1] ), .SE(cmsatpg), .CKG ( clkpke0[1] ));

`ifdef FPGA
    assign clkpke = clksrc[3];
`else
   logic clkpke_unbuf;
    assign clkpke_unmux = |clkpke0 ;
    CLKCELL_MUX2 u_scanmux_clkpke (.A(clkpke_unmux),.B(clkocc7_300m),.S(cmsatpg),.Z(clkpke_unbuf));
    CLKCELL_BUF buf_clkpke(.A(clkpke_unbuf),.Z(clkpke));
//   assign clkpke_unbuf = |clkpke0 ;
`endif

// clkout 0 : gear
// ==

    logic [0:OCNT-1]     iclken;
    logic [0:OCNT-1]     oclken;
    logic [0:OCNT-1]     oclken_aticlk;
    assign clkouten = oclken;

/*
    gearbox fd0(
        .clk        (clktop     ),
        .resetn     (resetn     ),
        .gnum    (fd[0]      ),
        .gnumld   (fdload     ),
        .gen    (oclken[0]  )
    );
*/
            cgufdsync #(.FD0('h7F ))fdu0(
                .clk            (clktop),
                .resetn         (resetn),
                .clk0en         (clktopenin),
                .clk1en         (1'b1),
                .fd0            (fd0[0]),
                .fd2            (fd[0]),
                .fdload         (fdload),
                .clk2en         (oclken[0]),
                .clk2en_atclk1  (clkouten_atparent[0])
            );

     ICG fdicg ( .CK (clktop   ), .EN ( oclken[0] ), .SE(cmsatpg), .CKG ( clkout_unmux[0] ));
//eco8a:
//     CLKCELL_MUX2 u_scanmux_clkf (.A(clkout_unmux[0]),.B(clkocc1_800m),.S(atpg_ascapen),.Z(clkout[0]));
//     TIELBWP30P140HVT u_scanmux_clkf_sel ( .ZN ( clkout_0_SEL ) ) ;
     CLKCELL_MUX2 u_scanmux_clkf (.A(clkout_unmux[0]),.B(clkocc1_800m),.S(1'b0),.Z(clkout[0]));

//    ICG fdicg ( .CK (clktop   ), .EN ( oclken[0] ), .SE(cmsatpg), .CKG ( clkout[0] ));

//    assign iclken[0] = 1'b0;
//    assign clkouten_atparent[0] = 1'b1;

// clkout 1~4 : fdsync
// ==
    logic [1:OCNT-1] oclkencheck;
    logic [1:OCNT-1] clkoutcheck;
    bit   [1:OCNT-1][15:0] checkcnt0, checkcnt1;
    logic [1:OCNT-1]checkfdsync_enatparenterror ;
    genvar gvi;

    generate
       for(gvi=1;gvi<OCNT;gvi++) begin: genfd
            cgufdsync #(.FD0( (gvi==OCNT-1)?'hF:'h7F ))fdu(
                .clk            (clktop),
                .resetn         (resetn),
                .clk0en         (clktopenin),
                .clk1en         (iclken[gvi]),
                .fd0            (fd0[gvi]),
                .fd2            (fd[gvi]),
                .fdload         (fdload),
                .clk2en         (oclken[gvi]),
                .clk2en_atclk1  (clkouten_atparent[gvi])
            );
            assign oclkencheck[gvi] = oclken[gvi] & ~iclken[gvi];
            `ifdef SIM
                always@(posedge clktop)
                    if(oclkencheck[gvi]) $display("%t %m clkfdsync wrong!", $time );
            logic clkout_0;
            assign clkout_0 = (gvi==OCNT-1) ?  clkout[2] : clkout[gvi-1];
            ICG fdicgcheck ( .CK (clkout_0   ), .EN ( clkouten_atparent[gvi] ), .SE(cmsatpg), .CKG ( clkoutcheck[gvi] ));
            always@(posedge clkout[gvi])      checkcnt0[gvi] <= checkcnt0[gvi] + 1;
            always@(posedge clkoutcheck[gvi]) checkcnt1[gvi] <= checkcnt1[gvi] + 1;
            always@(posedge clktop) checkfdsync_enatparenterror[gvi] <= ~( checkcnt0[gvi] == checkcnt1[gvi] );
            always@(posedge clktop)
                if(checkfdsync_enatparenterror[gvi]) $display("%t %m checkfdsync_en_atparent_error wrong!", $time );

            `endif
            assign iclken[gvi] = (gvi==OCNT-1) ?  oclken[2] : oclken[gvi-1]; // for the last clock is aoclk, which is based on ahb(oclken[3])
            ICG fdicg ( .CK (clktop   ), .EN (oclken[gvi] ), .SE(cmsatpg), .CKG (clkout_unmux[gvi]  ));
//           ICG fdicg ( .CK (clktop   ), .EN ( oclken[gvi] ), .SE(cmsatpg), .CKG ( clkout[gvi] ));
         end
    endgenerate
/*
*/
     CLKCELL_MUX2 u_scanmux_clka  (.A(clkout_unmux[1]),.B(clkocc2_400m),.S(atpg_ascapen),.Z(clkout[1]));
     CLKCELL_MUX2 u_scanmux_clkh  (.A(clkout_unmux[2]),.B(clkocc3_200m),.S(atpg_ascapen),.Z(clkout[2]));
     CLKCELL_MUX2 u_scanmux_clki  (.A(clkout_unmux[3]),.B(clkocc4_100m),.S(atpg_ascapen),.Z(clkout[3]));
     CLKCELL_MUX2 u_scanmux_clkp  (.A(clkout_unmux[4]),.B(clkocc5_50m ),.S(atpg_ascapen),.Z(clkout[4]));
     CLKCELL_MUX2 u_scanmux_clkao (.A(clkout_unmux[5]),.B(clkocc5_50m ),.S(cmsatpg),.Z(clkout[5]));
endmodule:cgucore


// sim testbench
// ==

`ifdef SIMCGUCORE

module cgucoretb();

        parameter ICNT = 3;
        parameter OCNT = 5;
        parameter FDW = 8;
        parameter GEARLMT = 2**FDW;

    bit [0:ICNT-1]    clksrc;
    bit               clk, resetn;
    bit               clksrcselupdate;
    bit               clksyssel;
    bit               clktopsel;
    bit               clksys;
    bit               clktop;
    bit               clktopenin=1;
    bit   [0:OCNT-1][FDW-1:0]  fd0;
    bit   [0:OCNT-1][FDW-1:0]  fd;
    bit                 fdload;
    logic [0:OCNT-1]    clkout;
    logic [0:OCNT-1]    clkouten_atparent;
    integer i;

    `genclk( clksrc[0], 40 );   // osc
    `genclk( clksrc[1], 41 );   // xtal
    `genclk( clksrc[2], 23  );  // clkpll

    logic               clkocc1_800m;
    logic               clkocc2_400m;
    logic               clkocc3_200m;
    logic               clkocc4_100m;
    logic               clkocc5_50m;

cgucore  #(
        .ICNT ( 4 ),
        .OCNT ( 5 ),
        .FDW ( 8 ),
        .GEARLMT ( 2**8 )
    )dut(.*);

//    `timemarker
    integer tmms=0, tmus=0;
    initial forever #( 1 `US ) tmus = ( tmus == 1000 ) ? 0 : tmus + 1 ;
    initial forever #( 1 `MS ) tmms = tmms + 1 ;
    always@( tmms ) $display("------------------------------------[%0dms][%4h][%4h][%4h][%4h][%d]------------------------------------", tmms,
            dut.checkcnt0[1],
            dut.checkcnt0[2],
            dut.checkcnt0[3],
            dut.checkcnt0[4],
            (dut.checkcnt0[4]+dut.checkcnt0[1]+dut.checkcnt0[2]+dut.checkcnt0[3])-
            (dut.checkcnt1[4]+dut.checkcnt1[1]+dut.checkcnt1[2]+dut.checkcnt1[3])
        ) ;

    `ifndef NOFSDB
    initial begin
        #(10 `MS); `maintestend
    `endif

    `maintest( cgucoretb, cgucoretb )
        #( 1`US ); #100 resetn = 1;

        #( 100 `US ); clksyssel = 1; clktopsel = 0; #( 1 `US );@(negedge clksys);clksrcselupdate=1;@(negedge clksys);clksrcselupdate=0;
        #( 100 `US ); clksyssel = 1; clktopsel = 1; #( 1 `US );@(negedge clksys);clksrcselupdate=1;@(negedge clksys);clksrcselupdate=0;
        #( 100 `US ); clksyssel = 1; clktopsel = 0; #( 1 `US );@(negedge clksys);clksrcselupdate=1;@(negedge clksys);clksrcselupdate=0;
        #( 100 `US ); clksyssel = 0; clktopsel = 0; #( 1 `US );@(negedge clksys);clksrcselupdate=1;@(negedge clksys);clksrcselupdate=0;

        #( 100 `US );


    `ifdef NOFSDB
        for( i = 0; i < 1000; i=0)begin
    `else
        for( i = 0; i < 1000; i++)begin
    `endif
            fd[0] = $urandom();
            fd[1] = $urandom();
            fd[2] = $urandom();
            fd[3] = $urandom();
            fd[4] = $urandom();

            #( 1 `US );@(negedge clktop );fdload=1;@(negedge clktop);fdload=0;
        #( 100 `US );
        end
        #( 100 `US );

    `maintestend

endmodule



`endif

