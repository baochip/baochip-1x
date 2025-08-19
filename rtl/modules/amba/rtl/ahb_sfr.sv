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

    `define ahbs_common \
    assign ahbs.hready = 1'b1; \
    assign ahbs.hresps = '0;




/*
    logic ahbrd, ahbwr, sfrlock;
    `ahbs_common

    assign sfrlock = 1'b0;
    assign ahbs.hrdata =
                sfr_cr.hrdata32 |
                sfr_sr.hrdata32 |
                sfr_fr.hrdata32 ;

    bit [15:0] sfrcr, sfrsr, sfrfr;
    logic sfrar;

    ahb_cr #(.A('h10), .DW(16), .IV('hff))  sfr_cr    (.cr(sfrcr),  .hrdata32(),.*);
    ahb_sr #(.A('h14), .DW(16)           )  sfr_sr    (.sr(sfrsr),  .hrdata32(),.*);
    ahb_fr #(.A('h18), .DW(16)           )  sfr_fr    (.fr(sfrfr),  .hrdata32(),.*);
    ahb_ar #(.A('h1c), .AR('h32)         )  sfr_ar    (.ar(sfrar),              .*);
*/


module ahb_cr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16,
      parameter IV=32'h0,
      parameter SFRCNT=1,
//      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'hffff_ffff        // read mask to remove undefined bit
//      parameter REXTMASK=32'h0              // read ext mask
)(
        input  logic                          hclk        ,
        input  logic                          resetn      ,
        ahbif.slavein                       ahbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrhaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrhrdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        output logic [31:0]                 hrdata32    ,
        output logic [0:SFRCNT-1][DW-1:0]   cr
);


    logic[DW-1:0] hrdata;
    assign hrdata32 = hrdata | 32'h0;

    ahb_sfr2 #(
            .AW          ( AW            ),
            .DW          ( DW            ),
            .IV          ( IV            ),
            .SFRCNT      ( SFRCNT        ),
            .RMASK       ( RMASK         ),      // read mask to remove undefined bit
            .FRMASK      ( 32'h0         ),      // set write 1 to clr ( for status reg )
            .SRMASK      ( 32'h0         )       // read ext mask
         )ahb_sfr(
            .hclk        (hclk           ),
            .resetn      (resetn         ),
            .ahbs        (ahbs           ),
            .sfrlock     (sfrlock|'0     ),
            .sfrhaddr    (A[AW-1:0]      ),
            .sfrsr       ('0             ),
            .sfrfr       ('0             ),
            .sfrhrdata   (hrdata         ),
            .sfrdata     (cr             )
         );

endmodule

module ahb_sr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16,
//      parameter IV=32'h0,                   // useless
      parameter SFRCNT=1,
//      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'hffff_ffff,        // read mask to remove undefined bit
      parameter SRMASK=32'hffff_ffff              // read ext mask
)(
        input  logic                          hclk        ,
        input  logic                          resetn      ,
        ahbif.slavein                       ahbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrhaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrhrdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        output logic [31:0]                 hrdata32    ,
        input  logic [0:SFRCNT-1][DW-1:0]   sr
);


    logic[DW-1:0] hrdata;
    assign hrdata32 = hrdata | 32'h0;

    ahb_sfr2 #(
            .AW          ( AW            ),
            .DW          ( DW            ),
            .IV          ( '0            ),
            .SFRCNT      ( SFRCNT        ),
            .RMASK       ( RMASK         ),      // read mask to remove undefined bit
            .FRMASK      ( 32'h0         ),      // set write 1 to clr ( for status reg )
            .SRMASK      ( SRMASK        )       // read ext mask
         )ahb_sfr(
            .hclk        (hclk           ),
            .resetn      (resetn         ),
            .ahbs        (ahbs           ),
            .sfrlock     (sfrlock|'0     ),
            .sfrhaddr    (A[AW-1:0]      ),
            .sfrsr       (sr             ),
            .sfrfr       ('0             ),
            .sfrhrdata   (hrdata         ),
            .sfrdata     (               )
         );

endmodule


module ahb_fr
#(
      parameter A=0,
      parameter AW=12,
      parameter DW=16,
//      parameter IV=32'h0,                   // useless
      parameter SFRCNT=1,
//      parameter SRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter RMASK=32'hffff_ffff,        // read mask to remove undefined bit
      parameter FRMASK=32'hffff_ffff              // read ext mask
)(
        input  logic                          hclk        ,
        input  logic                          resetn      ,
        ahbif.slavein                       ahbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrhaddr    ,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrhrdataext,
//        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        output logic [31:0]                 hrdata32    ,
        input  logic [0:SFRCNT-1][DW-1:0]   fr
);


    logic[DW-1:0] hrdata;
    assign hrdata32 = hrdata | 32'h0;

    ahb_sfr2 #(
            .AW          ( AW            ),
            .DW          ( DW            ),
            .IV          ( '0            ),
            .SFRCNT      ( SFRCNT        ),
            .RMASK       ( RMASK         ),      // read mask to remove undefined bit
            .FRMASK      ( FRMASK        ),      // set write 1 to clr ( for status reg )
            .SRMASK      ( '0            )       // read ext mask
         )ahb_sfr(
            .hclk        (hclk           ),
            .resetn      (resetn         ),
            .ahbs        (ahbs           ),
            .sfrlock     (sfrlock|'0     ),
            .sfrhaddr    (A[AW-1:0]      ),
            .sfrsr       ('0             ),
            .sfrfr       (fr             ),
            .sfrhrdata   (hrdata         ),
            .sfrdata     (               )
         );

endmodule


// ahb_sfr basic

    module ahb_sfr2 #(
      parameter AW=12,
      parameter DW=32,
      parameter [DW-1:0] IV='0,
      parameter SFRCNT=1,
      parameter RMASK=32'hffff_ffff,    // read mask to remove undefined bit
      parameter FRMASK=32'h0,               // set write 1 to clr ( for status reg )
      parameter SRMASK=32'h0              // read ext mask
     )(
        input  logic                          hclk        ,
        input  logic                          resetn      ,
        ahbif.slavein                       ahbs        ,
        input  bit                          sfrlock     ,
        input  bit   [AW-1:0]               sfrhaddr    ,
        input  bit   [0:SFRCNT-1][DW-1:0]   sfrsr       ,
        input  bit   [0:SFRCNT-1][DW-1:0]   sfrfr       ,
        output logic [DW-1:0]               sfrhrdata   ,
        output logic [0:SFRCNT-1][DW-1:0]   sfrdata
     );

  wire  [AW-1:0]         reg_addr;
  wire                   reg_read_en;
  wire                   reg_write_en, reg_write_en0;
  wire  [3:0]            reg_byte_strobe;
  wire  [31:0]           reg_wdata;
  wire  [31:0]           reg_rdata;

  ahbs_trans
   #(.ADDRWIDTH (AW))
    strans (
      .hclk         (hclk),
      .hresetn      (resetn),

      // Input slave port: 32 bit data bus interface
      .hsels        (ahbs.hsel),
      .haddrs       (ahbs.haddr[AW-1:0]),
      .htranss      (ahbs.htrans),
      .hsizes       (ahbs.hsize),
      .hwrites      (ahbs.hwrite),
      .hreadys      (ahbs.hreadym),
      .hwdatas      (ahbs.hwdata),

      .hreadyouts   (),
      .hresps       (),
      .hrdatas      (),

      // Register interface
      .addr         (reg_addr),
      .read_en      (reg_read_en),
      .write_en     (reg_write_en0),
      .byte_strobe  (reg_byte_strobe),
      .wdata        (reg_wdata),
      .rdata        (reg_rdata)
  );


    bit [0:SFRCNT-1][DW-1:0] sfrhrdata0, sfrhrdatas;
    bit [0:SFRCNT-1][DW-1:0] sfrdatarr;//={SFRCNT{IV}};
    bit [0:SFRCNT-1][DW-1:0] sfrdatasr;//{SFRCNT{IV}};
    bit [0:SFRCNT-1]           sfrsel ;
//    assign ahbrd = ahbs    .psel & ahbs    .penable & ~ahbs    .pwrite;
    assign reg_write_en = ~sfrlock & reg_write_en0;
    bit [DW-1:0]    sIV = IV;

    genvar i;
    generate
    for( i = 0; i < SFRCNT; i = i + 1) begin: GenRnd
        `theregfull( hclk, resetn, sfrdatarr[i], IV ) <= ( sfrsel[i] & reg_write_en ) ? reg_wdata : sfrdatarr[i];
        `theregfull( hclk, resetn, sfrdatasr[i], '0 ) <= ( sfrsel[i] & reg_write_en ) ? ( ~reg_wdata & sfrdatasr[i] ) : ( sfrdatasr[i] | sfrfr[i] );
        assign sfrdata[i] = ~FRMASK & sfrdatarr[i] | FRMASK & sfrdatasr[i];
        assign sfrsel[i] = ( reg_addr == sfrhaddr[AW-1:0] + 4*i );
        assign sfrhrdata0[i] = sfrdata[i] & ~SRMASK |  sfrsr[i] & SRMASK;
        assign sfrhrdatas[i] = reg_read_en & sfrsel[i] ? sfrhrdata0[i] & RMASK : 0;
    end
    endgenerate

    assign sfrhrdata = fnsfrhrdata(sfrhrdatas);

    function bit[DW-1:0]    fnsfrhrdata ( bit [0:SFRCNT-1][DW-1:0] fnsfrhrdatas );
        bit [DW-1:0] fnvalue;
        int i;
        fnvalue = 0;
        for( i = 0; i <  SFRCNT ; i = i + 1) begin
            fnvalue = fnvalue | fnsfrhrdatas[i];
        end
        fnsfrhrdata = fnvalue;
    endfunction


    endmodule

module ahb_ar #(
        parameter AW=12,
        parameter A=0,
        parameter AR=32'h5a
     )(
        input  logic  hclk,
        input  logic  resetn,
        ahbif.slavein                       ahbs        ,
        input  bit                          sfrlock     ,
//        input  bit   [AW-1:0]               sfrhaddr    ,
//        output logic                        ahbrd       ,
        output logic                        ar

     );
    localparam  SFRCNT = 1;

  wire  [AW-1:0]         reg_addr;
  wire                   reg_read_en;
  wire                   reg_write_en, reg_write_en0;
  wire  [3:0]            reg_byte_strobe;
  wire  [31:0]           reg_wdata;
  wire  [31:0]           reg_rdata;
  wire                   sfrsel;

  ahbs_trans
   #(.ADDRWIDTH (AW))
    strans (
      .hclk         (hclk),
      .hresetn      (resetn),

      // Input slave port: 32 bit data bus interface
      .hsels        (ahbs.hsel),
      .haddrs       (ahbs.haddr[AW-1:0]),
      .htranss      (ahbs.htrans),
      .hsizes       (ahbs.hsize),
      .hwrites      (ahbs.hwrite),
      .hreadys      (ahbs.hreadym),
      .hwdatas      (ahbs.hwdata),

      .hreadyouts   (),
      .hresps       (),
      .hrdatas      (),

      // Register interface
      .addr         (reg_addr),
      .read_en      (reg_read_en),
      .write_en     (reg_write_en0),
      .byte_strobe  (reg_byte_strobe),
      .wdata        (reg_wdata),
      .rdata        (reg_rdata)
  );

    assign reg_rdata = '0;
    assign sfrsel = ( reg_addr[AW-1:0] == A[AW-1:0] );
    assign reg_write_en = reg_write_en0 & sfrsel;

    `theregfull(hclk, resetn, ar, '0) <= reg_write_en & ( reg_wdata == AR );

endmodule

module ahbs_trans #(
  //parameter for address width
  parameter   ADDRWIDTH=12)
 (
  input  wire                  hclk,       // clock
  input  wire                  hresetn,    // reset

  // AHB connection to master
  input  wire                  hsels,
  input  wire [ADDRWIDTH-1:0]  haddrs,
  input  wire [1:0]            htranss,
  input  wire [2:0]            hsizes,
  input  wire                  hwrites,
  input  wire                  hreadys,
  input  wire [31:0]           hwdatas,

  output wire                  hreadyouts,
  output wire                  hresps,
  output wire [31:0]           hrdatas,

   // Register interface
  output wire [ADDRWIDTH-1:0]  addr,
  output wire                  read_en,
  output wire                  write_en,
  output wire [3:0]            byte_strobe,
  output wire [31:0]           wdata,
  input  wire [31:0]           rdata);

  // ----------------------------------------
  // Internal wires declarations
   wire                   trans_req= hreadys & hsels & htranss[1];
    // transfer request issued only in SEQ and NONSEQ status and slave is
    // selected and last transfer finish

   wire                   ahb_read_req  = trans_req & (~hwrites);// AHB read request
   wire                   ahb_write_req = trans_req &  hwrites;  // AHB write request
   wire                   update_read_req;    // To update the read enable register
   wire                   update_write_req;   // To update the write enable register

   reg  [ADDRWIDTH-1:0]   addr_reg;     // address signal, registered
   reg                    read_en_reg;  // read enable signal, registered
   reg                    write_en_reg; // write enable signal, registered

   reg  [3:0]             byte_strobe_reg; // registered output for byte strobe
   reg  [3:0]             byte_strobe_nxt; // next state for byte_strobe_reg
  //-----------------------------------------------------------
  // Module logic start
  //----------------------------------------------------------

  // Address signal registering, to make the address and data active at the same cycle
  always @(posedge hclk or negedge hresetn)
  begin
    if (~hresetn)
      addr_reg <= {(ADDRWIDTH){1'b0}}; //default address 0 is selected
    else if (trans_req)
      addr_reg <= haddrs[ADDRWIDTH-1:0];
  end


  // register read signal generation
  assign update_read_req = ahb_read_req | (read_en_reg & hreadys); // Update read enable control if
                                 //  1. When there is a valid read request
                                 //  2. When there is an active read, update it at the end of transfer (HREADY=1)

  always @(posedge hclk or negedge hresetn)
  begin
    if (~hresetn)
      begin
        read_en_reg <= 1'b0;
      end
    else if (update_read_req)
      begin
        read_en_reg  <= ahb_read_req;
      end
  end

  // register write signal generation
  assign update_write_req = ahb_write_req |( write_en_reg & hreadys);  // Update write enable control if
                                 //  1. When there is a valid write request
                                 //  2. When there is an active write, update it at the end of transfer (HREADY=1)

  always @(posedge hclk or negedge hresetn)
  begin
    if (~hresetn)
      begin
        write_en_reg <= 1'b0;
      end
    else if (update_write_req)
      begin
        write_en_reg  <= ahb_write_req;
      end
  end

  // byte strobe signal
   always @(hsizes or haddrs)
   begin
     if (hsizes == 3'b000)    //byte
       begin
         case(haddrs[1:0])
           2'b00: byte_strobe_nxt = 4'b0001;
           2'b01: byte_strobe_nxt = 4'b0010;
           2'b10: byte_strobe_nxt = 4'b0100;
           2'b11: byte_strobe_nxt = 4'b1000;
           default: byte_strobe_nxt = 4'bxxxx;
         endcase
       end
     else if (hsizes == 3'b001) //half word
       begin
         if(haddrs[1]==1'b1)
           byte_strobe_nxt = 4'b1100;
         else
           byte_strobe_nxt = 4'b0011;
       end
     else // default 32 bits, word
       begin
           byte_strobe_nxt = 4'b1111;
       end
   end

  always @(posedge hclk or negedge hresetn)
  begin
    if (~hresetn)
      byte_strobe_reg <= {4{1'b0}};
    else if (update_read_req|update_write_req)
      // Update byte strobe registers if
      // 1. if there is a valid read/write transfer request
      // 2. if there is an on going transfer
      byte_strobe_reg  <= byte_strobe_nxt;
  end

  //-----------------------------------------------------------
  // Outputs
  //-----------------------------------------------------------
  // For simplify the timing, the master and slave signals are connected directly, execpt data bus.
  assign addr        = addr_reg[ADDRWIDTH-1:0];
  assign read_en     = read_en_reg;
  assign write_en    = write_en_reg;
  assign wdata       = hwdatas;
  assign byte_strobe = byte_strobe_reg;

  assign hreadyouts  = 1'b1;  // slave always ready
  assign hresps      = 1'b0;  // OKAY response from slave
  assign hrdatas     = '0;//rdata;
  //-----------------------------------------------------------
  //Module logic end
  //----------------------------------------------------------


endmodule


module dummytb_ahbsfr();

/*
    logic ahbrd, ahbwr, sfrlock;
    `ahbs_common

    assign sfrlock = 1'b0;
    assign ahbs.prdata =
                sfr_cr.prdata32 |
                sfr_sr.prdata32 |
                sfr_fr.prdata32 ;
*/
    ahbif ahbs();
    bit hclk, resetn, sfrlock;

    bit [15:0] sfrcr, sfrsr, sfrfr;
    logic sfrar;

    ahb_cr #(.A('h10), .DW(16), .IV('hff))  sfr_cr    (.cr(sfrcr),  .hrdata32(),.*);
    ahb_sr #(.A('h14), .DW(16)           )  sfr_sr    (.sr(sfrsr),  .hrdata32(),.*);
    ahb_fr #(.A('h18), .DW(16)           )  sfr_fr    (.fr(sfrfr),  .hrdata32(),.*);
    ahb_ar #(.A('h1c), .AR('h32)         )  sfr_ar    (.ar(sfrar),              .*);

endmodule
