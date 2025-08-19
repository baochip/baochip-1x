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



module AesCore(
                Clk,
		Resetn,
		StartAes,
		AesIR,
		AesLen,
		AesMode,
		
		AesRamRd,
		AesRamWr,
		AesRamAdr,
		AesRamDat,
		RamAesDat,
	
		MaskIn,
	
		AesDone);


input          Clk	;
input          Resetn	;
input          StartAes	;
input   [1:0]  AesIR	;
input   [1:0]  AesLen	;
input   [2:0]  AesMode	;
output         AesRamRd	;
output         AesRamWr	;
output  [7:0]  AesRamAdr;
output  [31:0] AesRamDat;
input   [31:0] RamAesDat;
input   [31:0] MaskIn   ;
output         AesDone	;

wire           Clk	;
wire           Resetn	;
wire           StartAes	;
wire    [1:0]  AesIR	;
wire    [1:0]  AesLen	;
wire    [2:0]  AesMode	;
wire           AesRamRd	;
wire           AesRamWr	;
wire    [7:0]  AesRamAdr;
wire    [31:0] AesRamDat;
wire    [31:0] RamAesDat;
wire    [31:0] MaskIn   ;
wire           AesDone	;

wire KeyEn;
wire EncEn;
wire DecEn;
wire FirstRound;
wire LastRound;

wire [31:0] DataIn;
wire [31:0] DataOut;

wire [31:0] RoundKeyIn;


AesCtrl uCtrl(
        .Clk      (Clk			),
	.Resetn   (Resetn		),
	.StartAes (StartAes		),
	.AesIR    (AesIR		), //00 for KeyExp, 01 for Enc, 10 for Dec
	.AesLen   (AesLen		), //00 for 128bit, 01 for 192bit, 10 for 256bit
	.AesMode  (AesMode		), //00 for ECB ,01 for CBC , 10 for 
	
	.AesRamRd (AesRamRd		),
	.AesRamWr (AesRamWr		),
	.AesRamAdr(AesRamAdr		),
	.AesRamDat(AesRamDat		),
	.RamAesDat(RamAesDat		),

        .KeyEn    (KeyEn		),
        .EncEn    (EncEn		),
        .DecEn    (DecEn		),
        .DataPathCtrlDat    (DataOut	),
        .CtrlDataPathDat    (DataIn	),
	.LastRound(LastRound		),
	.FirstRound(FirstRound		),
	
	.AesDone  (AesDone		)
	);

 AesDataPath uDataPath(
        .DataIn		(DataIn			),
        .MaskIn		(MaskIn			),
	.RoundKeyIn	(RamAesDat              ), 
	.Enc		(EncEn			),
	.Dec		(DecEn			),
	.KeyEn		(KeyEn			),
	.FirstRound	(FirstRound		),
	.LastRound	(LastRound		),
	.DataOut	(DataOut		)
	);


endmodule
