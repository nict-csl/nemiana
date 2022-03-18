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


module test1(
	     input wire 	clock,
	     input wire 	nreset, 
	     input wire [3:0] 	btn,
	     output wire [11:0] led,
	     input [31:0] 	gpio0,
	     output [31:0] 	gpio1,

             input wire [31:0] 	s_tdata,
             input wire [3:0] 	s_tkeep,
             input wire 	s_tlast,
             output wire 	s_tready,
             input wire 	s_tvalid,

             output wire [31:0] m_tdata,
             output wire [3:0] 	m_tkeep,
             output wire 	m_tlast,
             input wire 	m_tready,
             output wire 	m_tvalid,
	     );

   wire [31:0] 			data;
   reg last_flag;
   reg valid_flag;

   assign m_tkeep = 15;
   assign m_tlast = last_flag;
   assign s_tready = 1;
   assign m_tvalid = valid_flag;

   reg [31:0] 		   count;

   always  @(posedge clock or negedge nreset) begin   
      if(!nreset) begin
	 count=0;
      end
      else begin
	 count = count + 1;
      end
   end
   
   reg [11:0] addr1;
   reg [1:0] state2;
   
   always @(posedge clock or negedge nreset) begin
      if(!nreset) begin
	 addr1 = 0;
      end
      else begin
	 addr1 = addr1 + 1;
      end
   end

   reg [31:0] mem1 [11:0];
   reg [31:0] data_out;
   reg 	      read_flag;
   
   wire [31:0] data_in;
   wire        start_flag;

   assign start_flag = gpio0[0];
//   assign m_tdata = data_out;
   assign m_tdata = count;

   assign data_in = s_tdata;
   
   always @(posedge clock) begin
      mem1[addr1] = data_in * 4;
   end

   reg [14:0] addr2;
   reg [31:0] write_data_count;
   always @(posedge clock) begin
      if(! nreset) begin
	 state2 = 0;
	 last_flag = 0;
	 valid_flag = 0;
	 addr2 = 0;
	 read_flag = 0;
	 write_data_count=0;
      end
      else if(state2 == 0) begin
	 if (start_flag) begin
	    state2 = 1;
	    last_flag = 0;
	    valid_flag = 1;
	    addr2 = 0;
	    read_flag = 0;
	 end
	 else begin
	    state2 = 0;
	    last_flag = 0;
	    valid_flag = 0;
	    read_flag = 0;
	 end
      end
      else if(state2 == 1) begin
	 if(m_tready) begin
	    if (addr2==63) begin
	       state2 = 2;
	       last_flag = 1;
	       read_flag = 0;
	    end
	    else begin
	       read_flag = 1;
	       addr2=addr2+1;
	       write_data_count = write_data_count+1;
	    end
	 end // if (m_tready)
	 else begin
	    read_flag = 0;
	 end
      end
      else if(state2 == 2) begin
	 last_flag = 0;
	 addr2=0;
	 state2=3;
	 read_flag = 0;
      end
      else if(state2 == 3) begin
	 if(!start_flag) begin
	    state2 = 0;
	    last_flag = 0;
	    valid_flag = 0;
	    read_flag = 0;
	 end
      end
      else begin
	 state2 = 0;
	 addr2 = 0;
	 valid_flag = 0;
      end
   end // always @ (posedge clock)
   assign led = data;
   assign data = {count[31:24], state2, last_flag, valid_flag, m_tready, s_tlast, s_tready, s_tvalid};
   assign gpio1 = write_data_count;
endmodule
