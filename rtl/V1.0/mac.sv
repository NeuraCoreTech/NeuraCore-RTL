`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2026 15:21:42
// Design Name: 
// Module Name: mac
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


module mac#(
    parameter DATA_WIDTH = 8,
    parameter MULT_WIDTH = 16
)(
    input logic                  clk,
    input logic                  ce,
    input logic                  sclr,
    input logic [DATA_WIDTH-1:0] ifmap,
    input logic [DATA_WIDTH-1:0] filter,
    input logic [DATA_WIDTH-1:0] psumin,
    output logic [DATA_WIDTH-1:0] psumout
    );
    logic [MULT_WIDTH-1:0] mult_out,out_raw;
    logic [DATA_WIDTH-1:0] clamped_out;
    
    generate 
    if (DATA_WIDTH==8)begin
        mult_width8b mult(
        .CLK(clk),
        .A(ifmap),
        .B(filter),
        .CE(ce),
        .SCLR(sclr),
        .P(mult_out)
        );
    end else begin
    // fallback (DSP inference)
    assign mult_out = ifmap * filter;
    end
    endgenerate

     always_ff @(posedge clk) begin
    if (sclr)
        psumout <= 0;
    else if (ce) begin
        out_raw <= mult_out + {{DATA_WIDTH{1'b0}}, psumin};

        if (out_raw > {{DATA_WIDTH{1'b0}}, {DATA_WIDTH{1'b1}}})
            psumout <= {DATA_WIDTH{1'b1}};
        else
            psumout <= out_raw[DATA_WIDTH-1:0];
    end
end
    
    
    
    
endmodule
