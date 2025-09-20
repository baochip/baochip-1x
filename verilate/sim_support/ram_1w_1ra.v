// Coded very narrowly to meet the spec of the register file generated for the VexRiscv core.

`resetall
`timescale 1ns / 1ps
`default_nettype none

module Ram_1w_1ra #(
    parameter wordCount = 32,
    parameter wordWidth = 32,
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
    input  wire                             clk,
    input  wire                             wr_en,
    input  wire                             wr_mask,
    input  wire [wrAddressWidth - 1:0]      wr_addr,
    input  wire [wrDataWidth - 1:0]         wr_data,
    input  wire [rdAddressWidth - 1:0]      rd_addr,
    output reg  [rdDataWidth - 1:0]         rd_data
);

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
    if (wrMaskWidth != 1) begin
        $error("This implementation only handles wrMaskWidth == 1");
    end
end

parameter RAM_DATA_WIDTH = wrDataWidth;
parameter RAM_ADDR_WIDTH = wrAddressWidth;

reg [RAM_DATA_WIDTH-1:0] mem[(2**RAM_ADDR_WIDTH)-1:0];

integer i, j;

initial begin
    for (i = 0; i < 2**RAM_ADDR_WIDTH; i = i + 2**(RAM_ADDR_WIDTH/2)) begin
        for (j = i; j < i + 2**(RAM_ADDR_WIDTH/2); j = j + 1) begin
            mem[j] = 0;
        end
    end
end

always @* begin
    rd_data = mem[rd_addr];
end

always @(posedge clk) begin
    if (wr_en == 1'b1) begin
        mem[wr_addr] <= wr_data;
    end
end

endmodule

`resetall