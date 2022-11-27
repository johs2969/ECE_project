`timescale 1ns / 1ps

module oneshot_universal(clk, rst, btn, btn_trig);

parameter width=1;
input clk,rst;
input [width-1:0] btn;
reg [width-1:0] btn_reg;
output reg [width-1:0] btn_trig;

always @(negedge rst or posedge clk) begin
    if(!rst) begin
        btn_reg <= {width{1'b0}};
        btn_trig <=  {width{1'b0}};
    end
    else begin
        btn_reg <=btn;
        btn_trig <=btn & ~btn_reg;
    end
 end           
endmodule