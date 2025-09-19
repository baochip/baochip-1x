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

module rbist_wrp #(
    parameter RAMC = 28
)(
    input logic         atpgrst, //Tony added
    input logic         cmsatpg,
    input logic         atpgse,

	jtagif.slave 		jtagrb,
    apbif.slavein       apbs,
    apbif.slave         apbx,
    input logic         pclk, clksys,
    input logic         sysresetn,
    input logic  [0:5]  clkbist,

    input  logic         iptregset,
    input  logic [63:0]  iptregout,
    output logic [63:0]  iptregin,
    input logic                  nvrtrmset,
    input logic [RAMC-1:0]       nvrtrmvld,
    input logic [RAMC-1:0][15:0] nvrtrmdat,

    rbif.master         rbif_ram32kx72	        [0:3]   ,       //  sram	        ram32kx72	        4	    sp
    rbif.master         rbif_ram8kx72	        [0:15]  ,       // 	sram	        ram8kx72	        16      sp
    rbif.master         rbif_rf1kx72	        [0:1]   ,       // 	cache	        rf1kx72	            2	    sp
    rbif.master         rbif_rf256x27	        [0:1]   ,       // 	cache	        rf256x27	        2	    sp
    rbif.master         rbif_rf512x39	        [0:7]   ,       // 	cache	        rf512x39	        8	    sp
    rbif.master         rbif_rf128x31	        [0:3]   ,       //  cache	        rf128x31	        4	    sp
    rbif.master         rbif_dtcm8kx36	        [0:1]   ,       // 	dtcm	        dtcm8kx36	        2	    sp
    rbif.master         rbif_itcm32kx18	        [0:3]   ,       // 	itcm	        itcm32kx18	        4	    sp
    rbif.master         rbif_ifram32kx36	    [0:1]   ,       //  ifram	        ifram32kx36	        2	    sp
    rbif.master         rbif_sce_sceram_10k	    [0:0]   ,       //  sceram	        sce_sceram_10k	    1	    sp
    rbif.master         rbif_sce_hashram_3k	    [0:0]   ,       // 	hashram	        sce_hashram_3k	    1	    sp
    rbif.master         rbif_sce_aesram_1k	    [0:0]   ,       // 	aesram	        sce_aesram_1k	    1	    sp
    rbif.master         rbif_sce_pkeram_4k	    [0:1]   ,       // 	pkeram	        sce_pkeram_4k	    2	    sp
    rbif.master         rbif_sce_aluram_3k	    [0:1]   ,       // 	aluram	        sce_aluram_3k	    2	    sp
    rbif.masterdp       rbif_sce_mimmdpram      [0:0]   ,       //  pkeramdp        sce_mimmdpram       1       dp
    rbif.masterdp       rbif_rdram1kx32	        [0:5]   ,       //  RAM_DP_1024_32	rdram1kx32	        6	    dp
    rbif.masterdp       rbif_rdram512x64	    [0:3]   ,       // 	RAM_DP_512_64	rdram512x64	        4	    dp
    rbif.masterdp       rbif_rdram128x22	    [0:7]   ,       // 	RAM_DP_128_22	rdram128x22	        8	    dp
    rbif.masterdp       rbif_rdram32x16	        [0:1]   ,       // 	RAM_DP_512_1	rdram32x16	        2	    dp
    rbif.master         rbif_bioram1kx32	    [0:3]   ,       //  RAM_SP_1024_32	bioram1kx32	        4	    sp
    rbif.masterdp       rbif_tx_fifo128x32	    [0:0]   ,       // 	csr.U_tx_fifo	fifo128x32	        1	    dp
    rbif.masterdp       rbif_rx_fifo128x32	    [0:0]   ,       // 	csr.U_rx_fifo	fifo128x32	        1	    dp
    rbif.masterdp       rbif_fifo32x19	        [0:0]   ,       // 	csr.U_cmd_fifo  fifo32x19	        1	    dp
    rbif.masterdp       rbif_udcmem_share	    [0:0]   ,       //  share_mem	    udcmem_1088x64	    1	    dp
    rbif.masterdp       rbif_udcmem_odb	        [0:0]   ,       // 	odb_mem	        udcmem_1088x64	    1	    dp
    rbif.masterdp       rbif_udcmem_256x64	    [0:0]   ,       // 	idb_mem	        udcmem_256x64	    1	    dp
    rbif.master         rbif_acram2kx64	        [0:0]   ,       //  acram           acram2kx64	        1	    sp
    rbif.master         rbif_aoram1kx36	        [0:1]           //  aoram	        aoram1kx36	        2	    sp
);


// trm
// ■■■■■■■■■■■■■■■

    typedef struct packed {
        bit [2:0]   ema;
        bit [2:0]   emab;
        bit [1:0]   emaw;
        bit         emas;
        bit         wabl;
        bit [2:0]   wablm;
        bit         rawl;
        bit [1:0]   rawlm;
    } t_trm;

    localparam t_trm IV_sram_sp_uhde_inst       = { ema: 3'b100, emab: 3'b000, emaw: 2'b00, emas:  1'b0, wabl: 1'b1, wablm: 3'b011, rawl: 1'b1, rawlm: 2'b11 };
    localparam t_trm IV_sram_sp_hde_inst        = { ema: 3'b100, emab: 3'b000, emaw: 2'b00, emas:  1'b0, wabl: 1'b1, wablm: 3'b001, rawl: 1'b0, rawlm: 2'b00 };
    localparam t_trm IV_rf_sp_hde_inst          = { ema: 3'b100, emab: 3'b000, emaw: 2'b00, emas:  1'b0, wabl: 1'b1, wablm: 3'b001, rawl: 1'b0, rawlm: 2'b00 };
    localparam t_trm IV_rf_2p_hdc_inst          = { ema: 3'b101, emab: 3'b101, emaw: 2'b00, emas:  1'b0, wabl: 1'b1, wablm: 3'b001, rawl: 1'b0, rawlm: 2'b00 };
    localparam t_trm IV_sram_sp_svt_inst        = { ema: 3'b100, emab: 3'b000, emaw: 2'b01, emas:  1'b0, wabl: 1'b0, wablm: 3'b000, rawl: 1'b0, rawlm: 2'b00 };
    localparam t_trm IV_sram_sp_svt_inst_tcm    = { ema: 3'b100, emab: 3'b000, emaw: 2'b01, emas:  1'b0, wabl: 1'b0, wablm: 3'b000, rawl: 1'b0, rawlm: 2'b00 };
    localparam t_trm IV_sram_sp_hde_inst_tcm    = { ema: 3'b100, emab: 3'b000, emaw: 2'b01, emas:  1'b0, wabl: 1'b1, wablm: 3'b000, rawl: 1'b0, rawlm: 2'b00 };
    localparam t_trm IV_rf_sp_hde_inst_cache    = { ema: 3'b100, emab: 3'b000, emaw: 2'b01, emas:  1'b0, wabl: 1'b1, wablm: 3'b001, rawl: 1'b0, rawlm: 2'b00 };
    localparam t_trm IV_sram_sp_hde_inst_sram1  = { ema: 3'b100, emab: 3'b000, emaw: 2'b00, emas:  1'b0, wabl: 1'b1, wablm: 3'b001, rawl: 1'b0, rawlm: 2'b00 };
    localparam t_trm IV_sram_sp_uhde_inst_sram0 = { ema: 3'b100, emab: 3'b000, emaw: 2'b00, emas:  1'b0, wabl: 1'b1, wablm: 3'b000, rawl: 1'b1, rawlm: 2'b01 };
    localparam t_trm IV_rf_2p_hdc_inst_vex      = { ema: 3'b011, emab: 3'b100, emaw: 2'b00, emas:  1'b0, wabl: 1'b0, wablm: 3'b000, rawl: 1'b0, rawlm: 2'b00 };

    logic [RAMC-1:0][15:0] trmdat;
    logic [15:0] trm_ram32kx72      ; assign trm_ram32kx72      = trmdat[0 ]; localparam t_trm IV_trm_ram32kx72      = IV_sram_sp_uhde_inst_sram0;
    logic [15:0] trm_ram8kx72       ; assign trm_ram8kx72       = trmdat[1 ]; localparam t_trm IV_trm_ram8kx72       = IV_sram_sp_hde_inst_sram1;
    logic [15:0] trm_rf1kx72        ; assign trm_rf1kx72        = trmdat[2 ]; localparam t_trm IV_trm_rf1kx72        = IV_rf_sp_hde_inst_cache;
    logic [15:0] trm_rf256x27       ; assign trm_rf256x27       = trmdat[3 ]; localparam t_trm IV_trm_rf256x27       = IV_rf_sp_hde_inst_cache;
    logic [15:0] trm_rf512x39       ; assign trm_rf512x39       = trmdat[4 ]; localparam t_trm IV_trm_rf512x39       = IV_rf_sp_hde_inst_cache;
    logic [15:0] trm_rf128x31       ; assign trm_rf128x31       = trmdat[5 ]; localparam t_trm IV_trm_rf128x31       = IV_rf_sp_hde_inst_cache;
    logic [15:0] trm_dtcm8kx36      ; assign trm_dtcm8kx36      = trmdat[6 ]; localparam t_trm IV_trm_dtcm8kx36      = IV_sram_sp_hde_inst_tcm;
    logic [15:0] trm_itcm32kx18     ; assign trm_itcm32kx18     = trmdat[7 ]; localparam t_trm IV_trm_itcm32kx18     = IV_sram_sp_hde_inst_tcm;
    logic [15:0] trm_ifram32kx36    ; assign trm_ifram32kx36    = trmdat[8 ]; localparam t_trm IV_trm_ifram32kx36    = IV_sram_sp_uhde_inst;
    logic [15:0] trm_sce_sceram_10k ; assign trm_sce_sceram_10k = trmdat[9 ]; localparam t_trm IV_trm_sce_sceram_10k = IV_sram_sp_hde_inst;
    logic [15:0] trm_sce_hashram_3k ; assign trm_sce_hashram_3k = trmdat[10]; localparam t_trm IV_trm_sce_hashram_3k = IV_rf_sp_hde_inst;
    logic [15:0] trm_sce_aesram_1k  ; assign trm_sce_aesram_1k  = trmdat[11]; localparam t_trm IV_trm_sce_aesram_1k  = IV_rf_sp_hde_inst;
    logic [15:0] trm_sce_pkeram_4k  ; assign trm_sce_pkeram_4k  = trmdat[12]; localparam t_trm IV_trm_sce_pkeram_4k  = IV_rf_sp_hde_inst;
    logic [15:0] trm_sce_aluram_3k  ; assign trm_sce_aluram_3k  = trmdat[13]; localparam t_trm IV_trm_sce_aluram_3k  = IV_rf_sp_hde_inst;
    logic [15:0] trm_sce_mimmdpram  ; assign trm_sce_mimmdpram  = trmdat[14]; localparam t_trm IV_trm_sce_mimmdpram  = IV_rf_2p_hdc_inst;
    logic [15:0] trm_rdram1kx32     ; assign trm_rdram1kx32     = trmdat[15]; localparam t_trm IV_trm_rdram1kx32     = IV_rf_2p_hdc_inst_vex;
    logic [15:0] trm_rdram512x64    ; assign trm_rdram512x64    = trmdat[16]; localparam t_trm IV_trm_rdram512x64    = IV_rf_2p_hdc_inst_vex;
    logic [15:0] trm_rdram128x22    ; assign trm_rdram128x22    = trmdat[17]; localparam t_trm IV_trm_rdram128x22    = IV_rf_2p_hdc_inst_vex;
    logic [15:0] trm_rdram32x16     ; assign trm_rdram32x16     = trmdat[18]; localparam t_trm IV_trm_rdram32x16     = IV_rf_2p_hdc_inst_vex;
    logic [15:0] trm_bioram1kx32    ; assign trm_bioram1kx32    = trmdat[19]; localparam t_trm IV_trm_bioram1kx32    = IV_rf_sp_hde_inst_cache;
    logic [15:0] trm_tx_fifo128x32  ; assign trm_tx_fifo128x32  = trmdat[20]; localparam t_trm IV_trm_tx_fifo128x32  = IV_rf_2p_hdc_inst;
    logic [15:0] trm_rx_fifo128x32  ; assign trm_rx_fifo128x32  = trmdat[21]; localparam t_trm IV_trm_rx_fifo128x32  = IV_rf_2p_hdc_inst;
    logic [15:0] trm_fifo32x19      ; assign trm_fifo32x19      = trmdat[22]; localparam t_trm IV_trm_fifo32x19      = IV_rf_2p_hdc_inst;
    logic [15:0] trm_udcmem_share   ; assign trm_udcmem_share   = trmdat[23]; localparam t_trm IV_trm_udcmem_share   = IV_rf_2p_hdc_inst;
    logic [15:0] trm_udcmem_odb     ; assign trm_udcmem_odb     = trmdat[24]; localparam t_trm IV_trm_udcmem_odb     = IV_rf_2p_hdc_inst;
    logic [15:0] trm_udcmem_256x64  ; assign trm_udcmem_256x64  = trmdat[25]; localparam t_trm IV_trm_udcmem_256x64  = IV_rf_2p_hdc_inst;
    logic [15:0] trm_acram2kx64     ; assign trm_acram2kx64     = trmdat[26]; localparam t_trm IV_trm_acram2kx64     = IV_sram_sp_uhde_inst_sram0;
    logic [15:0] trm_aoram1kx36     ; assign trm_aoram1kx36     = trmdat[27]; localparam t_trm IV_trm_aoram1kx36     = IV_sram_sp_hde_inst;

    localparam [15:0] IV_trm[0:27] = {
        IV_trm_ram32kx72      ,
        IV_trm_ram8kx72       ,
        IV_trm_rf1kx72        ,
        IV_trm_rf256x27       ,
        IV_trm_rf512x39       ,
        IV_trm_rf128x31       ,
        IV_trm_dtcm8kx36      ,
        IV_trm_itcm32kx18     ,
        IV_trm_ifram32kx36    ,
        IV_trm_sce_sceram_10k ,
        IV_trm_sce_hashram_3k ,
        IV_trm_sce_aesram_1k  ,
        IV_trm_sce_pkeram_4k  ,
        IV_trm_sce_aluram_3k  ,
        IV_trm_sce_mimmdpram  ,
        IV_trm_rdram1kx32     ,
        IV_trm_rdram512x64    ,
        IV_trm_rdram128x22    ,
        IV_trm_rdram32x16     ,
        IV_trm_bioram1kx32    ,
        IV_trm_tx_fifo128x32  ,
        IV_trm_rx_fifo128x32  ,
        IV_trm_fifo32x19      ,
        IV_trm_udcmem_share   ,
        IV_trm_udcmem_odb     ,
        IV_trm_udcmem_256x64  ,
        IV_trm_acram2kx64     ,
        IV_trm_aoram1kx36
    };

// apb sfr
// ■■■■■■■■■■■■■■■

    logic apbrd, apbwr;
    logic sfrlock;

    assign sfrlock = '0;

    `apbs_common;
    assign apbx.prdata = '0
                        | sfrcr_trm.prdata32 | sfrsr_trm.prdata32
                        ;

    bit [23:0] trmcr, trmsr;
    bit trmar;
    bit [7:0]  sfrtrmsel, ipttrmsel, trmsel;
    bit [15:0] sfrtrmdat, ipttrmdat;
    bit ipttrmset, sfrtrmset;
    logic resetn;
    assign resetn = sysresetn;

    apb_cr #(.A('h00), .DW(24))         sfrcr_trm    (.cr( trmcr    ), .prdata32(),.*);
    apb_sr #(.A('h04), .DW(24))         sfrsr_trm    (.sr( trmsr    ), .prdata32(),.*);
    apb_ar #(.A('h08), .AR(32'h5a))     sfrar_trm    (.ar( trmar    ),             .*);

    assign            { sfrtrmsel[7:0],  sfrtrmdat[15:0]      } = trmcr;
    assign trmsr =    { sfrtrmsel[7:0],     trmdat[sfrtrmsel] }        ;

    assign            { ipttrmsel[7:0],  ipttrmdat[15:0]           } = iptregout[23:0];
    assign iptregin = {    trmsel[7:0],     trmdat[ipttrmsel[6:0]] } | 64'h0    ;

    sync_pulse su0 ( .clka(jtagrb.tck), .resetn(sysresetn), .clkb(clksys), .pulsea (iptregset), .pulseb( ipttrmset ) );
    sync_pulse su1 ( .clka(pclk),        .resetn(sysresetn), .clkb(clksys), .pulsea (trmar    ), .pulseb( sfrtrmset ) );
//    sync_pulse su1 ( .clka(jtagipt.tck), .resetn(sysresetn), .clkb(clksys), .pulsea (ipt), .pulseb( nvrtrmset ) );

    genvar i;
    generate
        for ( i = 0; i < 28 ; i++) begin: gtrm
            t_trm trmtmp;
            `theregfull( clksys, sysresetn, trmtmp , IV_trm[i] ) <=
                    sfrtrmset & ( sfrtrmsel == i )     ? sfrtrmdat[15:0] :
                    ipttrmset & ( ipttrmsel == 128+i ) ? ipttrmdat[15:0] :
                    nvrtrmset & nvrtrmvld[i]           ? nvrtrmdat[i][15:0] :
                                                         trmtmp;
            assign trmdat[i] = trmtmp;
        end
    endgenerate

    `theregfull( clksys, sysresetn, trmsel , '0 ) <= ipttrmset ? ipttrmsel : trmsel;

// wrapper
// ■■■■■■■■■■■■■■■

    logic  [0:3]       ram32k_bclk   ; assign ram32k_bclk    =  {(3+1){clkbist[1]}};
    logic  [0:15]      ram8k_bclk    ; assign ram8k_bclk     = {(15+1){clkbist[1]}};
    logic  [0:1]       rf1k_bclk     ; assign rf1k_bclk      =  {(1+1){clkbist[0]}};
    logic  [0:1]       rf256_bclk    ; assign rf256_bclk     =  {(1+1){clkbist[0]}};
    logic  [0:7]       rf512_bclk    ; assign rf512_bclk     =  {(7+1){clkbist[0]}};
    logic  [0:3]       rf128_bclk    ; assign rf128_bclk     =  {(3+1){clkbist[0]}};
    logic  [0:1]       dtcm8k_bclk   ; assign dtcm8k_bclk    =  {(1+1){clkbist[0]}};
    logic  [0:3]       itcm32k_bclk  ; assign itcm32k_bclk   =  {(3+1){clkbist[0]}};
    logic  [0:1]       ifram32k_bclk ; assign ifram32k_bclk  =  {(1+1){clkbist[3]}};
    logic              sce10k_bclk   ; assign sce10k_bclk    =         clkbist[2]  ;
    logic              hash3k_bclk   ; assign hash3k_bclk    =         clkbist[2]  ;
    logic              aes1k_bclk    ; assign aes1k_bclk     =         clkbist[2]  ;
    logic  [0:1]       pke4k_bclk    ; assign pke4k_bclk     =  {(1+1){clkbist[2]}};
    logic  [0:1]       alu3k_bclk    ; assign alu3k_bclk     =  {(1+1){clkbist[2]}};
    logic              mimmdp_clka   ; assign mimmdp_clka    =         clkbist[2]  ;
    logic              mimmdp_clkb   ; assign mimmdp_clkb    =         clkbist[2]  ;
    logic  [0:5]       ram1k_clka    ; assign ram1k_clka     =  {(5+1){clkbist[1]}};
    logic  [0:5]       ram1k_clkb    ; assign ram1k_clkb     =  {(5+1){clkbist[1]}};
    logic  [0:3]       ram512_clka   ; assign ram512_clka    =  {(3+1){clkbist[1]}};
    logic  [0:3]       ram512_clkb   ; assign ram512_clkb    =  {(3+1){clkbist[1]}};
    logic  [0:7]       ram128_clka   ; assign ram128_clka    =  {(7+1){clkbist[1]}};
    logic  [0:7]       ram128_clkb   ; assign ram128_clkb    =  {(7+1){clkbist[1]}};
    logic  [0:1]       ram32_clka    ; assign ram32_clka     =  {(1+1){clkbist[1]}};
    logic  [0:1]       ram32_clkb    ; assign ram32_clkb     =  {(1+1){clkbist[1]}};
    logic  [0:3]       bioram1k_bclk ; assign bioram1k_bclk  =  {(3+1){clkbist[1]}};
    logic  [0:1]       fifo128_clka  ; assign fifo128_clka   =  {(1+1){clkbist[1]}};
    logic  [0:1]       fifo128_clkb  ; assign fifo128_clkb   =  {(1+1){clkbist[1]}};
    logic              fifo32_clka   ; assign fifo32_clka    =         clkbist[1]  ;
    logic              fifo32_clkb   ; assign fifo32_clkb    =         clkbist[1]  ;
    logic  [0:1]       udc1088_clka  ; assign udc1088_clka   =  {(1+1){clkbist[4]}};
    logic  [0:1]       udc1088_clkb  ; assign udc1088_clkb   =  {(1+1){clkbist[4]}};
    logic              udc256_clka   ; assign udc256_clka    =         clkbist[4]  ;
    logic              udc256_clkb   ; assign udc256_clkb    =         clkbist[4]  ;
    logic              acram_bclk    ; assign acram_bclk     =         clkbist[1]  ;
    logic  [0:1]       aoram1k_bclk  ; assign aoram1k_bclk   =  {(1+1){clkbist[5]}};

    logic   [0:3] [71:0]      ram32k_bq        ;
    logic   [0:15][71:0]      ram8k_bq         ;
    logic   [0:1] [71:0]      rf1k_bq          ;
    logic   [0:1] [26:0]      rf256_bq         ;
    logic   [0:7] [38:0]      rf512_bq         ;
    logic   [0:3] [30:0]      rf128_bq         ;
    logic   [0:1] [35:0]      dtcm8k_bq        ;
    logic   [0:3] [17:0]      itcm32k_bq       ;
    logic   [0:1] [35:0]      ifram32k_bq      ;
    logic         [35:0]      sce10k_bq        ;
    logic         [35:0]      hash3k_bq        ;
    logic         [35:0]      aes1k_bq         ;
    logic   [0:1] [71:0]      pke4k_bq         ;
    logic   [0:1] [35:0]      alu3k_bq         ;               // nto new
    logic         [71:0]      mimmdp_qa        ;               // nto new
    logic   [0:5] [31:0]      ram1k_qa         ;
    logic   [0:3] [63:0]      ram512_qa        ;
    logic   [0:7] [21:0]      ram128_qa        ;
    logic   [0:1] [15:0]      ram32_qa         ;
    logic   [0:3] [31:0]      bioram1k_bq      ;               // nto new
    logic   [0:1] [31:0]      fifo128_qa       ;               // nto delete sddc fifo128x32 *2
    logic         [18:0]      fifo32_qa        ;
    logic   [0:1] [63:0]      udc1088_qa       ;
    logic         [63:0]      udc256_qa        ;
    logic         [63:0]      acram_bq         ;
    logic   [0:1] [35:0]      aoram1k_bq       ;               // nto new

    logic  [0:3]             ram32k_bcen      ; assign ram32k_bcen    ='1;
    logic  [0:3]             ram32k_bgwen     ; assign ram32k_bgwen   ='1;
    logic  [0:3] [71:0]      ram32k_bwen      ; assign ram32k_bwen    ='1;
    logic  [0:3] [14:0]      ram32k_ba        ; assign ram32k_ba      ='0;
    logic  [0:3] [71:0]      ram32k_bd        ; assign ram32k_bd      ='0;
    logic  [0:15]            ram8k_bcen       ; assign ram8k_bcen     ='1;
    logic  [0:15]            ram8k_bgwen      ; assign ram8k_bgwen    ='1;
    logic  [0:15][71:0]      ram8k_bwen       ; assign ram8k_bwen     ='1;
    logic  [0:15][12:0]      ram8k_ba         ; assign ram8k_ba       ='0;
    logic  [0:15][71:0]      ram8k_bd         ; assign ram8k_bd       ='0;
    logic  [0:1]             rf1k_bcen        ; assign rf1k_bcen      ='1;
    logic  [0:1]             rf1k_bgwen       ; assign rf1k_bgwen     ='1;
    logic  [0:1] [71:0]      rf1k_bwen        ; assign rf1k_bwen      ='1;
    logic  [0:1] [9:0]       rf1k_ba          ; assign rf1k_ba        ='0;
    logic  [0:1] [71:0]      rf1k_bd          ; assign rf1k_bd        ='0;
    logic  [0:1]             rf256_bcen       ; assign rf256_bcen     ='1;
    logic  [0:1]             rf256_bgwen      ; assign rf256_bgwen    ='1;
    logic  [0:1] [26:0]      rf256_bwen       ; assign rf256_bwen     ='1;
    logic  [0:1] [7:0]       rf256_ba         ; assign rf256_ba       ='0;
    logic  [0:1] [26:0]      rf256_bd         ; assign rf256_bd       ='0;
    logic  [0:7]             rf512_bcen       ; assign rf512_bcen     ='1;
    logic  [0:7]             rf512_bgwen      ; assign rf512_bgwen    ='1;
    logic  [0:7] [38:0]      rf512_bwen       ; assign rf512_bwen     ='1;
    logic  [0:7] [8:0]       rf512_ba         ; assign rf512_ba       ='0;
    logic  [0:7] [38:0]      rf512_bd         ; assign rf512_bd       ='0;
    logic  [0:3]             rf128_bcen       ; assign rf128_bcen     ='1;
    logic  [0:3]             rf128_bgwen      ; assign rf128_bgwen    ='1;
    logic  [0:3] [30:0]      rf128_bwen       ; assign rf128_bwen     ='1;
    logic  [0:3] [6:0]       rf128_ba         ; assign rf128_ba       ='0;
    logic  [0:3] [30:0]      rf128_bd         ; assign rf128_bd       ='0;
    logic  [0:1]             dtcm8k_bcen      ; assign dtcm8k_bcen    ='1;
    logic  [0:1]             dtcm8k_bgwen     ; assign dtcm8k_bgwen   ='1;
    logic  [0:1] [35:0]      dtcm8k_bwen      ; assign dtcm8k_bwen    ='1;
    logic  [0:1] [12:0]      dtcm8k_ba        ; assign dtcm8k_ba      ='0;
    logic  [0:1] [35:0]      dtcm8k_bd        ; assign dtcm8k_bd      ='0;
    logic  [0:3]             itcm32k_bcen     ; assign itcm32k_bcen   ='1;
    logic  [0:3]             itcm32k_bgwen    ; assign itcm32k_bgwen  ='1;
    logic  [0:3] [17:0]      itcm32k_bwen     ; assign itcm32k_bwen   ='1;
    logic  [0:3] [14:0]      itcm32k_ba       ; assign itcm32k_ba     ='0;
    logic  [0:3] [17:0]      itcm32k_bd       ; assign itcm32k_bd     ='0;
    logic  [0:1]             ifram32k_bcen    ; assign ifram32k_bcen  ='1;
    logic  [0:1]             ifram32k_bgwen   ; assign ifram32k_bgwen ='1;
    logic  [0:1] [35:0]      ifram32k_bwen    ; assign ifram32k_bwen  ='1;
    logic  [0:1] [14:0]      ifram32k_ba      ; assign ifram32k_ba    ='0;
    logic  [0:1] [35:0]      ifram32k_bd      ; assign ifram32k_bd    ='0;
    logic                    sce10k_bcen      ; assign sce10k_bcen    ='1;
    logic                    sce10k_bgwen     ; assign sce10k_bgwen   ='1;
    logic        [11:0]      sce10k_ba        ; assign sce10k_ba      ='0;
    logic        [35:0]      sce10k_bd        ; assign sce10k_bd      ='0;
    logic                    hash3k_bcen      ; assign hash3k_bcen    ='1;
    logic                    hash3k_bwen      ; assign hash3k_bwen    ='1;
    logic        [9:0]       hash3k_ba        ; assign hash3k_ba      ='0;
    logic        [35:0]      hash3k_bd        ; assign hash3k_bd      ='0;
    logic                    aes1k_bcen       ; assign aes1k_bcen     ='1;
    logic                    aes1k_bwen       ; assign aes1k_bwen     ='1;
    logic        [7:0]       aes1k_ba         ; assign aes1k_ba       ='0;
    logic        [35:0]      aes1k_bd         ; assign aes1k_bd       ='0;
    logic  [0:1]             pke4k_bcen       ; assign pke4k_bcen     ='1;
    logic  [0:1]             pke4k_bgwen      ; assign pke4k_bgwen    ='1;
    logic  [0:1] [71:0]      pke4k_bwen       ; assign pke4k_bwen     ='1;
    logic  [0:1] [8:0]       pke4k_ba         ; assign pke4k_ba       ='0;
    logic  [0:1] [71:0]      pke4k_bd         ; assign pke4k_bd       ='0;
    logic  [0:1]             alu3k_bcen       ; assign alu3k_bcen     ='1;
    logic  [0:1]             alu3k_bgwen      ; assign alu3k_bgwen    ='1;
    logic  [0:1] [35:0]      alu3k_bwen       ; assign alu3k_bwen     ='1;
    logic  [0:1] [9:0]       alu3k_ba         ; assign alu3k_ba       ='0;
    logic  [0:1] [35:0]      alu3k_bd         ; assign alu3k_bd       ='0;
    logic                    mimmdp_cena      ; assign mimmdp_cena    ='1;
    logic        [7:0]       mimmdp_aa        ; assign mimmdp_aa      ='0;
    logic                    mimmdp_cenb      ; assign mimmdp_cenb    ='1;
    logic        [71:0]      mimmdp_wenb      ; assign mimmdp_wenb    ='0;
    logic        [7:0]       mimmdp_ab        ; assign mimmdp_ab      ='0;
    logic        [71:0]      mimmdp_db        ; assign mimmdp_db      ='0;
    logic  [0:5]             ram1k_cena       ; assign ram1k_cena     ='1;
    logic  [0:5] [9:0]       ram1k_aa         ; assign ram1k_aa       ='0;
    logic  [0:5]             ram1k_cenb       ; assign ram1k_cenb     ='1;
    logic  [0:5] [31:0]      ram1k_wenb       ; assign ram1k_wenb     ='0;
    logic  [0:5] [9:0]       ram1k_ab         ; assign ram1k_ab       ='0;
    logic  [0:5] [31:0]      ram1k_db         ; assign ram1k_db       ='0;
    logic  [0:3]             ram512_cena      ; assign ram512_cena    ='1;
    logic  [0:3] [8:0]       ram512_aa        ; assign ram512_aa      ='0;
    logic  [0:3]             ram512_cenb      ; assign ram512_cenb    ='1;
    logic  [0:3] [8:0]       ram512_ab        ; assign ram512_ab      ='0;
    logic  [0:3] [63:0]      ram512_db        ; assign ram512_db      ='0;
    logic  [0:7]             ram128_cena      ; assign ram128_cena    ='1;
    logic  [0:7] [6:0]       ram128_aa        ; assign ram128_aa      ='0;
    logic  [0:7]             ram128_cenb      ; assign ram128_cenb    ='1;
    logic  [0:7] [6:0]       ram128_ab        ; assign ram128_ab      ='0;
    logic  [0:7] [21:0]      ram128_db        ; assign ram128_db      ='0;
    logic  [0:1]             ram32_cena       ; assign ram32_cena     ='1;
    logic  [0:1] [4:0]       ram32_aa         ; assign ram32_aa       ='0;
    logic  [0:1]             ram32_cenb       ; assign ram32_cenb     ='1;
    logic  [0:1] [15:0]      ram32_wenb       ; assign ram32_wenb     ='0;
    logic  [0:1] [4:0]       ram32_ab         ; assign ram32_ab       ='0;
    logic  [0:1] [15:0]      ram32_db         ; assign ram32_db       ='0;
    logic  [0:3]             bioram1k_bcen    ; assign bioram1k_bcen  ='1;
    logic  [0:3]             bioram1k_bgwen   ; assign bioram1k_bgwen ='1;
    logic  [0:3] [31:0]      bioram1k_bwen    ; assign bioram1k_bwen  ='1;
    logic  [0:3] [9:0]       bioram1k_ba      ; assign bioram1k_ba    ='0;
    logic  [0:3] [31:0]      bioram1k_bd      ; assign bioram1k_bd    ='0;
    logic  [0:1]             fifo128_cena     ; assign fifo128_cena   ='1;
    logic  [0:1] [6:0]       fifo128_aa       ; assign fifo128_aa     ='0;
    logic  [0:1]             fifo128_cenb     ; assign fifo128_cenb   ='1;
    logic  [0:1] [6:0]       fifo128_ab       ; assign fifo128_ab     ='0;
    logic  [0:1] [31:0]      fifo128_db       ; assign fifo128_db     ='0;
    logic                    fifo32_cena      ; assign fifo32_cena    ='1;
    logic        [4:0]       fifo32_aa        ; assign fifo32_aa      ='0;
    logic                    fifo32_cenb      ; assign fifo32_cenb    ='1;
    logic        [4:0]       fifo32_ab        ; assign fifo32_ab      ='0;
    logic        [18:0]      fifo32_db        ; assign fifo32_db      ='0;
    logic  [0:1]             udc1088_cena     ; assign udc1088_cena   ='1;
    logic  [0:1] [10:0]      udc1088_aa       ; assign udc1088_aa     ='0;
    logic  [0:1]             udc1088_cenb     ; assign udc1088_cenb   ='1;
    logic  [0:1] [10:0]      udc1088_ab       ; assign udc1088_ab     ='0;
    logic  [0:1] [63:0]      udc1088_db       ; assign udc1088_db     ='0;
    logic                    udc256_cena      ; assign udc256_cena    ='1;
    logic        [7:0]       udc256_aa        ; assign udc256_aa      ='0;
    logic                    udc256_cenb      ; assign udc256_cenb    ='1;
    logic        [7:0]       udc256_ab        ; assign udc256_ab      ='0;
    logic        [63:0]      udc256_db        ; assign udc256_db      ='0;
    logic                    acram_bcen       ; assign acram_bcen     ='1;
    logic                    acram_bgwen      ; assign acram_bgwen    ='1;
    logic        [10:0]      acram_ba         ; assign acram_ba       ='0;
    logic        [63:0]      acram_bd         ; assign acram_bd       ='0;
    logic  [0:1]             aoram1k_bcen     ; assign aoram1k_bcen   ='1;
    logic  [0:1]             aoram1k_bgwen    ; assign aoram1k_bgwen  ='1;
    logic  [0:1] [9:0]       aoram1k_ba       ; assign aoram1k_ba     ='0;
    logic  [0:1] [35:0]      aoram1k_bd       ; assign aoram1k_bd     ='0;

    logic tck ; assign tck = jtagrb.tck   ;
    logic tdi ; assign tdi = jtagrb.tdi   ;
    logic tms ; assign tms = jtagrb.tms   ;
    logic trst; assign trst= jtagrb.trst  ;
    logic tdo ; assign jtagrb.tdo = tdo  ;

    logic tdo_en;

    rbist rbcore(

        .*);

endmodule : rbist_wrp

module __dummytb_rbist_wrp;
    parameter RAMC = 28;
    logic         cmsatpg, atpgrst, atpgse;
    jtagif        jtagrb();
    apbif         apbs(), apbx();
    logic         pclk, clksys;
    logic  [0:5]  clkbist;
    logic         sysresetn;
    logic         iptregset;
    logic [63:0]  iptregout;
    logic [63:0]  iptregin;
    logic                  nvrtrmset;
    logic [0:RAMC-1]       nvrtrmvld;
    logic [0:RAMC-1][15:0] nvrtrmdat;
    rbif #(.AW(15   ),      .DW(72))    rbif_ram32kx72      [0:3]   ();
    rbif #(.AW(13   ),      .DW(72))    rbif_ram8kx72       [0:15]  ();
    rbif #(.AW(10   ),      .DW(72))    rbif_rf1kx72        [0:1]   ();
    rbif #(.AW(8    ),      .DW(27))    rbif_rf256x27       [0:1]   ();
    rbif #(.AW(9    ),      .DW(39))    rbif_rf512x39       [0:7]   ();
    rbif #(.AW(7    ),      .DW(31))    rbif_rf128x31       [0:3]   ();
    rbif #(.AW(13   ),      .DW(36))    rbif_dtcm8kx36      [0:1]   ();
    rbif #(.AW(15   ),      .DW(18))    rbif_itcm32kx18     [0:3]   ();
    rbif #(.AW(12   ),      .DW(36))    rbif_sce_sceram_10k [0:0]   ();
    rbif #(.AW(10   ),      .DW(36))    rbif_sce_hashram_3k [0:0]   ();
    rbif #(.AW(8    ),      .DW(36))    rbif_sce_aesram_1k  [0:0]   ();
    rbif #(.AW(9    ),      .DW(72))    rbif_sce_pkeram_4k  [0:1]   ();
    rbif #(.AW(10   ),      .DW(36))    rbif_sce_aluram_3k  [0:1]   ();
    rbif #(.AW(8    ),      .DW(72))    rbif_sce_mimmdpram  [0:0]   ();
    rbif #(.AW(10   ),      .DW(32))    rbif_rdram1kx32     [0:5]   ();
    rbif #(.AW(9    ),      .DW(64))    rbif_rdram512x64    [0:3]   ();
    rbif #(.AW(7    ),      .DW(22))    rbif_rdram128x22    [0:7]   ();
    rbif #(.AW(5    ),      .DW(16))    rbif_rdram32x16     [0:1]   ();
    rbif #(.AW(10   ),      .DW(32))    rbif_bioram1kx32    [0:3]   ();
    rbif #(.AW(7    ),      .DW(32))    rbif_tx_fifo128x32  [0:0]   ();
    rbif #(.AW(7    ),      .DW(32))    rbif_rx_fifo128x32  [0:0]   ();
    rbif #(.AW(5    ),      .DW(19))    rbif_fifo32x19      [0:0]   ();
    rbif #(.AW(15   ),      .DW(36))    rbif_ifram32kx36    [0:1]   ();
    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_share   [0:0]   ();
    rbif #(.AW(11   ),      .DW(64))    rbif_udcmem_odb     [0:0]   ();
    rbif #(.AW(8    ),      .DW(64))    rbif_udcmem_256x64  [0:0]   ();
    rbif #(.AW(11   ),      .DW(64))    rbif_acram2kx64     [0:0]   ();
    rbif #(.AW(10   ),      .DW(36))    rbif_aoram1kx36     [0:1]   ();

    rbist_wrp u_rbist(
        .*
    );

endmodule
