`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/06/2021 12:10:30 PM
// Design Name: 
// Module Name: descriptor_tb
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
import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;


module descriptor_tb( );

bit aclk = 0;
bit aresetn = 0;
bit axi_error=0;
bit axi_txn_done=0;
logic[7:0] count_out;

xil_axi_ulong base_reg=32'h40000000; //slv_reg0 is base reg enable bit is LSB, reg increment/decrement setting is bit 1
xil_axi_ulong init_txn_reg = 32'h40000008; //reg for initiate txn of read or write. slv_reg2 is 8 away from base
xil_axi_ulong bram_reg=32'h00000204;//address to write directly into memory bram
xil_axi_ulong bram_count_out_reg=32'h00000200;//address that DUT write count value into memory bram
xil_axi_prot_t prot = 0;
xil_axi_resp_t resp;

//data to set settings
bit[31:0] enable_data = 32'h00000001; //bit 0 is tied to enable. high will enable. this data will also set inc/dec to increment (0001)
bit[31:0] disable_data=32'h00000000;//disable the enable and inc/dec set back to increment (0010)
bit[31:0] init_read_data=32'h00000002;// bit 1 of slv reg 2 will initiate the read txn

//test data
bit[31:0] test_data1 = 32'h000001C0; 
bit[31:0] test_data2 = 32'h000000AF;

bit[31:0] sanity_data;

design_1_wrapper DUT(
     .aclk_0(aclk),
    .aresetn_0(aresetn),
    .count_out_0(count_out),
    .m00_axi_error_0(axi_error),
    .m00_axi_txn_done_0(axi_txn_done));

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
    
    //write and then read start value to BRAM
     #200
    master_agent.AXI4LITE_WRITE_BURST(bram_reg, prot, test_data2, resp); //write start value to bram 204 addr. start value AF, inc mode
    #250
    
    //read start value before the enable
    master_agent.AXI4LITE_WRITE_BURST(init_txn_reg, prot, init_read_data, resp); //initiate a read data transaction so it will be in rdata from bram 204
    
    //enable
    #200
    master_agent.AXI4LITE_WRITE_BURST(base_reg, prot, enable_data, resp); //write to enable. 
  
    //initiate master to send count to bram    
    #500
    #500
    #200
    master_agent.AXI4LITE_WRITE_BURST(init_txn_reg, prot, enable_data, resp); //write data 01 into init_txn register to start master write txn. will write current count value to addr 200 of bram
 
    //disable counter 
    #50
     master_agent.AXI4LITE_WRITE_BURST(base_reg, prot, disable_data, resp); //disable.
     
    //read the bram count value
    #50
    master_agent.AXI4LITE_READ_BURST(bram_count_out_reg, prot, sanity_data, resp); //read count value that was sent to bram 200
    
    //write start value to BRAM
     #200
    master_agent.AXI4LITE_WRITE_BURST(bram_reg, prot, test_data1, resp); //write start value to bram 204 addr. start value C0 dec mode
    //#200
    //master_agent.AXI4LITE_READ_BURST(bram_reg, prot, sanity_data, resp); //read from bram will read from 204 
    #250
    
    //read start value before the enable
    master_agent.AXI4LITE_WRITE_BURST(init_txn_reg, prot, init_read_data, resp); //initiate a read data transaction so it will be in rdata from bram 204
    
    //enable
   #200
    master_agent.AXI4LITE_WRITE_BURST(base_reg, prot, enable_data, resp); //write to enable. 
    
    //disable counter 
    #50
     master_agent.AXI4LITE_WRITE_BURST(base_reg, prot, disable_data, resp); //disable.
    end


endmodule
