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


module dma_ctrl(
	     input wire 	pl_clk,
	     input wire 	cpu_clk, 
	     input wire 	nreset,
	     input wire 	fifo_reset,
	     input wire 	dma_start,
	     output wire [11:0] led,
             output wire [31:0] m_tdata,
             output wire [3:0] 	m_tkeep,
             output wire 	m_tlast,
             input wire 	m_tready,
             output wire 	m_tvalid,

	     input wire [127:0] dma_in,
	     input wire 	dma_we,
	     output wire 	dma_writable
	     );

   wire [31:0] 			data;
   reg last_flag;
   reg valid_flag;
   wire ready_flag;
   
   assign m_tkeep = 15;
   assign m_tlast = last_flag;
   assign m_tvalid = valid_flag;

   reg [31:0] 		   count;

   always  @(posedge pl_clk or negedge nreset) begin   
      if(!nreset) begin
	 count <= 0;
      end
      else begin
	 count <= count + 4;
      end
   end

   wire fifo_w_clk;
   wire fifo_r_clk;
   wire fifo_wr;
   wire fifo_rd;
   wire [127:0] fifo_data_in;
   wire [31:0] 	fifo_data_out;
   wire [11:0] 	fifo_ind;
   wire 	fifo_rst;
   wire 	fifo_full;
   wire 	fifo_empty;

   reg [31:0] 	fifo_count;
   reg 		fifo_wr_flag;
   reg [127:0] 	fifo_data_in_prev;
   reg 		read_flag;
   wire [31:0] 	data_in;
   wire 	start_flag;

   wire        rd_rst_busy_0;
   wire        wr_rst_busy_0;
   wire        fifo_enable = (rd_rst_busy_0===0) && (wr_rst_busy_0===0);

   assign dma_writable = !fifo_full & fifo_enable;
   
   design_1_wrapper fifo(
			 .rd_rst_busy_0(rd_rst_busy_0),
			 .wr_rst_busy_0(wr_rst_busy_0),
			 .empty_0(fifo_empty),
			 .full_0(fifo_full),
			 .din_0(fifo_data_in),
			 .dout_0(fifo_data_out),
			 .rd_clk_0(fifo_r_clk),
			 .rd_en_0(fifo_rd),
			 .rst_0(fifo_rst),
			 .wr_clk_0(fifo_w_clk),
			 .wr_en_0(fifo_wr));

   
   assign fifo_w_clk = cpu_clk;
   assign fifo_r_clk = pl_clk;
   assign fifo_wr = fifo_wr_flag;
   assign fifo_rd = read_flag;
   assign fifo_data_in = fifo_data_in_prev;
   assign fifo_rst = (!nreset) || fifo_reset;
   wire [29:0] 	fifo_count_4 = fifo_count[29:0];
   
   always @(posedge fifo_w_clk or posedge fifo_rst) begin
      if(fifo_rst) begin
	 fifo_count <= 0;
	 fifo_wr_flag <= 0;
	 fifo_data_in_prev <= 0;
      end
      else if(fifo_enable && dma_we) begin
	 fifo_count <= fifo_count +1;
	 fifo_wr_flag <= 1;
	 fifo_data_in_prev <= dma_in;
      end
      else begin
	 fifo_wr_flag <= 0;
	 fifo_data_in_prev <= ~0;
      end
   end

   assign start_flag = dma_start;
   reg [3:0] state2;
   reg [31:0] addr2;
   reg [31:0] write_data_count;
   assign m_tdata = (state2===2)?fifo_data_out:32'hFEFEFEFE;
  
   always @(posedge pl_clk) begin
      if(! nreset) begin
	 state2 <= 0;
	 last_flag <= 0;
	 valid_flag <= 0;
	 addr2 <= 0;
	 read_flag <= 0;
	 write_data_count<=0;
      end
      else if(state2 == 0) begin
	 if (start_flag && (!fifo_empty)) begin
	    state2 <= 1;
	    last_flag <= 0;
	    valid_flag <= 0;
	    addr2 <= 0;
	    read_flag <= 0;
	 end
	 else begin
	    state2 <= 0;
	    last_flag <= 0;
	    valid_flag <= 0;
	    read_flag <= 0;
	 end
      end
      else if(state2 == 1) begin
	 if (!fifo_empty) begin
	    state2 <= 6;
	    last_flag <= 0;
	    valid_flag <= 1;
	    addr2 <= 0;
	    read_flag <= 0;	
	 end
	 else begin
	    state2 <= 1;
	    last_flag <= 0;
	    valid_flag <= 0;
	    read_flag <= 0;
	 end
      end
      else if(state2 == 6) begin
	 if(m_tready) begin
	    addr2<=addr2+1;
	    if(addr2 > 6) begin
	       state2 <= 7;
	       read_flag <= 1;	
	    end
	    else begin
	       state2 <= 6;
	    end
	 end // if (m_tready)
      end
      else if(state2 == 7) begin
	 if(m_tready) begin
	    addr2<=addr2+1;
	    state2 <= 2;
	 end
	 else begin
	    state2 <= 7;
	 end // if (m_tready)
      end
      else if(state2 == 2) begin
	 if(!start_flag) begin
	    state2 <= 0;
	    last_flag <= 0;
	    valid_flag <= 0;
	    read_flag <= 0;
	 end
	 else if(m_tready) begin
	    if (fifo_empty) begin
	       state2 <= 4;
	       last_flag <= 1;
	       read_flag <= 0;
	    end
	    else if (addr2==32767) begin
	       state2 <= 4;
	       last_flag <= 1;
	       read_flag <= 0;
	       write_data_count <= write_data_count+1;
	    end
	    else begin
	       read_flag <= 1;
	       addr2<=addr2+1;
	       write_data_count <= write_data_count+1;
	       state2 <= 2;
	    end
	 end // if (m_tready)
	 else begin
	    read_flag <= 0;
	 end
      end
      else if(state2 == 3) begin
	 state2<=2;
      end
      else if(state2 == 4) begin
	 last_flag <= 0;
	 addr2<=0;
	 state2<=5;
	 valid_flag <= 0;
	 read_flag <= 0;
      end
      else if(state2 == 5) begin
	 if(!start_flag) begin
	    state2 <= 0;
	    last_flag <= 0;
	    valid_flag <= 0;
	    read_flag <= 0;
	 end
      end
      else begin
	 state2 <= 0;
	 addr2 <= 0;
	 valid_flag <= 0;
      end
   end // always @ (posedge pl_clk)

   assign led = data;
   assign data = {count[31:24], state2, fifo_enable, fifo_full, fifo_empty, start_flag, last_flag, valid_flag, m_tready};
endmodule
