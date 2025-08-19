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


module PkeRamMux(
             Clk                 ,
             Resetn              ,
             BasicStart        ,
             BasicDone         ,
             ModMulStart            ,
             ModMulDone             ,
             Src0Adr             ,
             Src1Adr             ,
             DstAdr              ,
             PointEn             ,
             ModMulEn               ,
             RsaMode            ,
             ExpMode            ,
             MimmMode,

             ModInvRamRd ,
             ModInvRamAdr,

             BasicRamRd1        ,
             BasicRamRd2        ,
             BasicRamWr1        ,
             BasicRamWr2        ,
             BasicRamAddr1      ,
             BasicRamAddr2      ,
             BasicRamDat1       ,
             BasicRamDat2       ,

             ModMulRamRdA            ,
             ModMulRamRdB            ,
             ModMulRamRdM            ,
             ModMulRamRdN            ,
             ModMulRamWr1            ,
             ModMulRamWr2            ,
             ModMulRamAddr1          ,
             ModMulRamAddr2          ,
             ModMulRamDat1           ,
             ModMulRamDat2           ,
             ModMulLongSrcAddr1      ,
             ModMulLongSrcAddr2      ,
             ModMulLongDstAddr       ,

             PkeRamRd0            ,
             PkeRamWr0            ,
             PkeRamAddr0          ,
             PkeRamDat0           ,
             PkeRamRd1            ,
             PkeRamWr1            ,
             PkeRamAddr1          ,
             PkeRamDat1
            );

// i) signal declare
input           Clk;
input           Resetn;
input           BasicStart;
input           BasicDone;
input           ModMulStart;
input           ModMulDone;

input    [8 :0] Src0Adr;
input    [8 :0] Src1Adr;
input           PointEn;
output          ModMulEn;

input           RsaMode;
input           ExpMode;
input           MimmMode;
input    [8 :0] DstAdr;

input           ModInvRamRd;
input    [8:0]  ModInvRamAdr;

input           BasicRamRd1;
input           BasicRamRd2;
input           BasicRamWr1;
input           BasicRamWr2;
input     [8:0] BasicRamAddr1;
input     [8:0] BasicRamAddr2;
input    [63:0] BasicRamDat1;
input    [63:0] BasicRamDat2;

input           ModMulRamRdA;
input           ModMulRamRdB;
input           ModMulRamRdM;
input           ModMulRamRdN;
input           ModMulRamWr1;
input           ModMulRamWr2;
input     [8:0] ModMulRamAddr1;
input     [8:0] ModMulRamAddr2;
input    [63:0] ModMulRamDat1;
input    [63:0] ModMulRamDat2;
input     [8:0] ModMulLongSrcAddr1;
input     [8:0] ModMulLongSrcAddr2;
input     [8:0] ModMulLongDstAddr;

output          PkeRamRd0;
output          PkeRamWr0;
output    [8:0] PkeRamAddr0;
output   [63:0] PkeRamDat0;
output          PkeRamRd1;
output          PkeRamWr1;
output    [8:0] PkeRamAddr1;
output   [63:0] PkeRamDat1;

//=============wire===========================
wire            Clk;
wire            Resetn;
wire            BasicStart;
wire            BasicDone;
wire            ModMulStart;
wire            ModMulDone;
wire     [8 :0] Src0Adr;
wire     [8 :0] Src1Adr;
wire     [8 :0] DstAdr;

wire            BasicRamRd1;
wire            BasicRamRd2;
wire            BasicRamWr1;
wire            BasicRamWr2;
wire      [8:0] BasicRamAddr1;
wire      [8:0] BasicRamAddr2;
wire     [63:0] BasicRamDat1;
wire     [63:0] BasicRamDat2;

wire            ModMulRamRdA;
wire            ModMulRamRdB;
wire            ModMulRamRdM;
wire            ModMulRamRdN;
wire            ModMulRamWr1;
wire            ModMulRamWr2;
wire      [8:0] ModMulRamAddr1;
wire      [8:0] ModMulRamAddr2;
wire     [63:0] ModMulRamDat1;
wire     [63:0] ModMulRamDat2;
wire      [8:0] ModMulLongSrcAddr1;
wire      [8:0] ModMulLongSrcAddr2;
wire      [8:0] ModMulLongDstAddr;

wire            PkeRamRd0;
wire            PkeRamWr0;
wire      [8:0] PkeRamAddr0;
wire     [63:0] PkeRamDat0;
wire            PkeRamRd1;
wire            PkeRamWr1;
wire      [8:0] PkeRamAddr1;
wire     [63:0] PkeRamDat1;

//==============Internal Signal===============
reg             BasicEn;
reg             ModMulEn;

wire            RsaMode;
wire            ExpMode;
wire            MimmMode;


wire      [8:0] LongRam1AddrSrc;
wire      [8:0] LongRam2AddrSrc;

wire      [8:0] ModMulRam1AddrSrc;
wire      [8:0] ModMulRam2AddrSrc;
wire      [8:0] ModMulRam1Addr;
wire      [8:0] ModMulRam2Addr;

wire      [8:0] BasicRam1Addr;
wire      [8:0] BasicRam2Addr;

wire           PointEn;
wire           ModInvRamRd;
wire    [8:0]  ModInvRamAdr;

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    BasicEn 	<= 1'b0;
else if(BasicStart)
    BasicEn 	<= 1'b1;
else if(BasicDone)
    BasicEn	<= 1'b0;

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    ModMulEn 	<= 1'b0;
else if(ModMulStart)
    ModMulEn 	<= 1'b1;
else if(ModMulDone)
    ModMulEn	<= 1'b0;


assign LongRam1AddrSrc =
                         ModMulEn       & BasicRamRd1 & ~RsaMode ? ModMulLongSrcAddr1 + 8'h24  : //N-Value
                         ModMulEn       & BasicRamRd1 & RsaMode  ? ModMulLongSrcAddr1 + 9'h100  :
                         ModMulEn       & BasicRamWr1 ? DstAdr           :
                         BasicRamRd1               ? Src0Adr          :
                         BasicRamWr1               ? DstAdr           :
                                                       8'h0;

assign LongRam2AddrSrc =
                         ModMulEn & BasicRamRd2 & ~RsaMode ? ModMulLongSrcAddr2 + 8'h2D  :  //M-Value
                         ModMulEn & BasicRamRd2 &  RsaMode ? ModMulLongSrcAddr2 + 9'h180  : // was 8'hc0@4kb //0x4000_1600
                         BasicRamRd2               ? Src1Adr                  :
                         BasicRamWr2               ? DstAdr                   :
                                                       8'h0;

assign BasicRam1Addr = LongRam1AddrSrc + BasicRamAddr1;

assign BasicRam2Addr = LongRam2AddrSrc + BasicRamAddr2;

assign ModMulRam1AddrSrc = ModMulRamRdA         ? Src0Adr :

                        ModMulRamRdN & ~RsaMode ? 8'h24   : //N-Value
                        ModMulRamRdN &  RsaMode ? 9'h100   :  //0x4000_1400
                        ModMulRamWr1 ? DstAdr :
                                                  8'h0;

assign ModMulRam2AddrSrc = ModMulRamRdB                          ? Src1Adr :
                        (ModMulRamRdM | ModMulRamWr2) & ~RsaMode ? 8'h2D   :  //M-Value
                        (ModMulRamRdM | ModMulRamWr2) & RsaMode  ? 9'h180   : // was 8'hc0@4kb  //0x4000_1600
                                                                   8'h00   ;

assign ModMulRam1Addr = ModMulRam1AddrSrc + ModMulRamAddr1;

assign ModMulRam2Addr = ModMulRam2AddrSrc + ModMulRamAddr2;


assign PkeRamRd0    = BasicRamRd1 | ModMulRamRdA | ModMulRamRdN |ModInvRamRd;

assign PkeRamWr0    =  ~PointEn & BasicRamWr1 | ModMulRamWr1;

assign PkeRamAddr0  =
                      BasicEn  ?  BasicRam1Addr :
                      ModMulEn      ?  ModMulRam1Addr     :
                                       ModInvRamAdr + 8'h2D;

assign PkeRamDat0    =
                       BasicEn  ? BasicRamDat1  :
                       ModMulEn      ? ModMulRamDat1      :
                                    64'h0;

assign PkeRamRd1    = BasicRamRd2 | ModMulRamRdB | ModMulRamRdM;

assign PkeRamWr1    =
                      RsaMode & ExpMode & PkeRamWr0 ? PkeRamWr0 :
                      PointEn & BasicRamWr1? BasicRamWr1:
                              BasicRamWr2 | ModMulRamWr2;

assign PkeRamAddr1  =
                      RsaMode & ( BasicRamWr1 | MimmMode & ModMulRamWr1 ) ? PkeRamAddr0 :
                      PointEn & BasicRamWr1? PkeRamAddr0 :
                      BasicEn  ?  BasicRam2Addr      :
                      ModMulEn      ?  ModMulRam2Addr          :
                                    8'h00;

assign PkeRamDat1    =
                        RsaMode & BasicRamWr1 ? PkeRamDat0 :
                        PointEn & BasicRamWr1 ? PkeRamDat0 :
                        BasicEn  ? BasicRamDat2  :
                        ModMulEn      ? ModMulRamDat2      :
                                     64'h0;


endmodule
