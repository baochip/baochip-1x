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



module udma_adc_ts_top #(
  parameter L2_AWIDTH_NOAL  = 12,
  parameter TRANS_SIZE      = 16,
  parameter UDMA_TRANS_SIZE = TRANS_SIZE,
  parameter TS_DATA_WIDTH   = 28,
  parameter TS_ID_LSB       = 28,
  parameter TS_NUM_CHS      = 8   )
(
  input  logic                       sys_clk_i,
  input  logic                       ts_clk_i,
  input  logic                       rstn_i,

  input  logic                [31:0] cfg_data_i,
  input  logic                 [4:0] cfg_addr_i,
  input  logic                       cfg_valid_i,
  input  logic                       cfg_rwn_i,
  output logic                [31:0] cfg_data_o,
  output logic                       cfg_ready_o,

  output logic  [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
  output logic [UDMA_TRANS_SIZE-1:0] cfg_rx_size_o,
  output logic                       cfg_rx_continuous_o,
  output logic                       cfg_rx_en_o,
  output logic                       cfg_rx_clr_o,
  input  logic                       cfg_rx_en_i,
  input  logic                       cfg_rx_pending_i,
  input  logic  [L2_AWIDTH_NOAL-1:0] cfg_rx_curr_addr_i,
  input  logic [UDMA_TRANS_SIZE-1:0] cfg_rx_bytes_left_i,

  output logic                 [1:0] data_rx_datasize_o,
  output logic                [31:0] data_rx_o,
  output logic                       data_rx_valid_o,
  input  logic                       data_rx_ready_i,

  // Timestamp signals
//  input  logic      [TS_NUM_CHS-1:0] ts_valid_async_i,
//  input  logic   [TS_DATA_WIDTH-1:0] ts_data_i,

    input logic dft_test_mode_i,
    input wire [3:0] ana_adcsrc//,
//    input logic clkbg

);
    logic clkbg;

  logic t_tsclk           ;
  logic t_cr_rstn         ;
  logic t_cr_adcen        ;
  logic t_clkbg          ;
  logic t_cr_bgen         ;
  logic t_tsadc_sample    ;
  logic [1:0] t_cr_tsadc_sel    ;
  logic [7:0] t_cr_tsadc_ana_reg;
  logic [4:0] t_cr_data_count;
  localparam TS_ID_WIDTH = $clog2(TS_NUM_CHS);

  logic [2:0][TS_NUM_CHS-1:0] ts_data_valid_sync;
  logic      [TS_NUM_CHS-1:0] ts_vld_edge;
  logic   [TS_DATA_WIDTH-1:0] ts_data_sync;

  logic [2:0][TS_NUM_CHS-1:0] sys_data_valid_sync;
  logic      [TS_NUM_CHS-1:0] sys_vld_edge;
  logic                       sys_udma_valid_SP, sys_udma_valid_SN;
  logic                [31:0] sys_data_sync;
  logic                [31:0] sys_merged_data;
  logic     [TS_ID_WIDTH-1:0] sys_id_bin;
    logic [1:0] cr_adcmux_sel, cr_tsadc_sel;
    logic [7:0] cr_clkfd, cr_tsadc_ana_reg;
    logic cr_rstn, cr_adcen, cr_bgen;
    logic [4:0] cr_data_count, tsdpcnt;
    logic [29:0] cr_adc;
    logic [7:0] tsclkcnt;
    logic tsclkreg, tsclk_unbuf, tsclk;
    logic [2:0] tssample_enregs;
    logic tssample_en;
    logic tsadc_sample;
    logic tsadc_data_valid, t_tsadc_data_valid;
    logic [9:0] tsadc_dout, t_tsadc_dout;
    logic tsdp;
    logic   [TS_NUM_CHS-1:0] ts_valid_async_i;
    logic   [TS_DATA_WIDTH-1:0] ts_data_i;

  assign data_rx_valid_o = sys_udma_valid_SP;
  assign data_rx_o       = tsadc_dout | '0;//sys_data_sync;


  // sync & edge detect of individual sync channels - ts clock side
  always_ff @(posedge ts_clk_i, negedge rstn_i) begin
    if ( rstn_i == 1'b0 ) begin
      ts_data_valid_sync    <= '0;
      ts_data_sync          <= '0;
    end
    else begin
      ts_data_valid_sync[0] <= ts_valid_async_i;
      ts_data_valid_sync[1] <= ts_data_valid_sync[0];
      ts_data_valid_sync[2] <= ts_data_valid_sync[1];

      if (|ts_vld_edge) ts_data_sync <= ts_data_i;

    end
  end

  // sync & edge detect of individual sync channels - sys clock side
  always_ff @(posedge sys_clk_i, negedge rstn_i) begin
    if ( rstn_i == 1'b0 ) begin
      sys_data_valid_sync    <= '0;
      sys_udma_valid_SP      <= '0;
      sys_data_sync          <= '0;
    end
    else begin
      sys_data_valid_sync[0] <= ts_data_valid_sync[2]; // handover between clock domains here
      sys_data_valid_sync[1] <= sys_data_valid_sync[0];
      sys_data_valid_sync[2] <= sys_data_valid_sync[1];
      sys_udma_valid_SP      <= cfg_rx_en_i ? sys_udma_valid_SN : '0;

      if (|sys_vld_edge) sys_data_sync <= sys_merged_data;

    end
  end

  onehot_to_bin #(
    .ONEHOT_WIDTH (TS_NUM_CHS)
  ) onehot_to_bin_ch_id_i
  (
    .onehot ( sys_vld_edge ),
    .bin    ( sys_id_bin )
  );

  assign ts_vld_edge  = (ts_data_valid_sync[1]  & ~ts_data_valid_sync[2]);//  | (~ts_data_valid_sync[1]  & ts_data_valid_sync[2]);
  assign sys_vld_edge = (sys_data_valid_sync[1] & ~sys_data_valid_sync[2]);// | (~sys_data_valid_sync[1] & sys_data_valid_sync[2]);

  always_comb begin
    sys_merged_data = '0;
    sys_merged_data[TS_DATA_WIDTH-1:0]                 = '0;//ts_data_sync; // handover between clock domains here
    sys_merged_data[TS_ID_LSB+TS_ID_WIDTH-1:TS_ID_LSB] = sys_id_bin;
  end


  always_comb begin
    sys_udma_valid_SN = sys_udma_valid_SP;
    if (|sys_vld_edge)
      sys_udma_valid_SN = 1'b1;
    else if (data_rx_ready_i)
      sys_udma_valid_SN = 1'b0;
  end


  udma_adc_ts_reg_if #(
    .L2_AWIDTH_NOAL  ( L2_AWIDTH_NOAL  ),
    .UDMA_TRANS_SIZE ( UDMA_TRANS_SIZE ),
    .TRANS_SIZE      ( TRANS_SIZE      ),
    .CRW             ( 30      )
  ) udma_adc_ts_reg_if_i
  (
    .clk_i               ( sys_clk_i            ),
    .rstn_i              ( rstn_i               ),

    .cfg_data_i          ( cfg_data_i           ),
    .cfg_addr_i          ( cfg_addr_i           ),
    .cfg_valid_i         ( cfg_valid_i          ),
    .cfg_rwn_i           ( cfg_rwn_i            ),
    .cfg_data_o          ( cfg_data_o           ),
    .cfg_ready_o         ( cfg_ready_o          ),

    .cr_adc              ( cr_adc ),
    .cfg_rx_startaddr_o  ( cfg_rx_startaddr_o   ),
    .cfg_rx_size_o       ( cfg_rx_size_o        ),
    .cfg_rx_datasize_o   ( data_rx_datasize_o   ),
    .cfg_rx_continuous_o ( cfg_rx_continuous_o  ),
    .cfg_rx_en_o         ( cfg_rx_en_o          ),
    .cfg_rx_clr_o        ( cfg_rx_clr_o         ),
    .cfg_rx_en_i         ( cfg_rx_en_i          ),
    .cfg_rx_pending_i    ( cfg_rx_pending_i     ),
    .cfg_rx_curr_addr_i  ( cfg_rx_curr_addr_i   ),
    .cfg_rx_bytes_left_i ( cfg_rx_bytes_left_i  )
  );

    logic [1:0] cr_tsen_clksel;

    assign {cr_tsen_clksel[1:0],
    cr_adcmux_sel[1:0], cr_tsadc_sel[1:0],
    cr_clkfd[7:0],
    cr_rstn, cr_adcen, cr_bgen, cr_data_count[4:0],
    cr_tsadc_ana_reg[7:0] } = cr_adc[29:0];


    `theregfull( ts_clk_i, rstn_i, tsclkcnt, 'h1 ) <= ( tsclkcnt == cr_clkfd ) ? '0 : tsclkcnt + 1 ;
    `theregfull( ts_clk_i, rstn_i, tsclkreg, '0 ) <= ( tsclkcnt == cr_clkfd ) ? ~tsclkreg : tsclkreg;

    assign tsclk_unbuf = dft_test_mode_i ? sys_clk_i : tsclkreg;
    CLKCELL_BUF buf_tsclk(.A(tsclk_unbuf),.Z(tsclk));


    `theregfull( tsclk, rstn_i, tssample_enregs, '0 ) <= { tssample_enregs, cfg_rx_en_i };
    assign tssample_en = tssample_enregs[2];

    `theregfull( tsclk, rstn_i, tsdp, '0 ) <= ~tssample_en ? '0 : ( tsadc_sample ? '1 : tsadc_data_valid ? '0 : tsdp );
    assign tsadc_sample = ~tssample_en ? '0 : ( tsdp ? ( tsdpcnt == cr_data_count )  : '1 );
    assign ts_valid_async_i = tsadc_data_valid;
    assign ts_data_i = tsadc_dout | '0;
    `theregfull( tsclk, rstn_i, tsdpcnt, '0 ) <= ~tssample_en ? '0 : ( tsadc_sample ? '0 : tsdpcnt + 1 );

    wire ana_adcdi;

    logic [4:0] tsenclk_undft,tsenclk;
    assign clkbg = (cr_tsen_clksel == 0) ? tsenclk[1]:
                   (cr_tsen_clksel == 1) ? tsenclk[2]:
                   (cr_tsen_clksel == 2) ? tsenclk[3]: tsenclk[4];

    `theregfull( ts_clk_i,   rstn_i, tsenclk_undft[0], '0 ) <= ~tsenclk_undft[0] ; assign tsenclk[0] = dft_test_mode_i ? ts_clk_i : tsenclk_undft[0]; // fd 2
    `theregfull( tsenclk[0], rstn_i, tsenclk_undft[1], '0 ) <= ~tsenclk_undft[1] ; assign tsenclk[1] = dft_test_mode_i ? ts_clk_i : tsenclk_undft[1]; // fd 4
    `theregfull( tsenclk[1], rstn_i, tsenclk_undft[2], '0 ) <= ~tsenclk_undft[2] ; assign tsenclk[2] = dft_test_mode_i ? ts_clk_i : tsenclk_undft[2]; // fd 8
    `theregfull( tsenclk[2], rstn_i, tsenclk_undft[3], '0 ) <= ~tsenclk_undft[3] ; assign tsenclk[3] = dft_test_mode_i ? ts_clk_i : tsenclk_undft[3]; // fd 16
    `theregfull( tsenclk[3], rstn_i, tsenclk_undft[4], '0 ) <= ~tsenclk_undft[4] ; assign tsenclk[4] = dft_test_mode_i ? ts_clk_i : tsenclk_undft[4]; // fd 32

`ifdef FPGA

    logic [4:0] tsadccnt;
    logic [9:0] tsadc_doutfake;
    logic tsadc_validfake;
    `theregfull( tsclk, rstn_i, tsadccnt, '0 ) <= tsadc_sample ? 'h1 :
                                                                (( tsadccnt == cr_data_count ) | ( tsadccnt == '0 ) ? '0 : tsadccnt + 'h1 );

    drng_lfsr #( .LFSR_W(229),.LFSR_NODE({ 10'd228, 10'd225, 10'd219 }), .LFSR_OW(10),.LFSR_IV('h55aa_aa55_5a5a_a5a5) )
        ua( .clk(tsclk), .resetn(rstn_i), .sen('1), .swr('0), .sdin('0), .sdout(tsadc_doutfake) );
    assign tsadc_validfake = ( tsadccnt == cr_data_count );


    assign tsadc_dout = tsadc_doutfake;
    assign tsadc_data_valid = tsadc_validfake;


`else
    inno_tsensor_ip
    adc
    (
`ifndef SYN
        .AVDD               (),
        .AVSS               (),
        .VSSESD             (),
        .VDD                (),
        .VSS                (),
        .VIN                (ana_adcdi),
`endif
        .tsadc_clk          (~t_tsclk),
        .tsadc_rstn         (t_cr_rstn),
        .tsadc_en           (t_cr_adcen),
        .tsadc_tsen_clk     (t_clkbg), // 4MHz ~ 20MHz
        .tsadc_tsen_en      (t_cr_bgen),
        .tsadc_sample       (t_tsadc_sample),
        .tsadc_sel          (t_cr_tsadc_sel[1:0]),
    //     .tsadc_tsen_trim    (tsadc_tsen_trim),
        .tsadc_ana_reg_0    (t_cr_tsadc_ana_reg[0]),
        .tsadc_ana_reg_1    (t_cr_tsadc_ana_reg[1]),
        .tsadc_ana_reg_2    (t_cr_tsadc_ana_reg[2]),
        .tsadc_ana_reg_3    (t_cr_tsadc_ana_reg[3]),
        .tsadc_ana_reg_4    (t_cr_tsadc_ana_reg[4]),
        .tsadc_ana_reg_5    (t_cr_tsadc_ana_reg[5]),
        .tsadc_ana_reg_6    (t_cr_tsadc_ana_reg[6]),
        .tsadc_ana_reg_7    (t_cr_tsadc_ana_reg[7]),
    //     .tsadc_ana_reg_8     (tsadc_ana_reg[8]),
    //     .tsadc_ana_reg_9     (tsadc_ana_reg[9]),
    //     .tsadc_ana_reg_10  (tsadc_ana_reg[10]),
    //     .tsadc_ana_reg_11  (tsadc_ana_reg[11]),
    //     .tsadc_ana_reg_12  (tsadc_ana_reg[12]),
    //     .tsadc_ana_reg_13  (tsadc_ana_reg[13]),
    //     .tsadc_ana_reg_14  (tsadc_ana_reg[14]),
    //     .tsadc_ana_reg_15  (tsadc_ana_reg[15]),
        /// bist
        .bist_mode        ('0),
        .bist_start       ('0),
        .bist_valid       (),
        .bist_error       (),
        .bist_ref_max     (10'h200),
        .bist_ref_min     (10'h100),
        .tsadc_data_count   (t_cr_data_count[4:0]), //14cycle
        .tsadc_data_valid   (t_tsadc_data_valid),
        .tsadc_dout         (t_tsadc_dout),

        .scanmode         (1'b0),
        .scanclk          (1'b0),
        .scanrstn         (1'b1),
        .scanen           (1'b0),
        .scanin           (1'b0),
        .scanout          ()
    );

    mux_4to1 adcmux (
    .VIN (ana_adcsrc[3:0]),
    .MSB (cr_adcmux_sel[1]),
    .LSB (cr_adcmux_sel[0]),
    .VOUT (ana_adcdi)
    );

    assign t_tsclk            = dft_test_mode_i ? '0 : tsclk;
    assign t_cr_rstn          = dft_test_mode_i ? '0 : cr_rstn;
    assign t_cr_adcen         = dft_test_mode_i ? '0 : cr_adcen;
    assign t_clkbg           = dft_test_mode_i ? '0 : clkbg;
    assign t_cr_bgen          = dft_test_mode_i ? '0 : cr_bgen;
    assign t_tsadc_sample     = dft_test_mode_i ? '0 : tsadc_sample;
    assign t_cr_tsadc_sel     = dft_test_mode_i ? '0 : cr_tsadc_sel;
    assign t_cr_tsadc_ana_reg = dft_test_mode_i ? '0 : cr_tsadc_ana_reg;
    assign t_cr_data_count    = dft_test_mode_i ? '0 : cr_data_count;
    assign {tsadc_data_valid, tsadc_dout[9:0]} = dft_test_mode_i ? {cr_tsadc_sel,cr_tsadc_sel[1:0],cr_tsadc_ana_reg[7:0]} : {t_tsadc_data_valid, t_tsadc_dout[9:0]};

`endif


endmodule