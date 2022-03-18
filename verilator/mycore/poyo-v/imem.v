//
// imem
//


`include "define.vh"

module imem (
    input wire 	       clk,
    input wire [31:0]  addr,
    output wire [31:0] rd_data
);
    reg [31:0] mem [0:8191];  // 521kbyte, 19bit address.
    reg [12:0] addr_sync;     // 17bit 
    initial $readmemh({`MEM_DATA_PATH, "code.hex"}, mem);
       
                
    always @(posedge clk) begin
       addr_sync <= addr[14:2];
    end
    
    assign rd_data = mem[addr_sync];

endmodule
