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

//
//  Description : AHB Testbench package contains AHB bus 
//                parameters and class tasks 
//
/////////////////////////////////////////////////////////////////////////// 

package ahb_tb_pkg;  

    import tb_util_pkg::*;


  //HTRANS
  parameter [1:0] HTRANS_IDLE   = 2'b00,
                  HTRANS_BUSY   = 2'b01,
                  HTRANS_NONSEQ = 2'b10,
                  HTRANS_SEQ    = 2'b11;

  //HSIZE
  parameter [2:0] HSIZE_B8    = 3'b000,
                  HSIZE_B16   = 3'b001,
                  HSIZE_B32   = 3'b010,
                  HSIZE_B64   = 3'b011,
                  HSIZE_B128  = 3'b100, //4-word line
                  HSIZE_B256  = 3'b101, //8-word line
                  HSIZE_B512  = 3'b110,
                  HSIZE_B1024 = 3'b111,
                  HSIZE_BYTE  = HSIZE_B8,
                  HSIZE_HWORD = HSIZE_B16,
                  HSIZE_WORD  = HSIZE_B32,
                  HSIZE_DWORD = HSIZE_B64;

  //HBURST
  parameter [2:0] HBURST_SINGLE = 3'b000,
                  HBURST_INCR   = 3'b001,
                  HBURST_WRAP4  = 3'b010,
                  HBURST_INCR4  = 3'b011,
                  HBURST_WRAP8  = 3'b100,
                  HBURST_INCR8  = 3'b101,
                  HBURST_WRAP16 = 3'b110,
                  HBURST_INCR16 = 3'b111;

  //HPROT
  parameter [3:0] HPROT_OPCODE         = 4'b0000,
                  HPROT_DATA           = 4'b0001,
                  HPROT_USER           = 4'b0000,
                  HPROT_PRIVILEGED     = 4'b0010,
                  HPROT_NON_BUFFERABLE = 4'b0000,
                  HPROT_BUFFERABLE     = 4'b0100,
                  HPROT_NON_CACHEABLE  = 4'b0000,
                  HPROT_CACHEABLE      = 4'b1000;

  //HRESP
  parameter       HRESP_OKAY  = 1'b0,
                  HRESP_ERROR = 1'b1;
class ahb_ax_beat #(
    parameter AW = 32
);
    logic  [AW-1:0]  haddr;          // Address bus
    logic  [1:0]     htrans;         // Transfer type
    logic            hwrite;         // Transfer direction
    logic  [2:0]     hsize;          // Transfer size
    logic  [2:0]     hburst;         // Burst type
    logic  [3:0]     hprot;          // Protection control
endclass

class ahb_d_beat #(
    parameter DW = 32
);
    logic  [DW-1:0]  hwdata;         // Write data
    logic  [DW-1:0]  hrdata;         // Read data bus    // old hready
    logic            hresp;          // Transfer response
endclass

class tb_ahb_monitor #(
      parameter AW,
      parameter DW,
      parameter bit verbose,
      parameter time TimeTest
);
  virtual ahb_tb_mon ahb_port;
  string msg_s;

  function new(
               virtual ahb_tb_mon  ahb_vif
           );

    begin
       this.ahb_port = ahb_vif;
    end
  endfunction : new

task initialize();

  @(posedge ahb_port.hresetn);
  $display("%t -- %m :: INFO :: Got ahbp hresetn released...", $time);
endtask : initialize

typedef ahb_ax_beat #(.AW(AW)) ahb_aw_vector_s; 
typedef ahb_d_beat #(.DW(DW)) ahb_d_vector_s; 
ahb_aw_vector_s     act_aw_packet_queue[$];
ahb_d_vector_s      act_d_packet_queue[$];

task get_address();
    ahb_aw_vector_s s;
  if (ahb_port.hready &&  ahb_port.hsel && ahb_port.htrans[1])
  begin
      read_aw(.s(s));
      act_aw_packet_queue.push_back(s);
      msg_s = "get_address";
      if (ahb_port.hwrite) begin
          $sformat(msg_s, "%s, an AHB write transaction", msg_s);
      end else begin
          $sformat(msg_s, "%s, an AHB read transaction", msg_s);
      end
      $sformat(msg_s, "%s, hprot = %h; htrans = %h; hburst = %h; hsize = %h;", msg_s, s.hprot, s.htrans, s.hburst, s.hsize);
      $sformat(msg_s, "%s, hwrite = %h; haddr = %h", msg_s, s.hwrite, s.haddr);
      if (verbose) begin
          $display("%t -- [AHB_BUS]:: %s", $time, msg_s);
      end
      @(posedge ahb_port.hclk);
  end
endtask : get_address

function void read_aw(output ahb_aw_vector_s s);
    s = new;
    s.haddr  = ahb_port.haddr;
    s.htrans = ahb_port.htrans;
    s.hburst = ahb_port.hburst;
    s.hsize  = ahb_port.hsize;
    s.hprot  = ahb_port.hprot;
    s.hwrite = ahb_port.hwrite;
endfunction : read_aw

function void read_d(output ahb_d_vector_s s);
    s = new;
    s.hwdata = ahb_port.hwdata;
    s.hrdata = ahb_port.hrdata;
    s.hresp  = ahb_port.hresp;
endfunction : read_d

//Wait for HREADY to assert
task get_data();
    ahb_d_vector_s s;
    ahb_aw_vector_s     aw_packet;
    logic  [AW-1:0]  aw_addr;          // Address bus 
    logic            aw_write;         // Transfer direction

    if ((act_aw_packet_queue.size() != 0) && !ahb_port.htrans[1] && (ahb_port.hreadym || ahb_port.hready)) begin
        read_d(.s(s));
        act_d_packet_queue.push_back(s);
        msg_s = "get_data";
        aw_packet = act_aw_packet_queue.pop_front();
        aw_addr = aw_packet.haddr;
        aw_write = aw_packet.hwrite;
        if (aw_write) 
            $sformat(msg_s, "%s, aw_write = %h; aw_addr = %h; aw_data = %h", msg_s, aw_write, aw_addr, s.hwdata);
        else
            $sformat(msg_s, "%s, aw_write = %h; aw_addr = %h; aw_data = %h", msg_s, aw_write, aw_addr, s.hrdata);
        if (verbose) begin
            $display("%t -- [AHB_BUS]:: %s", $time, msg_s);
        end
    end

endtask : get_data

    task cycle_start;
      #TimeTest;
    endtask: cycle_start

    task cycle_end;
      @(posedge ahb_port.hclk);
    endtask: cycle_end
//-------------------------------------
task run();

  forever
  begin
        // At every cycle, spawn some monitoring processes.
        cycle_start();

      fork
        get_address();
        get_data();
      join
      
        cycle_end();
  end
endtask : run

endclass : tb_ahb_monitor


  /// A driver for AHB Master interface.
  class ahb_driver #(
    parameter int  AW = 32  ,
    parameter int  DW = 32  ,
    parameter bit verbose = 0,
    parameter time TA = 0ns , // stimuli application time
    parameter time TT = 0ns   // stimuli test time
  );
    virtual ahb_tb_mst   #(.AW(AW),.DW(DW))      ahbm;

    typedef logic [DW-1:0] data_t;
    typedef ahb_ax_beat #(.AW(AW)) addr_beat_t;
    typedef ahb_d_beat  #(.DW(DW)) data_beat_t;
    logic   check_on_read;

    function new(
      virtual ahb_tb_mst   #(.AW(AW),.DW(DW)) ahbp_vif
    );
      this.ahbm = ahbp_vif;
    endfunction

    function void reset_master();
        ahbm.hsel          <= '0; 
        ahbm.haddr         <= '0;        
        ahbm.htrans        <= '0;       
        ahbm.hwrite        <= '0;       
        ahbm.hsize         <= '0;        
        ahbm.hburst        <= '0;           
        ahbm.hprot         <= '0;             
        ahbm.hmaster       <= '0;          
        ahbm.hwdata        <= '0;           
        ahbm.hmasterlock   <= '0;  
        ahbm.hreadym       <= '1;         
        ahbm.hauser        <= '0;
        ahbm.hwuser        <= '0;       
    endfunction

    task cycle_start;
      #TT;
    endtask

    task cycle_end;
      @(posedge ahbm.hclk);
    endtask

    /// Issue a beat on the Addr channel.
    task send_addr (
      input addr_beat_t beat
    );
      ahbm.haddr       <= #TA beat.haddr      ; 
      ahbm.htrans      <= #TA beat.htrans     ; 
      ahbm.hwrite      <= #TA beat.hwrite     ; 
      ahbm.hsize       <= #TA beat.hsize      ; 
      ahbm.hburst      <= #TA beat.hburst     ; 
      ahbm.hprot       <= #TA beat.hprot      ; 
      ahbm.hwdata      <= #TA '0;
      ahbm.hsel        <= #TA '1;
      ahbm.hmaster     <= #TA 4'h8;
      ahbm.hmasterlock <= #TA '0;
      ahbm.hreadym     <= #TA '1;
      ahbm.hauser      <= #TA '0;
      ahbm.hwuser      <= #TA '0;  
      cycle_start();
      while (ahbm.hready != 1) begin cycle_end(); cycle_start(); end
      ahbm.hreadym     <= #TA ahbm.hready;
      cycle_end();
      ahbm.htrans      <= #TA '0;
      ahbm.hauser      <= #TA '0;
      ahbm.hwuser      <= #TA '0;
    endtask

    /// Issue a beat on the write data channel.
    task send_wdata (
      input data_beat_t beat
    );
      ahbm.hwdata  <= #TA beat.hwdata;
      ahbm.hreadym <= #TA '1;
      cycle_start();
      @(posedge ahbm.hclk iff(!ahbm.hready));
      @(posedge ahbm.hclk iff(ahbm.hready));
      ahbm.hreadym <= #TA ahbm.hready;
    endtask

    /// Wait for a beat on the addr channel.
    task recv_addr (
      output addr_beat_t beat
    );
      ahbm.hreadym <= #TA '1;
      cycle_start();
      while (ahbm.hready != 1) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.haddr    = ahbm.haddr ;
      beat.htrans   = ahbm.htrans;
      beat.hwrite   = ahbm.hwrite;
      beat.hsize    = ahbm.hsize ;
      beat.hburst   = ahbm.hburst;
      beat.hprot    = ahbm.hprot ;
      ahbm.hreadym <= #TA ahbm.hready;
      cycle_end();
    endtask

    /// Wait for a beat on the write data channel.
    task recv_wdata (
      output data_beat_t beat
    );
      ahbm.hreadym <= #TA '1;
      cycle_start();
      while (ahbm.hready != 1) begin cycle_end(); cycle_start(); end
      beat = new;
      beat.hwdata  = ahbm.hwdata ;
      ahbm.hreadym <= #TA ahbm.hready;
      cycle_end();
    endtask

    /// Wait for a beat on the read data channel.
    task recv_rdata (
      output data_beat_t beat
    );
      ahbm.hreadym <= #TA '1;
      cycle_start();
      @(posedge ahbm.hclk iff(!ahbm.hready));
      @(posedge ahbm.hclk iff(ahbm.hready));
      beat = new;
      beat.hrdata = ahbm.hrdata;
      beat.hresp  = ahbm.hresp ;
      ahbm.hreadym <= #TA ahbm.hready;
    endtask

    task ahb_regrw (
        input [84:0] ahb_pack,
        output  [DW-1:0]  rcvd_hrdata,
        output            pass,
        input        read_on_check
    );
      logic [3:0] rand_4b;
      logic [84:0] reg_para;
      logic [7:0] action;
      logic pass = `PASS;
      data_t exp, exp_rd_data, exp_data[$];
      addr_beat_t addr_beat = new;
      data_beat_t data_beat = new;
      {action, reg_para} = {ahb_pack, 8'h0};
      {addr_beat.hprot, reg_para} = {reg_para, 4'h0};
      {addr_beat.htrans, reg_para} = {reg_para, 2'h0};
      {addr_beat.hburst, reg_para} = {reg_para, 3'h0};
      {addr_beat.hsize, reg_para} = {reg_para, 3'h0};
      {addr_beat.hwrite, reg_para} = {reg_para, 1'h0};
      {addr_beat.haddr, reg_para} = {reg_para, 32'h0};
      {data_beat.hwdata, reg_para} = {reg_para, 32'h0};
      send_addr(addr_beat);
      if (addr_beat.hwrite) begin
          send_wdata(data_beat);
      end else begin
          exp_rd_data = data_beat.hwdata;
          recv_rdata(data_beat);
      end
      if (verbose) begin
          $display("%t -- %m:: INFO :: hwrite = %h; haddr = %h, hwdata = %h", $time, addr_beat.hwrite, addr_beat.haddr, data_beat.hwdata);
      end
      if (read_on_check) begin
          if (addr_beat.hwrite)
              exp_data.push_back(data_beat.hwdata);
          else 
              exp_data.push_back(exp_rd_data);
          repeat (std::randomize(rand_4b)+10) @(posedge ahbm.hclk);
          addr_beat.hwrite = 0;
          addr_beat.hburst = 0;
          addr_beat.hsize = 2;
          send_addr(addr_beat);
          exp = exp_data.pop_front();
          recv_rdata(data_beat);
          rcvd_hrdata = data_beat.hrdata;
          if (verbose) begin
              $display("%t -- %m:: INFO :: hwrite = %h; haddr = %h, hrdata = %h", $time, addr_beat.hwrite, addr_beat.haddr, data_beat.hrdata);
          end
          assert(data_beat.hresp == 1'b0) else begin
              $error("%t -- %m:: ERROR :: Got HRESP transfer error...", $time);
              pass = `FAIL;
          end
          assert(data_beat.hrdata == exp) else begin
              $error("%t -- %m:: ERROR :: Address = %h -- Received 0x%h != expected 0x%h!", $time, addr_beat.haddr, data_beat.hrdata, exp);
              pass = `FAIL;
          end
      end else begin
          rcvd_hrdata = data_beat.hrdata;
      end
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
                // $display("%t -- %m :: INFO :: byte_count = %h, data = %h", $time, byte_count, data[1]);
                pat_sum=pattern_summary({8'h80,data[1]}>>(8*(64-byte_count)),0,strip_bytes,0);
            end // if (mem_index==1) 
            else begin
                if ((current_index==1) && (current_index != mem_index)) begin 
                    pat_sum=pattern_summary({8'h80,data[1]},pat_sum,strip_bytes,0); 
                    dt_header[31:30] = 2'b01;  //bom 
                    dt_header[27:20] = 64; // byte_count 
                end else begin
                    if (current_index==mem_index) begin 
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
            addr_offset = (current_index - 1) * 64;
            dt_header[15:0] = addr_offset;
            //$display("%t -- %m:: INFO :: dt_header = %h, pat_sum = %h", $time, dt_header, pat_sum); 
            //$display("%t -- %m :: INFO : dt_header = %h; data = %h", $time, dt_header, data[current_index]);
            transfer(gen_parameters,{dt_header, data[current_index]}); 
            data[current_index]=0; 
            current_index=current_index+1; 
        end //while 
        data_summary={dt_header, 8'h0, 16'h0, pat_sum};
        $display("%t -- %m:: INFO :: finished transfering data", $time); 
    endtask

    //  gen_parameters = {`FORLWORD, `GENSTART, <32bit address>, `AHBPROT, <4-bit>};
    task transfer (
        input [255:0]          gen_parameters,
        input [543:0]          cell_data
    );
        logic [84:0]  ahb_pack;
        logic [20:0]  ahb_reg_hdr;
        logic [1:0]   data_type;   // mem_data = 2'b01; sio_data = 2'b11
        logic [2:0]   data_size;   // ubyte = 3'b100; uword = 3'b101; lword = 2'b10
        logic [7:0]   code; 
        logic [31:0]  gen_ahb_addr;
        logic [31:0]  ahb_addr;
        logic [3:0]   ahb_hprot;
        logic [1:0]   ahb_htrans;
        logic [2:0]   ahb_hburst;
        logic [2:0]   ahb_hsize;
        logic [31:0]  ahb_data;
        logic [7:0]   byte_count;
        logic [7:0]   dummy_8b;
        logic [15:0]  index;
        logic [31:0]  dt_header;
        logic [511:0] send_data;
        logic [511:0] tmp_data;
        logic         tmp_pass;
        logic         mem_type;

       
        mem_type = '0;
        data_type = '0;
        data_size = '0;
        gen_parameters = gen_parameters<<(255-list_length(gen_parameters)); 
        while (gen_parameters) begin
           {code,gen_parameters}= {gen_parameters,8'h00}; 
           case(code)
               `MEM_DATA:
                   data_type = 2'b01;
               `FORUBYTE:
                   data_size = 3'b100; 
               `GENSTART:
                   {gen_ahb_addr, gen_parameters} = {gen_parameters, 32'h0}; 
               `AHBPROT:
                   {ahb_hprot, gen_parameters} = {gen_parameters, 4'h0}; 
               default: 
                   $display("%t -- %m :ERROR: Unknown command %h in data_generation gen_parameters",$time, code); 
           endcase 
        end // while (header_parameters)
        ////////////////////////////////////////////////////
        {dt_header, send_data} = cell_data;
        ahb_addr = gen_ahb_addr + dt_header[15:0];
        ahb_htrans = `AHB_HTRANS_NONSEQ;
        ahb_hburst = `AHB_HBURST_SINGLE;
        ahb_hsize = 3'h2;
        byte_count = dt_header[27:20];
        if (data_type == 2'h01) begin   // mem_data
            //$display("%t -- %m :: INFO : dt_header = %h; send_data = %h", $time, dt_header, send_data);
            for (index = 0; index < 64; index++) begin
                tmp_data = {tmp_data, send_data[7:0]};
                send_data = send_data >> 8;
            end
            send_data = tmp_data;
        end
        //$display("%t -- %m :: INFO :: send_data = %h", $time, send_data);
        while(byte_count) begin
            if (data_size == 3'b100) begin  // FORUBYTE:
                ahb_data = 32'h0;
                {send_data, ahb_data[7:0]} = {8'h0, send_data};
                byte_count = byte_count - 1;
            end else begin
                {send_data, ahb_data} = {32'h0, send_data};
                if (byte_count[7:2]) begin
                    byte_count = byte_count - 4;
                end else begin
                    byte_count = 0;
                end
            end
            ahb_reg_hdr = {`AHB_PACKET, ahb_hprot, ahb_htrans, ahb_hburst, ahb_hsize, `WRITE};
            ahb_pack = {ahb_reg_hdr, ahb_addr, ahb_data}; 
            //$display("%t -- %m :: INFO :: Write %h register with write data = %h", $time, ahb_addr, ahb_data);
            ahb_regrw(ahb_pack, tmp_data, tmp_pass, `NO_CHECK);
            ahb_addr = ahb_addr + 4;
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
        // search_parameters = {`MEM_DATA, `RDADDR, ahb_addr, `AHBPROT, ahb_hprot, `RXBYCNT, get_bytecnt}; 
        retrieve_payload(search_parameters, found, retrieved);
    endtask

    task retrieve_payload (
        input  [255:0]      search_parameters,
        output              found,
        output [255:0]      retrieved
    );
        logic [84:0]  ahb_pack;
        logic [20:0]  ahb_reg_hdr;
        logic [7:0]   code; 
        logic [1:0]   data_type;   // mem_data = 2'b01; sio_data = 2'b11
        logic [15:0]  get_byte_count; 
        logic [15:0]  index; 
        logic [31:0]  rd_addr;
        logic [31:0]  addr_offset;
        logic [31:0]  ahb_addr;
        logic [3:0]   ahb_hprot;
        logic [1:0]   ahb_htrans;
        logic [2:0]   ahb_hburst;
        logic [2:0]   ahb_hsize;
        logic [31:0]  ahb_data;
        logic [31:0]  rcvd_hrdata;
        logic [511:0] payload;
        logic [511:0] tmp_data;
        logic [543:0] retrieved_data;
        logic         first_cell;
        logic         tmp_pass;
        logic [7:0]   byte_count; 
        logic [31:0]  dt_header;
        logic [31:0]  header;
        logic [31:0]  dummy_32b;
        logic [95:0]  pat_sum;
        logic [7:0]   strip_bytes;


        // search_parameters = {`MEM_DATA, `RDADDR, ahb_addr, `AHBPROT, ahb_hprot, `RXBYCNT, get_bytecnt}; 
        search_parameters=search_parameters<<(255-list_length(search_parameters));
        while (search_parameters) begin
            {code,search_parameters}={search_parameters,8'h0};
            case(code)
                `MEM_DATA:
                   data_type = 2'b01;
                `SIO_DATA:
                   data_type = 2'b11;
                `RXBYCNT: begin
                    {get_byte_count, search_parameters} = {search_parameters, 16'h0};
                end
                `RDADDR: begin
                    {rd_addr, search_parameters} = {search_parameters, 32'h0};
                end
                `AHBPROT:
                    {ahb_hprot, search_parameters} = {search_parameters, 4'h0}; 
                default: begin
                    $display("%t -- %m: ERROR: Received UNKNOWN COMMAND %h",$time,code);
                end
            endcase 
        end
        ahb_addr = rd_addr;
        first_cell = 1;
        byte_count = 0;
        strip_bytes = 8;
        pat_sum = 0;
        addr_offset = 0;
        dt_header = 0;
        found = 0;
        ////////////////////////////////////////////////////
        while(get_byte_count) begin
            get_byte_count = get_byte_count - 4;
            ahb_htrans = `AHB_HTRANS_NONSEQ;
            ahb_hburst = `AHB_HBURST_SINGLE;
            ahb_hsize = 3'h2;
            ahb_reg_hdr = {`AHB_PACKET, ahb_hprot, ahb_htrans, ahb_hburst, ahb_hsize, `READ};
            ahb_pack = {ahb_reg_hdr, ahb_addr, ahb_data};
            ahb_regrw(ahb_pack, rcvd_hrdata, tmp_pass, `NO_CHECK);
            byte_count = byte_count + 4;
            ahb_addr = ahb_addr + 4;
            {payload, dummy_32b} = {rcvd_hrdata, payload};
            //$display("%t -- %m:: INFO :: get_byte_count = %h, payload = %h", $time, get_byte_count, payload); 
            if ((byte_count == 64) || (get_byte_count == 0)) begin
                //$display("%t -- %m:: INFO :: get_byte_count = %h", $time, get_byte_count); 
                if (first_cell) begin
                    if (get_byte_count != 0) begin
                        dt_header[31:30] = 2'b01; // BOM
                        first_cell = 0;
                    end else begin
                        dt_header[31:30] = 2'b11; // SSM
                    end
                end else begin
                    if (get_byte_count == 0)
                        dt_header[31:30] = 2'b10; // EOM
                    else
                        dt_header[31:30] = 2'b00; // COM
                end
                dt_header[27:20] = byte_count;
                retrieved_data = {dt_header, payload};
                case (data_type)
                    2'h1: begin   // mem_data
                        {header, payload} = retrieved_data;
                        byte_count = header[27:20];
                        for (index = 0; index < 64; index++) begin
                            tmp_data = {tmp_data, payload[7:0]};
                            payload = payload >> 8;
                        end
                        payload = tmp_data;
                        payload = payload << (64 - byte_count)*8;
                        //$display("%t -- %m:: INFO :: dt_header = %h, payload = %h", $time, dt_header, payload); 
                        case (header[31:30])
                            2'b11: begin // SSM
                                pat_sum=pattern_summary({8'h80,payload}>>(8*(64-byte_count)),0,strip_bytes,0);
                                found = 1;
                            end
                            2'b01: begin // BOM
                                pat_sum=pattern_summary({8'h80,payload},pat_sum,strip_bytes,0); 
                            end
                            2'b10: begin   // EOM
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
                        //$display("%t -- %m:: INFO :: header = %h, payload = %h", $time, header, payload); 
                        retrieved = {header, 8'h0, 16'h0, pat_sum};
                    end // case 2'h3
                endcase // case (data_type)
                byte_count = 0;
                //$display("%t -- %m:: INFO :: payload = %h", $time, payload); 
                $display("%t -- %m:: INFO :: dt_header = %h, pat_sum = %h", $time, dt_header, pat_sum); 
            end 
        end // while(get_byte_count)
    endtask

  endclass


endpackage
