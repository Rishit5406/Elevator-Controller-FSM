`timescale 1ns / 1ps

module tb_elevator_controller;

    reg clk;
    reg rst_n;
    reg [3:0] floor_request;
    reg door_obstruction;
    reg overload;
    reg emergency;

    wire motor_up;
    wire motor_down;
    wire door_open;
    wire door_close;
    wire alarm;
    wire [1:0] current_floor;
    wire [2:0] status;

    // Small timing values for faster simulation
    elevator_controller #(
        .MOVE_TIME(8'd5),
        .DOOR_TIME(8'd5)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .floor_request(floor_request),
        .door_obstruction(door_obstruction),
        .overload(overload),
        .emergency(emergency),
        .motor_up(motor_up),
        .motor_down(motor_down),
        .door_open(door_open),
        .door_close(door_close),
        .alarm(alarm),
        .current_floor(current_floor),
        .status(status)
    );

    // Clock generation: 10 ns time period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Display monitoring
    initial begin
        $monitor("Time=%0t | floor=%0d | req=%b | up=%b down=%b open=%b close=%b overload=%b emergency=%b status=%0d",
                 $time, current_floor, floor_request, motor_up, motor_down,
                 door_open, door_close, overload, emergency, status);
    end

    initial begin
        // Initial values
        rst_n = 0;
        floor_request = 4'b0000;
        door_obstruction = 0;
        overload = 0;
        emergency = 0;

        // Reset
        #20;
        rst_n = 1;

        // Request floor 2 from floor 0
        #10;
        floor_request = 4'b0100;
        #10;
        floor_request = 4'b0000;

        // Wait for lift to reach floor 2 and open/close door
        #200;

        // Request floor 3
        floor_request = 4'b1000;
        #10;
        floor_request = 4'b0000;

        #120;

        // Test door obstruction while closing
        door_obstruction = 1;
        #30;
        door_obstruction = 0;

        #100;

        // Test overload condition
        overload = 1;
        #50;
        overload = 0;

        #100;

        // Test emergency condition
        emergency = 1;
        #50;
        emergency = 0;

        #100;

        // Request floor 0 from current higher floor
        floor_request = 4'b0001;
        #10;
        floor_request = 4'b0000;

        #300;

        $finish;
    end

endmodule