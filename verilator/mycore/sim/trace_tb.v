`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/20 11:49:58
// Design Name: 
// Module Name: trace_tb
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


`define CPU_RESET         (1<<0)
`define RESTORE_MODE      (1<<1)
`define UPDATE_REGISTER   (1<<6)
`define UPDATE_PC         (1<<7)
`define TRACE_FAULT       (1<<13)

module trace_tb(

    );

   reg clk;
   reg clk2;
   
   parameter CYCLE = 10;

   reg [31:0] cpu_write_addr_in;
   reg [31:0] cpu_write_data_in;
   reg        cpu_write_enable_in;

   reg [31:0]  cpu_ctrl_in;
   wire	       stall_enable_in;
   reg 	       stall_disable_in;
   wire        is_stall_enabled_out;
   wire [127:0] iana_out;
   wire 	clock  = clk | clk2;
   wire 	clock2 = clk2;

   reg [31:0] clk_count;
   reg [31:0] clk2_count;
   integer    fd;

   reg 	      trace_flag;
   reg 	      nreset;
   reg 	      fifo_reset;

   wire [31:0] 	m_tdata;
   wire [3:0] 	m_tkeep;
   wire 	m_tlast;
   reg 		m_tready;
   wire 	m_tvalid
;
   wire [127:0] dma_ctrl_dma_in;
   reg 		dma_ctrl_dma_we;
   reg 		dma_ctrl_dma_start;
   wire [11:0] 	dma_ctrl_led;
   wire 	dma_ctrl_dma_writable;
   wire [3:0]	cpu_led;

   integer 		fd2;
   integer 		dma_count;
   integer 		dma_call;
   
   task wait_count;
      input integer c;
      
      begin 
	 repeat(c) begin
            #(CYCLE/2) 
	    clk2 <= ~clk2;
            #(CYCLE/2) 
	    clk2 <= ~clk2;
	    clk2_count <= clk2_count+1;

	    if((trace_flag==1) && (dma_ctrl_dma_we==1)) begin
	       $fdisplay(fd, "attr2:%08X,%08X,%08X,%08X", 
			 iana_out[127:96] , iana_out[95:64],
			 iana_out[63:32], iana_out[31:0]);
	    end
	 end // repeat (c)
	 $fwrite(fd, "---- %d ----\n", dma_call);
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
		    .clk(clock2),
		    .led(cpu_led)
		    );
   
   dma_ctrl dma_ctl(
   		    .pl_clk(clock),
		    .cpu_clk(clock2),
   		    .nreset(nreset),
		    .fifo_reset(fifo_reset),
		    .dma_start(dma_ctrl_dma_start),
   		    .led(dma_ctrl_led),
   		    .m_tdata(m_tdata),
   		    .m_tkeep(m_tkeep),
   		    .m_tlast(m_tlast),
   		    .m_tready(m_tready),
   		    .m_tvalid(m_tvalid),
		    .dma_in(dma_ctrl_dma_in),
		    .dma_we(dma_ctrl_dma_we),
		    .dma_writable(dma_ctrl_dma_writable)
   		    );

   assign dma_ctrl_dma_in = iana_out;

   reg prev_dma_ctrl_dma_we;
   reg prev_dma_ctrl_dma_we2;
   reg prev_dma_ctrl_dma_we3;
   always @(posedge clock2 or negedge nreset) begin
      if(!nreset) begin
	 prev_dma_ctrl_dma_we <= 0;
	 dma_ctrl_dma_we = 0;
      end
      else begin
	 prev_dma_ctrl_dma_we  <= !is_stall_enabled_out;
//	 dma_ctrl_dma_we <= prev_dma_ctrl_dma_we | (!is_stall_enabled_out);
	 prev_dma_ctrl_dma_we2 <= prev_dma_ctrl_dma_we;
	 prev_dma_ctrl_dma_we3 <= prev_dma_ctrl_dma_we2;
	 dma_ctrl_dma_we <= (prev_dma_ctrl_dma_we3 & (!cpu_ctrl_in[0])) | (!is_stall_enabled_out);
      end
   end
   // CPUの中で作っていないので，外側で調整作る必要がある．
   assign stall_enable_in = (!dma_ctrl_dma_writable) & (cpu_ctrl_in[13]);

   integer read_count;
 		
   task read_from_dma;
      begin
	 read_count = 0;
	 if(dma_ctrl_led[4] == 1'b0) begin
	    m_tready = 1;
	    dma_ctrl_dma_start = 1;
	    #10
	      while (~m_tvalid) begin
		 #(CYCLE/2) 
		 clk <= ~clk;
		 #(CYCLE/2) 
		 clk <= ~clk;
		 clk_count <= clk_count+1;
	      end // repeat (c)
	    while (m_tvalid) begin
	       if (read_count>11) begin
		  if ((read_count % 4) == 0) begin
		     $fwrite(fd2, "attr2:");
		  end
		  $fwrite(fd2, "%08X", m_tdata);
		  if ((read_count % 4) == 3) begin
		     $fwrite(fd2, "\n");
		  end
		  else begin
		     $fwrite(fd2, ",");
		  end
	       end
	       #(CYCLE/2) 
	       clk <= ~clk;
	       #(CYCLE/2)
	       dma_count = dma_count + 1;
	       read_count = read_count + 1;
	       clk <= ~clk;
	       clk_count <= clk_count+1;
	    end // repeat (c)
	    m_tready = 0;
	    dma_ctrl_dma_start = 0;
	 end // if (dma_ctrl_led[4] === 0)
         #(CYCLE/2) 
	 clk <= ~clk;
         #(CYCLE/2) 
	 clk <= ~clk;
	 $fwrite(fd2, "\n---- %d ----\n", dma_call);
	 dma_call = dma_call+1;
      end
   endtask // step
   
   task wait_resume_enable;
      begin
	 while (!dma_ctrl_dma_writable) begin
            #(CYCLE/2) 
	    clk2 <= ~clk2;
            #(CYCLE/2) 
	    clk2 <= ~clk2;
	 end
         #(CYCLE/2) 
	 clk2 <= ~clk2;
	 stall_disable_in = 1;
         #(CYCLE/2) 
	 clk2 <= ~clk2;
         #(CYCLE/2) 
	 clk2 <= ~clk2;
	 stall_disable_in = 0;
         #(CYCLE/2) 
	 clk2 <= ~clk2;
      end
      
   endtask // step

   task set_resume_enable;
      begin
         #(CYCLE/2) 
	 clk2 <= ~clk2;
	 stall_disable_in = 1;
         #(CYCLE/2) 
	 clk2 <= ~clk2;
         #(CYCLE/2) 
	 clk2 <= ~clk2;
	 stall_disable_in = 0;
         #(CYCLE/2) 
	 clk2 <= ~clk2;
      end
      
   endtask // step

   task trace_test;
      input integer c;
      begin
	 #10 wait_count(5000);
	 read_from_dma();
	 wait_resume_enable();
	 $fdisplay(fd, "%d:--------", c);
	 $fdisplay(fd2, "%d:--------", c);
	 $fflush(fd);
	 $fflush(fd2);
      end
   endtask // trace_test

   reg [31:0] w_addr;
   reg [31:0] w_data;
   integer    res;
   
   task apply_modify;
      input integer fd3;
      begin
	 #10 cpu_ctrl_in <= `RESTORE_MODE;
	 #10
	   wait_count(10);
	 while(!$feof(fd3)) begin
	    res = $fscanf(fd3, "%h %h\n", w_addr, w_data);
	    if(res>0) begin
	       $display("inputdata: %h %h\n", w_addr, w_data);
	       cpu_write_addr_in   = w_addr;
	       cpu_write_data_in   = w_data;
	       cpu_write_enable_in = 1;
	       #10 wait_count(4);
	       #10
		 cpu_write_enable_in = 0;
	       #10 wait_count(1);
	    end
	 end
	 #10 wait_count(100);
	 #10 cpu_ctrl_in <= 0;
      end
   endtask // apply_modify

   integer call_num;
   string  filename;
   
   task execute_loop;
      integer res_fd;
      begin
	 #10
	   wait_count(32'H1000);
	 #10 read_from_dma();
	 #10
	   if(cpu_led[0] === 1'b1) begin
	      filename = $sformatf("call%0d.txt", call_num);
	      res_fd= $fopen(filename,"r");
	      apply_modify(res_fd);
	      $fclose(res_fd);
	   end
	 set_resume_enable();
      end
   endtask

   integer res_fd;   
   integer i;

   initial begin
      call_num = 1;
      clk=0;
      clk2=0;
      trace_flag =0;
      dma_count=0;
      dma_call=0;
      clk_count=0;
      clk2_count=0;
      fd = $fopen ("trace2.log");
      fd2 = $fopen("trace3.log");
      cpu_ctrl_in = 0;
      stall_disable_in = 0;
      nreset = 0;
      fifo_reset =1;
      dma_ctrl_dma_start = 0;
      m_tready = 0;
      
      cpu_write_addr_in=0;
      cpu_write_data_in=0;
      cpu_write_enable_in=0;

      $stop();
      
      #10 wait_count(32'H1000);
	cpu_ctrl_in = `CPU_RESET;
      fifo_reset  = 1;
      nreset = 1;
      #10 wait_count(32'H10);
      fifo_reset  = 0;
      while(!dma_ctrl_dma_writable) begin
	 #10 wait_count(32'H10);
      end
      $stop();
      #10
      trace_flag <=1;
//      cpu_ctrl_in <= `TRACE_FAULT;
      cpu_ctrl_in <= 0;

      #10

      i=0;
      while(i<10) begin
	 execute_loop();
	 i = i+1;
      end
      
      wait_count(32'H1000);
      $fflush(fd);
      $fflush(fd2);
      $stop();
      
      #10
      cpu_ctrl_in <= `TRACE_FAULT; //DMA転送をするテスト
      i=0;
      while(i<10) begin
	 trace_test(i);
	 i = i+1;
      end

      $fclose(fd);
      $fclose(fd2);
      $stop;
   end

   
   
endmodule
