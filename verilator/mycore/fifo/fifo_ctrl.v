`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/05 14:50:01
// Design Name: 
// Module Name: ctrl
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

module fifo_ctrl(
		 input 	       w_clk,
		 input 	       r_clk,
		 input 	       wr,
		 input 	       rd,
		 input [127:0] data_in,
		 output [31:0] data_out,
		 output [11:0] ind,
		 input 	       rst,
		 output        o_full_flag,
		 output        o_empty_flag
    );
   reg 			  wr_en_flag;
   reg 			  rd_en_flag;
   reg [31:0] 		  status;

   wire 		  wr_en;
   wire [127:0] 	  fifo_in;
   wire 		  full;
   wire 		  rd_en;
   wire [127:0] 	  fifo_out;
   wire 		  empty;

   
   my_fifo #(
		  .WA(8),
		  .WD(128)
		  )
     fifo (
	     .rst(rst),
	     .wclk(w_clk),
	     .wen(wr_en),
	     .wdat(fifo_in),
	     .wfull(full),
	     .rclk(r_clk),
	     .ren(rd_en),
	     .rdat(fifo_out),
	     .rempty(empty)
	     );
   reg 			  empty_flag;
   
   assign wr_en = wr_en_flag & (!full);
   assign rd_en = rd_en_flag & (!empty);
   assign o_full_flag = full;
   assign o_empty_flag = empty;
   assign gpio_out = status;

   reg [31:0] 		  count;

   always @(posedge r_clk) begin
      count = count + 1;
      status = {count[24:23], rd_en_flag, wr_en_flag, full, empty};
   end

   reg [127:0] current_fifo_data;
   assign fifo_in = current_fifo_data;
   
   always @(posedge w_clk) begin
      current_fifo_data = {data_in};
   end

   always @(posedge w_clk) begin
      wr_en_flag = wr;
   end
   
   reg	[2:0] r_addr;
   reg [127:0] current_rd_data;
   
   always @(posedge r_clk) begin
      if(rst) begin
	 rd_en_flag = 0;
	 current_rd_data=fifo_out;
	 r_addr = 0;
      end
      else if((r_addr == 0)||(r_addr == 1)||(r_addr==2)) begin
	 rd_en_flag = 0;
      	 if(rd) begin
	    r_addr = r_addr + 1;
	 end
      end
      else if(r_addr == 3) begin
      	 if(rd) begin
	    rd_en_flag = 1;
	    current_rd_data=fifo_out;
	    r_addr = 0;
	 end
      end
   end

   assign data_out = (r_addr==3)?current_rd_data[127:96]:
	      ((r_addr==2)?current_rd_data[96:64]:
	       ((r_addr==1)?current_rd_data[63:32]:current_rd_data[31:0]));

   assign ind = {count[23], rd_en_flag, wr_en_flag, full, empty};
endmodule
