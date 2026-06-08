`timescale 1ns / 1ps

module elevator_controller #(
    parameter MOVE_TIME=8'd20, 
    parameter DOOR_TIME=8'd30
)(
    input wire clk, 
    input wire rst_n, 
    input wire [3:0]floor_request, 
    input wire door_obstruction, 
    input wire overload, 
    input wire emergency, 
    output reg motor_up, 
    output reg motor_down, 
    output reg door_open, 
    output reg door_close, 
    output reg alarm, 
    output reg [1:0] current_floor, 
    output reg [2:0] status
    );
    localparam LIFT_IDLE = 4'd0; 
    localparam CHECK_REQUEST = 4'd1;
    localparam MOVE_UP = 4'd2;
    localparam ARRIVED = 4'd3;
    localparam MOVE_DOWN = 4'd4;
    localparam DOOR_OPEN = 4'd5;
    localparam DOOR_WAIT = 4'd6;
    localparam DOOR_CLOSE = 4'd7;
    localparam OVERLOAD = 4'd8;
    localparam EMERGENCY = 4'd9;
    
    reg [3:0] state;
    reg [3:0] request_reg; 
    reg [7:0] timer; 
    reg direction_up; 
    
    wire request_here, request_up, request_down; 
    
    assign request_here = request_reg[current_floor]; 
    assign request_up = ((current_floor < 2'd3) && request_reg[3]) || ((current_floor < 2'd2) && request_reg[2]) || ((current_floor < 2'd1) && request_reg[1]);
assign request_down = ((current_floor > 2'd2) && request_reg[2]) ||
                      ((current_floor > 2'd1) && request_reg[1]) ||
                      ((current_floor > 2'd0) && request_reg[0]);    
    always @(*) begin  
        motor_up = 1'b0; 
        motor_down = 1'b0;
        door_open = 1'b0;
        door_close = 1'b0;
        alarm = 1'b0;
        status = state[2:0]; 
        
        case (state) 
            MOVE_UP: motor_up=1'b1; 
            MOVE_DOWN: motor_down=1'b1;
            DOOR_OPEN: door_open=1'b1;
            DOOR_WAIT: door_open=1'b1;
            DOOR_CLOSE: door_close=1'b1;
            OVERLOAD: door_open=1'b1;
            EMERGENCY: door_open=1'b1;
        endcase
    end
    always @(posedge clk) begin 
    if(!rst_n) begin 
        state <= LIFT_IDLE; 
        request_reg<=4'b0000;
        timer <=8'b0; 
        current_floor <=2'd0;
        direction_up <=1'b1; 
    end
    else begin 
        request_reg<=request_reg|floor_request; 
        if (emergency) begin 
            state<=EMERGENCY; 
            timer <=8'd0; 
        end    
        else if (overload) begin 
            state<=OVERLOAD;
            timer<=8'd0;
        end
        else begin 
            case (state) 
                LIFT_IDLE: begin 
                    timer<=8'd0;
                    if (request_reg != 4'b0000)
                        state<= CHECK_REQUEST;
                end
                CHECK_REQUEST: begin 
                    if (request_here) state<=DOOR_OPEN;
                    else if (request_up) begin 
                        direction_up<=1'b1; 
                        state<=MOVE_UP;
                        end
                    else if (request_down) begin 
                        direction_up<=1'b0;
                        state<=MOVE_DOWN;
                    end
                    else state<=LIFT_IDLE; 
                end
                MOVE_UP: begin 
                if (timer == MOVE_TIME) begin 
                    timer<=8'd0;
                    if (current_floor<2'd3) current_floor<=current_floor+2'd1; 
                    state<=ARRIVED;
                    end
                    else timer<=timer+8'd1; 
                end
                MOVE_DOWN: begin 
                if (timer == MOVE_TIME) begin 
                    timer<=8'd0;
                    if (current_floor>2'd0) current_floor<=current_floor-2'd1; 
                    state<=ARRIVED;
                    end
                    else timer<=timer+8'd1; 
                end
                ARRIVED: begin 
                if(request_reg[current_floor]) state<=DOOR_OPEN; 
                else state<=CHECK_REQUEST; 
                end
                DOOR_OPEN: begin 
                    timer <= 8'd0;
                    request_reg[current_floor] <= 1'b0;
                    state <= DOOR_WAIT; 
                end
                DOOR_WAIT: begin 
                    if (timer==DOOR_TIME) begin 
                        timer <= 8'd0; 
                        state<= DOOR_CLOSE;
                    end
                    else timer<=timer+8'd1; 
                end
                DOOR_CLOSE: begin 
                    if (door_obstruction) begin 
                        state<= DOOR_OPEN; 
                    end else begin 
                        state<=CHECK_REQUEST; 
                    end
                end
                OVERLOAD: begin 
                    if (!overload) state<= CHECK_REQUEST;
                end
                EMERGENCY: begin 
                    if(!emergency) state<= CHECK_REQUEST; 
                end
            endcase            
        end        
    end
    end
endmodule
