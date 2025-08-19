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


`resetall
`timescale 1ns / 1ps
`default_nettype none
//`include "rtl/model/artisan_ram_def_v0.1.svh"

module Ram_1w_1rs #(
    parameter ramname = "undefined",
    parameter wordCount = 32,
    parameter wordWidth = 32,
    parameter clockCrossing = 0,
    parameter technology = "auto", // not used
    parameter readUnderWrite = "dontCare",
    parameter wrAddressWidth = 5,
    parameter wrDataWidth = 32,
    parameter wrMaskWidth = 1,
    parameter wrMaskEnable = 0,
    parameter rdAddressWidth = 5,
    parameter rdDataWidth = 32
)
(
    input  wire                             wr_clk,
    input  wire                             wr_en,
    input  wire [wrMaskWidth -1:0]          wr_mask,
    input  wire [wrAddressWidth - 1:0]      wr_addr,
    input  wire [wrDataWidth - 1:0]         wr_data,
    input  wire                             rd_clk,
    input  wire                             rd_en,
    input  wire [rdAddressWidth - 1:0]      rd_addr,
    output logic  [rdDataWidth - 1:0]         rd_data,
    input  wire [2:0]    sramtrm,

    rbif.slavedp              rbs,
    input  wire                             CMBIST, // dummy pins for test insertion
    input  wire                             CMATPG // dummy pins for test insertion

);

parameter WORD_WIDTH = wrMaskWidth;
parameter WORD_SIZE = wrDataWidth/WORD_WIDTH;


    // in rv5 clka/clkb is same clk.
    // to balance clock tree
    logic clkdp;
    CLKCELL_BUF ckbuf_clkdp( .A(rd_clk), .Z(clkdp));



initial begin
    if (readUnderWrite != "dontCare") begin
        $error("This implementation only handles readUnderWrite == dontCare");
    end
    if (wrDataWidth != rdDataWidth) begin
        $error("This implementation only handles wrDataWidth == rdDataWidth");
    end
    if (wrAddressWidth != rdAddressWidth) begin
        $error("This implementation only handles wrAddressWidth == rdAddressWidth");
    end
    if (clockCrossing != 0) begin
        $error("This implementation only handles clockCrossing == 0");
    end
end

parameter RAM_DATA_WIDTH = wrDataWidth;
parameter RAM_ADDR_WIDTH = wrAddressWidth;


`ifdef FPGA

reg [RAM_DATA_WIDTH-1:0] mem[(2**RAM_ADDR_WIDTH)-1:0];

integer i, j;

initial begin
    for (i = 0; i < 2**RAM_ADDR_WIDTH; i = i + 2**(RAM_ADDR_WIDTH/2)) begin
        for (j = i; j < i + 2**(RAM_ADDR_WIDTH/2); j = j + 1) begin
            mem[j] = 0;
        end
    end
end

always @(posedge clkdp) begin
    for (i = 0; i < WORD_WIDTH; i = i + 1) begin
        if (wr_en & (wr_mask[i] | !wrMaskEnable)) begin
            mem[wr_addr][WORD_SIZE*i +: WORD_SIZE] <= wr_data[WORD_SIZE*i +: WORD_SIZE];
        end
    end
end
always @(posedge clkdp) begin
    if (rd_en) begin
        rd_data <= mem[rd_addr];
    end
end

`else

    logic clka, clkb, cena, cenb;



    ICG icga(.CK(clkdp),.EN(rd_en),.SE(CMATPG),.CKG(clka));
    ICG icgb(.CK(clkdp),.EN(wr_en),.SE(CMATPG),.CKG(clkb));
    assign #0.5 cena = ( ~rd_en );
    assign #0.5 cenb = ( ~wr_en );

    logic [WORD_WIDTH-1:0][WORD_SIZE-1:0] wenb ;



    localparam AW = rdAddressWidth;
    localparam DW = rdDataWidth;

    logic rb_clka, rb_cena, rb_clkb, rb_cenb;
    logic [AW-1:0] rb_aa, rb_ab;
    logic [DW-1:0] rb_wenb, rb_qa, rb_db;


    rbdpmux #(.AW(AW),.DW(DW))rbmux(
         .cmsatpg   (CMATPG),
         .cmsbist   (CMBIST),
            .clka     (clka     ),.clkb      (clkb     ),
            .qa       (rd_data  ),.qb        (         ),
            .cena     (cena     ),.cenb      (cenb     ),
            .gwena    ('1       ),.gwenb     ('1       ),
            .wena     ('1       ),.wenb      (wenb     ),
            .aa       (rd_addr  ),.ab        (wr_addr  ),
            .da       ('0       ),.db        (wr_data  ),
            .rb_clka  (rb_clka  ),.rb_clkb   (rb_clkb  ),
            .rb_qa    (rb_qa    ),.rb_qb     ('0       ),
            .rb_cena  (rb_cena  ),.rb_cenb   (rb_cenb  ),
            .rb_gwena (         ),.rb_gwenb  (         ),
            .rb_wena  (         ),.rb_wenb   (rb_wenb  ),
            .rb_aa    (rb_aa    ),.rb_ab     (rb_ab    ),
            .rb_da    (         ),.rb_db     (rb_db    ),
         .rbs         (rbs)
       );

    generate
        if(ramname=="RAM_DP_32_16_WM"||ramname=="RAM_DP_32_16_MM") begin: gen_RAM_DP_32_16

            for (genvar i = 0; i < WORD_WIDTH; i++) begin: gwenb
                assign wenb[i] = ~{WORD_SIZE{wr_mask[i]}};
            end
                rdram32x16 m(
                .clka   (rb_clka   ),
                .cena   (rb_cena   ),
                .aa     (rb_aa     ),
                .qa     (rb_qa     ),
                .clkb   (rb_clkb   ),
                .cenb   (rb_cenb   ),
                .wenb   (rb_wenb   ),
                .ab     (rb_ab     ),
                .db     (rb_db     ),
                `rf_2p_hdc_inst_vex
                );
        end
        if(ramname=="RAM_DP_1024_32"&&wrMaskEnable==0) begin: gen_RAM_DP_1024_32_wrmask0
                assign wenb = '0;
                rdram1kx32 m(
                .clka   (rb_clka),
                .cena   (rb_cena),
                .aa     (rb_aa),
                .qa     (rb_qa),
                .clkb   (rb_clkb),
                .cenb   (rb_cenb),
                .wenb   (rb_wenb),
                .ab     (rb_ab),
                .db     (rb_db),
                `rf_2p_hdc_inst_vex
                );
        end
        if(ramname=="RAM_DP_1024_32"&&wrMaskEnable==1) begin: gen_RAM_DP_1024_32_wrmask1

            for (genvar i = 0; i < WORD_WIDTH; i++) begin: gwenb
                assign wenb[i] = ~{WORD_SIZE{wr_mask[i]}};
            end
                rdram1kx32 m(
                .clka   (rb_clka   ),
                .cena   (rb_cena   ),
                .aa     (rb_aa     ),
                .qa     (rb_qa     ),
                .clkb   (rb_clkb   ),
                .cenb   (rb_cenb   ),
                .wenb   (rb_wenb   ),
                .ab     (rb_ab     ),
                .db     (rb_db     ),
                `rf_2p_hdc_inst_vex
                );
        end
        if(ramname=="RAM_DP_512_64") begin: gen_RAM_DP_512_64
                rdram512x64 m(
                .clka   (rb_clka   ),
                .cena   (rb_cena   ),
                .aa     (rb_aa     ),
                .qa     (rb_qa     ),
                .clkb   (rb_clkb   ),
                .cenb   (rb_cenb   ),
                .ab     (rb_ab     ),
                .db     (rb_db     ),
                `rf_2p_hdc_inst_vex
                );
        end
        if(ramname=="RAM_DP_128_22") begin: gen_RAM_DP_128_22
                rdram128x22 m(
                .clka   (rb_clka   ),
                .cena   (rb_cena   ),
                .aa     (rb_aa     ),
                .qa     (rb_qa     ),
                .clkb   (rb_clkb   ),
                .cenb   (rb_cenb   ),
                .ab     (rb_ab     ),
                .db     (rb_db     ),
                `rf_2p_hdc_inst_vex
                );
        end


    endgenerate



`endif


endmodule

`resetall