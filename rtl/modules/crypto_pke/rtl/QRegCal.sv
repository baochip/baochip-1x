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

module QRegCal2#(
    parameter QW = 256,
    parameter DW = 64,
    parameter DWW =8
    )
    (
       Clk,
       Resetn,
       N0Dat,
       StartQCal,

       QReg,
       EndQCal
       );
input         Clk;
input         Resetn;
input  [QW-1:0] N0Dat;
input         StartQCal;

output [QW-1:0] QReg;
output        EndQCal;


wire          Clk;
wire          Resetn;
wire   [QW-1:0] N0Dat;
wire          StartQCal;

wire          EndQCal;

parameter Q_IDLE	= 2'b00;
parameter Q_CALC	= 2'b01;
parameter Q_END		= 2'b10;


//1 signals
//

    bit [QW/DW:0][DW-1:0] N0Dat0;
    bit [QW/DW:0][DW-1:0] DiffReg;
    bit [QW/DW:0] cr;
    bit [7:0] QSubCnt;
    bit QSubCntDone;

reg  [1 :0] QState;
reg  [1 :0] NextQState;
reg  [DWW :0] QCnt;
wire [DWW :0] NextQCnt;
wire        QCalEnd;

reg        QRegBit;

reg  [QW-1:0] QReg;
wire [QW-1:0] NextQReg;


logic clk,resetn;

assign clk = Clk;
assign resetn = Resetn;


//2 FSM
//
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    QState <= Q_IDLE;
else
    QState <= NextQState;

always @(*)
case(QState)
    Q_IDLE:
        if(StartQCal)
            NextQState = Q_CALC;
        else
            NextQState = Q_IDLE;
    Q_CALC:
        if(QCalEnd)
            NextQState = Q_END;
        else
            NextQState = Q_CALC;
    Q_END:
            NextQState = Q_IDLE;
    default:
            NextQState = Q_IDLE;
endcase

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    QCnt <= 'd0;
else
    QCnt <= NextQCnt;

assign NextQCnt = StartQCal      ? 'd0   :
                  QSubCntDone & QState==Q_CALC ? QCnt+1 :
                                   QCnt   ;
assign QCalEnd = QSubCntDone & (QCnt == QW-1);

assign EndQCal = QState == Q_END;



always@(posedge Clk or negedge Resetn)
if(~Resetn)
    QSubCnt <= 'd0;
else
    QSubCnt <= StartQCal | QSubCntDone ? 0 : QSubCnt + (QState==Q_CALC);

assign QSubCntDone = ( QSubCnt == QW/DW ) ;

// 3 DataPath
//

    assign N0Dat0 = N0Dat;
    `theregrn( DiffReg[4] ) <= '0;
    `theregrn( cr[0] ) <= DiffReg[0][0] && N0Dat0[0];

genvar i;
generate
    for (i = 0; i < 4; i++) begin: gen_diffreg
        `theregrn( { cr[i+1], DiffReg[i]} ) <= ( QState == 0 ) | StartQCal ? (i==0) : (QState==Q_CALC) & ( QSubCnt == i ) ? { DiffReg[i+1][0], DiffReg[i][DW-1:1] } + ( QRegBit ? {N0Dat0[i+1][0],N0Dat0[i][DW-1:1] }+ cr[i]: 0 ) : DiffReg[i] ;
    end
endgenerate


`theregrn( QRegBit ) <= StartQCal ? '1 : QSubCntDone ? DiffReg[0][0] : QRegBit;


//4 Output
//

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    QReg <= 'd1;
else
    QReg <= (QState == Q_CALC) & QSubCntDone ? {QRegBit, QReg[QW-1:1]}:QReg;//NextQReg;






generate
    for(i = 0; i < QW; i = i+1) begin
//            assign NextQReg[i]  = (QState == Q_CALC) & (QCnt == i ) & QSubCnt ? QRegBit : QReg[i];
    end
    endgenerate


endmodule

`ifdef SIM_QREGCAL
module QRegCal_tb2();

    parameter DW = 256;
    bit Clk, Resetn, StartQCal, EndQCal;
    bit [DW-1:0]  N0Dat, QReg;

    QRegCal2 dut(
    .Clk(Clk),
    .Resetn(Resetn),
    .StartQCal(StartQCal),
    .N0Dat(N0Dat),
    .QReg(QReg),
    .EndQCal(EndQCal)

    );
        initial forever #5 Clk = ~Clk;

    `maintest(QRegCal_tb2, QRegCal_tb2)
    $display("Testing modified QReg Calculation");



    Resetn = 0;
    #(103) Resetn = 1;
    // assign  N0Dat = 64'h7ab49b369e220129;
        assign  N0Dat =256'h8e54750e723d8eada99445de2b8e3e58881070949fd5891c7ab49b369e220129;

        #( 1 `US );
        @(negedge Clk) StartQCal = 1;
        @(negedge Clk) StartQCal  = 0;

        @(posedge EndQCal);

    #(10 `US);
        $display("Showing QReg %x", QReg);
//2d6750782f0d51c27e24c3b564e50238a733669e4252f9dabffbfa7407e3d4e7
//2d6750782f0d51c27e24c3b564e50238a733669e4252f9dabffbfa7407e3d4e7
`maintestend

endmodule
`endif