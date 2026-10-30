module ifram32kx36 (q, clk, cen, gwen, a, d, wen, stov, ema, emaw, emas, ret1n, rawl, 
    rawlm, wabl, wablm);

  output reg [35:0] q;
  input  clk;
  input  cen;
  input  gwen;
  input [14:0] a;
  input [35:0] d;
  input [35:0] wen;
  input  stov;
  input [2:0] ema;
  input [1:0] emaw;
  input  emas;
  input  ret1n;
  input  rawl;
  input [1:0] rawlm;
  input  wabl;
  input [2:0] wablm;

  parameter RAM_DATA_WIDTH = 36;
  parameter RAM_ADDR_WIDTH = 15;
  parameter WORD_SIZE = 1;
  parameter WORD_WIDTH = 36;

  reg [RAM_DATA_WIDTH-1:0] mem[(2**RAM_ADDR_WIDTH)-1:0];

  integer i, j;

  initial begin
      for (i = 0; i < 2**RAM_ADDR_WIDTH; i = i + 2**(RAM_ADDR_WIDTH/2)) begin
          for (j = i; j < i + 2**(RAM_ADDR_WIDTH/2); j = j + 1) begin
              mem[j] = 0;
          end
      end
  end

  always @(posedge clk) begin
      for (i = 0; i < WORD_WIDTH; i = i + 1) begin
          if (~gwen & ~wen[i] & ~cen) begin
              mem[a][WORD_SIZE*i +: WORD_SIZE] <= d[WORD_SIZE*i +: WORD_SIZE];
          end
      end
      q <= mem[a];
  end


endmodule