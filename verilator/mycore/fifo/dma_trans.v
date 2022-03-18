`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/27 14:16:14
// Design Name: 
// Module Name: test1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dma_trans(
	     input wire 	pl_clk,
	     input wire 	cpu_clk, 
	     input wire 	nreset, 
	     input wire 	fifo_reset,

             input wire [31:0] 	s_tdata,
             input wire [3:0] 	s_tkeep,
             input wire 	s_tlast,
             output wire 	s_tready,
             input wire 	s_tvalid,

	     output wire [63:0] dma_out,
	     input wire 	dma_re,
	     input wire 	xxxx,
	     output wire 	dma_r_enable,
	     output wire [11:0] led
	     );

   reg [31:0] 		   count;
   
   always  @(posedge pl_clk or negedge nreset) begin   
      if(!nreset) begin
	 count <= 0;
      end
      else begin
	 count <= count + 4;
      end
   end

   wire in_fifo_w_clk;
   wire in_fifo_r_clk;
   wire in_fifo_wr;
   wire in_fifo_rd;
   wire [31:0] in_fifo_data_in;
   wire [63:0] in_fifo_data_out;
   wire        in_fifo_rst;
   wire        in_fifo_full;
   wire        in_fifo_empty;

   reg [31:0] 	in_fifo_count;
   reg 		in_fifo_wr_flag;
   reg 		in_fifo_rd_flag;
   reg [31:0] 	in_fifo_data_in_prev;
   reg [63:0] 	in_fifo_data_out_prev;
   assign dma_out = in_fifo_data_out_prev;
   
   wire        in_fifo_rd_rst_busy_0;
   wire        in_fifo_wr_rst_busy_0;
   wire        in_fifo_enable = (in_fifo_rd_rst_busy_0===0) && (in_fifo_wr_rst_busy_0===0);

   fifo2 in_fifo(
		 .rd_rst_busy_0(in_fifo_rd_rst_busy_0),
		 .wr_rst_busy_0(in_fifo_wr_rst_busy_0),
		 .empty_0(in_fifo_empty),
		 .full_0(in_fifo_full),
		 .din_0(in_fifo_data_in),
		 .dout_0(in_fifo_data_out),
		 .rd_clk_0(in_fifo_r_clk),
		 .rd_en_0(in_fifo_rd),
		 .rst_0(in_fifo_rst),
		 .wr_clk_0(in_fifo_w_clk),
		 .wr_en_0(in_fifo_wr));
   
   assign in_fifo_w_clk = pl_clk;
   assign in_fifo_r_clk = cpu_clk;
   assign in_fifo_wr = in_fifo_wr_flag;
   assign in_fifo_rd = in_fifo_rd_flag;
   assign in_fifo_data_in = in_fifo_data_in_prev;
   assign in_fifo_rst = (!nreset) || fifo_reset;
   wire        in_fifo_wr_ready = in_fifo_enable & (!in_fifo_full);
   wire        in_fifo_rd_ready = in_fifo_enable & (!in_fifo_empty);
   reg 	       s_tready_flag ;
   assign s_tready = s_tready_flag;
   reg 	       r_enable_flag;
   reg [1:0]        state;

   reg [31:0] 	    fifo_write_num;
   
   always @(posedge pl_clk) begin
      if(!nreset) begin
   	 in_fifo_wr_flag <= 0;
   	 state <= 0;
   	 s_tready_flag <= 0;
	 in_fifo_data_in_prev <= 0;
      end
      else if(state == 0) begin
   	 if (s_tvalid && in_fifo_wr_ready) begin
   	    state <= 1;
   	    s_tready_flag <= 1;
   	    in_fifo_wr_flag <= 0;
	    in_fifo_data_in_prev <= 0;
   	 end
      end
      else if(state == 1) begin
   	 if (!(s_tvalid && in_fifo_wr_ready && (!s_tlast))) begin
   	    state <= 0;
   	    s_tready_flag <= 0;
   	    in_fifo_wr_flag <= 0;
	    in_fifo_data_in_prev <= 0;
   	 end
	 else if(s_tdata == 32'hDEADBEEF) begin
	    state <= 2;
	    in_fifo_wr_flag <= 0;
	    in_fifo_data_in_prev <= 0;
	 end
      end
      else if(state == 2) begin
   	 if (!(s_tvalid && in_fifo_wr_ready && (!s_tlast))) begin
   	    state <= 0;
   	    s_tready_flag <= 0;
   	    in_fifo_wr_flag <= 0;
	    in_fifo_data_in_prev <= 0;
   	 end
	 else if(s_tdata == 32'hFFFFFFFF) begin
	    state <= 3;
	    in_fifo_wr_flag <= 0;
	    in_fifo_data_in_prev <= 0;
	 end
      end
      else if(state == 3) begin
   	 if (!(s_tvalid && in_fifo_wr_ready && (!s_tlast))) begin
   	    state <= 0;
   	    s_tready_flag <= 0;
   	    in_fifo_wr_flag <= 0;
	    in_fifo_data_in_prev <= 0;
   	 end
	 else begin
	    in_fifo_wr_flag <= 1;
	    in_fifo_data_in_prev <= s_tdata;
	 end
      end
   end

   reg [31:0] fifo_read_num;

   wire [31:0] dummy_addr = {4'h2, fifo_read_num[27:0]};
   wire [31:0] dummy_data1 = in_fifo_data_out[63:32];
   wire [31:0] dummy_data2 = in_fifo_data_out[31:0];
   reg 	       state2;
   
   always @(posedge cpu_clk) begin
      in_fifo_data_out_prev = in_fifo_data_out;
      in_fifo_rd_flag = xxxx;
//      in_fifo_rd_flag = dma_re;
      r_enable_flag = in_fifo_rd_ready;
   end
   
   assign dma_r_enable = r_enable_flag;

   // Status Data
   assign led = {count[26:23],   state, xxxx, dma_re, in_fifo_wr_ready, in_fifo_rd_ready, in_fifo_full, in_fifo_empty};
   //                           7,6         5              4                3                2
   //   1       0
//   assign data = {count[31:24], ~state, r_enable_flag, in_fifo_rd_flag, in_fifo_wr_ready, s_tlast, s_tready, s_tvalid};
endmodule
