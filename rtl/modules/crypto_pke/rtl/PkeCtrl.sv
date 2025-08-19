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

module PkeCtrl(
            Clk              ,
            Resetn           ,
            PkeStart         ,
            PkeIR            ,
            PkeNLen          ,
            PkeELen          ,
            PkeDone          ,
            ModInvRdy        ,
            LongAlgStart     ,
            LongAlgOp        ,
            LongAlgDone      ,
            LongAlgSR        ,
            MpcStart         ,
            MpcDone          ,
	        Src0Adr	         ,
            Src1Adr	         ,
            PointEn          ,
            DstAdr	         ,

            mmsel            ,
            mimm_opt         ,
            ModExpRamRd      ,
            ModExpRamAdr     ,
            RamModExpDat

            );

input           Clk              ;
input           Resetn           ;
input           PkeStart         ;
input    [7:0]  PkeIR            ;
input    [13:0] PkeNLen          ;
input    [13:0] PkeELen          ;
output          PkeDone		 ;
output          ModInvRdy        ;
output          LongAlgStart     ;
output   [5:0]  LongAlgOp        ;
input           LongAlgDone      ;
input    [2:0]  LongAlgSR        ;
output          MpcStart         ;
input           MpcDone          ;
output   [8:0]  Src0Adr          ;
output   [8:0]  Src1Adr          ;
output   [8:0]  DstAdr           ;
output          PointEn          ;

input wire       mmsel;
input wire [7:0] mimm_opt        ;     
output          ModExpRamRd 	 ;
output   [8 :0] ModExpRamAdr	 ;
input    [63:0] RamModExpDat     ;
// 0 signals defined
// 0.1 port signals
wire            Clk              ;
wire            Resetn           ;
wire            PkeStart         ;
wire     [7:0]  PkeIR            ;
wire     [13:0] PkeNLen          ;
wire     [13:0] PkeELen          ;
wire            PkeDone		 ;
reg             ModInvRdy        ;
wire            NextModInvRdy    ;
wire            LongAlgStart     ;
wire     [5:0]  LongAlgOp        ;
wire            LongAlgDone      ;
wire     [2:0]  LongAlgSR        ;
wire            MpcStart         ;
wire            MpcDone          ;
wire            MpcAEn           ;
wire     [8:0]  Src0Adr          ;
wire     [8:0]  Src1Adr          ;
wire     [8:0]  DstAdr           ;
wire            PointEn          ;
wire            PointEn_I2M      ;
wire            PointEn_PA       ;
wire            PointEn_PD       ;
wire            PointEn_M2I      ;

wire            StartHCal        ;

wire     [63:0] RamModExpDat     ;

// 0.2 paramters
parameter PKE_IDLE		=5'b00000;
parameter PKE_START		=5'b00001;
parameter PKE_RSAEXP		=5'b00010;
parameter PKE_RSAMODMUL		=5'b00011;
parameter PKE_RSAHCAL		=5'b00100;
parameter PKE_ECCHCAL		=5'b00101;
parameter PKE_ECCI2M		=5'b00110;
parameter PKE_ECCM2I		=5'b00111;
parameter PKE_ECCMODINV		=5'b01001;
parameter PKE_ECCMODMUL		=5'b01010;
parameter PKE_ECCPOINTADD	=5'b01011;
parameter PKE_ECCPOINTDBL	=5'b01100;
parameter PKE_END		=5'b01101;
parameter PKE_ECCMODADD		=5'b01110;
parameter PKE_ECCMODSUB		=5'b01111;
parameter PKE_EDI2M		=5'b10000;
parameter PKE_EDM2I		=5'b10001;
parameter PKE_EDPOINTADD	=5'b10010;
parameter PKE_EDPOINTDBL	=5'b10011;
parameter PKE_ECCPOINTMUL	=5'b10100;
parameter PKE_X25519	        =5'b10101;
parameter PKE_GCD 	        =5'b10110;
parameter PKE_RSAMODADD		=5'b10111; //zxjian,20230808
parameter PKE_RSAMODSUB		=5'b11000; //zxjian,20230808

parameter MODEXP_IDLE		=4'b0001;
parameter MODEXP_MM1H		=4'b0010;
parameter MODEXP_MMAH		=4'b0011;
parameter MODEXP_ERD		=4'b0100;
parameter MODEXP_ELD		=4'b0101;
parameter MODEXP_JUDGE1		=4'b0110;
parameter MODEXP_MMR0R1		=4'b0111;
parameter MODEXP_MMR1R0		=4'b1000;
parameter MODEXP_MMR0R0		=4'b1001;
parameter MODEXP_MMR1R1		=4'b1010;
parameter MODEXP_JUDGE2		=4'b1011;
parameter MODEXP_JUDGE3		=4'b1100;
parameter MODEXP_SET1		=4'b1101;
parameter MODEXP_MM1		=4'b1110;
parameter MODEXP_END		=4'b1111;

parameter MODMUL_IDLE		=2'b00;
parameter MODMUL_MMAH		=2'b01;
parameter MODMUL_MMAB		=2'b10;
parameter MODMUL_END		=2'b11;
parameter HCAL_IDLE		=3'b000;
parameter HCAL_SUB		=3'b001;
parameter HCAL_SHIFTD		=3'b010;
parameter HCAL_SHIFTT		=3'b011;
parameter HCAL_JUDGE   		=3'b100;
parameter HCAL_MOV		=3'b101;
parameter HCAL_MOV1		=3'b110;
parameter HCAL_END		=3'b111;
parameter ECCI2M_IDLE		=4'b0000;
parameter ECCI2M_MOVH		=4'b1001;
parameter ECCI2M_MMQ0XH		=4'b0001;
parameter ECCI2M_MMQ0YH		=4'b0010;
parameter ECCI2M_MMQ0ZH		=4'b0011;
parameter ECCI2M_MMQ1XH		=4'b0100;
parameter ECCI2M_MMQ1YH		=4'b0101;
parameter ECCI2M_MMQ1ZH		=4'b0110;
parameter ECCI2M_MMAH		=4'b0111;
parameter ECCI2M_END		=4'b1000;
parameter ECCM2I_IDLE		=4'b0000;
parameter ECCM2I_MMZ1		=4'b0001;
parameter ECCM2I_MODINVZ	=4'b0010;
parameter ECCM2I_MMZH		=4'b0011;
parameter ECCM2I_MMZ2		=4'b0100;
parameter ECCM2I_MMXZ2		=4'b0101;
parameter ECCM2I_MMZ3		=4'b0110;
parameter ECCM2I_MMYZ3		=4'b0111;
parameter ECCM2I_MMX1		=4'b1000;
parameter ECCM2I_MMY1		=4'b1001;
parameter ECCM2I_END		=4'b1010;
parameter ECCM2I_MOVZ2UT	=4'b1011;
parameter ECCM2I_MOVUT2U	=4'b1100;
parameter ECCM2I_MOVZ2TP1	=4'b1101;
parameter ECCM2I_MOVZ2TP0	=4'b1110;
parameter ECCM2I_MOVY2TP0	=4'b1111;
parameter MI_IDLE		=5'b00000;
parameter MI_INIT0		=5'b00001;
parameter MI_INIT1		=5'b00010;
parameter MI_INIT2		=5'b00011;
parameter MI_INIT3		=5'b00100;
parameter MI_INIT4		=5'b00101;
parameter MI_INIT5		=5'b00110;
parameter MI_JUDGE1		=5'b00111;
parameter MI_X3DIV2		=5'b01000;
parameter MI_JUDGE2		=5'b01001;
parameter MI_X1ADDU		=5'b01010;
parameter MI_X2SUBV		=5'b01011;
parameter MI_X1DIV2		=5'b01100;
parameter MI_X2DIV2		=5'b01101;
parameter MI_Y3DIV2		=5'b01110;
parameter MI_JUDGE3		=5'b01111;
parameter MI_Y1ADDU		=5'b10000;
parameter MI_Y2SUBV		=5'b10001;
parameter MI_Y1DIV2		=5'b10010;
parameter MI_Y2DIV2		=5'b10011;
parameter MI_X3CMPY3		=5'b10100;
parameter MI_Y1SUBX1		=5'b10101;
parameter MI_Y2SUBX2		=5'b10110;
parameter MI_Y3SUBX3		=5'b10111;
parameter MI_X1SUBY1		=5'b11000;
parameter MI_X2SUBY2		=5'b11001;
parameter MI_X3SUBY3		=5'b11010;
parameter MI_Y3SUB1		=5'b11011;
parameter MI_JUDGE4		=5'b11100;
parameter MI_Y2ADDP		=5'b11101;
parameter MI_Y2SUBP		=5'b11110;
parameter MI_END		=5'b11111;
parameter PA_IDLE		=6'b000000;
parameter PA_S1			=6'b000001;
parameter PA_S2			=6'b000010;
parameter PA_S3			=6'b000011;
parameter PA_S4			=6'b000100;
parameter PA_S5			=6'b000101;
parameter PA_S6			=6'b000110;
parameter PA_S7			=6'b000111;
parameter PA_S8			=6'b001000;
parameter PA_S9			=6'b001001;
parameter PA_S10		=6'b001010;
parameter PA_S11		=6'b001011;
parameter PA_S12		=6'b001100;
parameter PA_S13		=6'b001101;
parameter PA_S14		=6'b001110;
parameter PA_S15		=6'b001111;
parameter PA_S16		=6'b010000;
parameter PA_S17		=6'b010001;
parameter PA_S18		=6'b010010;
parameter PA_S19		=6'b010011;
parameter PA_S20		=6'b010100;
parameter PA_S21		=6'b010101;
parameter PA_S22		=6'b010110;
parameter PA_S23		=6'b010111;
parameter PA_S24		=6'b011000;
parameter PA_S25		=6'b011001;
parameter PA_S26		=6'b011010;
parameter PA_S27		=6'b011011;
parameter PA_S28		=6'b011100;
parameter PA_S29		=6'b011101;
parameter PA_S30		=6'b011110;
parameter PA_S31		=6'b011111;
parameter PA_S32		=6'b100000;
parameter PA_S33		=6'b100001;
parameter PA_S34		=6'b100010;
parameter PA_END		=6'b100011;
parameter PD_IDLE		=6'b000000;
parameter PD_S1			=6'b000001;
parameter PD_S2			=6'b000010;
parameter PD_S3			=6'b000011;
parameter PD_S4			=6'b000100;
parameter PD_S5			=6'b000101;
parameter PD_S6			=6'b000110;
parameter PD_S7			=6'b000111;
parameter PD_S8			=6'b001000;
parameter PD_S9			=6'b001001;
parameter PD_S10		=6'b001010;
parameter PD_S11		=6'b001011;
parameter PD_S12		=6'b001100;
parameter PD_S13		=6'b001101;
parameter PD_S14		=6'b001110;
parameter PD_S15		=6'b001111;
parameter PD_S16		=6'b010000;
parameter PD_S17		=6'b010001;
parameter PD_S18		=6'b010010;
parameter PD_S19		=6'b010011;
parameter PD_S20		=6'b010100;
parameter PD_S21		=6'b010101;
parameter PD_S22		=6'b010110;
parameter PD_S23		=6'b010111;
parameter PD_S24		=6'b011000;
parameter PD_S25		=6'b011001;
parameter PD_S26		=6'b011010;
parameter PD_S27		=6'b011011;
parameter PD_S28		=6'b011100;
parameter PD_S29		=6'b011101;
parameter PD_S30		=6'b011110;
parameter PD_S31		=6'b011111;
parameter PD_S32		=6'b100000;
parameter PD_S33		=6'b100001;
parameter PD_S34		=6'b100010;
parameter PD_S35		=6'b100011;
parameter PD_S36		=6'b100100;
parameter PD_S37		=6'b100101;
parameter PD_S38		=6'b100110;
parameter PD_END		=6'b100111;
parameter MA_IDLE		=3'b000;
parameter MA_ADD		=3'b001;
parameter MA_SUB		=3'b010;
parameter MA_ADD1		=3'b011;
parameter MA_END		=3'b100;
parameter MS_IDLE		=2'b00;
parameter MS_SUB		=2'b01;
parameter MS_ADD		=2'b10;
parameter MS_END		=2'b11;
parameter UNIT_AB_ADD_A         = 6'b000000;
parameter UNIT_AB_ADD_B         = 6'b011000;
parameter UNIT_AB_SUB_A         = 6'b000001;
parameter UNIT_BA_SUB_B         = 6'b011001;
parameter UNIT_A_LFT_A          = 6'b000010;
parameter UNIT_B_LFT_B          = 6'b011010;
parameter UNIT_A_RHT_A          = 6'b000011;
parameter UNIT_A_SRHT_A         = 6'b100011;
parameter UNIT_B_RHT_B          = 6'b011011;
parameter UNIT_B_SRHT_B         = 6'b111011;
parameter UNIT_A_MOV_B          = 6'b010100;
parameter UNIT_B_MOV_A          = 6'b001100;
parameter UNIT_AB_CMP           = 6'b000101;
parameter UNIT_A_SET0           = 6'b000110;
//parameter UNIT_B_SET0           = 6'b011110;
parameter UNIT_A_SET1           = 6'b000111;
parameter UNIT_B_SET1           = 6'b010111;
//parameter UNIT_AA_SUB_B         = 6'b001001;
parameter UNIT_BA_SUB_A         = 6'b001001;
parameter UNIT_BB_ADD_A         = 6'b010000;

parameter HCAL_T0		= 9'h000;  //20230318    // 8192 rsa
parameter HCAL_T1		= 9'h000;  //20230318    // 8192 rsa
//zxjian,20221116
parameter HCAL_N		= 9'h100; //20230318    // 8192 rsa
parameter HCAL_D		= 9'h100; //20230318    // 8192 rsa
//zxjian,20221118
//20230318
parameter ME_R0                 = 9'h000;          // 8192 rsa
parameter ME_R0T                = 9'h000;          // 8192 rsa
parameter ME_R1                 = 9'h080;          // 8192 rsa
parameter ME_R1T                = 9'h080;          // 8192 rsa
parameter ME_N                  = 9'h100;          // 8192 rsa
parameter ME_H                  = 9'h100;          // 8192 rsa
parameter ME_E                  = 9'h180;          // 8192 rsa
parameter ME_M                  = 9'h180;          // 8192 rsa
parameter MM_X                  = 9'h000;          // 8192 rsa
parameter MM_Y                  = 9'h000;          // 8192 rsa
parameter MM_H                  = 9'h100;          // 8192 rsa

//zxjian,20221116
//parameter MM_H                  = 9'h140;
parameter MM_H1                 = 8'h1B;

parameter MI_X1                 = 8'hAB;
parameter MI_X2                 = 8'hB4;
parameter MI_X3                 = 8'hBD;
parameter MI_Y1                 = 8'hAB;
parameter MI_Y2                 = 8'hB4;
parameter MI_Y3                 = 8'hBD;
parameter MI_C1                 = 8'h36;
parameter MI_U                  = 8'hC6;
parameter MI_UT                 = 8'hC6;
parameter MI_V                  = 8'h24;
parameter MI_VT                 = 8'h24;
parameter MI_T0                 = 8'hD8;
parameter MI_T1                 = 8'hCF;

parameter Q0X_ADR		= 8'h00;
parameter Q0Y_ADR		= 8'h00;
parameter Q0Z_ADR		= 8'h12;
parameter Q1X_ADR		= 8'h09;
parameter Q1Y_ADR		= 8'h09;
parameter Q1Z_ADR		= 8'h12;
parameter A_ADR                 = 8'h1B;
parameter P_ADR                 = 8'h24;
parameter K_ADR                 = 8'h2D;
parameter M_ADR                 = 8'h24;
parameter H_ADR                 = 8'h1B;
parameter C1_ADR                = 8'h36;
parameter TP0_ADR               = 8'hD8;
parameter TP1_ADR               = 8'hD8;
parameter Z1_ADR                = 8'h36;
parameter Z2_ADR                = 8'h3F;
parameter Z3_ADR                = 8'h3F;
parameter T1_ADR_PA		= 8'h48;
parameter T2_ADR_PA		= 8'h48;
parameter T3_ADR_PA		= 8'h51;
parameter T4_ADR_PA		= 8'h5A;
parameter T5_ADR_PA		= 8'h51;
parameter T6_ADR_PA		= 8'h5A;
parameter T7_ADR_PA		= 8'h63;
parameter T8_ADR_PA		= 8'h6C;
parameter T9_ADR_PA		= 8'h63;
parameter T10_ADR_PA		= 8'h6C;
parameter T11_ADR_PA		= 8'h75;
parameter T12_ADR_PA		= 8'h7E;
parameter T13_ADR_PA		= 8'h87;
parameter T14_ADR_PA		= 8'h75;
parameter T15_ADR_PA		= 8'h7E;
parameter T16_ADR_PA		= 8'h00;
parameter T17_ADR_PA		= 8'h90;
parameter T18_ADR_PA		= 8'h99;
parameter T19_ADR_PA		= 8'hA2;
parameter T20_ADR_PA		= 8'h87;
parameter T21_ADR_PA		= 8'h90;
parameter T22_ADR_PA		= 8'h99;
parameter T23_ADR_PA		= 8'h00;
parameter T24_ADR_PA		= 8'hA2;
parameter T25_ADR_PA		= 8'h12;
parameter T1_ADR_PD		= 8'h48;
parameter T2_ADR_PD		= 8'h48;
parameter T3_ADR_PD		= 8'h51;
parameter T4_ADR_PD		= 8'h5A;
parameter T5_ADR_PD		= 8'h51;
parameter T6_ADR_PD		= 8'h5A;
parameter T7_ADR_PD		= 8'h63;
parameter T8_ADR_PD		= 8'h63;
parameter T9_ADR_PD		= 8'h6C;
parameter T10_ADR_PD		= 8'h6C;
parameter T11_ADR_PD		= 8'h75;
parameter T12_ADR_PD		= 8'h75;
parameter T13_ADR_PD		= 8'h7E;
parameter T14_ADR_PD		= 8'h87;
parameter T15_ADR_PD		= 8'h7E;
parameter T16_ADR_PD		= 8'h90;
parameter T17_ADR_PD		= 8'h87;
parameter T18_ADR_PD		= 8'h90;
parameter T19_ADR_PD		= 8'h99;
parameter T20_ADR_PD		= 8'h99;
parameter T21_ADR_PD		= 8'h00;
parameter T22_ADR_PD		= 8'hA2;
parameter T23_ADR_PD		= 8'h12;
parameter T24_ADR_PD		= 8'h00;

parameter P0X_ADR		= 8'hCF;
parameter P0Y_ADR		= 8'hCF;
parameter P0Z_ADR		= 8'hEA;
parameter P0T_ADR		= 8'hEA;
parameter P1X_ADR		= 8'hE1;
parameter P1Y_ADR		= 8'hE1;
parameter P1Z_ADR		= 8'hF3;
parameter P1T_ADR		= 8'hF3;
parameter Q1T_ADR		= 8'h48;
parameter Q0T_ADR		= 8'h48;

parameter EDI2M_IDLE		=5'h00 ;
parameter EDI2M_MOVH		=5'h01 ;
parameter EDI2M_MMQ0XH		=5'h02 ;
parameter EDI2M_MMQ0YH		=5'h03 ;
parameter EDI2M_MMQ0ZH		=5'h04 ;
parameter EDI2M_MOVZ		=5'h05 ;
parameter EDI2M_MMQ0XZ		=5'h06 ;
parameter EDI2M_MMQ0XY		=5'h07 ;
parameter EDI2M_MMQ0YZ		=5'h08 ;
parameter EDI2M_MMQ1XH		=5'h09 ;
parameter EDI2M_MMQ1YH		=5'h0a ;
parameter EDI2M_MMQ1ZH		=5'h0b ;
parameter EDI2M_MOVZ1		=5'h0c ;
parameter EDI2M_MMQ1XZ		=5'h0d ;
parameter EDI2M_MMQ1XY		=5'h0e ;
parameter EDI2M_MMQ1YZ		=5'h0f ;
parameter EDI2M_MMAH		=5'h10 ;
parameter EDI2M_END		=5'h11 ;

parameter EDM2I_IDLE		=5'h00 ;
parameter EDM2I_MMZ1		=5'h01 ;
parameter EDM2I_MOVZ2UT		=5'h02 ;
parameter EDM2I_MOVUT2U		=5'h03 ;
parameter EDM2I_MODINVZ		=5'h04 ;
parameter EDM2I_MOVZ2TP0	=5'h05 ;
parameter EDM2I_MMZH		=5'h06 ;
parameter EDM2I_MOVZ2TP1	=5'h07 ;
parameter EDM2I_MMXZ		=5'h08 ;
parameter EDM2I_MMYZ		=5'h09 ;
parameter EDM2I_MMX1		=5'h0a ;
parameter EDM2I_MOVY2TP0	=5'h0b ;
parameter EDM2I_MMY1		=5'h0c ;
parameter EDM2I_END		=5'h0d ;

parameter EDPA_IDLE		=5'h00 ;
parameter EDPA_S1		=5'h01 ;
parameter EDPA_S2		=5'h02 ;
parameter EDPA_S3		=5'h03 ;
parameter EDPA_S4		=5'h04 ;
parameter EDPA_S5		=5'h05 ;
parameter EDPA_S6		=5'h06 ;
parameter EDPA_S7		=5'h07 ;
parameter EDPA_S8		=5'h08 ;
parameter EDPA_S9		=5'h09 ;
parameter EDPA_S10		=5'h0a ;
parameter EDPA_S11		=5'h0b ;
parameter EDPA_S12		=5'h0c ;
parameter EDPA_S13		=5'h0d ;
parameter EDPA_S14		=5'h0e ;
parameter EDPA_S15		=5'h0f ;
parameter EDPA_S16		=5'h10 ;
parameter EDPA_S17		=5'h11 ;
parameter EDPA_S18		=5'h12 ;
parameter EDPA_S19		=5'h13 ;
parameter EDPA_S20		=5'h14 ;
parameter EDPA_S21		=5'h15 ;
parameter EDPA_END		=5'h16 ;

parameter EDPD_IDLE		=5'h00 ;
parameter EDPD_S1		=5'h01 ;
parameter EDPD_S2		=5'h02 ;
parameter EDPD_S3		=5'h03 ;
parameter EDPD_S4		=5'h04 ;
parameter EDPD_S5		=5'h05 ;
parameter EDPD_S6		=5'h06 ;
parameter EDPD_S7		=5'h07 ;
parameter EDPD_S8		=5'h08 ;
parameter EDPD_S9		=5'h09 ;
parameter EDPD_S10		=5'h0a ;
parameter EDPD_S11		=5'h0b ;
parameter EDPD_S12		=5'h0c ;
parameter EDPD_S13		=5'h0d ;
parameter EDPD_S14		=5'h0e ;
parameter EDPD_S15		=5'h0f ;
parameter EDPD_S16		=5'h10 ;
parameter EDPD_S17		=5'h11 ;
parameter EDPD_S18		=5'h12 ;
parameter EDPD_S19		=5'h13 ;
parameter EDPD_END		=5'h14 ;

parameter ECCPM_IDLE		=6'd00;
parameter ECCPM_S1		=6'd01;
parameter ECCPM_S2		=6'd02;
parameter ECCPM_S3		=6'd03;
parameter ECCPM_S4		=6'd04;
parameter ECCPM_S5		=6'd05;
parameter ECCPM_S6		=6'd06;
parameter ECCPM_S7		=6'd07;
parameter ECCPM_S8		=6'd08;
parameter ECCPM_S9		=6'd09;
parameter ECCPM_S10		=6'd10;
parameter ECCPM_S11		=6'd11;
parameter ECCPM_S12		=6'd12;
parameter ECCPM_S13		=6'd13;
parameter ECCPM_S14		=6'd14;
parameter ECCPM_S15		=6'd15;
parameter ECCPM_S16		=6'd16;
parameter ECCPM_S17		=6'd17;
parameter ECCPM_S18		=6'd18;
parameter ECCPM_S19		=6'd19;
parameter ECCPM_S20		=6'd20;
parameter ECCPM_S21		=6'd21;
parameter ECCPM_S22		=6'd22;
parameter ECCPM_S23		=6'd23;
parameter ECCPM_S24		=6'd24;
parameter ECCPM_S25		=6'd25;
parameter ECCPM_S26		=6'd26;
parameter ECCPM_S27		=6'd27;
parameter ECCPM_S28		=6'd28;
parameter ECCPM_S29		=6'd29;
parameter ECCPM_S30		=6'd30;
parameter ECCPM_S31		=6'd31;
parameter ECCPM_S32		=6'd32;
parameter ECCPM_S33		=6'd33;
parameter ECCPM_S34		=6'd34;
parameter ECCPM_S35		=6'd35;
parameter ECCPM_S36		=6'd36;
parameter ECCPM_S37		=6'd37;
parameter ECCPM_S38		=6'd38;
parameter ECCPM_S39		=6'd39;
parameter ECCPM_S40		=6'd40;
parameter ECCPM_S41		=6'd41;
parameter ECCPM_S42		=6'd42;
parameter ECCPM_S43		=6'd43;
parameter ECCPM_S44		=6'd44;
parameter ECCPM_S45		=6'd45;
parameter ECCPM_S46		=6'd46;
parameter ECCPM_S47		=6'd47;
parameter ECCPM_S48		=6'd48;
parameter ECCPM_S49		=6'd49;
parameter ECCPM_END		=6'd50;

parameter X25519_IDLE		=6'd00;
parameter X25519_S1		=6'd01;
parameter X25519_S2		=6'd02;
parameter X25519_S3		=6'd03;
parameter X25519_S4		=6'd04;
parameter X25519_S5		=6'd05;
parameter X25519_S6		=6'd06;
parameter X25519_S7		=6'd07;
parameter X25519_S8		=6'd08;
parameter X25519_S9		=6'd09;
parameter X25519_S10		=6'd10;
parameter X25519_S11		=6'd11;
parameter X25519_S12		=6'd12;
parameter X25519_S13		=6'd13;
parameter X25519_S14		=6'd14;
parameter X25519_S15		=6'd15;
parameter X25519_S16		=6'd16;
parameter X25519_S17		=6'd17;
parameter X25519_S18		=6'd18;
parameter X25519_S19		=6'd19;
parameter X25519_S20		=6'd20;
parameter X25519_S21		=6'd21;
parameter X25519_S22		=6'd22;
parameter X25519_S23		=6'd23;
parameter X25519_S24		=6'd24;
parameter X25519_S25		=6'd25;
parameter X25519_S26		=6'd26;
parameter X25519_S27		=6'd27;
parameter X25519_S28		=6'd28;
parameter X25519_S29		=6'd29;
parameter X25519_S30		=6'd30;
parameter X25519_S31		=6'd31;
parameter X25519_S32		=6'd32;
parameter X25519_S33		=6'd33;
parameter X25519_S34		=6'd34;
parameter X25519_S35		=6'd35;
parameter X25519_S36		=6'd36;
parameter X25519_END		=6'd37;

//20221125
parameter GCD_IDLE		=5'd0;
parameter GCD_S1		=5'd1;
parameter GCD_S2		=5'd2;
parameter GCD_S3		=5'd3;
parameter GCD_S4		=5'd4;
parameter GCD_S5		=5'd5;
parameter GCD_S6		=5'd6;
parameter GCD_S7		=5'd7;
parameter GCD_S8		=5'd8;
parameter GCD_S9		=5'd9;
parameter GCD_S10		=5'd10;
parameter GCD_S11		=5'd11;
parameter GCD_S12		=5'd12;
parameter GCD_S13		=5'd13;
parameter GCD_S14		=5'd14;
parameter GCD_END		=5'd15;

parameter GCD_A			=8'h00;
parameter GCD_AT		=8'h41;
parameter GCD_B			=8'h00;
parameter GCD_BT		=8'h41;
parameter GCD_C			=8'h82;
parameter GCD_CT		=8'h82;

//end 20221125

wire         EccHCal           	;
wire         EccModMul         	;
wire         EccModAdd         	;
wire         EccModSub         	;
wire         RsaModAdd         	; //zxjian,20230808
wire         RsaModSub         	; //zxjian,20230808
wire         EccI2MA           	;
wire         EccI2MD           	;
wire         EccPointAdd       	;
wire         EccPointDbl       	;
wire         EccM2I            	;
wire         EccModInv         	;
wire         EccModInv1        	;
wire         RsaModInv         	;
wire         RsaHCal           	;
wire         RsaModMul         	;
wire         RsaExp            	;
wire         RsaM2I            	;
wire         EccI2M            	;
reg   [4 :0] PkeState		;
reg   [4 :0] NextPkeState	;
wire         StartModExp        ;
wire         StartModMul        ;
wire         StartEccI2M        ;
wire         StartEccM2I        ;
wire         StartEccModInv     ;
wire         StartEccPointAdd   ;
wire         StartEccPointDbl   ;
reg   [3 :0] ModExpState	;
reg   [3 :0] NextModExpState	;
wire         ModExpDone 	;
wire         ModExpRamRd 	;
wire  [8 :0] ModExpRamAdr	;
wire  [5 :0] EDatIndex		;
wire         EDatIsZero    	;
wire         NeedRd        	;
wire         EDatEnd       	;
reg   [15:0] ECnt		;
reg   [63:0] EDat		;
wire  [15:0] NextECnt		;
wire  [63:0] NextEDat		;
wire         StartMpc_ME	;
wire  [8 :0] ME_Src0         	;
wire  [8 :0] ME_Src1         	;
wire  [8 :0] ME_Dst          	;
wire         LongAlgStart_ME   	;
wire  [5 :0] LongAlgOp_ME      	;
reg   [1 :0] ModMulState	;
reg   [1 :0] NextModMulState	;
wire         ModMulDone         ;
wire         StartMpc_MM	;
wire  [8 :0]  MM_Src0         	;
wire  [8 :0]  MM_Src1         	;
wire  [8 :0]  MM_Dst          	;
reg   [2 :0] HCalState		;
reg   [2 :0] NextHCalState	;
wire         HCalDone		;
wire  [13:0] HLen               ;
wire         EndHCal		;
wire         HCalStart		;
reg  [13 :0] HCnt		;
wire [13 :0] NextHCnt		;
wire         LongAlgStart_HCal 	;
wire [ 5 :0] LongAlgOp_HCal    	;
wire [ 8 :0] HCal_Src0_RSA     	;
wire [ 8 :0] HCal_Src1_RSA     	;
wire [ 8 :0] HCal_Dst_RSA      	;
wire [ 7 :0] HCal_Src0_ECC     	;
wire [ 7 :0] HCal_Src1_ECC     	;
wire [ 7 :0] HCal_Dst_ECC      	;
reg   [3 :0] EccI2MState	;
reg   [3 :0] NextEccI2MState	;
wire         EccI2MDone		;
wire         StartMpc_I2M	;
wire         LongAlgStart_I2M   ;
wire  [5 :0] LongAlgOp_I2M   	;
reg   [3 :0] EccM2IState	;
reg   [3 :0] NextEccM2IState	;
wire         EccM2IDone		;
wire         StartMpc_M2I	;
wire         LongAlgStart_M2I   ;
wire  [5 :0] LongAlgOp_M2I      ;
wire         StartModInv_M2I	;
wire         EccStartModInv	;
wire         RsaStartModInv	;
wire         StartPointAdd	;
wire         StartPointDbl	;
reg   [4 :0] ModInvState	;
reg   [4 :0] NextModInvState	;
wire          ModInvDone      	;
wire          ResultIsZero    	;
wire          ResultIsNeg     	;
reg           X1IsEvenReg     	;
reg           X2IsEvenReg     	;
reg           X3IsEvenReg     	;
reg           Y1IsEvenReg     	;
reg           Y2IsEvenReg     	;
reg           Y3IsEvenReg     	;
reg           Y2IsNegReg      	;
wire          X1IsEven        	;
wire          X2IsEven        	;
wire          X3IsEven        	;
wire          Y1IsEven        	;
wire          Y2IsEven        	;
wire          Y3IsEven        	;
wire          Y2IsNeg         	;
wire          LongAlgStart_MI 	;
wire  [5 :0]  LongAlgOp_MI    	;
wire  [8 :0]  MI_Src0         	; //zxjian,20230209
wire  [8 :0]  MI_Src1         	;
wire  [8 :0]  MI_Dst          	;
wire  [7 :0]  MI_Src0_Ecc     	;
wire  [7 :0]  MI_Src1_Ecc      	;
wire  [7 :0]  MI_Dst_Ecc      	;
wire  [8 :0]  MI_Src0_Rsa     	; //zxjian,20230209
wire  [8 :0]  MI_Src1_Rsa     	;
wire  [8 :0]  MI_Dst_Rsa      	;
reg   [5 :0] PointAddState	;
reg   [5 :0] NextPointAddState	;
wire         EccPointAddDone	;
wire         StartMpc_PA     	;
wire         StartModAdd_PA  	;
wire         StartModSub_PA  	;
wire  [5 :0] LongAlgOp_PA	;
wire         LongAlgStart_PA	;
reg   [5 :0] PointDblState	;
reg   [5 :0] NextPointDblState	;
wire         EccPointDblDone   	;
wire         StartMpc_PD     	;
wire         StartModAdd_PD  	;
wire         StartModSub_PD  	;
wire  [5 :0] LongAlgOp_PD    	;
wire         LongAlgStart_PD 	;
reg   [2 :0] ModAddState	;
reg   [2 :0] NextModAddState	;
wire         LongAlgStart_MA	;
wire  [5 :0] LongAlgOp_MA    	;
wire         StartModAdd    	;
wire         ModAddDone     	;
reg   [1 :0] ModSubState	;
reg   [1 :0] NextModSubState	;
wire         LongAlgStart_MS 	;
wire  [5 :0] LongAlgOp_MS    	;
wire         StartModSub    	;
wire         ModSubDone     	;
wire  [7 :0] LongAlgSrc0        ;
wire  [7 :0] LongAlgSrc1        ;
wire  [7 :0] LongAlgDst         ;
wire  [7 :0] PA_Src0 		;
wire  [7 :0] PD_Src0 		;
wire  [7 :0] PA_Src1 		;
wire  [7 :0] PD_Src1 		;
wire  [7 :0] PA_Dst  		;
wire  [7 :0] PD_Dst  		;
reg   [15:0] ModInvCnt		;
wire  [15:0] NextModInvCnt	;
wire         ErrorDetect	;

wire         StartModAdd_Ecc  	;
wire         StartModSub_Ecc  	;

wire         EdI2MA         	;
wire         EdI2MD         	;
wire         EdPointAdd     	;
wire         EdPointDbl     	;
wire         EdM2I          	;
wire         EdI2M          	;

wire         StartEdI2M       	;
wire         StartEdM2I       	;
wire         StartEdPointAdd  	;
wire         StartEdPointDbl  	;

reg   [4 :0] EdI2MState		;
reg   [4 :0] NextEdI2MState	;
//EdI2M
wire         EdI2MDone		;
wire         StartMpc_EDI2M     ;
wire         LongAlgStart_EDI2M	;
wire  [5 :0] LongAlgOp_EDI2M	;
wire         PointEn_EDI2M    	;
//EdM2I State Machine
reg [4 :0]   EdM2IState     	;
reg [4 :0]   NextEdM2IState 	;
wire         EdM2IDone		;
wire         StartMpc_EDM2I     ;
wire         LongAlgStart_EDM2I	;
wire         StartModInv_EDM2I 	;
wire  [5 :0]LongAlgOp_EDM2I   	;
wire         PointEn_EDM2I     	;
wire         StartModInv       	;

//EdPointAdd State
reg  [4 :0]  EdPointAddState     ;
reg  [4 :0]  NextEdPointAddState ;
wire         EdPointAddDone   	;
wire         StartMpc_EDPA    	;
wire         StartModAdd_EDPA 	;
wire         StartModSub_EDPA 	;
wire [5  :0] LongAlgOp_EDPA   	;
wire         LongAlgStart_EDPA	;
wire         PointEn_EDPA     	;

//Ed PointDble State
reg  [4 :0]  EdPointDblState     ;
reg  [4 :0]  NextEdPointDblState ;
wire         EdPointDblDone  	;
wire         StartMpc_EDPD    	;
wire         StartModAdd_EDPD 	;
wire         StartModSub_EDPD 	;
wire [5  :0] LongAlgOp_EDPD   	;
wire         LongAlgStart_EDPD	;
wire         PointEn_EDPD     	;

wire [7 :0]  EDPA_Src0 		;
wire [7 :0]  EDPA_Src1 		;
wire [7 :0]  EDPA_Dst  		;
wire [7 :0]  EDPD_Src0 		;
wire [7 :0]  EDPD_Src1 		;
wire [7 :0]  EDPD_Dst  		;

wire         EcPointMul     	;
wire         EdPointMul     	;
wire         X25519         	;
wire         X25519Done        	;
wire         EccPointMul    	;
wire         StartPointMul  	;
wire         StartX25519    	;

reg  [5:0]   PointMulState	;
reg  [5:0]   NextPointMulState  ;

wire         EccPointMulDone    ;
wire         EccPointMulRamRd   ;
wire [7 :0]  EccPointMulRamAdr  ;
wire [5 :0]  KDatIndex		;
wire         KDatIsZero    	;
wire         KNeedRd       	;
wire         KDatEnd       	;

reg  [15 :0] KCnt		;
reg  [63 :0] KDat		;
wire [15 :0] NextKCnt		;
wire [63 :0] NextKDat		;
wire         StartPointAdd_PM  	;
wire         StartEdPointAdd_PM	;
wire         StartPointDbl_PM  	;
wire         StartEdPointDbl_PM ;
wire         PointAddDone 	;
wire         PointDblDone 	;

wire LongAlgStart_PM		;
wire [5  :0] LongAlgOp_PM   	;
wire [7 :0]  PM_Src0 	;
wire [7 :0]  PM_Src1 	;
wire [7 :0]  PM_Dst  	;
wire         PointEn_PM		;

reg  [5:0]   X25519State	;
reg  [5:0]   NextX25519State    ;

wire         X25519RamRd        ;
wire [7:0]   X25519RamAdr       ;
//swap flag
reg          Change		;
wire         NextChange		;
reg          SwapReg		;
wire         NextSwap   	;
wire         UpdateSwap		;
wire         StartMpc_X25519  	;
wire         StartModAdd_X25519;
wire         StartModSub_X25519;
wire         LongAlgStart_X25519;
wire [5  :0] LongAlgOp_X25519	;
wire [7  :0] X25519_Src0	;
wire [7  :0] X25519_Src1	;
wire         PointEn_X25519	;
wire [7  :0] X25519_Dst		;

//20221123
//signal declared
wire         GcdOp              ;
wire         StartGcd 		;
reg  [4  :0] GcdState		;
reg  [4  :0] NextGcdState	;
wire         GcdDone		;
wire         BIsZero           	;
wire         KIsZero           	;
wire         CIsPos            	;
reg          AIsEvenReg       	;
reg          BIsEvenReg       	;
reg          BIsZeroReg        	;
reg          CIsPosReg        	;
reg  [15 :0] GcdDat	     	;

wire [15 :0] NextGcdDat		;
wire         AIsEven        	;
wire         BIsEven        	;
wire         LongAlgStart_GCD 	;
wire [5  :0] LongAlgOp_GCD    	;

wire [7  :0] GCD_Src0         	;
wire [7  :0] GCD_Src1         	;
wire [7  :0] GCD_Dst          	;

reg  [15 :0] GcdCnt		;
wire [15 :0] NextGcdCnt		;
wire         GcdError		;

//end,20221123


//assign PointEn_PD =0;
//assign PointEn_M2I =0;
assign PointEn = PointEn_I2M | PointEn_PA | PointEn_PD | PointEn_M2I |
                 PointEn_EDI2M |PointEn_EDPA | PointEn_EDPD |PointEn_EDM2I |
                 PointEn_PM | PointEn_X25519;

//*********************************************************************************
//*********************************************************************************
// 1 Main Pke Logic
//*********************************************************************************
assign EccHCal        = PkeIR  == 8'h01 | PkeIR == 8'h81;
assign EccModMul      = PkeIR  == 8'h02;
assign EccI2MA        = PkeIR  == 8'h03;
assign EccI2MD        = PkeIR  == 8'h04;
assign EccPointAdd    = PkeIR  == 8'h05;
assign EccPointDbl    = PkeIR  == 8'h06;
assign EccM2I         = PkeIR  == 8'h07;
//zxjian,20230318
assign EccModInv      = PkeIR  == 8'h08;
assign EccModInv1      = PkeIR  == 8'h08 | PkeIR == 8'h07 | PkeIR == 8'h27;
assign EccModAdd      = PkeIR  == 8'h09;
assign EccModSub      = PkeIR  == 8'h0a;
assign RsaHCal        = PkeIR  == 8'h11;
assign RsaModMul      = PkeIR  == 8'h12;
assign RsaExp         = PkeIR  == 8'h13;
assign RsaM2I         = PkeIR  == 8'h14;
assign RsaModInv      = PkeIR  == 8'h18;
assign RsaModAdd      = PkeIR  == 8'h19; //zxjian,20230808
assign RsaModSub      = PkeIR  == 8'h1a; //zxjian,20230808
assign EccI2M         = EccI2MA | EccI2MD;
assign EdI2MA         = PkeIR  == 8'h23;
assign EdI2MD         = PkeIR  == 8'h24;
assign EdPointAdd     = PkeIR  == 8'h25;
assign EdPointDbl     = PkeIR  == 8'h26;
assign EdM2I          = PkeIR  == 8'h27;
assign EdI2M          = EdI2MA | EdI2MD;
assign EcPointMul     = PkeIR  == 8'h0b;
assign EdPointMul     = PkeIR  == 8'h2b;
assign X25519         = PkeIR  == 8'h3b;
assign EccPointMul    = EcPointMul | EdPointMul;

assign GcdOp          = PkeIR  == 8'h51;
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    PkeState <= PKE_IDLE;
else
    PkeState <= NextPkeState;

always @(*)
case(PkeState)
    PKE_IDLE:
    begin
        if(PkeStart)
            NextPkeState = PKE_START;
        else
            NextPkeState = PkeState;
    end
    PKE_START:
    begin
        if(RsaExp)
            NextPkeState = PKE_RSAEXP;
        else if(RsaModMul | RsaM2I )
            NextPkeState = PKE_RSAMODMUL;
        else if(RsaHCal)
            NextPkeState = PKE_RSAHCAL;
        else if(EccHCal)
            NextPkeState = PKE_ECCHCAL;
        else if(EccI2M)
            NextPkeState = PKE_ECCI2M;
        else if(EccM2I)
            NextPkeState = PKE_ECCM2I;
        else if(EccModInv | RsaModInv)
            NextPkeState = PKE_ECCMODINV;
        else if(EccModMul)
            NextPkeState = PKE_ECCMODMUL;
        else if(EccModAdd)
            NextPkeState = PKE_ECCMODADD;
        else if(EccModSub)
            NextPkeState = PKE_ECCMODSUB;
        //zxjian,20230808
        else if(RsaModAdd)
            NextPkeState = PKE_RSAMODADD;
        else if(RsaModSub)
            NextPkeState = PKE_RSAMODSUB;
        //end,20230808
        else if(EccPointAdd)
            NextPkeState = PKE_ECCPOINTADD;
        else if(EccPointDbl)
            NextPkeState = PKE_ECCPOINTDBL;
        else if(EdI2M)
            NextPkeState = PKE_EDI2M;
        else if(EdM2I)
            NextPkeState = PKE_EDM2I;
        else if(EdPointAdd)
            NextPkeState = PKE_EDPOINTADD;
        else if(EdPointDbl)
            NextPkeState = PKE_EDPOINTDBL;
        else if(EccPointMul)
            NextPkeState = PKE_ECCPOINTMUL;
        else if(X25519)
            NextPkeState = PKE_X25519;
        else if(GcdOp)
            NextPkeState = PKE_GCD;
        else
            NextPkeState = PKE_IDLE;
    end
    PKE_RSAEXP:
    begin
        if(ModExpDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_RSAMODMUL:
    begin
        if(ModMulDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_RSAHCAL:
    begin
        if(HCalDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_ECCHCAL:
    begin
        if(HCalDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_ECCI2M:
    begin
        if(EccI2MDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_ECCM2I:
    begin
        if(EccM2IDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_ECCMODINV:
    begin
        if(ModInvDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_ECCMODMUL:
    begin
        if(ModMulDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_ECCMODADD:
    begin
        if(ModAddDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_ECCMODSUB:
    begin
        if(ModSubDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    //zxjian,20230808
    PKE_RSAMODADD:
    begin
        if(ModAddDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_RSAMODSUB:
    begin
        if(ModSubDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    //end,20230808
    PKE_ECCPOINTADD:
    begin
        if(EccPointAddDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_ECCPOINTDBL:
    begin
        if(EccPointDblDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_END:
    begin
            NextPkeState = PKE_IDLE;
    end
    PKE_EDI2M:
    begin
        if(EdI2MDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_EDM2I:
    begin
        if(EdM2IDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_EDPOINTADD:
    begin
        if(EdPointAddDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_EDPOINTDBL:
    begin
        if(EdPointDblDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_ECCPOINTMUL:
    begin
        if(EccPointMulDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_X25519:
    begin
        if(X25519Done)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    PKE_GCD:
    begin
        if(GcdDone)
            NextPkeState = PKE_END;
        else
            NextPkeState = PkeState;
    end
    default:
    begin
            NextPkeState = PKE_IDLE;
    end
endcase

assign StartModExp      = PkeState == PKE_START & RsaExp;
assign StartModMul      = PkeState == PKE_START & (RsaModMul | EccModMul | RsaM2I);
assign StartHCal        = PkeState == PKE_START & (RsaHCal | EccHCal);
assign StartEccI2M      = PkeState == PKE_START & EccI2M;
assign StartEccM2I      = PkeState == PKE_START & EccM2I;
//zxjian,20230318
assign EccStartModInv   = PkeState == PKE_START & EccModInv;
//assign EccStartModInv   = PkeState == PKE_START & PkeIR == 8'h08;
assign RsaStartModInv   = PkeState == PKE_START & RsaModInv;
//assign StartPointAdd    = PkeState == PKE_START & EccPointAdd;
//assign StartPointDbl    = PkeState == PKE_START & EccPointDbl;
assign StartPointAdd    = PkeState == PKE_START & EccPointAdd | StartPointAdd_PM;
assign StartPointDbl    = PkeState == PKE_START & EccPointDbl | StartPointDbl_PM;
//zxjian,20230808
//assign StartModAdd_Ecc  = PkeState == PKE_START & EccModAdd;
//assign StartModSub_Ecc  = PkeState == PKE_START & EccModSub;
assign StartModAdd_Ecc  = PkeState == PKE_START & (EccModAdd | RsaModAdd);
assign StartModSub_Ecc  = PkeState == PKE_START & (EccModSub | RsaModSub);
assign StartEdI2M       = PkeState == PKE_START & EdI2M;
assign StartEdM2I       = PkeState == PKE_START & EdM2I;
//assign StartEdPointAdd  = PkeState == PKE_START & EdPointAdd;
//assign StartEdPointDbl  = PkeState == PKE_START & EdPointDbl;
assign StartEdPointAdd  = PkeState == PKE_START & EdPointAdd | StartEdPointAdd_PM;
assign StartEdPointDbl  = PkeState == PKE_START & EdPointDbl | StartEdPointDbl_PM;
assign StartPointMul    = PkeState == PKE_START & EccPointMul;
assign StartX25519      = PkeState == PKE_START & X25519;

assign StartGcd         = PkeState == PKE_START & GcdOp;

assign PkeDone          = PkeState == PKE_END;

always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        ModExpState <= MODEXP_IDLE;
    else
        ModExpState <= NextModExpState;
always @(*)
case(ModExpState)
    MODEXP_IDLE:
    begin
        if(StartModExp)
            NextModExpState = MODEXP_MM1H;
        else
            NextModExpState = ModExpState;
    end
    MODEXP_MM1H:
    begin
        if(MpcDone)
            NextModExpState = MODEXP_MMAH;
        else
            NextModExpState = ModExpState;
    end
    MODEXP_MMAH:
    begin
        if(MpcDone)
            NextModExpState = MODEXP_ERD;
        else
            NextModExpState = ModExpState;
    end
    MODEXP_ERD:
    begin
            NextModExpState = MODEXP_ELD;
    end
    MODEXP_ELD:
    begin
            NextModExpState = MODEXP_JUDGE1;
    end
    MODEXP_JUDGE1:
    begin
        if(EDatIsZero)
            NextModExpState = MODEXP_MMR0R1;  //R1 = R0*R1
        else
            NextModExpState = MODEXP_MMR1R0;  //R0 = R0*R1
    end
    MODEXP_MMR0R1:
    begin
        if(MpcDone)
            NextModExpState = MODEXP_MMR0R0;  //R0 = R0*R0
        else
            NextModExpState = ModExpState;
    end
    MODEXP_MMR1R0:
    begin
        if(MpcDone)
            NextModExpState = MODEXP_MMR1R1;  //R1 = R1*R1
        else
            NextModExpState = ModExpState;
    end
    MODEXP_MMR0R0:
    begin
        if(MpcDone)
            NextModExpState = MODEXP_JUDGE2;
        else
            NextModExpState = ModExpState;
    end
    MODEXP_MMR1R1:
    begin
        if(MpcDone)
            NextModExpState = MODEXP_JUDGE2;
        else
            NextModExpState = ModExpState;
    end
    MODEXP_JUDGE2:
    begin
        if(NeedRd)
            NextModExpState = MODEXP_JUDGE3;
        else
            NextModExpState = MODEXP_JUDGE1;
    end
    MODEXP_JUDGE3:   //Judge if EDat is End
    begin
        if(EDatEnd)
            NextModExpState = MODEXP_SET1;
        else
            NextModExpState = MODEXP_ERD;
    end
    MODEXP_SET1:
    begin
        if(LongAlgDone)
            NextModExpState = MODEXP_MM1;
        else
            NextModExpState = ModExpState;
    end
    MODEXP_MM1:
    begin
        if(MpcDone)
            NextModExpState = MODEXP_END;
        else
            NextModExpState = ModExpState;
    end
    MODEXP_END:
    begin
            NextModExpState = MODEXP_IDLE;
    end
    default:
            NextModExpState = MODEXP_IDLE;
endcase


assign ModExpDone    = ModExpState == MODEXP_END ;
assign ModExpRamRd   =
                       //ModExpState == MODEXP_ERD ;
                       ModExpState == MODEXP_ERD | EccPointMulRamRd | X25519RamRd ;

//assign ModExpRamAdr  = ECnt[15:6];
//zxjian,20230318
//assign ModExpRamAdr  = ModExpState == MODEXP_ERD ? ECnt[13:6] + 'h33:
assign ModExpRamAdr  = ModExpState == MODEXP_ERD ? ECnt[13:6] + 'h153: //was 93@4kbit
                       EccPointMulRamRd          ? KCnt[13:6] :
                       X25519RamRd               ? KCnt[13:6] :
                                                   8'h00      ;

assign EDatIndex     = ECnt[5:0];
assign EDatIsZero    = ~EDat[EDatIndex];
assign NeedRd        = ECnt[5:0] ==0;
assign EDatEnd       = ECnt == 0;

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    begin
    ECnt <= 16'h00;
    EDat <= 64'h0000;
    end
else
    begin
    ECnt <= NextECnt;
    EDat <= NextEDat;
    end

assign NextECnt      = StartModExp                    ? PkeELen -1   	:
                       (ModExpState == MODEXP_JUDGE2 & EDatEnd) ? ECnt  :
                       (ModExpState == MODEXP_JUDGE2) ? ECnt -1      	:
                                                        ECnt         	;
assign NextEDat      = (ModExpState == MODEXP_ELD)    ? RamModExpDat 	:
                                                        EDat         	;
assign StartMpc_ME   =
                        ModExpState == MODEXP_IDLE & StartModExp     |
                        ModExpState == MODEXP_MM1H & MpcDone         |
                        ModExpState == MODEXP_JUDGE1                 |
                        ModExpState == MODEXP_MMR1R0 & MpcDone       |
                        ModExpState == MODEXP_MMR0R1 & MpcDone       |
                        ModExpState == MODEXP_SET1 & LongAlgDone     ;

assign ME_Src0       =
                       (ModExpState == MODEXP_MM1H)   ? ME_R0        :
                       (ModExpState == MODEXP_MMAH)   ? ME_R1        :
                       (ModExpState == MODEXP_MMR1R0) ? ME_R0        :
                       (ModExpState == MODEXP_MMR0R1) ? ME_R0        :
                       (ModExpState == MODEXP_MMR0R0) ? ME_R0        :
                       (ModExpState == MODEXP_MMR1R1) ? ME_R1        :
                       (ModExpState == MODEXP_ERD)    ? ME_E         :
                       (ModExpState == MODEXP_MM1)    ? ME_R0        :
                                                        ME_R0        ;

assign ME_Src1       =
                       (ModExpState == MODEXP_MM1H)   ? ME_H         :
                       (ModExpState == MODEXP_MMAH)   ? ME_H         :
                       (ModExpState == MODEXP_MMR1R0) ? ME_R1T       :
                       (ModExpState == MODEXP_MMR0R1) ? ME_R1T       :
                       (ModExpState == MODEXP_MMR0R0) ? ME_R0T       :
                       (ModExpState == MODEXP_MMR1R1) ? ME_R1T       :
                       (ModExpState == MODEXP_MM1)    ? ME_R0T       :
                                                        ME_R1T       ;

assign ME_Dst        =
                       (ModExpState == MODEXP_MM1H)   ? ME_R0        :
                       (ModExpState == MODEXP_MMAH)   ? ME_R1        :
                       (ModExpState == MODEXP_MMR1R0) ? ME_R0        :
                       (ModExpState == MODEXP_MMR0R1) ? ME_R1        :
                       (ModExpState == MODEXP_MMR0R0) ? ME_R0        :
                       (ModExpState == MODEXP_MMR1R1) ? ME_R1        :
                       (ModExpState == MODEXP_MM1)    ? ME_R0        :
                                                        ME_R0        ;
assign LongAlgStart_ME  = ModExpState == MODEXP_JUDGE3 & EDatEnd     ;

assign LongAlgOp_ME     = ModExpState == MODEXP_SET1 ? UNIT_B_SET1   :
                                                       6'd0	     ;

always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        ModMulState <= MODMUL_IDLE;
    else
        ModMulState <= NextModMulState;
always @(*)
case(ModMulState)
    MODMUL_IDLE:
    begin
        if(StartModMul & RsaM2I)
            NextModMulState = MODMUL_MMAB;
        else if(StartModMul)
            NextModMulState = MODMUL_MMAH;
        else
            NextModMulState = ModMulState;
    end
    MODMUL_MMAH:		//MMAH
    begin
        if(MpcDone)
            NextModMulState = MODMUL_MMAB;
        else
            NextModMulState = ModMulState;
    end
    MODMUL_MMAB:		//MMAB
    begin
        if(MpcDone)
            NextModMulState = MODMUL_END;
        else
            NextModMulState = ModMulState;
    end
    MODMUL_END:
            NextModMulState = MODMUL_IDLE;
    default:
            NextModMulState = MODMUL_IDLE;
endcase

assign ModMulDone     = ModMulState == MODMUL_END;

assign StartMpc_MM    =
                       (ModMulState == MODMUL_IDLE) & StartModMul |
                       (ModMulState == MODMUL_MMAH) & MpcDone     ;

assign MM_Src0       =
                                                        MM_X                ;
assign MM_Src1       =
                       (ModMulState == MODMUL_MMAH & RsaModMul)   ? MM_H    :
                       (ModMulState == MODMUL_MMAH & RsaM2I   )   ? MM_H    :
                       (ModMulState == MODMUL_MMAH & EccModMul)   ? MM_H1   :
                       (ModMulState == MODMUL_MMAB & RsaModMul)   ? MM_Y    :
                       (ModMulState == MODMUL_MMAB & EccModMul)   ? MM_Y    :
                                                        MM_Y                ;
assign MM_Dst        =
                                                        MM_X                ;


always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        HCalState <= HCAL_IDLE;
    else
        HCalState <= NextHCalState;

always @(*)
case(HCalState)
    HCAL_IDLE:
    begin
        if(StartHCal)
            NextHCalState = HCAL_SUB;
        else
            NextHCalState = HCalState;
    end
    HCAL_SUB:
    begin
        if(LongAlgDone & ResultIsNeg & EndHCal)
            NextHCalState = HCAL_END;
        else if(LongAlgDone & EndHCal)
            NextHCalState = HCAL_MOV;
        else if(LongAlgDone & ResultIsNeg)
            NextHCalState = HCAL_SHIFTD;
        else if(LongAlgDone)
            NextHCalState = HCAL_SHIFTT;
        else
            NextHCalState = HCalState;
    end
    HCAL_SHIFTD:
        if(LongAlgDone)
            NextHCalState = HCAL_JUDGE;
        else
            NextHCalState = HCalState;
    HCAL_SHIFTT:
        if(LongAlgDone)
            NextHCalState = HCAL_JUDGE;
        else
            NextHCalState = HCalState;
    HCAL_JUDGE:
            NextHCalState = HCAL_SUB;
    HCAL_MOV:
        if(LongAlgDone)
            NextHCalState = HCAL_MOV1;
        else
            NextHCalState = HCalState;
    HCAL_MOV1:
        if(LongAlgDone)
            NextHCalState = HCAL_END;
        else
            NextHCalState = HCalState;
    HCAL_END:
            NextHCalState = HCAL_IDLE;
    default:
            NextHCalState = HCAL_IDLE;
endcase

assign HCalDone        = HCalState == HCAL_END;
assign HCalStart      = StartHCal;

assign HLen = PkeIR[7]             ? PkeELen :
             (mmsel &(mimm_opt[2:0] != 'd0) )? (mimm_opt[2:0] == 'd3)? ((PkeNLen[7:0]=='d0) ? PkeNLen : PkeNLen + 2*(256-PkeNLen[7:0])): // MIMM 4 mac
                                             ((PkeNLen[6:0]=='d0) ? PkeNLen : PkeNLen + 2*(128-PkeNLen[6:0])):// MIMM 2 mac 
                                             ((PkeNLen[5:0]=='d0) ? PkeNLen : PkeNLen + 2*(64-PkeNLen[5:0])); //  Dr.zheng & 1 mac
//              (PkeNLen[5:0]==6'd0) ? PkeNLen : PkeNLen + 2*(64-PkeNLen[5:0]);

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    HCnt <= 13'h000;
else
    HCnt <= NextHCnt;
assign NextHCnt = StartHCal              ? 13'h0   :
                  HCalState==HCAL_JUDGE  ? HCnt +1 :
                                           HCnt    ;
assign EndHCal = HCnt == HLen;

assign LongAlgStart_HCal = HCalState == HCAL_IDLE & StartHCal   |
                           HCalState == HCAL_SUB  & LongAlgDone & ~(EndHCal & ResultIsNeg)|
                           HCalState == HCAL_MOV  & LongAlgDone |
                           HCalState == HCAL_JUDGE              ;

assign LongAlgOp_HCal    = HCalState == HCAL_SUB    ? UNIT_BA_SUB_B :
                           HCalState == HCAL_SHIFTD ? UNIT_B_LFT_B  :
                           HCalState == HCAL_SHIFTT ? UNIT_B_LFT_B  :
                           HCalState == HCAL_MOV    ? UNIT_B_MOV_A  :
                           HCalState == HCAL_MOV1   ? UNIT_A_MOV_B  :
                                                      6'd0          ;
assign HCal_Src0_RSA      =
                         HCalState == HCAL_SUB      ? HCAL_N    :     //ME_M      :
                         HCalState == HCAL_SHIFTD   ? HCAL_N    :     //ME_M      :
                         HCalState == HCAL_SHIFTT   ? HCAL_N    :     //ME_M      :
                         HCalState == HCAL_MOV      ? HCAL_T0   :     //ME_E      :
                         HCalState == HCAL_MOV1     ? HCAL_T0   :     //ME_E      :
                                                      HCAL_T0   ;     //ME_E      ;


assign HCal_Src1_RSA     =
                         HCalState == HCAL_SUB      ? HCAL_D    :     //ME_H    :
                         HCalState == HCAL_SHIFTD   ? HCAL_D    :     //ME_H    :
                         HCalState == HCAL_SHIFTT   ? HCAL_T1   :     //ME_M    :
                         HCalState == HCAL_MOV      ? HCAL_T1   :     //ME_M    :
                         HCalState == HCAL_MOV1     ? HCAL_D    :     //ME_H    :
                                                      HCAL_D    ;     //ME_H    ;


assign HCal_Dst_RSA      =
                         HCalState == HCAL_SUB      ? HCAL_T1    :     //ME_M    :
                         HCalState == HCAL_SHIFTD   ? HCAL_D     :     //ME_H    :
                         HCalState == HCAL_SHIFTT   ? HCAL_D     :     //ME_H    :
                         HCalState == HCAL_MOV      ? HCAL_T0    :     //ME_E    :
                         HCalState == HCAL_MOV1     ? HCAL_D     :     //ME_H    :
                                                      HCAL_D     ;     //ME_H    ;


assign HCal_Src0_ECC      = //P_ADR;
                         HCalState == HCAL_SUB      ? P_ADR        :
                         HCalState == HCAL_SHIFTD   ? P_ADR        :
                         HCalState == HCAL_SHIFTT   ? P_ADR        :
                         HCalState == HCAL_MOV      ? TP0_ADR      :
                         HCalState == HCAL_MOV1     ? TP0_ADR      :
                                                      MI_X1        ;


assign HCal_Src1_ECC     =
                         HCalState == HCAL_SUB      ? H_ADR      :
                         HCalState == HCAL_SHIFTD   ? H_ADR      :
                         HCalState == HCAL_SHIFTT   ? TP1_ADR    :
                         HCalState == HCAL_MOV      ? TP1_ADR    :
                         HCalState == HCAL_MOV1     ? H_ADR      :
                                                      MI_X1      ;


assign HCal_Dst_ECC      =
                         HCalState == HCAL_SUB      ? TP1_ADR    :
                         HCalState == HCAL_SHIFTD   ? H_ADR      :
                         HCalState == HCAL_SHIFTT   ? H_ADR      :
                         HCalState == HCAL_MOV      ? TP0_ADR    :
                         HCalState == HCAL_MOV1     ? H_ADR      :
                                                      MI_X1      ;

always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        EccI2MState <= ECCI2M_IDLE;
    else
        EccI2MState <= NextEccI2MState;

always @(*)
case(EccI2MState)
    ECCI2M_IDLE:
    begin
        if(StartEccI2M)
            NextEccI2MState = ECCI2M_MOVH;
        else
            NextEccI2MState = EccI2MState;
    end
    ECCI2M_MOVH:
    begin
        if(LongAlgDone)
            NextEccI2MState = ECCI2M_MMQ0XH;
        else
            NextEccI2MState = EccI2MState;
    end
    ECCI2M_MMQ0XH:
    begin
        if(MpcDone)
            NextEccI2MState = ECCI2M_MMQ0YH;
        else
            NextEccI2MState = EccI2MState;
    end
    ECCI2M_MMQ0YH:
    begin
        if(MpcDone)
            NextEccI2MState = ECCI2M_MMQ0ZH;
        else
            NextEccI2MState = EccI2MState;
    end
    ECCI2M_MMQ0ZH:
    begin
        if(MpcDone & EccI2MA)
            NextEccI2MState = ECCI2M_MMQ1XH;
        else if(MpcDone & EccI2MD)
            NextEccI2MState = ECCI2M_MMAH;
        else
            NextEccI2MState = EccI2MState;
    end
    ECCI2M_MMQ1XH:
    begin
        if(MpcDone)
            NextEccI2MState = ECCI2M_MMQ1YH;
        else
            NextEccI2MState = EccI2MState;
    end
    ECCI2M_MMQ1YH:
    begin
        if(MpcDone)
            NextEccI2MState = ECCI2M_MMQ1ZH;
        else
            NextEccI2MState = EccI2MState;
    end
    ECCI2M_MMQ1ZH:
    begin
        if(MpcDone)
            NextEccI2MState = ECCI2M_END;
        else
            NextEccI2MState = EccI2MState;
    end
    ECCI2M_MMAH:
    begin
        if(MpcDone)
            NextEccI2MState = ECCI2M_END;
        else
            NextEccI2MState = EccI2MState;
    end
    ECCI2M_END:
    begin
            NextEccI2MState = ECCI2M_IDLE;
    end
    default:
            NextEccI2MState = ECCI2M_IDLE;
endcase

assign EccI2MDone = EccI2MState == ECCI2M_END;

assign StartMpc_I2M     =
                         (EccI2MState == ECCI2M_MOVH)   & LongAlgDone |
                         (EccI2MState == ECCI2M_MMQ0XH) & MpcDone     |
                         (EccI2MState == ECCI2M_MMQ0YH) & MpcDone     |
                         (EccI2MState == ECCI2M_MMQ0ZH) & MpcDone     |
                         (EccI2MState == ECCI2M_MMQ1XH) & MpcDone     |
                         (EccI2MState == ECCI2M_MMQ1YH) & MpcDone     ;
assign LongAlgStart_I2M = EccI2MState== ECCI2M_IDLE & StartEccI2M;
assign LongAlgOp_I2M    = EccI2MState != ECCI2M_IDLE ? UNIT_B_MOV_A : 6'd0;
assign PointEn_I2M      =
                         (EccI2MState == ECCI2M_MMQ0YH) ? 1'b1 :
                         (EccI2MState == ECCI2M_MMQ1YH) ? 1'b1 :
                         (EccI2MState == ECCI2M_MMQ1ZH) ? 1'b1 :
                                                          1'b0 ;

always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        EccM2IState <= ECCM2I_IDLE;
    else
        EccM2IState <= NextEccM2IState;
always @(*)
case(EccM2IState)
    ECCM2I_IDLE:
    begin
        if(StartEccM2I)
            NextEccM2IState = ECCM2I_MMZ1;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MMZ1:
    begin
        if(MpcDone)
            NextEccM2IState = ECCM2I_MOVZ2UT;
        else
            NextEccM2IState = EccM2IState;
    end

    ECCM2I_MOVZ2UT:
    begin
        if(LongAlgDone)
            NextEccM2IState = ECCM2I_MOVUT2U;
        else
            NextEccM2IState = EccM2IState;
    end

    ECCM2I_MOVUT2U:
    begin
        if(LongAlgDone)
            NextEccM2IState = ECCM2I_MODINVZ;
        else
            NextEccM2IState = EccM2IState;
    end

    ECCM2I_MODINVZ:
    begin
        if(ModInvDone)
            NextEccM2IState = ECCM2I_MOVZ2TP0;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MOVZ2TP0:
    begin
        if(LongAlgDone)
            NextEccM2IState = ECCM2I_MMZH;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MMZH:
    begin
        if(MpcDone )
            NextEccM2IState = ECCM2I_MOVZ2TP1;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MOVZ2TP1:
    begin
        if(LongAlgDone)
            NextEccM2IState = ECCM2I_MMZ2;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MMZ2:
    begin
        if(MpcDone)
            NextEccM2IState = ECCM2I_MMXZ2;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MMXZ2:
    begin
        if(MpcDone)
            NextEccM2IState = ECCM2I_MMZ3;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MMZ3:
    begin
        if(MpcDone)
            NextEccM2IState = ECCM2I_MMYZ3;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MMYZ3:
    begin
        if(MpcDone)
            NextEccM2IState = ECCM2I_MMX1;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MMX1:
    begin
        if(MpcDone)
            NextEccM2IState = ECCM2I_MOVY2TP0;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MOVY2TP0:
    begin
        if(LongAlgDone)
            NextEccM2IState = ECCM2I_MMY1;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_MMY1:
    begin
        if(MpcDone)
            NextEccM2IState = ECCM2I_END;
        else
            NextEccM2IState = EccM2IState;
    end
    ECCM2I_END:
    begin
            NextEccM2IState = ECCM2I_IDLE;
    end
    default:
            NextEccM2IState = ECCM2I_IDLE;
endcase

assign EccM2IDone = EccM2IState == ECCM2I_END;

assign StartMpc_M2I     =
                         (EccM2IState == ECCM2I_IDLE)    & StartEccM2I |
                         (EccM2IState == ECCM2I_MOVZ2TP0) & LongAlgDone |
                         (EccM2IState == ECCM2I_MOVZ2TP1) & LongAlgDone |
                         (EccM2IState == ECCM2I_MMZ2)    & MpcDone     |
                         (EccM2IState == ECCM2I_MMXZ2)   & MpcDone     |
                         (EccM2IState == ECCM2I_MMZ3)    & MpcDone     |
                         (EccM2IState == ECCM2I_MMYZ3)   & MpcDone     |
                         (EccM2IState == ECCM2I_MOVY2TP0) & LongAlgDone ;

assign LongAlgStart_M2I  = (EccM2IState == ECCM2I_MMZ1) & MpcDone        |
                           (EccM2IState == ECCM2I_MODINVZ) & ModInvDone  |
                           (EccM2IState == ECCM2I_MMZH)    & MpcDone     |
                           (EccM2IState == ECCM2I_MMX1)    & MpcDone     |
                           (EccM2IState == ECCM2I_MOVZ2UT) & LongAlgDone ;

assign StartModInv_M2I  = (EccM2IState == ECCM2I_MOVUT2U) & LongAlgDone ;

assign LongAlgOp_M2I    =
                          (EccM2IState == ECCM2I_MOVZ2UT ) ? UNIT_A_MOV_B :
                          (EccM2IState == ECCM2I_MOVUT2U ) ? UNIT_B_MOV_A :
                          (EccM2IState == ECCM2I_MOVZ2TP1) ? UNIT_A_MOV_B :
                          (EccM2IState == ECCM2I_MOVZ2TP0) ? UNIT_B_MOV_A :
                          (EccM2IState == ECCM2I_MOVY2TP0) ? UNIT_B_MOV_A :
                                                            6'd0         ;

assign PointEn_M2I      =
                         (EccM2IState == ECCM2I_MMZ2)     ? 1'b1 :
                         (EccM2IState == ECCM2I_MMYZ3)    ? 1'b1 :
                         (EccM2IState == ECCM2I_MMY1)     ? 1'b1 :
                                                            1'b0 ;
//zxjian,20221127
//assign StartModInv = EccStartModInv | StartModInv_M2I | StartModInv_EDM2I;
assign StartModInv = EccStartModInv | StartModInv_M2I | StartModInv_EDM2I | RsaStartModInv;

always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        ModInvState <= MI_IDLE;
    else
        ModInvState <= NextModInvState;
always @(*)
case(ModInvState)
    MI_IDLE:                        //Idle is S0
    begin
        if(StartModInv)
            NextModInvState = MI_INIT0;
        else
            NextModInvState = ModInvState;
    end
    MI_INIT0:
    begin
        if(LongAlgDone)
            NextModInvState = MI_INIT1;
        else
            NextModInvState = ModInvState;
    end
    MI_INIT1:
    begin
        if(LongAlgDone)
            NextModInvState = MI_INIT2;
        else
            NextModInvState = ModInvState;
    end
    MI_INIT2:
    begin
        if(LongAlgDone)
            NextModInvState = MI_INIT3;
        else
            NextModInvState = ModInvState;
    end
    MI_INIT3:
    begin
        if(LongAlgDone)
            NextModInvState = MI_INIT4;
        else
            NextModInvState = ModInvState;
    end
    MI_INIT4:
    begin
        if(LongAlgDone)
            NextModInvState = MI_INIT5;
        else
            NextModInvState = ModInvState;
    end
    MI_INIT5:
    begin
        if(LongAlgDone)
            NextModInvState = MI_JUDGE1;
        else
            NextModInvState = ModInvState;
    end
    MI_JUDGE1:
    begin
        if(ErrorDetect)
            NextModInvState = MI_END;
        else if(Y3IsEven)
            NextModInvState = MI_Y3DIV2;
        else if(X3IsEven)
            NextModInvState = MI_X3DIV2;
        else
            NextModInvState = MI_X3CMPY3;
    end
    MI_X3DIV2:
    begin
        if(LongAlgDone)
            NextModInvState = MI_JUDGE2;
        else
            NextModInvState = ModInvState;
    end
    MI_JUDGE2:
    begin
        if(~X1IsEven | ~X2IsEven)
            NextModInvState = MI_X1ADDU;
        else
            NextModInvState = MI_X1DIV2;
    end
    MI_X1ADDU:
    begin
        if(LongAlgDone)
            NextModInvState = MI_X2SUBV;
        else
            NextModInvState = ModInvState;
    end
    MI_X2SUBV:
    begin
        if(LongAlgDone)
            NextModInvState = MI_X1DIV2;
        else
            NextModInvState = ModInvState;
    end
    MI_X1DIV2:
    begin
        if(LongAlgDone)
            NextModInvState = MI_X2DIV2;
        else
            NextModInvState = ModInvState;
    end
    MI_X2DIV2:
    begin
        if(LongAlgDone)
            NextModInvState = MI_JUDGE1;
        else
            NextModInvState = ModInvState;
    end
    MI_Y3DIV2:
    begin
        if(LongAlgDone)
            NextModInvState = MI_JUDGE3;
        else
            NextModInvState = ModInvState;
    end
    MI_JUDGE3:
    begin
        if(~Y1IsEven | ~Y2IsEven)
            NextModInvState = MI_Y1ADDU;
        else
            NextModInvState = MI_Y1DIV2;
    end
    MI_Y1ADDU:
    begin
        if(LongAlgDone)
            NextModInvState = MI_Y2SUBV;
        else
            NextModInvState = ModInvState;
    end
    MI_Y2SUBV:
    begin
        if(LongAlgDone)
            NextModInvState = MI_Y1DIV2;
        else
            NextModInvState = ModInvState;
    end
    MI_Y1DIV2:
    begin
        if(LongAlgDone)
            NextModInvState = MI_Y2DIV2;
        else
            NextModInvState = ModInvState;
    end
    MI_Y2DIV2:
    begin
        if(LongAlgDone)
            NextModInvState = MI_JUDGE1;
        else
            NextModInvState = ModInvState;
    end
    MI_X3CMPY3:
    begin
        if(LongAlgDone & ResultIsZero)
            NextModInvState = MI_Y3SUB1;
        else if(LongAlgDone & ResultIsNeg)
            NextModInvState = MI_Y1SUBX1;
        else if(LongAlgDone )
            NextModInvState = MI_X1SUBY1;
        else
            NextModInvState = ModInvState;
    end
    MI_Y1SUBX1:
    begin
        if(LongAlgDone)
            NextModInvState = MI_Y2SUBX2;
        else
            NextModInvState = ModInvState;
    end
    MI_Y2SUBX2:
    begin
        if(LongAlgDone)
            NextModInvState = MI_Y3SUBX3;
        else
            NextModInvState = ModInvState;
    end
    MI_Y3SUBX3:
    begin
        if(LongAlgDone)
            NextModInvState = MI_JUDGE1;
        else
            NextModInvState = ModInvState;
    end
    MI_X1SUBY1:
    begin
        if(LongAlgDone)
            NextModInvState = MI_X2SUBY2;
        else
            NextModInvState = ModInvState;
    end
    MI_X2SUBY2:
    begin
        if(LongAlgDone)
            NextModInvState = MI_X3SUBY3;
        else
            NextModInvState = ModInvState;
    end
    MI_X3SUBY3:
    begin
        if(LongAlgDone)
            NextModInvState = MI_JUDGE1;
        else
            NextModInvState = ModInvState;
    end
    MI_Y3SUB1:
    begin
        if(LongAlgDone & ResultIsZero)
            NextModInvState = MI_JUDGE4;
        else if(LongAlgDone )
            NextModInvState = MI_END;
        else
            NextModInvState = ModInvState;
    end
    MI_JUDGE4:
    begin
        if(LongAlgDone & Y2IsNeg)
            NextModInvState = MI_Y2ADDP;
        else if(LongAlgDone)
            NextModInvState = MI_Y2SUBP;
        else
            NextModInvState = ModInvState;
    end
    MI_Y2ADDP:
    begin
        if(LongAlgDone & Y2IsNeg)
            NextModInvState = MI_Y2ADDP;
        else if(LongAlgDone)
            NextModInvState = MI_END;
        else
            NextModInvState = ModInvState;
    end
    MI_Y2SUBP:
    begin
        if(LongAlgDone & Y2IsNeg)
            NextModInvState = MI_Y2ADDP;
        else if(LongAlgDone)
            NextModInvState = MI_Y2SUBP;
        else
            NextModInvState = ModInvState;
    end
    MI_END:
    begin
            NextModInvState = MI_IDLE;
    end
    default:
    begin
            NextModInvState = MI_IDLE;
    end

endcase

assign ModInvDone      = ModInvState == MI_END;

assign ResultIsZero    = LongAlgSR[0];
assign ResultIsNeg     = LongAlgSR[1];

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    ModInvRdy <= 1'b0;
else
    ModInvRdy <= NextModInvRdy;
assign NextModInvRdy   = StartModInv                                             ? 1'b0 :
                        (ModInvState== MI_Y3SUB1) & LongAlgDone & ResultIsZero   ? 1'b1 :
                                                                                   ModInvRdy;

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    begin
    X1IsEvenReg       <= 1'b0;
    X2IsEvenReg       <= 1'b0;
    X3IsEvenReg       <= 1'b0;
    Y1IsEvenReg       <= 1'b0;
    Y2IsEvenReg       <= 1'b0;
    Y3IsEvenReg       <= 1'b0;
    Y2IsNegReg        <= 1'b0;
    end
else
    begin
    X1IsEvenReg       <= X1IsEven;
    X2IsEvenReg       <= X2IsEven;
    X3IsEvenReg       <= X3IsEven;
    Y1IsEvenReg       <= Y1IsEven;
    Y2IsEvenReg       <= Y2IsEven;
    Y3IsEvenReg       <= Y3IsEven;
    Y2IsNegReg        <= Y2IsNeg;
    end

assign X1IsEven        =
                         StartModInv                            ?         1'b0   :
                         ModInvState == MI_X1ADDU & LongAlgDone ? ~LongAlgSR[2]  :
                         ModInvState == MI_X1SUBY1 & LongAlgDone? ~LongAlgSR[2]  :
                         ModInvState == MI_X1DIV2 & LongAlgDone ? ~LongAlgSR[2]  :
                                                                  X1IsEvenReg    ;

assign X2IsEven        =
                         StartModInv                            ?         1'b1   :
                         ModInvState == MI_X2SUBV & LongAlgDone ? ~LongAlgSR[2]  :
                         ModInvState == MI_X2SUBY2 & LongAlgDone? ~LongAlgSR[2]  :
                         ModInvState == MI_X2DIV2 & LongAlgDone ? ~LongAlgSR[2]  :
                                                                  X2IsEvenReg    ;

assign X3IsEven        =
                         ModInvState == MI_INIT4 & LongAlgDone  ? ~LongAlgSR[2]  :
                         ModInvState == MI_X3SUBY3 & LongAlgDone? ~LongAlgSR[2]  :
                         ModInvState == MI_X3DIV2 & LongAlgDone ? ~LongAlgSR[2]  :
                                                                  X3IsEvenReg    ;

assign Y1IsEven        =
                         StartModInv                            ?         1'b1   :
                         ModInvState == MI_Y1ADDU & LongAlgDone ? ~LongAlgSR[2]  :
                         ModInvState == MI_Y1SUBX1 & LongAlgDone? ~LongAlgSR[2]  :
                         ModInvState == MI_Y1DIV2 & LongAlgDone ? ~LongAlgSR[2]  :
                                                                  Y1IsEvenReg    ;

assign Y2IsEven        =
                         StartModInv                            ?         1'b0   :
                         ModInvState == MI_Y2SUBV & LongAlgDone ? ~LongAlgSR[2]  :
                         ModInvState == MI_Y2SUBX2 & LongAlgDone? ~LongAlgSR[2]  :
                         ModInvState == MI_Y2DIV2 & LongAlgDone ? ~LongAlgSR[2]  :
                                                                  Y2IsEvenReg    ;

assign Y3IsEven        =
                         ModInvState == MI_INIT5 & LongAlgDone  ? ~LongAlgSR[2]  :
                         ModInvState == MI_Y3SUBX3 & LongAlgDone? ~LongAlgSR[2]  :
                         ModInvState == MI_Y3DIV2 & LongAlgDone ? ~LongAlgSR[2]  :
                                                                  Y3IsEvenReg    ;

assign Y2IsNeg         =
                         StartModInv                            ?         1'b0   :
                         ModInvState == MI_Y2SUBV & LongAlgDone ? LongAlgSR[1]   :
                         ModInvState == MI_Y2SUBX2 & LongAlgDone? LongAlgSR[1]   :
                         ModInvState == MI_Y2ADDP & LongAlgDone ? LongAlgSR[1]   :
                         ModInvState == MI_JUDGE4 & LongAlgDone ? LongAlgSR[1]   :
                         ModInvState == MI_Y2SUBP & LongAlgDone ? LongAlgSR[1]   :
                                                                  Y2IsNegReg     ;

assign LongAlgStart_MI =
                         ModInvState == MI_IDLE & StartModInv   |
                         ModInvState == MI_INIT0 & LongAlgDone  |
                         ModInvState == MI_INIT1 & LongAlgDone  |
                         ModInvState == MI_INIT2 & LongAlgDone  |
                         ModInvState == MI_INIT3 & LongAlgDone  |
                         ModInvState == MI_INIT4 & LongAlgDone  |
                         ModInvState == MI_JUDGE1               |
                         ModInvState == MI_JUDGE2               |
                         ModInvState == MI_X1ADDU & LongAlgDone |
                         ModInvState == MI_X2SUBV & LongAlgDone |
                         ModInvState == MI_X1DIV2 & LongAlgDone |
                         ModInvState == MI_JUDGE3               |
                         ModInvState == MI_Y1ADDU & LongAlgDone |
                         ModInvState == MI_Y2SUBV & LongAlgDone |
                         ModInvState == MI_Y1DIV2 & LongAlgDone |
                         ModInvState == MI_X3CMPY3 & LongAlgDone|
                         ModInvState == MI_Y1SUBX1 & LongAlgDone|
                         ModInvState == MI_Y2SUBX2 & LongAlgDone|
                         ModInvState == MI_X1SUBY1 & LongAlgDone|
                         ModInvState == MI_X2SUBY2 & LongAlgDone|
                         ModInvState == MI_Y3SUB1 & LongAlgDone & ResultIsZero |
                         ModInvState == MI_JUDGE4 & LongAlgDone                |
                         ModInvState == MI_Y2ADDP & LongAlgDone & Y2IsNeg |
                         ModInvState == MI_Y2SUBP & LongAlgDone ;

assign LongAlgOp_MI    =
                         ModInvState == MI_INIT0   ? UNIT_A_SET1   :
                         ModInvState == MI_INIT1   ? UNIT_A_SET0   :
                         ModInvState == MI_INIT2   ? UNIT_A_MOV_B  :
                         ModInvState == MI_INIT3   ? UNIT_A_MOV_B  :
                         ModInvState == MI_INIT4   ? UNIT_AB_ADD_A :
                         ModInvState == MI_INIT5   ? UNIT_AB_ADD_B :
                         ModInvState == MI_X3DIV2  ? UNIT_A_SRHT_A :
                         ModInvState == MI_X1ADDU  ? UNIT_AB_ADD_A :
                         ModInvState == MI_X2SUBV  ? UNIT_AB_SUB_A :
                         ModInvState == MI_X1DIV2  ? UNIT_A_SRHT_A :
                         ModInvState == MI_X2DIV2  ? UNIT_A_SRHT_A :
                         ModInvState == MI_Y3DIV2  ? UNIT_B_SRHT_B :
                         ModInvState == MI_Y1ADDU  ? UNIT_AB_ADD_B :
                         ModInvState == MI_Y2SUBV  ? UNIT_BA_SUB_B :
                         ModInvState == MI_Y1DIV2  ? UNIT_B_SRHT_B :
                         ModInvState == MI_Y2DIV2  ? UNIT_B_SRHT_B :
                         ModInvState == MI_X3CMPY3 ? UNIT_AB_SUB_A :
                         ModInvState == MI_Y1SUBX1 ? UNIT_BA_SUB_B :
                         ModInvState == MI_Y2SUBX2 ? UNIT_BA_SUB_B :
                         ModInvState == MI_Y3SUBX3 ? UNIT_BA_SUB_B :
                         ModInvState == MI_X1SUBY1 ? UNIT_AB_SUB_A :
                         ModInvState == MI_X2SUBY2 ? UNIT_AB_SUB_A :
                         ModInvState == MI_X3SUBY3 ? UNIT_AB_SUB_A :
                         ModInvState == MI_Y3SUB1  ? UNIT_AB_SUB_A :
                         ModInvState == MI_JUDGE4  ? UNIT_BA_SUB_B :
                         ModInvState == MI_Y2ADDP  ? UNIT_AB_ADD_B :
                         ModInvState == MI_Y2SUBP  ? UNIT_BA_SUB_B :
                                                     UNIT_AB_ADD_A ;

//20221127,extended ModInv to 2048bit
assign MI_Src0_Ecc     =
                         ModInvState == MI_INIT0   ? MI_X1      :
                         ModInvState == MI_INIT1   ? MI_X2      :
                         ModInvState == MI_INIT2   ? MI_X2      :
                         ModInvState == MI_INIT3   ? MI_X1      :
                         ModInvState == MI_INIT4   ? MI_V       :
                         ModInvState == MI_INIT5   ? MI_X2      :
                         ModInvState == MI_X3DIV2  ? MI_X3      :
                         ModInvState == MI_X1ADDU  ? MI_X1      :
                         ModInvState == MI_X2SUBV  ? MI_X2      :
                         ModInvState == MI_X1DIV2  ? MI_X1      :
                         ModInvState == MI_X2DIV2  ? MI_X2      :
                         ModInvState == MI_Y3DIV2  ? MI_Y3      :
                         ModInvState == MI_Y1ADDU  ? MI_U       :
                         ModInvState == MI_Y2SUBV  ? MI_V       :
                         ModInvState == MI_Y1DIV2  ? MI_Y1      :
                         ModInvState == MI_Y2DIV2  ? MI_Y2      :
                         ModInvState == MI_X3CMPY3 ? MI_X3      :
                         ModInvState == MI_Y1SUBX1 ? MI_Y1      :
                         ModInvState == MI_Y2SUBX2 ? MI_Y2      :
                         ModInvState == MI_Y3SUBX3 ? MI_Y3      :
                         ModInvState == MI_X1SUBY1 ? MI_X1      :
                         ModInvState == MI_X2SUBY2 ? MI_X2      :
                         ModInvState == MI_X3SUBY3 ? MI_X3      :
                         ModInvState == MI_Y3SUB1  ? MI_X3      :
                         ModInvState == MI_JUDGE4  ? MI_T0      :
                         ModInvState == MI_Y2ADDP  ? MI_V       :
                         ModInvState == MI_Y2SUBP  ? MI_V       :
                                                     MI_X1      ;


assign MI_Src1_Ecc     =
                         ModInvState == MI_INIT0   ? MI_X1      :
                         ModInvState == MI_INIT1   ? MI_X2      :
                         ModInvState == MI_INIT2   ? MI_Y1      :
                         ModInvState == MI_INIT3   ? MI_Y2      :
                         ModInvState == MI_INIT4   ? MI_Y1      :
                         ModInvState == MI_INIT5   ? MI_U       :
                         ModInvState == MI_X3DIV2  ? MI_X3      :
                         ModInvState == MI_X1ADDU  ? MI_UT      :
                         ModInvState == MI_X2SUBV  ? MI_VT      :
                         ModInvState == MI_X1DIV2  ? MI_X1      :
                         ModInvState == MI_X2DIV2  ? MI_X2      :
                         ModInvState == MI_Y3DIV2  ? MI_Y3      :
                         ModInvState == MI_Y1ADDU  ? MI_Y1      :
                         ModInvState == MI_Y2SUBV  ? MI_Y2      :
                         ModInvState == MI_Y1DIV2  ? MI_Y1      :
                         ModInvState == MI_Y2DIV2  ? MI_Y2      :
                         ModInvState == MI_X3CMPY3 ? MI_Y3      :
                         ModInvState == MI_Y1SUBX1 ? MI_X1      :
                         ModInvState == MI_Y2SUBX2 ? MI_X2      :
                         ModInvState == MI_Y3SUBX3 ? MI_X3      :
                         ModInvState == MI_X1SUBY1 ? MI_Y1      :
                         ModInvState == MI_X2SUBY2 ? MI_Y2      :
                         ModInvState == MI_X3SUBY3 ? MI_Y3      :
                         ModInvState == MI_Y3SUB1  ? MI_C1      :
                         ModInvState == MI_JUDGE4  ? MI_Y2      :
                         ModInvState == MI_Y2ADDP  ? MI_Y2      :
                         ModInvState == MI_Y2SUBP  ? MI_Y2      :
                                                     MI_X1      ;


assign MI_Dst_Ecc      =
                         ModInvState == MI_INIT0   ? MI_X1      :
                         ModInvState == MI_INIT1   ? MI_X2      :
                         ModInvState == MI_INIT2   ? MI_Y1      :
                         ModInvState == MI_INIT3   ? MI_Y2      :
                         ModInvState == MI_INIT4   ? MI_X3      :
                         ModInvState == MI_INIT5   ? MI_Y3      :
                         ModInvState == MI_X3DIV2  ? MI_X3      :
                         ModInvState == MI_X1ADDU  ? MI_X1      :
                         ModInvState == MI_X2SUBV  ? MI_X2      :
                         ModInvState == MI_X1DIV2  ? MI_X1      :
                         ModInvState == MI_X2DIV2  ? MI_X2      :
                         ModInvState == MI_Y3DIV2  ? MI_Y3      :
                         ModInvState == MI_Y1ADDU  ? MI_Y1      :
                         ModInvState == MI_Y2SUBV  ? MI_Y2      :
                         ModInvState == MI_Y1DIV2  ? MI_Y1      :
                         ModInvState == MI_Y2DIV2  ? MI_Y2      :
                         ModInvState == MI_X3CMPY3 ? MI_T0      :
                         ModInvState == MI_Y1SUBX1 ? MI_Y1      :
                         ModInvState == MI_Y2SUBX2 ? MI_Y2      :
                         ModInvState == MI_Y3SUBX3 ? MI_Y3      :
                         ModInvState == MI_X1SUBY1 ? MI_X1      :
                         ModInvState == MI_X2SUBY2 ? MI_X2      :
                         ModInvState == MI_X3SUBY3 ? MI_X3      :
                         ModInvState == MI_Y3SUB1  ? MI_X3      :
                         ModInvState == MI_JUDGE4  ? MI_Y2      :
                         ModInvState == MI_Y2ADDP  ? MI_Y2      :
                         ModInvState == MI_Y2SUBP  ? MI_Y2      :
                                                     MI_X1      ;
//20221127
assign MI_Src0_Rsa     =
                         ModInvState == MI_INIT0   ? 9'hC6	: //MI_X1      :8'h66
                         ModInvState == MI_INIT1   ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_INIT2   ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_INIT3   ? 9'hC6	: //MI_X1      :8'h66
                         ModInvState == MI_INIT4   ? 9'h42	: //MI_V       :8'h22
                         ModInvState == MI_INIT5   ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_X3DIV2  ? 9'h14A	: //MI_X3      :8'haa
                         ModInvState == MI_X1ADDU  ? 9'hC6	: //MI_X1      :8'h66
                         ModInvState == MI_X2SUBV  ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_X1DIV2  ? 9'hC6	: //MI_X1      :8'h66
                         ModInvState == MI_X2DIV2  ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_Y3DIV2  ? 9'h14A	: //MI_Y3      :8'haa
                         ModInvState == MI_Y1ADDU  ? 9'h00	: //MI_U       :8'h00
                         ModInvState == MI_Y2SUBV  ? 9'h42	: //MI_V       :8'h22
                         ModInvState == MI_Y1DIV2  ? 9'hC6	: //MI_Y1      :8'h66
                         ModInvState == MI_Y2DIV2  ? 9'h108	: //MI_Y2      :8'h88
                         ModInvState == MI_X3CMPY3 ? 9'h14A	: //MI_X3      :8'haa
                         ModInvState == MI_Y1SUBX1 ? 9'hC6	: //MI_Y1      :8'h66
                         ModInvState == MI_Y2SUBX2 ? 9'h108	: //MI_Y2      :8'h88
                         ModInvState == MI_Y3SUBX3 ? 9'h14A	: //MI_Y3      :8'haa
                         ModInvState == MI_X1SUBY1 ? 9'hC6	: //MI_X1      :8'h66
                         ModInvState == MI_X2SUBY2 ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_X3SUBY3 ? 9'h14A	: //MI_X3      :8'haa
                         ModInvState == MI_Y3SUB1  ? 9'h14A	: //MI_X3      :8'haa
                         ModInvState == MI_JUDGE4  ? 9'h18C	: //MI_T0      :8'hcc
                         ModInvState == MI_Y2ADDP  ? 9'h42	: //MI_V       :8'h22
                         ModInvState == MI_Y2SUBP  ? 9'h42	: //MI_V       :8'h22
                                                     9'hC6	; //MI_X1      ;8'h66


assign MI_Src1_Rsa     =
                         ModInvState == MI_INIT0   ? 9'hC6	: //MI_X1      : 8'h66
                         ModInvState == MI_INIT1   ? 9'h108	: //MI_X2      : 8'h88
                         ModInvState == MI_INIT2   ? 9'hC6	: //MI_Y1      : 8'h66
                         ModInvState == MI_INIT3   ? 9'h108	: //MI_Y2      : 8'h88
                         ModInvState == MI_INIT4   ? 9'hC6	: //MI_Y1      : 8'h66
                         ModInvState == MI_INIT5   ? 9'h00	: //MI_U       : 8'h00
                         ModInvState == MI_X3DIV2  ? 9'h14A	: //MI_X3      : 8'haa
                         ModInvState == MI_X1ADDU  ? 9'h00	: //MI_UT      : 8'h00
                         ModInvState == MI_X2SUBV  ? 9'h42	: //MI_VT      : 8'h22
                         ModInvState == MI_X1DIV2  ? 9'hC6	: //MI_X1      : 8'h66
                         ModInvState == MI_X2DIV2  ? 9'h108	: //MI_X2      : 8'h88
                         ModInvState == MI_Y3DIV2  ? 9'h14A	: //MI_Y3      : 8'haa
                         ModInvState == MI_Y1ADDU  ? 9'hC6	: //MI_Y1      : 8'h66
                         ModInvState == MI_Y2SUBV  ? 9'h108	: //MI_Y2      : 8'h88
                         ModInvState == MI_Y1DIV2  ? 9'hC6	: //MI_Y1      : 8'h66
                         ModInvState == MI_Y2DIV2  ? 9'h108	: //MI_Y2      : 8'h88
                         ModInvState == MI_X3CMPY3 ? 9'h14A	: //MI_Y3      : 8'haa
                         ModInvState == MI_Y1SUBX1 ? 9'hC6	: //MI_X1      : 8'h66
                         ModInvState == MI_Y2SUBX2 ? 9'h108	: //MI_X2      : 8'h88
                         ModInvState == MI_Y3SUBX3 ? 9'h14A	: //MI_X3      : 8'haa
                         ModInvState == MI_X1SUBY1 ? 9'hC6	: //MI_Y1      : 8'h66
                         ModInvState == MI_X2SUBY2 ? 9'h108	: //MI_Y2      : 8'h88
                         ModInvState == MI_X3SUBY3 ? 9'h14A	: //MI_Y3      : 8'haa
                         ModInvState == MI_Y3SUB1  ? 9'h84	: //MI_C1      : 8'h44
                         ModInvState == MI_JUDGE4  ? 9'h108	: //MI_Y2      : 8'h88
                         ModInvState == MI_Y2ADDP  ? 9'h108	: //MI_Y2      : 8'h88
                         ModInvState == MI_Y2SUBP  ? 9'h108	: //MI_Y2      : 8'h88
                                                     9'hC6	; //MI_X1      ; 8'h66


assign MI_Dst_Rsa      =
                         ModInvState == MI_INIT0   ? 9'hC6	: //MI_X1      :8'h66
                         ModInvState == MI_INIT1   ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_INIT2   ? 9'hC6	: //MI_Y1      :8'h66
                         ModInvState == MI_INIT3   ? 9'h108	: //MI_Y2      :8'h88
                         ModInvState == MI_INIT4   ? 9'h14A	: //MI_X3      :8'haa
                         ModInvState == MI_INIT5   ? 9'h14A	: //MI_Y3      :8'haa
                         ModInvState == MI_X3DIV2  ? 9'h14A	: //MI_X3      :8'haa
                         ModInvState == MI_X1ADDU  ? 9'hC6	: //MI_X1      :8'h66
                         ModInvState == MI_X2SUBV  ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_X1DIV2  ? 9'hC6	: //MI_X1      :8'h66
                         ModInvState == MI_X2DIV2  ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_Y3DIV2  ? 9'h14A	: //MI_Y3      :8'haa
                         ModInvState == MI_Y1ADDU  ? 9'hC6	: //MI_Y1      :8'h66
                         ModInvState == MI_Y2SUBV  ? 9'h108	: //MI_Y2      :8'h88
                         ModInvState == MI_Y1DIV2  ? 9'hC6	: //MI_Y1      :8'h66
                         ModInvState == MI_Y2DIV2  ? 9'h108	: //MI_Y2      :8'h88
                         ModInvState == MI_X3CMPY3 ? 9'h18C	: //MI_T0      :8'hcc
                         ModInvState == MI_Y1SUBX1 ? 9'hC6	: //MI_Y1      :8'h66
                         ModInvState == MI_Y2SUBX2 ? 9'h108	: //MI_Y2      :8'h88
                         ModInvState == MI_Y3SUBX3 ? 9'h14A	: //MI_Y3      :8'haa
                         ModInvState == MI_X1SUBY1 ? 9'hC6	: //MI_X1      :8'h66
                         ModInvState == MI_X2SUBY2 ? 9'h108	: //MI_X2      :8'h88
                         ModInvState == MI_X3SUBY3 ? 9'h14A	: //MI_X3      :8'haa
                         ModInvState == MI_Y3SUB1  ? 9'h14A	: //MI_X3      :8'haa
                         ModInvState == MI_JUDGE4  ? 9'h108	: //MI_Y2      :8'h88
                         ModInvState == MI_Y2ADDP  ? 9'h108	: //MI_Y2      :8'h88
                         ModInvState == MI_Y2SUBP  ? 9'h108	: //MI_Y2      :8'h88
                                                     9'hC6	; //MI_X1      ;8'h66


assign MI_Src0  = EccModInv1 ? {1'b0,MI_Src0_Ecc} :
                  RsaModInv ? MI_Src0_Rsa :
                              9'h00       ;

assign MI_Src1  = EccModInv1 ? {1'b0,MI_Src1_Ecc} :
                  RsaModInv ? MI_Src1_Rsa :
                              9'h00       ;

assign MI_Dst   = EccModInv1 ? {1'b0,MI_Dst_Ecc}  :
                  RsaModInv ? MI_Dst_Rsa  :
                              9'h00       ;

//20221127,extended ModInv to 2048bit

always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        ModInvCnt <= 16'h000;
    else
        ModInvCnt <= NextModInvCnt;

assign NextModInvCnt = StartModInv                 ? 16'h000       :
                       (ModInvState == MI_JUDGE1)  ? ModInvCnt + 1 :
                                                     ModInvCnt     ;

//assign ErrorDetect = (ModInvCnt >= 12'd2048);
//assign ErrorDetect = (ModInvCnt >= 16'd8192); //20230317
assign ErrorDetect = (ModInvCnt >= 16'd32768);

//end,20221127

always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        PointAddState <= PA_IDLE;
    else
        PointAddState <= NextPointAddState;
always @(*)
case(PointAddState)
    PA_IDLE:
    begin
        if(StartPointAdd)
            NextPointAddState = PA_S1;
        else
            NextPointAddState = PointAddState;
    end
    PA_S1:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S2;
        else
            NextPointAddState = PointAddState;
    end
    PA_S2:
    begin
        if(MpcDone)
            NextPointAddState = PA_S3;
        else
            NextPointAddState = PointAddState;
    end
    PA_S3:
    begin
        if(MpcDone)
            NextPointAddState = PA_S4;
        else
            NextPointAddState = PointAddState;
    end
    PA_S4:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S5;
        else
            NextPointAddState = PointAddState;
    end
    PA_S5:
    begin
        if(MpcDone)
            NextPointAddState = PA_S6;
        else
            NextPointAddState = PointAddState;
    end
    PA_S6:
    begin
        if(MpcDone)
            NextPointAddState = PA_S7;
        else
            NextPointAddState = PointAddState;
    end
    PA_S7:
    begin
        if(ModSubDone)
            NextPointAddState = PA_S8;
        else
            NextPointAddState = PointAddState;
    end
    PA_S8:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S9;
        else
            NextPointAddState = PointAddState;
    end
    PA_S9:
    begin
        if(MpcDone)
            NextPointAddState = PA_S10;
        else
            NextPointAddState = PointAddState;
    end
    PA_S10:
    begin
        if(MpcDone)
            NextPointAddState = PA_S11;
        else
            NextPointAddState = PointAddState;
    end
    PA_S11:
    begin
        if(MpcDone)
            NextPointAddState = PA_S12;
        else
            NextPointAddState = PointAddState;
    end
    PA_S12:
    begin
        if(MpcDone)
            NextPointAddState = PA_S13;
        else
            NextPointAddState = PointAddState;
    end
    PA_S13:
    begin
        if(ModSubDone)
            NextPointAddState = PA_S14;
        else
            NextPointAddState = PointAddState;
    end
    PA_S14:
    begin
        if(ModAddDone)
            NextPointAddState = PA_S15;
        else
            NextPointAddState = PointAddState;
    end
    PA_S15:
    begin
        if(ModAddDone)
            NextPointAddState = PA_S16;
        else
            NextPointAddState = PointAddState;
    end
    PA_S16:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S17;
        else
            NextPointAddState = PointAddState;
    end
    PA_S17:
    begin
        if(MpcDone)
            NextPointAddState = PA_S18;
        else
            NextPointAddState = PointAddState;
    end
    PA_S18:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S19;
        else
            NextPointAddState = PointAddState;
    end
    PA_S19:
    begin
        if(MpcDone)
            NextPointAddState = PA_S20;
        else
            NextPointAddState = PointAddState;
    end
    PA_S20:
    begin
        if(MpcDone)
            NextPointAddState = PA_S21;
        else
            NextPointAddState = PointAddState;
    end
    PA_S21:
    begin
        if(ModSubDone)
            NextPointAddState = PA_S22;
        else
            NextPointAddState = PointAddState;
    end
    PA_S22:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S23;
        else
            NextPointAddState = PointAddState;
    end
    PA_S23:
    begin
        if(ModAddDone)
            NextPointAddState = PA_S24;
        else
            NextPointAddState = PointAddState;
    end
    PA_S24:
    begin
        if(ModSubDone)
            NextPointAddState = PA_S25;
        else
            NextPointAddState = PointAddState;
    end
    PA_S25:
    begin
        if(MpcDone)
            NextPointAddState = PA_S26;
        else
            NextPointAddState = PointAddState;
    end
    PA_S26:
    begin
        if(MpcDone)
            NextPointAddState = PA_S27;
        else
            NextPointAddState = PointAddState;
    end
    PA_S27:
    begin
        if(MpcDone)
            NextPointAddState = PA_S28;
        else
            NextPointAddState = PointAddState;
    end
    PA_S28:
    begin
        if(ModSubDone & ~LongAlgSR[2])
            NextPointAddState = PA_S29;
        else if(ModSubDone)
            NextPointAddState = PA_S30;
        else
            NextPointAddState = PointAddState;
    end
    PA_S29:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S31;
        else
            NextPointAddState = PointAddState;
    end
    PA_S30:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S29;
        else
            NextPointAddState = PointAddState;
    end
    PA_S31:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S32;
        else
            NextPointAddState = PointAddState;
    end
    PA_S32:
    begin
        if(MpcDone)
            NextPointAddState = PA_S33;
        else
            NextPointAddState = PointAddState;
    end
    PA_S33:
    begin
        if(LongAlgDone)
            NextPointAddState = PA_S34;
        else
            NextPointAddState = PointAddState;
    end
    PA_S34:
    begin
        if(MpcDone)
            NextPointAddState = PA_END;
        else
            NextPointAddState = PointAddState;
    end
    PA_END:
    begin
            NextPointAddState = PA_IDLE;
    end
    default:
    begin
            NextPointAddState = PA_IDLE;
    end
endcase

assign EccPointAddDone    = PointAddState == PA_END;

assign StartMpc_PA     =
                         (PointAddState == PA_S1) & LongAlgDone     |
                         (PointAddState == PA_S2) & MpcDone         |
                         (PointAddState == PA_S4) & LongAlgDone     |
                         (PointAddState == PA_S5) & MpcDone         |
                         (PointAddState == PA_S8) & LongAlgDone     |
                         (PointAddState == PA_S9) & MpcDone         |
                         (PointAddState == PA_S10)& MpcDone         |
                         (PointAddState == PA_S11)& MpcDone         |
                         (PointAddState == PA_S16)& LongAlgDone     |
                         (PointAddState == PA_S18)& LongAlgDone     |
                         (PointAddState == PA_S19)& MpcDone         |
                         (PointAddState == PA_S24)& ModSubDone      |
                         (PointAddState == PA_S25)& MpcDone         |
                         (PointAddState == PA_S26)& MpcDone         |
                         (PointAddState == PA_S31)& LongAlgDone     |
                         (PointAddState == PA_S33)& LongAlgDone     ;


assign StartModAdd_PA  =
                         (PointAddState == PA_S13)& ModSubDone      |
                         (PointAddState == PA_S14)& ModAddDone      |
                         (PointAddState == PA_S22)& LongAlgDone     ;


assign StartModSub_PA  =
                         (PointAddState == PA_S6) & MpcDone         |
                         (PointAddState == PA_S12)& MpcDone         |
                         (PointAddState == PA_S20)& MpcDone         |
                         (PointAddState == PA_S23)& ModAddDone      |
                         (PointAddState == PA_S27)& MpcDone         ;

assign LongAlgOp_PA    =
                         (PointAddState == PA_S1) ? UNIT_B_MOV_A    :
                         (PointAddState == PA_S4) ? UNIT_A_MOV_B    :
                         (PointAddState == PA_S8) ? UNIT_B_MOV_A    :
                         (PointAddState == PA_S16)? UNIT_B_MOV_A    :
                         (PointAddState == PA_S18)? UNIT_A_MOV_B    :
                         (PointAddState == PA_S22)? UNIT_A_MOV_B    :
                         (PointAddState == PA_S31)? UNIT_A_MOV_B    :
                         (PointAddState == PA_S29)? UNIT_B_RHT_B    :
                         (PointAddState == PA_S30)? UNIT_BB_ADD_A   :
                         (PointAddState == PA_S33)? UNIT_B_MOV_A    :
                                                    UNIT_AB_ADD_A   ;

assign LongAlgStart_PA =
                         (PointAddState == PA_IDLE) & StartPointAdd |
                         (PointAddState == PA_S3  ) & MpcDone       |
                         (PointAddState == PA_S7  ) & ModSubDone    |
                         (PointAddState == PA_S15 ) & ModAddDone    |
                         (PointAddState == PA_S17 ) & MpcDone       |
                         (PointAddState == PA_S21 ) & ModSubDone    |
                         (PointAddState == PA_S28 ) & ModSubDone & ~LongAlgSR[2]    |
                         (PointAddState == PA_S29 ) & LongAlgDone   |
                         (PointAddState == PA_S30 ) & LongAlgDone   |
                         (PointAddState == PA_S28 ) & ModSubDone & LongAlgSR[2]     |
                         (PointAddState == PA_S32 ) & MpcDone       ;

assign PointEn_PA     =
                         (PointAddState == PA_S2  ) ? 1'b1 :
                         (PointAddState == PA_S5  ) ? 1'b1 :
                         (PointAddState == PA_S6  ) ? 1'b1 :
                         (PointAddState == PA_S12 ) ? 1'b1 :
                         (PointAddState == PA_S13 ) ? 1'b1 :
                         (PointAddState == PA_S19 ) ? 1'b1 :
                         (PointAddState == PA_S20 ) ? 1'b1 :
                         (PointAddState == PA_S26 ) ? 1'b1 :
                         (PointAddState == PA_S27 ) ? 1'b1 :
                         (PointAddState == PA_S28 ) ? 1'b1 :
                         (PointAddState == PA_S32 ) ? 1'b1 :
                                                      1'b0 ;


always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        PointDblState <= PD_IDLE;
    else
        PointDblState <= NextPointDblState;
always @(*)
case(PointDblState)
    PD_IDLE:
    begin
        if(StartPointDbl)
            NextPointDblState = PD_S1;
        else
            NextPointDblState = PointDblState;
    end
    PD_S1:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S2;
        else
            NextPointDblState = PointDblState;
    end
    PD_S2:
    begin
        if(MpcDone)
            NextPointDblState = PD_S3;
        else
            NextPointDblState = PointDblState;
    end
    PD_S3:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S4;
        else
            NextPointDblState = PointDblState;
    end
    PD_S4:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S5;
        else
            NextPointDblState = PointDblState;
    end
    PD_S5:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S6;
        else
            NextPointDblState = PointDblState;
    end
    PD_S6:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S7;
        else
            NextPointDblState = PointDblState;
    end
    PD_S7:
    begin
        if(MpcDone)
            NextPointDblState = PD_S8;
        else
            NextPointDblState = PointDblState;
    end
    PD_S8:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S9;
        else
            NextPointDblState = PointDblState;
    end
    PD_S9:
    begin
        if(MpcDone)
            NextPointDblState = PD_S10;
        else
            NextPointDblState = PointDblState;
    end
    PD_S10:
    begin
        if(MpcDone)
            NextPointDblState = PD_S11;
        else
            NextPointDblState = PointDblState;
    end
    PD_S11:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S12;
        else
            NextPointDblState = PointDblState;
    end
    PD_S12:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S13;
        else
            NextPointDblState = PointDblState;
    end
    PD_S13:
    begin
        if(MpcDone)
            NextPointDblState = PD_S14;
        else
            NextPointDblState = PointDblState;
    end
    PD_S14:
    begin
        if(MpcDone)
            NextPointDblState = PD_S15;
        else
            NextPointDblState = PointDblState;
    end
    PD_S15:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S16;
        else
            NextPointDblState = PointDblState;
    end
    PD_S16:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S17;
        else
            NextPointDblState = PointDblState;
    end
    PD_S17:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S18;
        else
            NextPointDblState = PointDblState;
    end
    PD_S18:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S19;
        else
            NextPointDblState = PointDblState;
    end
    PD_S19:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S20;
        else
            NextPointDblState = PointDblState;
    end
    PD_S20:
    begin
        if(MpcDone)
            NextPointDblState = PD_S21;
        else
            NextPointDblState = PointDblState;
    end
    PD_S21:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S22;
        else
            NextPointDblState = PointDblState;
    end
    PD_S22:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S23;
        else
            NextPointDblState = PointDblState;
    end
    PD_S23:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S24;
        else
            NextPointDblState = PointDblState;
    end
    PD_S24:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S25;
        else
            NextPointDblState = PointDblState;
    end
    PD_S25:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S26;
        else
            NextPointDblState = PointDblState;
    end
    PD_S26:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S27;
        else
            NextPointDblState = PointDblState;
    end
    PD_S27:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S28;
        else
            NextPointDblState = PointDblState;
    end
    PD_S28:
    begin
        if(MpcDone)
            NextPointDblState = PD_S29;
        else
            NextPointDblState = PointDblState;
    end
    PD_S29:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S30;
        else
            NextPointDblState = PointDblState;
    end
    PD_S30:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S31;
        else
            NextPointDblState = PointDblState;
    end
    PD_S31:
    begin
        if(ModSubDone)
            NextPointDblState = PD_S32;
        else
            NextPointDblState = PointDblState;
    end
    PD_S32:
    begin
        if(ModSubDone)
            NextPointDblState = PD_S33;
        else
            NextPointDblState = PointDblState;
    end
    PD_S33:
    begin
        if(MpcDone)
            NextPointDblState = PD_S35;
        else
            NextPointDblState = PointDblState;
    end
    PD_S34:
    begin
        if(ModSubDone)
            NextPointDblState = PD_S36;
        else
            NextPointDblState = PointDblState;
    end
    PD_S35:
    begin
        if(MpcDone)
            NextPointDblState = PD_S34;
        else
            NextPointDblState = PointDblState;
    end
    PD_S36:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_S37;
        else
            NextPointDblState = PointDblState;
    end
    PD_S37:
    begin
        if(ModAddDone)
            NextPointDblState = PD_S38;
        else
            NextPointDblState = PointDblState;
    end
    PD_S38:
    begin
        if(LongAlgDone)
            NextPointDblState = PD_END;
        else
            NextPointDblState = PointDblState;
    end
    PD_END:
    begin
            NextPointDblState = PD_IDLE;
    end
    default:
    begin
            NextPointDblState = PD_IDLE;
    end
endcase

assign EccPointDblDone = PointDblState == PD_END;

assign StartMpc_PD     =
                         (PointDblState == PD_S1 ) & LongAlgDone    |
                         (PointDblState == PD_S6 ) & LongAlgDone    |
                         (PointDblState == PD_S8 ) & LongAlgDone    |
                         (PointDblState == PD_S9 ) & MpcDone        |
                         (PointDblState == PD_S12) & LongAlgDone    |
                         (PointDblState == PD_S13) & MpcDone        |
                         (PointDblState == PD_S19) & LongAlgDone    |
                         (PointDblState == PD_S27) & LongAlgDone    |
                         (PointDblState == PD_S32) & ModSubDone     |
                         (PointDblState == PD_S33) & MpcDone        ;

assign StartModAdd_PD  =
                         (PointDblState == PD_S3 ) & LongAlgDone    |
                         (PointDblState == PD_S4 ) & ModAddDone     |
                         (PointDblState == PD_S10) & MpcDone        |
                         (PointDblState == PD_S15) & LongAlgDone    |
                         (PointDblState == PD_S17) & LongAlgDone    |
                         (PointDblState == PD_S21) & LongAlgDone    |
                         (PointDblState == PD_S23) & LongAlgDone    |
                         (PointDblState == PD_S25) & LongAlgDone    |
                         (PointDblState == PD_S29) & LongAlgDone    |
                         (PointDblState == PD_S36) & LongAlgDone    ;

assign StartModSub_PD  =
                         (PointDblState == PD_S30) & ModAddDone     |
                         (PointDblState == PD_S31) & ModSubDone     |
                         (PointDblState == PD_S35) & MpcDone        ;


assign LongAlgOp_PD    =
                         (PointDblState == PD_S1 ) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S3 ) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S6 ) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S8 ) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S12) ?    UNIT_B_MOV_A    :
                         (PointDblState == PD_S15) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S17) ?    UNIT_B_MOV_A    :
                         (PointDblState == PD_S19) ?    UNIT_B_MOV_A    :
                         (PointDblState == PD_S21) ?    UNIT_B_MOV_A    :
                         (PointDblState == PD_S23) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S25) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S27) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S29) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S36) ?    UNIT_A_MOV_B    :
                         (PointDblState == PD_S38) ?    UNIT_B_MOV_A    :
                                                        UNIT_AB_ADD_A   ;

assign LongAlgStart_PD =
                         (PointDblState == PD_IDLE) & StartPointDbl |
                         (PointDblState == PD_S2 ) & MpcDone        |
                         (PointDblState == PD_S5 ) & ModAddDone     |
                         (PointDblState == PD_S7 ) & MpcDone        |
                         (PointDblState == PD_S11) & ModAddDone     |
                         (PointDblState == PD_S14) & MpcDone        |
                         (PointDblState == PD_S16) & ModAddDone     |
                         (PointDblState == PD_S18) & ModAddDone     |
                         (PointDblState == PD_S20) & MpcDone        |
                         (PointDblState == PD_S22) & ModAddDone     |
                         (PointDblState == PD_S24) & ModAddDone     |
                         (PointDblState == PD_S26) & ModAddDone     |
                         (PointDblState == PD_S28) & MpcDone        |
                         (PointDblState == PD_S34) & ModSubDone     |
                         (PointDblState == PD_S37) & ModAddDone     ;

assign PointEn_PD     =
                         (PointDblState == PD_S4 ) ? 1'b1  :
                         (PointDblState == PD_S9 ) ? 1'b1  :
                         (PointDblState == PD_S10) ? 1'b1  :
                         (PointDblState == PD_S13) ? 1'b1  :
                         (PointDblState == PD_S16) ? 1'b1  :
                         (PointDblState == PD_S20) ? 1'b1  :
                         (PointDblState == PD_S26) ? 1'b1  :
                         (PointDblState == PD_S30) ? 1'b1  :
                         (PointDblState == PD_S31) ? 1'b1  :
                         (PointDblState == PD_S32) ? 1'b1  :
                         (PointDblState == PD_S34) ? 1'b1  :
                                                     1'b0  ;


//EdI2M
always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        EdI2MState <= EDI2M_IDLE;
    else
        EdI2MState <= NextEdI2MState;

always @(*)
case(EdI2MState)
    EDI2M_IDLE:
    begin
        if(StartEdI2M)
            NextEdI2MState = EDI2M_MOVH;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MOVH:   			//CP(H,TP0)
    begin
        if(LongAlgDone)
            NextEdI2MState = EDI2M_MMQ0XH;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ0XH:			//MM(X,H)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MMQ0YH;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ0YH:			//MM(TP0,Y)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MMQ0ZH;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ0ZH:             		//MM(Z,H)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MOVZ;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MOVZ:   			//CP(Z,TP1)
    begin
        if(LongAlgDone)
            NextEdI2MState = EDI2M_MMQ0XZ;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ0XZ:  			//X=MM(X,TP1)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MMQ0XY;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ0XY:  			//T=MM(X,Y) ==X*Y*Z
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MMQ0YZ;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ0YZ: 			//Y=MM(Y,Z)
    begin
        if(MpcDone & EdI2MA)
            NextEdI2MState = EDI2M_MMQ1XH;
        else if(MpcDone & EdI2MD)
            NextEdI2MState = EDI2M_MMAH;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ1XH:			//MM(Q1X,H)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MMQ1YH;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ1YH:			//MM(TP0,Q1Y)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MMQ1ZH;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ1ZH:  			//Z=MM(TP0, Q1Z)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MOVZ1;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MOVZ1:   			//CP(Z,TP0)
    begin
        if(LongAlgDone)
            NextEdI2MState = EDI2M_MMQ1XZ;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ1XZ:  			//X1=MM(X1,Z)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MMQ1XY;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ1XY:  			//T=MM(X,Y) ==X*Y*Z
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MMQ1YZ;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMQ1YZ:  			//Y=MM(Y,Z)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_MMAH;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_MMAH:    			//D=Mont(d,H)
    begin
        if(MpcDone)
            NextEdI2MState = EDI2M_END;
        else
            NextEdI2MState = EdI2MState;
    end
    EDI2M_END:
    begin
            NextEdI2MState = EDI2M_IDLE;
    end
    default:
            NextEdI2MState = EDI2M_IDLE;
endcase

assign EdI2MDone = EdI2MState == EDI2M_END;

assign StartMpc_EDI2M     =
                             (EdI2MState == EDI2M_MOVH)   & LongAlgDone |
                             (EdI2MState == EDI2M_MMQ0XH) & MpcDone     |
                             (EdI2MState == EDI2M_MMQ0YH) & MpcDone     |
                             (EdI2MState == EDI2M_MOVZ)   & LongAlgDone |
                             (EdI2MState == EDI2M_MMQ0XZ) & MpcDone     |
                             (EdI2MState == EDI2M_MMQ0XY) & MpcDone     |
                             (EdI2MState == EDI2M_MMQ0YZ) & MpcDone     |
                             (EdI2MState == EDI2M_MMQ1XH) & MpcDone     |
                             (EdI2MState == EDI2M_MMQ1YH) & MpcDone     |
                             (EdI2MState == EDI2M_MOVZ1)  & LongAlgDone |
                             (EdI2MState == EDI2M_MMQ1XZ) & MpcDone     |
                             (EdI2MState == EDI2M_MMQ1XY) & MpcDone     |
                             (EdI2MState == EDI2M_MMQ1YZ) & MpcDone     ;

assign LongAlgStart_EDI2M =  (EdI2MState == EDI2M_IDLE)   & StartEdI2M |
                             (EdI2MState == EDI2M_MMQ0ZH) & MpcDone    |
                             (EdI2MState == EDI2M_MMQ1ZH) & MpcDone    ;

assign LongAlgOp_EDI2M    =  (EdI2MState == EDI2M_MOVH) ? UNIT_B_MOV_A :
                             (EdI2MState == EDI2M_MOVZ) ? UNIT_A_MOV_B :
                             (EdI2MState == EDI2M_MOVZ1)? UNIT_B_MOV_A :
                                                          6'd0;
assign PointEn_EDI2M      =
                             (EdI2MState == EDI2M_MMQ0YH) ? 1'b1 :   //Y0
                             (EdI2MState == EDI2M_MMQ0YZ) ? 1'b1 :   //Y0
                             (EdI2MState == EDI2M_MMQ1YH) ? 1'b1 :   //Y1
                             (EdI2MState == EDI2M_MMQ1YZ) ? 1'b1 :   //Y1
                             (EdI2MState == EDI2M_MMQ1ZH) ? 1'b1 :   //Z1
                             (EdI2MState == EDI2M_MMQ1XY) ? 1'b1 :   //T1
                                                            1'b0 ;

//EdM2I State Machine
 always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        EdM2IState <= EDM2I_IDLE;
    else
        EdM2IState <= NextEdM2IState;
always @(*)
case(EdM2IState)
    EDM2I_IDLE:
    begin
        if(StartEdM2I)
            NextEdM2IState = EDM2I_MMZ1;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_MMZ1:
    begin
        if(MpcDone)
            NextEdM2IState = EDM2I_MOVZ2UT;
        else
            NextEdM2IState = EdM2IState;
    end

    EDM2I_MOVZ2UT:
    begin
        if(LongAlgDone)
            NextEdM2IState = EDM2I_MOVUT2U;
        else
            NextEdM2IState = EdM2IState;
    end

    EDM2I_MOVUT2U:
    begin
        if(LongAlgDone)
            NextEdM2IState = EDM2I_MODINVZ;
        else
            NextEdM2IState = EdM2IState;
    end

    EDM2I_MODINVZ:
    begin
        if(ModInvDone)
            NextEdM2IState = EDM2I_MOVZ2TP0;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_MOVZ2TP0:
    begin
        if(LongAlgDone)
            NextEdM2IState = EDM2I_MMZH;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_MMZH:
    begin
        if(MpcDone )
            NextEdM2IState = EDM2I_MOVZ2TP1;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_MOVZ2TP1:
    begin
        if(LongAlgDone)
            NextEdM2IState = EDM2I_MMXZ;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_MMXZ:
    begin
        if(MpcDone)
            NextEdM2IState = EDM2I_MMYZ;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_MMYZ:
    begin
        if(MpcDone)
            NextEdM2IState = EDM2I_MMX1;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_MMX1:
    begin
        if(MpcDone)
            NextEdM2IState = EDM2I_MOVY2TP0;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_MOVY2TP0:
    begin
        if(LongAlgDone)
            NextEdM2IState = EDM2I_MMY1;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_MMY1:
    begin
        if(MpcDone)
            NextEdM2IState = EDM2I_END;
        else
            NextEdM2IState = EdM2IState;
    end
    EDM2I_END:
    begin
            NextEdM2IState = EDM2I_IDLE;
    end
    default:
            NextEdM2IState = EDM2I_IDLE;
endcase

assign EdM2IDone = EdM2IState == EDM2I_END;

assign StartMpc_EDM2I     =
                           (EdM2IState == EDM2I_IDLE )    & StartEdM2I  |
                           (EdM2IState == EDM2I_MOVZ2TP0) & LongAlgDone |
                           (EdM2IState == EDM2I_MOVZ2TP1) & LongAlgDone |
                           (EdM2IState == EDM2I_MMXZ )    & MpcDone     |
                           (EdM2IState == EDM2I_MMYZ )    & MpcDone     |
                           (EdM2IState == EDM2I_MOVY2TP0) & LongAlgDone ;

assign LongAlgStart_EDM2I =
                           (EdM2IState == EDM2I_MMZ1)    & MpcDone     |
                           (EdM2IState == EDM2I_MODINVZ) & ModInvDone  |
                           (EdM2IState == EDM2I_MMZH)    & MpcDone     |
                           (EdM2IState == EDM2I_MMX1)    & MpcDone     |
                           (EdM2IState == EDM2I_MOVZ2UT) & LongAlgDone ;

assign StartModInv_EDM2I  = (EdM2IState == EDM2I_MOVUT2U) & LongAlgDone ;

assign LongAlgOp_EDM2I    =
                          (EdM2IState == EDM2I_MOVZ2UT ) ? UNIT_A_MOV_B :
                          (EdM2IState == EDM2I_MOVUT2U ) ? UNIT_B_MOV_A :
                          (EdM2IState == EDM2I_MOVZ2TP1) ? UNIT_A_MOV_B :
                          (EdM2IState == EDM2I_MOVZ2TP0) ? UNIT_B_MOV_A :
                          (EdM2IState == EDM2I_MOVY2TP0) ? UNIT_B_MOV_A :
                                                            6'd0        ;

assign PointEn_EDM2I      =
                          //(EdM2IState == EDM2I_MOVZ2UT)  ? 1'b1 :
                          //(EdM2IState == EDM2I_MOVZ2TP1) ? 1'b1 :
                          (EdM2IState == EDM2I_MMYZ)     ? 1'b1 :
                          (EdM2IState == EDM2I_MMY1)     ? 1'b1 :
                                                           1'b0 ;

//assign StartModInv     = EccStartModInv | StartModInv_M2I;

//EdPointAdd State
always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        EdPointAddState <= EDPA_IDLE;
    else
        EdPointAddState <= NextEdPointAddState;
always @(*)
case(EdPointAddState)
    EDPA_IDLE:
    begin
        if(StartEdPointAdd)
            NextEdPointAddState = EDPA_S1;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S1:               			//A1=Y1-X1
    begin
        if(ModSubDone)
            NextEdPointAddState = EDPA_S2;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S2:                     		//A2=Y2-X2
    begin
        if(ModSubDone)
            NextEdPointAddState = EDPA_S3;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S3:					//A3=A1*A2
    begin
        if(MpcDone)
            NextEdPointAddState = EDPA_S4;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S4:                			//B1=Y1+X1
    begin
        if(ModAddDone)
            NextEdPointAddState = EDPA_S5;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S5:              			//B2=Y2+X2
    begin
        if(ModAddDone)
            NextEdPointAddState = EDPA_S6;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S6:      				//B3=B1*B2
    begin
        if(MpcDone)
            NextEdPointAddState = EDPA_S7;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S7:  					//C1=T1*T2
    begin
        if(MpcDone)
            NextEdPointAddState = EDPA_S21;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S21:      				//MOV A/D to TEMP1
    begin
        if(LongAlgDone)
            NextEdPointAddState = EDPA_S8;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S8:      				//C2=A +TP1
    begin
        if(ModAddDone)
            NextEdPointAddState = EDPA_S9;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S9:                 			//C3=C1*C2
    begin
        if(MpcDone)
            NextEdPointAddState = EDPA_S10;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S10:        				//D1=Z1*Z2, Mov D1 to TEMP1
    begin
        if(MpcDone)
            NextEdPointAddState = EDPA_S20;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S11:           			//D2=D1+D1
    begin
        if(ModAddDone)
            NextEdPointAddState = EDPA_S12;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S12:     				//E=B3-A3
    begin
        if(ModSubDone)
            NextEdPointAddState = EDPA_S13;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S13:              			//F=D2-C3
    begin
        if(ModSubDone)
            NextEdPointAddState = EDPA_S14;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S14:           			//G=D2+C3
    begin
        if(ModAddDone)
            NextEdPointAddState = EDPA_S15;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S15:         				//H=B3+A3
    begin
        if(ModAddDone)
            NextEdPointAddState = EDPA_S16;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S16:                    		//X3=E*F
    begin
        if(MpcDone)
            NextEdPointAddState = EDPA_S17;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S17:					//Y3=G*H
    begin
        if(MpcDone)
            NextEdPointAddState = EDPA_S18;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S18:					//T3=E*H
    begin
        if(MpcDone)
            NextEdPointAddState = EDPA_S19;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S19:             			//Z3=F*G
    begin
        if(MpcDone)
            NextEdPointAddState = EDPA_END;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_S20:					//TEMP1 =D1
    begin
        if(LongAlgDone)
            NextEdPointAddState = EDPA_S11;
        else
            NextEdPointAddState = EdPointAddState;
    end
    EDPA_END:
    begin
            NextEdPointAddState = EDPA_IDLE;
    end
    default:
    begin
            NextEdPointAddState = EDPA_IDLE;
    end
endcase

assign EdPointAddDone    = EdPointAddState == EDPA_END;

assign StartMpc_EDPA    =
                         (EdPointAddState == EDPA_S2) & ModSubDone      |
                         (EdPointAddState == EDPA_S5) & ModAddDone      |
                         (EdPointAddState == EDPA_S6) & MpcDone         |
                         (EdPointAddState == EDPA_S8) & ModAddDone      |
                         (EdPointAddState == EDPA_S9) & MpcDone         |
                         (EdPointAddState == EDPA_S15)& ModAddDone      |
                         (EdPointAddState == EDPA_S16)& MpcDone         |
                         (EdPointAddState == EDPA_S17)& MpcDone         |
                         (EdPointAddState == EDPA_S18)& MpcDone         ;

assign StartModAdd_EDPA =
                         (EdPointAddState == EDPA_S3) & MpcDone         |
                         (EdPointAddState == EDPA_S4) & ModAddDone      |
                         //(EdPointAddState == EDPA_S7) & MpcDone         |
                         (EdPointAddState == EDPA_S21) & LongAlgDone    | //20220806
                         (EdPointAddState == EDPA_S20)& LongAlgDone     |
                         (EdPointAddState == EDPA_S13)& ModSubDone      |
                         (EdPointAddState == EDPA_S14)& ModAddDone      ;


assign StartModSub_EDPA =
                         (EdPointAddState == EDPA_IDLE)&StartEdPointAdd |
                         (EdPointAddState == EDPA_S1)  & ModSubDone     |
                         (EdPointAddState == EDPA_S11) & ModAddDone     |
                         (EdPointAddState == EDPA_S12) & ModSubDone     ;

assign LongAlgOp_EDPA   =
                         //(EdPointAddState == EDPA_S1) ? UNIT_BA_SUB_A   :
                         //(EdPointAddState == EDPA_S2) ? UNIT_BA_SUB_B   :
                         //(EdPointAddState == EDPA_S4) ? UNIT_AB_ADD_A   :
                         //(EdPointAddState == EDPA_S5) ? UNIT_AB_ADD_B   :
                         //(EdPointAddState == EDPA_S8) ? UNIT_AB_ADD_B   :
                         //(EdPointAddState == EDPA_S11)? UNIT_AB_ADD_B   :
                         //(EdPointAddState == EDPA_S12)? UNIT_BA_SUB_A   :
                         //(EdPointAddState == EDPA_S13)? UNIT_BA_SUB_B   :
                         //(EdPointAddState == EDPA_S14)? UNIT_AB_ADD_A   :
                         //(EdPointAddState == EDPA_S15)? UNIT_AB_ADD_B   :
                         (EdPointAddState == EDPA_S20)? UNIT_A_MOV_B    :
                         (EdPointAddState == EDPA_S21)? UNIT_A_MOV_B    :
                                                        UNIT_AB_ADD_A   ;

assign LongAlgStart_EDPA=
                         (EdPointAddState == EDPA_S7)   & MpcDone       |  //20220806
                         (EdPointAddState == EDPA_S10)  & MpcDone       ;

assign PointEn_EDPA    =
                         (EdPointAddState == EDPA_S2  ) ? 1'b1 :
                         (EdPointAddState == EDPA_S5  ) ? 1'b1 :
                         (EdPointAddState == EDPA_S6  ) ? 1'b1 :
                         (EdPointAddState == EDPA_S8  ) ? 1'b1 :
                         (EdPointAddState == EDPA_S11 ) ? 1'b1 :
                         (EdPointAddState == EDPA_S13 ) ? 1'b1 :
                         (EdPointAddState == EDPA_S15 ) ? 1'b1 :
                         (EdPointAddState == EDPA_S17 ) ? 1'b1 :
                                                      1'b0 ;

//Ed PointDble State
always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        EdPointDblState <= EDPD_IDLE;
    else
        EdPointDblState <= NextEdPointDblState;
always @(*)
case(EdPointDblState)
    EDPD_IDLE:
    begin
        if(StartEdPointDbl)
            NextEdPointDblState = EDPD_S1;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S1:          				//Mov X1 to TP1
    begin
        if(LongAlgDone)
            NextEdPointDblState = EDPD_S2;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S2:                       		//MM(X1,TP1)
    begin
        if(MpcDone)
            NextEdPointDblState = EDPD_S3;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S3:  					//Mov Y1 to TP0
    begin
        if(LongAlgDone)
            NextEdPointDblState = EDPD_S4;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S4:                   			//MM(TP0,Y1)
    begin
        if(MpcDone)
            NextEdPointDblState = EDPD_S5;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S5:                 			//MOV Z1 to TEMP1
    begin
        if(LongAlgDone)
            NextEdPointDblState = EDPD_S6;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S6:       				//MM(Z1,TEMP1)
    begin
        if(MpcDone)
            NextEdPointDblState = EDPD_S7;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S7:      				//MOV C1 to TP0
    begin
        if(LongAlgDone)
            NextEdPointDblState = EDPD_S8;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S8:  					//TP0+C1
    begin
        if(ModAddDone)
            NextEdPointDblState = EDPD_S9;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S9:     				//A+B
    begin
        if(ModAddDone)
            NextEdPointDblState = EDPD_S10;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S10:                       		//X1+Y1
    begin
        if(ModAddDone)
            NextEdPointDblState = EDPD_S11;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S11:                       		//Mov E1 to TP0
    begin
        if(LongAlgDone)
            NextEdPointDblState = EDPD_S12;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S12: 					//TP0*E1
    begin
        if(MpcDone)
            NextEdPointDblState = EDPD_S13;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S13:                     		//H-E2
    begin
        if(ModSubDone)
            NextEdPointDblState = EDPD_S14;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S14:    				//A-B
    begin
        if(ModSubDone)
            NextEdPointDblState = EDPD_S15;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S15:                                  //C+G
    begin
        if(ModAddDone)
            NextEdPointDblState = EDPD_S16;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S16:
    begin
        if(MpcDone)
            NextEdPointDblState = EDPD_S17;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S17:
    begin
        if(MpcDone)
            NextEdPointDblState = EDPD_S18;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S18:
    begin
        if(MpcDone)
            NextEdPointDblState = EDPD_S19;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_S19:
    begin
        if(MpcDone)
            NextEdPointDblState = EDPD_END;
        else
            NextEdPointDblState = EdPointDblState;
    end
    EDPD_END:
    begin
            NextEdPointDblState = EDPD_IDLE;
    end
    default:
    begin
            NextEdPointDblState = EDPD_IDLE;
    end
endcase

assign EdPointDblDone = EdPointDblState == EDPD_END;

assign StartMpc_EDPD     =
                         (EdPointDblState == EDPD_S1 ) & LongAlgDone    |
                         (EdPointDblState == EDPD_S3 ) & LongAlgDone    |
                         (EdPointDblState == EDPD_S5 ) & LongAlgDone    |
                         (EdPointDblState == EDPD_S11) & LongAlgDone    |
                         (EdPointDblState == EDPD_S15) & ModAddDone     |
                         (EdPointDblState == EDPD_S16) & MpcDone        |
                         (EdPointDblState == EDPD_S17) & MpcDone        |
                         (EdPointDblState == EDPD_S18) & MpcDone        ;


assign StartModAdd_EDPD  =
                         (EdPointDblState == EDPD_S7 ) & LongAlgDone    |
                         (EdPointDblState == EDPD_S8 ) & ModAddDone     |
                         (EdPointDblState == EDPD_S9 ) & ModAddDone     |
                         (EdPointDblState == EDPD_S14) & ModSubDone     ;

assign StartModSub_EDPD  =
                         (EdPointDblState == EDPD_S12) & MpcDone        |
                         (EdPointDblState == EDPD_S13) & ModSubDone     ;


assign LongAlgOp_EDPD    =
                         (EdPointDblState == EDPD_S1 ) ?    UNIT_A_MOV_B    :
                         (EdPointDblState == EDPD_S3 ) ?    UNIT_B_MOV_A    :
                         (EdPointDblState == EDPD_S5 ) ?    UNIT_A_MOV_B    :
                         (EdPointDblState == EDPD_S7 ) ?    UNIT_A_MOV_B    :
                         //(EdPointDblState == EDPD_S8 ) ?    UNIT_AB_ADD_B   :
                         //(EdPointDblState == EDPD_S9 ) ?    UNIT_AB_ADD_B   :
                         //(EdPointDblState == EDPD_S10) ?    UNIT_AB_ADD_B   :
                         (EdPointDblState == EDPD_S11) ?    UNIT_B_MOV_A    :
                         //(EdPointDblState == EDPD_S13) ?    UNIT_BA_SUB_A   :
                         //(EdPointDblState == EDPD_S14) ?    UNIT_AB_SUB_A   :
                         //(EdPointDblState == EDPD_S15) ?    UNIT_AB_ADD_B   :
                                                            UNIT_AB_ADD_A   ;

assign LongAlgStart_EDPD =
                         (EdPointDblState == EDPD_IDLE) & StartEdPointDbl |
                         (EdPointDblState == EDPD_S2 )  & MpcDone         |
                         (EdPointDblState == EDPD_S4 )  & MpcDone         |
                         (EdPointDblState == EDPD_S6 )  & MpcDone         |
                         (EdPointDblState == EDPD_S10)  & ModAddDone      ;

assign PointEn_EDPD     =
                         //(EdPointDblState == EDPD_S2 ) ? 1'b0  :
                         (EdPointDblState == EDPD_S4 ) ? 1'b1  :
                         (EdPointDblState == EDPD_S8 ) ? 1'b1  :
                         (EdPointDblState == EDPD_S9 ) ? 1'b1  :
                         (EdPointDblState == EDPD_S10) ? 1'b1  :
                         (EdPointDblState == EDPD_S15) ? 1'b1  :
                         //(EdPointDblState == EDPD_S6 ) ? 1'b0  :
                         //(EdPointDblState == EDPD_S12) ? 1'b0  :
                         //(EdPointDblState == EDPD_S16) ? 1'b0  :
                         (EdPointDblState == EDPD_S17) ? 1'b1  :
                         //(EdPointDblState == EDPD_S18) ? 1'b0  :
                         //(EdPointDblState == EDPD_S19) ? 1'b0  :
                                                         1'b0  ;

assign EDPA_Src0 =
                  (EdPointAddState == EDPA_S1    ) ? Q0X_ADR    :
                  (EdPointAddState == EDPA_S2    ) ? Q1X_ADR    :
                  (EdPointAddState == EDPA_S3    ) ? T4_ADR_PD  :
                  (EdPointAddState == EDPA_S4    ) ? Q0X_ADR    :
                  (EdPointAddState == EDPA_S5    ) ? Q1X_ADR    :
                  (EdPointAddState == EDPA_S6    ) ? T9_ADR_PD  :
                  (EdPointAddState == EDPA_S7    ) ? T1_ADR_PD  :
                  (EdPointAddState == EDPA_S8    ) ? A_ADR      :
                  (EdPointAddState == EDPA_S9    ) ? T11_ADR_PD :
                  (EdPointAddState == EDPA_S10   ) ? Q0Z_ADR    :
                  (EdPointAddState == EDPA_S11   ) ? T14_ADR_PD :
                  (EdPointAddState == EDPA_S12   ) ? T7_ADR_PD  :
                  (EdPointAddState == EDPA_S13   ) ? T13_ADR_PD :
                  (EdPointAddState == EDPA_S14   ) ? T13_ADR_PD :
                  (EdPointAddState == EDPA_S15   ) ? T7_ADR_PD  :
                  (EdPointAddState == EDPA_S16   ) ? T16_ADR_PD :
                  (EdPointAddState == EDPA_S17   ) ? T20_ADR_PD :
                  (EdPointAddState == EDPA_S18   ) ? T16_ADR_PD :
                  (EdPointAddState == EDPA_S19   ) ? T20_ADR_PD :
                  (EdPointAddState == EDPA_S20   ) ? T14_ADR_PD :
                  (EdPointAddState == EDPA_S21   ) ? A_ADR      :
                                                     8'h00      ;

assign EDPA_Src1 =
                  (EdPointAddState == EDPA_S1    ) ? Q0Y_ADR    :
                  (EdPointAddState == EDPA_S2    ) ? Q1Y_ADR    :
                  (EdPointAddState == EDPA_S3    ) ? T6_ADR_PD  :
                  (EdPointAddState == EDPA_S4    ) ? Q0Y_ADR    :
                  (EdPointAddState == EDPA_S5    ) ? Q1Y_ADR    :
                  (EdPointAddState == EDPA_S6    ) ? T10_ADR_PD :
                  (EdPointAddState == EDPA_S7    ) ? T2_ADR_PD  :
                  (EdPointAddState == EDPA_S8    ) ? TP1_ADR    :
                  (EdPointAddState == EDPA_S9    ) ? T12_ADR_PD :
                  (EdPointAddState == EDPA_S10   ) ? Q1Z_ADR    :
                  (EdPointAddState == EDPA_S11   ) ? TP1_ADR    :
                  (EdPointAddState == EDPA_S12   ) ? T8_ADR_PD  :
                  (EdPointAddState == EDPA_S13   ) ? T15_ADR_PD :
                  (EdPointAddState == EDPA_S14   ) ? T15_ADR_PD :
                  (EdPointAddState == EDPA_S15   ) ? T8_ADR_PD  :
                  (EdPointAddState == EDPA_S16   ) ? T18_ADR_PD :
                  (EdPointAddState == EDPA_S17   ) ? T19_ADR_PD :
                  (EdPointAddState == EDPA_S18   ) ? T19_ADR_PD :
                  (EdPointAddState == EDPA_S19   ) ? T18_ADR_PD :
                  (EdPointAddState == EDPA_S20   ) ? TP1_ADR    :
                  (EdPointAddState == EDPA_S21   ) ? TP1_ADR    :
                                                     8'h00      ;

assign EDPA_Dst =                                                //Wr to SRAM0 or SRAM1 according PointEn
                  (EdPointAddState == EDPA_S1    ) ? T4_ADR_PD  :
                  (EdPointAddState == EDPA_S2    ) ? T6_ADR_PD  :
                  (EdPointAddState == EDPA_S3    ) ? T7_ADR_PD  :
                  (EdPointAddState == EDPA_S4    ) ? T9_ADR_PD  :
                  (EdPointAddState == EDPA_S5    ) ? T10_ADR_PD :
                  (EdPointAddState == EDPA_S6    ) ? T8_ADR_PD  :
                  (EdPointAddState == EDPA_S7    ) ? T11_ADR_PD :
                  (EdPointAddState == EDPA_S8    ) ? T12_ADR_PD :
                  (EdPointAddState == EDPA_S9    ) ? T13_ADR_PD :
                  (EdPointAddState == EDPA_S10   ) ? T14_ADR_PD :
                  (EdPointAddState == EDPA_S11   ) ? T15_ADR_PD :
                  (EdPointAddState == EDPA_S12   ) ? T16_ADR_PD :
                  (EdPointAddState == EDPA_S13   ) ? T18_ADR_PD :
                  (EdPointAddState == EDPA_S14   ) ? T20_ADR_PD :
                  (EdPointAddState == EDPA_S15   ) ? T19_ADR_PD :
                  (EdPointAddState == EDPA_S16   ) ? Q0X_ADR    :
                  (EdPointAddState == EDPA_S17   ) ? Q0Y_ADR    :
                  (EdPointAddState == EDPA_S18   ) ? T1_ADR_PD  :
                  (EdPointAddState == EDPA_S19   ) ? Q0Z_ADR    :
                  (EdPointAddState == EDPA_S20   ) ? TP1_ADR    :
                  (EdPointAddState == EDPA_S21   ) ? TP1_ADR    :
                                                     8'h00      ;

assign EDPD_Src0 =
                  (EdPointDblState==EDPD_S1   ) ? Q0X_ADR    :
                  (EdPointDblState==EDPD_S2   ) ? Q0X_ADR    :
                  (EdPointDblState==EDPD_S3   ) ? TP0_ADR    :
                  (EdPointDblState==EDPD_S4   ) ? TP0_ADR    :
                  (EdPointDblState==EDPD_S5   ) ? Q0Z_ADR    :
                  (EdPointDblState==EDPD_S6   ) ? Q0Z_ADR    :
                  (EdPointDblState==EDPD_S7   ) ? T11_ADR_PD :
                  (EdPointDblState==EDPD_S8   ) ? T11_ADR_PD :
                  (EdPointDblState==EDPD_S9   ) ? T4_ADR_PD  :
                  (EdPointDblState==EDPD_S10  ) ? Q0X_ADR    :
                  (EdPointDblState==EDPD_S11  ) ? TP0_ADR    :
                  (EdPointDblState==EDPD_S12  ) ? TP0_ADR    :
                  (EdPointDblState==EDPD_S13  ) ? T14_ADR_PD :
                  (EdPointDblState==EDPD_S14  ) ? T4_ADR_PD  :
                  (EdPointDblState==EDPD_S15  ) ? T20_ADR_PD :
                  (EdPointDblState==EDPD_S16  ) ? T16_ADR_PD :
                  (EdPointDblState==EDPD_S17  ) ? T20_ADR_PD :
                  (EdPointDblState==EDPD_S18  ) ? T16_ADR_PD :
                  (EdPointDblState==EDPD_S19  ) ? T20_ADR_PD :
                                                  8'h00      ;

assign EDPD_Src1 =
                  (EdPointDblState==EDPD_S1   ) ? TP1_ADR    :
                  (EdPointDblState==EDPD_S2   ) ? TP1_ADR    :
                  (EdPointDblState==EDPD_S3   ) ? Q0Y_ADR    :
                  (EdPointDblState==EDPD_S4   ) ? Q0Y_ADR    :
                  (EdPointDblState==EDPD_S5   ) ? TP1_ADR    :
                  (EdPointDblState==EDPD_S6   ) ? TP1_ADR    :
                  (EdPointDblState==EDPD_S7   ) ? TP1_ADR    :
                  (EdPointDblState==EDPD_S8   ) ? TP1_ADR    :
                  (EdPointDblState==EDPD_S9   ) ? T10_ADR_PD :
                  (EdPointDblState==EDPD_S10  ) ? Q0Y_ADR    :
                  (EdPointDblState==EDPD_S11  ) ? T17_ADR_PD :
                  (EdPointDblState==EDPD_S12  ) ? T17_ADR_PD :
                  (EdPointDblState==EDPD_S13  ) ? T19_ADR_PD :
                  (EdPointDblState==EDPD_S14  ) ? T10_ADR_PD :
                  (EdPointDblState==EDPD_S15  ) ? T12_ADR_PD :
                  (EdPointDblState==EDPD_S16  ) ? T18_ADR_PD :
                  (EdPointDblState==EDPD_S17  ) ? T19_ADR_PD :
                  (EdPointDblState==EDPD_S18  ) ? T19_ADR_PD :
                  (EdPointDblState==EDPD_S19  ) ? T18_ADR_PD :
                                                  8'h00      ;

assign EDPD_Dst =
                  (EdPointDblState==EDPD_S1   ) ? TP1_ADR    :
                  (EdPointDblState==EDPD_S2   ) ? T4_ADR_PD  :
                  (EdPointDblState==EDPD_S3   ) ? TP0_ADR    :
                  (EdPointDblState==EDPD_S4   ) ? T10_ADR_PD :
                  (EdPointDblState==EDPD_S5   ) ? TP1_ADR    :
                  (EdPointDblState==EDPD_S6   ) ? T11_ADR_PD :
                  (EdPointDblState==EDPD_S7   ) ? TP1_ADR    :
                  (EdPointDblState==EDPD_S8   ) ? T12_ADR_PD :
                  (EdPointDblState==EDPD_S9   ) ? T19_ADR_PD :
                  (EdPointDblState==EDPD_S10  ) ? T17_ADR_PD :
                  (EdPointDblState==EDPD_S11  ) ? TP0_ADR    :
                  (EdPointDblState==EDPD_S12  ) ? T14_ADR_PD :
                  (EdPointDblState==EDPD_S13  ) ? T16_ADR_PD :
                  (EdPointDblState==EDPD_S14  ) ? T20_ADR_PD :
                  (EdPointDblState==EDPD_S15  ) ? T18_ADR_PD :
                  (EdPointDblState==EDPD_S16  ) ? Q0X_ADR    :
                  (EdPointDblState==EDPD_S17  ) ? Q0Y_ADR    :
                  (EdPointDblState==EDPD_S18  ) ? T1_ADR_PD  :
                  (EdPointDblState==EDPD_S19  ) ? Q0Z_ADR    :
                                                  8'h00      ;


always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        ModAddState <= MA_IDLE;
    else
        ModAddState <= NextModAddState;
always @(*)
case(ModAddState)
    MA_IDLE:
    begin
        if(StartModAdd)
            NextModAddState = MA_ADD;
        else
            NextModAddState = ModAddState;
    end
    MA_ADD:
        if(LongAlgDone)
            NextModAddState = MA_SUB;
        else
            NextModAddState = ModAddState;
    MA_SUB:
        if(LongAlgDone & LongAlgSR[1])
            NextModAddState = MA_ADD1;
        else if(LongAlgDone)
            NextModAddState = MA_END;
        else
            NextModAddState = ModAddState;
    MA_ADD1:
        if(LongAlgDone)
            NextModAddState = MA_END;
        else
            NextModAddState = ModAddState;
    MA_END:
        if(StartModAdd)
            NextModAddState = MA_ADD;
        else
            NextModAddState = MA_IDLE;
    default:
            NextModAddState = MA_IDLE;
endcase

assign LongAlgStart_MA =
                         (ModAddState == MA_END ) & StartModAdd |
                         (ModAddState == MA_IDLE) & StartModAdd |
                         (ModAddState == MA_ADD)  & LongAlgDone |
                         (ModAddState == MA_SUB)  & LongAlgDone & LongAlgSR[1] ;
assign LongAlgOp_MA    =
                         (ModAddState == MA_ADD)  ? UNIT_AB_ADD_A :
                         //(ModAddState == MA_SUB & PointEn)  ? UNIT_AA_SUB_B :
                         (ModAddState == MA_SUB & PointEn)  ? UNIT_BA_SUB_A :
                         (ModAddState == MA_SUB)  ? UNIT_AB_SUB_A :
                         (ModAddState == MA_ADD1) ? UNIT_AB_ADD_A :
                                                    UNIT_AB_ADD_A ;

//assign StartModAdd    = StartModAdd_PA | StartModAdd_PD | StartModAdd_Ecc;
assign StartModAdd    = StartModAdd_PA | StartModAdd_PD | StartModAdd_Ecc | StartModAdd_EDPA | StartModAdd_EDPD | StartModAdd_X25519;

assign ModAddDone     = ModAddState == MA_END;

always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        ModSubState <= MS_IDLE;
    else
        ModSubState <= NextModSubState;
always @(*)
case(ModSubState)
    MS_IDLE:
    begin
        if(StartModSub)
            NextModSubState = MS_SUB;
        else
            NextModSubState = ModSubState;
    end
    MS_SUB:
        if(LongAlgDone & LongAlgSR[1])
            NextModSubState = MS_ADD;
        else if(LongAlgDone)
            NextModSubState = MS_END;
        else
            NextModSubState = ModSubState;
    MS_ADD:
        if(LongAlgDone)
            NextModSubState = MS_END;
        else
            NextModSubState = ModSubState;
    MS_END:
        if(StartModSub)
            NextModSubState = MS_SUB;
        else
            NextModSubState = MS_IDLE;
    default:
            NextModSubState = MS_IDLE;
endcase

assign LongAlgStart_MS =
                         (ModSubState == MS_END ) & StartModSub |
                         (ModSubState == MS_IDLE) & StartModSub |
                         (ModSubState == MS_SUB)  & LongAlgDone & LongAlgSR[1] ;
assign LongAlgOp_MS    =
                         (ModSubState == MS_ADD)  ? UNIT_AB_ADD_A :
  //(ModSubState==MS_SUB & PointAddState== PA_S24)  ? UNIT_AA_SUB_B :
  (ModSubState==MS_SUB & PointAddState== PA_S24)  ? UNIT_BA_SUB_A : //the only B-A operation
  (ModSubState==MS_SUB & EdPointAddState== EDPA_S1) ? UNIT_BA_SUB_A :
  (ModSubState==MS_SUB & EdPointAddState== EDPA_S2) ? UNIT_BA_SUB_A :
  (ModSubState==MS_SUB & EdPointAddState== EDPA_S12)? UNIT_BA_SUB_A :
  (ModSubState==MS_SUB & EdPointAddState== EDPA_S13)? UNIT_BA_SUB_A :
  (ModSubState==MS_SUB & EdPointDblState== EDPD_S13)? UNIT_BA_SUB_A :
                         (ModSubState == MS_SUB)  ? UNIT_AB_SUB_A :
                                                    UNIT_AB_ADD_A ;

//assign StartModSub    = StartModSub_PA | StartModSub_PD | StartModSub_Ecc;
assign StartModSub    = StartModSub_PA | StartModSub_PD | StartModSub_Ecc | StartModSub_EDPA | StartModSub_EDPD | StartModSub_X25519;
assign ModSubDone     = ModSubState == MS_END;

assign MpcStart       = StartMpc_ME | StartMpc_MM |StartMpc_I2M | StartMpc_M2I | StartMpc_PA | StartMpc_PD |
                        StartMpc_EDPA | StartMpc_EDPD | StartMpc_EDI2M | StartMpc_EDM2I | StartMpc_X25519;
assign LongAlgStart   = LongAlgStart_PA | LongAlgStart_PD | LongAlgStart_MA | LongAlgStart_MS | LongAlgStart_MI | LongAlgStart_I2M | LongAlgStart_M2I | LongAlgStart_HCal | LongAlgStart_ME |
                        LongAlgStart_EDPA | LongAlgStart_EDPD | LongAlgStart_EDI2M | LongAlgStart_EDM2I | LongAlgStart_PM | LongAlgStart_X25519 | LongAlgStart_GCD; //20221125
assign LongAlgOp      = LongAlgOp_PA | LongAlgOp_PD | LongAlgOp_MA | LongAlgOp_MS | LongAlgOp_MI | LongAlgOp_I2M |LongAlgOp_M2I | LongAlgOp_HCal |LongAlgOp_ME |
                        LongAlgOp_EDPA | LongAlgOp_EDPD | LongAlgOp_EDI2M | LongAlgOp_EDM2I | LongAlgOp_PM | LongAlgOp_X25519 | LongAlgOp_GCD ;//20221125


assign LongAlgSrc0  =                                                                                      //zxjian,20220918,added this col
                         (ModAddState == MA_ADD)             ? PA_Src0  | PD_Src0 | EDPA_Src0 | EDPD_Src0 | X25519_Src0 :
                         (ModAddState == MA_SUB & ~PointEn)  ? PA_Dst   | PD_Dst  | EDPA_Dst  | EDPD_Dst  | X25519_Dst  :
                         (ModAddState == MA_ADD1 & ~PointEn) ? PA_Dst   | PD_Dst  | EDPA_Dst  | EDPD_Dst  | X25519_Dst  :
                         (ModAddState == MA_SUB & PointEn)   ? P_ADR              :
                         (ModAddState == MA_ADD1 & PointEn)  ? P_ADR              :
                         (ModSubState == MS_SUB)             ? PA_Src0  | PD_Src0 | EDPA_Src0 | EDPD_Src0 | X25519_Src0 :
                         (ModSubState == MS_ADD & ~PointEn)  ? PA_Dst   | PD_Dst  | EDPA_Dst  | EDPD_Dst  | X25519_Dst  :
                         (ModSubState == MS_ADD & PointEn)   ? P_ADR                                                    :
                                                               //PA_Src0  | PD_Src0 | EDPA_Src0 | EDPD_Src0;
                                                               PA_Src0  | PD_Src0 | EDPA_Src0 | EDPD_Src0 | PM_Src0 | X25519_Src0;
assign LongAlgSrc1  =
                         (ModAddState == MA_ADD)   	     ? PA_Src1  | PD_Src1 | EDPA_Src1 | EDPD_Src1 | X25519_Src1 :
                         (ModAddState == MA_SUB & ~PointEn)  ? P_ADR              :
                         (ModAddState == MA_ADD1 & ~PointEn) ? P_ADR              :
                         (ModAddState == MA_SUB & PointEn)   ? PA_Dst | PD_Dst    | EDPA_Dst  | EDPD_Dst  | X25519_Dst  :
                         (ModAddState == MA_ADD1 & PointEn)  ? PA_Dst | PD_Dst    | EDPA_Dst  | EDPD_Dst  | X25519_Dst  :
                         (ModSubState == MS_SUB)             ? PA_Src1  | PD_Src1 | EDPA_Src1 | EDPD_Src1 | X25519_Src1 :
                         (ModSubState == MS_ADD & ~PointEn)  ? P_ADR              :
                         (ModSubState == MS_ADD & PointEn)   ? PA_Dst | PD_Dst    | EDPA_Dst  | EDPD_Dst  | X25519_Dst  :
                                                               //PA_Src1  | PD_Src1 | EDPA_Src1 | EDPD_Src1;
                                                               PA_Src1  | PD_Src1 | EDPA_Src1 | EDPD_Src1 | PM_Src1 | X25519_Src1;

//assign LongAlgDst   =     PA_Dst | PD_Dst | EDPA_Dst | EDPD_Dst;
assign LongAlgDst   =     PA_Dst | PD_Dst | EDPA_Dst | EDPD_Dst | PM_Dst | X25519_Dst;

assign PA_Src0 =
                  (PointAddState == PA_S1    ) ? Q1Z_ADR    :
                  (PointAddState == PA_S2    ) ? TP0_ADR    :
                  (PointAddState == PA_S3    ) ? Q0X_ADR    :
                  (PointAddState == PA_S4    ) ? Q0Z_ADR    :
                  (PointAddState == PA_S5    ) ? Q0Z_ADR    :
                  (PointAddState == PA_S6    ) ? Q1X_ADR    :
                  (PointAddState == PA_S7    ) ? T2_ADR_PA  :
                  (PointAddState == PA_S8    ) ? Q1Z_ADR    :
                  (PointAddState == PA_S9    ) ? TP0_ADR    :
                  (PointAddState == PA_S10   ) ? T6_ADR_PA  :
                  (PointAddState == PA_S11   ) ? Q0Z_ADR    :
                  (PointAddState == PA_S12   ) ? T8_ADR_PA  :
                  (PointAddState == PA_S13   ) ? T7_ADR_PA  :
                  (PointAddState == PA_S14   ) ? T2_ADR_PA  :
                  (PointAddState == PA_S15   ) ? T7_ADR_PA  :
                  (PointAddState == PA_S16   ) ? T10_ADR_PA :
                  (PointAddState == PA_S17   ) ? TP0_ADR    :
                  (PointAddState == PA_S18   ) ? T5_ADR_PA  :
                  (PointAddState == PA_S19   ) ? T5_ADR_PA  :
                  (PointAddState == PA_S20   ) ? T11_ADR_PA :
                  (PointAddState == PA_S21   ) ? T13_ADR_PA :
                  (PointAddState == PA_S22   ) ? T16_ADR_PA :
                  (PointAddState == PA_S23   ) ? T16_ADR_PA :
                  (PointAddState == PA_S24   ) ? T17_ADR_PA :
                  (PointAddState == PA_S25   ) ? T18_ADR_PA :
                  (PointAddState == PA_S26   ) ? T5_ADR_PA  :
                  (PointAddState == PA_S27   ) ? T12_ADR_PA :
                  (PointAddState == PA_S28   ) ? T19_ADR_PA :
                  (PointAddState == PA_S29   ) ? T22_ADR_PA :
                  (PointAddState == PA_S30   ) ? P_ADR      :
                  (PointAddState == PA_S31   ) ? Q0Z_ADR    :
                  (PointAddState == PA_S32   ) ? T5_ADR_PA  :
                  (PointAddState == PA_S33   ) ? Q1Z_ADR    :
                  (PointAddState == PA_S34   ) ? TP0_ADR    :
                                                 8'h00      ;
//
assign PD_Src0 =
                  (PointDblState==PD_S1   ) ? Q0X_ADR    :
                  (PointDblState==PD_S2   ) ? Q0X_ADR    :
                  (PointDblState==PD_S3   ) ? T1_ADR_PD  :
                  (PointDblState==PD_S4   ) ? T1_ADR_PD  :
                  (PointDblState==PD_S5   ) ? T1_ADR_PD  :
                  (PointDblState==PD_S6   ) ? Q0Z_ADR    :
                  (PointDblState==PD_S7   ) ? Q0Z_ADR    :
                  (PointDblState==PD_S8   ) ? T4_ADR_PD  :
                  (PointDblState==PD_S9   ) ? T4_ADR_PD  :
                  (PointDblState==PD_S10  ) ? A_ADR      :
                  (PointDblState==PD_S11  ) ? T3_ADR_PD  :
                  (PointDblState==PD_S12  ) ? Q0Y_ADR    :
                  (PointDblState==PD_S13  ) ? TP0_ADR    :
                  (PointDblState==PD_S14  ) ? Q0X_ADR    :
                  (PointDblState==PD_S15  ) ? T9_ADR_PD  :
                  (PointDblState==PD_S16  ) ? T9_ADR_PD  :
                  (PointDblState==PD_S17  ) ? T10_ADR_PD :
                  (PointDblState==PD_S18  ) ? TP0_ADR    :
                  (PointDblState==PD_S19  ) ? T8_ADR_PD  :
                  (PointDblState==PD_S20  ) ? TP0_ADR    :
                  (PointDblState==PD_S21  ) ? TP0_ADR    :
                  (PointDblState==PD_S22  ) ? TP0_ADR    :
                  (PointDblState==PD_S23  ) ? T13_ADR_PD :
                  (PointDblState==PD_S24  ) ? T13_ADR_PD :
                  (PointDblState==PD_S25  ) ? T14_ADR_PD :
                  (PointDblState==PD_S26  ) ? T14_ADR_PD :
                  (PointDblState==PD_S27  ) ? T7_ADR_PD  :
                  (PointDblState==PD_S28  ) ? T7_ADR_PD  :
                  (PointDblState==PD_S29  ) ? T11_ADR_PD :
                  (PointDblState==PD_S30  ) ? T11_ADR_PD :
                  (PointDblState==PD_S31  ) ? T16_ADR_PD :
                  (PointDblState==PD_S32  ) ? T11_ADR_PD :
                  (PointDblState==PD_S33  ) ? T7_ADR_PD  :
                  (PointDblState==PD_S34  ) ? T20_ADR_PD :
                  (PointDblState==PD_S35  ) ? Q0Z_ADR    :
                  (PointDblState==PD_S36  ) ? T22_ADR_PD :
                  (PointDblState==PD_S37  ) ? T22_ADR_PD :
                  (PointDblState==PD_S38  ) ? T24_ADR_PD :
                                                 8'h00   ;

assign PA_Src1 =
                  (PointAddState == PA_S1    ) ? Q1Z_ADR    :
                  (PointAddState == PA_S2    ) ? Q1Z_ADR    :
                  (PointAddState == PA_S3    ) ? T1_ADR_PA  :
                  (PointAddState == PA_S4    ) ? TP1_ADR    :
                  (PointAddState == PA_S5    ) ? TP1_ADR    :
                  (PointAddState == PA_S6    ) ? T3_ADR_PA  :
                  (PointAddState == PA_S7    ) ? T4_ADR_PA  :
                  (PointAddState == PA_S8    ) ? Q1Z_ADR    :
                  (PointAddState == PA_S9    ) ? T1_ADR_PA  :
                  (PointAddState == PA_S10   ) ? Q0Y_ADR    :
                  (PointAddState == PA_S11   ) ? T3_ADR_PA  :
                  (PointAddState == PA_S12   ) ? Q1Y_ADR    :
                  (PointAddState == PA_S13   ) ? T9_ADR_PA  :
                  (PointAddState == PA_S14   ) ? T4_ADR_PA  :
                  (PointAddState == PA_S15   ) ? T9_ADR_PA  :
                  (PointAddState == PA_S16   ) ? T10_ADR_PA :
                  (PointAddState == PA_S17   ) ? T10_ADR_PA :
                  (PointAddState == PA_S18   ) ? TP1_ADR    :
                  (PointAddState == PA_S19   ) ? TP1_ADR    :
                  (PointAddState == PA_S20   ) ? T14_ADR_PA :
                  (PointAddState == PA_S21   ) ? T15_ADR_PA :
                  (PointAddState == PA_S22   ) ? TP1_ADR    :
                  (PointAddState == PA_S23   ) ? TP1_ADR    :
                  (PointAddState == PA_S24   ) ? T15_ADR_PA :
                  (PointAddState == PA_S25   ) ? T10_ADR_PA :
                  (PointAddState == PA_S26   ) ? T14_ADR_PA :
                  (PointAddState == PA_S27   ) ? T20_ADR_PA :
                  (PointAddState == PA_S28   ) ? T21_ADR_PA :
                  (PointAddState == PA_S29   ) ? T22_ADR_PA :
                  (PointAddState == PA_S30   ) ? T22_ADR_PA :
                  (PointAddState == PA_S31   ) ? TP1_ADR    :
                  (PointAddState == PA_S32   ) ? TP1_ADR    :
                  (PointAddState == PA_S33   ) ? Q1Z_ADR    :
                  (PointAddState == PA_S34   ) ? T24_ADR_PA :
                                                 8'h00      ;
assign PD_Src1 =
                  (PointDblState==PD_S1   ) ? TP1_ADR      :
                  (PointDblState==PD_S2   ) ? TP1_ADR      :
                  (PointDblState==PD_S3   ) ? TP1_ADR      :
                  (PointDblState==PD_S4   ) ? TP1_ADR      :
                  (PointDblState==PD_S5   ) ? T2_ADR_PD    :
                  (PointDblState==PD_S6   ) ? TP1_ADR      :
                  (PointDblState==PD_S7   ) ? TP1_ADR      :
                  (PointDblState==PD_S8   ) ? TP1_ADR      :
                  (PointDblState==PD_S9   ) ? TP1_ADR      :
                  (PointDblState==PD_S10  ) ? T5_ADR_PD    :
                  (PointDblState==PD_S11  ) ? T6_ADR_PD    :
                  (PointDblState==PD_S12  ) ? Q0Y_ADR      :
                  (PointDblState==PD_S13  ) ? Q0Y_ADR      :
                  (PointDblState==PD_S14  ) ? T8_ADR_PD    :
                  (PointDblState==PD_S15  ) ? TP1_ADR      :
                  (PointDblState==PD_S16  ) ? TP1_ADR      :
                  (PointDblState==PD_S17  ) ? T10_ADR_PD   :
                  (PointDblState==PD_S18  ) ? T10_ADR_PD   :
                  (PointDblState==PD_S19  ) ? T8_ADR_PD    :
                  (PointDblState==PD_S20  ) ? T8_ADR_PD    :
                  (PointDblState==PD_S21  ) ? T12_ADR_PD   :
                  (PointDblState==PD_S22  ) ? T12_ADR_PD   :
                  (PointDblState==PD_S23  ) ? TP1_ADR      :
                  (PointDblState==PD_S24  ) ? TP1_ADR      :
                  (PointDblState==PD_S25  ) ? TP1_ADR      :
                  (PointDblState==PD_S26  ) ? TP1_ADR      :
                  (PointDblState==PD_S27  ) ? TP1_ADR      :
                  (PointDblState==PD_S28  ) ? TP1_ADR      :
                  (PointDblState==PD_S29  ) ? TP1_ADR      :
                  (PointDblState==PD_S30  ) ? TP1_ADR      :
                  (PointDblState==PD_S31  ) ? T17_ADR_PD   :
                  (PointDblState==PD_S32  ) ? T18_ADR_PD   :
                  (PointDblState==PD_S33  ) ? T19_ADR_PD   :
                  (PointDblState==PD_S34  ) ? T15_ADR_PD   :
                  (PointDblState==PD_S35  ) ? Q0Y_ADR      :
                  (PointDblState==PD_S36  ) ? TP1_ADR      :
                  (PointDblState==PD_S37  ) ? TP1_ADR      :
                  (PointDblState==PD_S38  ) ? T18_ADR_PD   :
                                                 8'h00     ;
assign PA_Dst =
                  (PointAddState == PA_S1    ) ? TP0_ADR    :
                  (PointAddState == PA_S2    ) ? T1_ADR_PA  :
                  (PointAddState == PA_S3    ) ? T2_ADR_PA  :
                  (PointAddState == PA_S4    ) ? TP1_ADR    :
                  (PointAddState == PA_S5    ) ? T3_ADR_PA  :
                  (PointAddState == PA_S6    ) ? T4_ADR_PA  :
                  (PointAddState == PA_S7    ) ? T5_ADR_PA  :
                  (PointAddState == PA_S8    ) ? TP0_ADR    :
                  (PointAddState == PA_S9    ) ? T6_ADR_PA  :
                  (PointAddState == PA_S10   ) ? T7_ADR_PA  :
                  (PointAddState == PA_S11   ) ? T8_ADR_PA  :
                  (PointAddState == PA_S12   ) ? T9_ADR_PA  :
                  (PointAddState == PA_S13   ) ? T10_ADR_PA :
                  (PointAddState == PA_S14   ) ? T11_ADR_PA :
                  (PointAddState == PA_S15   ) ? T12_ADR_PA :
                  (PointAddState == PA_S16   ) ? TP0_ADR    :
                  (PointAddState == PA_S17   ) ? T13_ADR_PA :
                  (PointAddState == PA_S18   ) ? TP1_ADR    :
                  (PointAddState == PA_S19   ) ? T14_ADR_PA :
                  (PointAddState == PA_S20   ) ? T15_ADR_PA :
                  (PointAddState == PA_S21   ) ? T16_ADR_PA :
                  (PointAddState == PA_S22   ) ? TP1_ADR    :
                  (PointAddState == PA_S23   ) ? T17_ADR_PA :
                  (PointAddState == PA_S24   ) ? T18_ADR_PA :
                  (PointAddState == PA_S25   ) ? T19_ADR_PA :
                  (PointAddState == PA_S26   ) ? T20_ADR_PA :
                  (PointAddState == PA_S27   ) ? T21_ADR_PA :
                  (PointAddState == PA_S28   ) ? T22_ADR_PA :
                  (PointAddState == PA_S29   ) ? T23_ADR_PA :
                  (PointAddState == PA_S30   ) ? T22_ADR_PA :
                  (PointAddState == PA_S31   ) ? TP1_ADR    :
                  (PointAddState == PA_S32   ) ? T24_ADR_PA :
                  (PointAddState == PA_S33   ) ? TP0_ADR    :
                  (PointAddState == PA_S34   ) ? T25_ADR_PA :
                                                 8'h00      ;

assign PD_Dst =
                  (PointDblState==PD_S1   ) ? TP1_ADR    :
                  (PointDblState==PD_S2   ) ? T1_ADR_PD  :
                  (PointDblState==PD_S3   ) ? TP1_ADR    :
                  (PointDblState==PD_S4   ) ? T2_ADR_PD  :
                  (PointDblState==PD_S5   ) ? T3_ADR_PD  :
                  (PointDblState==PD_S6   ) ? TP1_ADR    :
                  (PointDblState==PD_S7   ) ? T4_ADR_PD  :
                  (PointDblState==PD_S8   ) ? TP1_ADR    :
                  (PointDblState==PD_S9   ) ? T5_ADR_PD  :
                  (PointDblState==PD_S10  ) ? T6_ADR_PD  :
                  (PointDblState==PD_S11  ) ? T7_ADR_PD  :
                  (PointDblState==PD_S12  ) ? TP0_ADR    :
                  (PointDblState==PD_S13  ) ? T8_ADR_PD  :
                  (PointDblState==PD_S14  ) ? T9_ADR_PD  :
                  (PointDblState==PD_S15  ) ? TP1_ADR    :
                  (PointDblState==PD_S16  ) ? T10_ADR_PD :
                  (PointDblState==PD_S17  ) ? TP0_ADR    :
                  (PointDblState==PD_S18  ) ? T11_ADR_PD :
                  (PointDblState==PD_S19  ) ? TP0_ADR    :
                  (PointDblState==PD_S20  ) ? T12_ADR_PD :
                  (PointDblState==PD_S21  ) ? TP0_ADR    :
                  (PointDblState==PD_S22  ) ? T13_ADR_PD :
                  (PointDblState==PD_S23  ) ? TP1_ADR    :
                  (PointDblState==PD_S24  ) ? T14_ADR_PD :
                  (PointDblState==PD_S25  ) ? TP1_ADR    :
                  (PointDblState==PD_S26  ) ? T15_ADR_PD :
                  (PointDblState==PD_S27  ) ? TP1_ADR    :
                  (PointDblState==PD_S28  ) ? T16_ADR_PD :
                  (PointDblState==PD_S29  ) ? TP1_ADR    :
                  (PointDblState==PD_S30  ) ? T17_ADR_PD :
                  (PointDblState==PD_S31  ) ? T18_ADR_PD :
                  (PointDblState==PD_S32  ) ? T19_ADR_PD :
                  (PointDblState==PD_S33  ) ? T20_ADR_PD :
                  (PointDblState==PD_S34  ) ? T21_ADR_PD :
                  (PointDblState==PD_S35  ) ? T22_ADR_PD :
                  (PointDblState==PD_S36  ) ? TP1_ADR    :
                  (PointDblState==PD_S37  ) ? T23_ADR_PD :
                  (PointDblState==PD_S38  ) ? T24_ADR_PD :
                                                 8'h00   ;

assign Src0Adr  =
                  (PkeState == PKE_RSAHCAL  )       ? HCal_Src0_RSA :
                  (PkeState == PKE_ECCHCAL  )       ? HCal_Src0_ECC :
                  (PkeState == PKE_RSAEXP  )        ? ME_Src0       :
                  (PkeState == PKE_RSAMODMUL  )     ? MM_Src0       :
                  (PkeState == PKE_ECCMODMUL  )     ? MM_Src0       :
                  (PkeState == PKE_ECCMODADD  )     ? MM_Src0       :
                  (PkeState == PKE_ECCMODSUB  )     ? MM_Src0       :
                  (PkeState == PKE_RSAMODADD  )     ? MM_Src0       : //zxjian,20230808
                  (PkeState == PKE_RSAMODSUB  )     ? MM_Src0       : //zxjian,20230808
                  (PkeState == PKE_ECCMODINV  )     ? MI_Src0       :
                  (PkeState == PKE_GCD)             ? GCD_Src0      : //20221125
                  (EccI2MState == ECCI2M_MOVH  )    ? H_ADR         :
                  (EccI2MState == ECCI2M_MMQ0XH)    ? Q0X_ADR       :
                  (EccI2MState == ECCI2M_MMQ0YH)    ? TP0_ADR       :
                  (EccI2MState == ECCI2M_MMQ0ZH)    ? Q0Z_ADR       :
                  (EccI2MState == ECCI2M_MMQ1XH)    ? Q1X_ADR       :
                  (EccI2MState == ECCI2M_MMQ1YH)    ? TP0_ADR       :
                  (EccI2MState == ECCI2M_MMQ1ZH)    ? TP0_ADR       :
                  (EccI2MState == ECCI2M_MMAH  )    ? A_ADR         :
                  (EccM2IState == ECCM2I_MMZ1  )    ? Q0Z_ADR       :
                  (EccM2IState == ECCM2I_MOVZ2UT)   ? Q0Z_ADR       :
                  (EccM2IState == ECCM2I_MOVUT2U)   ? MI_U          :
                  (EccM2IState == ECCM2I_MMZH  )    ? TP0_ADR       :
                  (EccM2IState == ECCM2I_MOVZ2TP0 ) ? TP0_ADR       :
                  (EccM2IState == ECCM2I_MOVZ2TP1 ) ? Z1_ADR        :
                  (EccM2IState == ECCM2I_MMZ2  )    ? Z1_ADR        :
                  (EccM2IState == ECCM2I_MMXZ2 )    ? Q0X_ADR       :
                  (EccM2IState == ECCM2I_MMZ3  )    ? Z1_ADR        :
                  (EccM2IState == ECCM2I_MMYZ3 )    ? Z3_ADR        :
                  (EccM2IState == ECCM2I_MMX1  )    ? Q0X_ADR       :
                  (EccM2IState == ECCM2I_MOVY2TP0 ) ? TP0_ADR       :
                  (EccM2IState == ECCM2I_MMY1  )    ? TP0_ADR       :
//20220802
                  (EdI2MState == EDI2M_MOVH	) ? TP0_ADR       :
                  (EdI2MState == EDI2M_MMQ0XH	) ? Q0X_ADR       :
                  (EdI2MState == EDI2M_MMQ0YH	) ? TP0_ADR       :
                  (EdI2MState == EDI2M_MMQ0ZH	) ? Q0Z_ADR       :
                  (EdI2MState == EDI2M_MOVZ	) ? Q0Z_ADR       :
                  (EdI2MState == EDI2M_MMQ0XZ	) ? Q0X_ADR       :
                  (EdI2MState == EDI2M_MMQ0XY	) ? Q0X_ADR       :
                  (EdI2MState == EDI2M_MMQ0YZ	) ? Q0Z_ADR       ://20220809
                  (EdI2MState == EDI2M_MMQ1XH	) ? Q1X_ADR       :
                  (EdI2MState == EDI2M_MMQ1YH	) ? TP0_ADR       :
                  (EdI2MState == EDI2M_MMQ1ZH	) ? TP0_ADR       :
                  (EdI2MState == EDI2M_MOVZ1	) ? TP0_ADR       :
                  (EdI2MState == EDI2M_MMQ1XZ	) ? Q1X_ADR       :
                  (EdI2MState == EDI2M_MMQ1XY	) ? Q1X_ADR       :
                  (EdI2MState == EDI2M_MMQ1YZ	) ? TP0_ADR       :
                  (EdI2MState == EDI2M_MMAH	) ? A_ADR         :
//20220805
                  (EdM2IState == EDM2I_MMZ1	) ? Q0Z_ADR       :
                  (EdM2IState == EDM2I_MOVZ2UT	) ? Z1_ADR        :
                  (EdM2IState == EDM2I_MOVUT2U	) ? MI_U          :
                  //(EdM2IState == EDM2I_MODINVZ	) ? Z3_ADR        :
                  (EdM2IState == EDM2I_MOVZ2TP0)  ? TP0_ADR       :
                  (EdM2IState == EDM2I_MMZH	) ? TP0_ADR       :
                  (EdM2IState == EDM2I_MOVZ2TP1)  ? Z1_ADR        :
                  (EdM2IState == EDM2I_MMXZ	) ? Q0X_ADR       :
                  (EdM2IState == EDM2I_MMYZ	) ? Z1_ADR        :
                  (EdM2IState == EDM2I_MMX1	) ? Q0X_ADR       :
                  (EdM2IState == EDM2I_MOVY2TP0)  ? TP0_ADR       :
                  (EdM2IState == EDM2I_MMY1	) ? TP0_ADR       :
                  (EdM2IState == EDM2I_MODINVZ )  ? MI_Src0       :
//20220802
                  (EccM2IState == ECCM2I_MODINVZ )  ? MI_Src0       :
                  (PkeState == PKE_ECCPOINTADD    ) ? LongAlgSrc0   :
                  (PkeState == PKE_ECCPOINTDBL    ) ? LongAlgSrc0   :
                  (PkeState == PKE_EDPOINTADD    )  ? LongAlgSrc0   : //20220723
                  (PkeState == PKE_EDPOINTDBL    )  ? LongAlgSrc0   : //20220723
                  (PkeState == PKE_ECCPOINTMUL   )  ? LongAlgSrc0   : //20220815
                  (PkeState == PKE_X25519        )  ? LongAlgSrc0   : //20220918
                                                      Q0X_ADR       ;


assign Src1Adr  =
                  (PkeState == PKE_RSAHCAL  )       ? HCal_Src1_RSA :
                  (PkeState == PKE_ECCHCAL  )       ? HCal_Src1_ECC :
                  (PkeState == PKE_RSAEXP  )        ? ME_Src1       :
                  (PkeState == PKE_RSAMODMUL  )     ? MM_Src1       :
                  (PkeState == PKE_ECCMODMUL  )     ? MM_Src1       :
                  (PkeState == PKE_ECCMODADD & ModAddState == MA_SUB  )     ? P_ADR        : //zxjian,20220408
                  (PkeState == PKE_ECCMODADD & ModAddState == MA_ADD1 )     ? P_ADR        : //zxjian,20220408
                  (PkeState == PKE_ECCMODADD  )                             ? MM_Src1      : //zxjian,20220408
                  (PkeState == PKE_ECCMODSUB & ModSubState == MS_ADD  )     ? P_ADR        : //zxjian,20220408
                  (PkeState == PKE_ECCMODSUB  )                             ? MM_Src1      : //zxjian,20220408
                  (PkeState == PKE_RSAMODADD & ModAddState == MA_SUB  )     ? ME_N         : //zxjian,20230808
                  (PkeState == PKE_RSAMODADD & ModAddState == MA_ADD1 )     ? ME_N         : //zxjian,20230808
                  (PkeState == PKE_RSAMODADD  )                             ? MM_Src1      : //zxjian,20230808
                  (PkeState == PKE_RSAMODSUB & ModSubState == MS_ADD  )     ? ME_N         : //zxjian,20230808
                  (PkeState == PKE_RSAMODSUB  )                             ? MM_Src1      : //zxjian,20230808
                  (PkeState == PKE_ECCMODINV  )     ? MI_Src1       :
                  (PkeState == PKE_GCD)             ? GCD_Src1      : //20221125
                  (EccI2MState == ECCI2M_MOVH  )    ? H_ADR         :
                  (EccI2MState == ECCI2M_MMQ0XH)    ? H_ADR         :
                  (EccI2MState == ECCI2M_MMQ0YH)    ? Q0Y_ADR       :
                  (EccI2MState == ECCI2M_MMQ0ZH)    ? H_ADR         :
                  (EccI2MState == ECCI2M_MMQ1XH)    ? H_ADR         :
                  (EccI2MState == ECCI2M_MMQ1YH)    ? Q1Y_ADR       :
                  (EccI2MState == ECCI2M_MMQ1ZH)    ? Q1Z_ADR       :
                  (EccI2MState == ECCI2M_MMAH  )    ? A_ADR         :
                  (EccM2IState == ECCM2I_MMZ1  )    ? C1_ADR        :
                  (EccM2IState == ECCM2I_MOVZ2UT)   ? MI_UT         :
                  (EccM2IState == ECCM2I_MOVUT2U)   ? MI_UT         :
                  (EccM2IState == ECCM2I_MMZH  )    ? H_ADR         :
                  (EccM2IState == ECCM2I_MOVZ2TP0 ) ? MI_Y2         :
                  (EccM2IState == ECCM2I_MOVZ2TP1 ) ? TP1_ADR       :
                  (EccM2IState == ECCM2I_MMZ2  )    ? TP1_ADR       :
                  (EccM2IState == ECCM2I_MMXZ2 )    ? Z2_ADR        :
                  (EccM2IState == ECCM2I_MMZ3  )    ? Z2_ADR        :
                  (EccM2IState == ECCM2I_MMYZ3 )    ? Q0Y_ADR       :
                  (EccM2IState == ECCM2I_MMX1  )    ? C1_ADR        :
                  (EccM2IState == ECCM2I_MOVY2TP0 ) ? Q0Y_ADR       :
                  (EccM2IState == ECCM2I_MMY1  )    ? C1_ADR        :
//20220802
                  (EdI2MState == EDI2M_MOVH	) ? H_ADR         :
                  (EdI2MState == EDI2M_MMQ0XH	) ? H_ADR         :
                  (EdI2MState == EDI2M_MMQ0YH	) ? Q0Y_ADR       :
                  (EdI2MState == EDI2M_MMQ0ZH	) ? H_ADR         :
                  (EdI2MState == EDI2M_MOVZ	) ? TP1_ADR       :
                  (EdI2MState == EDI2M_MMQ0XZ	) ? TP1_ADR       :
                  (EdI2MState == EDI2M_MMQ0XY	) ? Q0Y_ADR       :
                  (EdI2MState == EDI2M_MMQ0YZ	) ? Q0Y_ADR       : //
                  (EdI2MState == EDI2M_MMQ1XH	) ? H_ADR         :
                  (EdI2MState == EDI2M_MMQ1YH	) ? Q1Y_ADR       :
                  //(EdI2MState == EDI2M_MMQ1ZH	) ? H_ADR         :
                  (EdI2MState == EDI2M_MMQ1ZH	) ? Q1Z_ADR       : //20230812
                  (EdI2MState == EDI2M_MOVZ1	) ? Q1Z_ADR       :
                  (EdI2MState == EDI2M_MMQ1XZ	) ? Q1Z_ADR       :
                  (EdI2MState == EDI2M_MMQ1XY	) ? Q1Y_ADR       :
                  (EdI2MState == EDI2M_MMQ1YZ	) ? Q1Y_ADR       :
                  (EdI2MState == EDI2M_MMAH	) ? H_ADR         :
//20220805
                  (EdM2IState == EDM2I_MMZ1	) ? C1_ADR        :
                  (EdM2IState == EDM2I_MOVZ2UT	) ? MI_UT         :
                  (EdM2IState == EDM2I_MOVUT2U	) ? MI_UT         :
                  (EdM2IState == EDM2I_MODINVZ	) ? MI_Src1       :
                  (EdM2IState == EDM2I_MOVZ2TP0)  ? MI_Y2         :
                  (EdM2IState == EDM2I_MMZH	) ? H_ADR         :
                  (EdM2IState == EDM2I_MOVZ2TP1)  ? TP1_ADR       :
                  (EdM2IState == EDM2I_MMXZ	) ? TP1_ADR       :
                  (EdM2IState == EDM2I_MMYZ	) ? Q0Y_ADR       :
                  (EdM2IState == EDM2I_MMX1	) ? C1_ADR        :
                  (EdM2IState == EDM2I_MOVY2TP0)  ? Q0Y_ADR       :
                  (EdM2IState == EDM2I_MMY1	) ? C1_ADR        :

//20220802
                  (EccM2IState == ECCM2I_MODINVZ )  ? MI_Src1       :
                  (PkeState == PKE_ECCPOINTADD   )  ? LongAlgSrc1   :
                  (PkeState == PKE_ECCPOINTDBL   )  ? LongAlgSrc1   :
                  (PkeState == PKE_EDPOINTADD    )  ? LongAlgSrc1   : //20220723
                  (PkeState == PKE_EDPOINTDBL    )  ? LongAlgSrc1   : //20220723
                  (PkeState == PKE_ECCPOINTMUL   )  ? LongAlgSrc1   : //20220815
                  (PkeState == PKE_X25519        )  ? LongAlgSrc1   : //20220918
                                                      Q0X_ADR       ;
assign DstAdr   =
                  (PkeState == PKE_RSAHCAL  )       ? HCal_Dst_RSA  :
                  (PkeState == PKE_ECCHCAL  )       ? HCal_Dst_ECC  :
                  (PkeState == PKE_RSAEXP  )        ? ME_Dst        :
                  (PkeState == PKE_RSAMODMUL  )     ? MM_Dst        :
                  (PkeState == PKE_ECCMODMUL  )     ? MM_Dst        :
                  (PkeState == PKE_ECCMODADD  )     ? MM_Dst        :
                  (PkeState == PKE_ECCMODSUB  )     ? MM_Dst        :
                  (PkeState == PKE_RSAMODADD  )     ? MM_Dst        : //zxjian,20230808
                  (PkeState == PKE_RSAMODSUB  )     ? MM_Dst        : //zxjian,20230808
                  (PkeState == PKE_ECCMODINV  )     ? MI_Dst        :
                  (PkeState == PKE_GCD)             ? GCD_Dst       : //20221125
                  (EccI2MState == ECCI2M_MOVH  )    ? TP0_ADR       :
                  (EccI2MState == ECCI2M_MMQ0XH)    ? Q0X_ADR       :
                  (EccI2MState == ECCI2M_MMQ0YH)    ? Q0Y_ADR       :
                  (EccI2MState == ECCI2M_MMQ0ZH)    ? Q0Z_ADR       :
                  (EccI2MState == ECCI2M_MMQ1XH)    ? Q1X_ADR       :
                  (EccI2MState == ECCI2M_MMQ1YH)    ? Q1Y_ADR       :
                  (EccI2MState == ECCI2M_MMQ1ZH)    ? Q1Z_ADR       :
                  (EccI2MState == ECCI2M_MMAH  )    ? A_ADR         :
                  (EccM2IState == ECCM2I_MMZ1  )    ? Q0Z_ADR       :
                  (EccM2IState == ECCM2I_MOVZ2UT)   ? MI_UT         :
                  (EccM2IState == ECCM2I_MOVUT2U)   ? MI_U          :
                  (EccM2IState == ECCM2I_MMZH  )    ? Z1_ADR        :
                  (EccM2IState == ECCM2I_MOVZ2TP0 ) ? TP0_ADR       :
                  (EccM2IState == ECCM2I_MOVZ2TP1 ) ? TP1_ADR       :
                  (EccM2IState == ECCM2I_MMZ2  )    ? Z2_ADR        :
                  (EccM2IState == ECCM2I_MMXZ2 )    ? Q0X_ADR       :
                  (EccM2IState == ECCM2I_MMZ3  )    ? Z3_ADR        :
                  (EccM2IState == ECCM2I_MMYZ3 )    ? Q0Y_ADR       :
                  (EccM2IState == ECCM2I_MMX1  )    ? Q0X_ADR       :
                  (EccM2IState == ECCM2I_MOVY2TP0 ) ? TP0_ADR       :
                  (EccM2IState == ECCM2I_MMY1  )    ? Q0Y_ADR       :
//20220802
                  (EdI2MState == EDI2M_MOVH	) ? TP0_ADR       :
                  (EdI2MState == EDI2M_MMQ0XH	) ? Q0X_ADR       :
                  (EdI2MState == EDI2M_MMQ0YH	) ? Q0Y_ADR       : //1
                  (EdI2MState == EDI2M_MMQ0ZH	) ? Q0Z_ADR       :
                  (EdI2MState == EDI2M_MOVZ	) ? TP1_ADR       :
                  (EdI2MState == EDI2M_MMQ0XZ	) ? Q0X_ADR       :
                  (EdI2MState == EDI2M_MMQ0XY	) ? T1_ADR_PD     ://Q0T_ADR
                  (EdI2MState == EDI2M_MMQ0YZ	) ? Q0Y_ADR       : //1
                  (EdI2MState == EDI2M_MMQ1XH	) ? Q1X_ADR       :
                  (EdI2MState == EDI2M_MMQ1YH	) ? Q1Y_ADR       : //1
                  (EdI2MState == EDI2M_MMQ1ZH	) ? Q1Z_ADR       : //1
                  (EdI2MState == EDI2M_MOVZ1	) ? TP0_ADR       :
                  (EdI2MState == EDI2M_MMQ1XZ	) ? Q1X_ADR       :
                  (EdI2MState == EDI2M_MMQ1XY	) ? T2_ADR_PD     ://Q1T_ADR       : //1
                  (EdI2MState == EDI2M_MMQ1YZ	) ? Q1Y_ADR       : //1
                  (EdI2MState == EDI2M_MMAH	) ? A_ADR         :
//20220805
                  (EdM2IState == EDM2I_MMZ1	) ? Z1_ADR        :
                  (EdM2IState == EDM2I_MOVZ2UT	) ? MI_UT         :
                  (EdM2IState == EDM2I_MOVUT2U	) ? MI_U          :
                  (EdM2IState == EDM2I_MODINVZ	) ? MI_Dst        :
                  (EdM2IState == EDM2I_MOVZ2TP0)  ? TP0_ADR       :
                  (EdM2IState == EDM2I_MMZH	) ? Z1_ADR        :
                  (EdM2IState == EDM2I_MOVZ2TP1)  ? TP1_ADR       :
                  (EdM2IState == EDM2I_MMXZ	) ? Q0X_ADR       :
                  (EdM2IState == EDM2I_MMYZ	) ? Q0Y_ADR       :
                  (EdM2IState == EDM2I_MMX1	) ? Q0X_ADR       :
                  (EdM2IState == EDM2I_MOVY2TP0)  ? TP0_ADR       :
                  (EdM2IState == EDM2I_MMY1	) ? Q0Y_ADR       :

                  (EccM2IState == ECCM2I_MODINVZ )  ? MI_Dst        :
                  (PkeState == PKE_ECCPOINTADD )    ? LongAlgDst    :
                  (PkeState == PKE_ECCPOINTDBL )    ? LongAlgDst    :
                  (PkeState == PKE_EDPOINTADD    )  ? LongAlgDst    : //20220723
                  (PkeState == PKE_EDPOINTDBL    )  ? LongAlgDst    : //20220723
                  (PkeState == PKE_ECCPOINTMUL    ) ? LongAlgDst    : //20220815
                  (PkeState == PKE_X25519         ) ? LongAlgDst    : //20220918
                                                      Q0X_ADR       ;


always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        PointMulState <= ECCPM_IDLE;
    else
        PointMulState <= NextPointMulState;
always @(*)
case(PointMulState)
    ECCPM_IDLE:
    begin
        if(StartPointMul)
            NextPointMulState = ECCPM_S1;
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S1:   //Read K
    begin
            NextPointMulState = ECCPM_S2;
    end
    ECCPM_S2:	//Load K
    begin
            NextPointMulState = ECCPM_S3;
    end
    ECCPM_S3:   //JUDGE1
    begin
            NextPointMulState = ECCPM_S4;
    end
    ECCPM_S4:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S5;  //P0X to Q0X
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S5:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S6;  //P0Y to Q0Y
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S6:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S7;  //P0Z to TP1
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S7:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S8;  //TP1 to Q0Z
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S8:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S9;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S9:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S10;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S10:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S11;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S11:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S12;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S12:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S13;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S13:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S14;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S14:			            //Q0 =Q0+Q1
    begin
        if(PointAddDone)
            NextPointMulState = ECCPM_S15;
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S15:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S16;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S16:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S17;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S17:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S18;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S18:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S19;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S19:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S20;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S20:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S21;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S21:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S22;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S22:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S23;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S23:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S24;
        else
            NextPointMulState = PointMulState;
    end

    ECCPM_S24:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S25;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S25:  			    //Q0=2Q0
    begin
        if(PointDblDone)
            NextPointMulState = ECCPM_S26;  //R1 = R1*R1
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S26:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S27;
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S27:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S28;
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S28:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S29;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S29:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S30;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S30:
    begin
        if(LongAlgDone)
            NextPointMulState = ECCPM_S31;  //R0 = R0*R0
        else
            NextPointMulState = PointMulState;
    end
    ECCPM_S31:
    begin
        if(KNeedRd)
            NextPointMulState = ECCPM_S32;
        else
            NextPointMulState = ECCPM_S3;
    end
    ECCPM_S32:   //Judge if EDat is End
    begin
        if(KDatEnd)
            NextPointMulState = ECCPM_END;
        else
            NextPointMulState = ECCPM_S1;
    end
    ECCPM_END:
    begin
            NextPointMulState = ECCPM_IDLE;
    end
    default:
            NextPointMulState = ECCPM_IDLE;
endcase


assign EccPointMulDone    = PointMulState == ECCPM_END;
assign EccPointMulRamRd   =
                            PointMulState == ECCPM_S1;

assign EccPointMulRamAdr  = KCnt[15:6];

assign KDatIndex     = KCnt[5:0];
assign KDatIsZero    = ~KDat[KDatIndex];
assign KNeedRd       = KCnt[5:0] ==0;
assign KDatEnd       = KCnt == 0;

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    begin
    KCnt <= 16'h00;
    KDat <= 64'h0000;
    end
else
    begin
    KCnt <= NextKCnt;
    KDat <= NextKDat;
    end

assign NextKCnt      = StartPointMul                          ? PkeELen -2   	:
                       StartX25519                            ? PkeELen -1   	:
                       (PointMulState == ECCPM_S31 & KDatEnd) ? KCnt            :
                       (X25519State == X25519_S30 & KDatEnd)  ? KCnt            :
                       (X25519State == X25519_S30 & ~KDatEnd) ? KCnt -1         :
                       (PointMulState == ECCPM_S31 & ~KDatEnd)? KCnt -1      	:
                                                                KCnt         	;

assign NextKDat      = (PointMulState == ECCPM_S2)            ? RamModExpDat	:
                       (X25519State == X25519_S7 )            ? RamModExpDat	:
                                                                  KDat         	;
assign StartPointAdd_PM  = EcPointMul &
                           (PointMulState == ECCPM_S13 & LongAlgDone);

assign StartEdPointAdd_PM= EdPointMul &
                           (PointMulState == ECCPM_S13 & LongAlgDone);

assign StartPointDbl_PM  = EcPointMul &
                           (PointMulState == ECCPM_S24 & LongAlgDone);

assign StartEdPointDbl_PM = EdPointMul &
                           (PointMulState == ECCPM_S24 & LongAlgDone);

assign PointAddDone = EcPointMul & EccPointAddDone | EdPointMul & EdPointAddDone;
assign PointDblDone = EcPointMul & EccPointDblDone | EdPointMul & EdPointDblDone;

assign LongAlgStart_PM = PointMulState == ECCPM_S3  |
                         PointMulState == ECCPM_S4  & LongAlgDone |
                         PointMulState == ECCPM_S5  & LongAlgDone |
                         PointMulState == ECCPM_S6  & LongAlgDone |
                         PointMulState == ECCPM_S7  & LongAlgDone |
                         PointMulState == ECCPM_S8  & LongAlgDone |
                         PointMulState == ECCPM_S9  & LongAlgDone |
                         PointMulState == ECCPM_S10 & LongAlgDone |
                         PointMulState == ECCPM_S11 & LongAlgDone |
                         PointMulState == ECCPM_S12 & LongAlgDone |
                         PointMulState == ECCPM_S14 & PointAddDone|
                         PointMulState == ECCPM_S15 & LongAlgDone |
                         PointMulState == ECCPM_S16 & LongAlgDone |
                         PointMulState == ECCPM_S17 & LongAlgDone |
                         PointMulState == ECCPM_S18 & LongAlgDone |
                         PointMulState == ECCPM_S19 & LongAlgDone |
                         PointMulState == ECCPM_S20 & LongAlgDone |
                         PointMulState == ECCPM_S21 & LongAlgDone |
                         PointMulState == ECCPM_S22 & LongAlgDone |
                         PointMulState == ECCPM_S23 & LongAlgDone |
                         PointMulState == ECCPM_S25 & PointDblDone |
                         PointMulState == ECCPM_S26 & LongAlgDone |
                         PointMulState == ECCPM_S27 & LongAlgDone |
                         PointMulState == ECCPM_S28 & LongAlgDone |
                         PointMulState == ECCPM_S29 & LongAlgDone ;

assign LongAlgOp_PM    = 					     //Src0	Src1	Dst
                         PointMulState == ECCPM_S4  ? UNIT_B_MOV_A : //Q0X	P0X	Q0X
                         PointMulState == ECCPM_S5  ? UNIT_A_MOV_B : //P0Y	Q0Y	Q0Y
                         PointMulState == ECCPM_S6  ? UNIT_A_MOV_B : //P0Z	TP1	TP1
                         PointMulState == ECCPM_S7  ? UNIT_B_MOV_A : //Q0Z	TP1	Q0Z
                         PointMulState == ECCPM_S8  ? UNIT_B_MOV_A : //Q0T	P0T	Q0T
                         PointMulState == ECCPM_S9  ? UNIT_B_MOV_A : //Q1X  	P1X	Q1X
                         PointMulState == ECCPM_S10 ? UNIT_A_MOV_B : //P1Y	Q1Y	Q1Y
                         PointMulState == ECCPM_S11 ? UNIT_A_MOV_B : //P1Z	Q1Z	Q1Z
                         PointMulState == ECCPM_S12 ? UNIT_B_MOV_A : //TP0	P1T	TP0
                         PointMulState == ECCPM_S13 ? UNIT_A_MOV_B : //TP0	Q1T	Q1T

                         PointMulState == ECCPM_S15 ? UNIT_A_MOV_B : //Q0X	P1X	Q0X
                         PointMulState == ECCPM_S16 ? UNIT_B_MOV_A : //P1Y	Q0Y	Q0Y
                         PointMulState == ECCPM_S17 ? UNIT_A_MOV_B : //Q0Z	TP1	TP1
                         PointMulState == ECCPM_S18 ? UNIT_B_MOV_A : //PZ	TP1	PZ
                         PointMulState == ECCPM_S19 ? UNIT_A_MOV_B : //Q0T	PT	Q0T

                         PointMulState == ECCPM_S20 ? UNIT_B_MOV_A : //Q0X	P0X	Q0X
                         PointMulState == ECCPM_S21 ? UNIT_A_MOV_B : //PY	Q0Y	Q0Y
                         PointMulState == ECCPM_S22 ? UNIT_A_MOV_B : //P0Z	TP1	TP1
                         PointMulState == ECCPM_S23 ? UNIT_B_MOV_A : //Q0Z	TP1	Q0Z
                         PointMulState == ECCPM_S24 ? UNIT_B_MOV_A : //Q0T	P0T	Q0T

                         PointMulState == ECCPM_S26 ? UNIT_A_MOV_B : //Q0X	PX	Q0X
                         PointMulState == ECCPM_S27 ? UNIT_B_MOV_A : //PY	Q0Y	Q0Y
                         PointMulState == ECCPM_S28 ? UNIT_A_MOV_B : //Q0Z	TP1	TP1
                         PointMulState == ECCPM_S29 ? UNIT_B_MOV_A : //PZ	TP1	PZ
                         PointMulState == ECCPM_S30 ? UNIT_A_MOV_B : //Q0T	PT	Q0T

                                                      6'd0;

wire [7:0] PM_P0X;
wire [7:0] PM_P0Y;
wire [7:0] PM_P0Z;
wire [7:0] PM_P0T;

wire [7:0] PM_P1X;
wire [7:0] PM_P1Y;
wire [7:0] PM_P1Z;
wire [7:0] PM_P1T;

assign PM_P0X = KDatIsZero ? P0X_ADR : P1X_ADR;
assign PM_P0Y = KDatIsZero ? P0Y_ADR : P1Y_ADR;
assign PM_P0Z = KDatIsZero ? P0Z_ADR : P1Z_ADR;
assign PM_P0T = KDatIsZero ? P0T_ADR : P1T_ADR;


assign PM_P1X = ~KDatIsZero ? P0X_ADR : P1X_ADR;
assign PM_P1Y = ~KDatIsZero ? P0Y_ADR : P1Y_ADR;
assign PM_P1Z = ~KDatIsZero ? P0Z_ADR : P1Z_ADR;
assign PM_P1T = ~KDatIsZero ? P0T_ADR : P1T_ADR;

assign PM_Src0 =
                         PointMulState == ECCPM_S4  ? Q0X_ADR : //Q0X	P0X	Q0X
                         PointMulState == ECCPM_S5  ? P0Y_ADR : //P0Y	Q0Y	Q0Y
                         PointMulState == ECCPM_S6  ? P0Z_ADR : //P0Z	TP1	TP1
                         PointMulState == ECCPM_S7  ? Q0Z_ADR : //Q0Z	TP1	Q0Z
                         PointMulState == ECCPM_S8  ? Q0T_ADR : //Q0T	P0T	Q0T
                         PointMulState == ECCPM_S9  ? Q1X_ADR : //Q1X  	P1X	Q1X
                         PointMulState == ECCPM_S10 ? P1Y_ADR : //P1Y	Q1Y	Q1Y
                         PointMulState == ECCPM_S11 ? P1Z_ADR : //P1Z	Q1Z	Q1Z
                         PointMulState == ECCPM_S12 ? TP0_ADR : //TP0	P1T	TP0
                         PointMulState == ECCPM_S13 ? TP0_ADR : //TP0	Q1T	Q1T
                         ////Suppose KDatIsZero, else exchange P0 and P1
                         PointMulState == ECCPM_S15 ? Q0X_ADR : //Q0X	P1X	P1X
                         PointMulState == ECCPM_S16 ? PM_P1Y  : //P1Y	Q0Y	P1Y
                         PointMulState == ECCPM_S17 ? Q0Z_ADR : //Q0Z	TP1	TP1
                         PointMulState == ECCPM_S18 ? PM_P1Z  : //P1Z	TP1	P1Z
                         PointMulState == ECCPM_S19 ? Q0T_ADR : //Q0T	P1T	P1T
                         //Suppose KDatIsZero, else exchange P0 and P1
                         PointMulState == ECCPM_S20 ? Q0X_ADR : //Q0X	P0X	Q0X
                         PointMulState == ECCPM_S21 ? PM_P0Y  : //P0Y	Q0Y	Q0Y
                         PointMulState == ECCPM_S22 ? PM_P0Z  : //P0Z	TP1	TP1
                         PointMulState == ECCPM_S23 ? Q0Z_ADR : //Q0Z	TP1	Q0Z
                         PointMulState == ECCPM_S24 ? Q0T_ADR : //Q0T	P0T	Q0T
                         //Suppose KDatIsZero, else exchange P0 and P1
                         PointMulState == ECCPM_S26 ? Q0X_ADR : //Q0X	P0X	P0X
                         PointMulState == ECCPM_S27 ? PM_P0Y  : //P0Y	Q0Y	P0Y
                         PointMulState == ECCPM_S28 ? Q0Z_ADR : //Q0Z	TP1	TP1
                         PointMulState == ECCPM_S29 ? PM_P0Z  : //P0Z	TP1	P0Z
                         PointMulState == ECCPM_S30 ? Q0T_ADR : //Q0T	P0T	P0T
                                                      8'd0;

assign PM_Src1 =
                         PointMulState == ECCPM_S4  ? P0X_ADR : //Q0X	P0X	Q0X
                         PointMulState == ECCPM_S5  ? Q0Y_ADR : //P0Y	Q0Y	Q0Y
                         PointMulState == ECCPM_S6  ? TP1_ADR : //P0Z	TP1	TP1
                         PointMulState == ECCPM_S7  ? TP1_ADR : //Q0Z	TP1	Q0Z
                         PointMulState == ECCPM_S8  ? P0T_ADR : //Q0T	P0T	Q0T
                         PointMulState == ECCPM_S9  ? P1X_ADR : //Q1X  	P1X	Q1X
                         PointMulState == ECCPM_S10 ? Q1Y_ADR : //P1Y	Q1Y	Q1Y
                         PointMulState == ECCPM_S11 ? Q1Z_ADR : //P1Z	Q1Z	Q1Z
                         PointMulState == ECCPM_S12 ? P1T_ADR : //TP0	P1T	TP0
                         PointMulState == ECCPM_S13 ? Q1T_ADR : //TP0	Q1T	Q1T
                         //Suppose KDatIsZero, else exchange P0 and P1
                         PointMulState == ECCPM_S15 ? PM_P1X :  //Q0X	P1X	P1X
                         PointMulState == ECCPM_S16 ? Q0Y_ADR : //P1Y	Q0Y	P1Y
                         PointMulState == ECCPM_S17 ? TP1_ADR : //Q0Z	TP1	TP1
                         PointMulState == ECCPM_S18 ? TP1_ADR : //P1Z	TP1	P1Z
                         PointMulState == ECCPM_S19 ? PM_P1T  : //Q0T	P1T	P1T
                         //Suppose KDatIsZero, else exchange P0 and P1
                         PointMulState == ECCPM_S20 ? PM_P0X  : //Q0X	P0X	Q0X
                         PointMulState == ECCPM_S21 ? Q0Y_ADR : //P0Y	Q0Y	Q0Y
                         PointMulState == ECCPM_S22 ? TP1_ADR : //P0Z	TP1	TP1
                         PointMulState == ECCPM_S23 ? TP1_ADR : //Q0Z	TP1	Q0Z
                         PointMulState == ECCPM_S24 ? PM_P0T  : //Q0T	P0T	Q0T
                         //Suppose KDatIsZero, else exchange P0 and P1
                         PointMulState == ECCPM_S26 ? PM_P0X  : //Q0X	P0X	P0X
                         PointMulState == ECCPM_S27 ? Q0Y_ADR : //P0Y	Q0Y	P0Y
                         PointMulState == ECCPM_S28 ? TP1_ADR : //Q0Z	TP1	TP1
                         PointMulState == ECCPM_S29 ? TP1_ADR : //P0Z	TP1	P0Z
                         PointMulState == ECCPM_S30 ? PM_P0T  : //Q0T	P0T	P0T

                                                      8'd0;

//assign PM_Dst  =
assign {PointEn_PM,PM_Dst}  =
                         PointMulState == ECCPM_S4  ? Q0X_ADR : //Q0X	P0X	Q0X
                         PointMulState == ECCPM_S5  ? Q0Y_ADR : //P0Y	Q0Y	Q0Y
                         PointMulState == ECCPM_S6  ? TP1_ADR : //P0Z	TP1	TP1
                         PointMulState == ECCPM_S7  ? Q0Z_ADR : //Q0Z	TP1	Q0Z
                         PointMulState == ECCPM_S8  ? Q0T_ADR : //Q0T	P0T	Q0T
                         PointMulState == ECCPM_S9  ? Q1X_ADR : //Q1X  	P1X	Q1X
                         PointMulState == ECCPM_S10 ? Q1Y_ADR : //P1Y	Q1Y	Q1Y
                         PointMulState == ECCPM_S11 ? Q1Z_ADR : //P1Z	Q1Z	Q1Z
                         PointMulState == ECCPM_S12 ? TP0_ADR : //TP0	P1T	TP0
                         PointMulState == ECCPM_S13 ? Q1T_ADR : //TP0	Q1T	Q1T

                         PointMulState == ECCPM_S15 ? PM_P1X  : //Q0X	P1X	P1X
                         PointMulState == ECCPM_S16 ? PM_P1Y  : //P1Y	Q0Y	P1Y
                         PointMulState == ECCPM_S17 ? TP1_ADR : //Q0Z	TP1	TP1
                         PointMulState == ECCPM_S18 ? PM_P1Z  : //P1Z	TP1	P1Z
                         PointMulState == ECCPM_S19 ? PM_P1T  : //Q0T	P1T	P1T

                         PointMulState == ECCPM_S20 ? Q0X_ADR : //Q0X	P0X	Q0X
                         PointMulState == ECCPM_S21 ? Q0Y_ADR : //P0Y	Q0Y	Q0Y
                         PointMulState == ECCPM_S22 ? TP1_ADR : //P0Z	TP1	TP1
                         PointMulState == ECCPM_S23 ? Q0Z_ADR : //Q0Z	TP1	Q0Z
                         PointMulState == ECCPM_S24 ? Q0T_ADR : //P0T	Q0T	Q0T

                         PointMulState == ECCPM_S26 ? PM_P0X  : //Q0X	P0X	P0X
                         PointMulState == ECCPM_S27 ? PM_P0Y  : //P0Y	Q0Y	P0Y
                         PointMulState == ECCPM_S28 ? TP1_ADR : //Q0Z	TP1	TP1
                         PointMulState == ECCPM_S29 ? PM_P0Z  : //P0Z	TP1	P0Z
                         PointMulState == ECCPM_S30 ? PM_P0T  : //Q0T	P0T	P0T

                                                      8'd0;

always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        X25519State <= X25519_IDLE;
    else
        X25519State <= NextX25519State;
always @(*)
case(X25519State)
    X25519_IDLE:
    begin
        if(StartX25519)
            NextX25519State = X25519_S1;
        else
            NextX25519State = X25519State;
    end
    X25519_S1:   //Mov X1 to TP1
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S2;
        else
            NextX25519State = X25519State;
    end
    X25519_S2:	//Mov TP1 to X3
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S33;
        else
            NextX25519State = X25519State;
    end
    X25519_S33:	//Mov C1 to TP0
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S3;
        else
            NextX25519State = X25519State;
    end
    X25519_S3:	//MM(C1,H)
    begin
        if(MpcDone)
            NextX25519State = X25519_S4;
        else
            NextX25519State = X25519State;
    end
    X25519_S4:	//Set Z2 =0
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S5;
        else
            NextX25519State = X25519State;
    end
    X25519_S5:	//Mov X2 to Z3
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S6;
        else
            NextX25519State = X25519State;
    end
    X25519_S6:	//Rd K
    begin
            NextX25519State = X25519_S7;
    end
    X25519_S7:	//Ld K
    begin
            NextX25519State = X25519_S8;
    end
    X25519_S8:   //JUDGE1
    begin
            NextX25519State = X25519_S9;  //Set Swap flag here, according KDatIsZero
    end
    X25519_S9:  //A=X2+Z2
    begin
        if(ModAddDone)
            NextX25519State = X25519_S10;
        else
            NextX25519State = X25519State;
    end
    X25519_S10: //Mov A to TP1
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S11;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S11: //AA=A*TP1
    begin
        if(MpcDone)
            NextX25519State = X25519_S12;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S12:  //B=X2-Z2
    begin
        if(ModSubDone)
            NextX25519State = X25519_S13;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S13:  //Mov B to TP0
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S14;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S14:  //BB=TP0*B
    begin
        if(MpcDone)
            NextX25519State = X25519_S15;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S15:  //E=AA-BB
    begin
        if(ModSubDone)
            NextX25519State = X25519_S16;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S16:	//C=X3+Z3
    begin
        if(ModAddDone)
            NextX25519State = X25519_S17;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S17:  //D=X3-Z3
    begin
        if(ModSubDone)
            NextX25519State = X25519_S18;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S18:  //DA=D*A
    begin
        if(MpcDone)
            NextX25519State = X25519_S19;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S19:  //CB=C*B
    begin
        if(MpcDone)
            NextX25519State = X25519_S20;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S20:  //X3T1=DA+CB
    begin
        if(ModAddDone)
            NextX25519State = X25519_S32;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S32:  //Mov X3T1 to TP0
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S21;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S21:  //X3=TP0*X3T1
    begin
        if(MpcDone)
            NextX25519State = X25519_S22;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S22:  //Z3T1=DA-CB
    begin
        if(ModSubDone)
            NextX25519State = X25519_S23;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S23:  //Mov Z3T1 to TP1
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S24;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S24:  // Z3T2 = Z3T1*TP1
    begin
        if(MpcDone)
            NextX25519State = X25519_S25;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S25:  //Z3=X1*Z3T2
    begin
        if(MpcDone)
            NextX25519State = X25519_S26;  //R1 = R1*R1
        else
            NextX25519State = X25519State;
    end
    X25519_S26:  //X2=AA*BB
    begin
        if(MpcDone)
            NextX25519State = X25519_S27;
        else
            NextX25519State = X25519State;
    end
    X25519_S27:  //Z2T1 = A24*E
    begin
        if(MpcDone)
            NextX25519State = X25519_S28;
        else
            NextX25519State = X25519State;
    end
    X25519_S28: //Z2T2 = AA *Z2T1
    begin
        if(ModAddDone)
            NextX25519State = X25519_S29;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S29:  //Z2 = Z2T2*E
    begin
        if(MpcDone)
            NextX25519State = X25519_S30;  //R0 = R0*R0
        else
            NextX25519State = X25519State;
    end
    X25519_S30: //JUDGE2
    begin
        if(KNeedRd)
            NextX25519State = X25519_S31;
        else
            NextX25519State = X25519_S8;
    end
    X25519_S31:   //JUDGE3: Judge if EDat is End
    begin
        if(KDatEnd)
            NextX25519State = X25519_S34;
        else
            NextX25519State = X25519_S6;
    end
    X25519_S34:  //Mov C1 to TP0
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S35;
        else
            NextX25519State = X25519State;
    end
    X25519_S35:  //Mov TP0 to X1
    begin
        if(LongAlgDone)
            NextX25519State = X25519_S36;
        else
            NextX25519State = X25519State;
    end
    X25519_S36:  //Mov Z2 to X3
    begin
        if(LongAlgDone)
            NextX25519State = X25519_END;
        else
            NextX25519State = X25519State;
    end
    X25519_END:
    begin
            NextX25519State = X25519_IDLE;
    end
    default:
            NextX25519State = X25519_IDLE;
endcase


assign X25519Done    = X25519State == X25519_END;
assign X25519RamRd   =
                       X25519State == X25519_S6;

assign X25519RamAdr  = KCnt[15:6];

reg KDatIsZeroReg;
wire NextKDatIsZero;
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    KDatIsZeroReg <= 1'b0;
else
    KDatIsZeroReg <= NextKDatIsZero;
assign NextKDatIsZero  = UpdateSwap ? ~KDatIsZero : KDatIsZeroReg;

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    SwapReg <= 1'b0;
else
    SwapReg <= NextSwap;
assign NextSwap  = StartX25519 ? 1'b0		 	:
                   UpdateSwap  ? KDatIsZeroReg ^ ~KDatIsZero	:
                                 SwapReg 		;
assign UpdateSwap = X25519State == X25519_S8;  //After KDat Shift

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    Change <= 1'b0;
else
    Change <= NextChange;

assign NextChange = UpdateSwap & NextSwap ? ~Change : Change;

assign StartMpc_X25519  =
                         X25519State == X25519_S10 & LongAlgDone |
                         X25519State == X25519_S13 & LongAlgDone |
                         X25519State == X25519_S17 & ModSubDone  |
                         X25519State == X25519_S18 & MpcDone     |
                         //X25519State == X25519_S20 & ModAddDone  |
                         X25519State == X25519_S32 & LongAlgDone  |
                         X25519State == X25519_S23 & LongAlgDone |
                         X25519State == X25519_S24 & MpcDone     |
                         X25519State == X25519_S25 & MpcDone     |
                         X25519State == X25519_S26 & MpcDone     |
                         //X25519State == X25519_S27 & MpcDone     |
                         X25519State == X25519_S33 & LongAlgDone |
                         X25519State == X25519_S28 & ModAddDone  ;

assign StartModAdd_X25519  =
                         X25519State == X25519_S8                |
                         X25519State == X25519_S15 & ModSubDone  |
                         X25519State == X25519_S27 & MpcDone     |
                         X25519State == X25519_S19 & MpcDone     ;


assign StartModSub_X25519  =
                         X25519State == X25519_S11 & MpcDone     |
                         X25519State == X25519_S14 & MpcDone     |
                         X25519State == X25519_S16 & ModAddDone  |
                         X25519State == X25519_S21 & MpcDone     ;


assign LongAlgStart_X25519 =
                         X25519State == X25519_IDLE& StartX25519 |
                         X25519State == X25519_S1  & LongAlgDone |
                         X25519State == X25519_S2  & LongAlgDone |
                         X25519State == X25519_S3  & MpcDone     |
                         X25519State == X25519_S4  & LongAlgDone |
                         //X25519State == X25519_S8                |
                         X25519State == X25519_S9  & ModAddDone  |
                         //X25519State == X25519_S11 & MpcDone     |
                         X25519State == X25519_S12 & ModSubDone  |
                         //X25519State == X25519_S14 & MpcDone     |
                         //X25519State == X25519_S15 & ModSubDone  |
                         //X25519State == X25519_S16 & ModAddDone  |
                         //X25519State == X25519_S19 & MpcDone     |
                         //X25519State == X25519_S21 & MpcDone     |
                         X25519State == X25519_S20 & ModAddDone  |
                         X25519State == X25519_S31 & KDatEnd     |
                         X25519State == X25519_S34 & LongAlgDone |
                         X25519State == X25519_S35 & LongAlgDone |
                         //X25519State == X25519_S33 & LongAlgDone |
                         X25519State == X25519_S22 & ModSubDone  ;

assign LongAlgOp_X25519    = 					     //Src0	Src1	Dst
                         X25519State == X25519_S1   ? UNIT_A_MOV_B : //Q0X      TP1     TP1
                         X25519State == X25519_S2   ? UNIT_B_MOV_A : //Q0Z      TP1     TP1
                         X25519State == X25519_S4   ? UNIT_A_SET0  : //Q1Y      Q1Y	Q1Y
                         X25519State == X25519_S5   ? UNIT_A_MOV_B : //Q1X      Q1Z	Q1Z
                         X25519State == X25519_S10  ? UNIT_A_MOV_B : //T4       TP1	TP1
                         X25519State == X25519_S13  ? UNIT_B_MOV_A : //TP0      T6 	TP0
                         X25519State == X25519_S23  ? UNIT_A_MOV_B : //T13      TP1	TP1
                         X25519State == X25519_S32  ? UNIT_B_MOV_A :
                         X25519State == X25519_S33  ? UNIT_B_MOV_A : //Q1X      C1      Q1X
                         X25519State == X25519_S34  ? UNIT_A_MOV_B : //X2 to TP1
                         X25519State == X25519_S35  ? UNIT_B_MOV_A : //TP1 to Q0X
                         X25519State == X25519_S36  ? UNIT_B_MOV_A : //Z2 to Q0Z
                                                      6'd0;
wire  [7 :0] X25519_X2;
wire  [7 :0] X25519_X3;
wire  [7 :0] X25519_Z2;
wire  [7 :0] X25519_Z3;

assign X25519_X2 = Change ? Q0Z_ADR : Q1X_ADR;
assign X25519_X3 = Change ? Q1X_ADR : Q0Z_ADR;
assign X25519_Z2 = Change ? Q1Z_ADR : Q1Y_ADR;
assign X25519_Z3 = Change ? Q1Y_ADR : Q1Z_ADR;

assign X25519_Src0 =
                         X25519State == X25519_S1   ? Q0X_ADR   : //TP1     TP1
                         X25519State == X25519_S2   ? Q0Z_ADR   : //TP1     TP1
                         X25519State == X25519_S3   ? TP0_ADR   : //C1      Q1X
                         X25519State == X25519_S33  ? TP0_ADR   : //C1      Q1X
                         X25519State == X25519_S4   ? Q1Y_ADR   : //Q1Y	Q1Y
                         X25519State == X25519_S5   ? Q1X_ADR   : //Q1Z	Q1Z
                         //X25519State == X25519_S9   ? Q1X_ADR   : //Q1Y	T4
                         X25519State == X25519_S9   ? X25519_X2   : //Q1Y	T4
                         X25519State == X25519_S10  ? T4_ADR_PD : //TP1	TP1
                         X25519State == X25519_S11  ? T4_ADR_PD : //TP1	T7
                         //X25519State == X25519_S12  ? Q1X_ADR   : //Q1Y	T6
                         X25519State == X25519_S12  ? X25519_X2: //Q1Y	T6
                         X25519State == X25519_S13  ? TP0_ADR   : //T6 	TP0
                         X25519State == X25519_S14  ? TP0_ADR   : //T6 	T8
                         X25519State == X25519_S15  ? T7_ADR_PD : //T8 	T19
                         //X25519State == X25519_S16  ? Q0Z_ADR   : //Q1Z 	T9
                         //X25519State == X25519_S17  ? Q0Z_ADR   : //Q1Z 	T10
                         X25519State == X25519_S16  ? X25519_X3   : //Q1Z 	T9
                         X25519State == X25519_S17  ? X25519_X3   : //Q1Z 	T10
                         X25519State == X25519_S18  ? T4_ADR_PD : //T10 	T11
                         X25519State == X25519_S19  ? T9_ADR_PD : //T6 	T12
                         X25519State == X25519_S20  ? T11_ADR_PD: //T12 	T15
                         X25519State == X25519_S21  ? TP0_ADR   : //T15 	Q0Z
                         X25519State == X25519_S22  ? T11_ADR_PD: //T12 	T13
                         X25519State == X25519_S23  ? T13_ADR_PD: //TP1	TP1
                         X25519State == X25519_S24  ? T13_ADR_PD: //TP1	T17
                         X25519State == X25519_S25  ? Q0X_ADR   : //T17	Q1Z
                         X25519State == X25519_S26  ? T7_ADR_PD : //T8 	Q1X
                         X25519State == X25519_S27  ? A_ADR     : //T19 	T18
                         X25519State == X25519_S28  ? T7_ADR_PD : //T18 	T14
                         X25519State == X25519_S29  ? T14_ADR_PD: //T14 	T19
                         X25519State == X25519_S32  ? TP0_ADR   : //TP0
                         X25519State == X25519_S34  ? X25519_X2 : //X2 to TP1
                         X25519State == X25519_S35  ? Q0X_ADR   : //TP1 to Q0X
                         X25519State == X25519_S36  ? Q0Z_ADR   : //Z2 to Q0Z
                                                      8'd0      ;

assign X25519_Src1 =
                         X25519State == X25519_S1   ? TP1_ADR    :// TP1
                         X25519State == X25519_S2   ? TP1_ADR    :// TP1
                         X25519State == X25519_S3   ? H_ADR    :// Q1X
                         X25519State == X25519_S33  ?  C1_ADR    :// Q1X
                         X25519State == X25519_S4   ? Q1Y_ADR    ://   Q1Y
                         X25519State == X25519_S5   ? Q1Z_ADR    ://   Q1Z
                         //X25519State == X25519_S9   ? Q1Y_ADR    ://   T4
                         X25519State == X25519_S9   ? X25519_Z2    ://   T4
                         X25519State == X25519_S10  ? TP1_ADR    ://   TP1
                         X25519State == X25519_S11  ? TP1_ADR    ://   T7
                         //X25519State == X25519_S12  ? Q1Y_ADR    ://   T6
                         X25519State == X25519_S12  ? X25519_Z2    ://   T6
                         X25519State == X25519_S13  ?  T6_ADR_PD ://   TP0
                         X25519State == X25519_S14  ?  T6_ADR_PD ://   T8
                         X25519State == X25519_S15  ?  T8_ADR_PD ://   T19
                         //X25519State == X25519_S16  ? Q1Z_ADR    ://   T9
                         //X25519State == X25519_S17  ? Q1Z_ADR    ://   T10
                         X25519State == X25519_S16  ? X25519_Z3   ://   T9
                         X25519State == X25519_S17  ? X25519_Z3   ://   T10
                         X25519State == X25519_S18  ? T10_ADR_PD ://   T11
                         X25519State == X25519_S19  ?  T6_ADR_PD ://   T12
                         X25519State == X25519_S20  ? T12_ADR_PD ://   T15
                         X25519State == X25519_S21  ? T15_ADR_PD ://   Q0Z
                         X25519State == X25519_S22  ? T12_ADR_PD ://   T13
                         X25519State == X25519_S23  ? TP1_ADR    ://   TP1
                         X25519State == X25519_S24  ? TP1_ADR    ://   T17
                         X25519State == X25519_S25  ? T17_ADR_PD ://   Q1Z
                         X25519State == X25519_S26  ?  T8_ADR_PD ://   Q1X
                         X25519State == X25519_S27  ? T19_ADR_PD ://   T18
                         X25519State == X25519_S28  ? T18_ADR_PD ://   T14
                         X25519State == X25519_S29  ? T19_ADR_PD ://   T19
                         X25519State == X25519_S32  ? T15_ADR_PD ://   TP1
                         X25519State == X25519_S34  ? TP1_ADR    : //X2 to TP1
                         X25519State == X25519_S35  ? TP1_ADR    : //TP1 to Q0X
                         X25519State == X25519_S36  ? X25519_Z2  : //Z2 to Q0Z
                                                      8'd0  ;

assign {PointEn_X25519,X25519_Dst}  =
                         X25519State == X25519_S1   ? TP1_ADR    :
                         X25519State == X25519_S2   ? Q0Z_ADR    :
                         X25519State == X25519_S3   ? Q1X_ADR    :
                         X25519State == X25519_S33  ? TP0_ADR    :
                         X25519State == X25519_S4   ? {1'b1,Q1Y_ADR}    :
                         X25519State == X25519_S5   ? Q1Z_ADR    :
                         X25519State == X25519_S9   ?  T4_ADR_PD :
                         X25519State == X25519_S10  ? TP1_ADR    :
                         X25519State == X25519_S11  ?  T7_ADR_PD :
                         X25519State == X25519_S12  ? {1'b1,T6_ADR_PD} :
                         X25519State == X25519_S13  ? TP0_ADR    :
                         X25519State == X25519_S14  ? {1'b1,T8_ADR_PD}:
                         X25519State == X25519_S15  ? {1'b1,T19_ADR_PD}:
                         X25519State == X25519_S16  ?  T9_ADR_PD :
                         X25519State == X25519_S17  ? {1'b1,T10_ADR_PD}:
                         X25519State == X25519_S18  ? T11_ADR_PD :
                         X25519State == X25519_S19  ? {1'b1,T12_ADR_PD} :
                         X25519State == X25519_S20  ? {1'b1,T15_ADR_PD}:
                         //X25519State == X25519_S21  ? Q0Z_ADR    :
                         X25519State == X25519_S21  ? X25519_X3    :
                         X25519State == X25519_S22  ? T13_ADR_PD :
                         X25519State == X25519_S23  ? TP1_ADR    :
                         X25519State == X25519_S24  ? {1'b1,T17_ADR_PD}:
                         //X25519State == X25519_S25  ? Q1Z_ADR    :
                         X25519State == X25519_S25  ? {1'b1,X25519_Z3}:
                         //X25519State == X25519_S26  ? Q1X_ADR    :
                         X25519State == X25519_S26  ? X25519_X2:
                         X25519State == X25519_S27  ? {1'b1,T18_ADR_PD}:
                         X25519State == X25519_S28  ? T14_ADR_PD :
                         //X25519State == X25519_S29  ? T19_ADR_PD :
                         X25519State == X25519_S29  ? {1'b1,X25519_Z2}:
                         X25519State == X25519_S32  ? TP0_ADR    :
                         X25519State == X25519_S34  ? TP1_ADR    : //X2 to TP1
                         X25519State == X25519_S35  ? Q0X_ADR    : //TP1 to Q0X
                         X25519State == X25519_S36  ? Q0Z_ADR    : //Z2 to Q0Z
                                                      9'd0  ;
//zxjian,20221123
always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        GcdState <= GCD_IDLE;
    else
        GcdState <= NextGcdState;
always @(*)
case(GcdState)
    GCD_IDLE:                        //Idle is S0
    begin
        if(StartGcd)
            NextGcdState = GCD_S1;
        else
            NextGcdState = GcdState;
    end
    GCD_S1:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S2;
        else
            NextGcdState = GcdState;
    end
    GCD_S2:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S3;
        else
            NextGcdState = GcdState;
    end
    GCD_S3:
    begin
//zxjian,20221125,added ErrorDetect
        if(GcdError)
            NextGcdState = GCD_END;

        else if(BIsZero)
            NextGcdState = GCD_S13;
        else
            NextGcdState = GCD_S4;
    end
    GCD_S4:
    begin
        if(AIsEven && BIsEven)
            NextGcdState = GCD_S5;
        else if(AIsEven)
            NextGcdState = GCD_S7;
        else if(BIsEven)
            NextGcdState = GCD_S8;
        else
            NextGcdState = GCD_S9;
    end
    GCD_S5:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S6;
        else
            NextGcdState = GcdState;
    end
    GCD_S6:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S3;
        else
            NextGcdState = GcdState;
    end
    GCD_S7:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S9;
        else
            NextGcdState = GcdState;
    end
    GCD_S8:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S9;
        else
            NextGcdState = GcdState;
    end
    GCD_S9:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S10;
        else
            NextGcdState = GcdState;
    end
    GCD_S10:
    begin
        if(CIsPos)
            NextGcdState = GCD_S11;
        else
            NextGcdState = GCD_S12;
    end
    GCD_S11:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S3;
        else
            NextGcdState = GcdState;
    end
    GCD_S12:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S3;
        else
            NextGcdState = GcdState;
    end
    GCD_S13:
    begin
        if(KIsZero)
            NextGcdState = GCD_END;
        else
            NextGcdState = GCD_S14;
    end
    GCD_S14:
    begin
        if(LongAlgDone)
            NextGcdState = GCD_S13;
        else
            NextGcdState = GcdState;
    end

    GCD_END:
    begin
            NextGcdState = GCD_IDLE;
    end
    default:
    begin
            NextGcdState = GCD_IDLE;
    end

endcase

assign GcdDone      = GcdState == GCD_END;

//this can be mergerd with modinv
//or change X1, X2, X3, Y1, Y2, Y3 to U, V, C;

assign KIsZero         = GcdDat==0; //Maximum K is 4095, KDat maybe 12bit? Expand to 16bit KDat

//KData Update
assign NextGcdDat        = (GcdState == GCD_S4) & AIsEven & BIsEven ? GcdDat + 1 :
                           (GcdState == GCD_S14)& LongAlgDone       ? GcdDat - 1 :
                                                                      GcdDat     ;

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    begin
    AIsEvenReg       <= 1'b0;
    BIsEvenReg       <= 1'b0;
    BIsZeroReg       <= 1'b0;
    CIsPosReg        <= 1'b0;
    GcdDat	     <= 16'h0000;
    end
else
    begin
    AIsEvenReg       <= AIsEven;
    BIsEvenReg       <= BIsEven;
    BIsZeroReg       <= BIsZero;
    CIsPosReg        <= CIsPos;
    GcdDat	     <= NextGcdDat;
    end

assign AIsEven        =
                         StartGcd                                                                                           ?         1'b0   :
                         (GcdState == GCD_S1 | GcdState == GCD_S5 | GcdState == GCD_S7 | GcdState == GCD_S11) & LongAlgDone ? ~LongAlgSR[2]  :
                                                                                                                               AIsEvenReg    ;

assign BIsEven        =
                         StartGcd                                                                                           ?         1'b0   :
                         (GcdState == GCD_S2 | GcdState == GCD_S6 | GcdState == GCD_S8 | GcdState == GCD_S12) & LongAlgDone ? ~LongAlgSR[2]  :
                                                                                                                               BIsEvenReg    ;

assign BIsZero         = StartGcd                                                                                           ?         1'b0   :
                         (GcdState == GCD_S2 | GcdState == GCD_S6 | GcdState == GCD_S8 | GcdState == GCD_S12) & LongAlgDone ?  LongAlgSR[0]  :
                                                                                                                               BIsZeroReg    ;

assign CIsPos          = StartGcd                            ?         1'b1  :
                         (GcdState == GCD_S9) & LongAlgDone  ? ~LongAlgSR[1] & ~LongAlgSR[0]: //A>B, A-B is not neg and not zero
                                                                   CIsPosReg ;

assign LongAlgStart_GCD =
                         GcdState == GCD_IDLE  & StartGcd     |
                         GcdState == GCD_S1    & LongAlgDone  |
                         GcdState == GCD_S4                   |
                         GcdState == GCD_S5    & LongAlgDone  |
                         GcdState == GCD_S7    & LongAlgDone  |
                         GcdState == GCD_S8    & LongAlgDone  |
                         GcdState == GCD_S10                  |
                         GcdState == GCD_S13   & ~KIsZero     ;

assign LongAlgOp_GCD    =                                        //SRC0    SRC1     DST
                         GcdState == GCD_S1   ? UNIT_A_MOV_B   : //GCD_A : GCD_CT : GCD_CT
                         GcdState == GCD_S2   ? UNIT_B_MOV_A   : //GCD_C : GCD_B  : GCD_C
                         GcdState == GCD_S5   ? UNIT_A_RHT_A   : //GCD_A : GCD_AT : GCD_A
                         GcdState == GCD_S6   ? UNIT_B_RHT_B   : //GCD_BT: GCD_B  : GCD_B
                         GcdState == GCD_S7   ? UNIT_A_RHT_A   : //GCD_A : GCD_AT : GCD_A
                         GcdState == GCD_S8   ? UNIT_B_RHT_B   : //GCD_BT: GCD_B  : GCD_B
                         GcdState == GCD_S9   ? UNIT_AB_SUB_A  : //GCD_A : GCD_B  : GCD_C
                         GcdState == GCD_S11  ? UNIT_AB_SUB_A  : //GCD_A : GCD_B  : GCD_A
                         GcdState == GCD_S12  ? UNIT_BA_SUB_B  : //GCD_A : GCD_B  : GCD_B
                         GcdState == GCD_S14  ? UNIT_A_LFT_A   : //GCD_A : GCD_AT : GCD_A
                                                UNIT_AB_ADD_A ;
assign GCD_Src0         =
                         GcdState == GCD_S1   ?  GCD_A :
                         GcdState == GCD_S2   ?  GCD_C :
                         GcdState == GCD_S5   ?  GCD_A :
                         GcdState == GCD_S6   ?  GCD_BT: //don't care
                         GcdState == GCD_S7   ?  GCD_A :
                         GcdState == GCD_S8   ?  GCD_BT:
                         GcdState == GCD_S9   ?  GCD_A :
                         GcdState == GCD_S11  ?  GCD_A :
                         GcdState == GCD_S12  ?  GCD_A :
                         GcdState == GCD_S14  ?  GCD_A:
                                                 GCD_A ;


assign GCD_Src1         =
                         GcdState == GCD_S1   ?  GCD_CT :
                         GcdState == GCD_S2   ?  GCD_B  :
                         GcdState == GCD_S5   ?  GCD_AT :
                         GcdState == GCD_S6   ?  GCD_B  :
                         GcdState == GCD_S7   ?  GCD_AT :
                         GcdState == GCD_S8   ?  GCD_B  :
                         GcdState == GCD_S9   ?  GCD_B  :
                         GcdState == GCD_S11  ?  GCD_B  :
                         GcdState == GCD_S12  ?  GCD_B  :
                         GcdState == GCD_S14  ?  GCD_AT :
                                                 GCD_A  ;


assign GCD_Dst          =
                         GcdState == GCD_S1   ?  GCD_CT :
                         GcdState == GCD_S2   ?  GCD_C  :
                         GcdState == GCD_S5   ?  GCD_A  :
                         GcdState == GCD_S6   ?  GCD_B  :
                         GcdState == GCD_S7   ?  GCD_A  :
                         GcdState == GCD_S8   ?  GCD_B  :
                         GcdState == GCD_S9   ?  GCD_C  :
                         GcdState == GCD_S11  ?  GCD_A  :
                         GcdState == GCD_S12  ?  GCD_B  :
                         GcdState == GCD_S14  ?  GCD_A  :
                                                 GCD_A  ;

//Error Cnt maybe deleted
always @(posedge Clk or negedge Resetn)
    if(~Resetn)
        GcdCnt <= 16'h0000;
    else
        GcdCnt <= NextGcdCnt;

assign NextGcdCnt = StartGcd                               ? 16'h0000   :
                   (GcdState == GCD_S4) &AIsEven & BIsEven ? GcdCnt + 1 :
                                                             GcdCnt     ;

assign GcdError = (GcdCnt >= 16'd8192);  //Is this enough?

//end,20221123

endmodule
