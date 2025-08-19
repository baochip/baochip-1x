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


//zxjian,20230207 
//added AesMode 
//ECB：001，CBC：010，CFB：011， OFB：100，CTR：101
module AesCtrl(
                Clk      ,
		Resetn   ,
		StartAes ,
		AesIR    , //00 for KeyExp, 01 for Enc, 10 for Dec
		AesLen   , //00 for 128bit, 01 for 192bit, 10 for 256bit
		AesMode  , //00 for ECB ,01 for CBC , 10 for OFB,11 for CFB, 
		
		AesRamRd ,
		AesRamWr ,
		AesRamAdr,
		AesRamDat,
		RamAesDat,
	

                KeyEn,
                EncEn,
                DecEn,
                FirstRound,
                LastRound,
                DataPathCtrlDat,
                CtrlDataPathDat,
	
		AesDone
		);


input        Clk;
input        Resetn;
input        StartAes;
input [1 :0] AesIR;
input [1 :0] AesLen;
input [2 :0] AesMode;

output       KeyEn;
output       EncEn;
output       DecEn;
output       FirstRound;
output       LastRound;
output       AesDone;

input  [31:0]DataPathCtrlDat;
output [31:0]CtrlDataPathDat;

output       AesRamRd;
output       AesRamWr;
output [7:0] AesRamAdr;
output [31:0]AesRamDat;
input  [31:0]RamAesDat;

wire         Clk;
wire         Resetn;
wire         StartAes;
wire  [1 :0] AesIR;
wire  [1 :0] AesLen;
wire  [2 :0] AesMode;

wire         KeyEn;
wire         EncEn;
wire         DecEn;
wire         FirstRound;
wire         LastRound;
wire         AesDone;

wire   [31:0]DataPathCtrlDat;
wire   [31:0]CtrlDataPathDat;

wire         AesRamRd;
wire         AesRamWr;
wire   [7:0] AesRamAdr;
wire   [31:0]AesRamDat;
wire   [31:0]RamAesDat;

//parameters
//parameters
//	
parameter AES_IDLE	= 3'b000;
parameter AES_START	= 3'b001;
parameter AES_KEYEXP	= 3'b010;
parameter AES_ENC	= 3'b011;
parameter AES_DONE	= 3'b100;
//zxjian,20230207
parameter AES_MODE0	= 3'b101;
parameter AES_MODE1	= 3'b110;
	
parameter KEY_IDLE	= 3'b000;
parameter KEY_START	= 3'b001;                             	
parameter KEY_LOAD	= 3'b010;				 	
parameter KEY_EXP	= 3'b011;                             	
parameter KEY_STORE	= 3'b100;                             	
parameter KEY_READ	= 3'b101;				 	
parameter KEY_DONE	= 3'b111;

parameter EN_IDLE	= 3'b000;
parameter EN_START	= 3'b001;                             	
parameter EN_LOAD	= 3'b010;				 	
parameter EN_ROUND0	= 3'b011;                             	
parameter EN_ROUND1	= 3'b100;                             	
parameter EN_STORE	= 3'b101;                             	
parameter EN_DONE	= 3'b111;

parameter MODE0_IDLE	= 5'd0 ;
parameter MODE0_START	= 5'd1 ;
parameter MODE0_READ0 	= 5'd2 ; 
parameter MODE0_READ1    = 5'd3 ; 
parameter MODE0_READ2    = 5'd4 ; 
parameter MODE0_READ3    = 5'd5 ; 
parameter MODE0_READ4    = 5'd6 ; 
parameter MODE0_READ5    = 5'd7 ; 
parameter MODE0_READ6    = 5'd8 ; 
parameter MODE0_READ7    = 5'd9 ; 
parameter MODE0_XOR      = 5'd10 ; 
parameter MODE0_WRITE0   = 5'd11 ; 
parameter MODE0_WRITE1   = 5'd12 ; 
parameter MODE0_WRITE2   = 5'd13 ; 
parameter MODE0_WRITE3   = 5'd14 ; 
parameter MODE0_DONE	= 5'd15 ;		   	   

parameter MODE1_IDLE	= 5'd0 ;
parameter MODE1_START	= 5'd1 ;
parameter MODE1_READ0 	= 5'd2 ; 
parameter MODE1_READ1    = 5'd3 ; 
parameter MODE1_READ2    = 5'd4 ; 
parameter MODE1_READ3    = 5'd5 ; 
parameter MODE1_READ4    = 5'd6 ; 
parameter MODE1_READ5    = 5'd7 ; 
parameter MODE1_READ6    = 5'd8 ; 
parameter MODE1_READ7    = 5'd9 ; 
parameter MODE1_XOR      = 5'd10 ; 
parameter MODE1_WRITE0   = 5'd11 ; 
parameter MODE1_WRITE1   = 5'd12 ; 
parameter MODE1_WRITE2   = 5'd13 ; 
parameter MODE1_WRITE3   = 5'd14 ; 
parameter MODE1_DONE	= 5'd15 ;		   	   

// Signals
// 1 FSM
// 1.1 Main FSM
reg   [2:0] AesState	; 	
reg   [2:0] NextAesState;
//wire        AesDone	;
wire        StartKeyExp ;
wire        StartDatEnc ;
wire        StartDatDec ;
// 1.2 KeyExp FSM
reg   [2:0] KeyState	; 	
reg   [2:0] NextKeyState;
wire        KeyDone	;
// 1.3 Enc FSM
reg   [2:0] EnState	; 	
reg   [2:0] NextEnState;
wire        EncDone	;
wire        StateEnd    ;
//wire        FirstRound  ;
// 1.4 Dec FSM
reg   [2:0] DeState	; 	
reg   [2:0] NextDeState;
wire        DecDone	;

//2 Register Update
reg   [7:0] SReg00 ;
reg   [7:0] SReg01 ;
reg   [7:0] SReg02 ;
reg   [7:0] SReg03 ;
reg   [7:0] SReg10 ;
reg   [7:0] SReg11 ;
reg   [7:0] SReg12 ;
reg   [7:0] SReg13 ;
reg   [7:0] SReg20 ;
reg   [7:0] SReg21 ;
reg   [7:0] SReg22 ;
reg   [7:0] SReg23 ;
reg   [7:0] SReg30 ;
reg   [7:0] SReg31 ;
reg   [7:0] SReg32 ;
reg   [7:0] SReg33 ;
reg   [7:0] KReg00 ;
reg   [7:0] KReg01 ;
reg   [7:0] KReg02 ;
reg   [7:0] KReg03 ;
wire  [7:0] NextSReg00;
wire  [7:0] NextSReg01;
wire  [7:0] NextSReg02;
wire  [7:0] NextSReg03;
wire  [7:0] NextSReg10;
wire  [7:0] NextSReg11;
wire  [7:0] NextSReg12;
wire  [7:0] NextSReg13;
wire  [7:0] NextSReg20;
wire  [7:0] NextSReg21;
wire  [7:0] NextSReg22;
wire  [7:0] NextSReg23;
wire  [7:0] NextSReg30;
wire  [7:0] NextSReg31;
wire  [7:0] NextSReg32;
wire  [7:0] NextSReg33;
wire  [7:0] NextKReg00 ;
wire  [7:0] NextKReg01 ;
wire  [7:0] NextKReg02 ;
wire  [7:0] NextKReg03 ;

//3 signals for DataPath
//wire KeyEn 	;
//wire LastRound  ;
//4 Counter
reg   [7:0] AesCnt	;
wire  [7:0] NextAesCnt	;

reg   [2:0] WCnt	;
wire  [2:0] NextWCnt	;

reg   [3:0] RCnt	;
wire  [3:0] NextRCnt	;

reg   [1:0] SCnt	;
wire  [1:0] NextSCnt	;

wire  [7:0] EncAdr      ;
wire  [7:0] DecAdr      ;

wire  [2:0] MaxW        ;

wire  [7:0] InitialKeyStart;
wire  [7:0] InitialDeStart;
wire  [7:0] InitialKeyEnd;

//
reg   [7:0] Rcon;
wire        LastKey;
wire  [31:0] KeyExpDatIn;
wire         Nk8Mod4;
wire  [31:0] KeyExpDatOut;
wire  [31:0] EncDatOut;
wire  [31:0] DecDatOut;

//zxjian,20230207
////zxjian,20230207
wire StartMode0 ; 
wire StartMode1 ;
wire Mode0Done;
wire Mode1Done;
//MODE0 FSM
reg  [4 :0] Mode0State     ;
reg  [4 :0] NextMode0State ;
    
reg  [31:0] IVector0;
reg  [31:0] IVector1;
reg  [31:0] IVector2;
reg  [31:0] IVector3;
wire [31:0] NextIVector0 ; 
wire [31:0] NextIVector1 ; 
wire [31:0] NextIVector2 ; 
wire [31:0] NextIVector3 ; 

//assign AesRamRd
wire [7 :0] Mode0Adr;
wire [31:0] Mode0Dat; 
//MODE1 FSM
reg  [4 :0] Mode1State    ;
reg  [4 :0] NextMode1State;
wire [7 :0] Mode1Adr;
wire [31:0] Mode1Dat; 

//end,zxjian,20230207




wire KeyExp;
wire DatEnc;
wire DatDec;

assign KeyExp = AesIR==2'b00;
assign DatEnc = AesIR==2'b10;
assign DatDec = AesIR==2'b11;

assign KeyEn = KeyExp;
assign EncEn = DatEnc;
assign DecEn = DatDec;

// 1 FSM
// 1.1 Main FSM
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    AesState <= AES_IDLE;
else
    AesState <= NextAesState;

always @(*)
case(AesState)
    AES_IDLE:
	if(StartAes)
	    NextAesState = AES_START;
	else
	    NextAesState = AesState;
    AES_START:
	if(KeyExp)
	    NextAesState = AES_KEYEXP;
	else if(DatEnc | DatDec)
	    NextAesState = AES_MODE0;
        else 
            NextAesState = AES_IDLE;
    AES_KEYEXP:
        if(KeyDone)
            NextAesState = AES_DONE;
        else 
            NextAesState = AesState;
    AES_MODE0: //added for Mode operation beforce enc | dec
        if(Mode0Done)
            NextAesState = AES_ENC;
        else 
            NextAesState = AesState;
    AES_ENC:
        if(EncDone)
            NextAesState = AES_MODE1;
        else 
            NextAesState = AesState;    			
    AES_MODE1: //added for Mode operation after enc | dec
        if(Mode1Done)
            NextAesState = AES_DONE;
        else 
            NextAesState = AesState;
    AES_DONE:
            NextAesState = AES_IDLE;
    default:
            NextAesState = AES_IDLE;
endcase

assign StartKeyExp = AesState == AES_START & KeyExp;
assign StartDatEnc = AesState == AES_MODE0 & Mode0Done & (DatEnc | DatDec);
assign AesDone = AesState == AES_DONE;

//zxjian,20230207
assign StartMode0 = AesState == AES_START & (DatEnc | DatDec);
assign StartMode1 = AesState == AES_ENC & EncDone;

//MODE0 FSM
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    Mode0State <= MODE0_IDLE;
else
    Mode0State <= NextMode0State;

always @(*)
case(Mode0State)
    MODE0_IDLE:
        if(StartMode0)
	    NextMode0State = MODE0_START;
        else
	    NextMode0State = Mode0State;
    MODE0_START:
        if(AesMode ==3'b010 & DatEnc)           //only valid for cbc enc
            NextMode0State = MODE0_READ0;
        else
	    NextMode0State = MODE0_DONE;
    
    MODE0_READ0:                             	//Read IV
	    NextMode0State = MODE0_READ1;
    MODE0_READ1:                             	//Read IV
	    NextMode0State = MODE0_READ2;
    MODE0_READ2:                             	//Read IV
	    NextMode0State = MODE0_READ3;
    MODE0_READ3:                             	//Read IV
	    NextMode0State = MODE0_READ4;
    MODE0_READ4:                             	//Read Plain
	    NextMode0State = MODE0_READ5;
    MODE0_READ5:                             	//Read Plain
	    NextMode0State = MODE0_READ6;
    MODE0_READ6:                             	//Read Plain
	    NextMode0State = MODE0_READ7;
    MODE0_READ7:                             	//Read Plain
	    NextMode0State = MODE0_XOR;
    MODE0_XOR:   			   	//Read Plaintext
            NextMode0State = MODE0_WRITE0;
    MODE0_WRITE0:                             	//Write Plain
	    NextMode0State = MODE0_WRITE1;
    MODE0_WRITE1:                             	//Write Plain
	    NextMode0State = MODE0_WRITE2;
    MODE0_WRITE2:                             	//Write Plain
	    NextMode0State = MODE0_WRITE3;
    MODE0_WRITE3:                             	//Write Plain
	    NextMode0State = MODE0_DONE;
    MODE0_DONE:			   	   
            NextMode0State = MODE0_IDLE;
    default:
            NextMode0State = MODE0_IDLE;
endcase

assign Mode0Done = Mode0State == MODE0_DONE;

always @(posedge Clk or negedge Resetn)
if(~Resetn)
    begin
    IVector0 <= 32'h0;
    IVector1 <= 32'h0;
    IVector2 <= 32'h0;
    IVector3 <= 32'h0;
    end
else
    begin
    IVector0 <= NextIVector0;
    IVector1 <= NextIVector1;
    IVector2 <= NextIVector2;
    IVector3 <= NextIVector3;
    end

assign NextIVector0 = Mode0State == MODE0_READ1 ? RamAesDat : 
                      Mode0State == MODE0_READ5 ? RamAesDat ^ IVector0: 
                      Mode1State == MODE1_READ1 ? RamAesDat : 
                      Mode1State == MODE1_READ5 ? RamAesDat ^ IVector0: 
                                                  IVector0  ;
assign NextIVector1 = Mode0State == MODE0_READ2 ? RamAesDat : 
                      Mode0State == MODE0_READ6 ? RamAesDat ^ IVector1: 
                      Mode1State == MODE1_READ2 ? RamAesDat : 
                      Mode1State == MODE1_READ6 ? RamAesDat ^ IVector1: 
                                                  IVector1  ;
assign NextIVector2 = Mode0State == MODE0_READ3 ? RamAesDat : 
                      Mode0State == MODE0_READ7 ? RamAesDat ^ IVector2: 
                      Mode1State == MODE1_READ3 ? RamAesDat : 
                      Mode1State == MODE1_READ7 ? RamAesDat ^ IVector2: 
                                                  IVector2  ;
assign NextIVector3 = Mode0State == MODE0_READ4 ? RamAesDat : 
                      Mode0State == MODE0_XOR   ? RamAesDat ^ IVector3: 
                      Mode1State == MODE1_READ4 ? RamAesDat : 
                      Mode1State == MODE1_XOR   ? RamAesDat ^ IVector3: 
                                                  IVector3  ;

//assign AesRamRd
assign Mode0Adr = Mode0State == MODE0_READ0  ? 8'd0 :
                  Mode0State == MODE0_READ1  ? 8'd1 :
                  Mode0State == MODE0_READ2  ? 8'd2 :
                  Mode0State == MODE0_READ3  ? 8'd3 :
                  Mode0State == MODE0_READ4  ? 8'd4 :
                  Mode0State == MODE0_READ5  ? 8'd5 :
                  Mode0State == MODE0_READ6  ? 8'd6 :
                  Mode0State == MODE0_READ7  ? 8'd7 :
                  Mode0State == MODE0_WRITE0 ? 8'd0 :
                  Mode0State == MODE0_WRITE1 ? 8'd1 :
                  Mode0State == MODE0_WRITE2 ? 8'd2 :
                  Mode0State == MODE0_WRITE3 ? 8'd3 :
                                               8'd0 ;

assign Mode0Dat = 
                  Mode0State == MODE0_WRITE0 ? IVector0 :
                  Mode0State == MODE0_WRITE1 ? IVector1 :
                  Mode0State == MODE0_WRITE2 ? IVector2 :
                  Mode0State == MODE0_WRITE3 ? IVector3 :
                                               32'h0    ;
//MODE1 FSM
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    Mode1State <= MODE1_IDLE;
else
    Mode1State <= NextMode1State;

always @(*)
case(Mode1State)
    MODE1_IDLE:
        if(StartMode1)
	    NextMode1State = MODE1_START;
        else
	    NextMode1State = Mode1State;
    MODE1_START:
        if(AesMode ==3'b010 & DatDec | AesMode == 3'b100 | AesMode == 3'b101 | AesMode == 3'b011)  //valid for cbc dec, ctr, cfb & ofb
            NextMode1State = MODE1_READ0;
        else
	    NextMode1State = MODE1_DONE;
    
    MODE1_READ0:                             	//Read IV
	    NextMode1State = MODE1_READ1;
    MODE1_READ1:                             	//Read IV
	    NextMode1State = MODE1_READ2;
    MODE1_READ2:                             	//Read IV
	    NextMode1State = MODE1_READ3;
    MODE1_READ3:                             	//Read IV
	    NextMode1State = MODE1_READ4;
    MODE1_READ4:                             	//Read Plain
	    NextMode1State = MODE1_READ5;
    MODE1_READ5:                             	//Read Plain
	    NextMode1State = MODE1_READ6;
    MODE1_READ6:                             	//Read Plain
	    NextMode1State = MODE1_READ7;
    MODE1_READ7:                             	//Read Plain
	    NextMode1State = MODE1_XOR;
    MODE1_XOR:   			   	//Read Plaintext
            NextMode1State = MODE1_WRITE0;
    MODE1_WRITE0:                             	//Write Plain
	    NextMode1State = MODE1_WRITE1;
    MODE1_WRITE1:                             	//Write Plain
	    NextMode1State = MODE1_WRITE2;
    MODE1_WRITE2:                             	//Write Plain
	    NextMode1State = MODE1_WRITE3;
    MODE1_WRITE3:                             	//Write Plain
	    NextMode1State = MODE1_DONE;
    MODE1_DONE:			   	   
            NextMode1State = MODE1_IDLE;
    default:
            NextMode1State = MODE1_IDLE;
endcase

assign Mode1Done = Mode1State == MODE1_DONE;
//always @(posedge Clk or negedge Resetn)
//if(~Resetn)
//    begin
//    IVector0 <= 32'h0;
//    IVector1 <= 32'h0;
//    IVector2 <= 32'h0;
//    IVector3 <= 32'h0;
//    end
//else
//    begin
//    IVector0 <= NextIVector0;
//    IVector1 <= NextIVector1;
//    IVector2 <= NextIVector2;
//    IVector3 <= NextIVector3;
//    end
//
//assign NextIVector0 = Mode1State == MODE1_READ1 ? RamAesDat : 
//                      Mode1State == MODE1_READ5 ? RamAesDat ^ IVector0: 
//                                                  IVector0  ;
//assign NextIVector1 = Mode1State == MODE1_READ2 ? RamAesDat : 
//                      Mode1State == MODE1_READ6 ? RamAesDat ^ IVector1: 
//                                                  IVector1  ;
//assign NextIVector2 = Mode1State == MODE1_READ3 ? RamAesDat : 
//                      Mode1State == MODE1_READ7 ? RamAesDat ^ IVector2: 
//                                                  IVector2  ;
//assign NextIVector3 = Mode1State == MODE1_READ4 ? RamAesDat : 
//                      Mode1State == MODE1_XOR   ? RamAesDat ^ IVector3: 
//                                                  IVector3  ;

//20230401
wire OfbMode;
assign OfbMode = AesMode == 3'b100;

//assign AesRamRd
assign Mode1Adr = Mode1State == MODE1_READ0  ? 8'd68:
                  Mode1State == MODE1_READ1  ? 8'd69:
                  Mode1State == MODE1_READ2  ? 8'd70:
                  Mode1State == MODE1_READ3  ? 8'd71:
                  Mode1State == MODE1_READ4  ? 8'd4 :
                  Mode1State == MODE1_READ5  ? 8'd5 :
                  Mode1State == MODE1_READ6  ? 8'd6 :
                  Mode1State == MODE1_READ7  ? 8'd7 :
                  Mode1State == MODE1_WRITE0 & OfbMode  ? 8'd72 : //20230401
                  Mode1State == MODE1_WRITE1 & OfbMode  ? 8'd73 : 
                  Mode1State == MODE1_WRITE2 & OfbMode  ? 8'd74 : 
                  Mode1State == MODE1_WRITE3 & OfbMode  ? 8'd75 : 
                  Mode1State == MODE1_WRITE0 & ~OfbMode ? 8'd68 : //20230401
                  Mode1State == MODE1_WRITE1 & ~OfbMode ? 8'd69 : 
                  Mode1State == MODE1_WRITE2 & ~OfbMode ? 8'd70 : 
                  Mode1State == MODE1_WRITE3 & ~OfbMode ? 8'd71 : 
                                               8'd0 ;

assign Mode1Dat = 
                  Mode1State == MODE1_WRITE0 ? IVector0 :
                  Mode1State == MODE1_WRITE1 ? IVector1 :
                  Mode1State == MODE1_WRITE2 ? IVector2 :
                  Mode1State == MODE1_WRITE3 ? IVector3 :
                                               32'h0    ;
//end zxjian,20230207

// 1.2 KeyExp FSM
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    KeyState <= KEY_IDLE;
else
    KeyState <= NextKeyState;

always @(*)
case(KeyState)
    KEY_IDLE:
	    if(StartKeyExp)
	    NextKeyState = KEY_START;
	    else
	    NextKeyState = KeyState;
    KEY_START:                             	//Read Last Initial Key Word
	    NextKeyState = KEY_READ;
    KEY_READ:                             	//Read Last Initial Key Word
	    NextKeyState = KEY_LOAD;
    KEY_LOAD:				   	//Read previous Key
            NextKeyState = KEY_EXP;
    KEY_EXP:                             	//KEYEXP 
            NextKeyState = KEY_STORE;           
    KEY_STORE:                                  //WR RoundKey Back
            if(LastKey)                           	
            NextKeyState = KEY_DONE;
            else
            NextKeyState = KEY_LOAD;   
    KEY_DONE:
            NextKeyState = KEY_IDLE;
    default:
            NextKeyState = KEY_IDLE;
endcase

assign KeyDone = KeyState == KEY_DONE;
assign LastKey = AesLen == 2'b00 ?  AesCnt == 39 :  //zhxj,20191012,to be revised!!!
                 AesLen == 2'b01 ?  AesCnt == 45 :  //zhxj,20191012,to be reviesd!!!
                                    AesCnt == 51 ;  //zhxj,20191012,to be reviesd!!!
 
// 1.2 Enc FSM
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    EnState <= EN_IDLE;
else
    EnState <= NextEnState;

always @(*)
case(EnState)
    EN_IDLE:
	if(StartDatEnc)
	    NextEnState = EN_START;
	else
	    NextEnState = EnState;
    EN_START:                                  			//Send RamRd
	    NextEnState = EN_LOAD;
    EN_LOAD:						  	//DatWord
        if(StateEnd)
	    NextEnState = EN_ROUND0;
        else
            NextEnState = EnState;
    EN_ROUND0:						  	//RoundKey
        if(StateEnd)
	    NextEnState = EN_ROUND1;
        else
            NextEnState = EnState;
    EN_ROUND1:                             			//ENC ROUND Word0
	if(LastRound & StateEnd)
	    NextEnState = EN_STORE;
	else 
            NextEnState = EnState;    			
    EN_STORE:						  	//DatWord
        if(StateEnd)
	    NextEnState = EN_DONE;
        else
            NextEnState = EnState;
    EN_DONE:
            NextEnState = EN_IDLE;
    default:
            NextEnState = EN_IDLE;
endcase

assign EncDone = EnState == EN_DONE;
assign StateEnd= SCnt == 2'b00; 
assign FirstRound = EnState == EN_ROUND0;

//2 Register Update
//
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    begin
	SReg00 <= 8'h00;
	SReg01 <= 8'h00;
	SReg02 <= 8'h00;
	SReg03 <= 8'h00;
	SReg10 <= 8'h00;
	SReg11 <= 8'h00;
	SReg12 <= 8'h00;
	SReg13 <= 8'h00;
	SReg20 <= 8'h00;
	SReg21 <= 8'h00;
	SReg22 <= 8'h00;
	SReg23 <= 8'h00;
	SReg30 <= 8'h00;
	SReg31 <= 8'h00;
	SReg32 <= 8'h00;
	SReg33 <= 8'h00;
        KReg00 <= 8'h00;
        KReg01 <= 8'h00;
        KReg02 <= 8'h00;
        KReg03 <= 8'h00;
	end
else
    begin
	SReg00 <= NextSReg00;
	SReg01 <= NextSReg01;
	SReg02 <= NextSReg02;
	SReg03 <= NextSReg03;
	SReg10 <= NextSReg10;
	SReg11 <= NextSReg11;
	SReg12 <= NextSReg12;
	SReg13 <= NextSReg13;
	SReg20 <= NextSReg20;
	SReg21 <= NextSReg21;
	SReg22 <= NextSReg22;
	SReg23 <= NextSReg23;
	SReg30 <= NextSReg30;
	SReg31 <= NextSReg31;
	SReg32 <= NextSReg32;
	SReg33 <= NextSReg33;
        KReg00 <= NextKReg00;
        KReg01 <= NextKReg01;
        KReg02 <= NextKReg02;
        KReg03 <= NextKReg03;
	end

//Col0
assign NextSReg00  = EnState == EN_LOAD & SCnt ==2'b01  ? RamAesDat[7:0]         : //Load0,1,2,3
                     EnState == EN_ROUND0 & SCnt==2'b01 ? DataPathCtrlDat[7:0]   : //Round0
                     EnState == EN_ROUND0 & SCnt==2'b00 ? DataPathCtrlDat[7:0]   : //Round0
                     EnState == EN_ROUND1 & SCnt==2'b01 ? DataPathCtrlDat[7:0]   : //Round3,LineShift
        ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? DataPathCtrlDat[7:0]   : //Round3,LineShift
					                  SReg00                 ;
assign NextSReg01  = EnState == EN_LOAD & SCnt ==2'b01  ? RamAesDat[15:8]        :
                     EnState == EN_ROUND0 & SCnt==2'b01 ? DataPathCtrlDat[15:8]  : //Round0 
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg21                 : //Round0 
                     EnState == EN_ROUND1 & SCnt==2'b01 ? DataPathCtrlDat[15:8]  : //Round3,LineShift
	 ~LastRound & 	     EnState == EN_ROUND1 & SCnt==2'b00 ? SReg21                 : //Round3,LineShift
                                                          SReg01                 ;
assign NextSReg02  = EnState == EN_LOAD & SCnt ==2'b01  ? RamAesDat[23:16]       : 
                     EnState == EN_ROUND0 & SCnt==2'b01 ? DataPathCtrlDat[23:16] : //Round0
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg12                 : //Round0
                     EnState == EN_ROUND1 & SCnt==2'b01 ? DataPathCtrlDat[23:16] : //Round3,LineShift
        ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? SReg12                 : //Round3,LineShift
                                                          SReg02                 ;
assign NextSReg03  = EnState == EN_LOAD & SCnt ==2'b01  ? RamAesDat[31:24]       :
                     EnState == EN_ROUND0 & SCnt==2'b01 ? DataPathCtrlDat[31:24] : //Round0
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg03                 : //Round0
		     EnState == EN_ROUND1 & SCnt==2'b01 ? DataPathCtrlDat[31:24] : //Round3 ,LineShift
        ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? SReg03                 : //Round3 ,LineShift
                                                          SReg03                 ;

assign NextSReg10  = EnState == EN_LOAD & SCnt ==2'b10  ? RamAesDat[7:0]         : //Load0,1,2,3
                     EnState == EN_ROUND0 & SCnt==2'b10 ? DataPathCtrlDat[7:0]   : //Round0
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg00                 : //Round0
                     EnState == EN_ROUND1 & SCnt==2'b10 ? DataPathCtrlDat[7:0]   : //Round3,LineShift
       ~LastRound &  EnState == EN_ROUND1 & SCnt==2'b00 ? SReg00                 : //Round3,LineShift
					                  SReg10                 ;
assign NextSReg11  = EnState == EN_LOAD & SCnt ==2'b10  ? RamAesDat[15:8] 	      :
                     EnState == EN_ROUND0 & SCnt==2'b10 ? DataPathCtrlDat[15:8]  : //Round0 
                     EnState == EN_ROUND0 & SCnt==2'b00 ? DataPathCtrlDat[15:8]  : //Round0 
		     EnState == EN_ROUND1 & SCnt==2'b10 ? DataPathCtrlDat[15:8]  : //Round3,LineShift
        ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? DataPathCtrlDat[15:8]  : //Round3,LineShift
                                                         SReg11                 ;
assign NextSReg12  = EnState == EN_LOAD & SCnt ==2'b10  ? RamAesDat[23:16]       : 
                     EnState == EN_ROUND0 & SCnt==2'b10 ? DataPathCtrlDat[23:16] : //Round0
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg22                 : //Round0
                     EnState == EN_ROUND1 & SCnt==2'b10 ? DataPathCtrlDat[23:16] : //Round3,LineShift
         ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? SReg22                 : //Round3,LineShift
                                                          SReg12                 ;
assign NextSReg13  = EnState == EN_LOAD & SCnt ==2'b10  ? RamAesDat[31:24]       :
                     EnState == EN_ROUND0 & SCnt==2'b10 ? DataPathCtrlDat[31:24] : //Round0
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg13                 : //Round0
		     EnState == EN_ROUND1 & SCnt==2'b10 ? DataPathCtrlDat[31:24] : //Round3 ,LineShift
	 ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? SReg13                 : //Round3 ,LineShift
                                                          SReg13                 ;

assign NextSReg20  = EnState == EN_LOAD & SCnt ==2'b11  ? RamAesDat[7:0]         : //Load0,1,2,3
                     EnState == EN_ROUND0 & SCnt==2'b11 ? DataPathCtrlDat[7:0]   : //Round0
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg10                 : //Round0
                     EnState == EN_ROUND1 & SCnt==2'b11 ? DataPathCtrlDat[7:0]   : //Round3,LineShift
       ~LastRound &  EnState == EN_ROUND1 & SCnt==2'b00 ? SReg10                 : //Round3,LineShift
					                  SReg20                 ;
assign NextSReg21  = EnState == EN_LOAD & SCnt ==2'b11  ? RamAesDat[15:8] 	      :
                     EnState == EN_ROUND0 & SCnt==2'b11 ? DataPathCtrlDat[15:8]  : //Round0 
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg01                 : //Round0 
		     EnState == EN_ROUND1 & SCnt==2'b11 ? DataPathCtrlDat[15:8]  : //Round3,LineShift
        ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? SReg01                 : //Round3,LineShift
                                                          SReg21                 ;
assign NextSReg22  = EnState == EN_LOAD & SCnt ==2'b11  ? RamAesDat[23:16]       : 
                     EnState == EN_ROUND0 & SCnt==2'b11 ? DataPathCtrlDat[23:16] : //Round0
                     EnState == EN_ROUND0 & SCnt==2'b00 ? DataPathCtrlDat[23:16] : //Round0
                     EnState == EN_ROUND1 & SCnt==2'b11 ? DataPathCtrlDat[23:16] : //Round3,LineShift
        ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? DataPathCtrlDat[23:16] : //Round3,LineShift
                                                          SReg22                 ;
assign NextSReg23  = EnState == EN_LOAD & SCnt ==2'b11  ? RamAesDat[31:24]       :
                     EnState == EN_ROUND0 & SCnt==2'b11 ? DataPathCtrlDat[31:24] : //Round0
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg23                 : //Round0
		     EnState == EN_ROUND1 & SCnt==2'b11 ? DataPathCtrlDat[31:24] : //Round3 ,LineShift
        ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? SReg23                 : //Round3 ,LineShift
                                                          SReg23                 ;

assign NextSReg30  = EnState == EN_LOAD & SCnt ==2'b00  ? RamAesDat[7:0]         : //Load0,1,2,3
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg20                 : //Round0
        ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? SReg20                 : //Round3,LineShift
                     EnState == EN_ROUND1 & SCnt==2'b00 ? DataPathCtrlDat[7:0]   : //Round3,LineShift
					                                      SReg30                 ;
assign NextSReg31  = EnState == EN_LOAD & SCnt ==2'b00  ? RamAesDat[15:8]        :
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg11                 : //Round0 
	~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? SReg11                 : //Round3,LineShift
                     EnState == EN_ROUND1 & SCnt==2'b00 ? DataPathCtrlDat[15:8]  : //Round3,LineShift
                                                          SReg31                 ;
assign NextSReg32  = EnState == EN_LOAD & SCnt ==2'b00  ? RamAesDat[23:16]       : 
                     EnState == EN_ROUND0 & SCnt==2'b00 ? SReg02                 : //Round0
        ~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? SReg02                 : //Round3,LineShift
                     EnState == EN_ROUND1 & SCnt==2'b00 ? DataPathCtrlDat[23:16] : //Round3,LineShift
                                                          SReg32                 ;
assign NextSReg33  = EnState == EN_LOAD & SCnt ==2'b00  ? RamAesDat[31:24]       :
                     EnState == EN_ROUND0 & SCnt==2'b00 ? DataPathCtrlDat[31:24] : //Round0
	~LastRound & EnState == EN_ROUND1 & SCnt==2'b00 ? DataPathCtrlDat[31:24] : //Round3 ,LineShift
                     EnState == EN_ROUND1 & SCnt==2'b00 ? DataPathCtrlDat[31:24] : //Round3,LineShift
                                                          SReg33                 ;

assign NextKReg00 =
                   StartKeyExp          ?      8'h00     : 
                   KeyState == KEY_READ ? RamAesDat[7:0] :
                   KeyState == KEY_EXP  ? KeyExpDatIn[7:0] :
                                               KReg00    ;
assign NextKReg01 =
                   StartKeyExp          ?      8'h00     : 
                   KeyState == KEY_READ ? RamAesDat[15:8] :
                   KeyState == KEY_EXP  ? KeyExpDatIn[15:8] :
                                               KReg01    ;
assign NextKReg02 =
                   StartKeyExp          ?      8'h00     : 
                   KeyState == KEY_READ ? RamAesDat[23:16] :
                   KeyState == KEY_EXP  ? KeyExpDatIn[23:16] :
                                               KReg02    ;
assign NextKReg03 =
                   StartKeyExp          ?      8'h00     : 
                   KeyState == KEY_READ ? RamAesDat[31:24] :
                   KeyState == KEY_EXP  ? KeyExpDatIn[31:24] :
                                               KReg03    ;

assign KeyExpDatIn = WCnt == 3'b000 ? {DataPathCtrlDat[31:24] ^ Rcon , DataPathCtrlDat[23:0]} ^ RamAesDat  :
                     Nk8Mod4        ? DataPathCtrlDat ^ RamAesDat                                          :
                                      {KReg03,KReg02,KReg01,KReg00} ^ RamAesDat                            ;

assign KeyExpDatOut[7:0]   =  Nk8Mod4 ? KReg00: KReg03 ;
assign KeyExpDatOut[15:8]  =  Nk8Mod4 ? KReg01: KReg00 ;
assign KeyExpDatOut[23:16] =  Nk8Mod4 ? KReg02: KReg01 ;
assign KeyExpDatOut[31:24] =  Nk8Mod4 ? KReg03: KReg02 ;

assign Nk8Mod4 = (AesLen == 2'b10) & (WCnt == 4); 

//3 signals for DataPath
//zhxj,20191013,to be revised!!! according AesLen
assign LastRound = AesLen == 2'b00 ? AesCnt == 8'd9 :
                   AesLen == 2'b01 ? AesCnt == 8'd11:
                                     AesCnt == 8'd13;

//zhxj,20191008,tobe revised!!!
//assign CtrlDataPathDat = {SReg00, SReg01, SReg02, SReg03};
assign CtrlDataPathDat = KeyEn ? KeyExpDatOut : //For KeyExp
                         EncEn ? EncDatOut    :
                         DecEn ? DecDatOut    :
                                 32'h0        ;
assign EncDatOut =
                   SCnt == 2'b01 ?  {SReg03, SReg02, SReg01, SReg00} : 
                   SCnt == 2'b10 ?  {SReg13, SReg12, SReg11, SReg10} : 
                   SCnt == 2'b11 ?  {SReg23, SReg22, SReg21, SReg20} : 
                                    {SReg33, SReg32, SReg31, SReg30} ; 

assign DecDatOut =
                   SCnt == 2'b01 ?  {SReg03, SReg02, SReg01, SReg00} : 
                   SCnt == 2'b10 ?  {SReg13, SReg12, SReg11, SReg10} : 
                   SCnt == 2'b11 ?  {SReg23, SReg22, SReg21, SReg20} : 
                                    {SReg33, SReg32, SReg31, SReg30} ; 
//4 Counter
// 4.1 AesCnt
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    AesCnt <= 8'h00;
else 
    AesCnt <= NextAesCnt;

assign NextAesCnt =  StartAes                      ? 8'h00      :
                     EnState==EN_ROUND1 & StateEnd ? AesCnt + 1 :
		     //KeyEn & KeyState==KEY_STORE ? AesCnt + 1 :
		     KeyState==KEY_STORE           ? AesCnt + 1 :
		                                     AesCnt     ;
// 4.2 WordCnt
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    WCnt <= 3'h0;
else 
    WCnt <= NextWCnt;

assign NextWCnt =  StartAes   ? 3'b000  :
		   KeyEn & KeyState==KEY_STORE & WCnt==MaxW    ? 3'b000 :
		   KeyEn & KeyState==KEY_STORE    ? WCnt + 1 :
		                WCnt     ;

assign MaxW = AesLen == 2'b00 ? 3 :
              AesLen == 2'b01 ? 5 :
                                7 ;
// 4.3 RoundCnt
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    RCnt <= 4'h0;
else 
    RCnt <= NextRCnt;

assign NextRCnt =  StartAes                    ? 4'h0      :
		   KeyEn & KeyState==KEY_STORE & WCnt==MaxW ? RCnt + 1 :
		                                   RCnt     ;
// 4.4 StateCnt
always @(posedge Clk or negedge Resetn)
if(~Resetn)
    SCnt <= 2'h0;
else 
    SCnt <= NextSCnt;

assign NextSCnt =  EnState == EN_IDLE  ? 2'b00  : SCnt + 1;
		   //EnState == EN_START | EnState==EN_LOAD | EnState==EN_ROUND0   ? SCnt+1 :
                                                //             SCnt   ;
// 4.2 WordCnt
// 5 Ram signals

//assign AesRamRd = AesState == AES_START | AesState == AES_ENC;
// 5 Ram signals

//assign AesRamRd = AesState == AES_START | AesState == AES_ENC;
//assign AesRamRd = KeyState == KEY_START | KeyState == KEY_LOAD |
//                  EnState == EN_START | EnState == EN_LOAD | EnState == EN_ROUND0 | EnState == EN_ROUND1;
//zxjian,20230207
assign AesRamRd = KeyState == KEY_START | KeyState == KEY_LOAD |
                  Mode0State == MODE0_READ0 | Mode0State == MODE0_READ1 |Mode0State == MODE0_READ2 | Mode0State == MODE0_READ3 |
                  Mode0State == MODE0_READ4 | Mode0State == MODE0_READ5 |Mode0State == MODE0_READ6 | Mode0State == MODE0_READ7 |
                  Mode1State == MODE1_READ0 | Mode1State == MODE1_READ1 |Mode1State == MODE1_READ2 | Mode1State == MODE1_READ3 |
                  Mode1State == MODE1_READ4 | Mode1State == MODE1_READ5 |Mode1State == MODE1_READ6 | Mode1State == MODE1_READ7 |
                  EnState == EN_START | EnState == EN_LOAD | EnState == EN_ROUND0 | EnState == EN_ROUND1;


//Dec Adr should be revised!!! 
assign EncAdr    =
                   EnState == EN_START   ? 0                                     :
                   EnState == EN_LOAD & SCnt != 2'b00   ? SCnt                   :
                   EnState == EN_LOAD & SCnt == 2'b00   ? 8                      :
                   EnState == EN_ROUND0 & SCnt !=2'b00  ? SCnt+8                 :
                   EnState == EN_ROUND0 & SCnt ==2'b00  ? 12                     :
                   EnState == EN_ROUND1 & SCnt !=2'b00  ? SCnt+12+(AesCnt<<2)    :
                   EnState == EN_ROUND1 & SCnt ==2'b00  ? SCnt+16+(AesCnt<<2)    :
                   EnState == EN_STORE  & SCnt !=2'b00  ? SCnt+8'd67             :
                   EnState == EN_STORE  & SCnt ==2'b00  ? 8'd71                  :
                                                          8'h00                  ;
assign DecAdr    =
                   EnState == EN_START   ? 3                                     :
                   EnState == EN_LOAD & SCnt != 2'b00   ? 3-SCnt                 :
                   //EnState == EN_LOAD & SCnt == 2'b00   ? 51                     :
                   //EnState == EN_ROUND0 & SCnt !=2'b00  ? 51-SCnt                :
                   //EnState == EN_ROUND0 & SCnt ==2'b00  ? 47                     :
                   //EnState == EN_ROUND1 & SCnt !=2'b00  ? 47-SCnt-(AesCnt<<2)    :
                   //EnState == EN_ROUND1 & SCnt ==2'b00  ? 43-SCnt-(AesCnt<<2)    :
                   EnState == EN_LOAD & SCnt == 2'b00   ? InitialDeStart                   :
                   EnState == EN_ROUND0 & SCnt !=2'b00  ? InitialDeStart-SCnt              :
                   EnState == EN_ROUND0 & SCnt ==2'b00  ? InitialDeStart-4                 :
                   EnState == EN_ROUND1 & SCnt !=2'b00  ? InitialDeStart-4-SCnt-(AesCnt<<2):
                   EnState == EN_ROUND1 & SCnt ==2'b00  ? InitialDeStart-8-(AesCnt<<2)     :
                   EnState == EN_STORE  & SCnt !=2'b00  ? SCnt+8'd67             :
                   EnState == EN_STORE  & SCnt ==2'b00  ? 8'd71                  :
                                                          8'h00                            ;
assign AesRamAdr = 
                   //EnState == EN_START   ? 0                                     :
                   //EnState == EN_LOAD & SCnt != 2'b00   ? SCnt                   :
                   //EnState == EN_LOAD & SCnt == 2'b00   ? 8                      :
                   //EnState == EN_ROUND0 & SCnt !=2'b00  ? SCnt+8                 :
                   //EnState == EN_ROUND0 & SCnt ==2'b00  ? 12                     :
                   //EnState == EN_ROUND1 & SCnt !=2'b00  ? SCnt+12+(AesCnt<<2)    :
                   //EnState == EN_ROUND1 & SCnt ==2'b00  ? SCnt+16+(AesCnt<<2)    :
                   AesState == AES_MODE0 ? Mode0Adr               : //zxjian,20230207
                   AesState == AES_MODE1 ? Mode1Adr               : //zxjian,20230207
                   EncEn                 ? EncAdr                 :
                   DecEn                 ? DecAdr                 :
                   KeyState == KEY_START ? InitialKeyEnd-1        : //11: 
                   KeyState == KEY_STORE ? AesCnt + InitialKeyEnd : //+12 :
                                           AesCnt+ InitialKeyStart; //+8;
assign AesRamWr = KeyState== KEY_STORE | EnState == EN_STORE |
                  Mode0State == MODE0_WRITE0 | Mode0State == MODE0_WRITE1 |Mode0State == MODE0_WRITE2 | Mode0State == MODE0_WRITE3 | //zxjian,20230207
                  Mode1State == MODE1_WRITE0 | Mode1State == MODE1_WRITE1 |Mode1State == MODE1_WRITE2 | Mode1State == MODE1_WRITE3 ; //zxjian,20230207
                
assign AesRamDat = 
                  AesState == AES_MODE0 ? Mode0Dat                    : //zxjian,20230207
                  AesState == AES_MODE1 ? Mode1Dat                    : //zxjian,20230207
        
                  EncEn&(SCnt==2'b00) ? {SReg33,SReg32,SReg31,SReg30} :
                  EncEn&(SCnt==2'b11) ? {SReg23,SReg22,SReg21,SReg20} :
                  EncEn&(SCnt==2'b10) ? {SReg13,SReg12,SReg11,SReg10} :
                  EncEn&(SCnt==2'b01) ? {SReg03,SReg02,SReg01,SReg00} :
                  //zhxj,20191013,littleEnd need revised!!!
                  //DecEn&(SCnt==2'b00) ? {SReg33,SReg32,SReg31,SReg30} :
                  //DecEn&(SCnt==2'b11) ? {SReg23,SReg22,SReg21,SReg20} :
                  //DecEn&(SCnt==2'b10) ? {SReg13,SReg12,SReg11,SReg10} :
                  //DecEn&(SCnt==2'b01) ? {SReg03,SReg02,SReg01,SReg00} :
                  DecEn&(SCnt==2'b01) ? {SReg33,SReg32,SReg31,SReg30} :
                  DecEn&(SCnt==2'b10) ? {SReg23,SReg22,SReg21,SReg20} :
                  DecEn&(SCnt==2'b11) ? {SReg13,SReg12,SReg11,SReg10} :
                  DecEn&(SCnt==2'b00) ? {SReg03,SReg02,SReg01,SReg00} :
                                        {KReg03,KReg02,KReg01,KReg00} ;

assign InitialKeyEnd = AesLen == 2'b00 ? 8'd12 :
                       AesLen == 2'b01 ? 8'd14 :
                                         8'd16 ;
assign InitialKeyStart = 8'd8;

assign InitialDeStart = AesLen == 2'b00 ? 8'd51 :
                        AesLen == 2'b01 ? 8'd59 :
                                          8'd67 ;


//6 RC constant
// the round constant 
always@( * )
begin
    case(RCnt)                       
        4'b0000: Rcon  =  8'b00000001 ; // 0  : 01
        4'b0001: Rcon  =  8'b00000010 ; // 1  : 02
        4'b0010: Rcon  =  8'b00000100 ; // 2  : 04
        4'b0011: Rcon  =  8'b00001000 ; // 3  : 08
        4'b0100: Rcon  =  8'b00010000 ; // 4  : 10
        4'b0101: Rcon  =  8'b00100000 ; // 5  : 20
        4'b0110: Rcon  =  8'b01000000 ; // 6  : 40
        4'b0111: Rcon  =  8'b10000000 ; // 7  : 80
        4'b1000: Rcon  =  8'b00011011 ; // 8  : 1B
        4'b1001: Rcon  =  8'b00110110 ; // 9  : 36
        default: Rcon  =  8'b0;
    endcase
end

endmodule
