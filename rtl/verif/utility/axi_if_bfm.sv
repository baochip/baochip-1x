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

//  Description : AXI Testbench Interface module
//
/////////////////////////////////////////////////////////////////////////// 

interface axi_if_bfm #(
                      parameter AXI_ID_WIDTH   = 6,
                      parameter AXI_ADDR_WIDTH = 32,
                      parameter AXI_DATA_WIDTH = 32,
                      parameter AXI_LEN_WIDTH = 8
                     )(
                     input wire clk,
                     input wire reset,
                     input wire clken,

                     input wire                          aw_ready,  // Slave is ready to accept
                     input wire [AXI_ID_WIDTH-1:0]	 aw_id,     // Write ID
                     input wire [AXI_ADDR_WIDTH-1:0]   aw_addr,   // Write address
                     input wire [AXI_LEN_WIDTH-1:0]    aw_len,    // Write Burst Length
                     input wire [2:0]                    aw_size,   // Write Burst size
                     input wire [1:0]                    aw_burst,  // Write Burst type
                     input wire [0:0]                    aw_lock,   // Write lock type
                     input wire [3:0]                    aw_cache,  // Write Cache type
                     input wire [2:0]                    aw_prot,   // Write Protection type
                     input wire [3:0]                    aw_qos,    // Write Quality of Svc
                     input wire                          aw_valid,  // Write address valid

                     // AXI write data channel signals
                     input wire                          w_ready,  // Write data ready
                     input wire [AXI_DATA_WIDTH-1:0]   w_data,   // Write data
                     input wire [AXI_DATA_WIDTH/8-1:0] w_strb,   // Write strobes
                     input wire                          w_last,   // Last write transaction
                     input wire                          w_valid,  // Write valid

                     // AXI write response channel signals
                     input wire [AXI_ID_WIDTH-1:0]     b_id,     // Response ID
                     input wire [1:0]                    b_resp,   // Write response
                     input wire                          b_valid,  // Write reponse valid
                     input wire                          b_ready,   // Response ready

                     // AXI read address channel signals
                     input  wire                         ar_ready, // Read address ready
                     input  wire [AXI_ID_WIDTH-1:0]    ar_id,    // Read ID
                     input  wire [AXI_ADDR_WIDTH-1:0]  ar_addr,  // Read address
                     input  wire [AXI_LEN_WIDTH-1:0]   ar_len,   // Read Burst Length
                     input  wire [2:0]                   ar_size,  // Read Burst size
                     input  wire [1:0]                   ar_burst, // Read Burst type
                     input  wire [0:0]                   ar_lock,  // Read lock type
                     input  wire [3:0]                   ar_cache, // Read Cache type
                     input  wire [2:0]                   ar_prot,  // Read Protection type
                     input  wire [3:0]                   ar_qos,   // Read Protection type
                     input  wire                         ar_valid, // Read address valid

                     // AXI read data channel signals
                     input  wire [AXI_ID_WIDTH-1:0]    r_id,    // Response ID
                     input  wire [1:0]                   r_resp,  // Read response
                     input  wire                         r_valid, // Read reponse valid
                     input  wire [AXI_DATA_WIDTH-1:0]  r_data,  // Read data
                     input  wire                         r_last,  // Read last
                     input  wire                         r_ready  // Read Response ready
                    );
  import axi_tb_pkg::*;

  axi_tb_pkg::atop_t   aw_atop;


  // rename the input signals
  logic [AXI_ID_WIDTH-1:0]	 awid;
  logic [AXI_ADDR_WIDTH-1:0]   awaddr;
  logic                          awvalid;
  logic                          awready;
  logic [AXI_LEN_WIDTH-1:0]    awlen;
  logic [2:0]                    awsize;
  logic [1:0]                    awburst;
  logic [0:0]                    awlock;
  logic [3:0]                    awcache;
  logic [2:0]                    awprot;
  logic [3:0]                    awqos;

                     // AXI write data channel signals
  logic                          wready;
  logic [AXI_DATA_WIDTH-1:0]   wdata;
  logic [AXI_DATA_WIDTH/8-1:0] wstrb;
  logic                          wlast;
  logic                          wvalid;

                     // AXI write response channel signals
  logic [AXI_ID_WIDTH-1:0]     bid;
  logic [1:0]                    bresp;
  logic                          bvalid;
  logic                          bready;

   // AXI read address channel signals
  logic                          arready;
  logic  [AXI_ID_WIDTH-1:0]    arid;
  logic  [AXI_ADDR_WIDTH-1:0]  araddr;
  logic  [AXI_LEN_WIDTH-1:0]   arlen;
  logic  [2:0]                   arsize;
  logic  [1:0]                   arburst;
  logic  [0:0]                   arlock;
  logic  [3:0]                   arcache;
  logic  [2:0]                   arprot;
  logic  [3:0]                   arqos;
  logic                          arvalid;

                     // AXI read data channel signals
  logic [AXI_ID_WIDTH-1:0]     rid;
  logic [1:0]                    rresp;
  logic                          rvalid;
  logic [AXI_DATA_WIDTH-1:0]   rdata;
  logic                          rlast;
  logic                          rready;

  // internal axi signals
  logic [AXI_ID_WIDTH-1:0]	 iawid;
  logic [AXI_ADDR_WIDTH-1:0]   iawaddr;
  logic                          iawvalid;
  logic                          iawready;
  logic [AXI_LEN_WIDTH-1:0]    iawlen;
  logic [2:0]                    iawsize;
  logic [1:0]                    iawburst;
  logic [0:0]                    iawlock;
  logic [3:0]                    iawcache;
  logic [2:0]                    iawprot;
  logic [3:0]                    iawqos;

                     // AXI write data channel signals
  logic                          iwready;
  logic [AXI_DATA_WIDTH-1:0]   iwdata;
  logic [AXI_DATA_WIDTH/8-1:0] iwstrb;
  logic                          iwlast;
  logic                          iwvalid;

                     // AXI write response channel signals
  logic [AXI_ID_WIDTH-1:0]     ibid;
  logic [1:0]                    ibresp;
  logic                          ibvalid;
  logic                          ibready;

   // AXI read address channel signals
  logic                          iarready;
  logic  [AXI_ID_WIDTH-1:0]    iarid;
  logic  [AXI_ADDR_WIDTH-1:0]  iaraddr;
  logic  [AXI_LEN_WIDTH-1:0]   iarlen;
  logic  [2:0]                   iarsize;
  logic  [1:0]                   iarburst;
  logic  [0:0]                   iarlock;
  logic  [3:0]                   iarcache;
  logic  [2:0]                   iarprot;
  logic  [3:0]                   iarqos;
  logic                          iarvalid;

                     // AXI read data channel signals
  logic [AXI_ID_WIDTH-1:0]     irid;
  logic [1:0]                    irresp;
  logic                          irvalid;
  logic [AXI_DATA_WIDTH-1:0]   irdata;
  logic                          irlast;
  logic                          irready;


  logic [31:0] awready_toggle_pattern;
  bit          awready_toggle_pattern_enable=0;

  logic [31:0]  wready_toggle_pattern;
  bit           wready_toggle_pattern_enable=0;

  logic [31:0]  bready_toggle_pattern;
  bit           bready_toggle_pattern_enable=0;

  logic [31:0]  arready_toggle_pattern;
  bit           arready_toggle_pattern_enable=0;

  logic [31:0]  rready_toggle_pattern;
  bit           rready_toggle_pattern_enable=0;


  assign awid    = aw_id;
  assign awaddr  = aw_addr;
  assign awvalid = aw_valid;
  assign awready = aw_ready;
  assign awlen   = aw_len;
  assign awsize  = aw_size;
  assign awburst = aw_burst;
  assign awlock  = aw_lock;
  assign awcache = aw_cache;
  assign awprot  = aw_prot;
  assign awqos   = aw_qos;

  assign wready  = w_ready;
  assign wdata   = w_data;
  assign wstrb   = w_strb;
  assign wlast   = w_last;
  assign wvalid  = w_valid;

  assign bid     = b_id;
  assign bresp   = b_resp;
  assign bvalid  = b_valid;
  assign bready  = b_ready;

  assign arready = ar_ready;
  assign arid    = ar_id;
  assign araddr  = ar_addr;
  assign arlen   = ar_len;
  assign arsize  = ar_size;
  assign arburst = ar_burst;
  assign arlock  = ar_lock;
  assign arcache = ar_cache;
  assign arprot  = ar_prot;
  assign arqos   = ar_qos;
  assign arvalid = ar_valid;

  assign rid     = r_id;
  assign rresp   = r_resp;
  assign rvalid  = r_valid;
  assign rdata   = r_data;
  assign rlast   = r_last;
  assign rready  = r_ready;

    // AXI capture read data signals
  logic [AXI_ID_WIDTH-1:0]     rid_d1;
  logic [1:0]                    rresp_d1;
  logic                          rvalid_d1;
  logic [AXI_DATA_WIDTH-1:0]   rdata_d1;
  logic                          rlast_d1;
  logic                          rready_d1;

  always_ff @(posedge clk) begin
      rid_d1 <= rid;
      rresp_d1 <= rresp;
      rvalid_d1 <= rvalid;
      rdata_d1 <= rdata;
      rlast_d1 <= rlast;
      rready_d1 <= rready;
  end

  // assign awid    = iawid;
  // assign awaddr  = iawaddr;
  // assign awvalid = iawvalid;
  // assign awready = iawready;
  // assign awlen   = iawlen;
  // assign awsize  = iawsize;
  // assign awburst = iawburst;
  // assign awlock  = iawlock;
  // assign awcache = iawcache;
  // assign awprot  = iawprot;
  // assign awqos   = iawqos;

  // assign wready  = iwready;
  // assign wdata   = iwdata;
  // assign wstrb   = iwstrb;
  // assign wlast   = iwlast;
  // assign wvalid  = iwvalid;

  // assign bid     = ibid;
  // assign bresp   = ibresp;
  // assign bvalid  = ibvalid;
  // assign bready  = ibready;

  // assign arready = iarready;
  // assign arid    = iarid;
  // assign araddr  = iaraddr;
  // assign arlen   = iarlen;
  // assign arsize  = iarsize;
  // assign arburst = iarburst;
  // assign arlock  = iarlock;
  // assign arcache = iarcache;
  // assign arprot  = iarprot;
  // assign arqos   = iarqos;
  // assign arvalid = iarvalid;

  // assign rid     = irid;
  // assign rresp   = irresp;
  // assign rvalid  = irvalid;
  // assign rdata   = irdata;
  // assign rlast   = irlast;
  // assign rready  = irready;


  initial begin
     iawid    = 'z;
     iawaddr  = 'z;
     iawvalid = 'z;
     iawready = 'z;
     iawlen   = 'z;
     iawsize  = 'z;
     iawburst = 'z;
     iawlock  = 'z;
     iawcache = 'z;
     iawprot  = 'z;
     iawqos   = 'z;

     iwready = 'z;
     iwdata  = 'z;
     iwstrb  = 'z;
     iwlast  = 'z;
     iwvalid = 'z;

     ibid    = 'z;
     ibresp  = 'z;
     ibvalid = 'z;
     ibready = 'z;

     iarready = 'z;
     iarid    = 'z;
     iaraddr  = 'z;
     iarlen   = 'z;
     iarsize  = 'z;
     iarburst = 'z;
     iarlock  = 'z;
     iarcache = 'z;
     iarprot  = 'z;
     iarqos   = 'z;
     iarvalid = 'z;

     irid     = 'z;
     irresp   = 'z;
     irvalid  = 'z;
     irdata   = 'z;
     irlast   = 'z;
     irready  = 'z;

  end
// wait for n clock cycles. Default: 1
task wait_for_clks(int cnt=1);
    if (cnt==0) return;
    repeat (cnt) @(posedge clk);
endtask : wait_for_clks

task wait_for_not_in_reset;
    wait (reset == 1'b0);
endtask : wait_for_not_in_reset;

task detected_clken_toggled;
        wait (clken == 1'b0);
        $display("%t -- %m:: INFO :: got CLKEN off...", $time);
        wait (clken == 1'b1);
        $display("%t -- %m:: INFO :: got CLKEN on...", $time);
endtask : detected_clken_toggled

task wait_for_awready_awvalid;

  if (awready == 1'b1 && awvalid == 1'b1)
    return;
  else  if (awvalid == 1'b1)
    @(posedge awready);
  else  if (awready == 1'b1)
    @(posedge awvalid);
  else
    @(posedge awvalid or posedge awready)  wait_for_awready_awvalid();

endtask : wait_for_awready_awvalid


task wait_for_awvalid;
  @(posedge awvalid);
endtask : wait_for_awvalid;

task wait_for_wready;
  while (wready != 1'b1)
    wait_for_clks(.cnt(1));
endtask : wait_for_wready

task wait_for_bvalid;
  @(posedge bvalid);
endtask : wait_for_bvalid

task wait_for_write_address(output axi_seq_item_aw_vector_s s);
    //wait_for_awready_awvalid();
  forever begin
    @(posedge clk) begin
      if (awready == 1'b1 && awvalid== 1'b1) begin
        read_aw(.s(s));
        return;
      end
    end
  end
endtask : wait_for_write_address

task wait_for_write_data(output axi_seq_item_w_vector_s s);

  forever begin
    @(posedge clk) begin
      if (wready == 1'b1 && wvalid== 1'b1) begin
        read_w(.s(s));
        return;
      end
    end
  end
endtask : wait_for_write_data

task wait_for_write_response(output axi_seq_item_b_vector_s s);

  forever begin
    @(posedge clk) begin
      if (bready == 1'b1 && bvalid== 1'b1) begin
        read_b(.s(s));
        return;
      end
    end
  end
endtask : wait_for_write_response

task wait_for_read_address(output axi_seq_item_ar_vector_s s);
    //wait_for_awready_awvalid();
  forever begin
    @(posedge clk) begin
      if (arready == 1'b1 && arvalid== 1'b1) begin
        read_ar(.s(s));
        return;
      end
    end
  end
endtask : wait_for_read_address

task wait_for_read_data(output axi_seq_item_r_vector_s s);

  forever begin
    @(posedge clk) begin
      if (rready == 1'b1 && rvalid== 1'b1) begin
        read_r(.s(s));
        return;
      end
    end
  end
endtask : wait_for_read_data

function bit get_awready_awvalid;
  return awready & awvalid;
endfunction : get_awready_awvalid;

function bit get_awready;
  return awready;
endfunction : get_awready;

function bit get_wready_wvalid;
  return wvalid & wready;
endfunction : get_wready_wvalid;

function bit get_wvalid;
  return wvalid;
endfunction : get_wvalid

function bit get_wready;
  return wready;
endfunction : get_wready

function bit get_bready_bvalid;
  return bready & bvalid;
endfunction : get_bready_bvalid;

function bit get_bvalid;
  return bvalid;
endfunction : get_bvalid

function bit get_bready;
  return bready;
endfunction : get_bready

function bit get_arready_arvalid;
  return arready & arvalid;
endfunction : get_arready_arvalid;

function bit get_arready;
  return arready;
endfunction : get_arready;

function bit get_rready_rvalid;
  return rvalid & rready;
endfunction : get_rready_rvalid;

function bit get_rvalid;
  return rvalid;
endfunction : get_rvalid

function bit get_rready;
  return rready;
endfunction : get_rready

task set_awvalid(bit state);
  wait_for_clks(.cnt(1));
  iawvalid <= state;
endtask : set_awvalid

task set_awready(bit state);
    wait_for_clks(.cnt(1));
    iawready <= state;
endtask : set_awready

task set_wvalid(bit state);
  wait_for_clks(.cnt(1));
  iwvalid <= state;
endtask : set_wvalid

task set_wready(bit state);
  wait_for_clks(.cnt(1));
    iwready <= state;
endtask : set_wready

task set_bvalid(bit state);
  wait_for_clks(.cnt(1));
  ibvalid <= state;
endtask : set_bvalid

task set_bready(bit state);
  wait_for_clks(.cnt(1));
    ibready <= state;
endtask : set_bready

task set_arvalid(bit state);
  wait_for_clks(.cnt(1));
  iarvalid <= state;
endtask : set_arvalid

task set_rvalid(bit state);
  wait_for_clks(.cnt(1));
  irvalid <= state;
endtask : set_rvalid

task set_rready(bit state);
  wait_for_clks(.cnt(1));
    irready <= state;
endtask : set_rready

function void enable_awready_toggle_pattern(bit [31:0] pattern);
    awready_toggle_pattern=pattern;
    awready_toggle_pattern_enable=1;
endfunction : enable_awready_toggle_pattern

function void disable_awready_toggle_pattern();
     awready_toggle_pattern_enable = 0;
endfunction : disable_awready_toggle_pattern

function void enable_wready_toggle_pattern(bit [31:0] pattern);
    wready_toggle_pattern=pattern;
    wready_toggle_pattern_enable=1;
endfunction : enable_wready_toggle_pattern

function void disable_wready_toggle_pattern();
     wready_toggle_pattern_enable = 0;
endfunction : disable_wready_toggle_pattern

function void enable_bready_toggle_pattern(bit [31:0] pattern);
    bready_toggle_pattern=pattern;
    bready_toggle_pattern_enable=1;
endfunction : enable_bready_toggle_pattern

function void disable_bready_toggle_pattern();
     bready_toggle_pattern_enable = 0;
endfunction : disable_bready_toggle_pattern

function void enable_arready_toggle_pattern(bit [31:0] pattern);
    arready_toggle_pattern=pattern;
    arready_toggle_pattern_enable=1;
endfunction : enable_arready_toggle_pattern

function void disable_arready_toggle_pattern();
     arready_toggle_pattern_enable = 0;
endfunction : disable_arready_toggle_pattern

function void enable_rready_toggle_pattern(bit [31:0] pattern);
    rready_toggle_pattern=pattern;
    rready_toggle_pattern_enable=1;
endfunction : enable_rready_toggle_pattern

function void disable_rready_toggle_pattern();
     rready_toggle_pattern_enable = 0;
endfunction : disable_rready_toggle_pattern


function void write_aw(axi_seq_item_aw_vector_s s, bit valid=1'b1);

     iawvalid <= valid;
     iawid    <= s.awid;
     iawaddr  <= s.awaddr;
     iawlen   <= s.awlen;
     iawsize  <= s.awsize;
     iawburst <= s.awburst;
     iawlock  <= s.awlock;
     iawcache <= s.awcache;
     iawprot  <= s.awprot;
     iawqos   <= s.awqos;


endfunction : write_aw


function void write_w(axi_seq_item_w_vector_s  s);

    iwvalid <= s.wvalid;
    iwdata  <= s.wdata;
    iwstrb  <= s.wstrb;
    iwlast  <= s.wlast;

endfunction : write_w

function void write_b(axi_seq_item_b_vector_s s, bit valid=1'b1);

  ibvalid <= valid;
  ibid    <= s.bid;
  ibresp  <= s.bresp;

endfunction : write_b

function void read_aw(output axi_seq_item_aw_vector_s s);

     s.awvalid = awvalid;
     s.awid    = awid;
     s.awaddr  = awaddr;
     s.awlen   = awlen;
    s.awsize  = awsize;
    s.awburst = awburst;
     s.awlock  = awlock;
     s.awcache = awcache;
     s.awprot  = awprot;
     s.awqos   = awqos;

endfunction : read_aw


function void read_w(output axi_seq_item_w_vector_s  s);

    s.wvalid = wvalid;
    s.wdata = wdata;
    s.wstrb = wstrb;
    s.wlast = wlast;

endfunction : read_w

function void read_b(output axi_seq_item_b_vector_s  s);
  s.bid   = bid;
  s.bresp = bresp;
endfunction : read_b


function void write_ar(axi_seq_item_ar_vector_s s, bit valid=1'b1);

     iarvalid <= valid;
     iarid    <= s.arid;
     iaraddr  <= s.araddr;
     iarlen   <= s.arlen;
     iarsize  <= s.arsize;
     iarburst <= s.arburst;
     iarlock  <= s.arlock;
     iarcache <= s.arcache;
     iarprot  <= s.arprot;
     iarqos   <= s.arqos;


endfunction : write_ar

function void write_r(axi_seq_item_r_vector_s  s);

    irvalid <= s.rvalid;
    irdata  <= s.rdata;
    //irstrb  <= s.rstrb;
    irlast  <= s.rlast;
    irid     <= s.rid;

endfunction : write_r


function void read_ar(output axi_seq_item_ar_vector_s s);

     s.arvalid = arvalid;
     s.arid    = arid;
     s.araddr  = araddr;
     s.arlen   = arlen;
     s.arsize  = arsize;
     s.arburst = arburst;
     s.arlock  = arlock;
     s.arcache = arcache;
     s.arprot  = arprot;
     s.arqos   = arqos;

endfunction : read_ar

function void read_r(output axi_seq_item_r_vector_s  s);

    s.rvalid = rvalid;
    s.rdata  = rdata;
    s.rlast  = rlast;
    s.rid    = rid;
    s.rresp  = rresp;

endfunction : read_r


// *ready toggling
initial begin
   forever begin
     @(posedge clk) begin
       if (awready_toggle_pattern_enable == 1'b1) begin
         awready_toggle_pattern[31:0] <= {awready_toggle_pattern[30:0], awready_toggle_pattern[31]};
            iawready                  <= awready_toggle_pattern[31];
         end
      end
   end
end


initial begin
   forever begin
     @(posedge clk) begin
       if (wready_toggle_pattern_enable == 1'b1) begin
         wready_toggle_pattern[31:0] <= {wready_toggle_pattern[30:0], wready_toggle_pattern[31]};
            iwready                 <= wready_toggle_pattern[31];
        end
      end
   end
end

initial begin
   forever begin
     @(posedge clk) begin
       if (bready_toggle_pattern_enable == 1'b1) begin
         bready_toggle_pattern[31:0] <= {bready_toggle_pattern[30:0], bready_toggle_pattern[31]};
            ibready                 <= bready_toggle_pattern[31];
        end
      end
   end
end


initial begin
   forever begin
     @(posedge clk) begin
       if (arready_toggle_pattern_enable == 1'b1) begin
         arready_toggle_pattern[31:0] <= {arready_toggle_pattern[30:0],
                                          arready_toggle_pattern[31]};

            iarready                  <= arready_toggle_pattern[31];
         end
      end
   end
end

initial begin
   forever begin
     @(posedge clk) begin
       if (rready_toggle_pattern_enable == 1'b1) begin
         rready_toggle_pattern[31:0] <= {rready_toggle_pattern[30:0],
                                          rready_toggle_pattern[31]};

            irready                  <= rready_toggle_pattern[31];
         end
      end
   end
end


endinterface : axi_if_bfm
