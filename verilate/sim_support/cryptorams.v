module sce_aesram_1k (q, clk, cen, wen, a, d, ema, emaw, emas, ret1n, wabl, wablm,
    rawl, rawlm);

  output reg [35:0] q;
  input  clk;
  input  cen;
  input  wen;
  input [7:0] a;
  input [35:0] d;
  input [2:0] ema;
  input [1:0] emaw;
  input  emas;
  input  ret1n;
  input  wabl;
  input [1:0] wablm;
  input  rawl;
  input [1:0] rawlm;

  parameter RAM_DATA_WIDTH = 36;
  parameter RAM_ADDR_WIDTH = 8;
  parameter WORD_SIZE = 1;
  parameter WORD_WIDTH = 36;

  reg [RAM_DATA_WIDTH-1:0] mem[(2**RAM_ADDR_WIDTH)-1:0];

  integer i, j, k;
`ifdef SIM
  initial begin
      for (i = 0; i < 2**RAM_ADDR_WIDTH; i = i + 2**(RAM_ADDR_WIDTH/2)) begin
          for (j = i; j < i + 2**(RAM_ADDR_WIDTH/2); j = j + 1) begin
              mem[j] = 'X;
          end
      end
  end
`endif

always @(posedge clk) begin
    if (!cen) begin
        q <= mem[a];
        for (i = 0; i < WORD_WIDTH; i = i + 1) begin: writes
            if (!((wen[i]))) begin
                mem[a][WORD_SIZE*i +: WORD_SIZE] <= d[WORD_SIZE*i +: WORD_SIZE];
            end
        end
    end else begin
        q <= q;
    end
end
endmodule

module sce_pkeram_4k (q, clk, cen, wen, a, d, ema, emaw, emas, gwen, ret1n, wabl, wablm,
    rawl, rawlm);

  output reg [71:0] q;
  input  clk;
  input  cen;
  input [71:0] wen;
  input [8:0] a;
  input [71:0] d;
  input [2:0] ema;
  input [1:0] emaw;
  input  emas;
  input  gwen;
  input  ret1n;
  input  wabl;
  input [1:0] wablm;
  input  rawl;
  input [1:0] rawlm;

  parameter RAM_DATA_WIDTH = 72;
  parameter RAM_ADDR_WIDTH = 9;
  parameter WORD_SIZE = 1;
  parameter WORD_WIDTH = 72;

  reg [RAM_DATA_WIDTH-1:0] mem[(2**RAM_ADDR_WIDTH)-1:0];

  integer i, j, k;
`ifdef SIM
  initial begin
      for (i = 0; i < 2**RAM_ADDR_WIDTH; i = i + 2**(RAM_ADDR_WIDTH/2)) begin
          for (j = i; j < i + 2**(RAM_ADDR_WIDTH/2); j = j + 1) begin
              mem[j] = 'X;
          end
      end
  end
`endif

always @(posedge clk) begin
    if (!cen) begin
        q <= mem[a];
        for (i = 0; i < WORD_WIDTH; i = i + 1) begin: writes
            if (!(gwen | (wen[i]))) begin
                mem[a][WORD_SIZE*i +: WORD_SIZE] <= d[WORD_SIZE*i +: WORD_SIZE];
            end
        end
    end else begin
        q <= q;
    end
end
endmodule

module sce_hashram_3k (q, clk, cen, wen, a, d, ema, emaw, emas, ret1n, wabl, wablm,
    rawl, rawlm);

  output reg [35:0] q;
  input  clk;
  input  cen;
  input  wen;
  input [9:0] a;
  input [35:0] d;
  input [2:0] ema;
  input [1:0] emaw;
  input  emas;
  input  ret1n;
  input  wabl;
  input [1:0] wablm;
  input  rawl;
  input [1:0] rawlm;

  parameter RAM_DATA_WIDTH = 36;
  parameter RAM_ADDR_WIDTH = 10;
  parameter WORD_SIZE = 1;
  parameter WORD_WIDTH = 36;

  reg [RAM_DATA_WIDTH-1:0] mem[(2**RAM_ADDR_WIDTH)-1:0];

  integer i, j, k;
`ifdef SIM
  initial begin
      for (i = 0; i < 2**RAM_ADDR_WIDTH; i = i + 2**(RAM_ADDR_WIDTH/2)) begin
          for (j = i; j < i + 2**(RAM_ADDR_WIDTH/2); j = j + 1) begin
              mem[j] = 'X;
          end
      end
  end
`endif

always @(posedge clk) begin
    if (!cen) begin
        q <= mem[a];
        for (i = 0; i < WORD_WIDTH; i = i + 1) begin: writes
            if (!((wen))) begin
                mem[a][WORD_SIZE*i +: WORD_SIZE] <= d[WORD_SIZE*i +: WORD_SIZE];
            end
        end
    end else begin
        q <= q;
    end
end
endmodule

module sce_aluram_3k (q, clk, cen, wen, a, d, ema, emaw, emas, gwen, ret1n, wabl, wablm,
    rawl, rawlm);

  output reg [35:0] q;
  input  clk;
  input  cen;
  input [35:0] wen;
  input [9:0] a;
  input [35:0] d;
  input [2:0] ema;
  input [1:0] emaw;
  input  emas;
  input  gwen;
  input  ret1n;
  input  wabl;
  input [1:0] wablm;
  input  rawl;
  input [1:0] rawlm;

  parameter RAM_DATA_WIDTH = 36;
  parameter RAM_ADDR_WIDTH = 10;
  parameter WORD_SIZE = 1;
  parameter WORD_WIDTH = 36;

  reg [RAM_DATA_WIDTH-1:0] mem[(2**RAM_ADDR_WIDTH)-1:0];

  integer i, j, k;
`ifdef SIM
  initial begin
      for (i = 0; i < 2**RAM_ADDR_WIDTH; i = i + 2**(RAM_ADDR_WIDTH/2)) begin
          for (j = i; j < i + 2**(RAM_ADDR_WIDTH/2); j = j + 1) begin
              mem[j] = 'X;
          end
      end
  end
`endif

always @(posedge clk) begin
    if (!cen) begin
        q <= mem[a];
        for (i = 0; i < WORD_WIDTH; i = i + 1) begin: writes
            if (!(gwen | (wen[i]))) begin
                mem[a][WORD_SIZE*i +: WORD_SIZE] <= d[WORD_SIZE*i +: WORD_SIZE];
            end
        end
    end else begin
        q <= q;
    end
end
endmodule

module sce_sceram_10k (q, clk, cen, a, d, ema, emaw, emas, gwen, ret1n, wabl, wablm,
    rawl, rawlm, stov);

  output reg [35:0] q;
  input  clk;
  input  cen;
  input [11:0] a;
  input [35:0] d;
  input [2:0] ema;
  input [1:0] emaw;
  input  emas;
  input  gwen;
  input  ret1n;
  input  wabl;
  input [1:0] wablm;
  input  rawl;
  input [1:0] rawlm;
  input stov;

  parameter RAM_DATA_WIDTH = 36;
  parameter RAM_ADDR_WIDTH = 12;
  parameter WORD_SIZE = 1;
  parameter WORD_WIDTH = 36;

  reg [RAM_DATA_WIDTH-1:0] mem[(2**RAM_ADDR_WIDTH)-1:0];

  integer i, j, k;
`ifdef SIM
  initial begin
      for (i = 0; i < 2**RAM_ADDR_WIDTH; i = i + 2**(RAM_ADDR_WIDTH/2)) begin
          for (j = i; j < i + 2**(RAM_ADDR_WIDTH/2); j = j + 1) begin
              mem[j] = 'X;
          end
      end
  end
`endif

always @(posedge clk) begin
    if (!cen) begin
        q <= mem[a];
        for (i = 0; i < WORD_WIDTH; i = i + 1) begin: writes
            if (!(gwen)) begin
                mem[a][WORD_SIZE*i +: WORD_SIZE] <= d[WORD_SIZE*i +: WORD_SIZE];
            end
        end
    end else begin
        q <= q;
    end
end
endmodule