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


//bus type
`define X8  //X8, X16

`define DDP   // SDP(single die package), DDP( dual die package)

parameter STOP_ON_ERROR     =          0; // Set to 1, stop simulation on errors

parameter MHz166 = 6.0;
parameter MHz133 = 7.5;
parameter MHz104 = 9.6;
parameter MHz85  = 11.76;
parameter MHz200 = 5.0;
parameter MHz250 = 4.0;

`define  clk_period MHz250

`ifdef T250
parameter  tCK= MHz250;
`else `ifdef T200
parameter  tCK= MHz200; //
`else `ifdef T166
parameter  tCK= MHz166; //
`else `ifdef T133
parameter  tCK= MHz133; //
`else `ifdef T104
parameter  tCK= MHz104; //
`else `ifdef T85
parameter  tCK= MHz85; //
`else
parameter  tCK= `clk_period; //

`endif  `endif `endif `endif `endif `endif


parameter  tCH_MIN= 0.45; //clocks
parameter  tCH_MAX= 0.55; //clocks
parameter  tCL_MIN= 0.45; //clocks
parameter  tCL_MAX= 0.55; //clocks




parameter LOW	= 0;
parameter HIGH	= 1;
parameter HIZ	= 'bz;
parameter XX	= 'bx;

parameter ENABLE = 1'b1;
parameter DISABLE = 1'b0;

parameter READY = 1'b1;
parameter NOTREADY = 1'b0;
	
`ifdef X8
parameter ADQ_BITS	= 8;
parameter RWDS_BITS	= 1;

`ifdef DDP
parameter ADDR_BITS	= 25; //A0~A24 
parameter MEM_BITS	= 25;
`else
parameter ADDR_BITS	= 24; //A0~A23
parameter MEM_BITS	= 24;
`endif
`else
parameter ADQ_BITS	= 16;
parameter RWDS_BITS	= 2;
parameter MEM_BITS	= 23;
parameter ADDR_BITS = 23; //A0~A22
`endif

parameter WORD_BITS	= 16;


parameter TEST_DELAY = 0.1;
parameter refresh_cycle = 4e3;	// optional value



parameter Fixed  = 1'b1;
parameter fixed_type  = 1'b1;
parameter Variable  = 1'b0;
parameter variable_type  = 1'b0;


parameter full_mem_bits= 22;

//hyperram
`ifdef T133
parameter tCSHI =7.5 ; //ns
parameter tRWR = 37.5 ; //ns
parameter tCSS = 3 ; //ns
parameter tDSV=  12 ; //ns
parameter tIS = 0.8; //ns
parameter tIH = 0.8 ; //ns
parameter tACC =37.5 ; //ns
parameter tCKD_max     = 5.5 ; //ns
parameter tCKDI_max    = 4.5 ; //ns
parameter tDV          = 2.375 ; //ns
parameter tCKDS_max    = 5.5 ; //ns
parameter tDSS_min =-0.6 ; //ns
parameter tDSS_max =0.6 ; //ns
parameter tDSH_min =-0.6 ; //ns
parameter tDSH_max =0.6 ; //ns
parameter tDSZ     = 6 ; //ns
parameter tOZ      = 6 ; //ns
`else `ifdef T166
parameter tCSHI =6 ; //ns
parameter tRWR =36 ; //ns
parameter tCSS=  3 ; //ns
parameter tDSV=12 ; //ns
parameter tIS= 0.6; //ns
parameter tIH= 0.6 ; //ns
parameter tACC =36 ; //ns
parameter tCKD_max     = 5.5 ; //ns
parameter tCKDI_max    = 4.6 ; //ns
parameter tDV          = 1.8 ; //ns
parameter tCKDS_max    = 5.0 ; //ns
parameter tDSS_min =-0.45 ; //ns
parameter tDSS_max =0.45 ; //ns
parameter tDSH_min =-0.45 ; //ns
parameter tDSH_max =0.45 ; //ns
parameter tDSZ=6 ; //ns
parameter tOZ=6 ; //ns
`else `ifdef T200
parameter tCSHI =6 ; //ns
parameter tRWR = 35 ; //ns
parameter tCSS = 4 ; //ns
parameter tDSV=5 ; //ns
parameter tIS= 0.5; //ns
parameter tIH= 0.5 ; //ns
parameter tACC =35 ; //ns
parameter tCKD_max     = 5.0 ; //ns
parameter tCKDI_max    = 4.2 ; //ns
parameter tDV          = 1.45 ; //ns
parameter tCKDS_max    = 5.0 ; //ns
parameter tDSS_min =-0.4 ; //ns
parameter tDSS_max =0.4 ; //ns
parameter tDSH_min =-0.4 ; //ns
parameter tDSH_max =0.4 ; //ns
parameter tDSZ   = 5 ; //ns
parameter tOZ    = 5 ; //ns
`else  //250MHz
parameter tCSHI =6 ; //ns
parameter tRWR = 35 ; //ns
parameter tCSS = 4 ; //ns
parameter tDSV=5 ; //ns
parameter tIS= 0.5; //ns
parameter tIH= 0.5 ; //ns
parameter tACC =28 ; //ns
parameter tCKD_max     = 5.0 ; //ns
parameter tCKDI_max    = 4.2 ; //ns
parameter tDV          = 1.0 ; //ns
parameter tCKDS_max    = 5.0 ; //ns
parameter tDSS_min =-0.4 ; //ns
parameter tDSS_max =0.4 ; //ns
parameter tDSH_min =-0.4 ; //ns
parameter tDSH_max =0.4 ; //ns
parameter tDSZ   = 5 ; //ns
parameter tOZ    = 5 ; //ns

`endif `endif `endif


parameter tCKD_min = 1 ; //ns


parameter tCKDS_min =1 ; //ns
parameter tCKDSR_min =1 ; //ns
parameter tCKDSR_max =5.5 ; //ns



parameter  tCSH_MIN = 0.0; //ns
parameter  tCSH_MAX = 0.0; //ns

`ifdef LA_85C
parameter tCSM=1000 ; //ns, larger than 85C
`else
parameter tCSM=4000 ; //ns, less than 85C
`endif

parameter tRP = 200 ; //ns, 
parameter tRH = 200 ; //ns, 
parameter tRPH = 400 ; //ns, 

parameter tVCS = 150000 ; //ns, 

parameter tDMV = 0 ; //ns,


//hybrid sleep 
parameter  tHSMXC_min=60; //ns
parameter  tHSMX_max=70000; //ns


parameter  tHSIN      = 3000; //ns
parameter  tCSHS_min  =   60; //ns
parameter  tCSHS_max  = 3000; //ns
parameter  tEXTHS_max = 100000; //ns


//DPD
parameter  tDPDIN      = 3000;  //3us
parameter  tDPDCSL     = 200;    //200ns
parameter  tDPDOUT_MAX = 150000; //150us
parameter  tCSDPD_min  = 200;    //200ns
parameter  tCSDPD_max  = 3000;   
parameter  tEXTDPD   = 150000;   




parameter memory_space=0;
parameter register_space=1;


`ifdef X8
`ifdef DDP
parameter DEFAULT_ID_REG0_DIE0           = 16'b00_0_01111_1000_0110;    //16 row bits, 9 colums bits, 0x0f86 
parameter DEFAULT_ID_REG1_DIE0           = 16'b00000000_0000_0001;      //hyperram  X8,               0x0001
parameter DEFAULT_ID_REG0_DIE1           = 16'b01_0_01111_1000_0110;    //16 row bits, 9 colums bits, 0x4f86 
parameter DEFAULT_ID_REG1_DIE1           = 16'b00000000_0000_0001;      //hyperram  X8,               0x0001
`else
parameter DEFAULT_ID_REG0           = 16'b00_0_01110_1000_0110;         //15 row bits, 9 colums bits, 0x0e86 
parameter DEFAULT_ID_REG1           = 16'b00000000_0000_0001;           //hyperram  X8,               0x0001
`endif
`else
parameter DEFAULT_ID_REG0           = 16'b00_0_01110_0111_0110;         //15 row bits, 8 colums bits,0x0e76 
parameter DEFAULT_ID_REG1           = 16'b00000000_0000_1001;           //hyperram-extened-IO X16   ,0x0009
`endif


parameter DEFAULT_CONFIG_REG0  = 16'b1_000_1111_0010_1_1_11;            //0x8f2f
parameter DEFAULT_CONFIG_REG1  = 16'b11111111_1_1_0_000_01;             //0xffC1

parameter INDEX_ID_REG0     =0;
parameter INDEX_ID_REG1     =1;
parameter INDEX_CONFIG_REG0 =2;
parameter INDEX_CONFIG_REG1 =3;

parameter ID0_READ = 48'hE0_00_00_00_00_00;
parameter ID1_READ = 48'hE0_00_00_00_00_01;
parameter CR0_READ = 48'hE0_00_01_00_00_00;
parameter CR0_WRITE= 48'h60_00_01_00_00_00;
parameter CR1_READ = 48'hE0_00_01_00_00_01;
parameter CR1_WRITE= 48'h60_00_01_00_00_01;



//dual die
parameter ID0_READ_DIE0 = 48'hE0_00_00_00_00_00;
parameter ID1_READ_DIE0 = 48'hE0_00_00_00_00_01;
parameter CR0_READ_DIE0 = 48'hE0_00_01_00_00_00;
parameter CR0_WRITE_DIE0= 48'h60_00_01_00_00_00;
parameter CR1_READ_DIE0 = 48'hE0_00_01_00_00_01;
parameter CR1_WRITE_DIE0= 48'h60_00_01_00_00_01;

parameter ID0_READ_DIE1 = 48'hE0_20_00_00_00_00;
parameter ID1_READ_DIE1 = 48'hE0_20_00_00_00_01;
parameter CR0_READ_DIE1 = 48'hE0_20_01_00_00_00;
parameter CR0_WRITE_DIE1= 48'h60_00_01_00_00_00;
parameter CR1_READ_DIE1 = 48'hE0_20_01_00_00_01;
parameter CR1_WRITE_DIE1= 48'h60_00_01_00_00_01;


parameter  CR1_SOFT_RESET = 4'b1010; //CR1[15:12]
//CR0
//CR0[15] 
parameter CR0_B15_ENETR_DPD=0;
parameter CR0_B15_NORMAL=1;

//CR0[14:12] 
parameter CR0_B14_12_drive_34_ohms    =3'b000; //default
parameter CR0_B14_12_drive_115_ohms   =3'b001;
parameter CR0_B14_12_drive_67_ohms    =3'b010;
parameter CR0_B14_12_drive_46_ohms    =3'b011;
parameter CR0_B14_12_drive_34_2_ohms  =3'b100; 
parameter CR0_B14_12_drive_27_ohms    =3'b101;
parameter CR0_B14_12_drive_22_ohms    =3'b110;
parameter CR0_B14_12_drive_19_ohms    =3'b111;

//CR0[7:4] 
parameter CR0_B7_4_LC5 =4'b0000;
parameter CR0_B7_4_LC6 =4'b0001; 
parameter CR0_B7_4_LC7 =4'b0010;
parameter CR0_B7_4_LC8 =4'b0011;
parameter CR0_B7_4_LC9 =4'b0100;
parameter CR0_B7_4_LC3 =4'b1110;
parameter CR0_B7_4_LC4 =4'b1111;

//CR0[3] 
parameter CR0_B3_VARIABLE_LATENCY=1'b0;
parameter CR0_B3_FIXED_LATENCY=1'b1;//default

//CR0[2] 
parameter CR0_B2_HYBRID_WRAP_BURST=1'b0;
parameter CR0_B2_LEGACY_WRAP_BURST=1'b1;

//CR0[1:0] 
parameter CR0_B1_0_BL_128 =2'b00;
parameter CR0_B1_0_BL_64  =2'b01;
parameter CR0_B1_0_BL_16  =2'b10;
parameter CR0_B1_0_BL_32  =2'b11; //default;

//CR1
//CR1[6] 
parameter CR1_B6_CLOCK_DIFF =1'b0;
parameter CR1_B6_CLOCK_SING =1'b1;

//CR1[5] 
parameter CR1_B5_NOT_IN_HALF_SLEEP =1'b0;
parameter CR1_B5_ENTER_HALF_SLEEP  =1'b1;


//CR1[4:2] 
parameter CR1_B4_2_FULL     =3'b000;
parameter CR1_B4_2_BOT_HALF =3'b001;
parameter CR1_B4_2_BOT_QRTR =3'b010;
parameter CR1_B4_2_BOT_OCTR =3'b011;
parameter CR1_B4_2_NONE     =3'b100;
parameter CR1_B4_2_TOP_HALF =3'b101;
parameter CR1_B4_2_TOP_QRTR =3'b110;
parameter CR1_B4_2_TOP_OCTR =3'b111;




//CR1[1:0] 
parameter CR1_B1_0_TBD_TIMES =2'b10;
parameter CR1_B1_0_1P5_TIMES =2'b11;
parameter CR1_B1_0_2_TIMES   =2'b00;
parameter CR1_B1_0_4_TIMES   =2'b01;



