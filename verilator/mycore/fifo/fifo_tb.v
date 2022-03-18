`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/08 10:25:28
// Design Name: 
// Module Name: sim2
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


module fifo_tb(

    );
   reg clk=0;

   parameter CYCLE = 10;
   
   always #(CYCLE/2) clk = ~clk;

   wire	       fifo_w_clk;
   wire	       fifo_r_clk;
   reg 	       fifo_wr=0;
   reg 	       fifo_rd=0;
   reg [127:0] fifo_data_in;
   wire [31:0] fifo_data_out;
   wire [11:0] fifo_ind;
   reg 	       fifo_rst=0;
   wire        fifo_o_full_flag;
   wire        fifo_o_empty_flag;

   
   fifo_ctrl fifo(
		  .w_clk(fifo_w_clk),
		  .r_clk(fifo_r_clk),
		  .wr(fifo_wr),
		  .rd(fifo_rd),
		  .data_in(fifo_data_in),
		  .data_out(fifo_data_out),
		  .ind(fifo_ind),
		  .rst(fifo_rst),
		  .o_full_flag(fifo_o_full_flag),
		  .o_empty_flag(fifo_o_empty_flag)
		  );
   assign fifo_w_clk = clk;
   assign fifo_r_clk = clk;


   wire        empty_0;
   wire        full_0;
   wire        almost_empty_0;
   wire        almost_full_0;
   reg [127:0] din_0;
   wire [31:0] dout_0;
   wire        rd_clk_0;
   reg 	       rd_en_0;
   reg 	       rst_0;
   wire        wr_clk_0;
   reg 	       wr_en_0;
   wire        rd_rst_busy_0;
   wire        wr_rst_busy_0;

   design_1_wrapper fifo2(
			  .rd_rst_busy_0(rd_rst_busy_0),
			  .wr_rst_busy_0(wr_rst_busy_0),
			  .almost_empty_0(almost_empty_0),
			  .almost_full_0(almost_full_0),
			  .empty_0(empty_0),
			  .full_0(full_0),
			  .din_0(din_0),
			  .dout_0(dout_0),
			  .rd_clk_0(rd_clk_0),
			  .rd_en_0(rd_en_0),
			  .rst_0(rst_0),
			  .wr_clk_0(wr_clk_0),
			  .wr_en_0(wr_en_0));

   assign wr_clk_0 = clk;
   assign rd_clk_0 = clk;
      
   integer     fd;

   reg [29:0] i;
   reg [29:0] j;
   initial begin
      fd = $fopen("aaa.res");
      $fwrite(fd, "queue\n", fifo_data_out);

      rst_0 = 1;
      rd_en_0 = 0;
      wr_en_0 = 0;
      din_0   = 0;

      #105
	rst_0 = 0;
      wr_en_0 = 0;

      while(wr_rst_busy_0!==0) begin
	 #1
			   i=0;
      end

      wr_en_0 = 1;
      i=0;
      while (i<512) begin
	 din_0 = {i,2'd3, i,2'd2, i,2'd1, i,2'd0};
	 #10
	   i = i+1;
      end
      j=0;
      wr_en_0 = 0;
      rd_en_0 = 1;
      $fdisplay(fd, "count %d:%d\n", j, dout_0);
      while (j<200) begin
	 #10
	   j= j+1;
	   $fdisplay(fd, "count %d:%d\n", j, dout_0);
      end
      wr_en_0 = 1;
      rd_en_0 = 0;
      while (!full_0) begin
	 din_0 = {i,2'd3, i,2'd2, i,2'd1, i,2'd0};
	 #10
	   i = i+1;
      end
      $display("full: i=%d\n",i);
      wr_en_0 = 0;
      rd_en_0 = 1;
      while (!empty_0) begin
	 #10
	   $fdisplay(fd, "count %d:%d\n", j, dout_0);
	   j= j+1;
      end
      $display("empty: j=%d\n",i);
      $fclose(fd);

      



//////// test for my fifo
      #100
	fifo_rst =1;
      fifo_data_in = ~0;

      
      #105
	fifo_rst =0;
	fifo_wr  =1;




      i=0;
      while (!fifo_o_full_flag) begin
	 fifo_data_in = {i,2'd3, i,2'd2, i,2'd1, i,2'd0};
	 #10 
	   i= i+1;
      end

      $display("i=%d\n",i);
      
      fifo_data_in = {i,2'd3, i,2'd2, i,2'd1, i,2'd0};
      #10
      fifo_wr  =0;
      fifo_rd  =1;

      j=0;
      while (j<200) begin
	 #5 $fdisplay(fd, "count %d:%d\n", j, fifo_data_out);
	 #5
	   j= j+1;
      end
      fifo_wr  =1;
      fifo_rd  =0;
      while (!fifo_o_full_flag) begin
	 fifo_data_in = {i,2'd3, i,2'd2, i,2'd1, i,2'd0};
	 #10 
	   i= i+1;
      end

      $display("i=%d\n",i);
      fifo_wr  =0;
      fifo_rd  =1;

      while (!fifo_o_empty_flag) begin
	 #5 $fdisplay(fd, "count %d:%d\n", j, fifo_data_out);
	 #5
	   j= j+1;
      end
      
      $fclose(fd);
   end
endmodule
