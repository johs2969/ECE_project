`timescale 1ns / 1ps

module bin2bcd(clk, rst, bin, bcd);

input clk,rst;
input [7:0] bin;
output reg [7:0] bcd;

always @(negedge rst or posedge clk) begin
    if(!rst) begin
    bcd <= {4'd0, 4'd0};
    end
    else begin
        case(bin)
        0 : bcd <={4'd0,4'd0};
        1 : bcd <={4'd0,4'd1};
        2 : bcd <={4'd0,4'd2};
        3 : bcd <={4'd0,4'd3};
        4 : bcd <={4'd0,4'd4};
        5 : bcd <={4'd0,4'd5};
        6 : bcd <={4'd0,4'd6};
        7 : bcd <={4'd0,4'd7};
        8 : bcd <={4'd0,4'd8};
        9 : bcd <={4'd0,4'd9};
        10 : bcd <={4'd1,4'd0};
        11 : bcd <={4'd1,4'd1};
        12 : bcd <={4'd1,4'd2};
        13 : bcd <={4'd1,4'd3};
        14 : bcd <={4'd1,4'd4};
        15 : bcd <={4'd1,4'd5};
        16 : bcd <={4'd1,4'd6};
        17 : bcd <={4'd1,4'd7};
        18 : bcd <={4'd1,4'd8};
        19 : bcd <={4'd1,4'd9};
        20 : bcd <={4'd2,4'd0};
        21 : bcd <={4'd2,4'd1};
        22 : bcd <={4'd2,4'd2};
        23 : bcd <={4'd2,4'd3};
        24 : bcd <={4'd2,4'd4};
        25 : bcd <={4'd2,4'd5};
        26 : bcd <={4'd2,4'd6};
        27 : bcd <={4'd2,4'd7};
        28 : bcd <={4'd2,4'd8};
        29 : bcd <={4'd2,4'd9};
        30 : bcd <={4'd3,4'd0};
        31 : bcd <={4'd3,4'd1};
        32 : bcd <={4'd3,4'd2};
        33 : bcd <={4'd3,4'd3};
        34 : bcd <={4'd3,4'd4};
        35 : bcd <={4'd3,4'd5};
        36 : bcd <={4'd3,4'd6};
        37 : bcd <={4'd3,4'd7};
        38 : bcd <={4'd3,4'd8};
        39 : bcd <={4'd3,4'd9};
        40 : bcd <={4'd4,4'd0};
        41 : bcd <={4'd4,4'd1};
        42 : bcd <={4'd4,4'd2};
        43 : bcd <={4'd4,4'd3};
        44 : bcd <={4'd4,4'd4};
        45 : bcd <={4'd4,4'd5};
        46 : bcd <={4'd4,4'd6};
        47 : bcd <={4'd4,4'd7};
        48 : bcd <={4'd4,4'd8};
        49 : bcd <={4'd4,4'd9};
        50 : bcd <={4'd5,4'd0};
        51 : bcd <={4'd5,4'd1};
        52 : bcd <={4'd5,4'd2};
        53 : bcd <={4'd5,4'd3};
        54 : bcd <={4'd5,4'd4};
        55 : bcd <={4'd5,4'd5};
        56 : bcd <={4'd5,4'd6};
        57 : bcd <={4'd5,4'd7};
        58 : bcd <={4'd5,4'd8};
        59 : bcd <={4'd5,4'd9};
        default bcd <={4'd0,4'd0};
        endcase
    end 
 end      
endmodule
