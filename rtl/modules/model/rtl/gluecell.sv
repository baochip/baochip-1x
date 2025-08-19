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


    module ip_gluecell (
    //	input logic ana_laser_in,
    //	inout wire vddd,
    //	inout wire vssd,
`ifdef MPW
        input wire ana_test_use_only,
`endif
    	input logic d2a_glue_in,
    	input logic d2a_nrst,
    	output logic a2d_glue_out
    );

`ifdef FPGA
        assign a2d_glue_out = '0;
`elsif SIM
        bit thereg = 0;
        always@(negedge d2a_nrst) thereg <= 0;
        assign a2d_glue_out = thereg | d2a_glue_in;

        integer a=0,b=0;
        initial begin
            while (1) begin
                #(200 `US );
                a = $urandom()%256;
                if(a==1)begin
                 thereg = 1;
//                 $display("%m: thereg");
                end
            end
        end
`endif

    endmodule
