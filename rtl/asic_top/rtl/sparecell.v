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

module sparecell#(parameter SPC=10)();
`ifdef SYN
//wire logic0, logic1;
generate
    for (genvar i = 0; i < SPC; i++) begin: gencell

		//TIEHBWP40P140HVT U_SPARECELL0 (.Z(logic1));
		//TIELBWP40P140HVT U_SPARECELL1 (.ZN(logic0));

		INVD4BWP40P140HVT U_SPARECELL2 (.I(1'b0) );
		INVD4BWP40P140HVT U_SPARECELL3 (.I(1'b0) );
		INVD4BWP40P140HVT U_SPARECELL4 (.I(1'b0) );
		INVD4BWP40P140HVT U_SPARECELL5 (.I(1'b0) );
		INVD4BWP40P140HVT U_SPARECELL6 (.I(1'b0) );

		ND2D2BWP40P140HVT U_SPARECELL10 (.A1(1'b0), .A2(1'b1) );
		ND2D2BWP40P140HVT U_SPARECELL11 (.A1(1'b0), .A2(1'b1) );
		ND2D2BWP40P140HVT U_SPARECELL12 (.A1(1'b0), .A2(1'b1) );
		ND2D2BWP40P140HVT U_SPARECELL13 (.A1(1'b0), .A2(1'b1) );
		ND2D2BWP40P140HVT U_SPARECELL14 (.A1(1'b0), .A2(1'b1) );

		NR2D2BWP40P140HVT U_SPARECELL20 (.A1(1'b0), .A2(1'b1) );
		NR2D2BWP40P140HVT U_SPARECELL21 (.A1(1'b0), .A2(1'b1) );
		NR2D2BWP40P140HVT U_SPARECELL22 (.A1(1'b0), .A2(1'b1) );
		NR2D2BWP40P140HVT U_SPARECELL23 (.A1(1'b0), .A2(1'b1) );
		NR2D2BWP40P140HVT U_SPARECELL24 (.A1(1'b0), .A2(1'b1) );

		SDFCSNQD2BWP40P140HVT U_SPARECELL30 (.D(1'b0), .SI(1'b0), .SE(1'b0), .CP(1'b0), .CDN(1'b1), .SDN(1'b1));
		SDFCSNQD2BWP40P140HVT U_SPARECELL31 (.D(1'b0), .SI(1'b0), .SE(1'b0), .CP(1'b0), .CDN(1'b1), .SDN(1'b1));
		SDFCSNQD2BWP40P140HVT U_SPARECELL32 (.D(1'b0), .SI(1'b0), .SE(1'b0), .CP(1'b0), .CDN(1'b1), .SDN(1'b1));
    end
endgenerate
`endif
endmodule
