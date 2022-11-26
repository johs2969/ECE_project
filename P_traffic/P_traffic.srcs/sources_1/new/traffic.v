`timescale 1ns / 1ps
//10khz 기준
module traffic(rst, clk, led_red, led_yellow, led_green, led_left, led_walk_red, led_walk_green);

input clk,rst;
output reg [3:0] led_red, led_yellow, led_green, led_walk_red, led_walk_green, led_left;

reg [13:0] cnt_1h;
wire clk_flicker;

// 점멸신호 10khz 기준으로 0.5초마다 flicker가 바뀌며 점멸한다.

always @(posedge clk or posedge rst) begin
    if(rst) 
        cnt_1h <= 0;
    else if(cnt_1h >=9999)
        cnt_1h <=0;
     else
     cnt_1h <= cnt_1h +1;
end

assign clk_flicker = (cnt_1h >=4999) ? 0:1;            

// state 변경 ,aaa는 주간 시간, bbb는 야간 시간이다. 실제로 내부시계를 이용해서 구현해야하는데, 일단 임시로 설정.

reg [3:0] state;
parameter A1=4'b0000,
          A2=4'b0001,
          B=4'b0010,
          C=4'b0011,
          D=4'b0100,
          E1=4'b0101,
          E2=4'b0110,
          F=4'b0111,
          G=4'b1000,
          H=4'b1001;

integer cnt;
reg [31:0] hold_t=0;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= A1;
        cnt <=0;
        end
    else if(aaa) begin// 5초 유지시간 주간 case
        hold_t<= 50000;
        case(state)
            A1:begin if(cnt >= 50000) state <= D;
            if(cnt >= 50000) cnt <=0;
                else cnt <= cnt+1;
            end    
            D :begin if(cnt >= 50000) state <= E1;
            if(cnt >= 50000) cnt <=0;
                else cnt <= cnt+1;
            end                 
            E1 :begin if(cnt >= 50000) state <= F;
            if(cnt >= 50000) cnt <=0;
                else cnt <= cnt+1;
            end 
            F :begin if(cnt >= 50000) state <= E2;
            if(cnt >= 50000) cnt <=0;
                else cnt <= cnt+1;
            end 
            E2 :begin if(cnt >= 50000) state <= G;
            if(cnt >= 50000) cnt <=0;
                else cnt <= cnt+1;
            end 
            G :begin if(cnt >= 50000) state <= A1;
            if(cnt >= 50000) cnt <=0;
                else cnt <= cnt+1;
            end 
            default: state <= A1;
       endcase
     end  
    else if(bbb) begin // 10초 유지시간으로 변경해준다 야간 case    
         hold_t<= 100000;
       case(state)
            A1:begin if(cnt >= 100000) state <= B;
            if(cnt >= 100000) cnt <=0;
                else cnt <= cnt+1;
            end    
            B :begin if(cnt >= 100000) state <= A2;
            if(cnt >= 100000) cnt <=0;
                else cnt <= cnt+1;
            end                 
            A2 :begin if(cnt >= 100000) state <= C;
            if(cnt >= 100000) cnt <=0;
                else cnt <= cnt+1;
            end 
            C :begin if(cnt >= 100000) state <= E1;
            if(cnt >= 100000) cnt <=0;
                else cnt <= cnt+1;
            end 
            E1 :begin if(cnt >= 100000) state <= H;
            if(cnt >= 100000) cnt <=0;
                else cnt <= cnt+1;
            end 
            H :begin if(cnt >= 100000) state <= A1;
            if(cnt >= 100000) cnt <=0;
                else cnt <= cnt+1;
            end 
            default: state <= A1;
       endcase    
      end
end 

// state별 신호등 

always @(posedge clk or posedge rst) begin
    if(rst) begin
        led_red <=4'b0000;
        led_green <=4'b0000;
        led_yellow <=4'b0000;
        led_walk_red <=4'b0000;
        led_walk_green <=4'b0000;
        end
    else
        case(state)// 남.북, 서,,동 순서이다.
            A1,A2: begin
                if(cnt <= (5/6)*hold_t) begin
                    led_red <=4'b0011;
                    led_green <=4'b1100;
                    led_yellow <=4'b0000;
                    led_left <=4'b0000;   
                  end 
                 else begin
                    led_red <=4'b0011;
                    led_green <=4'b0000;
                    led_yellow <=4'b1100;
                    led_left <=4'b0000; 
                    end
                 if(cnt <= hold_t/2) begin
                    led_walk_red <=4'b1100;
                    led_walk_green <=4'b0011;   
                    end    
                 else if(cnt > hold_t/2) begin  
                   led_walk_red <=4'b1100;
                    led_walk_green <={2'b00,~clk_flicker,~clk_flicker}; 
                    end
                 end
             B: begin // 남.북, 서,,동 순서이다.
                if(cnt <= (5/6)*hold_t) begin
                    led_red <=4'b1011;
                    led_green <=4'b0100;
                    led_yellow <=4'b0000;
                    led_left <=4'b0100;   
                  end 
                 else begin
                    led_red <=4'b1011;
                    led_green <=4'b0000;
                    led_yellow <=4'b0100;
                    led_left <=4'b0000; 
                    end
                 if(cnt <= hold_t/2) begin
                    led_walk_red <=4'b1110;
                    led_walk_green <=4'b0001;   
                    end    
                 else if(cnt > hold_t/2) begin  
                   led_walk_red <=4'b1110;
                    led_walk_green <={3'b00,~clk_flicker}; 
                    end
                 end
             C: begin // 남.북, 서,,동 순서이다.
                if(cnt <= (5/6)*hold_t) begin
                    led_red <=4'b0111;
                    led_green <=4'b1000;
                    led_yellow <=4'b0000;
                    led_left <=4'b1000;   
                  end 
                 else begin
                    led_red <=4'b0111;
                    led_green <=4'b0000;
                    led_yellow <=4'b1000;
                    led_left <=4'b0000; 
                    end
                 if(cnt <= hold_t/2) begin
                    led_walk_red <=4'b1101;
                    led_walk_green <=4'b0010;   
                    end    
                 else if(cnt > hold_t/2) begin  
                   led_walk_red <=4'b1101;
                    led_walk_green <={2'b00,~clk_flicker,1'b0}; 
                    end
                 end
              D: begin // 남.북, 서,,동 순서이다.
                if(cnt <= (5/6)*hold_t) begin
                    led_red <=4'b0011;
                    led_green <=4'b0000;
                    led_yellow <=4'b0000;
                    led_left <=4'b1100;   
                  end 
                 else begin
                    led_red <=4'b0011;
                    led_green <=4'b0000;
                    led_yellow <=4'b1100;
                    led_left <=4'b0000; 
                    end
                 if(cnt <= hold_t/2) begin
                    led_walk_red <=4'b1111;
                    led_walk_green <=4'b0000;   
                    end    
                 else if(cnt > hold_t/2) begin  
                   led_walk_red <=4'b1111;
                    led_walk_green <=4'b0000;
                    end
                 end
              E1,E2: begin // 남.북, 서,,동 순서이다.
                if(cnt <= (5/6)*hold_t) begin
                    led_red <=4'b1100;
                    led_green <=4'b0011;
                    led_yellow <=4'b0000;
                    led_left <=4'b0000;   
                  end 
                 else begin
                    led_red <=4'b1100;
                    led_green <=4'b0000;
                    led_yellow <=4'b0011;
                    led_left <=4'b0000; 
                    end
                 if(cnt <= hold_t/2) begin
                    led_walk_red <=4'b0011;
                    led_walk_green <=4'b1100;   
                    end    
                 else if(cnt > hold_t/2) begin  
                   led_walk_red <=4'b0011;
                    led_walk_green <={~clk_flicker,~clk_flicker,2'b0}; 
                    end
                 end
              F: begin // 남.북, 서,,동 순서이다.
                if(cnt <= (5/6)*hold_t) begin
                    led_red <=4'b1101;
                    led_green <=4'b0010;
                    led_yellow <=4'b0000;
                    led_left <=4'b0010;   
                  end 
                 else begin
                    led_red <=4'b1101;
                    led_green <=4'b0000;
                    led_yellow <=4'b0010;
                    led_left <=4'b0000; 
                    end
                 if(cnt <= hold_t/2) begin
                    led_walk_red <=4'b1011;
                    led_walk_green <=4'b0100;   
                    end    
                 else if(cnt > hold_t/2) begin  
                   led_walk_red <=4'b1011;
                    led_walk_green <={1'b0,~clk_flicker,2'b00};
                    end
                 end
               G: begin // 남.북, 서,,동 순서이다.
                if(cnt <= (5/6)*hold_t) begin
                    led_red <=4'b1110;
                    led_green <=4'b0001;
                    led_yellow <=4'b0000;
                    led_left <=4'b0001;   
                  end 
                 else begin
                    led_red <=4'b1110;
                    led_green <=4'b0000;
                    led_yellow <=4'b0001;
                    led_left <=4'b0000; 
                    end
                 if(cnt <= hold_t/2) begin
                    led_walk_red <=4'b0111;
                    led_walk_green <=4'b1000;   
                    end    
                 else if(cnt > hold_t/2) begin  
                   led_walk_red <=4'b0111;
                    led_walk_green <={~clk_flicker,3'b000};
                    end
                 end 
              H: begin // 남.북, 서,,동 순서이다.
                if((cnt <= (5/6)*hold_t) begin
                    led_red <=4'b1100;
                    led_green <=4'b0000;
                    led_yellow <=4'b0000;
                    led_left <=4'b0011;   
                  end 
                 else begin
                    led_red <=4'b1100;
                    led_green <=4'b0000;
                    led_yellow <=4'b0011;
                    led_left <=4'b0000; 
                    end
                 if(cnt <= hold_t/2) begin
                    led_walk_red <=4'b1111;
                    led_walk_green <=4'b0000;   
                    end    
                 else if(cnt > hold_t/2) begin  
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
                    
endmodule
