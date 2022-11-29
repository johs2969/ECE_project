`timescale 1ns / 1ps
//10khz 기준
module traffic(rst, clk, hour_up, break,a,b,c, led_red, led_yellow, led_green, led_left, led_walk_red, led_walk_green,LCD_E,LCD_RS,LCD_RW,LCD_DATA );

input clk,rst,hour_up,break,a,b,c;
output reg [3:0] led_red, led_yellow, led_green, led_walk_red, led_walk_green, led_left;

reg [13:0] cnt_1h;
wire clk_flicker,hour_up_t,break_t;
reg [7:0] hour,min,sec;
integer cccnt;

reg [3:0] state,state3;
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
          
oneshot_universal #(.width(2)) uut(.clk(clk), .rst(rst), .btn({hour_up, break}), .btn_trig({hour_up_t,break_t}));
 //시간 계산 10khz기준 시간이 100배 빠르게 흐를것임. 대략 14분이면 하루가 돌게 된다.
 
 integer d=99;
always @(posedge clk or posedge rst) begin   
        if(rst) begin
        cccnt <=0;
        hour <=0;
        sec <=0;
        min <=0;
        end
    else if(hour_up_t && hour < 23) hour <= hour+1;// 버튼 누르면 강제로 1시간 증가. 원샷트리거로 작동.
    else if(hour_up_t && hour == 23) hour <= 0;// 버튼 누르면 강제로 1시간 증가. 원샷트리거로 작동
    else if (cccnt < d)  begin cccnt <= cccnt+1; //1clk마다 cccnt 증가, 실제1초가 내부시계0.01초인 셈. 실제시간의 100배
            d <= a? 9999 :(b? 999 : (c? 49: 99)); //a=실제시간의 1배, b= 실제시간의 10배, c=실제시간의 200배 dip 스위치를 사용할것이니, 꾹 누르지 않아도 됨(배율 유지가능)
            end
       else begin //cnt==99. 99밀리초->0밀리초 넘어갈 때
           cccnt <= 0;
         if (sec < 59) sec <= sec+1; //99+1밀리초마다 초 단위 증가.
          else begin //sec==59. 59초->0초 넘어갈 때
           sec <= 0;
         if (min < 59) min <= min+1; //59+1초마다 분 단위 증가.
          else begin //min==59. 59분->0분 넘어갈 때
           min <= 0;
          if (hour < 23) hour <= hour+1; //59분 59+1초마다 시간 단위 증가.
           else begin //hour==23. 23시->0시 넘어갈 때 
            hour <= 0;
            end //hour=23 
         end //min==59
      end //sec==59                   
  end //cnt==99
end         

//text LCD
wire [7:0] bcd1,bcd2,bcd3;

bin2bcd b1 (.clk(clk), .rst(rst), .bin(hour), .bcd(bcd1));
bin2bcd b11 (.clk(clk), .rst(rst), .bin(min), .bcd(bcd2));
bin2bcd b111 (.clk(clk), .rst(rst), .bin(sec), .bcd(bcd3));
      
output LCD_E;
output reg LCD_RS, LCD_RW;
output reg [7:0] LCD_DATA;

reg [3:0] state2 = 4'b0011;
parameter DELAY2 =4'b0011,
          FUNCTION_SET =4'b0100,
          ENTRY_MODE =4'b0101,
          DISP_ONOFF =4'b0110,
          LINE1 =4'b0111,
          LINE2 =4'b1000,
          DELAY_T =4'b1001;
          
 integer ccnt;               
          
always @(posedge clk or posedge rst)
begin
    if(rst) begin
        state2 <= DELAY2;
        ccnt <=0;
        end
    else
    begin
        case(state2)
        DELAY2 :begin
            if(ccnt >=700) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 700) state2 <= FUNCTION_SET;
        end
        FUNCTION_SET :begin
            if(ccnt >=30) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 30) state2 <= DISP_ONOFF;
        end
        DISP_ONOFF :begin
            if(ccnt >=30) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 30) state2 <= ENTRY_MODE;
        end
        ENTRY_MODE :begin
            if(ccnt >=30) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 30) state2 <= LINE1;
        end
        LINE1 :begin
            if(ccnt >=20) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 20) state2 <= LINE2;
           end
         LINE2 :begin
            if(ccnt >=20) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 20) state2 <= DELAY_T;
           end
        DELAY_T :begin
            if(ccnt >= 5) ccnt <= 0;
            else ccnt <= ccnt+1;
            if(ccnt == 5) state2 <= LINE1;
        end
        default : state2 <= DELAY2;
     endcase
  end
end
                              
always @(posedge clk or posedge rst)
begin
    if(rst)
        {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_00000000;
    else begin
        case(state2)
            FUNCTION_SET :
                {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_0011_1000;
            DISP_ONOFF :
                {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_0000_1100;
            ENTRY_MODE :
                {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_0000_0110;   
            LINE1 : begin
                case(ccnt)
                    00 : {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_1000_0000; //    
                    01 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0100; // T
                    02 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1001; // i
                    03 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1101; // m
                    04 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0101; // e
                    05 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // 
                    06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1010; // : 
                    07 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //   
                    08 : begin case(bcd1[7:4]) //10의 자릿수 입력 hour
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                        endcase
                        end                  
                    09 : begin case(bcd1[3:0]) //1의 자릿수 입력 hour
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                            6: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0110; // 6
                            7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0111; // 7
                            8: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1000; // 8
                            9: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1001; // 9
                        endcase
                        end 
                    10 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1010; // :                    
                    11 :begin case(bcd2[7:4]) //10의 자릿수 입력 min
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                        endcase
                        end
                    12 :begin case(bcd2[3:0]) //1의 자릿수 입력 min
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                            6: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0110; // 6
                            7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0111; // 7
                            8: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1000; // 8
                            9: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1001; // 9
                        endcase
                        end     
                      13 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1010; // :      
                      14 :begin case(bcd3[7:4]) //1의 자릿수 입력 sec
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                        endcase
                        end          
                      15 :begin case(bcd3[3:0]) //1의 자릿수 입력 sec
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                            6: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0110; // 6
                            7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0111; // 7
                            8: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1000; // 8
                            9: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1001; // 9
                        endcase
                        end                            
                    default : {LCD_RS, LCD_RW, LCD_DATA} <=10'b1_0_0010_0000; // 
                 endcase
              end
               LINE2 : begin
                case(ccnt)
                    00 : {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_1100_0000; //    
                    01 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0011; // S
                    02 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_0100; // t
                    03 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0001; // a
                    04 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_0100; // t
                    05 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0101; // e
                    06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //  
                    07 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1010; // :  
                    08 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //  
                    09 : begin case(state) // state입력
                           A1,A2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0001; // A
                            B: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0010; // B
                            C: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0011; // C
                            D: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0100; // D
                          E1,E2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0101; // E
                            F: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0110; // F
                            G: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0111; // G
                            H: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1000; // H
                        endcase
                        end                  
                    10 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_1000; // (                   
                    11 :begin case(hour) //시간으로 주/야간 판단
                            8,9,10,11,12,13,14,15,16,17,18,19,20,21,22: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //
                            23,0,1,2,3,4,5,6,7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1110; // n
                        endcase
                        end
                    12 :begin case(hour) //시간으로 주/야간 판단
                            8,9,10,11,12,13,14,15,16,17,18,19,20,21,22: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0100; // d
                            23,0,1,2,3,4,5,6,7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1001; // i
                        endcase
                        end
                     13 :begin case(hour) //시간으로 주/야간 판단
                            8,9,10,11,12,13,14,15,16,17,18,19,20,21,22: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0001; // a
                            23,0,1,2,3,4,5,6,7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0111; // g
                        endcase
                        end     
                     14 :begin case(hour) //시간으로 주/야간 판단
                            8,9,10,11,12,13,14,15,16,17,18,19,20,21,22: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_1001; // y
                            23,0,1,2,3,4,5,6,7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1000; // h
                        endcase
                        end    
                     15 :begin case(hour) //시간으로 주/야간 판단
                            8,9,10,11,12,13,14,15,16,17,18,19,20,21,22: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //
                            23,0,1,2,3,4,5,6,7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_0100; // t
                        endcase
                        end 
                     16 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_1001; // )                         
                    default : {LCD_RS, LCD_RW, LCD_DATA} <=10'b1_0_0010_0000; // 
                 endcase
              end
            DELAY_T :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0010;
            default :
                {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_0000_0000;              
          endcase
      end
  end
  
  assign LCD_E = clk;               

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

// state 변경 

integer cnt;
reg [31:0] hold_t=0;
reg x=0;


always @(posedge clk or posedge rst) begin
    if(rst) begin 
        state <= A1;
        cnt <=0;
        end
    else if(break_t || x) begin // 신호등 수동조작, 긴급차량 발생, 
        hold_t<= 150000;
        state <= (cnt >= 160000) ? state3 : ((cnt >= 10000 && x==1) ? A1 : state3 ); //1초 흐르고 A1으로 전환, 그리고 STATE가 끝나면 원래 STATE로 돌아감.
        if(cnt >= 160000)  cnt <=0;
            else cnt <= (x==0)? 0: cnt+1; // cnt 가 처음에 들어올때 0으로 초기화 되어야함. 
        x <= (cnt >= 160000) ? 0:1;  // 처음에 break_t신호가 들어오면 x=1이 되면서 수동조작 상태가 유지된다. 그러다가 cnt=150000 15초가 지나면, x=0이되면서 수동조작 상태가 꺼지고 주,야간으로 되돌아간다.
        end
    else if(hour >= 8 && hour < 23) begin// 5초 유지시간 주간 case
        hold_t<= 50000;
        state3 <=state;
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
    else if(hour < 8 || hour == 23) begin // 10초 유지시간으로 변경해준다 야간 case    
         hold_t<= 100000;
         state3 <=state;
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
                if(cnt <= hold_t/2) begin
                    led_red <=4'b0011;
                    led_green <=4'b1100;
                    led_yellow <=4'b0000;
                    led_left <=4'b0000;   
                  end 
                 else if(cnt > hold_t/2) begin
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
                if(cnt <= hold_t/2) begin
                    led_red <=4'b1011;
                    led_green <=4'b0100;
                    led_yellow <=4'b0000;
                    led_left <=4'b0100;   
                  end 
                 else if(cnt > hold_t/2) begin 
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
                if(cnt <= hold_t/2) begin
                    led_red <=4'b0111;
                    led_green <=4'b1000;
                    led_yellow <=4'b0000;
                    led_left <=4'b1000;   
                  end 
                 else if(cnt > hold_t/2) begin 
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
                if(cnt <= hold_t/2) begin
                    led_red <=4'b0011;
                    led_green <=4'b0000;
                    led_yellow <=4'b0000;
                    led_left <=4'b1100;   
                  end 
                 else if(cnt > hold_t/2) begin 
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
                if(cnt <= hold_t/2) begin
                    led_red <=4'b1100;
                    led_green <=4'b0011;
                    led_yellow <=4'b0000;
                    led_left <=4'b0000;   
                  end 
                 else if(cnt > hold_t/2) begin 
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
                if(cnt <= hold_t/2) begin
                    led_red <=4'b1101;
                    led_green <=4'b0010;
                    led_yellow <=4'b0000;
                    led_left <=4'b0010;   
                  end 
                 else if(cnt > hold_t/2) begin 
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
                if(cnt <= hold_t/2) begin
                    led_red <=4'b1110;
                    led_green <=4'b0001;
                    led_yellow <=4'b0000;
                    led_left <=4'b0001;   
                  end 
                 else if(cnt > hold_t/2) begin 
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
                if(cnt <= hold_t/2) begin
                    led_red <=4'b1100;
                    led_green <=4'b0000;
                    led_yellow <=4'b0000;
                    led_left <=4'b0011;   
                  end 
                 else if(cnt > hold_t/2) begin 
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
