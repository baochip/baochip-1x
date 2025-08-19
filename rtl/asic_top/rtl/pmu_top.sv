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

module pmu ( A2D_VDD85D_VD09H,
	A2D_VDD85D_VD09L,
	A2D_VDD85D_VD25H,
	A2D_VDD85D_VD25L,
	A2D_VDD85D_VD33H,
	A2D_VDD85D_VD33L,
	A2D_VDDAO_BGRDY,
	A2D_VDDAO_POR,
	A2D_VDDAO_VR25RDY,
	A2D_VDDAO_VR85ARDY,
	A2D_VDDAO_VR85DRDY,
	A2D_VDDRR0_POC_IO_R0,
	A2D_VDDRR1_POC_IO_R1,
	ANA_IN0P1U,
	D2A_VDD85D_IBIASENA,
	D2A_VDD85D_VD09ENA,
	D2A_VDD85D_VD09TH,
	D2A_VDD85D_VD09TL,
	D2A_VDD85D_VD09_CFG,
	D2A_VDD85D_VD25ENA,
	D2A_VDD85D_VD25TH,
	D2A_VDD85D_VD25TL,
	D2A_VDD85D_VD33ENA,
	D2A_VDD85D_VD33TH,
	D2A_VDD85D_VD33TL,
	D2A_VDDAO_IOUTENA,
	D2A_VDDAO_PMU_TEST_EN,
	D2A_VDDAO_PMU_TEST_SEL,
	D2A_VDDAO_POCENA,
	D2A_VDDAO_TRM_CTAT,
	D2A_VDDAO_TRM_CUR,
	D2A_VDDAO_TRM_DP60_VDD25,
	D2A_VDDAO_TRM_DP60_VDD85A,
	D2A_VDDAO_TRM_DP60_VDD85D,
	D2A_VDDAO_TRM_LATCH_b,
	D2A_VDDAO_TRM_PTAT,
	D2A_VDDAO_VDDAO_CURRENT_CFG,
	D2A_VDDAO_VDDAO_VOLTAGE_CFG,
	D2A_VDDAO_VR25ENA,
	D2A_VDDAO_VR85A95ENA,
	D2A_VDDAO_VR85AENA,
	D2A_VDDAO_VR85D95ENA,
	D2A_VDDAO_VR85DENA,
	PMU_ANA_TEST,
	VDD25,
	VDD33,
	VDD85A,
	VDD85D,
	VDDAO,
	VDDRR0,
	VDDRR1,
	VSS
);
output wire A2D_VDD85D_VD09H ;
output wire A2D_VDD85D_VD09L ;
output wire A2D_VDD85D_VD25H ;
output wire A2D_VDD85D_VD25L ;
output wire A2D_VDD85D_VD33H ;
output wire A2D_VDD85D_VD33L ;
output wire A2D_VDDAO_BGRDY ;
output wire A2D_VDDAO_POR ;
output wire A2D_VDDAO_VR25RDY ;
output wire A2D_VDDAO_VR85ARDY ;
output wire A2D_VDDAO_VR85DRDY ;
output wire A2D_VDDRR0_POC_IO_R0 ;
output wire A2D_VDDRR1_POC_IO_R1 ;
output wire ANA_IN0P1U ;

input wire D2A_VDD85D_IBIASENA ;
input wire D2A_VDD85D_VD09ENA ;
input wire D2A_VDD85D_VD09TH ;
input wire D2A_VDD85D_VD09TL ;
input wire [1:0] D2A_VDD85D_VD09_CFG ;
input wire D2A_VDD85D_VD25ENA ;
input wire D2A_VDD85D_VD25TH ;
input wire D2A_VDD85D_VD25TL ;
input wire D2A_VDD85D_VD33ENA ;
input wire D2A_VDD85D_VD33TH ;
input wire D2A_VDD85D_VD33TL ;
input wire D2A_VDDAO_IOUTENA ;
input wire [2:0] D2A_VDDAO_PMU_TEST_EN ;
input wire [2:0] D2A_VDDAO_PMU_TEST_SEL ;
input wire D2A_VDDAO_POCENA ;
input wire [4:0] D2A_VDDAO_TRM_CTAT ;
input wire [5:0] D2A_VDDAO_TRM_CUR ;
input wire [4:0] D2A_VDDAO_TRM_DP60_VDD25 ;
input wire [4:0] D2A_VDDAO_TRM_DP60_VDD85A ;
input wire [4:0] D2A_VDDAO_TRM_DP60_VDD85D ;
input wire D2A_VDDAO_TRM_LATCH_b ;
input wire [4:0] D2A_VDDAO_TRM_PTAT ;
input wire D2A_VDDAO_VDDAO_CURRENT_CFG ;
input wire [2:0] D2A_VDDAO_VDDAO_VOLTAGE_CFG ;
input wire D2A_VDDAO_VR25ENA ;
input wire D2A_VDDAO_VR85A95ENA ;
input wire D2A_VDDAO_VR85AENA ;
input wire D2A_VDDAO_VR85D95ENA ;
input wire D2A_VDDAO_VR85DENA ;

inout wire PMU_ANA_TEST ;
inout wire VDD25 ;
inout wire VDD33 ;
inout wire VDD85A ;
inout wire VDD85D ;
inout wire VDDAO ;
inout wire VDDRR0 ;
inout wire VDDRR1 ;
inout wire VSS ;

`ifdef FPGA

assign A2D_VDDAO_BGRDY =      '1;
assign A2D_VDDAO_VR25RDY =    '1;
assign A2D_VDDAO_VR85ARDY =   '1;
assign A2D_VDDAO_VR85DRDY =   '1;
assign A2D_VDDAO_POR =        '0;
assign A2D_VDD85D_VD09L =     '1;
assign A2D_VDD85D_VD09H =     '1;
assign A2D_VDD85D_VD25L =     '1;
assign A2D_VDD85D_VD25H =     '1;
assign A2D_VDD85D_VD33L =     '1;
assign A2D_VDD85D_VD33H =     '1;
assign VDD33  =    '1;
assign VSS    =    '0;
assign VDD25  =    '1;
assign VDD85A =    '1;
assign VDD85D =    '1;
assign VDDAO  =    '1;
assign A2D_VDDRR0_POC_IO_R0=1 ;
assign A2D_VDDRR1_POC_IO_R1=1 ;

`endif


`ifdef SIM

    logic reg_BGRDY = '0;     assign A2D_VDDAO_BGRDY = reg_BGRDY;
    logic reg_VR25RDY = '0;   assign A2D_VDDAO_VR25RDY = reg_VR25RDY;
    logic reg_VR85ARDY = '0;  assign A2D_VDDAO_VR85ARDY = reg_VR85ARDY;
    logic reg_VR85DRDY = '0;  assign A2D_VDDAO_VR85DRDY = reg_VR85DRDY;
    logic reg_POR = '0;       assign A2D_VDDAO_POR = reg_POR;
    logic reg_POC_IO = '0;    assign A2D_VDDRR0_POC_IO_R0 = reg_POC_IO;
    						  assign A2D_VDDRR1_POC_IO_R1 = reg_POC_IO;
    logic reg_VD09L = '0;     assign A2D_VDD85D_VD09L = reg_VD09L;
    logic reg_VD09H = '0;     assign A2D_VDD85D_VD09H = reg_VD09H;
    logic reg_VD25L = '0;     assign A2D_VDD85D_VD25L = reg_VD25L;
    logic reg_VD25H = '0;     assign A2D_VDD85D_VD25H = reg_VD25H;
    logic reg_VD33L = '0;     assign A2D_VDD85D_VD33L = reg_VD33L;
    logic reg_VD33H = '0;     assign A2D_VDD85D_VD33H = reg_VD33H;

// power
    logic pwr_VDD    = '0;    assign VDD33  = pwr_VDD    ;
    logic pwr_VSS    = '0;    assign VSS    = pwr_VSS    ;
    logic pwr_VDD25  = '0;    assign VDD25  = pwr_VDD25  ;
    logic pwr_VDD85A = '0;    assign VDD85A = pwr_VDD85A ;
    logic pwr_VDD85D = '0;    assign VDD85D = pwr_VDD85D ;
    logic pwr_VDDAO  = '0;    assign VDDAO  = pwr_VDDAO  ;


    initial  begin
#1;
        reg_BGRDY = '0;
        reg_VR25RDY = '0;
        reg_VR85ARDY = '0;
        reg_VR85DRDY = '0;
        reg_POR = '0;
        reg_POC_IO = '0;

        reg_VD09L = '0;
        reg_VD09H = '0;
        reg_VD25L = '0;
        reg_VD25H = '0;
        reg_VD33L = '0;
        reg_VD33H = '0;
// p
        pwr_VDD    = '0;
        pwr_VSS    = '0;
        pwr_VDD25  = '0;
        pwr_VDD85A = '0;
        pwr_VDD85D = '0;
        pwr_VDDAO  = '0;
        pwr_VDD = '0;

#1;
        reg_BGRDY = '1;
        reg_VR25RDY = '1;
        reg_VR85ARDY = '1;
        reg_VR85DRDY = '1;
        reg_POR = '1;
        reg_POC_IO = '1;
        reg_VD09L = '1;
        reg_VD09H = '1;
        reg_VD25L = '1;
        reg_VD25H = '1;
        reg_VD33L = '1;
        reg_VD33H = '1;
        pwr_VDD    = '1;
        pwr_VSS    = '1;
        pwr_VDD25  = '1;
        pwr_VDD85A = '1;
        pwr_VDD85D = '1;
        pwr_VDDAO  = '1;
        pwr_VDD = '1;

#1;
        reg_BGRDY = '0;
        reg_VR25RDY = '0;
        reg_VR85ARDY = '0;
        reg_VR85DRDY = '0;
        reg_POR = '0;
        reg_POC_IO = '0;

        reg_VD09L = '0;
        reg_VD09H = '0;
        reg_VD25L = '0;
        reg_VD25H = '0;
        reg_VD33L = '0;
        reg_VD33H = '0;
// p
        pwr_VDD    = '0;
        pwr_VSS    = '0;
        pwr_VDD25  = '0;
        pwr_VDD85A = '0;
        pwr_VDD85D = '0;
        pwr_VDDAO  = '0;
        pwr_VDD = '0;


    #1  pwr_VDD = 1;
    end

    always@(posedge pwr_VDD)   #( 100 `US ) pwr_VDDAO = 1;
    always@(posedge pwr_VDD or posedge D2A_VDDAO_VR25ENA  )   #( 300 `US ) pwr_VDD25 =  pwr_VDD & D2A_VDDAO_VR25ENA ;
    always@(posedge pwr_VDD or posedge D2A_VDDAO_VR85AENA )   #( 200 `US ) pwr_VDD85A = pwr_VDD & D2A_VDDAO_VR85AENA;
    always@(posedge pwr_VDD or posedge D2A_VDDAO_VR85DENA )   #( 200 `US ) pwr_VDD85D = pwr_VDD & D2A_VDDAO_VR85DENA;

    always@( * ) if(~ pwr_VDD)  #( 300 `US ) pwr_VDDAO = '0;
    always@( * ) if(~ pwr_VDD | ~ D2A_VDDAO_VR25ENA  )  #( 100 `US ) pwr_VDD25 =  '0;
    always@( * ) if(~ pwr_VDD | ~ D2A_VDDAO_VR85AENA )  #( 100 `US ) pwr_VDD85A = '0;
    always@( * ) if(~ pwr_VDD | ~ D2A_VDDAO_VR85DENA )  #( 100 `US ) pwr_VDD85D = '0;

    always@(*)
        if(pwr_VDDAO) begin
            reg_POR = '1;
            #( 150 `US );
            reg_POR = '0;
        end else if(~pwr_VDD) begin
            reg_POR =  1;
            @(negedge pwr_VDDAO);
            reg_POR = '0;
        end

        logic pwr_VDD85A_delay20;
    assign #(20 `US) pwr_VDD85A_delay20 =  pwr_VDD85A;
    always@(*) reg_POC_IO = pwr_VDD & ~( pwr_VDD85A_delay20 & pwr_VDD85A );

    always@(posedge pwr_VDD)    #( 700 `US ) reg_BGRDY = '1;
    always@(posedge pwr_VDD25)   #( 400 `US ) reg_VR25RDY = '1;
    always@(posedge pwr_VDD85A)  #( 200 `US ) reg_VR85ARDY = '1;
    always@(posedge pwr_VDD85D)  #( 200 `US ) reg_VR85DRDY = '1;

    always@( * ) if(~ pwr_VDD)    reg_BGRDY = '0;
    always@( * ) if(~ pwr_VDD25)   reg_VR25RDY = '0;
    always@( * ) if(~ pwr_VDD85A)  reg_VR85ARDY = '0;
    always@( * ) if(~ pwr_VDD85D)  reg_VR85DRDY = '0;

    always@(*)begin
        reg_VD09L = VDD25 & VDD85A & ( ~D2A_VDD85D_VD09ENA ? '1 : D2A_VDD85D_VD09TL ? '1 : VDD85D );
        reg_VD09H = VDD25 & VDD85A & ( ~D2A_VDD85D_VD09ENA ? '1 : D2A_VDD85D_VD09TH ? '1 : VDD85D );
        reg_VD25L = VDD25 & VDD85A & ( ~D2A_VDD85D_VD25ENA ? '1 : D2A_VDD85D_VD25TL ? '1 : VDD25 );
        reg_VD25H = VDD25 & VDD85A & ( ~D2A_VDD85D_VD25ENA ? '1 : D2A_VDD85D_VD25TH ? '1 : VDD25 );
        reg_VD33L = VDD25 & VDD85A & ( ~D2A_VDD85D_VD33ENA ? '1 : D2A_VDD85D_VD33TL ? '1 : VDD33 );
        reg_VD33H = VDD25 & VDD85A & ( ~D2A_VDD85D_VD33ENA ? '1 : D2A_VDD85D_VD33TH ? '1 : VDD33 );
    end

/*
    logic VDD25_vrdrv, VDD85A_vrdrv, VDD85D_vrdrv, VDDAO_vrdrv;

    assign VSS    = '0;
    assign VDD25  = VDD25_vrdrv;
    assign VDD85A = VDD85A_vrdrv;
    assign VDD85D = VDD85D_vrdrv;
    assign VDDAO  = VDDAO_vrdrv;

always@(*)begin

if( VDD ) begin
    #( 100 `US );
        VDDAO_vrdrv = '1;
        VDD08A_vrdrv = '1;
        VDDAO_vrdrv = '1;
    end
end

end


bit BGRDY_reg = 0;       assign BGRDY = BGRDY_reg;
bit VR25RDY_reg = 0;     assign VR25RDY = VR25RDY_reg;
bit VR85ARDY_reg = 0;    assign VR85ARDY = VR85ARDY_reg;
bit VR85DRDY_reg = 0;    assign VR85DRDY = VR85DRDY_reg;
bit POR_reg = 0;         assign POR = POR_reg;
bit VD09L_reg = 0;       assign VD09L = VD09L_reg;
bit VD09H_reg = 0;       assign VD09H = VD09H_reg;
bit VD25L_reg = 0;       assign VD25L = VD25L_reg;
bit VD25H_reg = 0;       assign VD25H = VD25H_reg;
bit VD33L_reg = 0;       assign VD33L = VD33L_reg;
bit VD33H_reg = 0;       assign VD33H = VD33H_reg;


    output  wire  BGRDY               ,
    output  wire  VR25RDY             ,
    output  wire  VR85ARDY            ,
    output  wire  VR85DRDY            ,
    output  wire  POR                 ,
    output  wire  POC_IO              ,
    output  wire  VD09L               ,
    output  wire  VD09H               ,
    output  wire  VD25L               ,
    output  wire  VD25H               ,
    output  wire  VD33L               ,
    output  wire  VD33H               ,

*/
`endif

endmodule ;
