`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.04.2026 09:30:31
// Design Name: 
// Module Name: fifo_24b_8d
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


module fifo_block#(
parameter DATA_WIDTH=8,
parameter DEPTH=8,
parameter ADD_WIDTH=$clog2(DEPTH)
    )(
    input logic                   clk,
    input logic                   reset,
    input logic                   we,
    input logic                   re,
    input logic  [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  empty_flag,
    output logic                  full_flag  
);

    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    logic [ADD_WIDTH-1:0]  wr_ptr, rd_ptr, count;

    // Memory write
    always_ff @(posedge clk) begin
        if (we && !full_flag)
            mem[wr_ptr] <= data_in;
    end

    // Read output
    always_ff @(posedge clk) begin
        if (re && !empty_flag)
            data_out <= mem[rd_ptr];
    end

    // Pointer and count control
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
        end else begin 
            case ({we & !full_flag, re & !empty_flag})
                2'b10: begin wr_ptr <= wr_ptr + 1'b1; count <= count + 1'b1; end
                2'b01: begin rd_ptr <= rd_ptr + 1'b1; count <= count - 1'b1; end
                2'b11: begin wr_ptr <= wr_ptr + 1'b1; rd_ptr <= rd_ptr + 1'b1; end
                default: ;
            endcase
        end
    end

    assign empty_flag = (count == '0); 
    assign full_flag  = (count == DEPTH);

endmodule