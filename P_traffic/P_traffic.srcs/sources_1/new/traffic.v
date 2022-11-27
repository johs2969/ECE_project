`timescale 1ns / 1ps
//10khz ����
module traffic(rst, clk, hour_up, break, led_red, led_yellow, led_green, led_left, led_walk_red, led_walk_green,LCD_E,LCD_RS,LCD_RW,LCD_DATA );

input clk,rst,hour_up,break;
output reg [3:0] led_red, led_yellow, led_green, led_walk_red, led_walk_green, led_left;

reg [13:0] cnt_1h;
wire clk_flicker,hour_up_t,break_t;
reg [7:0] hour,min,sec;
integer cccnt;

oneshot_universal #(.width(2)) uut(.clk(clk), .rst(rst), .btn({hour_up, break}), .btn_trig({hour_up_t,break_t}));
 //�ð� ��� 10khz���� �ð��� 100�� ������ �带����. �뷫 14���̸� �Ϸ簡 ���� �ȴ�.
 
always @(posedge clk or posedge rst) begin   
        if(rst) begin
        cccnt <=0;
        hour <=0;
        sec <=0;
        min <=0;
        end
    else if(hour_up_t) hour <= hour+1;// ��ư ������ ������ 1�ð� ����. ����Ʈ���ŷ� �۵�.
        else if (cccnt < 99)  cccnt <= cccnt+1; //1clk���� cccnt ����, ����1�ʰ� ���νð�0.01���� ��. 
       else begin //cnt==99. 99�и���->0�и��� �Ѿ ��
           cccnt <= 0;
         if (sec < 59) sec <= sec+1; //99+1�и��ʸ��� �� ���� ����.
          else begin //sec==59. 59��->0�� �Ѿ ��
           sec <= 0;
         if (min < 59) min <= min+1; //59+1�ʸ��� �� ���� ����.
          else begin //min==59. 59��->0�� �Ѿ ��
           min <= 0;
          if (hour < 23) hour <= hour+1; //59�� 59+1�ʸ��� �ð� ���� ����.
           else begin //hour==23. 23��->0�� �Ѿ �� 
            hour <= 0;
            end //hour=23 
         end //min==59
      end //sec==59                   
  end //cnt==99
end

//text LCD
wire [11:0] bcd1,bcd2,bcd3;

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
                    08 : begin case(bcd1[7:4]) //10�� �ڸ��� �Է� hour
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                        endcase
                        end                  
                    09 : begin case(bcd1[3:0]) //1�� �ڸ��� �Է� hour
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
                    11 :begin case(bcd2[7:4]) //10�� �ڸ��� �Է� min
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                        endcase
                        end
                    12 :begin case(bcd2[3:0]) //1�� �ڸ��� �Է� min
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
                      14 :begin case(bcd3[7:4]) //1�� �ڸ��� �Է� sec
                            0: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
                            1: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
                            2: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // 2
                            3: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // 3
                            4: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // 4
                            5: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0101; // 5
                        endcase
                        end          
                      15 :begin case(bcd3[3:0]) //1�� �ڸ��� �Է� sec
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
                    00 : {LCD_RS, LCD_RW, LCD_DATA} <=10'b0_0_1000_0000; //    
                    01 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0011; // S
                    02 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_0100; // t
                    03 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0001; // a
                    04 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_0100; // t
                    05 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0101; // e
                    06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //  
                    07 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1010; // :  
                    06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //  
                    08 : begin case(state) // state�Է�
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
                    09 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //
                    10 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_1000; // (                   
                    11 :begin case(hour) //�ð����� ��/�߰� �Ǵ�
                            8,9,10,11,12,13,14,15,16,17,18,19,20,21,22: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; //
                            23,0,1,2,3,4,5,6,7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1110; // n
                        endcase
                        end
                    12 :begin case(hour) //�ð����� ��/�߰� �Ǵ�
                            8,9,10,11,12,13,14,15,16,17,18,19,20,21,22: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0100; // d
                            23,0,1,2,3,4,5,6,7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1001; // i
                        endcase
                        end
                     13 :begin case(hour) //�ð����� ��/�߰� �Ǵ�
                            8,9,10,11,12,13,14,15,16,17,18,19,20,21,22: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0001; // a
                            23,0,1,2,3,4,5,6,7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_0111; // g
                        endcase
                        end     
                     14 :begin case(hour) //�ð����� ��/�߰� �Ǵ�
                            8,9,10,11,12,13,14,15,16,17,18,19,20,21,22: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0111_1001; // y
                            23,0,1,2,3,4,5,6,7: {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0110_1000; // h
                        endcase
                        end    
                     15 :begin case(hour) //�ð����� ��/�߰� �Ǵ�
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

// �����ȣ 10khz �������� 0.5�ʸ��� flicker�� �ٲ�� �����Ѵ�.

always @(posedge clk or posedge rst) begin
    if(rst) 
        cnt_1h <= 0;
    else if(cnt_1h >=9999)
        cnt_1h <=0;
     else
     cnt_1h <= cnt_1h +1;
end

assign clk_flicker = (cnt_1h >=4999) ? 0:1;            

// state ���� 

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
reg x=0;


always @(posedge clk or posedge rst) begin
    if(rst) begin 
        state <= A1;
        cnt <=0;
        end
    else if(break_t || x) begin // ��ȣ�� ��������, ������� �߻�, 
        hold_t<= 150000;
        if(cnt >= 10000 && x==1) state <= A1; // 1�� �帣�� state A�� ��ȯ
        if(cnt >= 160000) cnt <=0;
            else cnt <= (x==0)? 0: cnt+1; // cnt �� ó���� ���ö� 0���� �ʱ�ȭ �Ǿ����. 
        x <= (cnt >= 160000) ? 0:1;  // ó���� break_t��ȣ�� ������ x=1�� �Ǹ鼭 �������� ���°� �����ȴ�. �׷��ٰ� cnt=150000 15�ʰ� ������, x=0�̵Ǹ鼭 �������� ���°� ������ ��,�߰����� �ǵ��ư���.
        end
    else if(hour >= 8 && hour < 23) begin// 5�� �����ð� �ְ� case
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
    else if(hour < 8 || hour == 23) begin // 10�� �����ð����� �������ش� �߰� case    
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

// state�� ��ȣ�� 

always @(posedge clk or posedge rst) begin
    if(rst) begin
        led_red <=4'b0000;
        led_green <=4'b0000;
        led_yellow <=4'b0000;
        led_walk_red <=4'b0000;
        led_walk_green <=4'b0000;
        end
    else
        case(state)// ��.��, ��,,�� �����̴�.
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
             B: begin // ��.��, ��,,�� �����̴�.
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
             C: begin // ��.��, ��,,�� �����̴�.
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
              D: begin // ��.��, ��,,�� �����̴�.
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
              E1,E2: begin // ��.��, ��,,�� �����̴�.
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
              F: begin // ��.��, ��,,�� �����̴�.
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
               G: begin // ��.��, ��,,�� �����̴�.
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
              H: begin // ��.��, ��,,�� �����̴�.
                if((cnt <= (5/6)*hold_t)) begin
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
