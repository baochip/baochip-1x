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

//  Description : Daric Testbench Utility Package
//                General definitions/parameters used in the testbench 
//
//  Notes:
//      --- AHB defines
//      ips/nic400_hxb32/logical/nic400_hxb32/amib_axim/verilog/Ahb.v
//
/////////////////////////////////////////////////////////////////////////// 

package tb_util_pkg;

    `include "ccitt_rand.task.sv"
    `include "crc_generator.func.sv"
    `include "list_length.func.sv"
    `include "pattern_generator.task.sv"
    `include "pattern_summary.func.sv"

  `define PASS 1'b1
  `define FAIL 1'b0

  `define CHECK 1'b1
  `define NO_CHECK 1'b0

  `define WRITE 1'b1
  `define READ 1'b0


  parameter AXI_ID_WIDTH   = 4;
  parameter AXI_ADDR_WIDTH = 32;
  parameter AXI_DATA_WIDTH = 256;
  parameter AXI_LEN_WIDTH  = 8;
  parameter AXI_USER_WIDTH = 8;

  parameter AW = 32;
  parameter DW = 32;


  localparam DATAWIDTH = 64;
  localparam DATA_BYTES = 8;
  //Function to account for the Big Endianness of $fread
  function [DATAWIDTH-1:0] swizzle;
      input [DATAWIDTH-1:0] data_in;
      integer i;
      begin
        for (i=0; i<DATA_BYTES; i=i+1)
          swizzle[i*8 +:8] = data_in[(DATA_BYTES-1-i)*8 +:8];
      end
  endfunction

  function [143:0] rram_encoder;
    input [127:0] messg;
    input mode;
    bit [15:0] parity;

      parity[0]=    messg[0]^    messg[2]^    messg[3]^    messg[4]^    messg[5]^    messg[6]^    messg[12]^    messg[14]^    messg[15]^
                  messg[16]^    messg[18]^    messg[19]^    messg[20]^    messg[21]^    messg[26]^    messg[28]^    messg[31]^    messg[37]^
    messg[38]^    messg[39]^    messg[40]^    messg[42]^    messg[43]^    messg[44]^    messg[46]^    messg[48]^    messg[49]^    messg[51]^
    messg[52]^    messg[53]^    messg[63]^    messg[65]^    messg[66]^    messg[69]^    messg[70]^    messg[71]^    messg[72]^    messg[73]^
    messg[75]^    messg[76]^    messg[77]^    messg[79]^    messg[82]^    messg[84]^    messg[87]^    messg[89]^    messg[91]^    messg[93]^
    messg[97]^    messg[98]^    messg[101]^    messg[107]^    messg[110]^    messg[111]^    messg[112]^    messg[120]^    messg[121]^
    messg[123]^    messg[124]^    messg[125];

     parity[1]=    messg[0]^    messg[1]^    messg[2]^    messg[7]^    messg[8]^    messg[12]^    messg[13]^    messg[14]^    messg[17]^
    messg[20]^    messg[22]^    messg[24]^    messg[26]^    messg[27]^    messg[28]^    messg[29]^    messg[31]^    messg[32]^    messg[37]^
    messg[41]^    messg[45]^    messg[46]^    messg[47]^    messg[48]^    messg[54]^    messg[57]^    messg[63]^    messg[64]^    messg[65]^
    messg[67]^    messg[73]^    messg[74]^    messg[75]^    messg[78]^    messg[79]^    messg[80]^    messg[82]^    messg[83]^    messg[84]^
    messg[85]^    messg[86]^    messg[87]^    messg[88]^    messg[89]^    messg[90]^    messg[91]^    messg[92]^    messg[93]^    messg[94]^
    messg[96]^    messg[97]^    messg[98]^    messg[99]^    messg[101]^    messg[102]^    messg[107]^    messg[108]^    messg[113]^
    messg[120]^    messg[121]^    messg[122]^    messg[123]^    messg[126]^    messg[127];

     parity[2]=    messg[1]^    messg[2]^    messg[3]^    messg[8]^    messg[9]^    messg[13]^    messg[14]^    messg[15]^    messg[18]^
    messg[20]^    messg[21]^    messg[23]^    messg[27]^    messg[28]^    messg[29]^    messg[30]^    messg[32]^    messg[33]^    messg[38]^
    messg[47]^    messg[48]^    messg[49]^    messg[50]^    messg[51]^    messg[54]^    messg[58]^    messg[64]^    messg[65]^    messg[66]^
    messg[73]^    messg[74]^    messg[75]^    messg[76]^    messg[79]^    messg[80]^    messg[81]^    messg[83]^    messg[86]^    messg[87]^
    messg[89]^    messg[90]^    messg[91]^    messg[92]^    messg[93]^    messg[94]^    messg[95]^    messg[96]^    messg[97]^    messg[99]^
    messg[102]^    messg[103]^    messg[105]^    messg[108]^    messg[109]^    messg[110]^    messg[114]^    messg[122]^    messg[123]^
    messg[124]^    messg[127];

     parity[3]=     messg[2]^    messg[3]^    messg[4]^    messg[8]^    messg[9]^    messg[10]^    messg[14]^    messg[15]^    messg[16]^
    messg[19]^    messg[21]^    messg[22]^    messg[24]^    messg[25]^    messg[28]^    messg[29]^    messg[30]^    messg[32]^    messg[33]^
    messg[34]^    messg[39]^    messg[46]^    messg[48]^    messg[49]^    messg[50]^    messg[52]^    messg[54]^    messg[57]^    messg[59]^
    messg[65]^    messg[66]^    messg[67]^    messg[68]^    messg[69]^    messg[74]^    messg[75]^    messg[76]^    messg[77]^    messg[80]^
    messg[81]^    messg[82]^    messg[84]^    messg[85]^    messg[86]^    messg[87]^    messg[88]^    messg[90]^    messg[91]^    messg[92]^
    messg[93]^    messg[94]^    messg[95]^    messg[97]^    messg[98]^    messg[102]^    messg[103]^    messg[104]^    messg[106]^
    messg[109]^    messg[111]^    messg[114]^    messg[115]^    messg[121]^    messg[123]^    messg[124]^    messg[125]^    messg[127];

     parity[4]=    messg[3]^    messg[4]^    messg[5]^    messg[9]^    messg[10]^    messg[11]^    messg[15]^    messg[16]^    messg[17]^    messg[18]^
    messg[22]^    messg[23]^    messg[26]^    messg[29]^    messg[30]^    messg[33]^    messg[34]^    messg[35]^    messg[40]^    messg[42]^    messg[46]^    messg[47]^
    messg[49]^    messg[50]^    messg[53]^    messg[55]^    messg[58]^    messg[60]^    messg[66]^    messg[67]^    messg[68]^    messg[70]^    messg[73]^
    messg[75]^    messg[76]^    messg[77]^    messg[78]^    messg[81]^    messg[82]^    messg[83]^    messg[84]^    messg[87]^    messg[88]^    messg[89]^
    messg[91]^    messg[92]^    messg[93]^    messg[94]^    messg[95]^    messg[96]^    messg[99]^    messg[102]^    messg[103]^    messg[104]^    messg[105]^
    messg[107]^    messg[110]^    messg[112]^    messg[114]^    messg[115]^    messg[116]^    messg[121]^    messg[122]^    messg[124]^    messg[125]^    messg[126];

     parity[5]=    messg[0]^    messg[2]^    messg[3]^    messg[10]^    messg[11]^    messg[14]^    messg[15]^    messg[17]^    messg[18]^
     messg[20]^    messg[21]^    messg[23]^    messg[24]^    messg[25]^    messg[26]^    messg[27]^    messg[28]^    messg[30]^    messg[32]^
    messg[34]^    messg[35]^    messg[36]^    messg[37]^    messg[38]^    messg[39]^    messg[40]^    messg[42]^    messg[44]^    messg[46]^    messg[47]^
    messg[49]^    messg[52]^    messg[53]^    messg[55]^    messg[56]^    messg[59]^    messg[61]^    messg[63]^    messg[65]^    messg[66]^
    messg[67]^    messg[68]^    messg[70]^    messg[72]^    messg[74]^    messg[75]^    messg[78]^    messg[83]^    messg[84]^    messg[85]^    messg[86]^    messg[87]^
    messg[88]^    messg[90]^    messg[91]^    messg[92]^    messg[94]^    messg[95]^    messg[96]^    messg[100]^    messg[101]^    messg[102]^
    messg[103]^    messg[104]^    messg[105]^    messg[106]^    messg[107]^    messg[108]^    messg[112]^    messg[113]^    messg[115]^    messg[116]^
    messg[117]^    messg[120]^    messg[121]^    messg[122]^    messg[124]^    messg[126];

     parity[6]=    messg[0]^    messg[1]^    messg[2]^    messg[5]^    messg[6]^    messg[8]^    messg[11]^    messg[14]^    messg[22]^    messg[24]^    messg[27]^
    messg[29]^    messg[32]^    messg[33]^    messg[35]^    messg[36]^    messg[45]^    messg[47]^    messg[49]^    messg[50]^    messg[51]^
    messg[52]^    messg[54]^    messg[55]^    messg[56]^    messg[57]^    messg[60]^    messg[62]^    messg[63]^    messg[64]^    messg[65]^
    messg[67]^    messg[69]^    messg[70]^    messg[72]^    messg[73]^    messg[77]^    messg[82]^    messg[86]^    messg[92]^    messg[95]^
    messg[100]^    messg[103]^    messg[104]^    messg[105]^    messg[106]^    messg[108]^    messg[109]^    messg[111]^    messg[112]^    messg[113]^
    messg[116]^    messg[117]^    messg[118]^    messg[120]^    messg[121]^    messg[122]^    messg[124];

     parity[7]=    messg[1]^    messg[2]^    messg[3]^    messg[6]^    messg[7]^    messg[8]^    messg[9]^    messg[12]^    messg[15]^    messg[20]^
    messg[23]^    messg[24]^    messg[25]^    messg[28]^    messg[30]^    messg[31]^    messg[32]^    messg[33]^    messg[34]^    messg[36]^
    messg[37]^    messg[42]^    messg[44]^    messg[48]^    messg[51]^    messg[52]^    messg[53]^    messg[54]^    messg[56]^    messg[58]^    messg[61]^
    messg[63]^    messg[64]^    messg[65]^    messg[66]^    messg[68]^    messg[70]^    messg[71]^    messg[73]^    messg[74]^    messg[78]^
    messg[83]^    messg[84]^    messg[87]^    messg[93]^    messg[98]^    messg[101]^    messg[102]^    messg[104]^    messg[105]^    messg[106]^
    messg[107]^    messg[109]^    messg[110]^    messg[112]^    messg[113]^    messg[114]^    messg[117]^    messg[118]^
    messg[119]^    messg[122]^    messg[123]^    messg[125];

     parity[8]=    messg[0]^    messg[5]^    messg[6]^    messg[7]^    messg[9]^    messg[10]^    messg[12]^    messg[13]^    messg[14]^    messg[15]^    messg[19]^
    messg[25]^    messg[28]^    messg[29]^    messg[32]^    messg[33]^    messg[34]^    messg[35]^    messg[39]^    messg[40]^    messg[44]^    messg[45]^
    messg[48]^    messg[59]^    messg[62]^    messg[63]^    messg[64]^    messg[67]^    messg[70]^    messg[73]^    messg[74]^    messg[76]^    messg[77]^
    messg[82]^    messg[84]^    messg[87]^    messg[89]^    messg[91]^    messg[93]^    messg[94]^    messg[96]^    messg[97]^    messg[99]^    messg[100]^
    messg[101]^    messg[102]^    messg[103]^    messg[106]^    messg[108]^    messg[112]^    messg[113]^    messg[115]^
    messg[118]^    messg[119]^    messg[120]^    messg[125]^    messg[126];

     parity[9]=    messg[0]^    messg[1]^    messg[2]^    messg[3]^    messg[4]^    messg[5]^    messg[7]^    messg[10]^    messg[11]^    messg[12]^    messg[13]^
    messg[19]^    messg[20]^    messg[21]^    messg[24]^    messg[25]^    messg[28]^    messg[29]^    messg[30]^    messg[31]^    messg[33]^    messg[34]^
    messg[35]^    messg[36]^    messg[37]^    messg[38]^    messg[39]^    messg[41]^    messg[43]^    messg[45]^    messg[48]^    messg[50]^
    messg[51]^    messg[52]^    messg[53]^    messg[54]^    messg[55]^    messg[60]^    messg[64]^    messg[66]^    messg[69]^    messg[70]^    messg[72]^
    messg[74]^    messg[76]^    messg[78]^    messg[79]^    messg[82]^    messg[83]^    messg[86]^    messg[87]^    messg[89]^    messg[90]^
    messg[91]^    messg[92]^    messg[93]^    messg[94]^    messg[95]^    messg[96]^    messg[103]^    messg[104]^    messg[105]^    messg[109]^    messg[110]^
    messg[111]^    messg[112]^    messg[113]^    messg[114]^    messg[116]^    messg[119]^    messg[123]^    messg[124]^    messg[125]^    messg[126]^    messg[127];

     parity[10]=    messg[0]^    messg[1]^    messg[11]^    messg[13]^    messg[15]^    messg[16]^    messg[19]^    messg[22]^    messg[24]^    messg[28]^
    messg[29]^    messg[30]^    messg[32]^    messg[34]^    messg[35]^    messg[36]^    messg[42]^    messg[43]^    messg[46]^    messg[48]^    messg[54]^
    messg[55]^    messg[56]^    messg[57]^    messg[61]^    messg[63]^    messg[66]^    messg[67]^    messg[68]^    messg[69]^    messg[72]^    messg[73]^
    messg[76]^    messg[80]^    messg[82]^    messg[83]^    messg[84]^    messg[86]^    messg[89]^    messg[90]^    messg[92]^    messg[94]^    messg[95]^
    messg[96]^    messg[98]^    messg[101]^    messg[104]^    messg[105]^    messg[106]^    messg[107]^    messg[113]^    messg[115]^    messg[117]^
    messg[121]^    messg[123]^    messg[126];

     parity[11]=    messg[0]^    messg[1]^    messg[3]^    messg[4]^    messg[5]^    messg[6]^    messg[15]^    messg[17]^    messg[19]^    messg[20]^    messg[21]^
    messg[23]^    messg[25]^    messg[26]^    messg[28]^    messg[29]^    messg[30]^    messg[31]^    messg[32]^    messg[33]^    messg[35]^
    messg[36]^    messg[38]^    messg[39]^    messg[40]^    messg[41]^    messg[44]^    messg[46]^    messg[47]^    messg[48]^    messg[50]^
    messg[51]^    messg[52]^    messg[53]^    messg[54]^    messg[56]^    messg[58]^    messg[62]^    messg[63]^    messg[64]^    messg[65]^
    messg[66]^    messg[67]^    messg[68]^    messg[69]^    messg[71]^    messg[72]^    messg[74]^    messg[75]^    messg[76]^    messg[79]^
    messg[81]^    messg[82]^    messg[83]^    messg[85]^    messg[86]^    messg[89]^    messg[90]^    messg[95]^    messg[99]^    messg[101]^
    messg[106]^    messg[108]^    messg[110]^    messg[111]^    messg[112]^    messg[116]^    messg[118]^    messg[122]^    messg[123]^    messg[125];

     parity[12]=    messg[1]^    messg[2]^    messg[4]^    messg[5]^    messg[6]^    messg[7]^    messg[8]^    messg[16]^    messg[18]^    messg[21]^
    messg[22]^    messg[25]^    messg[26]^    messg[27]^    messg[29]^    messg[30]^    messg[31]^    messg[33]^    messg[34]^    messg[36]^
    messg[37]^    messg[39]^    messg[40]^    messg[41]^    messg[45]^    messg[46]^    messg[47]^    messg[48]^    messg[49]^    messg[50]^
    messg[52]^    messg[53]^    messg[55]^    messg[59]^    messg[63]^    messg[64]^    messg[65]^    messg[66]^    messg[67]^    messg[70]^
    messg[72]^    messg[75]^    messg[76]^    messg[77]^    messg[80]^    messg[82]^    messg[83]^    messg[84]^    messg[86]^    messg[87]^
    messg[88]^    messg[90]^    messg[91]^    messg[100]^    messg[102]^    messg[105]^    messg[107]^    messg[109]^    messg[110]^    messg[111]^
    messg[112]^    messg[113]^    messg[117]^    messg[119]^    messg[123]^    messg[124]^    messg[126];

     parity[13]=    messg[0]^    messg[4]^    messg[7]^    messg[9]^    messg[12]^    messg[14]^    messg[15]^    messg[16]^    messg[17]^    messg[18]^
    messg[20]^    messg[21]^    messg[22]^    messg[23]^    messg[24]^    messg[27]^    messg[30]^    messg[34]^    messg[35]^    messg[39]^
    messg[41]^    messg[43]^    messg[44]^    messg[46]^    messg[47]^    messg[50]^    messg[52]^    messg[55]^    messg[56]^    messg[60]^
    messg[63]^    messg[64]^    messg[67]^    messg[68]^    messg[70]^    messg[72]^    messg[73]^    messg[75]^    messg[78]^    messg[79]^
    messg[81]^    messg[82]^    messg[83]^    messg[86]^    messg[92]^    messg[93]^    messg[96]^    messg[97]^    messg[103]^    messg[106]^
    messg[107]^    messg[108]^    messg[110]^    messg[113]^    messg[118]^    messg[120]^    messg[121]^    messg[123];

     parity[14]=    messg[0]^    messg[1]^    messg[2]^    messg[3]^    messg[4]^    messg[6]^    messg[10]^    messg[12]^    messg[13]^
    messg[14]^    messg[17]^    messg[18]^    messg[22]^    messg[23]^    messg[26]^    messg[35]^    messg[36]^    messg[37]^    messg[38]^
    messg[39]^    messg[42]^    messg[43]^    messg[45]^    messg[46]^    messg[47]^    messg[49]^    messg[51]^    messg[52]^    messg[55]^
    messg[56]^    messg[61]^    messg[63]^    messg[64]^    messg[66]^    messg[69]^    messg[70]^    messg[72]^    messg[73]^    messg[74]^
    messg[75]^    messg[77]^    messg[80]^    messg[83]^    messg[86]^    messg[89]^    messg[91]^    messg[94]^    messg[96]^    messg[101]^
    messg[104]^    messg[105]^    messg[108]^    messg[109]^    messg[110]^    messg[112]^    messg[119]^    messg[121]^
    messg[122]^    messg[123]^    messg[125];

    parity[15]=    messg[1]^    messg[2]^    messg[3]^    messg[4]^    messg[5]^    messg[7]^    messg[11]^    messg[13]^    messg[14]^    messg[15]^
    messg[18]^    messg[19]^    messg[20]^    messg[23]^    messg[25]^    messg[27]^    messg[31]^    messg[36]^    messg[37]^    messg[38]^
    messg[39]^    messg[40]^    messg[41]^    messg[42]^    messg[43]^    messg[47]^    messg[48]^    messg[50]^    messg[51]^    messg[52]^
    messg[53]^    messg[56]^    messg[62]^    messg[64]^    messg[65]^    messg[67]^    messg[68]^    messg[69]^    messg[70]^    messg[71]^
    messg[74]^    messg[75]^    messg[76]^    messg[78]^    messg[81]^    messg[84]^    messg[85]^    messg[86]^    messg[87]^    messg[88]^
    messg[90]^    messg[92]^    messg[95]^    messg[96]^    messg[97]^    messg[100]^    messg[106]^    messg[109]^    messg[110]^    messg[111]^
    messg[113]^    messg[122]^    messg[123]^    messg[124]^    messg[126]^    messg[127];

    rram_encoder =(mode)?({parity,messg}):(144'd0);

  endfunction


endpackage : tb_util_pkg

