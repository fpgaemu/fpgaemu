`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2021 01:06:35 PM
// Design Name: 
// Module Name: counter_tb
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


module counter_tb();
//create necessary variables
reg aclk; 
reg enable;
reg aresetn;
reg inc_dec;
reg [7:0]start_value;
wire[7:0] count_out;

//create DUT
counter DUT(
.aclk(aclk),
.enable(enable),
.aresetn(aresetn),
.inc_dec(inc_dec),
.start_value (start_value),
.count_out(count_out)
);

//define clk
always begin
    #5 //delay 5ns
    aclk=~aclk;//should be a 100MHz clk
end

initial begin
//will turn in after 100ns and start inc from af for 100ns
//then reset and new start value at c0 will increment for 50
//disbale for 50ns
//enable again and then decrement
    aresetn=0;//turn on reset
    enable=0;//not enabled
    aclk=0;
    start_value=8'haf;//set a start value
    inc_dec=0;//will increment
    
    #100 //100ns delay
    aresetn=1;//turn off reset
    #20
    enable=1;//turn on enable
    
    #100
    aresetn=0;
    start_value=8'hc0;//new start value
    aresetn=1; //lift the reset
    #50
    enable=0;
    #50ns
    enable=1;
    inc_dec=1;
  end
    
    
endmodule
