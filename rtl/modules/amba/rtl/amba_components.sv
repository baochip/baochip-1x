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
//`include "amba_interface_def_v0.2.sv"


  //
  //  index
  //  ==
  //  ahb_mux
  //  apb_mux
  //  ahb_ifs2wire,ahb_wire2ifm,apb_ifs2wire,apb_wire2ifm
  //  ahbm_null ahbs_null apbm_null apbs_null axim_null axis_null
  //  ahb_sync
  //  ahb downsizer

  //  apb_bdg
  //  ahb_thru, apb_thru, axi_thru
  //  apb_sfr
  //  apb_sfrop
  //  define
  //  dummytb





  //
  //  ahb_mux
  //  ==

 /*
    module ahb_mux_orig #(
          parameter SLVCNT = 4,
          parameter DW=32,
          parameter AW=32,
          parameter [0:SLVCNT-1][AW-1:0]
          SLV_AMSK = {32'h0000ffff, 32'h0000ffff, 32'h0000ffff, 32'h0000ffff},
          SLV_ADDR = {32'h00000000, 32'h00010000, 32'h00020000, 32'h00030000}
     )
     (

        input bit           hclk,
        input bit           resetn,

        ahbif.slave         ahbslave,
        ahbif.master        ahbmaster[0:SLVCNT-1]

    );

        localparam HTRANS_IDLE = 2'h0;
        localparam HTRANS_NONSEQ = 2'h2;
        localparam HTRANS_SEQ = 2'h3;

        bit clk;
        assign clk = hclk;

      //
      //  ahb phase
      //  ==
      //

        bit                         ahbaddrphase, ahbdataphase;
        bit [0:SLVCNT-1][DW-1:0]    hrdatain;
        bit [0:SLVCNT-1]            hreadyall, hseldataphase, hrespall;
        bit [0:SLVCNT-1]            ahbmaster_sel, ahbmaster_sel_0;
        bit [0:SLVCNT-1][AW-1:0]    pm_SLV_AMSK, pm_SLV_ADDR, ahbslave_haddr_mask;
        bit [AW-1:0]                ahbslave_haddr;

        assign ahbaddrphase = ~( ahbslave.htrans == HTRANS_NONSEQ ) & ahbslave.hready & ahbslave.hsel & ahbslave.hreadym;
        `theregrn( ahbdataphase ) <= ahbaddrphase ? 1'b1 : ahbslave.hready ? 1'b0 : ahbdataphase;
        assign ahbslave_haddr = ahbslave.haddr;
        bit [31:0]                  pm_AW;
        assign pm_AW = AW;
        genvar i;
        generate
          for( i = 0; i < SLVCNT; i = i + 1) begin: GenRnd
            assign pm_SLV_AMSK[i] = ~SLV_AMSK[i];
            assign pm_SLV_ADDR[i] =  SLV_ADDR[i];
            assign ahbslave_haddr_mask[i] = ahbslave_haddr & pm_SLV_AMSK[i];
            assign ahbmaster_sel_0[i] = ( ahbslave_haddr_mask[i] == pm_SLV_ADDR[i] );
            assign ahbmaster_sel[i] = ahbmaster_sel_0[i] & ahbslave.hsel;
            `theregrn( hseldataphase[i] ) <= ahbaddrphase ? ahbmaster[i].hsel : ahbmaster[i].hready ? 0 : hseldataphase[i];
            assign hrespall[i]  = ahbmaster[i].hresp  & hseldataphase[i];
        	assign hreadyall[i] = ahbmaster[i].hready & hseldataphase[i];
        	assign hrdatain[i] = ahbmaster[i].hrdata;

            assign ahbmaster[i].hsel        = ahbmaster_sel[i];// ( ahbslave.haddr & ~SLV_AMSK[i] == SLV_ADDR[i] ) & ahbslave.hsel;
            assign ahbmaster[i].haddr       = ahbslave.haddr        ;
            assign ahbmaster[i].htrans      = ahbslave.htrans       ;
            assign ahbmaster[i].hwrite      = ahbslave.hwrite       ;
            assign ahbmaster[i].hsize       = ahbslave.hsize        ;
            assign ahbmaster[i].hburst      = ahbslave.hburst       ;
            assign ahbmaster[i].hprot       = ahbslave.hprot        ;
            assign ahbmaster[i].hmaster     = ahbslave.hmaster      ;
            assign ahbmaster[i].hwdata      = ahbslave.hwdata       ;
            assign ahbmaster[i].hmasterlock = ahbslave.hmasterlock  ;
            assign ahbmaster[i].hreadym    = ahbslave.hreadym     ;
          end
        endgenerate

        assign ahbslave.hready = |hseldataphase ? |hreadyall : 1'b1;
        assign ahbslave.hrdata = fnhrdata( hrdatain, hseldataphase );
        assign ahbslave.hresp  = |hrespall;

        function bit [DW-1:0] fnhrdata(input bit [0:SLVCNT-1][DW-1:0]    fnhrdatain, input bit [0:SLVCNT-1] fnhseldataphase);
            bit [DW-1:0] fnmux;
            int fni;
            for(fni = 0; fni < SLVCNT; fni = fni + 1 ) fnmux = fnmux | ( fnhrdatain[fni] & {DW{fnhseldataphase[fni]}} );
            fnhrdata = fnmux;
        endfunction

    endmodule

    module ahb_mux #(
      parameter AW=16,
      parameter DECAW=4,
      parameter DW=32
     )
     (

      input bit             hclk,
      input bit             resetn,

        ahbif.slave         ahbslave,
        ahbif.master        ahbmaster[0:2**DECAW-1]
    );


        localparam SLVCNT = 2**DECAW;
        localparam SAW = AW-DECAW;
        bit [31:0]                  pm_AW;
        assign pm_AW = AW;

        //bit [0:SLVCNT-1][AW-1:0]    slv_amsk, slv_addr;
        function bit [0:SLVCNT-1][AW-1:0] fnslvaddr();
            bit [0:SLVCNT-1][AW-1:0] fntemp;
            int fni;
            for(fni = 0; fni < SLVCNT; fni = fni + 1 ) fntemp[fni] = { fni , {(SAW){1'b0}}};
            fnslvaddr = fntemp;
        endfunction

        localparam [0:SLVCNT-1][AW-1:0] slv_amsk = {SLVCNT{ {(DECAW){1'b0}}, {(SAW){1'b1}}}};
        localparam [0:SLVCNT-1][AW-1:0] slv_addr = fnslvaddr();
        bit [0:SLVCNT-1][AW-1:0] pm_slv_amsk;   assign pm_slv_amsk = slv_amsk;
        bit [0:SLVCNT-1][AW-1:0] pm_slv_addr;   assign pm_slv_addr = slv_addr;
    ahb_mux_orig  #(
        .SLVCNT             (SLVCNT),
        .AW                 (AW),
        .DW                 (DW),
        .SLV_AMSK           (slv_amsk),
        .SLV_ADDR           (slv_addr)
     )uahb_mux_orig
     (

        .hclk               (hclk),
        .resetn             (resetn),

        .ahbslave             (ahbslave),
        .ahbmaster            (ahbmaster)
    );
    endmodule
*/

  //
  //  ahb_mux
  //  ==

module ahb_mux3 #(
      parameter AW=16,
      parameter DW=32
)(

      input bit             hclk,
      input bit             resetn,
      ahbif.slave         ahbslave[0:2],
      ahbif.master        ahbmaster
);

    logic [31:0] ahbm_haddr32;
    assign ahbmaster.haddr = ahbm_haddr32;
    logic [1:0] msel;

cmsdk_ahb_master_mux u
 (
  // --------------------------------------------------------------------------------
  // I/O declaration
  // --------------------------------------------------------------------------------

  .HCLK     (hclk),       // Clock
  .HRESETn  (resetn),    // Reset

  // AHB connection to master #0
  .HSELS0       (ahbslave[0].hsel       ),
  .HADDRS0      (ahbslave[0].haddr | '0 ),
  .HTRANSS0     (ahbslave[0].htrans     ),
  .HSIZES0      (ahbslave[0].hsize      ),
  .HWRITES0     (ahbslave[0].hwrite     ),
  .HREADYS0     (ahbslave[0].hreadym    ),
  .HPROTS0      (ahbslave[0].hprot      ),
  .HBURSTS0     (ahbslave[0].hburst     ),
  .HMASTLOCKS0  (ahbslave[0].hmasterlock  ),
  .HWDATAS0     (ahbslave[0].hwdata     ),
  .HREADYOUTS0  (ahbslave[0].hready     ),
  .HRESPS0      (ahbslave[0].hresp      ),
  .HRDATAS0     (ahbslave[0].hrdata     ),

  // AHB connection to master #1
  .HSELS1       (ahbslave[1].hsel       ),
  .HADDRS1      (ahbslave[1].haddr | '0 ),
  .HTRANSS1     (ahbslave[1].htrans     ),
  .HSIZES1      (ahbslave[1].hsize      ),
  .HWRITES1     (ahbslave[1].hwrite     ),
  .HREADYS1     (ahbslave[1].hreadym    ),
  .HPROTS1      (ahbslave[1].hprot      ),
  .HBURSTS1     (ahbslave[1].hburst     ),
  .HMASTLOCKS1  (ahbslave[1].hmasterlock  ),
  .HWDATAS1     (ahbslave[1].hwdata     ),
  .HREADYOUTS1  (ahbslave[1].hready     ),
  .HRESPS1      (ahbslave[1].hresp      ),
  .HRDATAS1     (ahbslave[1].hrdata     ),

  // AHB connection to master #2
  .HSELS2       (ahbslave[2].hsel       ),
  .HADDRS2      (ahbslave[2].haddr | '0 ),
  .HTRANSS2     (ahbslave[2].htrans     ),
  .HSIZES2      (ahbslave[2].hsize      ),
  .HWRITES2     (ahbslave[2].hwrite     ),
  .HREADYS2     (ahbslave[2].hreadym    ),
  .HPROTS2      (ahbslave[2].hprot      ),
  .HBURSTS2     (ahbslave[2].hburst     ),
  .HMASTLOCKS2  (ahbslave[2].hmasterlock  ),
  .HWDATAS2     (ahbslave[2].hwdata     ),
  .HREADYOUTS2  (ahbslave[2].hready     ),
  .HRESPS2      (ahbslave[2].hresp      ),
  .HRDATAS2     (ahbslave[2].hrdata     ),

  // AHB output master port
  .HSELM        (ahbmaster.hsel          ),
  .HADDRM       (ahbm_haddr32       ),
  .HTRANSM      (ahbmaster.htrans        ),
  .HSIZEM       (ahbmaster.hsize         ),
  .HWRITEM      (ahbmaster.hwrite        ),
  .HREADYM      (ahbmaster.hreadym       ),
  .HPROTM       (ahbmaster.hprot         ),
  .HBURSTM      (ahbmaster.hburst        ),
  .HMASTLOCKM   (ahbmaster.hmasterlock     ),
  .HWDATAM      (ahbmaster.hwdata        ),
  .HREADYOUTM   (ahbmaster.hready        ),
  .HRESPM       (ahbmaster.hresp         ),
  .HRDATAM      (ahbmaster.hrdata        ),

  .HMASTERM     (msel)
  );

 logic [0:2][7:0] hmaster;
 assign hmaster[0] = ahbslave[0].hmaster | '0;
 assign hmaster[1] = ahbslave[1].hmaster | '0;
 assign hmaster[2] = ahbslave[2].hmaster | '0;

 assign ahbmaster.hmaster = hmaster[msel];
 assign ahbmaster.hauser = (msel == 2) ? ahbslave[2].hauser : (msel == 1) ? ahbslave[1].hauser : ahbslave[0].hauser ;
 assign ahbmaster.hwuser = (msel == 2) ? ahbslave[2].hwuser : (msel == 1) ? ahbslave[1].hwuser : ahbslave[0].hwuser ;

endmodule

  //
  //  apb_mux
  //  ==

    module apb_mux #(
      parameter PAW=16,
      parameter DECAW=4,
      parameter DW=32
     )
     (
        apbif.slave         apbslave,
        apbif.master        apbmaster[0:2**DECAW-1]
    );

        localparam SLVCNT = 2**DECAW;
        localparam SAW = PAW-DECAW;

        bit [0:SLVCNT-1] pselall, preadyall, pslverrall;
        bit [0:SLVCNT-1][DW-1:0]    prdataall;
        bit [DECAW-1:0]  paddrdec;

        assign paddrdec = apbslave.paddr[PAW-1:SAW] ;

        genvar i;
        generate
          for( i = 0; i < SLVCNT; i = i + 1) begin: GenRnd
            assign apbmaster[i].psel     =  apbslave.psel & ( paddrdec == i );
            assign apbmaster[i].paddr    =  apbslave.paddr;
            assign apbmaster[i].penable  =  apbslave.penable;
            assign apbmaster[i].pwrite   =  apbslave.pwrite;
            assign apbmaster[i].pstrb    =  apbslave.pstrb;
            assign apbmaster[i].pprot    =  apbslave.pprot;
            assign apbmaster[i].pwdata   =  apbslave.pwdata;
            assign apbmaster[i].apbactive=  apbslave.apbactive;

            assign pselall[i]   = apbmaster[i].psel;
            assign pslverrall[i]   = apbmaster[i].pslverr & apbmaster[i].psel;
        	assign preadyall[i] = apbmaster[i].pready  & apbmaster[i].psel;
        	assign prdataall[i] = apbmaster[i].prdata;

          end
        endgenerate

        assign apbslave.pready  = |preadyall;
        assign apbslave.pslverr = |pslverrall;
//        assign apbslave.prdata  = fnprdata( prdataall, pselall );
    /*
        function bit [DW-1:0] fnprdata(input bit [0:SLVCNT-1][DW-1:0]    fnprdatain, input bit [0:SLVCNT-1] fnpsel);
            bit [DW-1:0] fnmux = 0;
            int fni;
            for(fni = 0; fni < SLVCNT; fni = fni + 1 ) fnmux = fnmux | ( fnprdatain[fni] & {DW{fnpsel[fni]}} );
            fnprdata = fnmux;
        endfunction
    */
        always_comb begin
            apbslave.prdata = '0;
            for (int i = 0; i < SLVCNT; i++) begin
                apbslave.prdata = apbslave.prdata | ( pselall[i] ? prdataall[i] : '0 );
            end
        end


    endmodule

  //
  //  ahb_ifs2wire,ahb_wire2ifm,apb_ifs2wire,apb_wire2ifm
  //  ==

    module ahb_ifs2wire #(
      parameter AW=32,
      parameter DW=32
     )(
        ahbif.slave             ahbslave,
        output  logic           hsel,           // Slave Select
        output  logic  [AW-1:0] haddr,          // Address bus
        output  logic  [1:0]    htrans,         // Transfer type
        output  logic           hwrite,         // Transfer direction
        output  logic  [2:0]    hsize,          // Transfer size
        output  logic  [2:0]    hburst,         // Burst type
        output  logic  [3:0]    hprot,          // Protection control
        output  logic  [3:0]    hmaster,        //Master select
        output  logic  [DW-1:0] hwdata,         // Write data
        output  logic           hmasterlock,    // Locked Sequence
        output  logic           hreadym,       // Transfer done
        input   logic  [DW-1:0] hrdata,         // Read data bus
        input   logic           hready,         // HREADY feedback
        input   logic           hresp          // Transfer response
    );

        assign hsel        = ahbslave.hsel        ;
        assign haddr       = ahbslave.haddr       ;
        assign htrans      = ahbslave.htrans      ;
        assign hwrite      = ahbslave.hwrite      ;
        assign hsize       = ahbslave.hsize       ;
        assign hburst      = ahbslave.hburst      ;
        assign hprot       = ahbslave.hprot       ;
        assign hmaster     = ahbslave.hmaster     ;
        assign hwdata      = ahbslave.hwdata      ;
        assign hmasterlock = ahbslave.hmasterlock ;
        assign hreadym    = ahbslave.hreadym    ;
        assign ahbslave.hrdata      = hrdata      ;
        assign ahbslave.hready      = hready      ;
        assign ahbslave.hresp       = hresp       ;

    endmodule

    module ahb_wire2ifm #(
      parameter AW=32,
      parameter DW=32,
      parameter UW=4
     )(
        ahbif.master            ahbmaster,
        input   logic           hsel,           // Slave Select
        input   logic  [AW-1:0] haddr,          // Address bus
        input   logic  [1:0]    htrans,         // Transfer type
        input   logic           hwrite,         // Transfer direction
        input   logic  [2:0]    hsize,          // Transfer size
        input   logic  [2:0]    hburst,         // Burst type
        input   logic  [3:0]    hprot,          // Protection control
        input   logic  [3:0]    hmaster,        //Master select
        input   logic  [DW-1:0] hwdata,         // Write data
        input   logic           hmasterlock,    // Locked Sequence
        input   logic           hreadym,       // Transfer done
        output  logic  [DW-1:0] hrdata,         // Read data bus
        output  logic           hready,         // HREADY feedback
        output  logic           hresp,         // Transfer response
        input   logic  [UW-1:0] hauser,
        input   logic  [UW-1:0] hwuser,
        output  logic  [UW-1:0] hruser
    );

        assign ahbmaster.hsel        = hsel        ;
        assign ahbmaster.haddr       = haddr       ;
        assign ahbmaster.htrans      = htrans      ;
        assign ahbmaster.hwrite      = hwrite      ;
        assign ahbmaster.hsize       = hsize       ;
        assign ahbmaster.hburst      = hburst      ;
        assign ahbmaster.hprot       = hprot       ;
        assign ahbmaster.hmaster     = hmaster     ;
        assign ahbmaster.hwdata      = hwdata      ;
        assign ahbmaster.hmasterlock = hmasterlock ;
        assign ahbmaster.hreadym     = hreadym     ;
        assign hrdata      = ahbmaster.hrdata      ;
        assign hready      = ahbmaster.hready      ;
        assign hresp       = ahbmaster.hresp       ;

        assign ahbmaster.hauser      = hauser      ;
        assign ahbmaster.hwuser      = hwuser      ;
        assign hruser      = ahbmaster.hruser      ;

    endmodule

    module apb_ifs2wire #(
      parameter AW=16,
      parameter DW=32
     )(
        apbif.slave             apbslave,
        output logic            psel         ,
        output logic [AW-1:0]   paddr        ,
        output logic            penable      ,
        output logic            pwrite       ,
        output logic [3:0]      pstrb        ,
        output logic [2:0]      pprot        ,
        output logic [31:0]     pwdata       ,
        output logic            apbactive    ,
        input  logic [DW-1:0]   prdata       ,
        input  logic            pready       ,
        input  logic            pslverr
     );

        assign psel        = apbslave.psel          ;
        assign paddr       = apbslave.paddr         ;
        assign penable     = apbslave.penable       ;
        assign pwrite      = apbslave.pwrite        ;
        assign pstrb       = apbslave.pstrb         ;
        assign pprot       = apbslave.pprot         ;
        assign pwdata      = apbslave.pwdata        ;
        assign apbactive   = apbslave.apbactive     ;
        assign apbslave.prdata       = prdata       ;
        assign apbslave.pready       = pready       ;
        assign apbslave.pslverr      = pslverr      ;

    endmodule

    module apb_wire2ifm #(
      parameter AW=16,
      parameter DW=32
     )(
        apbif.master            apbmaster,
        input  logic            psel         ,
        input  logic [AW-1:0]   paddr        ,
        input  logic            penable      ,
        input  logic            pwrite       ,
        input  logic [3:0]      pstrb        ,
        input  logic [2:0]      pprot        ,
        input  logic [31:0]     pwdata       ,
        input  logic            apbactive    ,
        output logic [DW-1:0]   prdata       ,
        output logic            pready       ,
        output logic            pslverr
    );

        assign apbmaster.psel      = psel          ;
        assign apbmaster.paddr     = paddr         ;
        assign apbmaster.penable   = penable       ;
        assign apbmaster.pwrite    = pwrite        ;
        assign apbmaster.pstrb     = pstrb         ;
        assign apbmaster.pprot     = pprot         ;
        assign apbmaster.pwdata    = pwdata        ;
        assign apbmaster.apbactive = apbactive     ;
        assign prdata       = apbmaster.prdata       ;
        assign pready       = apbmaster.pready       ;
        assign pslverr      = apbmaster.pslverr      ;

    endmodule

  //
  //  ahbm_null ahbs_null apbm_null apbs_null axim_null axis_null
  //  ==

    module ahbm_null( ahbif.master ahbmaster );
        assign ahbmaster.hsel        = 0 ;
        assign ahbmaster.haddr       = 0 ;
        assign ahbmaster.htrans      = 0 ;
        assign ahbmaster.hwrite      = 0 ;
        assign ahbmaster.hsize       = 0 ;
        assign ahbmaster.hburst      = 0 ;
        assign ahbmaster.hprot       = 0 ;
        assign ahbmaster.hmaster     = 0 ;
        assign ahbmaster.hwdata      = 0 ;
        assign ahbmaster.hmasterlock = 0 ;
        assign ahbmaster.hreadym    = 0 ;
        assign ahbmaster.hauser    = 0 ;
        assign ahbmaster.hwuser    = 0 ;
    endmodule

    module ahbs_null ( ahbif.slave  ahbslave );
        assign ahbslave.hrdata      = 0      ;
        assign ahbslave.hready      = 1      ;
        assign ahbslave.hresp       = 0      ;
        assign ahbslave.hruser       = 0      ;
    endmodule

    module ahbs_nulls #(SLVCNT=4)( ahbif.slave  ahbslave[0:SLVCNT-1]  );
        genvar i;
        generate
        	for( i = 0; i < SLVCNT; i = i + 1) begin: Gencode
                ahbs_null unull( ahbslave[i] );
        	end
   endgenerate
    endmodule

    module apbm_null( apbif.master apbmaster );
        assign apbmaster.psel      = 0 ;
        assign apbmaster.paddr     = 0 ;
        assign apbmaster.penable   = 0 ;
        assign apbmaster.pwrite    = 0 ;
        assign apbmaster.pstrb     = 0 ;
        assign apbmaster.pprot     = 0 ;
        assign apbmaster.pwdata    = 0 ;
        assign apbmaster.apbactive = 0 ;
    endmodule

    module apbs_null ( apbif.slave  apbslave );
        assign apbslave.prdata       = 0        ;
        assign apbslave.pready       = 1        ;
        assign apbslave.pslverr      = 0        ;
    endmodule

    module apbs_nulls #(SLVCNT=4)( apbif.slave  apbslave[0:SLVCNT-1]  );
        genvar i;
        generate
        	for( i = 0; i < SLVCNT; i = i + 1) begin: Gencode
                apbs_null unull( apbslave[i] );
        	end
        endgenerate
    endmodule

    module axim_null( axiif.master aximaster );

        assign aximaster.arvalid = '0;
        assign aximaster.araddr = '0;
        assign aximaster.arid = '0;
        assign aximaster.arburst = '0;
        assign aximaster.arlen = '0;
        assign aximaster.arsize = '0;
        assign aximaster.arlock = '0;
        assign aximaster.arcache = '0;
        assign aximaster.arprot = '0;
        assign aximaster.armaster = '0;
        assign aximaster.arinner = '0;
        assign aximaster.arshare = '0;
        assign aximaster.aruser = '0;
        assign aximaster.awvalid = '0;
        assign aximaster.awaddr = '0;
        assign aximaster.awid = '0;
        assign aximaster.awburst = '0;
        assign aximaster.awlen = '0;
        assign aximaster.awsize = '0;
        assign aximaster.awlock = '0;
        assign aximaster.awcache = '0;
        assign aximaster.awprot = '0;
        assign aximaster.awmaster = '0;
        assign aximaster.awinner = '0;
        assign aximaster.awshare = '0;
        assign aximaster.awsparse = '0;
        assign aximaster.awuser = '0;
        assign aximaster.rready = '1;
        assign aximaster.wvalid = '0;
        assign aximaster.wid = '0;
        assign aximaster.wlast = '0;
        assign aximaster.wstrb = '0;
        assign aximaster.wdata = '0;
        assign aximaster.wuser = '0;
        assign aximaster.bready = '1;


    endmodule

    module axis_null( axiif.slave axislave );

        assign axislave.bvalid = '0;
        assign axislave.bid = '0;
        assign axislave.bresp = '0;
        assign axislave.buser = '0;
        assign axislave.arready = '1;
        assign axislave.awready = '1;
        assign axislave.rvalid = '0;
        assign axislave.rid = '0;
        assign axislave.rlast = '0;
        assign axislave.rresp = '0;
        assign axislave.rdata = '0;
        assign axislave.ruser = '0;
        assign axislave.wready = '1;

    endmodule


    module ahbsim#(
        parameter AW=32,
        parameter DW=32,
        parameter IDW=4,
        parameter UW=4
    )(
        input  logic         hclk        ,
        input  logic         resetn      ,
        ahbif.slave     ahbs    ,
        ahbif.master    ahbm
    );

`ifdef SIM
        ahbif #(.AW(AW),.DW(DW),.IDW(IDW),.UW(UW)) ahbs3[0:2]();
        ahbif #(.AW(AW),.DW(DW),.IDW(IDW),.UW(UW)) ahbsim();

        ahb_mux3 #(.AW(32))uahb_mux (.hclk(hclk),.resetn(resetn), .ahbslave(ahbs3),.ahbmaster(ahbm));


        ahb_thru #(.AW(AW),.DW(DW)) u0(ahbs,  ahbs3[0]);
        ahbm_null u2(ahbs3[2]);

        logic           sim_hsel        ;     // Slave Select
        logic  [AW-1:0] sim_haddr       ;     // Address bus
        logic  [1:0]    sim_htrans      ;     // Transfer type
        logic           sim_hwrite      ;     // Transfer direction
        logic  [2:0]    sim_hsize       ;     // Transfer size
        logic  [2:0]    sim_hburst      ;     // Burst type
        logic  [3:0]    sim_hprot       ;     // Protection control
        logic  [3:0]    sim_hmaster     ;     //Master select
        logic  [DW-1:0] sim_hwdata      ;     // Write data
        logic           sim_hmasterlock ;     // Locked Sequence
        logic           sim_hreadym     ;    // Transfer done
        logic  [DW-1:0] sim_hrdata      ;
        logic           sim_hready      ;
        logic           sim_hresp       ;
        logic  [UW-1:0] sim_hauser      ;
        logic  [UW-1:0] sim_hruser      ;
        logic  [UW-1:0] sim_hwuser      ;

        ahb_wire2ifm #(.AW(AW),.DW(DW)) usim(
            .ahbmaster    ( ahbs3[1]        ),
            .hsel         ( sim_hsel        ),
            .haddr        ( sim_haddr       ),
            .htrans       ( sim_htrans      ),
            .hwrite       ( sim_hwrite      ),
            .hsize        ( sim_hsize       ),
            .hburst       ( sim_hburst      ),
            .hprot        ( sim_hprot       ),
            .hmaster      ( sim_hmaster     ),
            .hwdata       ( sim_hwdata      ),
            .hmasterlock  ( sim_hmasterlock ),
            .hreadym      ( sim_hreadym     ),
            .hrdata       ( sim_hrdata      ),
            .hready       ( sim_hready      ),
            .hresp        ( sim_hresp       ),
            .hauser       ( sim_hauser      ),
            .hruser       ( sim_hruser      ),
            .hwuser       ( sim_hwuser      )
        );

//        assign sim_hsel        = ahbs.hsel        ;
        assign sim_hburst      = ahbs.hburst      ;
        assign sim_hmaster     = ahbs.hmaster     ;
        assign sim_hreadym     = ahbs.hreadym     ;
        assign sim_hauser      = ahbs.hauser      ;
        assign sim_hwuser      = ahbs.hwuser      ;

        initial begin
            sim_hsel        = '0 ;
            sim_haddr       = '0 ;
            sim_htrans      = '0 ;
            sim_hwrite      = '0 ;
            sim_hsize       = '0 ;
            sim_hprot       = '0 ;
            sim_hwdata      = '0 ;
            sim_hmasterlock = '0 ;
        end
//        assign ahbm.hauser = ahbs.hauser;
//        assign ahbm.hwuser = ahbs.hwuser;
//        assign ahbs.hruser = ahbm.hruser;
`else
        ahb_thru #(.AW(AW),.DW(DW)) u0(ahbs,  ahbm);
`endif

    endmodule : ahbsim

  //
  //  ahb_sync
  //  ==
    module ahb_sync#(
        parameter AW = 32,
        parameter DW = 32,
        parameter SYNCDOWN = 1,
        parameter SYNCUP = 0,
        parameter MW = 4
    ) (
        input  logic         hclk        ,
        input  logic         resetn      ,
        input  logic         hclken      ,
        ahbif.slave     ahbslave    ,
        ahbif.master    ahbmaster
    );
    wire    bwerr;
    bit     [31:0]   uahbcore_HADDRM;

`ifndef AMBCOMP_SMALL
    genvar i;
    generate
    	if( SYNCDOWN ) begin: gen_syncdown


    cmsdk_ahb_to_ahb_sync_down
    #(
      .AW(AW),
      .DW(DW),
      .MW(MW),
      .BURST(1)
    )uahbcore(
         .HCLK            (hclk),
         .HCLKEN          (hclken),
         .HRESETn         (resetn),
          //bridge slave interface (fast AHB)
         .HSELS           (ahbslave.hsel),
         .HADDRS          (ahbslave.haddr|32'h0),
         .HTRANSS         (ahbslave.htrans),
         .HSIZES          (ahbslave.hsize),
         .HWRITES         (ahbslave.hwrite),
         .HREADYS         (ahbslave.hreadym),
         .HPROTS          (ahbslave.hprot),
         .HMASTERS        (ahbslave.hmaster),
         .HMASTLOCKS      (ahbslave.hmasterlock),
         .HWDATAS         (ahbslave.hwdata),
         .HBURSTS         (ahbslave.hburst),

         .HREADYOUTS      (ahbslave.hready),
         .HRESPS          (ahbslave.hresp),
         .HRDATAS         (ahbslave.hrdata),

          // bridge master interface (slow AHB)
         .HADDRM          (uahbcore_HADDRM),
         .HTRANSM         (ahbmaster.htrans),
         .HSIZEM          (ahbmaster.hsize),
         .HWRITEM         (ahbmaster.hwrite),
         .HPROTM          (ahbmaster.hprot),
         .HMASTLOCKM      (ahbmaster.hmasterlock),
         .HWDATAM         (ahbmaster.hwdata),
         .HMASTERM        (ahbmaster.hmaster),
         .HBURSTM         (ahbmaster.hburst),

         .HREADYM         (ahbmaster.hready),
         .HRESPM          (ahbmaster.hresp),
         .HRDATAM         (ahbmaster.hrdata),
         .BWERR           (bwerr)
       );
    	end
        else if( SYNCUP ) begin: gen_syncup
    cmsdk_ahb_to_ahb_sync_up
    #(
      .AW(AW),
      .DW(DW),
      .MW(MW),
      .BURST(1)
    )uahbcore(
         .HCLK            (hclk),
         .HCLKEN          (hclken),
         .HRESETn         (resetn),
          //bridge slave interface (fast AHB)
         .HSELS           (ahbslave.hsel),
         .HADDRS          (ahbslave.haddr|32'h0),
         .HTRANSS         (ahbslave.htrans),
         .HSIZES          (ahbslave.hsize),
         .HWRITES         (ahbslave.hwrite),
         .HREADYS         (ahbslave.hreadym),
         .HPROTS          (ahbslave.hprot),
         .HMASTERS        (ahbslave.hmaster),
         .HMASTLOCKS      (ahbslave.hmasterlock),
         .HWDATAS         (ahbslave.hwdata),
         .HBURSTS         (ahbslave.hburst),

         .HREADYOUTS      (ahbslave.hready),
         .HRESPS          (ahbslave.hresp),
         .HRDATAS         (ahbslave.hrdata),

          // bridge master interface (slow AHB)
         .HADDRM          (uahbcore_HADDRM),
         .HTRANSM         (ahbmaster.htrans),
         .HSIZEM          (ahbmaster.hsize),
         .HWRITEM         (ahbmaster.hwrite),
         .HPROTM          (ahbmaster.hprot),
         .HMASTLOCKM      (ahbmaster.hmasterlock),
         .HWDATAM         (ahbmaster.hwdata),
         .HMASTERM        (ahbmaster.hmaster),
         .HBURSTM         (ahbmaster.hburst),

         .HREADYM         (ahbmaster.hready),
         .HRESPM          (ahbmaster.hresp),
         .HRDATAM         (ahbmaster.hrdata),
         .BWERR           (bwerr)
       );
        end
    	else begin: gen_nosyncdown
    cmsdk_ahb_to_ahb_sync
    #(
      .AW(AW),
      .DW(DW),
      .MW(MW),
      .BURST(1)
    )uahbcore(
         .HCLK            (hclk),
//         .HCLKEN          (hclken),
         .HRESETn         (resetn),
          //bridge slave interface (fast AHB)
         .HSELS           (ahbslave.hsel),
         .HADDRS          (ahbslave.haddr|32'h0),
         .HTRANSS         (ahbslave.htrans),
         .HSIZES          (ahbslave.hsize),
         .HWRITES         (ahbslave.hwrite),
         .HREADYS         (ahbslave.hreadym),
         .HPROTS          (ahbslave.hprot),
         .HMASTERS        (ahbslave.hmaster),
         .HMASTLOCKS      (ahbslave.hmasterlock),
         .HWDATAS         (ahbslave.hwdata),
         .HBURSTS         (ahbslave.hburst),

         .HREADYOUTS      (ahbslave.hready),
         .HRESPS          (ahbslave.hresp),
         .HRDATAS         (ahbslave.hrdata),

          // bridge master interface (slow AHB)
         .HADDRM          (uahbcore_HADDRM),
         .HTRANSM         (ahbmaster.htrans),
         .HSIZEM          (ahbmaster.hsize),
         .HWRITEM         (ahbmaster.hwrite),
         .HPROTM          (ahbmaster.hprot),
         .HMASTLOCKM      (ahbmaster.hmasterlock),
         .HWDATAM         (ahbmaster.hwdata),
         .HMASTERM        (ahbmaster.hmaster),
         .HBURSTM         (ahbmaster.hburst),

         .HREADYM         (ahbmaster.hready),
         .HRESPM          (ahbmaster.hresp),
         .HRDATAM         (ahbmaster.hrdata)
       );
    	end
    endgenerate
`endif // AMBCOMP_SMALL
    assign ahbmaster.haddr = uahbcore_HADDRM;
    assign ahbmaster.hsel = 1;
    assign ahbmaster.hreadym = ahbmaster.hready;
    assign ahbmaster.hauser = ahbslave.hauser;
    assign ahbmaster.hwuser = ahbslave.hwuser;
    assign ahbslave.hruser = ahbmaster.hruser;
endmodule


  //
  //  ahb downsizer
  //  ==
    module ahb_downsizer (
        input  logic         hclk        ,
        input  logic         resetn      ,
        ahbif.slave     ahbslave    ,
        ahbif.master    ahbmaster
    );
    bit     [31:0]   uahbcore_HADDRM;
    assign ahbmaster.haddr = uahbcore_HADDRM;

    cmsdk_ahb_downsizer64
    #(.HMASTER_WIDTH(4))
    uahbcore (
         .HCLK            (hclk),
         .HRESETn         (resetn),
          //bridge slave interface (fast AHB)
         .HSELS           (ahbslave.hsel),
         .HADDRS          (ahbslave.haddr|32'h0),
         .HTRANSS         (ahbslave.htrans),
         .HSIZES          (ahbslave.hsize),
         .HWRITES         (ahbslave.hwrite),
         .HREADYS         (ahbslave.hreadym),
         .HPROTS          (ahbslave.hprot),
         .HMASTERS        (ahbslave.hmaster),
         .HMASTLOCKS      (ahbslave.hmasterlock),
         .HWDATAS         (ahbslave.hwdata),
         .HBURSTS         (ahbslave.hburst),

         .HREADYOUTS      (ahbslave.hready),
         .HRESPS          (ahbslave.hresp),
         .HRDATAS         (ahbslave.hrdata),

          // bridge master interface (slow AHB)
         .HSELM           (ahbmaster.hsel),
         .HADDRM          (uahbcore_HADDRM),
         .HTRANSM         (ahbmaster.htrans),
         .HSIZEM          (ahbmaster.hsize),
         .HWRITEM         (ahbmaster.hwrite),
         .HPROTM          (ahbmaster.hprot),
         .HMASTLOCKM      (ahbmaster.hmasterlock),
         .HWDATAM         (ahbmaster.hwdata),
         .HMASTERM        (ahbmaster.hmaster),
         .HBURSTM         (ahbmaster.hburst),
         .HREADYM         (ahbmaster.hreadym),
         .HRESPM          (ahbmaster.hresp),
         .HRDATAM         (ahbmaster.hrdata),
         .HREADYOUTM      (ahbmaster.hready),
         .*
       );
    endmodule



  //
  //  apb_bdg
  //  ==



    module apb_bdg#(
        parameter AW = 32,
        parameter DW = 32,
        parameter PAW = 16
    ) (
        input  wire         hclk        ,
        input  wire         resetn      ,
        input  wire         pclken      ,
        ahbif.slave     ahbslave    ,
        apbif.master    apbmaster
    );

`ifndef AMBCOMP_SMALL
    cmsdk_ahb_to_apb #( .ADDRWIDTH(PAW)
    )uapbbdg(
       .HCLK          ( hclk                    ),      // Clock
       .HRESETn       ( resetn                  ),   // Reset
       .PCLKEN        ( pclken                  ),    // APB clock enable signal

       .HSEL          ( ahbslave.hsel           ),      // Device select
       .HADDR         ( ahbslave.haddr[PAW-1:0] ),     // Address
       .HTRANS        ( ahbslave.htrans         ),    // Transfer control
       .HSIZE         ( ahbslave.hsize          ),     // Transfer size
       .HPROT         ( ahbslave.hprot          ),     // Protection control
       .HWRITE        ( ahbslave.hwrite         ),    // Write control
       .HREADY        ( ahbslave.hready         ),    // Transfer phase done
       .HWDATA        ( ahbslave.hwdata         ),    // Write data

       .HREADYOUT     ( ahbslave.hready         ), // Device ready
       .HRDATA        ( ahbslave.hrdata         ),    // Read data output
       .HRESP         ( ahbslave.hresp          ),     // Device response
                   // APB Output
       .PADDR         ( apbmaster.paddr         ),     // APB Address
       .PENABLE       ( apbmaster.penable       ),// APB Enable
       .PWRITE        ( apbmaster.pwrite        ),// APB Write
       .PSTRB         ( apbmaster.pstrb         ),// APB Byte Strobe
       .PPROT         ( apbmaster.pprot         ),// APB Prot
       .PWDATA        ( apbmaster.pwdata        ),// APB write data
       .PSEL          ( apbmaster.psel          ),// APB Select

       .APBACTIVE     ( apbmaster.apbactive     ), // APB bus is active, for clock gating
                   // of APB bus

                   // APB Input
       .PRDATA        ( apbmaster.prdata        ),    // Read data for each APB slave
       .PREADY        ( apbmaster.pready        ),    // Ready for each APB slave
       .PSLVERR       ( apbmaster.pslverr       )
       );  // Error state for each APB slave
`endif // AMBCOMP_SMALL

    endmodule

  //
  //  ahb_thru, apb_thru, axi_thru
  //  ==

    module ahb_thru #(
      parameter AW=32,
      parameter DW=32
     )(
        ahbif.slave             ahbslave,
        ahbif.master            ahbmaster
    );


    `ifdef SIM
        bit ahben;
        initial ahben = 1;
    `else
        bit ahben;
        assign ahben = 1;
    `endif

        assign ahbmaster.hsel        = ahben & ahbslave.hsel        ;
        assign ahbmaster.haddr       = ahbslave.haddr       ;
        assign ahbmaster.htrans      = ahben ? ahbslave.htrans : '0      ;
        assign ahbmaster.hwrite      = ahbslave.hwrite      ;
        assign ahbmaster.hsize       = ahbslave.hsize       ;
        assign ahbmaster.hburst      = ahbslave.hburst      ;
        assign ahbmaster.hprot       = ahbslave.hprot       ;
        assign ahbmaster.hmaster     = ahbslave.hmaster     ;
        assign ahbmaster.hwdata      = ahbslave.hwdata      ;
        assign ahbmaster.hmasterlock = ahbslave.hmasterlock ;
        assign ahbmaster.hreadym    = ahbslave.hreadym    ;
        assign ahbslave.hrdata       = ahbmaster.hrdata     ;
        assign ahbslave.hready       = ahbmaster.hready     ;
        assign ahbslave.hresp        = ahbmaster.hresp      ;
        assign ahbmaster.hauser = ahbslave.hauser;
        assign ahbmaster.hwuser = ahbslave.hwuser;
        assign ahbslave.hruser = ahbmaster.hruser;

    endmodule

    module ahb_gate #(
      parameter AW=32,
      parameter DW=32
     )(
        input logic ahben,
        ahbif.slave             ahbslave,
        ahbif.master            ahbmaster
    );

        assign ahbmaster.hsel        = ahben & ahbslave.hsel        ;
        assign ahbmaster.haddr       = ahbslave.haddr       ;
        assign ahbmaster.htrans      = ahben ? ahbslave.htrans : '0      ;
        assign ahbmaster.hwrite      = ahbslave.hwrite      ;
        assign ahbmaster.hsize       = ahbslave.hsize       ;
        assign ahbmaster.hburst      = ahbslave.hburst      ;
        assign ahbmaster.hprot       = ahbslave.hprot       ;
        assign ahbmaster.hmaster     = ahbslave.hmaster     ;
        assign ahbmaster.hwdata      = ahbslave.hwdata      ;
        assign ahbmaster.hmasterlock = ahbslave.hmasterlock ;
        assign ahbmaster.hreadym    = ahbslave.hreadym    ;
        assign ahbslave.hrdata       = ahbmaster.hrdata     ;
        assign ahbslave.hready       = ahbmaster.hready     ;
        assign ahbslave.hresp        = ahbmaster.hresp      ;

    endmodule

    module apb_thru #(
      parameter AW=16,
      parameter DW=32
     )(
        apbif.slave             apbslave,
        apbif.master            apbmaster
     );

        assign apbmaster.psel        = apbslave.psel          ;
        assign apbmaster.paddr       = apbslave.paddr         ;
        assign apbmaster.penable     = apbslave.penable       ;
        assign apbmaster.pwrite      = apbslave.pwrite        ;
        assign apbmaster.pstrb       = apbslave.pstrb         ;
        assign apbmaster.pprot       = apbslave.pprot         ;
        assign apbmaster.pwdata      = apbslave.pwdata        ;
        assign apbmaster.apbactive   = apbslave.apbactive     ;
        assign apbslave.prdata       = apbmaster.prdata       ;
        assign apbslave.pready       = apbmaster.pready       ;
        assign apbslave.pslverr      = apbmaster.pslverr      ;

    endmodule

    module axi_thru (
        axiif.slave             axislave,
        axiif.master            aximaster
    );


        assign aximaster.arvalid        = axislave.arvalid;
        assign aximaster.araddr         = axislave.araddr ;
        assign aximaster.arid           = axislave.arid   ;
        assign aximaster.arburst        = axislave.arburst;
        assign aximaster.arlen          = axislave.arlen  ;
        assign aximaster.arsize         = axislave.arsize ;
        assign aximaster.arlock         = axislave.arlock ;
        assign aximaster.arcache        = axislave.arcache;
        assign aximaster.arprot         = axislave.arprot ;
        assign aximaster.armaster       = axislave.armaster;
        assign aximaster.arinner        = axislave.arinner;
        assign aximaster.arshare        = axislave.arshare;
        assign aximaster.aruser         = axislave.aruser ;
        assign aximaster.awvalid        = axislave.awvalid;
        assign aximaster.awaddr         = axislave.awaddr ;
        assign aximaster.awid           = axislave.awid   ;
        assign aximaster.awburst        = axislave.awburst;
        assign aximaster.awlen          = axislave.awlen  ;
        assign aximaster.awsize         = axislave.awsize ;
        assign aximaster.awlock         = axislave.awlock ;
        assign aximaster.awcache        = axislave.awcache;
        assign aximaster.awprot         = axislave.awprot ;
        assign aximaster.awmaster       = axislave.awmaster;
        assign aximaster.awinner        = axislave.awinner;
        assign aximaster.awshare        = axislave.awshare;
        assign aximaster.awsparse       = axislave.awsparse;
        assign aximaster.awuser         = axislave.awuser ;
        assign aximaster.rready         = axislave.rready ;
        assign aximaster.wvalid         = axislave.wvalid ;
        assign aximaster.wid            = axislave.wid    ;
        assign aximaster.wlast          = axislave.wlast  ;
        assign aximaster.wstrb          = axislave.wstrb  ;
        assign aximaster.wdata          = axislave.wdata  ;
        assign aximaster.wuser          = axislave.wuser  ;
        assign aximaster.bready      = axislave.bready ;

        assign axislave.bvalid         = aximaster.bvalid ;
        assign axislave.bid            = aximaster.bid    ;
        assign axislave.bresp          = aximaster.bresp  ;
        assign axislave.buser          = aximaster.buser  ;
        assign axislave.arready     = aximaster.arready ;
        assign axislave.awready     = aximaster.awready ;
        assign axislave.rvalid      = aximaster.rvalid ;
        assign axislave.rid         = aximaster.rid ;
        assign axislave.rlast       = aximaster.rlast ;
        assign axislave.rresp       = aximaster.rresp ;
        assign axislave.rdata       = aximaster.rdata ;
        assign axislave.ruser       = aximaster.ruser ;
        assign axislave.wready      = aximaster.wready ;
    endmodule



  //
  //  apb_sfr
  //  ==
    /*
    //instance template
    apb_sfr #(
            .AW		     ( 16            ),
            .DW		     ( 32            ),
            .IV		     ( 32'h0         ),
            .SFRCNT      ( 1             ),
            .SRMASK      ( 32'h0         ),      // set write 1 to clr ( for status reg )
            .RMASK       ( 32'hffff_ffff ),      // read mask to remove undefined bit
            .REXTMASK    ( 32'h0         )       // read ext mask
         )apb_sfr(
            .pclk        (pclk           ),
            .resetn      (resetn         ),
            .apbslave    (apbslave       ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (sfrpaddr       ),
            .sfrprdataext(sfrprdataext   ),
            .sfrsr       (sfrsr          ),
            .sfrprdata   (sfrprdata      ),
            .sfrdata     (sfrdata        )
         );
    */
/*
    module apb_sfr #(
      parameter AW=16,
      parameter DW=32,
      parameter IV=32'h0,
      parameter SFRCNT=1,
      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'hffff_ffff,    // read mask to remove undefined bit
      parameter REXTMASK=32'h0              // read ext mask
     )(
        input  bit                          pclk        ,
        input  bit                          resetn      ,
        apbif.slave                         apbslave    ,
        input  bit                          sfrlock     ,
        input  bit   [AW-1:0]               sfrpaddr    ,
        input  bit   [0:SFRCNT-1][DW-1:0]   sfrprdataext,
        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
//        output logic [0:SFRCNT-1]           sfrsel      ,
        output logic [DW-1:0]               sfrprdata   ,
        output logic [0:SFRCNT-1][DW-1:0]   sfrdata

     );

    bit [0:SFRCNT-1][DW-1:0] sfrprdata0, sfrprdatas;
    bit [0:SFRCNT-1][DW-1:0] sfrdatarr=IV, sfrdatasr=IV;
    bit [0:SFRCNT-1]           sfrsel ;
    assign apbrd = apbslave.psel & apbslave.penable & ~apbslave.pwrite;
    assign apbwr = ~sfrlock & apbslave.psel & apbslave.penable & apbslave.pwrite;
    bit [DW-1:0]    sIV = IV;

    genvar i;
    generate
	for( i = 0; i < SFRCNT; i = i + 1) begin: GenRnd
	    //  SRMASK indicate SR_bit: set 1 by sfrsr, clr by write 1:
//        `theregfull( pclk, resetn, sfrdata[i], IV ) <= ( SRMASK & sfrsr[i] ) | ( sfrsel[i] & apbwr ? ( ~SRMASK & apbslave.pwdata | SRMASK & ~apbslave.pwdata & sfrdata[i] ) : sfrdata[i] );
        `theregfull( pclk, resetn, sfrdatarr[i], IV ) <= ( sfrsel[i] & apbwr ) ? apbslave.pwdata : sfrdatarr[i];
        `theregfull( pclk, resetn, sfrdatasr[i], IV ) <= ( sfrsel[i] & apbwr ) ? ( ~apbslave.pwdata & sfrdatasr[i] ) : ( sfrdatasr[i] | sfrsr[i] );
        assign sfrdata[i] = ~SRMASK & sfrdatarr[i] | SRMASK & sfrdatasr[i];
        assign sfrsel[i] = ( apbslave.paddr == sfrpaddr[AW-1:0] + 4*i );
        assign sfrprdata0[i] = sfrdata[i] & ~REXTMASK |  sfrprdataext[i] & REXTMASK;
        assign sfrprdatas[i] = apbrd & sfrsel[i] ? sfrprdata0[i] & RMASK : 0;
	end
    endgenerate

    assign sfrprdata = fnsfrprdata(sfrprdatas);

    function bit[DW-1:0]    fnsfrprdata ( bit [0:SFRCNT-1][DW-1:0] fnsfrprdatas );
        bit [DW-1:0] fnvalue;
        int i;
        fnvalue = 0;
        for( i = 0; i <  SFRCNT ; i = i + 1) begin
            fnvalue = fnvalue | fnsfrprdatas[i];
        end
        fnsfrprdata = fnvalue;
    endfunction


    endmodule
*/

  //
  //  apb_sfrop
  //  ==
    /*
    //instance template
    apb_sfrop #(
            .AW		     ( 16            )
         )apb_sfrop(
            .apbslave    (apbslave       ),
            .sfrlock     (sfrlock        ),
            .sfrpaddr    (sfrpaddr       ),
            .apbrd       (sfrapbrd       ),
            .apbwr       (sfrapbwr       )
         );
    */
/*
    module apb_sfrop #(
      parameter AW=16
     )(
        apbif.slave                         apbslave    ,
        input  bit                          sfrlock     ,
        input  bit   [AW-1:0]               sfrpaddr    ,
        output logic                        apbrd       ,
        output logic                        apbwr

     );
    localparam  SFRCNT = 1;
    logic       sfrsel ;
    assign sfrsel = ( apbslave.paddr[AW-1:0] == sfrpaddr[AW-1:0] );
    assign apbrd = apbslave.psel & apbslave.penable & ~apbslave.pwrite & sfrsel;
    assign apbwr = ~sfrlock & apbslave.psel & apbslave.penable & apbslave.pwrite & sfrsel;

    endmodule
*/
  //
  //  define
  //  ==

    `define apbslave_common \
    assign apbslave.pready = 1'b1; \
    assign apbslave.pslverr = 1'b0; \
    assign apbrd = apbslave.psel & apbslave.penable & ~apbslave.pwrite; \
    assign apbwr = apbslave.psel & apbslave.penable & apbslave.pwrite

//    `define apbs_common \
//    assign apbs.pready = 1'b1; \
//    assign apbs.pslverr = 1'b0; \
//    assign apbrd = apbs.psel & apbs.penable & ~apbs.pwrite; \
//    assign apbwr = apbs.psel & apbs.penable & apbs.pwrite

  //
  //  dummytb
  //  ==

    module dummytb_ahb_mux();
        ahbif   ahbslave[0:2]();
        ahbif   ahbmaster();
        ahbif   ahbs(),ahbm();
        bit     hclk, resetn;
        ahbm_null dd0(ahbslave[0]);
        ahbm_null dd1(ahbslave[1]);
        ahbm_null dd2(ahbslave[2]);
        ahb_mux3 #(.AW(32))uahb_mux (.hclk(hclk),.resetn(resetn), .ahbslave(ahbslave),.ahbmaster(ahbmaster));
        ahbs_null bb(.ahbslave(ahbmaster));
        ahbsim uu0(.ahbs(ahbs),.ahbm(ahbm),.*);
    endmodule

    module dummytb_apb_mux();
        apbif   apbslave(), apbmaster[0:1]();
        apb_mux #(.DECAW(1))uapb_mux( .apbslave(apbslave),.apbmaster(apbmaster));
        apbm_null dd(apbslave);
        apbs_nulls #(.SLVCNT(2))aa(apbmaster[0:1]);

        ahbif   ahbmaster[0:1]();
        ahbs_nulls #(.SLVCNT(2))bb(.ahbslave(ahbmaster[0:1]));
    endmodule

    module dummytb_ahbapb_trans();
        ahbif   ahbtrans();
        apbif   apbtrans();
        wire            hsel;           // Slave Select
        wire  [31:0]    haddr;          // Address bus
        wire  [1:0]     htrans;         // Transfer type
        wire            hwrite;         // Transfer direction
        wire  [2:0]     hsize;          // Transfer size
        wire  [2:0]     hburst;         // Burst type
        wire  [3:0]     hprot;          // Protection control
        wire  [3:0]     hmaster;        //Master select
        wire  [31:0]    hwdata;         // Write data
        wire            hmasterlock;    // Locked Sequence
        wire            hreadym;       // Transfer done
        wire  [31:0]    hrdata;         // Read data bus
        wire            hready;         // HREADY feedback
        wire            hresp;          // Transfer response
        wire               psel;
        wire   [15:0]      paddr;
        wire               penable;
        wire               pwrite;
        wire   [3:0]       pstrb;
        wire   [2:0]       pprot;
        wire   [31:0]      pwdata;
        wire               apbactive;
        wire   [31:0]      prdata;
        wire               pready;
        wire               pslverr;
        wire [3:0] hauser, hruser, hwuser;
        ahb_ifs2wire u1(.ahbslave (ahbtrans),.*);
        ahb_wire2ifm u2(.ahbmaster(ahbtrans),.*);
        apb_ifs2wire u3(.apbslave (apbtrans),.*);
        apb_wire2ifm u4(.apbmaster(apbtrans),.*);
    endmodule

    module dummytb_ahbapb_null();
        ahbif   ahbtrans();
        apbif   apbtrans();
        ahbs_null u1(.ahbslave (ahbtrans));
        ahbm_null u2(.ahbmaster(ahbtrans));
        apbs_null u3(.apbslave (apbtrans));
        apbm_null u4(.apbmaster(apbtrans));
    endmodule

    module dummytb_ahbapb_thru();
        ahbif   ahb1(),ahb2();
        ahbif   ahb3(),ahb4();
        apbif   apb1(),apb2();
        ahbm_null u1(ahb1);
        ahb_thru  u2(ahb1,ahb2);
        ahbs_null u3(ahb2);
        apbm_null u4(apb1);
        apb_thru  u5(apb1,apb2);
        apbs_null u6(apb2);
        ahb_gate  u7(1'b1,ahb3,ahb4);
    endmodule

    module dummytb_ahbsync_apbbdg();
        ahbif   ahb1(),ahb2(),ahb3(),ahb4();
        ahbif #(.DW(64)) ahb64();
        apbif   apb1();
        bit hclk,resetn,hclken,pclken,pclk;
        ahbm_null u0(ahb1);
        ahb_sync #(.SYNCDOWN(0))u1(.ahbslave(ahb1),.ahbmaster(ahb2),.hclk(hclk),.resetn(resetn),.hclken(hclken));
        ahb_sync #(.SYNCDOWN(1))u2(.ahbslave(ahb2),.ahbmaster(ahb3),.hclk(hclk),.resetn(resetn),.hclken(hclken));
        apb_bdg u3(.ahbslave(ahb3),.apbmaster(apb1),.hclk(hclk),.resetn(resetn),.pclken(pclken));
        ahb_downsizer u4(.ahbslave(ahb64),.ahbmaster(ahb4),.hclk(hclk),.resetn(resetn));
//        apb_sfr u4(.pclk,.resetn,.apbslave(apb1),.sfrlock(1'b0),.sfrpaddr(16'h0),.sfrprdataext(32'h0),.sfrprdata(),.sfrsr(32'h0),.sfrdata());
//        apb_sfr2 u6(.pclk,.resetn,.apbslave(apb1),.sfrlock(1'b0),.sfrpaddr(16'h0),.sfrfr(32'h0),.sfrprdata(),.sfrsr(32'h0),.sfrdata());
        //apb_sfrop u5(.apbslave(apb1),.sfrlock(1'b0),.sfrpaddr(16'h0),.apbrd(),.apbwr());
    endmodule

    module dummytb_axi();
        axiif axi1(),axi2();
        axi_thru u1(.axislave(axi1),.aximaster(axi2));
        axis_null u2(axi2);
        axim_null u3(axi1);
    endmodule



    module dummytb_for_ambainterfaces__just_ignore_it();
       dummytb_ahb_mux          u1();
       dummytb_apb_mux          u2();
       dummytb_ahbapb_trans     u3();
       dummytb_ahbapb_null      u4();
       dummytb_ahbsync_apbbdg   u5();
       dummytb_ahbapb_thru      u6();
       dummytb_axi              u7();
    endmodule




