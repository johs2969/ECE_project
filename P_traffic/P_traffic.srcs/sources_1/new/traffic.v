`timescale 1ns / 1ps

module traffic(rst, clk, flicker, sw_flicker, led_red, led_yellow, led_green, led_left, led_walk_red, led_walk_green, led_manual_flicker );

input clk,rst,flicker,sw_flicker;
output reg [3:0] led_red, led_yellow, led_green, led_walk_red, led_walk_green;
output [3:0] led_left;
output [1:0] led_manual_flicker;

reg [13:0] cnt_1h;
reg [3:0] cnt_circle;
reg [1:0] direction;

parameter S=2'b00,
          W=2'b01,
          E=2'b10,
          N=2'b11;
            
reg manual_flicker;
reg [1:0] reg_sw_flicker;

wire clk_1h, flicker_en, clk_flicker;

always @(posedge clk or posedge rst) begin
    if(rst)
        reg_sw_flicker <= 2'b00;
    else
        reg_sw_flicker <= {reg_sw_flicker[0],sw_flicker};
end

always @(posedge clk or posedge rst) begin
    if(rst)   
       manual_flicker <= 0;
    else if(reg_sw_flicker <= 2'b01)
      manual_flicker <= ~ manual_flicker;               
end

assign led_manual_flicker = manual_flicker;
assign flicker_en = ((manual_flicker == 1) || (flicker == 1) ? 1:0);

always @(posedge clk or posedge rst) begin
    if(rst) 
        cnt_1h <= 0;
    else if(cnt_1h >=9999)
        cnt_1h <=0;
     else
     cnt_1h <= cnt_1h +1;
end

assign clk_1h = (cnt_1h >=9999) ? 1:0;
assign clk_flicker = (cnt_1h >=4999) ? 0:1;            

always @(posedge clk or posedge rst) begin
    if(rst) 
        direction <= S;
    else if (flicker_en == 1)
        direction <= S;
    else if((clk_1h ==1) && (cnt_circle ==12))
        case(direction)
            S :direction <= N;
            N :direction <= W;    
            W :direction <= E;
            E :direction <= S;
        endcase
end 

always @(posedge clk or posedge rst) begin
    if(rst) begin
        led_red <=4'b0000;
        led_green <=4'b0000;
        led_yellow <=4'b0000;
        led_walk_red <=4'b0000;
        led_walk_green <=4'b0000;
        end
    else if (flicker_en == 1) begin
        led_red <=4'b0000;
        led_green <=4'b0000;
        led_yellow <={4{clk_flicker}};
        led_walk_red <={4{clk_flicker}};
        led_walk_green <=4'b0000;    
        end
    else
        case(direction)
            S: begin
                if(cnt_circle <=10) begin
                    led_red <=4'b0111;
                    led_green <=4'b1000;
                    led_yellow <=4'b0000;    
                  end 
                 else begin
                    led_red <=4'b0111;
                    led_green <=4'b0000;
                    led_yellow <=4'b1000;
                    end
                 if(cnt_circle <=3) begin
                    led_walk_red <=4'b1011;
                    led_walk_green <=4'b0100;   
                    end    
                 else if(cnt_circle <=10) begin  
                   led_walk_red <=4'b1011;
                    led_walk_green <={1'b0,~clk_flicker, 2'b00}; 
                    end
                 else begin
                    led_walk_red <=4'b1111;
                    led_walk_green <=4'b0000;   
                    end
                 end
             N: begin
                if(cnt_circle <=10) begin
                    led_red <=4'b1011;
                    led_green <=4'b0100;
                    led_yellow <=4'b0000;    
                  end 
                 else begin
                    led_red <=4'b1011;
                    led_green <=4'b0000;
                    led_yellow <=4'b0100;
                    end
                 if(cnt_circle <=3) begin
                    led_walk_red <=4'b1101;
                    led_walk_green <=4'b0010;   
                    end    
                 else if(cnt_circle <=10) begin  
                   led_walk_red <=4'b1101;
                    led_walk_green <={2'b00,~clk_flicker, 1'b0}; 
                    end
                 else begin
                    led_walk_red <=4'b1111;
                    led_walk_green <=4'b0000;   
                    end
                 end                
             W: begin
                if(cnt_circle <=10) begin
                    led_red <=4'b1101;
                    led_green <=4'b0010;
                    led_yellow <=4'b0000;    
                  end 
                 else begin
                    led_red <=4'b1101;
                    led_green <=4'b0000;
                    led_yellow <=4'b0010;
                    end
                 if(cnt_circle <=3) begin
                    led_walk_red <=4'b1110;
                    led_walk_green <=4'b0001;   
                    end    
                 else if(cnt_circle <=10) begin  
                   led_walk_red <=4'b1110;
                    led_walk_green <={3'b000,~clk_flicker}; 
                    end
                 else begin
                    led_walk_red <=4'b1111;
                    led_walk_green <=4'b0000;   
                    end
                 end
              E: begin
                if(cnt_circle <=10) begin
                    led_red <=4'b1110;
                    led_green <=4'b0001;
                    led_yellow <=4'b0000;    
                  end 
                 else begin
                    led_red <=4'b1110;
                    led_green <=4'b0000;
                    led_yellow <=4'b0001;
                    end
                 if(cnt_circle <=3) begin
                    led_walk_red <=4'b0111;
                    led_walk_green <=4'b1000;   
                    end    
                 else if(cnt_circle <=10) begin  
                   led_walk_red <=4'b0111;
                    led_walk_green <={~clk_flicker, 3'b000}; 
                    end
                 else begin
                    led_walk_red <=4'b1111;
                    led_walk_green <=4'b0000;   
                    end
                 end
               default: begin
                    led_red <=4'b0000;
                    led_green <=4'b0000;
                    led_yellow <=4'b0000;
                    led_walk_red <=4'b0000;
                    led_walk_green <=4'b0000;  
                  end
                endcase
end

assign led_left = led_green;                     
endmodule
