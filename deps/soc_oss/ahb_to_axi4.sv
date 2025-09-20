`ifdef XVLOG // required for compatibility with xsim
`include "template.sv"
`include "apb_sfr.sv"
`include "axi_pkg.sv"
`include "daric_cfg_sim.sv"
`include "amba_interface_def.sv"
`include "io_interface_def.sv"
`endif

module ahb_to_axi4 #(
      parameter AW  = 32,
      parameter DW  = 32,
      parameter IDW = 8,
      parameter UW  = 8
    )(
      input logic   clk,
      input logic   resetn,

      output   logic            axi_awvalid,
      input    logic            axi_awready,
      output   logic [IDW-1:0]  axi_awid,
      output   logic [AW-1:0]   axi_awaddr,
      output   logic [2:0]      axi_awsize,
      output   logic [2:0]      axi_awprot,
      output   logic [7:0]      axi_awlen,
      output   logic [1:0]      axi_awburst,

      output   logic            axi_wvalid,
      input    logic            axi_wready,
      output   logic [DW-1:0]   axi_wdata,
      output   logic [DW/8-1:0] axi_wstrb,
      output   logic            axi_wlast,

      input    logic            axi_bvalid,
      output   logic            axi_bready,
      input    logic [1:0]      axi_bresp,
      input    logic [IDW-1:0]  axi_bid,
      // AXI   Read Channel,
      output   logic            axi_arvalid,
      input    logic            axi_arready,
      output   logic [IDW-1:0]  axi_arid,
      output   logic [AW-1:0]   axi_araddr,
      output   logic [2:0]      axi_arsize,
      output   logic [2:0]      axi_arprot,
      output   logic [7:0]      axi_arlen,
      output   logic [1:0]      axi_arburst,

      input    logic            axi_rvalid,
      output   logic            axi_rready,
      input    logic [IDW-1:0]  axi_rid,
      input    logic [DW-1:0]   axi_rdata,
      input    logic [1:0]      axi_rresp,
                  
      // AHB-  Lite signals
      input    logic [AW-1:0]   ahb_haddr,     // ahb bus address
      input    logic [2:0]      ahb_hburst,    // tied to 0
      input    logic            ahb_hmastlock, // tied to 0
      input    logic [3:0]      ahb_hprot,     // tied to 4'b0011
      input    logic [2:0]      ahb_hsize,     // size of bus transaction (possible values 0;1;2;3)
      input    logic [1:0]      ahb_htrans,    // Transaction type (possible values 0;2 only right now)
      input    logic            ahb_hwrite,    // ahb bus write
      input    logic [DW-1:0]   ahb_hwdata,    // ahb bus write data
      input    logic            ahb_hsel,      // this slave was selected
      input    logic            ahb_hreadyin,  // previous hready was accepted or not
                  
      output   logic [DW-1:0]   ahb_hrdata,      // ahb bus read data
      output   logic            ahb_hreadyout,   // slave ready to accept transaction
      output   logic            ahb_hresp        // slave response (high indicates erro)
);

`ifdef DNU
    assign axi_awready  = aximaster.awready                 ;
    assign                aximaster.awvalid  = axi_awvalid  ;
    assign                aximaster.awid     = axi_awid     ;
    assign                aximaster.awaddr   = axi_awaddr   ;
    assign                aximaster.awsize   = axi_awsize   ;
    assign                aximaster.awprot   = axi_awprot   ;
    assign                aximaster.awlen    = axi_awlen    ;
    assign                aximaster.awburst  = axi_awburst  ;
    assign                aximaster.awcache  = '0;
    assign                aximaster.awinner  = '0;
    assign                aximaster.awlock   = '0;
    assign                aximaster.awmaster = '0;
    assign                aximaster.awshare  = '0;
    assign                aximaster.awsparse = '1;
    assign                aximaster.awuser   = ahbslave.hmaster | '0;

/*           */       
    assign axi_wready   = aximaster.wready                 ;
    assign                aximaster.wvalid   = axi_wvalid  ;
    assign                aximaster.wdata    = axi_wdata   ;
    assign                aximaster.wstrb    = axi_wstrb   ;
    assign                aximaster.wlast    = axi_wlast   ;
    assign                aximaster.wid      = '0;//ahbslave.hmaster*16;
    assign                aximaster.wuser    = '0;
/*           */   
    assign                aximaster.bready   = axi_bready   ;
    assign axi_bvalid   = aximaster.bvalid   ;
    assign axi_bresp    = aximaster.bresp    ;
    assign axi_bid      = aximaster.bid      ;
/*           */   
    // AXI   Read Channels
    assign axi_arready  = aximaster.arready                   ;
    assign                aximaster.arvalid   = axi_arvalid   ;
    assign                aximaster.arid      = axi_arid      ;
    assign                aximaster.araddr    = axi_araddr    ;
    assign                aximaster.arsize    = axi_arsize    ;
    assign                aximaster.arprot    = axi_arprot    ;
    assign                aximaster.arlen     = axi_arlen     ;
    assign                aximaster.arburst   = axi_arburst   ;
    assign                aximaster.arcache   = '0;
    assign                aximaster.arinner   = '0;
    assign                aximaster.arlock    = '0;
    assign                aximaster.armaster  = '0;
    assign                aximaster.arshare   = '0;
    assign                aximaster.aruser    = ahbslave.hmaster | '0;

    assign                aximaster.rready   = axi_rready   ;
    assign axi_rvalid   = aximaster.rvalid    ;
    assign axi_rid      = aximaster.rid       ;
    assign axi_rdata    = aximaster.rdata     ;
    assign axi_rresp    = aximaster.rresp     ;

// #missing signals##
//##;

    assign ahb_haddr     = ahbslave.haddr;     
    assign ahb_hburst    = ahbslave.hburst;    
    assign ahb_hmastlock = ahbslave.hmasterlock; 
    assign ahb_hprot     = ahbslave.hprot;     
    assign ahb_hsize     = ahbslave.hsize;     
    assign ahb_htrans    = ahbslave.htrans;    
    assign ahb_hwrite    = ahbslave.hwrite;    
    assign ahb_hwdata    = ahbslave.hwdata;    
    assign ahb_hsel      = ahbslave.hsel;      
    assign ahb_hreadyin  = ahbslave.hreadym;  

    assign ahbslave.hrdata    = ahb_hrdata    ;
    assign ahbslave.hready    = ahb_hreadyout ;
    assign ahbslave.hresp     = ahb_hresp     ;
`endif


 typedef enum logic [1:0] {   IDLE   = 2'b00,    // Nothing in the buffer. No commands yet recieved
                              WR     = 2'b01,    // Write Command recieved
                              RD     = 2'b10,    // Read Command recieved
                              PEND   = 2'b11     // Waiting on Read Data from core
                            } state_t;
   state_t      buf_state, buf_nxtstate;
   logic        buf_state_en;

   // Buffer signals (one entry buffer)
   logic                    buf_read_error_in, buf_read_error;
   logic [DW-1:0]           buf_rdata;

   logic                    ahb_hready;
   logic                    ahb_hready_q;
   logic [1:0]              ahb_htrans_in, ahb_htrans_q;
   logic [2:0]              ahb_hsize_q;
   logic                    ahb_hwrite_q;
   logic [AW-1:0]           ahb_haddr_q;
   logic [DW-1:0]           ahb_hwdata_q;
   logic                    ahb_hresp_q;

   // signals needed for the read data coming back from the core and to block any further commands as AHB is a blocking bus
   logic                    buf_rdata_en;

   logic                    ahb_bus_addr_clk_en, buf_rdata_clk_en;
   logic                    ahb_clk, ahb_addr_clk, buf_rdata_clk;
   // Command buffer is the holding station where we convert to AXI and send to core
   logic                    cmdbuf_wr_en, cmdbuf_rst;
   logic                    cmdbuf_full;
   logic                    cmdbuf_vld, cmdbuf_write;
   logic [1:0]              cmdbuf_size;
   logic [DW/8-1:0]         cmdbuf_wstrb;
   logic [AW-1:0]           cmdbuf_addr;
   logic [DW-1:0]           cmdbuf_wdata;

   logic                    bus_clk;
   logic [DW/8-1:0]       master_wstrb;
   logic [3:0]            master_wstrb32;
   logic [7:0]            master_wstrb64;

   logic                 axi_aw_valid_pending;
   logic                 axi_w_valid_pending;

// FSM to control the bus states and when to block the hready and load the command buffer
   always_comb begin
      buf_nxtstate      = IDLE;
      buf_state_en      = 1'b0;
      buf_rdata_en      = 1'b0;              // signal to load the buffer when the core sends read data back
      buf_read_error_in = 1'b0;              // signal indicating that an error came back with the read from the core
      cmdbuf_wr_en      = 1'b0;              // all clear from the gasket to load the buffer with the command for reads, command/dat for writes
      case (buf_state)
         IDLE: begin  // No commands recieved
                  buf_nxtstate      = ahb_hwrite ? WR : RD;
                  buf_state_en      = ahb_hready & ahb_htrans[1] & ahb_hsel;                 // only transition on a valid hrtans
          end
         WR: begin // Write command recieved last cycle
                  buf_nxtstate      = (ahb_hresp | (ahb_htrans[1:0] == 2'b0) | ~ahb_hsel) ? IDLE : (ahb_hwrite ? WR : RD);
                  buf_state_en      = (~cmdbuf_full | ahb_hresp) ;
                  cmdbuf_wr_en      = ~cmdbuf_full & ~(ahb_hresp | ((ahb_htrans[1:0] == 2'b01) & ahb_hsel));   // Dont send command to the buffer in case of an error or when the master is not ready with the data now.
         end
         RD: begin // Read command recieved last cycle.
                 buf_nxtstate      = ahb_hresp ? IDLE :PEND;                                       // If error go to idle, else wait for read data
                 buf_state_en      = (~cmdbuf_full | ahb_hresp);                                   // only when command can go, or if its an error
                 cmdbuf_wr_en      = ~ahb_hresp & ~cmdbuf_full;                                    // send command only when no error
         end
         PEND: begin // Read Command has been sent. Waiting on Data.
                 buf_nxtstate      = IDLE;                                                          // go back for next command and present data next cycle
                 buf_state_en      = axi_rvalid & ~cmdbuf_write;                                    // read data is back
                 buf_rdata_en      = buf_state_en;                                                  // buffer the read data coming back from core
                 buf_read_error_in = buf_state_en & |axi_rresp[1:0];                                // buffer error flag if return has Error ( ECC )
         end
     endcase
   end // always_comb begin

    assign master_wstrb = ( DW == 64 ) ? master_wstrb64 : master_wstrb32;

   // this mimics the implementation in cmsdk_ahb_to_sram.v
   always_comb begin
      case (ahb_hsize_q)
         3'b000: begin
            master_wstrb32[3:0] = 4'b0001 << ahb_haddr_q[1:0];
         end
         3'b001: begin
            if (ahb_haddr_q[1]) begin
               master_wstrb32[3:0] = 4'b1100;
            end else begin
               master_wstrb32[3:0] = 4'b0011;
            end
         end
         3'b010: begin
            master_wstrb32[3:0] = 4'b1111;
         end
      endcase
   end

   assign master_wstrb64[7:0]   = ({8{ahb_hsize_q[2:0] == 3'b0}}  & (8'b1    << ahb_haddr_q[2:0])) |
                                  ({8{ahb_hsize_q[2:0] == 3'b1}}  & (8'b11   << ahb_haddr_q[2:0])) |
                                  ({8{ahb_hsize_q[2:0] == 3'b10}} & (8'b1111 << ahb_haddr_q[2:0])) |
                                  ({8{ahb_hsize_q[2:0] == 3'b11}} & 8'b1111_1111);

   // AHB signals
   assign ahb_hreadyout       = ahb_hresp ? (ahb_hresp_q & ~ahb_hready_q) :
                                         ((~cmdbuf_full | (buf_state == IDLE)) & ~(buf_state == RD | buf_state == PEND)  & ~buf_read_error);

   assign ahb_hready          = ahb_hreadyout & ahb_hreadyin;
   assign ahb_htrans_in[1:0]  = {2{ahb_hsel}} & ahb_htrans[1:0];
   assign ahb_hrdata       = buf_rdata;
   assign ahb_hresp        = ((ahb_htrans_q[1:0] != 2'b0) & (buf_state != IDLE)  &
                             ((ahb_hsize_q[2:0] == 3'h1) & ahb_haddr_q[0])   |                                                                             // HW size but unaligned
                             ((ahb_hsize_q[2:0] == 3'h2) & (|ahb_haddr_q[1:0])) |                                                                          // W size but unaligned
                             ((ahb_hsize_q[2:0] == 3'h3) & (|ahb_haddr_q[2:0]))) |                                                                        // DW size but unaligned
                             buf_read_error |                                                                                                              // Read ECC error
                             (ahb_hresp_q & ~ahb_hready_q);                                                                                                // This is for second cycle of hresp protocol

   always_ff @(posedge clk) begin
      if (axi_awready) begin
         axi_aw_valid_pending <= 0;
      end else if (axi_awvalid & !axi_awready | ahb_hwrite_q) begin
         axi_aw_valid_pending <= 1;
      end else begin
         axi_aw_valid_pending <= axi_aw_valid_pending;
      end
      if (axi_wready) begin
         axi_w_valid_pending <= 0;
      end else if (axi_wvalid & !axi_wready | ahb_hwrite_q) begin
         axi_w_valid_pending <= 1;
      end else begin
         axi_w_valid_pending <= axi_w_valid_pending;
      end
   end

    assign ahb_bus_addr_clk_en =  (ahb_hready & ahb_htrans[1]);
    assign cmdbuf_rst =
      (
         (
            (
               (axi_awvalid & axi_awready) & !axi_w_valid_pending
               | (axi_wvalid & axi_wready) & !axi_aw_valid_pending
            )
          | (axi_arvalid & axi_arready)
         ) & ~cmdbuf_wr_en
      )
      | (ahb_hresp & ~cmdbuf_write);
    assign cmdbuf_full        = (cmdbuf_vld & ~((axi_awvalid & axi_awready) | (axi_arvalid & axi_arready)));

    `theregrn( ahb_hresp_q )  <= ahb_hresp ;
    `theregrn( ahb_hready_q ) <= ahb_hready;
    `theregrn( ahb_htrans_q ) <= ahb_htrans_in;


    `theregfull( clk, resetn, buf_state, IDLE ) <= buf_state_en        ? buf_nxtstate  : buf_state ;
    `theregrn( ahb_hsize_q  ) <= ahb_bus_addr_clk_en ? ahb_hsize  : ahb_hsize_q  ;
    `theregrn( ahb_hwrite_q ) <= ahb_bus_addr_clk_en ? ahb_hwrite : ahb_hwrite_q ;
    `theregrn( ahb_haddr_q  ) <= ahb_bus_addr_clk_en ? ahb_haddr  : ahb_hwrite_q ;
    `theregrn( buf_rdata    ) <= buf_rdata_en        ? axi_rdata  : buf_rdata ;
    `theregrn( buf_read_error ) <= buf_read_error_in;

   `theregrn( cmdbuf_vld    ) <= cmdbuf_rst ? '0 : cmdbuf_wr_en ? 1'b1 : cmdbuf_vld;
   `theregrn( cmdbuf_write  ) <= cmdbuf_wr_en ? ahb_hwrite_q : cmdbuf_write ;
   `theregrn( cmdbuf_size   ) <= cmdbuf_wr_en ? ahb_hsize_q  : cmdbuf_size  ;
   `theregrn( cmdbuf_wstrb  ) <= cmdbuf_wr_en ? master_wstrb : cmdbuf_wstrb ;

   `theregrn( cmdbuf_addr   ) <= cmdbuf_wr_en ? ahb_haddr_q  : cmdbuf_addr  ;
   `theregrn( cmdbuf_wdata  ) <= cmdbuf_wr_en ? ahb_hwdata   : cmdbuf_wdata ;


   // AXI Write Command Channel
   assign axi_awvalid           = cmdbuf_vld & cmdbuf_write;
   assign axi_awid[IDW-1:0]     = '0;//ahbslave.hmaster*16;
   assign axi_awaddr[AW-1:0]      = cmdbuf_addr[AW-1:0];
   assign axi_awsize[2:0]       = {1'b0, cmdbuf_size[1:0]};
   assign axi_awprot[2:0]       = 3'b0;
   assign axi_awlen[7:0]        = '0;
   assign axi_awburst[1:0]      = 2'b01;
   // AXI Write Data Channel - This is tied to the command channel as we only write the command buffer once we have the data.
   assign axi_wvalid            = cmdbuf_vld & cmdbuf_write;
   assign axi_wdata[DW-1:0]       = cmdbuf_wdata[DW-1:0];
   assign axi_wstrb[DW/8-1:0]        = cmdbuf_wstrb[DW/8-1:0];
   assign axi_wlast             = 1'b1;
  // AXI Write Response - Always ready. AHB does not require a write response.
   assign axi_bready            = 1'b1;
   // AXI Read Channels
   assign axi_arvalid           = cmdbuf_vld & ~cmdbuf_write;
   assign axi_arid[IDW-1:0]     = '0;//ahbslave.hmaster*16;
   assign axi_araddr[31:0]      = cmdbuf_addr[31:0];
   assign axi_arsize[2:0]       = {1'b0, cmdbuf_size[1:0]};
   assign axi_arprot            = 3'b0;
   assign axi_arlen[7:0]        = '0;
   assign axi_arburst[1:0]      = 2'b01;
   // AXI Read Response Channel - Always ready as AHB reads are blocking and the the buffer is available for the read coming back always.
   assign axi_rready            = 1'b1;

   // Clock header logic

`ifdef ASSERT_ON
   property ahb_error_protocol;
      @(posedge ahb_clk) (ahb_hready & ahb_hresp) |-> (~$past(ahb_hready) & $past(ahb_hresp));
   endproperty
   assert_ahb_error_protocol: assert property (ahb_error_protocol) else
      $display("Bus Error with hReady isn't preceded with Bus Error without hready");

`endif

endmodule // ahb_to_axi4