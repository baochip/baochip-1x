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

//Gf4 Square
module Gf4Square 
        (
         In,
         Out
        );

input [1:0]    In ;
output[1:0]    Out;

wire  [1:0]    In ;
wire  [1:0]    Out;

assign Out[1] = In[0]&In[0];
assign Out[0] = In[1]&In[1];

endmodule

//Gf4 Multiply
module Gf4Mult 
        (
         In1,
         In2,
         Out
        );

input [1:0]    In1;
input [1:0]    In2;
output[1:0]    Out;

wire  [1:0]    In1;
wire  [1:0]    In2;
wire  [1:0]    Out;

wire  tmp     ;

assign tmp    = (In1[1]^In1[0])&(In2[1]^In2[0]);

assign Out[1] = (In1[1]&In2[1])^tmp            ;
assign Out[0] = (In1[0]&In2[0])^tmp            ;

endmodule

//Gf4Inv
module Gf4Inv 
        (
        DataIn,
        MaskIn,
        DataOut 
        );

input  [1:0] DataIn;
input  [1:0] MaskIn;

output [1:0] DataOut;

wire   [1:0] DataIn;
wire   [1:0] MaskIn;
wire   [1:0] DataOut;

wire   [1:0] tmp1 ;
wire   [1:0] tmp2 ;


Gf4Square uGf4Square0(
         .In    (DataIn ),
         .Out    (tmp1   )
        );

Gf4Square uGf4Square1(
         .In    (MaskIn     ),
         .Out   (tmp2       )
        );

assign DataOut = tmp1^ tmp2 ^ MaskIn ;

endmodule


//Gf16 Square
module Gf16Square(
                 In,
                 Out
                );

input [3:0]    In;
output[3:0]    Out;

wire  [3:0]    In;
wire  [3:0]    Out;

wire  [1:0]    tmp1;
wire  [1:0]    tmp2;

wire  [1:0]    ah;
wire  [1:0]    al;

assign tmp1   = ah ^ al;

Gf4Mult uGf4Mult0(
                 .In1  (tmp1),
                 .In2  (2'd2),
                 .Out  (tmp2)
                 );

Gf4Square uGf4Square0(
                    .In  (In[3:2] ),
                    .Out (ah      )
                    );

Gf4Square uGf4Square1(
                    .In  (In[1:0] ),
                    .Out (al      )
                    );

assign Out[3:2] = ah ^ tmp2;
assign Out[1:0] = al ^ tmp2;

endmodule

//Gf16 Mult

module Gf16Mult(
         In1,
         In2,
         Out
        );

input [3:0]    In1 ;
input [3:0]    In2 ;
output[3:0]    Out ;

wire  [3:0]    In1 ;
wire  [3:0]    In2 ;
wire  [3:0]    Out ;

wire  [1:0]    tmp1;
wire  [1:0]    tmp2;
wire  [1:0]    tmp3;
wire  [1:0]    tmp4;


wire  [1:0]    ch;
wire  [1:0]    cl;

assign tmp1   = In1[3:2]^In1[1:0] ;
assign tmp2   = In2[3:2]^In2[1:0] ;

Gf4Mult uGf4Mult0(
        .In1  (tmp1),
        .In2  (tmp2),
        .Out  (tmp3)
        );

Gf4Mult uGf4Mut1( 
        .In1  (tmp3),
        .In2  (2'd2),
        .Out  (tmp4)
        );

Gf4Mult uGf4Mult2( 
        .In1  (In1[3:2] ),
        .In2  (In2[3:2] ),
        .Out  (ch       )
        );

Gf4Mult uGf4Mult3(
        .In1  (In1[1:0] ),
        .In2  (In2[1:0] ),
        .Out  (cl )
        );

assign Out[3:2] = ch ^ tmp4 ;
assign Out[1:0] = cl ^ tmp4 ;

endmodule

//Gf16 Inv

module Gf16Inv( 
              DataIn  ,
              MaskIn  ,
              DataOut
              );

input  [3:0] DataIn;
input  [3:0] MaskIn;

output [3:0] DataOut;

wire   [3:0] DataIn;
wire   [3:0] MaskIn;
wire   [3:0] DataOut;

wire[1:0] inv_ch,inv_cl      ;
wire[1:0] Ah,Al,rh,rl      ;
wire[1:0] add_Ahl, sqr_Ahl, d_tmp1 ,mult_Ahl , mult_rhl , add_rhl , sqr_rhl , d_tmp2  ;
wire[1:0] mult_Ahrl, mult_Alrh ;
wire[1:0] d,inv_add_drh , d1  ;
wire[1:0] mult_Ahd1, mult_Ald ;
wire[1:0] mult_rhd1, mult_rld ;

assign  Ah = DataIn[3:2]  ;   
assign  Al = DataIn[1:0]  ;
assign  rh = MaskIn[3:2]  ;   
assign  rl = MaskIn[1:0]  ;

assign add_Ahl = Ah ^ Al   ;
assign add_rhl = rh ^ rl   ;

Gf4Square uGf4Square0(
         .In    (add_Ahl     ),
         .Out   (sqr_Ahl     )
        );

Gf4Mult uGf4Mult0
        (
         .In1    (sqr_Ahl),
         .In2    (2'd2),
         .Out    (d_tmp1 )
        );

Gf4Mult uGf4Mult1
        (
         .In1    (Ah   ),
         .In2    (Al   ),
         .Out    (mult_Ahl )
        );

Gf4Mult uGf4Mult2
        (
         .In1    (rh   ),
         .In2    (rl   ),
         .Out    (mult_rhl )
        );

Gf4Square uGf4Square1
        (
         .In    (add_rhl     ),
         .Out    (sqr_rhl     )
        );

Gf4Mult uGf4Mult3
        (
         .In1    (sqr_rhl   ),
         .In2    (2'd2),
         .Out    (d_tmp2    )
        );

Gf4Mult uGf4Mult4
        (
         .In1    (Ah       ),
         .In2    (rl       ),
         .Out    (mult_Ahrl    )
        );

Gf4Mult uGf4Mult5
        (
         .In1    (Al       ),
         .In2    (rh       ),
         .Out    (mult_Alrh    )
        );

assign d = rh ^ d_tmp1 ^ mult_Ahl ^ mult_rhl ^ d_tmp2 ^ mult_Ahrl ^ mult_Alrh ;

Gf4Inv uGf4Inv(
        .DataIn   (d         ),
        .MaskIn   (rh        ),
        .DataOut  (inv_add_drh)
        );

assign d1 =  inv_add_drh ^ rh ^ rl  ;

Gf4Mult uGf4Mult6
        (
         .In1    (Al       ),
         .In2    (inv_add_drh           ),
         .Out    (mult_Ald    )
        );

Gf4Mult uGf4Mult7
        (
         .In1    (Ah       ),
         .In2    (d1           ),
         .Out    (mult_Ahd1    )
        );

Gf4Mult uGf4Mult8
        (
         .In1    (rl       ),
         .In2    (inv_add_drh           ),
         .Out    (mult_rld    )
        );

Gf4Mult uGf4Mult9
        (
         .In1    (rh       ),
         .In2    (d1           ),
         .Out    (mult_rhd1    )
        );

assign inv_ch = rh ^ mult_Ald ^ mult_rhl ^ mult_rld ^ mult_Alrh ;
assign inv_cl = rl ^ mult_Ahd1 ^ mult_rhl ^ mult_rhd1 ^ mult_Ahrl ;

assign DataOut= {inv_ch, inv_cl} ; 



endmodule

//Gf256Inv
module Gf256Inv(
               DataIn ,
               MaskIn ,
               DataOut 
               );

input [7 :0] DataIn ;
input [7 :0] MaskIn ;

output[7 :0] DataOut;

wire  [7 :0] DataIn ;
wire  [7 :0] MaskIn ;

wire  [7 :0] DataOut;


wire[3:0] d, add_Ahl, sqr_Ahl, d_tmp1 ,mult_Ahl , mult_rhl , add_rhl , sqr_rhl , d_tmp2  ;
wire[3:0] mult_Ahrl, mult_Alrh ;
wire[3:0] inv_add_drh , d1  ;
wire[3:0] mult_Ahd1, mult_Ald ;
wire[3:0] mult_rhd1, mult_rld ;
wire[3:0] Ah,Al,rh,rl,inv_ch, inv_cl;

assign  Ah = DataIn[7:4]  ;   
assign  Al = DataIn[3:0]  ;   
assign  rh = MaskIn[7:4]  ;   
assign  rl = MaskIn[3:0]  ;   

assign add_Ahl = Ah ^ Al   ;
assign add_rhl = rh ^ rl   ;

Gf16Square uGf16Square0
        (
         .In    (add_Ahl     ),
         .Out    (sqr_Ahl     )
        );

Gf16Mult uGf16Mult0
        (
         .In1    (sqr_Ahl),
         .In2    (4'd4),
         .Out    (d_tmp1 )
        );

Gf16Mult uGf16Mult1
        (
         .In1    (Ah   ),
         .In2    (Al   ),
         .Out    (mult_Ahl )
        );

Gf16Mult uGf16Mult2
        (
         .In1    (rh   ),
         .In2    (rl   ),
         .Out    (mult_rhl )
        );

Gf16Square uGf16Square1
        (
         .In    (add_rhl     ),
         .Out    (sqr_rhl     )
        );

Gf16Mult uGf16Mult3
        (
         .In1    (sqr_rhl   ),
         .In2    (4'd4),
         .Out    (d_tmp2    )
        );

Gf16Mult uGf16Mult4
        (
         .In1    (Ah       ),
         .In2    (rl       ),
         .Out    (mult_Ahrl    )
        );

Gf16Mult uGf16Mult5
        (
         .In1    (Al       ),
         .In2    (rh       ),
         .Out    (mult_Alrh    )
        );

assign d = rh ^ d_tmp1 ^ mult_Ahl ^ mult_rhl ^ d_tmp2 ^ mult_Ahrl ^ mult_Alrh ;

Gf16Inv uGf16Inv(
        .DataIn (d         ),
        .MaskIn (rh    ),
        .DataOut (inv_add_drh)
        );

assign d1 =  inv_add_drh ^ rh ^ rl  ;

Gf16Mult uGf16Mult6
        (
         .In1    (Al       ),
         .In2    (inv_add_drh            ),
         .Out    (mult_Ald     )
        );

Gf16Mult uGf16Mult7
        (
         .In1    (Ah       ),
         .In2    (d1           ),
         .Out    (mult_Ahd1    )
        );

Gf16Mult uGf16Mult8
        (
         .In1    (rl       ),
         .In2    (inv_add_drh            ),
         .Out    (mult_rld     )
        );

Gf16Mult uGf16Mult9
        (
         .In1    (rh       ),
         .In2    (d1           ),
         .Out    (mult_rhd1    )
        );

assign inv_ch = rh ^ mult_Ald ^ mult_rhl ^ mult_rld ^ mult_Alrh ;
assign inv_cl = rl ^ mult_Ahd1 ^ mult_rhl ^ mult_rhd1 ^ mult_Ahrl ;
assign DataOut= {inv_ch,inv_cl}; 


endmodule



















