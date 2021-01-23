`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Capstone Project Qualcomm FPGA Emu
// Engineer: Haley Guastaferro
// 
// Create Date: 01/14/2021 12:41:26 PM
// Design Name: 
// Module Name: counter
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

//parameters
module counter( 
    input aclk,
    input enable, //will enable or disable count
    input aresetn, //will reset count back to start value
    input inc_dec, //will indicate wheather increment count or decrement count. inc count is 0, dec count is 1
    input [7:0] start_value, //value to start counting from
    output reg [7:0] count_out //count value
    );
  
  //local registers  
    reg [7:0] count_next;//next count value
    reg [7:0]prev_start_value=start_value;
    
    always @(posedge aclk)
        begin
            if(aresetn ==0 || prev_start_value!=start_value)//reset mode or new start value
                   begin
                    count_out =start_value;//reset count out to start value
                    prev_start_value=start_value;//set prev start value to start value
                   end 
            else //reset=1, no reset
                begin
                    if(enable==1) //enable is high a
                         begin
                            if(inc_dec==0) begin//and incdec is low
                                count_next=count_out+1; //increment next value
                                end 
                                else begin //inc_dec is high
                                count_next=count_out-1;// decrement next value
                                end
                            count_out=count_next;// set output equal to next value
                            end
                    else count_out=count_out;//same value if no enable
                    end
                end                
endmodule
