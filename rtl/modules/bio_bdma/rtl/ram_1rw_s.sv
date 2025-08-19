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

// This is modeled on Single-Port High Density Register File for 22ULL spec
// Clock speed target = 800MHz, Min Cycle clk ~0.6ns @ typical
module Ram_1rw_s #(
    parameter ramname = "undefined",
    parameter wordCount = 1024,
    parameter wordWidth = 32,
    parameter technology = "auto", // not used
    parameter AddressWidth = 10,
    parameter DataWidth = 32,
    parameter wrMaskWidth = 4,
    parameter wrMaskEnable = 1
)
(
    input  wire                             clk,
    input  wire [AddressWidth - 1:0]        addr,
    input  wire [DataWidth - 1:0]           d,
    output reg  [DataWidth - 1:0]           q,
    input  wire                             wr_n,    // gwen on RAM maacro
    input  wire                             ce_n,
    input  wire [wrMaskWidth -1:0]          wr_mask_n, // wen[n-1] on RAM macro
    rbif.slave                              rbs,
    input  wire                             cmbist, // dummy pins for test insertion
    input  wire                             cmatpg, // dummy pins for test insertion
    input  wire [2:0]                       sramtrm // dummy pins for trim insertion
);

parameter WORD_WIDTH = wrMaskWidth;
parameter WORD_SIZE = DataWidth/WORD_WIDTH;

parameter RAM_DATA_WIDTH = DataWidth;
parameter RAM_ADDR_WIDTH = AddressWidth;

`ifdef FPGA
reg [RAM_DATA_WIDTH-1:0] mem[(2**RAM_ADDR_WIDTH)-1:0];

integer i, j;

initial begin
    for (i = 0; i < 2**RAM_ADDR_WIDTH; i = i + 2**(RAM_ADDR_WIDTH/2)) begin
        for (j = i; j < i + 2**(RAM_ADDR_WIDTH/2); j = j + 1) begin
            mem[j] = 'X;
        end
    end
end

always @(posedge clk) begin
    if (!ce_n) begin
        q <= mem[addr];
        for (i = 0; i < WORD_WIDTH; i = i + 1) begin: writes
            if (!(wr_n | (wr_mask_n[i])) & wrMaskEnable) begin
                mem[addr][WORD_SIZE*i +: WORD_SIZE] <= d[WORD_SIZE*i +: WORD_SIZE];
            end
        end
    end else begin
        q <= q;
    end
end

`else
    localparam AW = AddressWidth;
    localparam DW = DataWidth;

    logic cen_gate, clk_gate;
    assign #0.5 cen_gate = ce_n;
    ICG icg(.CK(clk),.EN(~cen_gate),.SE(cmatpg),.CKG(clk_gate));

    logic rb_clk;
    logic rb_cen;
    logic [AW-1:0] rb_addr;
    logic [DW-1:0] rb_data;
    logic [DW-1:0] rb_wenb;
    logic [DW-1:0] rb_wr_data;
    logic rb_gwen;
    logic [DW-1:0] wenb;

    // This needs checking - not sure if this is correct!
    integer i;
    always @(*) begin
        for (i = 0; i < DW; i++) begin
            wenb[i] = wr_mask_n[i / WORD_SIZE];
        end
    end

    rbspmux #(.AW(AW),.DW(DW))rbmux(
            .cmsatpg   (cmatpg),
            .cmsbist   (cmbist),
            .clk     (clk_gate ),
            .q       (q        ),
            .cen     (cen_gate ),
            .gwen    (wr_n     ),
            .wen     (wenb     ),
            .a       (addr     ),
            .d       (d        ),
            .rb_clk  (rb_clk   ),
            .rb_q    (rb_data  ),
            .rb_cen  (rb_cen   ),
            .rb_gwen (rb_gwen  ),
            .rb_wen  (rb_wenb  ),
            .rb_a    (rb_addr  ),
            .rb_d    (rb_wr_data),
            .rbs     (rbs      )
        );

    generate
        if(ramname=="RAM_SP_1024_32") begin: gen_RAM_SP_1024_32
            bioram1kx32 m(
            .clk    (rb_clk    ),
            .cen    (rb_cen    ),
            .a      (rb_addr   ),
            .q      (rb_data   ),
            .d      (rb_wr_data),
            .gwen   (rb_gwen   ),
            .wen    (rb_wenb   ),
            `rf_sp_hde_inst_bio
            );
        end
     endgenerate

`endif

endmodule

`resetall
