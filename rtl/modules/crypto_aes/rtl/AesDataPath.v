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


//one round without lineshift operation!!!
//
module AesDataPath (
            		DataIn,
            		MaskIn,
			RoundKeyIn,
			
			Enc,
			Dec,
			KeyEn,
			FirstRound,
			LastRound,
			DataOut
			);

input [31:0] DataIn;
input [31:0] MaskIn;
input [31:0] RoundKeyIn;

input        Enc;
input        Dec;
input        KeyEn;
input        FirstRound;
input        LastRound;

output [31:0]DataOut;

wire  [31:0] DataIn;
wire  [31:0] MaskIn;
wire  [31:0] RoundKeyIn;

wire         Enc;
wire         Dec;
wire         KeyEn;
wire         FirstRound;
wire         LastRound;

wire   [31:0]DataOut;

//zxjian,20221011			
//wire [31:0] MaskIn;
wire [31:0] MaskOut;
wire [31:0] SboxDataOut_tmp;
wire [31:0] DataIn_tmp;
wire [31:0] MixMaskOut;

//assign MaskIn = 32'haaaa5555;
//end,20221011


wire         e_d;
wire   [31:0]SboxDataOut;
wire   [31:0]MixColDataOut;

wire [31:0] RoundKeyOut;
//Enc or Dec
assign e_d = Dec ? 1'b1 : 1'b0; 

//zxjian,20221011, using mask sbox
// 1.1 Sbox
//AesSbox uSbox0( 
//             .e_d	(	e_d		),
//             .din	(	DataIn[7:0]	),
//             .dout	(	SboxDataOut[7:0])
//			 );
//			 
//AesSbox uSbox1( 
//             .e_d	(		e_d	),
//             .din	(	    DataIn[15:8]),
//             .dout	(      SboxDataOut[15:8])
//			 );
//			 
//AesSbox uSbox2( 
//             .e_d	(		e_d	),
//             .din	(          DataIn[23:16]),
//             .dout	(     SboxDataOut[23:16])
//			 );			 
//
//AesSbox uSbox3( 
//             .e_d	(		e_d	),
//             .din	(	   DataIn[31:24]),
//             .dout	(     SboxDataOut[31:24])
//			 );

assign DataIn_tmp = DataIn ^ MaskIn;

AesSbox uSbox0(
        .DataIn     (DataIn_tmp[7:0]		),
        .MaskIn     (MaskIn[7:0]		),
        .EncDec     (e_d			),
        .DataOut    (SboxDataOut_tmp[7:0]	),
        .MaskOut    (MaskOut[7:0]		)
        );

AesSbox uSbox1(
        .DataIn     (DataIn_tmp[15:8]		),
        .MaskIn     (MaskIn[15:8]		),
        .EncDec     (e_d			),
        .DataOut    (SboxDataOut_tmp[15:8]	),
        .MaskOut    (MaskOut[15:8]		)
        );

AesSbox uSbox2(
        .DataIn     (DataIn_tmp[23:16]		),
        .MaskIn     (MaskIn[23:16]		),
        .EncDec     (e_d			),
        .DataOut    (SboxDataOut_tmp[23:16]	),
        .MaskOut    (MaskOut[23:16]		)
        );

AesSbox uSbox3(
        .DataIn     (DataIn_tmp[31:24]	 	),
        .MaskIn     (MaskIn[31:24]		),
        .EncDec     (e_d			),
        .DataOut    (SboxDataOut_tmp[31:24]	),
        .MaskOut    (MaskOut[31:24]		)
        );

//assign SboxDataOut = SboxDataOut_tmp ^ MaskOut;
assign SboxDataOut = SboxDataOut_tmp ;
//end,zxjian,20221011

//1.2 MixCol Data
AesMixCol uMixColData( 
               .DIn     (            SboxDataOut),
               .E_D	(                    e_d),
               .DOut    (          MixColDataOut)            
              );

//1.2a MixCol Mask
AesMixCol uMixColDataMask( 
               .DIn     (            MaskOut    ),
               .E_D	(                    e_d),
               .DOut    (          MixMaskOut  )            
              );

// InvMixCol for RoundKey
// InvMixCol for RoundKey
AesMixCol uMixColKey( 
               .DIn     (RoundKeyIn		),
               .E_D	(e_d			),
               .DOut    (RoundKeyOut		)            
              );

//1.3 Xor
assign DataOut = 
                Enc & FirstRound   ? DataIn ^ RoundKeyIn  	:
//zxjian,20221011,using mask sbox
                //Enc & LastRound    ? SboxDataOut ^ RoundKeyIn    :
                //Enc                ? MixColDataOut ^ RoundKeyIn  :
                //Dec & FirstRound   ? DataIn ^ RoundKeyIn  	   :
                //Dec & LastRound    ? SboxDataOut ^ RoundKeyIn    :
                //Dec                ? MixColDataOut ^ RoundKeyOut :
	        //KeyEn              ? SboxDataOut                 :
                Enc & LastRound    ? SboxDataOut ^ RoundKeyIn  	 ^ MaskOut:
                Enc                ? MixColDataOut ^ RoundKeyIn  ^ MixMaskOut:
                Dec & FirstRound   ? DataIn ^ RoundKeyIn  	 :
                Dec & LastRound    ? SboxDataOut ^ RoundKeyIn    ^ MaskOut:
                Dec                ? MixColDataOut ^ RoundKeyOut ^ MixMaskOut:
	        KeyEn              ? SboxDataOut                 ^ MaskOut:
//end,zxjian,20221011
	         	                                  32'h00;


endmodule
