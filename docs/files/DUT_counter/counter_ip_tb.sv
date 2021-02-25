`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/17/2021 09:31:31 PM
// Design Name: 
// Module Name: counter_ip_tb
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

//import necessary packages
import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;

module counter_ip_tb();

bit aclk = 0;
bit aresetn = 0;
logic[7:0] count_out;

xil_axi_ulong base_reg=32'h44A00000; //slv_reg0 is base reg enable bit is LSB, reg increment/decrement setting is bit 1
xil_axi_ulong start_value_reg = 32'h44A00004; //reg for start value. slv_reg1 is 4 away from base
xil_axi_ulong sanity_check_reg = 32'h44A000C; //sanity check reg. slv_reg3 which is 12 away from base reg
xil_axi_prot_t prot = 0;
xil_axi_resp_t resp;
//data to set settings
bit[31:0] enable_data = 32'h00000001; //bit 0 is tied to enable. high will enable. this data will also set inc/dec to increment (0001)
bit[31:0] disable_data=32'h00000000;//disable the enable and inc/dec set back to increment (0010)
bit[31:0] inc_dec =32'h00000003;//bit 1 is tied to inc/dec. high is decrement. this will set decrement and enable (0011)
//test data
bit[31:0] test_data1 = 32'h000000C0; 
bit[31:0] test_data2 = 32'h000000AF;
bit[31:0] test_data3 = 32'h00000011;
bit[31:0] sanity_data;

//instantiate block design//
design_1_wrapper DUT(
.aclk_0(aclk),
.aresetn_0(aresetn),
.count_out_0(count_out)
);

//initialize AXI Master Agent
//create master agent vip
    design_1_axi_vip_0_0_mst_t      master_agent;
    
    always begin
    #5
    aclk=~aclk;//100mhz clk
    end
  //create agent and start
    initial begin 
    master_agent=new("master vip agent",DUT.design_1_i.axi_vip_0.inst.IF); 
    master_agent.start_master();
    
    #100
    aresetn = 1; //turn off reset
    
    //enable
    #50
    master_agent.AXI4LITE_WRITE_BURST(base_reg, prot, enable_data, resp); //write to enable. increment mode
    
    //test read and write
    #100
    master_agent.AXI4LITE_WRITE_BURST(start_value_reg, prot, test_data1, resp); //write data c0 into start value register
    #50
    master_agent.AXI4LITE_READ_BURST(start_value_reg, prot, sanity_data, resp); //read start value reg
    #100
    master_agent.AXI4LITE_WRITE_BURST(start_value_reg, prot, test_data2, resp); //write data2 AF into start reg. still increment mode
  
  //test enable/disable
     #50
     master_agent.AXI4LITE_WRITE_BURST(base_reg, prot, disable_data, resp); //disable. increment mode
     #50
    master_agent.AXI4LITE_WRITE_BURST(base_reg, prot, enable_data, resp); //write to enable. increment mode
    
    //test decrement
    #100
    master_agent.AXI4LITE_WRITE_BURST(base_reg, prot, inc_dec, resp); //write to change to decrement mode
    #100
    master_agent.AXI4LITE_WRITE_BURST(start_value_reg, prot, test_data3, resp); //write data3 11 into start value
    
    //sanity check
    #100
    master_agent.AXI4LITE_READ_BURST(sanity_check_reg, prot, sanity_data, resp); //read sanity check register. should be abcd1234
    
    //test reset
    #100
    aresetn=0;//enable reset
    #100
    aresetn=1;//turn off reset
    
    //enable and read start reg, should be 0 after reset
    #100
    master_agent.AXI4LITE_WRITE_BURST(base_reg, prot, enable_data, resp); //write to enable. increment mode
    #100
    master_agent.AXI4LITE_READ_BURST(start_value_reg, prot, sanity_data, resp); //read start value register
   
    end
    
endmodule
