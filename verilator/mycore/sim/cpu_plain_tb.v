`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/15 14:59:26
// Design Name: 
// Module Name: cpu_plain_tb
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


module cpu_plain_tb(

    );
   reg clk;
   parameter CYCLE = 10;

   wire [31:0] cpu_write_addr_in=0;
   wire [31:0] cpu_write_data_in=0;
   wire [31:0] cpu_write_enable_in;
   reg [31:0] cpu_ctrl_in;
   reg 	      stall_enable_in;
   reg 	      stall_disable_in;
   wire       is_stall_enabled_out;
   wire [127:0] iana_out;
   
   reg [31:0] clk_count;
   integer    fd;

   task wait_count;
      input integer c;
      
      begin 
	 repeat(c) begin
            #(CYCLE/2) 
	    clk <= ~clk;
            #(CYCLE/2) 
	    clk <= ~clk;
	    clk_count <= clk_count+1;

	    $fdisplay(fd, "%08X %08X %08X %08X", 
		      iana_out[127:96], iana_out[95:64],
		      iana_out[63:32], iana_out[31:0]);
	 end
      end
   endtask // step
   
   
   cpu_top cpu_top (
		    .cpu_write_addr_in(cpu_write_addr_in),
		    .cpu_write_data_in(cpu_write_data_in),
		    .cpu_write_enable_in(cpu_write_enable_in),
		    .cpu_ctrl_in(cpu_ctrl_in),
		    .iana_out(iana_out),
		    .stall_enable_in(stall_enable_in),
		    .stall_disable_in(stall_disable_in),
		    .is_stall_enabled_out(is_stall_enabled_out),
		    .clk(clk)
		    );


   wire       clock = clk;
   
   initial begin

      fd = $fopen ("trace1.log");
      
      clk <= 1'd0;
      clk_count <= 0;
      cpu_ctrl_in <= 1;
      stall_enable_in <=0;
      stall_disable_in <=0;

      wait_count(32'H10);
      #10 cpu_ctrl_in <=0;
      clk_count <= 0;
      #10 
	wait_count(32'H10000);
      #10 cpu_ctrl_in = 1<<12;  //      #10 cpu_ctrl_in =1<<11;
      wait_count(32'H5);
      #10 cpu_ctrl_in = 0<<12;  //      #10 cpu_ctrl_in =1<<11;
      #5
	wait_count(32'H10);
      #10 
	wait_count(32'H23);
      #10 cpu_ctrl_in = 1<<11;  //      #10 cpu_ctrl_in =1<<11;
      wait_count(5);
      #10 cpu_ctrl_in = 0<<11;
      #10 wait_count(10);
      #10 cpu_ctrl_in = 1<<12;  //      #10 cpu_ctrl_in =1<<11;
      wait_count(5);
      #10 cpu_ctrl_in = 0<<12;
      #10 wait_count(10);
      #10 stall_enable_in = 1;
      #10 wait_count(5);
      #10 stall_enable_in = 0;
      #10 wait_count(10);
      #10 stall_disable_in = 1;
      #10 wait_count(5);
      #10 stall_disable_in = 0;
      #10 wait_count(10);
      $fflush(fd);
      $stop;

   end

endmodule
