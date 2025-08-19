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

module i2s_clkws_gen (
                      input logic        clk_i,
                      input logic        rstn_i,

                      input logic        dft_test_mode_i,
                      input logic        dft_cg_enable_i,

                      input logic        pad_slave_sck_i,
                      output logic       pad_slave_sck_o,
                      output logic       pad_slave_sck_oe,
                      input logic        pad_slave_ws_i,
                      output logic       pad_slave_ws_o,
                      output logic       pad_slave_ws_oe,
                      input logic        pad_master_sck_i,
                      output logic       pad_master_sck_o,
                      output logic       pad_master_sck_oe,
                      input logic        pad_master_ws_i,
                      output logic       pad_master_ws_o,
                      output logic       pad_master_ws_oe,

                      input logic        master_en_i,
                      input logic        slave_en_i,
                      input logic        pdm_en_i,

                      input logic        pdm_clk_i,

                      input logic [15:0] cfg_div_0_i,
                      input logic [15:0] cfg_div_1_i,

                      input logic [4:0]  cfg_word_size_0_i,
                      input logic [2:0]  cfg_word_num_0_i,
                      input logic [4:0]  cfg_word_size_1_i,
                      input logic [2:0]  cfg_word_num_1_i,

                      input logic        sel_master_num_i,
                      input logic        sel_master_ext_i,
                      input logic        sel_slave_num_i,
                      input logic        sel_slave_ext_i,

                      output logic       clk_master_o,
                      output logic       clk_slave_o,
                      output logic       ws_master_o,
                      output logic       ws_slave_o

                      );

   logic                   s_clk_gen_0;
   logic                   s_clk_gen_1;

   logic                   s_clk_gen_0_en;
   logic                   s_clk_gen_1_en;

   logic                   s_clk_int_master;
   logic                   s_clk_int_slave;

   logic                   s_clk_ext_master;
   logic                   s_clk_ext_slave;

   logic                   s_clk_master;
   logic                   s_clk_slave;

   logic                   s_ws_int_master;
   logic                   s_ws_int_slave;

   logic                   s_ws_ext_master;
   logic                   s_ws_ext_slave;

   logic                   s_ws_master;
   logic                   s_ws_slave;

   logic s_ws_gen_0_en, s_ws_gen_1_en, s_ws_int_0, s_ws_int_1;
   logic s_clk_master_unmux, s_clk_slave_unmux;

   assign pad_slave_sck_oe = ~sel_slave_ext_i;
   assign pad_slave_ws_oe  = ~sel_slave_ext_i;
   assign pad_slave_ws_o   = pad_slave_ws_oe & s_ws_slave;

   assign pad_master_sck_oe = ~sel_master_ext_i;
   assign pad_master_sck_o  = pad_master_sck_oe & s_clk_master;
   assign pad_master_ws_oe  = ~sel_master_ext_i;
   assign pad_master_ws_o   = pad_master_ws_oe & s_ws_master;

   assign s_clk_gen_0_en = (master_en_i | slave_en_i) & ((~sel_master_num_i & ~sel_master_ext_i) | (~sel_slave_num_i & ~sel_slave_ext_i));
   assign s_clk_gen_1_en = (master_en_i | slave_en_i) & (( sel_master_num_i & ~sel_master_ext_i) | ( sel_slave_num_i & ~sel_slave_ext_i));

   i2s_clk_gen i_clkgen0
     (
      .clk_i        ( clk_i ),
      .rstn_i       ( rstn_i ),
      .test_mode_i  ( dft_test_mode_i ),
      .sck_o        ( s_clk_gen_0 ),
      .cfg_clk_en_i ( s_clk_gen_0_en ),
      .cfg_clk_en_o (  ),
      .cfg_div_i    ( cfg_div_0_i )
      );

   i2s_clk_gen i_clkgen1
     (
      .clk_i        ( clk_i ),
      .rstn_i       ( rstn_i ),
      .test_mode_i  ( dft_test_mode_i ),
      .sck_o        ( s_clk_gen_1 ),
      .cfg_clk_en_i ( s_clk_gen_1_en ),
      .cfg_clk_en_o (  ),
      .cfg_div_i    ( cfg_div_1_i )
      );

`ifndef PULP_FPGA_EMUL
   pulp_clock_mux2 i_clk_slave_out
     (
      .clk0_i(s_clk_slave),
      .clk1_i(pdm_clk_i),
      .clk_sel_i(pdm_en_i),
      .clk_o(pad_slave_sck_o)
      );

   pulp_clock_mux2 i_clock_int_master
     (
      .clk0_i(s_clk_gen_0),
      .clk1_i(s_clk_gen_1),
      .clk_sel_i(sel_master_num_i),
      .clk_o(s_clk_int_master)
      );

   pulp_clock_mux2 i_clock_int_slave
     (
      .clk0_i(s_clk_gen_0),
      .clk1_i(s_clk_gen_1),
      .clk_sel_i(sel_slave_num_i),
      .clk_o(s_clk_int_slave)
      );

   pulp_clock_mux2 i_clock_ext_master
     (
      .clk0_i(pad_master_sck_i),
      .clk1_i(pad_slave_sck_i),
      .clk_sel_i(sel_master_num_i),
      .clk_o(s_clk_ext_master)
      );

   pulp_clock_mux2 i_clock_ext_slave
     (
      .clk0_i(pad_master_sck_i),
      .clk1_i(pad_slave_sck_i),
      .clk_sel_i(sel_slave_num_i),
      .clk_o(s_clk_ext_slave)
      );

   pulp_clock_mux2 i_clock_master
     (
      .clk0_i(s_clk_int_master),
      .clk1_i(s_clk_ext_master),
      .clk_sel_i(sel_master_ext_i),
      .clk_o(s_clk_master_unmux)
      );

   pulp_clock_mux2 i_clock_slave
     (
      .clk0_i(s_clk_int_slave),
      .clk1_i(s_clk_ext_slave),
      .clk_sel_i(sel_slave_ext_i),
      .clk_o(s_clk_slave_unmux)
      );

     assign s_clk_master = dft_test_mode_i ? clk_i : s_clk_master_unmux;
     assign s_clk_slave  = dft_test_mode_i ? clk_i : s_clk_slave_unmux;

`else
   assign pad_slave_sck_o  = ( pdm_en_i         ? pdm_clk_i        : s_clk_slave ) & pad_slave_sck_oe;
   assign s_clk_int_master = sel_master_num_i ? s_clk_gen_1      : s_clk_gen_0;
   assign s_clk_int_slave  = sel_slave_num_i  ? s_clk_gen_1      : s_clk_gen_0;
   assign s_clk_ext_master = sel_master_num_i ? pad_slave_sck_i  : pad_master_sck_i;
   assign s_clk_ext_slave  = sel_slave_num_i  ? pad_slave_sck_i  : pad_master_sck_i;
   assign s_clk_master     = sel_master_ext_i ? s_clk_ext_master : s_clk_int_master;
   assign s_clk_slave      = sel_slave_ext_i  ? s_clk_ext_slave  : s_clk_int_slave;
`endif


  logic clk_master_undft, clk_slave_undft;

   pulp_clock_gating i_master_cg
     (
      .clk_i(s_clk_master),
      .en_i(master_en_i),
      .test_en_i(dft_cg_enable_i),
      .clk_o(clk_master_undft)
      );

   pulp_clock_gating i_slave_cg
     (
      .clk_i(s_clk_slave),
      .en_i(slave_en_i),
      .test_en_i(dft_cg_enable_i),
      .clk_o(clk_slave_undft)
      );

   pulp_sync #(2) i_master_en_sync
     (
      .clk_i(s_clk_master),
      .rstn_i(rstn_i),
      .serial_i(master_en_i),
      .serial_o(s_ws_gen_0_en)
      );

   pulp_sync #(2) i_slave_en_sync
     (
      .clk_i(s_clk_slave),
      .rstn_i(rstn_i),
      .serial_i(slave_en_i),
      .serial_o(s_ws_gen_1_en)
      );

   i2s_ws_gen i_ws_gen_0
     (
      .sck_i           ( s_clk_master       ),
      .rstn_i          ( rstn_i             ),
      .cfg_ws_en_i     ( s_ws_gen_0_en      ),
      .ws_o            ( s_ws_int_0         ),
      .cfg_data_size_i ( cfg_word_size_0_i  ),
      .cfg_word_num_i  ( cfg_word_num_0_i   )
      );

   i2s_ws_gen i_ws_gen_1
     (
      .sck_i           ( s_clk_slave        ),
      .rstn_i          ( rstn_i             ),
      .cfg_ws_en_i     ( s_ws_gen_1_en      ),
      .ws_o            ( s_ws_int_1         ),
      .cfg_data_size_i ( cfg_word_size_1_i  ),
      .cfg_word_num_i  ( cfg_word_num_1_i   )
      );


   assign s_ws_int_master = sel_master_num_i ? s_ws_int_1 : s_ws_int_0;
   assign s_ws_int_slave  = sel_slave_num_i  ? s_ws_int_1 : s_ws_int_0;

   assign s_ws_ext_master = sel_master_num_i ? pad_slave_ws_i : pad_master_ws_i;
   assign s_ws_ext_slave  = sel_slave_num_i  ? pad_slave_ws_i : pad_master_ws_i;

   assign s_ws_master = sel_master_ext_i ? s_ws_ext_master : s_ws_int_master;
   assign s_ws_slave  = sel_slave_ext_i  ? s_ws_ext_slave  : s_ws_int_slave;

   assign ws_master_o = s_ws_master;
   assign ws_slave_o  = s_ws_slave;


   pulp_clock_mux2 clk_master_dftmux
     (
      .clk0_i(clk_master_undft),
      .clk1_i(clk_i),
      .clk_sel_i(dft_test_mode_i),
      .clk_o(clk_master_o)
      );

   pulp_clock_mux2 clk_slave_dftmux
     (
      .clk0_i(clk_slave_undft),
      .clk1_i(clk_i),
      .clk_sel_i(dft_test_mode_i),
      .clk_o(clk_slave_o)
      );

endmodule // i2s_clk_gen
