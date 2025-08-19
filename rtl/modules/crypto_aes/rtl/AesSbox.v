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

//---------------------------------------
module AesSbox(
              DataIn  ,
              MaskIn  ,
              EncDec	,
              DataOut ,
              MaskOut
              );

input   [7  :0] DataIn	; 
input   [7  :0] MaskIn	;
input           EncDec	;
output  [7  :0] DataOut	;
output  [7  :0] MaskOut	;

wire    [7  :0] DataIn	; 
wire    [7  :0] MaskIn	;
wire            EncDec	;
wire    [7  :0] DataOut	;
wire    [7  :0] MaskOut	;

wire    [7  :0] DataDecForInv		;
wire    [7  :0] MaskDecForInv		;
wire    [7  :0] DataEncForInv		;
wire    [7  :0] MaskEncForInv		;
wire    [7  :0] DataInForGfInv		;
wire    [7  :0] MaskInForGfInv		;
wire    [7  :0] DataOutForGfInv		;
wire    [7  :0] DataFromInv     	;
wire    [7  :0] DataAffTransForDec	;    
wire    [7  :0] DataAffTransForEnc	;
wire    [7  :0] MaskAffTransForDec	;    
wire    [7  :0] MaskAffTransForEnc	;

//aff_trans for dec           
assign DataAffTransForDec[7] =   DataIn[6] ^ DataIn[4] ^ DataIn[1] ;
assign DataAffTransForDec[6] =   DataIn[5] ^ DataIn[3] ^ DataIn[0]  ;
assign DataAffTransForDec[5] =   DataIn[7] ^ DataIn[4] ^ DataIn[2] ;
assign DataAffTransForDec[4] =   DataIn[6] ^ DataIn[3] ^ DataIn[1]  ;
assign DataAffTransForDec[3] =   DataIn[5] ^ DataIn[2] ^ DataIn[0]  ;
assign DataAffTransForDec[2] =   ~(DataIn[7] ^ DataIn[4] ^ DataIn[1])  ;
assign DataAffTransForDec[1] =   DataIn[6] ^ DataIn[3] ^ DataIn[0]  ;
assign DataAffTransForDec[0] =   ~(DataIn[7] ^ DataIn[5] ^ DataIn[2])  ;

assign MaskAffTransForDec[7] = MaskIn[6] ^ MaskIn[4] ^ MaskIn[1]  ;
assign MaskAffTransForDec[6] = MaskIn[5] ^ MaskIn[3] ^ MaskIn[0]  ;
assign MaskAffTransForDec[5] = MaskIn[7] ^ MaskIn[4] ^ MaskIn[2]  ;
assign MaskAffTransForDec[4] = MaskIn[6] ^ MaskIn[3] ^ MaskIn[1]  ;
assign MaskAffTransForDec[3] = MaskIn[5] ^ MaskIn[2] ^ MaskIn[0]  ;
assign MaskAffTransForDec[2] = MaskIn[7] ^ MaskIn[4] ^ MaskIn[1]  ;
assign MaskAffTransForDec[1] = MaskIn[6] ^ MaskIn[3] ^ MaskIn[0]  ;
assign MaskAffTransForDec[0] = MaskIn[7] ^ MaskIn[5] ^ MaskIn[2]  ;

assign DataDecForInv[0] = DataAffTransForDec[0] ^ DataAffTransForDec[4] ^ DataAffTransForDec[5] ^ DataAffTransForDec[6] ;
assign DataDecForInv[1] = DataAffTransForDec[0] ^ DataAffTransForDec[1] ^ DataAffTransForDec[2] ^ DataAffTransForDec[5] ^ DataAffTransForDec[6] ^ DataAffTransForDec[7];
assign DataDecForInv[2] = DataAffTransForDec[0] ^ DataAffTransForDec[5] ^ DataAffTransForDec[6] ^ DataAffTransForDec[7];
assign DataDecForInv[3] = DataAffTransForDec[0] ^ DataAffTransForDec[1] ^ DataAffTransForDec[5] ^ DataAffTransForDec[6];
assign DataDecForInv[4] = DataAffTransForDec[0] ;
assign DataDecForInv[5] = DataAffTransForDec[0] ^ DataAffTransForDec[1] ^ DataAffTransForDec[3] ^ DataAffTransForDec[4] ^ DataAffTransForDec[7];
assign DataDecForInv[6] = DataAffTransForDec[0] ^ DataAffTransForDec[1] ^ DataAffTransForDec[2] ^ DataAffTransForDec[3] ^ DataAffTransForDec[6];
assign DataDecForInv[7] = DataAffTransForDec[0] ^ DataAffTransForDec[5] ^ DataAffTransForDec[6];

assign MaskDecForInv[0] = MaskAffTransForDec[0] ^ MaskAffTransForDec[4] ^ MaskAffTransForDec[5] ^ MaskAffTransForDec[6] ;
assign MaskDecForInv[1] = MaskAffTransForDec[0] ^ MaskAffTransForDec[1] ^ MaskAffTransForDec[2] ^ MaskAffTransForDec[5] ^ MaskAffTransForDec[6] ^ MaskAffTransForDec[7];
assign MaskDecForInv[2] = MaskAffTransForDec[0] ^ MaskAffTransForDec[5] ^ MaskAffTransForDec[6] ^ MaskAffTransForDec[7];
assign MaskDecForInv[3] = MaskAffTransForDec[0] ^ MaskAffTransForDec[1] ^ MaskAffTransForDec[5] ^ MaskAffTransForDec[6];
assign MaskDecForInv[4] = MaskAffTransForDec[0] ;
assign MaskDecForInv[5] = MaskAffTransForDec[0] ^ MaskAffTransForDec[1] ^ MaskAffTransForDec[3] ^ MaskAffTransForDec[4] ^ MaskAffTransForDec[7];
assign MaskDecForInv[6] = MaskAffTransForDec[0] ^ MaskAffTransForDec[1] ^ MaskAffTransForDec[2] ^ MaskAffTransForDec[3] ^ MaskAffTransForDec[6];
assign MaskDecForInv[7] = MaskAffTransForDec[0] ^ MaskAffTransForDec[5] ^ MaskAffTransForDec[6];

assign DataEncForInv[0] = DataIn[0] ^ DataIn[4] ^ DataIn[5] ^ DataIn[6] ;
assign DataEncForInv[1] = DataIn[0] ^ DataIn[1] ^ DataIn[2] ^ DataIn[5] ^ DataIn[6] ^ DataIn[7];
assign DataEncForInv[2] = DataIn[0] ^ DataIn[5] ^ DataIn[6] ^ DataIn[7];
assign DataEncForInv[3] = DataIn[0] ^ DataIn[1] ^ DataIn[5] ^ DataIn[6];
assign DataEncForInv[4] = DataIn[0] ;
assign DataEncForInv[5] = DataIn[0] ^ DataIn[1] ^ DataIn[3] ^ DataIn[4] ^ DataIn[7];
assign DataEncForInv[6] = DataIn[0] ^ DataIn[1] ^ DataIn[2] ^ DataIn[3] ^ DataIn[6];
assign DataEncForInv[7] = DataIn[0] ^ DataIn[5] ^ DataIn[6];

assign MaskEncForInv[0] = MaskIn[0] ^ MaskIn[4] ^ MaskIn[5] ^ MaskIn[6] ;
assign MaskEncForInv[1] = MaskIn[0] ^ MaskIn[1] ^ MaskIn[2] ^ MaskIn[5] ^ MaskIn[6] ^ MaskIn[7];
assign MaskEncForInv[2] = MaskIn[0] ^ MaskIn[5] ^ MaskIn[6] ^ MaskIn[7];
assign MaskEncForInv[3] = MaskIn[0] ^ MaskIn[1] ^ MaskIn[5] ^ MaskIn[6];
assign MaskEncForInv[4] = MaskIn[0] ;
assign MaskEncForInv[5] = MaskIn[0] ^ MaskIn[1] ^ MaskIn[3] ^ MaskIn[4] ^ MaskIn[7];
assign MaskEncForInv[6] = MaskIn[0] ^ MaskIn[1] ^ MaskIn[2] ^ MaskIn[3] ^ MaskIn[6];
assign MaskEncForInv[7] = MaskIn[0] ^ MaskIn[5] ^ MaskIn[6];

//inverse
assign DataInForGfInv = EncDec ? DataDecForInv: DataEncForInv; 
assign MaskInForGfInv = EncDec ? MaskDecForInv: MaskEncForInv; 


Gf256Inv uGf256Inv(
                 .DataIn      (DataInForGfInv  ),
                 .MaskIn      (MaskInForGfInv  ),
                 .DataOut     (DataOutForGfInv )
                  );

//aff for enc
assign DataFromInv[0] = DataOutForGfInv[4] ;
assign DataFromInv[1] = DataOutForGfInv[3] ^ DataOutForGfInv[7];
assign DataFromInv[2] = DataOutForGfInv[1] ^ DataOutForGfInv[2] ^ DataOutForGfInv[3] ^ DataOutForGfInv[7];
assign DataFromInv[3] = DataOutForGfInv[0] ^ DataOutForGfInv[2] ^ DataOutForGfInv[3] ^ DataOutForGfInv[4] ^ DataOutForGfInv[5] ^ DataOutForGfInv[7];
assign DataFromInv[4] = DataOutForGfInv[0] ^ DataOutForGfInv[7];
assign DataFromInv[5] = DataOutForGfInv[0] ^ DataOutForGfInv[1] ^ DataOutForGfInv[3] ^ DataOutForGfInv[4] ^ DataOutForGfInv[5] ^ DataOutForGfInv[6];
assign DataFromInv[6] = DataOutForGfInv[0] ^ DataOutForGfInv[1] ^ DataOutForGfInv[3] ^ DataOutForGfInv[5] ^ DataOutForGfInv[6] ^ DataOutForGfInv[7];
assign DataFromInv[7] = DataOutForGfInv[2] ^ DataOutForGfInv[7];

assign DataAffTransForEnc[0] = ~(DataFromInv[0] ^ DataFromInv[4] ^ DataFromInv[5] ^ DataFromInv[6] ^ DataFromInv[7]);
assign DataAffTransForEnc[1] = ~(DataFromInv[0] ^ DataFromInv[1] ^ DataFromInv[5] ^ DataFromInv[6] ^ DataFromInv[7]);
assign DataAffTransForEnc[2] =   DataFromInv[0] ^ DataFromInv[1] ^ DataFromInv[2] ^ DataFromInv[6] ^ DataFromInv[7];
assign DataAffTransForEnc[3] =   DataFromInv[0] ^ DataFromInv[1] ^ DataFromInv[2] ^ DataFromInv[3] ^ DataFromInv[7];
assign DataAffTransForEnc[4] =   DataFromInv[0] ^ DataFromInv[1] ^ DataFromInv[2] ^ DataFromInv[3] ^ DataFromInv[4];
assign DataAffTransForEnc[5] = ~(DataFromInv[1] ^ DataFromInv[2] ^ DataFromInv[3] ^ DataFromInv[4] ^ DataFromInv[5]);
assign DataAffTransForEnc[6] = ~(DataFromInv[2] ^ DataFromInv[3] ^ DataFromInv[4] ^ DataFromInv[5] ^ DataFromInv[6]);
assign DataAffTransForEnc[7] =   DataFromInv[3] ^ DataFromInv[4] ^ DataFromInv[5] ^ DataFromInv[6] ^ DataFromInv[7];

assign MaskAffTransForEnc[0] = MaskIn[0] ^ MaskIn[4] ^ MaskIn[5] ^ MaskIn[6] ^ MaskIn[7];
assign MaskAffTransForEnc[1] = MaskIn[0] ^ MaskIn[1] ^ MaskIn[5] ^ MaskIn[6] ^ MaskIn[7];
assign MaskAffTransForEnc[2] = MaskIn[0] ^ MaskIn[1] ^ MaskIn[2] ^ MaskIn[6] ^ MaskIn[7];
assign MaskAffTransForEnc[3] = MaskIn[0] ^ MaskIn[1] ^ MaskIn[2] ^ MaskIn[3] ^ MaskIn[7];
assign MaskAffTransForEnc[4] = MaskIn[0] ^ MaskIn[1] ^ MaskIn[2] ^ MaskIn[3] ^ MaskIn[4];
assign MaskAffTransForEnc[5] = MaskIn[1] ^ MaskIn[2] ^ MaskIn[3] ^ MaskIn[4] ^ MaskIn[5];
assign MaskAffTransForEnc[6] = MaskIn[2] ^ MaskIn[3] ^ MaskIn[4] ^ MaskIn[5] ^ MaskIn[6];
assign MaskAffTransForEnc[7] = MaskIn[3] ^ MaskIn[4] ^ MaskIn[5] ^ MaskIn[6] ^ MaskIn[7];

assign DataOut = EncDec ? DataFromInv : DataAffTransForEnc;
assign MaskOut = EncDec ? MaskAffTransForDec : MaskAffTransForEnc;

endmodule
