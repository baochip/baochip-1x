// (c) Copyright 2024 CrossBar, Inc.
//
// SPDX-FileCopyrightText: 2024 CrossBar, Inc.
// SPDX-License-Identifier: SHL-0.51
//
// This file has been modified by CrossBar, Inc.

// Copyright 2015-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`define RGB565        3'b000
`define RGB555        3'b001
`define RGB444        3'b010
`define BYPASS_LITEND 3'b100
`define BYPASS_BIGEND 3'b101

module camera_if
   #(
        parameter L2_AWIDTH_NOAL = 12,
        parameter TRANS_SIZE     = 16,
        parameter DATA_WIDTH     = 12,
        parameter BUFFER_WIDTH   = 8
    )
    (
        input logic                       clk_i,
        input logic                       rstn_i,

        input  logic                       dft_test_mode_i,
        input  logic                       dft_cg_enable_i,

        input  logic               [31:0] cfg_data_i,
        input  logic                [4:0] cfg_addr_i,
        input  logic                      cfg_valid_i,
        input  logic                      cfg_rwn_i,
        output logic               [31:0] cfg_data_o,
        output logic                      cfg_ready_o,

        output logic [L2_AWIDTH_NOAL-1:0] cfg_rx_startaddr_o,
        output logic     [TRANS_SIZE-1:0] cfg_rx_size_o,
        output logic                      cfg_rx_continuous_o,
        output logic                      cfg_rx_en_o,
        output logic                      cfg_rx_clr_o,
        input  logic                      cfg_rx_en_i,
        input  logic                      cfg_rx_pending_i,
        input  logic [L2_AWIDTH_NOAL-1:0] cfg_rx_curr_addr_i,
        input  logic     [TRANS_SIZE-1:0] cfg_rx_bytes_left_i,

        output logic                [1:0] data_rx_datasize_o,
        output logic               [15:0] data_rx_data_o,
        output logic                      data_rx_valid_o,
        input  logic                      data_rx_ready_i,

        input  logic                      cam_clk_i,
        input  logic     [DATA_WIDTH-1:0] cam_data_i,
        input  logic                      cam_hsync_i,
        input  logic                      cam_vsync_i
    );

    logic [15:0] r_rowcounter;
    logic [15:0] r_colcounter;

    logic  [5:0] r_framecounter;

    logic        r_sample_msb;
    logic  [7:0] r_data_msb;    // First received byte

    logic        s_pixel_valid;
    logic        r_vsync;
    logic        r_enable;
    logic [1:0]  r_en_sync;

    logic [15:0] udma_tx_data;
    logic        udma_tx_valid;
    logic        udma_tx_valid_flush;
    logic        udma_tx_ready;

    logic [15:0] s_cfg_rowlen;

    logic   [7:0] s_cfg_r_coeff;
    logic   [7:0] s_cfg_g_coeff;
    logic   [7:0] s_cfg_b_coeff;

    logic   [7:0] s_r_pix;
    logic   [7:0] s_g_pix;
    logic   [7:0] s_b_pix;
    logic   [15:0] s_yuv_pix;
    logic   [15:0] r_yuv_pix;
    logic   r_yuv_data_valid;

    logic   [7:0] r_r_pix;
    logic   [7:0] r_g_pix;
    logic   [7:0] r_b_pix;

    logic  [15:0] s_r_filt;
    logic  [15:0] s_g_filt;
    logic  [15:0] s_b_filt;

    logic [15:0] s_data_filter_shift;
    logic [16:0] s_data_filter;
    logic [16:0] r_data_filter;
    logic        r_data_filter_valid;

    logic        r_tx_valid;

    logic        s_cam_vsync;
    logic        s_cam_vsync_polarity;
    logic        s_cam_hsync;
    logic        s_cam_hsync_polarity;

    logic [31:0] s_cfg_glob;
    logic [31:0] s_cfg_ll;
    logic [31:0] s_cfg_ur;
    logic [31:0] s_cfg_filter;
    logic [31:0] s_cfg_size;


    logic        s_cfg_framedrop_en;
    logic  [5:0] s_cfg_framedrop_val;
    logic        s_cfg_frameslice_en;
    logic  [2:0] s_cfg_format;
    logic  [3:0] s_cfg_shift;
    logic        s_cfg_sof_sync; // enable SOF snapping

    logic        s_cam_clk_dft;

    logic         s_cfg_en;
    logic  [15:0] s_cfg_frameslice_llx;
    logic  [15:0] s_cfg_frameslice_lly;
    logic  [15:0] s_cfg_frameslice_urx;
    logic  [15:0] s_cfg_frameslice_ury;
    logic         s_sof;
    logic         s_framevalid;
    logic         s_tx_valid;
    logic         s_data_rx_ready;

    logic         cfg_rx_en_state;
    logic         cfg_rx_en_reg_if; // the cfg_rx_en_o from the reg if
    logic         [3:0] cfg_vsync; // bring vsync into the cfg domain and rising edge detect
    logic         cfg_sof;
    logic         cfg_rx_en_d;

    //assign s_r_filt = r_r_pix * s_cfg_r_coeff;
    //assign s_g_filt = r_g_pix * s_cfg_g_coeff;
    //assign s_b_filt = r_b_pix * s_cfg_b_coeff;

    generic_mult8x8 gen_mult_r (.in_a (r_r_pix), .in_b (s_cfg_r_coeff), .out_y(s_r_filt));
    generic_mult8x8 gen_mult_g (.in_a (r_g_pix), .in_b (s_cfg_g_coeff), .out_y(s_g_filt));
    generic_mult8x8 gen_mult_b (.in_a (r_b_pix), .in_b (s_cfg_b_coeff), .out_y(s_b_filt));


    assign s_data_filter = s_r_filt + s_g_filt + s_b_filt;

    assign s_cfg_framedrop_en  = s_cfg_glob[0];
    assign s_cfg_framedrop_val = s_cfg_glob[6:1];
    assign s_cfg_frameslice_en = s_cfg_glob[7];
    assign s_cfg_format        = s_cfg_glob[10:8];
    assign s_cfg_shift         = s_cfg_glob[14:11];
    assign s_cfg_sof_sync      = s_cfg_glob[30];
    assign s_cfg_en            = s_cfg_glob[31];

    assign s_cfg_rowlen = s_cfg_size[31:16];

    assign s_cfg_frameslice_llx = s_cfg_ll[15:0];
    assign s_cfg_frameslice_lly = s_cfg_ll[31:16];
    assign s_cfg_frameslice_urx = s_cfg_ur[15:0];
    assign s_cfg_frameslice_ury = s_cfg_ur[31:16];

    assign s_cfg_r_coeff        = s_cfg_filter[23:16];
    assign s_cfg_g_coeff        = s_cfg_filter[15:8];
    assign s_cfg_b_coeff        = s_cfg_filter[7:0];

    assign s_cam_vsync = s_cam_vsync_polarity ? ~cam_vsync_i : cam_vsync_i;
    assign s_cam_hsync = s_cam_hsync_polarity ? ~cam_hsync_i : cam_hsync_i;
    assign s_sof = ~r_vsync &  s_cam_vsync;

    assign s_framevalid = (r_framecounter == 0);

    assign s_tx_valid = s_cam_hsync & s_pixel_valid & ~r_sample_msb;

    assign cfg_sof = ~cfg_vsync[2] & cfg_vsync[1];
    assign cfg_rx_en_o = s_cfg_sof_sync ? cfg_rx_en_state & cfg_sof : cfg_rx_en_reg_if;
    always_ff @(posedge clk_i or negedge rstn_i) begin : sof_fix
        if (~rstn_i) begin
            cfg_rx_en_state <= 0;
            cfg_rx_en_d <= 0;
            cfg_vsync <= 0;
        end else begin
            cfg_rx_en_d <= cfg_rx_en_i;
            cfg_vsync <= {cfg_vsync[1:0], s_cam_vsync};
            if (~cfg_rx_en_i & cfg_rx_en_d) begin
                cfg_rx_en_state <= 0;
            end else begin
                if (cfg_rx_en_reg_if) begin
                    cfg_rx_en_state <= 1;
                end
            end
        end
    end

    camera_reg_if #(
        .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
        .TRANS_SIZE(TRANS_SIZE)
    ) u_reg_if (
        .clk_i              ( clk_i               ),
        .rstn_i             ( rstn_i              ),

        .cfg_data_i         ( cfg_data_i          ),
        .cfg_addr_i         ( cfg_addr_i          ),
        .cfg_valid_i        ( cfg_valid_i         ),
        .cfg_rwn_i          ( cfg_rwn_i           ),
        .cfg_ready_o        ( cfg_ready_o         ),
        .cfg_data_o         ( cfg_data_o          ),

        .cfg_rx_startaddr_o ( cfg_rx_startaddr_o  ),
        .cfg_rx_size_o      ( cfg_rx_size_o       ),
        .cfg_rx_datasize_o  ( data_rx_datasize_o  ),
        .cfg_rx_continuous_o( cfg_rx_continuous_o ),
        .cfg_rx_en_o        ( cfg_rx_en_reg_if    ),
        .cfg_rx_clr_o       ( cfg_rx_clr_o        ),
        .cfg_rx_en_i        ( cfg_rx_en_i         ),
        .cfg_rx_pending_i   ( cfg_rx_pending_i    ),
        .cfg_rx_running_i   ('0),
        .cfg_rx_curr_addr_i ( cfg_rx_curr_addr_i  ),
        .cfg_rx_bytes_left_i( cfg_rx_bytes_left_i ),

        .cfg_cam_ip_en_i     ( cfg_rx_en_state    ),
        .cfg_cam_vsync_polarity_o ( s_cam_vsync_polarity   ),
        .cfg_cam_hsync_polarity_o ( s_cam_hsync_polarity   ),
        .cfg_cam_cfg_o       ( s_cfg_glob   ),
        .cfg_cam_cfg_ll_o    ( s_cfg_ll     ),
        .cfg_cam_cfg_ur_o    ( s_cfg_ur     ),
        .cfg_cam_cfg_size_o  ( s_cfg_size   ),
        .cfg_cam_cfg_filter_o( s_cfg_filter )
    );

`ifndef PULP_FPGA_EMUL
 `ifdef PULP_DFT
    pulp_clock_mux2 i_test_mux_dft
    (
        .clk_o(s_cam_clk_dft),
        .clk0_i(cam_clk_i),
        .clk1_i(clk_i),
        .clk_sel_i(dft_test_mode_i)
    );
 `else
   assign s_cam_clk_dft = cam_clk_i;
 `endif
`else
  assign s_cam_clk_dft = cam_clk_i;
`endif

    assign s_data_rx_ready     = (s_cfg_en==1'b0) ? 1'b1 : data_rx_ready_i;
    assign udma_tx_valid_flush = (s_cfg_en==1'b0) ? 1'b0 : udma_tx_valid;

    udma_dc_fifo #(16,BUFFER_WIDTH) u_dc_fifo
    (
        .dst_clk_i          ( clk_i           ),
        .dst_rstn_i         ( rstn_i          ), //this is not sync with the clock but the external clock is down during system reset
        .dst_data_o         ( data_rx_data_o  ),
        .dst_valid_o        ( data_rx_valid_o ),
        .dst_ready_i        ( s_data_rx_ready ),
        .src_clk_i          ( s_cam_clk_dft   ),
        .src_rstn_i         ( rstn_i          ),
        .src_data_i         ( udma_tx_data    ),
        .src_valid_i        ( udma_tx_valid_flush   ),
        .src_ready_o        ( udma_tx_ready   )
    );

    always_comb begin : proc_format
        s_r_pix = 'h0;
        s_g_pix = 'h0;
        s_b_pix = 'h0;
        s_yuv_pix = 'h0;
        case(s_cfg_format)
            `RGB565:
            begin
                s_r_pix = {r_data_msb[7:3],3'b000};
                s_g_pix = {r_data_msb[2:0],cam_data_i[7:5],2'b00};
                s_b_pix = {cam_data_i[4:0],3'b000};
            end
            `RGB555:
            begin
                s_r_pix = {r_data_msb[6:2],3'b000};
                s_g_pix = {r_data_msb[1:0],cam_data_i[7:5],3'b000};
                s_b_pix = {cam_data_i[4:0],3'b000};
            end
            `RGB444:
            begin
                s_r_pix = {r_data_msb[3:0],4'b0000};
                s_g_pix = {cam_data_i[7:4],4'b0000};
                s_b_pix = {cam_data_i[3:0],4'b0000};
            end
            `BYPASS_LITEND:
                s_yuv_pix = {r_data_msb[7:0], cam_data_i[7:0]};
            `BYPASS_BIGEND:
                s_yuv_pix = {cam_data_i[7:0], r_data_msb[7:0]};
        endcase // r_format
    end

    always_comb begin : proc_sfilter_shift
        case(s_cfg_shift)
            0:
                s_data_filter_shift=r_data_filter[15:0];
            1:
                s_data_filter_shift=r_data_filter[16:1];
            2:
                s_data_filter_shift={1'h0,r_data_filter[16:2]};
            3:
                s_data_filter_shift={2'h0,r_data_filter[16:3]};
            4:
                s_data_filter_shift={3'h0,r_data_filter[16:4]};
            5:
                s_data_filter_shift={4'h0,r_data_filter[16:5]};
            6:
                s_data_filter_shift={5'h0,r_data_filter[16:6]};
            7:
                s_data_filter_shift={6'h0,r_data_filter[16:7]};
            8:
                s_data_filter_shift={7'h0,r_data_filter[16:8]};
            9:
                s_data_filter_shift={8'h0,r_data_filter[16:9]};
            default:
                s_data_filter_shift=r_data_filter[15:0];
        endcase // s_cfg_format
    end

    always_ff @(posedge s_cam_clk_dft or negedge rstn_i) begin : proc_pix
        if(~rstn_i) begin
            r_r_pix <= 0;
            r_g_pix <= 0;
            r_b_pix <= 0;
            r_yuv_pix <= 0;
            r_tx_valid <= 1'b0;
            udma_tx_data <= 'h0;
            r_yuv_data_valid <= 1'b0;
            udma_tx_valid <= 1'b0;
            r_data_filter <=  'h0;
            r_data_filter_valid <= 1'b0;
        end else begin
            if (s_tx_valid) begin
               if (s_cfg_format[2] != 1'b1) begin // not `BYPASS_LITEND or `BYPASS_BIGEND
                    r_r_pix <= s_r_pix;
                    r_g_pix <= s_g_pix;
                    r_b_pix <= s_b_pix;
                    r_tx_valid <= 1'b1;
               end
               else begin
                   r_yuv_pix <= s_yuv_pix;
                   r_yuv_data_valid <= 1'b1;
               end
            end
            else begin
               r_tx_valid <= 1'b0;
               r_yuv_data_valid <= 1'b0;
             end

            if (r_tx_valid)
            begin
                r_data_filter       <= s_data_filter;
                r_data_filter_valid <= 1'b1;
            end
            else
                r_data_filter_valid <= 1'b0;

            if(r_data_filter_valid || r_yuv_data_valid)
            begin
                udma_tx_data  <= r_data_filter_valid ? s_data_filter_shift: r_yuv_pix;
                udma_tx_valid <= 1'b1;
            end
            else
                udma_tx_valid <= 1'b0;
        end
    end


    always_comb begin : proc_sampledata
        if(s_framevalid && r_enable)
        begin
            if(s_cfg_frameslice_en)
            begin
                if( (r_rowcounter >= s_cfg_frameslice_lly) &&
                    (r_rowcounter <= s_cfg_frameslice_ury) &&
                    (r_colcounter >= s_cfg_frameslice_llx) &&
                    (r_colcounter <= s_cfg_frameslice_urx) )
                    s_pixel_valid = 1'b1;
                else
                    s_pixel_valid = 1'b0;
            end
            else
                    s_pixel_valid = 1'b1;
        end
        else
            s_pixel_valid = 1'b0;
    end

    always_ff @(posedge s_cam_clk_dft or negedge rstn_i) begin : proc_vsync
        if(~rstn_i) begin
            r_vsync     <= 0;
        end else begin
            if(r_en_sync[1])
                r_vsync     <= s_cam_vsync;
        end
    end

    always_ff @(posedge s_cam_clk_dft or negedge rstn_i) begin : proc_en_sync
        if(~rstn_i) begin
            r_en_sync     <= 0;
        end else begin
            r_en_sync     <= {r_en_sync[0],s_cfg_en};
        end
    end

    always_ff @(posedge s_cam_clk_dft or negedge rstn_i) begin : proc_sample_lsb
        if(~rstn_i) begin
            r_sample_msb <= 1'b1;
        end
        else if(~r_enable | ~s_cam_hsync) begin
            r_sample_msb <= 1'b1;
        end
        else if(s_cam_hsync & r_enable) begin
            r_sample_msb <= ~r_sample_msb;
        end
    end

    always_ff @(posedge s_cam_clk_dft or negedge rstn_i) begin : proc_data
        if(~rstn_i) begin
            r_data_msb   <=  'h0;
            r_rowcounter <=  'h0;
            r_colcounter <=  'h0;
            r_enable     <= 1'b0;
        end else begin
            if(s_sof)
            begin
                r_rowcounter <= 'h0;
                r_colcounter <=  'h0;
                r_enable     <= r_en_sync[1]; //enable the IP only when SOF
            end
            else if (~s_sof & ~r_en_sync[1])
            begin
                r_rowcounter <= 'h0;
                r_colcounter <= 'h0;
                r_enable     <= r_en_sync[1]; //disable the IP when not SOF
              end
            else if(s_cam_hsync & r_enable)
            begin
                if(r_sample_msb)
                    r_data_msb <= cam_data_i;
                if (!r_sample_msb  && s_cfg_frameslice_en)
                begin
                    if(r_colcounter == s_cfg_rowlen)
                    begin
                        r_colcounter <= 'h0;
                        r_rowcounter <= r_rowcounter + 1;
                    end
                    else
                        r_colcounter <= r_colcounter + 1;
                end
            end
        end
    end

    always_ff @(posedge s_cam_clk_dft or negedge rstn_i) begin : proc_framecount
        if(~rstn_i) begin
            r_framecounter <= 'h0;
        end else begin
            if(s_sof && r_enable)
            begin
                if(s_cfg_framedrop_en)
                begin
                    if(r_framecounter == s_cfg_framedrop_val)
                        r_framecounter <= 'h0;
                    else
                        r_framecounter <= r_framecounter + 1;
                end
                else
                    r_framecounter <= 'h0;
            end
        end
    end

endmodule // camera_if
