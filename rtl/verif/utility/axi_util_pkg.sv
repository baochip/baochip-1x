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

//  Description : AXI Testbench Utility Packsge
//                contains AXI class tasks
//
//
/////////////////////////////////////////////////////////////////////////// 


/// A set of testbench utilities for AXI interfaces.
package axi_util_pkg;

  import tb_util_pkg::*;
  import axi_tb_pkg::*;


  /// The data transferred on a beat on the AW/AR channels.
  class axi_ax_beat #(
    parameter AW = 32,
    parameter IW = 8 ,
    parameter UW = 1
  );
    rand logic [IW-1:0] ax_id     = '0;
    rand logic [AW-1:0] ax_addr   = '0;
    logic [7:0]         ax_len    = '0;
    logic [2:0]         ax_size   = '0;
    logic [1:0]         ax_burst  = '0;
    logic               ax_lock   = '0;
    logic [3:0]         ax_cache  = '0;
    logic [2:0]         ax_prot   = '0;
    rand logic [3:0]    ax_qos    = '0;
    logic [3:0]         ax_region = '0;
    logic [5:0]         ax_atop   = '0; // Only defined on the AW channel.
    rand logic [UW-1:0] ax_user   = '0;
  endclass

  /// The data transferred on a beat on the W channel.
  class axi_w_beat #(
    parameter DW = 32,
    parameter IW = 8 ,
    parameter UW = 1
  );
    rand logic [IW-1:0]   w_id  = '0;
    rand logic [DW-1:0]   w_data = '0;
    rand logic [DW/8-1:0] w_strb = '0;
    logic                 w_last = '0;
    rand logic [UW-1:0]   w_user = '0;
  endclass

  /// The data transferred on a beat on the B channel.
  class axi_b_beat #(
    parameter IW = 8,
    parameter UW = 1
  );
    rand logic [IW-1:0] b_id   = '0;
    axi_tb_pkg::resp_t     b_resp = '0;
    rand logic [UW-1:0] b_user = '0;
  endclass

  /// The data transferred on a beat on the R channel.
  class axi_r_beat #(
    parameter DW = 32,
    parameter IW = 8 ,
    parameter UW = 1
  );
    rand logic [IW-1:0] r_id   = '0;
    rand logic [DW-1:0] r_data = '0;
    axi_tb_pkg::resp_t     r_resp = '0;
    logic               r_last = '0;
    rand logic [UW-1:0] r_user = '0;
  endclass

  /// A driver for AXI4 interface.
  class axi_driver #(
    parameter int  AW = 32  ,
    parameter int  DW = 32  ,
    parameter int  IW = 8   ,
    parameter int  UW = 1   ,
    parameter time TA = 0ns , // stimuli application time
    parameter time TT = 0ns   // stimuli test time
  );
    virtual axi_if_mst   #(.AW(AW),.DW(DW),.IDW(IW),.LENW(8),.UW(UW))      axi;

    typedef logic [DW-1:0] data_t;
    typedef axi_ax_beat #(.AW(AW), .IW(IW), .UW(UW)) ax_beat_t;
    typedef axi_w_beat  #(.DW(DW), .IW(IW), .UW(UW)) w_beat_t;
    typedef axi_b_beat  #(.IW(IW), .UW(UW))          b_beat_t;
    typedef axi_r_beat  #(.DW(DW), .IW(IW), .UW(UW)) r_beat_t;

    function new(
      virtual axi_if_mst   #(.AW(AW),.DW(DW),.IDW(IW),.LENW(8),.UW(UW)) cm7_axim_vif
    );
      this.axi = cm7_axim_vif;
    endfunction

    function void reset_master();
      axi.aw_id     <= '0;
      axi.aw_addr   <= '0;
      axi.aw_len    <= '0;
      axi.aw_size   <= '0;
      axi.aw_burst  <= '0;
      axi.aw_lock   <= '0;
      axi.aw_cache  <= '0;
      axi.aw_prot   <= '0;
      axi.aw_qos    <= '0;
      axi.aw_region <= '0;
      axi.aw_atop   <= '0;
      axi.aw_user   <= '0;
      axi.aw_valid  <= '0;
      axi.w_data    <= '0;
      axi.w_strb    <= '0;
      axi.w_last    <= '0;
      axi.w_user    <= '0;
      axi.w_valid   <= '0;
      axi.b_ready   <= '0;
      axi.ar_id     <= '0;
      axi.ar_addr   <= '0;
      axi.ar_len    <= '0;
      axi.ar_size   <= '0;
      axi.ar_burst  <= '0;
      axi.ar_lock   <= '0;
      axi.ar_cache  <= '0;
      axi.ar_prot   <= '0;
      axi.ar_qos    <= '0;
      axi.ar_region <= '0;
      axi.ar_user   <= '0;
      axi.ar_valid  <= '0;
      axi.r_ready   <= '0;
    endfunction

    function void reset_slave();
      axi.aw_ready  <= '0;
      axi.w_ready   <= '0;
      axi.b_id      <= '0;
      axi.b_resp    <= '0;
      axi.b_user    <= '0;
      axi.b_valid   <= '0;
      axi.ar_ready  <= '0;
      axi.r_id      <= '0;
      axi.r_data    <= '0;
      axi.r_resp    <= '0;
      axi.r_last    <= '0;
      axi.r_user    <= '0;
      axi.r_valid   <= '0;
    endfunction

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge axi.clk);
    endtask

    /// Issue a beat on the AW channel.
    task send_aw (
      input ax_beat_t beat
    );
      axi.aw_id     <= #TA beat.ax_id;
      axi.aw_addr   <= #TA beat.ax_addr;
      axi.aw_len    <= #TA beat.ax_len;
      axi.aw_size   <= #TA beat.ax_size;
      axi.aw_burst  <= #TA beat.ax_burst;
      axi.aw_lock   <= #TA beat.ax_lock;
      axi.aw_cache  <= #TA beat.ax_cache;
      axi.aw_prot   <= #TA beat.ax_prot;
      axi.aw_qos    <= #TA beat.ax_qos;
      axi.aw_region <= #TA beat.ax_region;
      axi.aw_atop   <= #TA beat.ax_atop;
      axi.aw_user   <= #TA beat.ax_user;
      axi.aw_valid  <= #TA 1;
      cycle_start();
      while (axi.aw_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      axi.aw_id     <= #TA '0;
      axi.aw_addr   <= #TA '0;
      axi.aw_len    <= #TA '0;
      axi.aw_size   <= #TA '0;
      axi.aw_burst  <= #TA '0;
      axi.aw_lock   <= #TA '0;
      axi.aw_cache  <= #TA '0;
      axi.aw_prot   <= #TA '0;
      axi.aw_qos    <= #TA '0;
      axi.aw_region <= #TA '0;
      axi.aw_atop   <= #TA '0;
      axi.aw_user   <= #TA '0;
      axi.aw_valid  <= #TA 0;
    endtask

    /// Issue a beat on the W channel.
    task send_w (
      input w_beat_t beat
    );
      axi.w_id    <= #TA beat.w_id;
      axi.w_data  <= #TA beat.w_data;
      axi.w_strb  <= #TA beat.w_strb;
      axi.w_last  <= #TA beat.w_last;
      axi.w_user  <= #TA beat.w_user;
      axi.w_valid <= #TA 1;
      cycle_start();
      while (axi.w_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      axi.w_id    <= #TA '0;
      axi.w_data  <= #TA '0;
      axi.w_strb  <= #TA '0;
      axi.w_last  <= #TA '0;
      axi.w_user  <= #TA '0;
      axi.w_valid <= #TA 0;
    endtask

    /// Issue a beat on the B channel.
    task send_b (
      input b_beat_t beat
    );
      axi.b_id    <= #TA beat.b_id;
      axi.b_resp  <= #TA beat.b_resp;
      axi.b_user  <= #TA beat.b_user;
      axi.b_valid <= #TA 1;
      cycle_start();
      while (axi.b_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      axi.b_id    <= #TA '0;
      axi.b_resp  <= #TA '0;
      axi.b_user  <= #TA '0;
      axi.b_valid <= #TA 0;
    endtask

    /// Issue a beat on the AR channel.
    task send_ar (
      input ax_beat_t beat
    );
      axi.ar_id     <= #TA beat.ax_id;
      axi.ar_addr   <= #TA beat.ax_addr;
      axi.ar_len    <= #TA beat.ax_len;
      axi.ar_size   <= #TA beat.ax_size;
      axi.ar_burst  <= #TA beat.ax_burst;
      axi.ar_lock   <= #TA beat.ax_lock;
      axi.ar_cache  <= #TA beat.ax_cache;
      axi.ar_prot   <= #TA beat.ax_prot;
      axi.ar_qos    <= #TA beat.ax_qos;
      axi.ar_region <= #TA beat.ax_region;
      axi.ar_user   <= #TA beat.ax_user;
      axi.ar_valid  <= #TA 1;
      cycle_start();
      while (axi.ar_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      // axi.ar_id     <= #TA '0;
      // axi.ar_addr   <= #TA '0;
      // axi.ar_len    <= #TA '0;
      // axi.ar_size   <= #TA '0;
      // axi.ar_burst  <= #TA '0;
      // axi.ar_lock   <= #TA '0;
      // axi.ar_cache  <= #TA '0;
      // axi.ar_prot   <= #TA '0;
      // axi.ar_qos    <= #TA '0;
      // axi.ar_region <= #TA '0;
      // axi.ar_user   <= #TA '0;
      axi.ar_valid  <= #TA 0;
    endtask

    /// Issue a beat on the R channel.
    task send_r (
      input r_beat_t beat
    );
      axi.r_id    <= #TA beat.r_id;
      axi.r_data  <= #TA beat.r_data;
      axi.r_resp  <= #TA beat.r_resp;
      axi.r_last  <= #TA beat.r_last;
      axi.r_user  <= #TA beat.r_user;
      axi.r_valid <= #TA 1;
      cycle_start();
      while (axi.r_ready != 1) begin cycle_end(); cycle_start(); end
      cycle_end();
      axi.r_id    <= #TA '0;
      axi.r_data  <= #TA '0;
      axi.r_resp  <= #TA '0;
      axi.r_last  <= #TA '0;
      axi.r_user  <= #TA '0;
      axi.r_valid <= #TA '0;
    endtask

    /// Wait for a beat on the AW channel.
    task recv_aw (
      output ax_beat_t beat
    );
      axi.aw_ready <= #TA 1;
      cycle_start();
      while (axi.aw_valid != 1) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.ax_id     = axi.aw_id;
      beat.ax_addr   = axi.aw_addr;
      beat.ax_len    = axi.aw_len;
      beat.ax_size   = axi.aw_size;
      beat.ax_burst  = axi.aw_burst;
      beat.ax_lock   = axi.aw_lock;
      beat.ax_cache  = axi.aw_cache;
      beat.ax_prot   = axi.aw_prot;
      beat.ax_qos    = axi.aw_qos;
      beat.ax_region = axi.aw_region;
      beat.ax_atop   = axi.aw_atop;
      beat.ax_user   = axi.aw_user;
      cycle_end();
      axi.aw_ready <= #TA 0;
    endtask

    /// Wait for a beat on the W channel.
    task recv_w (
      output w_beat_t beat
    );
      axi.w_ready <= #TA 1;
      cycle_start();
      while (axi.w_valid != 1) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.w_data = axi.w_data;
      beat.w_strb = axi.w_strb;
      beat.w_last = axi.w_last;
      beat.w_user = axi.w_user;
      cycle_end();
      axi.w_ready <= #TA 0;
    endtask

    /// Wait for a beat on the B channel.
    task recv_b (
      output b_beat_t beat
    );
      axi.b_ready <= #TA 1;
      cycle_start();
      while (axi.b_valid != 1) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.b_id   = axi.b_id;
      beat.b_resp = axi.b_resp;
      beat.b_user = axi.b_user;
      cycle_end();
      axi.b_ready <= #TA 0;
    endtask

    /// Wait for a beat on the AR channel.
    task recv_ar (
      output ax_beat_t beat
    );
      axi.ar_ready  <= #TA 1;
      cycle_start();
      while (axi.ar_valid != 1) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.ax_id     = axi.ar_id;
      beat.ax_addr   = axi.ar_addr;
      beat.ax_len    = axi.ar_len;
      beat.ax_size   = axi.ar_size;
      beat.ax_burst  = axi.ar_burst;
      beat.ax_lock   = axi.ar_lock;
      beat.ax_cache  = axi.ar_cache;
      beat.ax_prot   = axi.ar_prot;
      beat.ax_qos    = axi.ar_qos;
      beat.ax_region = axi.ar_region;
      beat.ax_atop   = 'X;  // Not defined on the AR channel.
      beat.ax_user   = axi.ar_user;
      cycle_end();
      axi.ar_ready  <= #TA 0;
    endtask

    /// Wait for a beat on the R channel.
    task recv_r (
      output r_beat_t beat
    );
      axi.r_ready <= #TA 1;
      cycle_start();
      // while (axi.r_valid && axi.r_ready) begin cycle_end(); cycle_start(); end
      //@(posedge axi.clk iff(!axi.r_valid));
      @(posedge axi.clk iff(axi.r_valid&&axi.r_ready));
      beat = new;
      beat.r_id   = axi.r_id;
      beat.r_data = axi.r_data;
      beat.r_resp = axi.r_resp;
      beat.r_last = axi.r_last;
      beat.r_user = axi.r_user;
      //cycle_end();
      //axi.r_ready <= #TA 0;
    endtask

    /// Monitor the AW channel and return the next beat.
    task mon_aw (
      output ax_beat_t beat
    );
      cycle_start();
      while (!(axi.aw_valid && axi.aw_ready)) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.ax_id     = axi.aw_id;
      beat.ax_addr   = axi.aw_addr;
      beat.ax_len    = axi.aw_len;
      beat.ax_size   = axi.aw_size;
      beat.ax_burst  = axi.aw_burst;
      beat.ax_lock   = axi.aw_lock;
      beat.ax_cache  = axi.aw_cache;
      beat.ax_prot   = axi.aw_prot;
      beat.ax_qos    = axi.aw_qos;
      beat.ax_region = axi.aw_region;
      beat.ax_atop   = axi.aw_atop;
      beat.ax_user   = axi.aw_user;
      cycle_end();
    endtask

    /// Monitor the W channel and return the next beat.
    task mon_w (
      output w_beat_t beat
    );
      cycle_start();
      while (!(axi.w_valid && axi.w_ready)) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.w_data = axi.w_data;
      beat.w_strb = axi.w_strb;
      beat.w_last = axi.w_last;
      beat.w_user = axi.w_user;
      cycle_end();
    endtask

    /// Monitor the B channel and return the next beat.
    task mon_b (
      output b_beat_t beat
    );
      cycle_start();
      while (!(axi.b_valid && axi.b_ready)) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.b_id   = axi.b_id;
      beat.b_resp = axi.b_resp;
      beat.b_user = axi.b_user;
      cycle_end();
    endtask

    /// Monitor the AR channel and return the next beat.
    task mon_ar (
      output ax_beat_t beat
    );
      cycle_start();
      while (!(axi.ar_valid && axi.ar_ready)) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.ax_id     = axi.ar_id;
      beat.ax_addr   = axi.ar_addr;
      beat.ax_len    = axi.ar_len;
      beat.ax_size   = axi.ar_size;
      beat.ax_burst  = axi.ar_burst;
      beat.ax_lock   = axi.ar_lock;
      beat.ax_cache  = axi.ar_cache;
      beat.ax_prot   = axi.ar_prot;
      beat.ax_qos    = axi.ar_qos;
      beat.ax_region = axi.ar_region;
      beat.ax_atop   = 'X;  // Not defined on the AR channel.
      beat.ax_user   = axi.ar_user;
      cycle_end();
    endtask

    /// Monitor the R channel and return the next beat.
    task mon_r (
      output r_beat_t beat
    );
      cycle_start();
      while (!(axi.r_valid && axi.r_ready)) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.r_id   = axi.r_id;
      beat.r_data = axi.r_data;
      beat.r_resp = axi.r_resp;
      beat.r_last = axi.r_last;
      beat.r_user = axi.r_user;
      cycle_end();
    endtask

    task axi_regrw (
        input [567:0] axi_packet,
        output [511:0] axi_rcvd_data,
        output pass
    );
      logic [3:0] rand_4b;
      logic [567:0] reg_para;
      logic [512:0] reg_wdata;
      logic [7:0] action;
      logic [63:0] dummy_64;
      data_t exp_data[$];
      ax_beat_t aw_beat = new, ar_beat = new;
      w_beat_t w_beat = new;
      b_beat_t b_beat = new;
      r_beat_t r_beat = new;
      pass = `PASS;
      reg_para = axi_packet << (567 - list_length(axi_packet));
      {action, reg_para} = {reg_para, 8'h0};
      case(action)
          `AXI_WD_PACKET: begin
              {aw_beat.ax_id, reg_para} = {reg_para, 4'h0};
              {aw_beat.ax_prot, reg_para} = {reg_para, 3'h0};
              {aw_beat.ax_burst, reg_para} = {reg_para, 2'h0};
              {aw_beat.ax_size, reg_para} = {reg_para, 3'h0};
              {aw_beat.ax_len, reg_para} = {reg_para, 4'h0};
              {aw_beat.ax_addr, reg_para} = {reg_para, 32'h0};
              {reg_wdata, reg_para} = {reg_para, 512'h0};
              aw_beat.ax_cache = 4'hf;
              aw_beat.ax_user = 8'h2;
              send_aw(aw_beat);
              for (int unsigned i = 0; i <= aw_beat.ax_len; i++) begin
                  w_beat.w_id = aw_beat.ax_id;
                  {reg_wdata, w_beat.w_data[63:0]} = {64'h0, reg_wdata};
                  w_beat.w_strb = '1;
                  if (i == aw_beat.ax_len) begin
                    w_beat.w_last = 1'b1;
                  end
                  send_w(w_beat);
                  exp_data.push_back(w_beat.w_data);
              end
              recv_b(b_beat);
              assert(b_beat.b_resp == axi_tb_pkg::RESP_OKAY);
              repeat (std::randomize(rand_4b)+10) @(posedge axi.clk);
          end
          `AXI_AR_PACKET: begin
              {ar_beat.ax_id, reg_para} = {reg_para, 4'h0};
              {ar_beat.ax_prot, reg_para} = {reg_para, 3'h0};
              {ar_beat.ax_burst, reg_para} = {reg_para, 2'h0};
              {ar_beat.ax_size, reg_para} = {reg_para, 3'h0};
              {ar_beat.ax_len, reg_para} = {reg_para, 4'h0};
              {ar_beat.ax_addr, reg_para} = {reg_para, 32'h0};
              ar_beat.ax_cache = 4'hf;
              aw_beat.ax_user = 8'h2;
              send_ar(ar_beat);
              axi_rcvd_data = 0;
              // R beats
              for (int unsigned i = 0; i <= ar_beat.ax_len; i++) begin
                automatic data_t exp = exp_data.pop_front();
                recv_r(r_beat);
                {axi_rcvd_data, dummy_64} = {r_beat.r_data, axi_rcvd_data};
                // assert(r_beat.r_data == exp) else
                //   $error("Received 0x%h != expected 0x%h!", r_beat.r_data, exp);
              end
              axi_rcvd_data = axi_rcvd_data >> (512-(ar_beat.ax_len+1)*64);
          end
          default: begin
              $display("%t -- %m: ERROR: AXI_DRIVER received UNKNOWN COMMAND %h",$time, action);
              pass = `FAIL;
          end
      endcase
    endtask

    task send_payload (
        input  [255:0]          header_parameters,
        input  [255:0]          gen_parameters,
        input  [255:0]          payload_parameters,
        output [255:0]          data_summary 
    );
        logic [7:0]              code; 
        logic [7:0]              byte_count; 
        logic [15:0]             tx_byte_count; 
        logic [15:0]             addr_offset; 
        logic [10:0]             mem_index; 
        logic [10:0]             current_index; 
        logic [15:0]             context_count; 
        logic [7:0]              context_index; 
        logic [15:0]             context_data;
        logic [31:0]             dt_header; 
        logic [7:0]              payload_data; 
        logic [7:0]              org_data;
        logic [7:0]              load_data; 
        logic [95:0]             pat_sum; 
        logic [511:0]            data[1:128]; 
        logic [511:0]            orgdata;
        logic [511:0]            XX;
        logic [7:0]              strip_bytes;

        ////////////////////////////////////////////////////
        header_parameters = header_parameters<<(255-list_length(header_parameters)); 
        while (header_parameters) begin
           {code,header_parameters}= {header_parameters,8'h00}; 
           case(code)
               `TXBYCNT:
                   {tx_byte_count, header_parameters} = {header_parameters, 16'h0}; 
               default: 
                   $display("%t -- %m :ERROR: Unknown command %h in data_generation header_parameters",$time, code); 
           endcase 
        end // while (header_parameters)
        ////////////////////////////////////////////////////
        //Create frame 
        context_index=(list_length(payload_parameters)-7)/8; 
        pat_sum=0; 
        strip_bytes = 8;
        current_index=1; 
        mem_index=1; 
        byte_count=0;
        context_data=0;
        context_count=0;
        dt_header = 0;
        while ((mem_index<128) && (context_index != 8'hff) && (tx_byte_count != 0)) begin
            if ((mem_index==127) && (byte_count==16)) 
                $display ("WARNING: Data seg is exceeding largest allowable data size!");
            pattern_generator(payload_parameters, context_data, context_count, context_index, load_data);
            payload_data = load_data;           
            org_data = load_data;
            byte_count = byte_count + 1; 
            tx_byte_count = tx_byte_count - 1; 
            data[mem_index]={data[mem_index], payload_data};
            orgdata = {orgdata, org_data};
            if ((byte_count==64)&&(context_index !=8'hff)) begin
                mem_index=mem_index+1;
                byte_count=0; 
            end
        end // while ((mem_index<100) && (context_index != 8'hff) && (tx_byte_count != 0))
        ////////////////////////////////////////////////////
        // Generate summary
        addr_offset = 0;
        data[mem_index]={data[mem_index],XX}>>(byte_count*8); 
        orgdata = {orgdata, XX} >> (byte_count*8); 
        while (mem_index!=0) begin 
            if (mem_index==1) begin 
                dt_header[31:30] = 2'b11;  //ssm 
                dt_header[27:20] = byte_count;
                mem_index=0; 
                pat_sum=pattern_summary({8'h80,data[1]}>>(8*(64-byte_count)),0,strip_bytes,0);
            end // if (mem_index==1) 
            else begin
                if ((current_index==1) && (current_index != mem_index)) begin 
                    pat_sum=pattern_summary({8'h80,data[1]},pat_sum,strip_bytes,0); 
                    dt_header[31:30] = 2'b01;  //bom 
                    dt_header[27:20] = 64; // byte_count 
                end else begin
                    if (current_index==mem_index) begin 
                        //$display("%t -- %m :: INFO : dt_header = %h; data = %h", $time, dt_header, data[current_index]);
                        pat_sum=pattern_summary({8'h80,data[current_index]}>>(8*(64-byte_count)),pat_sum,strip_bytes,0); 
                        dt_header[31:30] = 2'b10;  //eom 
                        dt_header[27:20] = byte_count; 
                        mem_index=0; 
                    end else begin 
                        pat_sum=pattern_summary({8'h80,data[current_index]},pat_sum,strip_bytes,0); 
                        dt_header[31:30] = 2'b00;  //com 
                        dt_header[27:20] = 64;
                    end
                end
            end // else: !if(mem_index==1)
            $display("%t -- %m :: INFO : pat_sum = %h", $time, pat_sum);
            addr_offset = (current_index - 1) * 64;
            dt_header[15:0] = addr_offset;
            //$display("%t -- %m :: INFO : dt_header = %h; data = %h", $time, dt_header, data[current_index]);
            transfer(gen_parameters,{dt_header, data[current_index]}); 
            data[current_index]=0; 
            current_index=current_index+1; 
        end //while 
        data_summary={dt_header, 8'h0, 16'h0, pat_sum};
        $display("%t -- %m:: INFO :: finished transfering data", $time); 
    endtask

    //  gen_parameters = {`FORLWORD, `GENSTART, <32bit address>, `AXID, <4-bit>, `AXPROT, <3-bit>, `DONE};
    task transfer (
        input [255:0]          gen_parameters,
        input [543:0]          cell_data
    );
        logic [567:0] axi_pack;
        logic [23:0]  axi_reg_hdr;
        logic [1:0]   data_type;   // byte = 2'b00; word = 2'b01; lword = 2'b10
        logic [7:0]   code; 
        logic [31:0]  gen_axi_addr;
        logic [31:0]  axi_addr;
        logic [3:0]   axi_axid;
        logic [2:0]   axi_prot;
        logic [1:0]   axi_burst;
        logic [2:0]   axi_size;
        logic [3:0]   axi_len;
        logic [511:0] axi_data;
        logic [7:0]   byte_count;
        logic [7:0]   dummy_8b;
        logic [15:0]  index;
        logic [31:0]  dt_header;
        logic [511:0] send_data;
        logic [511:0] tmp_data;
        logic         tmp_pass;
        logic         mem_type;
        logic [1:0]   second_run;

       
        mem_type = '0;
        data_type = '0;
        gen_parameters = gen_parameters<<(255-list_length(gen_parameters)); 
        while (gen_parameters) begin
           {code,gen_parameters}= {gen_parameters,8'h00}; 
           case(code)
               `MEM_DATA:
                   mem_type = 1'b1;
               `FORLWORD:
                   data_type = 2'b10;
               `GENSTART:
                   {gen_axi_addr, gen_parameters} = {gen_parameters, 32'h0}; 
               `AXID:
                   {axi_axid, gen_parameters} = {gen_parameters, 4'h0}; 
               `AXPROT:
                   {axi_prot, gen_parameters} = {gen_parameters, 3'h0}; 
               default: 
                   $display("%t -- %m :ERROR: Unknown command %h in data_generation gen_parameters",$time, code); 
           endcase 
        end // while (header_parameters)
        ////////////////////////////////////////////////////
        axi_burst = axi_tb_pkg::BURST_INCR;
        axi_size = 3'h3;
        {dt_header, send_data} = cell_data;
        byte_count = dt_header[27:20];
        second_run = 0;
        if (mem_type) begin
            send_data = send_data >> (64 - byte_count)*8; 
            //$display("%t -- %m :: INFO : dt_header = %h; send_data = %h", $time, dt_header, send_data);
            for (index = 0; index < byte_count; index++) begin
                tmp_data = {tmp_data, send_data[7:0]};
                send_data = send_data >> 8;
            end
            send_data = tmp_data;
        end
        while(byte_count) begin
            if (byte_count[7:5]) begin
                second_run++;
                axi_len = 4'h3;
                axi_data = {256'h0, send_data[255:0]};
                send_data = send_data >> 256;
                byte_count = byte_count - 32;
            end else begin
                second_run++;
                axi_len = byte_count[4:3];
                axi_data = {256'h0, send_data[255:0]};
                byte_count = 0;
            end
            axi_addr = gen_axi_addr + dt_header[15:0] + (second_run[1]*32);
            axi_reg_hdr = {`AXI_WD_PACKET, axi_axid, axi_prot, axi_burst, axi_size, axi_len};
            axi_pack = {axi_reg_hdr, axi_addr, axi_data}; 
            //$display("%t -- %m :: INFO : dt_header = %h; second_run = %h", $time, dt_header, second_run);
            //$display("%t -- %m :: INFO : axi_addr = %h; axi_data = %h", $time, axi_addr, axi_data);
            axi_regrw(axi_pack, tmp_data, tmp_pass);
        end
    endtask

    task get_payload(
        input  [255:0]     search_configuration,
        input  [255:0]     search_parameters,
        output             found,
        output [255:0]     retrieved
    );
         
        logic [7:0]         code; 
        logic [1:0]         data_type;   // mem_data = 2'b01; sio_data = 2'b11
        ////////////////////////////////////////////////////
        // search_configuration = {`MEM_DATA}
        search_configuration=search_configuration<<(255-list_length(search_configuration));
        while (search_configuration) begin
            {code,search_configuration}={search_configuration,8'h0};
            case (code)
                `MEM_DATA:
                  data_type = 2'h1;
                `SIO_DATA:
                  data_type = 2'h3;
                default: begin
                  $display("ERROR: get_payload received UNKNOWN COMMAND %h",code);
                end // case: default
            endcase // case (code)
        end // while (search_configuration)
        found = 0;
        retrieved = 0;
        ////////////////////////////////////////////////////
        // search_parameters = {`MEM_DATA, `RDADDR, axi_addr, `AXID, axi_id, `AXPROT, axi_prot, `RXBYCNT, get_bytecnt}; 
        retrieve_payload(search_parameters, found, retrieved);
    endtask

    task retrieve_payload (
        input  [255:0]      search_parameters,
        output              found,
        output [255:0]      retrieved
    );
        logic [567:0] axi_pack;
        logic [23:0]  axi_reg_hdr;
        logic [7:0]   code; 
        logic [1:0]   data_type;   // mem_data = 2'b01; sio_data = 2'b11
        logic [15:0]  get_byte_count; 
        logic [15:0]  index; 
        logic [31:0]  rd_addr;
        logic [31:0]  addr_offset;
        logic [31:0]  axi_addr;
        logic [3:0]   axi_axid;
        logic [2:0]   axi_prot;
        logic [1:0]   axi_burst;
        logic [2:0]   axi_size;
        logic [3:0]   axi_len;
        logic [511:0] axi_data;
        logic [511:0] payload;
        logic [511:0] tmp_data;
        logic [543:0] retrieved_data;
        logic         first_cell;
        logic         tmp_pass;
        logic [1:0]   second_run;
        logic [7:0]   byte_count; 
        logic [31:0]  dt_header;
        logic [31:0]  header;
        logic [255:0] dummy_256b;
        logic [95:0]  pat_sum;
        logic [7:0]   strip_bytes;


        // search_parameters = {`MEM_DATA, `RDADDR, axi_addr, `AXID, axi_id, `AXPROT, axi_prot, `RXBYCNT, get_bytecnt}; 
        search_parameters=search_parameters<<(255-list_length(search_parameters));
        while (search_parameters) begin
            {code,search_parameters}={search_parameters,8'h0};
            case(code)
                `MEM_DATA:
                   data_type = 2'b01;
                `RXBYCNT: begin
                    {get_byte_count, search_parameters} = {search_parameters, 16'h0};
                end
                `RDADDR: begin
                    {rd_addr, search_parameters} = {search_parameters, 32'h0};
                end
                `AXID:
                    {axi_axid, search_parameters} = {search_parameters, 4'h0}; 
                `AXPROT:
                    {axi_prot, search_parameters} = {search_parameters, 3'h0}; 
                default: begin
                    $display("%t -- %m: ERROR: Received UNKNOWN COMMAND %h",$time,code);
                end
            endcase 
        end
        axi_addr = rd_addr;
        first_cell = 1;
        second_run = 0;
        byte_count = 0;
        strip_bytes = 8;
        pat_sum = 0;
        addr_offset = 0;
        dt_header = 0;
        found = 0;
        ////////////////////////////////////////////////////
        while(get_byte_count) begin
            if (get_byte_count[15:5]) begin
                if (first_cell) begin
                    dt_header[31:30] = 2'b01; // BOM
                    first_cell = 0;
                end else begin
                    if (get_byte_count == 32)
                        dt_header[31:30] = 2'b10; // EOM
                    else
                        dt_header[31:30] = 2'b00; // COM
                end
                axi_len = 4'h3;
                get_byte_count = get_byte_count - 32;
                byte_count = byte_count + 32;
                axi_addr = rd_addr + addr_offset;
                addr_offset = addr_offset + 32;
            end else begin
                if (first_cell) begin
                    dt_header[31:30] = 2'b11; // SSM
                end else begin
                    dt_header[31:30] = 2'b10; // EOM
                end
                axi_len = get_byte_count[4:3];
                byte_count = byte_count + get_byte_count;
                axi_addr = rd_addr + addr_offset;
                addr_offset = addr_offset + get_byte_count;
                get_byte_count = 0;
            end
            dt_header[27:20] = byte_count;
            axi_burst = axi_tb_pkg::BURST_INCR;
            axi_size = 3'h3;
            axi_reg_hdr = {`AXI_AR_PACKET, axi_axid, axi_prot, axi_burst, axi_size, axi_len};
            axi_pack = {axi_reg_hdr, axi_addr}; 
            axi_regrw(axi_pack, axi_data, tmp_pass);
            //$display("%t -- %m :: INFO : axi_addr = %h, axi_data = %h", $time, axi_addr, axi_data);
            second_run++;
            {payload, dummy_256b} = {axi_data[255:0], payload};
            retrieved_data = {dt_header, payload};
            //$display("%t -- %m :: INFO : dt_header = %h, payload = %h, second_run = %h", $time, dt_header, payload, second_run);
            if ((second_run[1]) || (get_byte_count == 0)) begin
                {header, payload} = retrieved_data;
                if (get_byte_count == 0) begin
                    payload = payload >> second_run[0] * 256;
                end
                case (data_type)
                    2'h1: begin   // mem_data
                        byte_count = header[27:20];
                        //$display("%t -- %m :: INFO : header = %h, payload = %h", $time, header, payload);
                        for (index = 0; index < byte_count; index++) begin
                            tmp_data = {tmp_data, payload[7:0]};
                            payload = payload >> 8;
                        end
                        payload = tmp_data;
                        case (header[31:30])
                            2'b11: begin // SSM
                                pat_sum=pattern_summary({8'h80,payload}>>(8*(64-byte_count)),0,strip_bytes,0);
                                found = 1;
                            end
                            2'b01: begin // BOM
                                pat_sum=pattern_summary({8'h80,payload},pat_sum,strip_bytes,0); 
                            end
                            2'b10: begin   // EOM
                                //$display("%t -- %m :: INFO : byte_count = %h, payload = %h, second_run = %h", $time, byte_count, payload, second_run);
                                payload = payload << (64-byte_count)*8;
                                pat_sum=pattern_summary({8'h80,payload}>>(8*(64-byte_count)),pat_sum,strip_bytes,0); 
                                found = 1;
                            end
                            2'b00: begin  //com
                                pat_sum=pattern_summary({8'h80,payload},pat_sum,strip_bytes,0); 
                            end
                        endcase
                        retrieved = {header, 8'h0, 16'h0, pat_sum};
                    end  // case (2'h1)
                    2'h3: begin    // sio_data
                        {header,payload} = retrieved_data;
                        retrieved = {header, 8'h0, 16'h0, pat_sum};
                    end // case 2'h3
                endcase // case (data_type)
                $display("%t -- %m :: INFO : pat_sum = %h", $time, pat_sum);
                second_run = 0;
                byte_count = 0;
            end // if (second_run[1])  
        end // while(get_byte_count)
    endtask


endclass


endpackage

