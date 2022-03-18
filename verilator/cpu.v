module cpu(
	  input [31:0] 	 cpu_write_addr_in,
	  input [31:0] 	 cpu_write_data_in,
	  input 	 cpu_write_enable_in,
	  input [31:0] 	 cpu_ctrl_in,
	  output [31:0]  cpu_state,
	  output [127:0] iana_out,
	  output 	 is_stall_enabled_out,
	  input 	 cpu_resume,
	  input 	 stall_enable_in,
	  output [3:0] 	 cpu_led,

	  input 	 clock,
	  input 	 reset
	   );

   wire [31:0] 		 gpi_in=0;
   wire [31:0] 		 gpo_out;
   wire [31:0] 		 gpi1_in=0;
   wire [31:0] 		 gpo1_out;
   wire 		 uart_tx;
   wire 		 uart_rx=0;
   assign cpu_state = {28'h0, cpu_led};

   cpu_top cpu_top (
		    .cpu_write_addr_in(cpu_write_addr_in),
		    .cpu_write_data_in(cpu_write_data_in),
		    .cpu_write_enable_in(cpu_write_enable_in),
		    .cpu_ctrl_in(cpu_ctrl_in),
		    .iana_out(iana_out),
		    .stall_enable_in(stall_enable_in),
		    .stall_disable_in(cpu_resume),
		    .is_stall_enabled_out(is_stall_enabled_out),

		    .gpi_in(gpi_in),
		    .gpo_out(gpo_out),
		    .gpi1_in(gpi1_in),
		    .gpo1_out(gpo1_out),
		    .uart_tx(uart_tx),
		    .uart_rx(uart_rx),
		    
		    .clk(clock),
		    .led(cpu_led)
		    );
endmodule // cpu
