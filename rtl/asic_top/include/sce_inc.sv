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

`include "template.sv"
//`define MPW

`include "include/common_cell_inc.sv"
`include "modules/crypto_top/rtl/hash_pkg.sv"
`include "modules/crypto_top/rtl/scedma_pkg.sv"

`ifndef __TRNGAES
`include "modules/crypto_trng/rtl/aes_cipher_top.v"
`include "modules/crypto_trng/rtl/aes_key_expand_128.v"
`include "modules/crypto_trng/rtl/aes_rcon.v"
`include "modules/crypto_trng/rtl/aes_sbox.v"
`include "modules/crypto_trng/rtl/aes_update.v"
`include "modules/crypto_trng/rtl/ctr_aes.v"
`define __TRNGAES
`endif

`include "modules/crypto_alu/rtl/alu.sv"
`include "modules/crypto_alu/rtl/aludiv.sv"
`include "modules/crypto_alu/rtl/alucomm.sv"


`include "modules/crypto_trng/rtl/data_buf.v"
`include "modules/crypto_trng/rtl/digitalization.v"
`include "modules/crypto_trng/rtl/healthtest.v"
`include "modules/crypto_trng/rtl/lfsr129.v"
`include "modules/crypto_trng/rtl/postprocess.v"
`include "modules/crypto_trng/rtl/rng_top.v"
`include "modules/crypto_top/rtl/trng.sv"

`include "modules/crypto_top/rtl/hashcore.sv"
`include "modules/crypto_top/rtl/hashcore_blk.sv"
`include "modules/crypto_top/rtl/hashcore_ripe.sv"
`include "modules/crypto_top/rtl/combohasha.sv"
`include "modules/crypto_top/rtl/sce_dmachnl.sv"
`include "modules/crypto_top/rtl/scedma_amba.sv"
`include "modules/crypto_hash/rtl/hashcore_sha3.sv"
`include "modules/crypto_top/rtl/sce_memc.sv"
`include "modules/crypto_top/rtl/scedma_ac.sv"
`include "modules/crypto_top/rtl/scedma.sv"

`include "modules/crypto_top/rtl/pke.sv"
//`include "rtl/crypto/PkeCore_dummy.sv"
//`include "rtl/crypto/pke/cmsdk_ahb_to_sram.v"
`include "modules/crypto_pke/rtl/com_alg.v"
//`include "rtl/crypto/pke/emb_v2.v"
`include "modules/crypto_pke/rtl/mgmr_mul.v"
`include "modules/crypto_pke/rtl/PkeCtrl.sv"
`include "modules/crypto_pke/rtl/PkeRamMux.v"
`include "modules/crypto_pke/rtl/PkeCore.sv"
`include "modules/crypto_pke/rtl/QRegCal.sv"
//`include "rtl/crypto/pke/sram128X32C2V4.v"
//`include "rtl/crypto/pke/sram128X32C2V4_wrp.v"
`include "modules/crypto_pke/rtl/mac_cell.sv"
`include "modules/crypto_pke/rtl/mac_ref.sv"
`include "modules/crypto_pke/rtl/mimm_dpram.sv"
`include "modules/crypto_pke/rtl/mimm.sv"

`include "modules/crypto_top/rtl/aes.sv"
//`include "rtl/crypto/AesCore_dummy.sv"
`default_nettype none

`include "modules/crypto_aes/rtl/AesCore.v"
`include "modules/crypto_aes/rtl/AesCtrl.v"
`include "modules/crypto_aes/rtl/AesDataPath.v"
`include "modules/crypto_aes/rtl/AesMixCol.v"
`include "modules/crypto_aes/rtl/AesSbox.v"
`include "modules/crypto_aes/rtl/GfFunctions.v"

`include "modules/crypto_top/rtl/cryptoram.sv"

`include "modules/crypto_top/rtl/sce_sec.sv"
`include "modules/crypto_top/rtl/sce_glbsfra.sv"

`include "modules/crypto_top/rtl/sce.sv"

`ifdef SIM
`include "asic_top/lib/arm_sram_macro/sce_aesram_1k/sce_aesram_1k.v"
`include "asic_top/lib/arm_sram_macro/sce_pkeram_4k/sce_pkeram_4k.v"
`include "asic_top/lib/arm_sram_macro/sce_hashram_3k/sce_hashram_3k.v"
`include "asic_top/lib/arm_sram_macro/sce_aluram_3k/sce_aluram_3k.v"
`include "asic_top/lib/arm_sram_macro/sce_sceram_10k/sce_sceram_10k.v"
`include "asic_top/lib/arm_sram_macro/sce_mimmdpram/sce_mimmdpram.v"
//`include "modules/model/rtl/rng_cell.sv"
`endif

`ifdef SYN
`include "modules/model/rtl/rng_cell.sv"
`endif
