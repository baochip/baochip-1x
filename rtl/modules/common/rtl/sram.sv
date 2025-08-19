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

/*
    MODULENAME  = sram
    AW          = 14
    DW          = 32

*/

module sram #(
    AW = 14,
    DW = 32
)
(
    input                       clk            ,
    ramif.slave                 ramport
);

    sram_basic #(
    .AW             (AW        ),
    .DW             (DW        )
    )uram(
    .clk            ( clk               ),
    .ramen          ( ramport.ramen     ),// SRAM write enable (active high)
    .ramcs          ( ramport.ramcs     ),// SRAM write enable (active high)
    .ramaddr        ( ramport.ramaddr   ),// SRAM Read Data
    .ramwr          ( ramport.ramwr     ),// SRAM address
    .ramrdata       ( ramport.ramrdata  ),// SRAM write data
    .ramwdata       ( ramport.ramwdata  )
    );
endmodule

module sram_basic #(
    AW = 14,
    DW = 32
)
(
    input                       clk            ,
    input                       ramen          ,
    input                       ramcs          ,
    input           [AW-1:0]    ramaddr        ,
    input           [DW/8-1:0]  ramwr          ,
    input           [DW-1:0]    ramwdata       ,
    output  logic   [DW-1:0]    ramrdata       
);

    localparam HEIGHT = 2**AW;
    localparam DWW = $clog2(DW);
    localparam WRW = DW/8;
`ifndef FPGA
`ifdef SIM
    bit [0:HEIGHT-1][DW-1:0]  ramdatareg;
    bit [DW-1:0]              rdatareg;
    logic                     oprd,opwr;
    bit [AW-1:0]              ramaddrreg;

genvar i;
generate
	for( i = 0; i < WRW; i = i + 1) begin: GenRnd
    always@(posedge clk) if(opwr) ramdatareg[ramaddr][i*8+7:i*8] <= ramwr[i] ? ramwdata[(i+1)*8-1:i*8] : ramdatareg[ramaddr][i*8+7:i*8];
end
endgenerate

    always@(posedge clk) rdatareg <= oprd ? ramdatareg[ramaddr] : rdatareg;
    always@(posedge clk) ramaddrreg <= oprd ? ramaddr : ramaddrreg;

    assign oprd = ramen * ramcs;// *  (ramwr==0);
    assign opwr = ramen * ramcs * ~(ramwr==0);

    assign ramrdata = ramen ? ramdatareg[ramaddrreg] : {DW{1'bz}};

`endif
`endif
`ifdef FPGA

// bram 36Kb, simple dual port RAM, v14.7
// Ref UG768(v14.7). 
    localparam BRAMAWPRIM = 15; // 36K(32k) x 1b
    localparam BRAMAW = BRAMAWPRIM - DWW;
    logic [0:fnbramcnt()-1][WRW-1:0] br_ramwr;
    logic [0:fnbramcnt()-1][DW-1:0]  br_ramrdata;
    logic [0:fnbramcnt()-1]          br_ramsel,br_ramselreg;

    function int fnbramcnt();
        int fntmp;
        if( AW > BRAMAW ) fntmp = 2**(AW-BRAMAW);
        else fntmp = 1;
        fnbramcnt = fntmp;
    endfunction

    always@(clk) br_ramselreg <= br_ramsel;

    function bit [DW-1:0] fnbramrdata(input logic [0:fnbramcnt()-1] fnbr_ramselreg, input logic [0:fnbramcnt()-1][DW-1:0]  fnbr_ramrdata);
        bit [DW-1:0] fntmp;
        int fni;
        for(fni = 0; fni < fnbramcnt(); fni = fni + 1 ) fntmp = fntmp | ( fnbr_ramrdata[fni] & {DW{fnbr_ramselreg[fni]}} );
        fnbramrdata = fntmp;
    endfunction

    assign ramrdata = fnbramrdata( br_ramselreg, br_ramrdata );

genvar i;
generate
	for( i = 0; i < fnbramcnt(); i = i + 1) begin: GenRnd

BRAM_SDP_MACRO #( 
    .BRAM_SIZE("36Kb"), // Target BRAM, "18Kb" or "36Kb" 
    .DEVICE("7SERIES"), // Target device: "VIRTEX5", "VIRTEX6", "SPARTAN6", "7SERIES" 
    .WRITE_WIDTH(DW), // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb") 
    .READ_WIDTH(DW), // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb") 
    .DO_REG(0), // Optional output register (0 or 1) 
    .INIT_FILE ("NONE"), 
    .SIM_COLLISION_CHECK ("NONE"), // Collision check enable "ALL", "WARNING_ONLY", // "GENERATE_X_ONLY" or "NONE" 
    .SRVAL(0), // Set/Reset value for port output 
    .INIT(0), // Initial values on output port 
    .WRITE_MODE("WRITE_FIRST") // Specify "READ_FIRST" for same clock or synchronous clocks // Specify "WRITE_FIRST for asynchronous clocks on ports 
)  ubram_macro36kb ( 
    .DO             (br_ramrdata[i]), // Output read data port, width defined by READ_WIDTH parameter 
    .DI             (ramwdata), // Input write data port, width defined by WRITE_WIDTH parameter 
    .RDADDR         (ramaddr), // Input read address, width defined by read port depth 
    .RDCLK          (clk), // 1-bit input read clock 
    .RDEN           (1'b1), // 1-bit input read port enable 
    .REGCE          (1'b0), // 1-bit input read output register enable 
    .RST            (1'b1), // 1-bit input reset 
    .WE             (br_ramwr[i]), // Input write enable, width defined by write port depth 
    .WRADDR         (ramaddr), // Input write address, width defined by write port depth 
    .WRCLK          (clk), // 1-bit input write clock 
    .WREN           (1'b1) // 1-bit input write port enable
 ); 

    assign br_ramsel[i] = (( ramaddr >> BRAMAW ) == i );
    assign br_ramwr[i] = br_ramsel[i] ? ramwr : 0;
	end
endgenerate

`endif

`ifdef ASIC
`endif

endmodule

module dummytb_sram ();

    parameter AW = 14;
    parameter DW = 32;
    logic clk;
    ramif ramport();

    sram u(.*);

endmodule