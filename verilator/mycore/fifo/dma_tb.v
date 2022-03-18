`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/07 14:55:48
// Design Name: 
// Module Name: sim
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


module sim(

    );



   reg clk=0;

   parameter CYCLE = 10;
   
   always #(CYCLE/2) clk = ~clk;

   reg nreset = 0;
   reg [3:0] btn = 0;
   wire [11:0] led;
   reg [31:0]  gpio0 = 0;
   wire [31:0] gpio1;

   reg [31:0]  s_tdata=0;
   reg [3:0]   s_tkeep=0;
   reg 	       s_tlast=0;
   wire        s_tready=0;
   reg 	       s_tvalid=0;
   wire [31:0] m_tdata;
   wire [3:0]  m_tkeep;
   wire        m_tlast;
   reg 	       m_tready=0;
   wire        m_tvalid;
   reg [31:0]  i;
   
   dma_ctrl dma_ctrl1(
		  .clock(clk),
		  .nreset(nreset),
		  .led(led),
		  .gpio0(gpio0),
		  .gpio1(gpio1),
		  .s_tdata(s_tdata),
		  .s_tkeep(s_tkeep),
		  .s_tlast(s_tlast),
		  .s_tready(s_tready),
		  .s_tvalid(s_tvalid),
		  .m_tdata(m_tdata),
		  .m_tkeep(m_tkeep),
		  .m_tlast(m_tlast),
		  .m_tready(m_tready),
		  .m_tvalid(m_tvalid)
	      );

   integer     fd;   
   initial begin

      fd = $fopen("aaa.res");


      #100
	nreset =0;
      #100
	nreset =1;
      #100
	gpio0 =1;

      #1000
	m_tready=1;

      #5 i=0;
      #10 $fdisplay(fd, "Turn 1");
      while(!m_tlast) begin
	 #5 $fdisplay(fd, "count %i:%d %x:%x\n", i, m_tdata>>16, m_tdata&65535);
	 #5 i= i+1;
      end
      $fflush(fd);
      gpio0 = 0;

      #10 gpio0 = 1;
      #10 $fdisplay(fd, "Turn 2");
      while(!m_tlast) begin
	 #5 $fdisplay(fd, "count %i:%d %x:%x\n", i, m_tdata>>16, m_tdata&65535);
	 #5 i= i+1;
      end
      $fflush(fd);
      #10 gpio0 = 0;
      
      #10 gpio0 = 1;
      #10 $fdisplay(fd, "Turn 3");
      while(!m_tlast) begin
	 #5 $fdisplay(fd, "count %i:%d %x:%x\n", i, m_tdata>>16, m_tdata&65535);
	 #5 i= i+1;
      end
      $fclose(fd);
      #10 gpio0 = 0;
      $stop;
      
	
   end
endmodule
