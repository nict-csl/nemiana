`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/12 17:22:59
// Design Name: 
// Module Name: cpu_tb
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


module cpu_tb(

    );


   reg clk;
   parameter CYCLE = 10;

   always #(CYCLE/2) clk = ~clk;

   wire [31:0] cpu_write_addr_in;
   wire [31:0] cpu_write_data_in;
   wire [31:0] cpu_write_enable_in;
   reg [31:0] cpu_ctrl_in;
   
   cpu_top cpu_top (
		    .cpu_write_addr_in(cpu_write_addr_in),
		    .cpu_write_data_in(cpu_write_data_in),
		    .cpu_write_enable_in(cpu_write_enable_in),
		    .cpu_ctrl_in(cpu_ctrl_in),
		    .clk(clk)
		    );


   wire       clock = clk;
   wire       clock2 = clk;
   reg 	      nreset;
   reg 	      fifo_reset;

   reg [31:0] s_tdata;
   reg [3:0]  s_tkeep;
   reg 	      s_tlast;
   wire       s_tready;
   reg 	      s_tvalid;
   wire [63:0]  dma_ctrl_dma_out;
   reg 		dma_ctrl_dma_re;
   wire 	dma_ctrl_dma_r_enable;
   wire [11:0]  dma_trans_led;
   
   dma_trans dma_trans(
   		    .pl_clk(clock),
   		    .cpu_clk(clock2),
   		    .nreset(nreset),
   		    .fifo_reset(fifo_reset),
   		    .led(dma_trans_led),
   		    .s_tdata(s_tdata),
   		    .s_tkeep(s_tkeep),
   		    .s_tlast(s_tlast),
   		    .s_tready(s_tready),
   		    .s_tvalid(s_tvalid),
   		    .dma_out(dma_ctrl_dma_out),
   		    .dma_re(dma_ctrl_dma_re),
   		    .dma_r_enable(dma_ctrl_dma_r_enable)
   		    );

   assign cpu_write_addr_in= dma_ctrl_dma_out[63:32];
   assign cpu_write_data_in= dma_ctrl_dma_out[31:0];
   assign cpu_write_enable_in = dma_ctrl_dma_r_enable;
   
   integer fd;
   integer count;
       
   reg [31:0] i;

   initial begin
      clk = 1'd0;
      cpu_ctrl_in=1;
      // initialize DMA
      nreset =  0;
      fifo_reset =  1;
      s_tdata = 0;
      s_tkeep = 0;
      s_tlast = 0;
      s_tvalid = 0;
      dma_ctrl_dma_re = 0;

      #100 //reset fifo
	nreset =  1;
      fifo_reset = 0;
      cpu_ctrl_in=32'h00000000;
      #10005
	s_tvalid = 1;
	i=0;
	//
	// load fifo
      while(i<32) begin
	   s_tdata = i+ 32'h80000000;
	 #10
	   s_tdata = 32'hDEADBEAF+i;
	 #10
	   i=i+1;
      end
      i=0;
      while(i<32) begin
	   s_tdata = i*4+ 32'h20000000;
	 #10
	   s_tdata = 32'hDEADBEAF+i;
	 #10
	   i=i+1;
      end
      s_tlast  = 0;
      s_tvalid = 0;

      // reset cpu
      # 100
	cpu_ctrl_in=32'h00000001;
      //Enter restore mode
      //write register
      # 100
	cpu_ctrl_in= 32'h00000003;
      
      i=0;
      dma_ctrl_dma_re = 1;
      cpu_ctrl_in= 32'h00000007;
      while(i<64) begin
	 #10
	   i = i+ 1;
	 
      end
      dma_ctrl_dma_re = 0;
      cpu_ctrl_in= 32'h00000003;
      //REGISTER Update
      cpu_ctrl_in = 32'h00000043;
      # 20000
	cpu_ctrl_in= 32'h00000003;


      

      
   end

   

   
endmodule
