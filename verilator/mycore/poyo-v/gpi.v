//
// gpi
//


module gpi (
    input wire clk,
    input wire rst_n,
    input wire [31:0] wr_data,
    output reg [31:0] gpi_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
	        gpi_out <= 32'b00000000;
        end else begin
	        gpi_out <= wr_data;
        end
    end

endmodule
