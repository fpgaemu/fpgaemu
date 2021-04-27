//-----------------------------------------------------------------------------
//
// (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : AXI Memory Mapped Bridge to PCI Express
// File       : xilinx_axi_pcie_ep.v
// Version    : 2.8
//-----------------------------------------------------------------------------
// Project    : AXI PCIe example design
// File       : xilinx_axi_pcie_ep.v
// Version    : 2.2 
// Description : Top-level example file
//
// Hierarchy   : consists of axi_pcie_0_support & axi_pcie_0 if both EXT_CLK< EXT_GT_COOMON are FALSE & axi_bram_ctrl_0
//               |--xilinx_axi_pcie_ep
//                  |
//                  |--axi_bram_cntrl
//                  |--axi_pcie_0 if PCIE_EXT_CLK & PCIE_EXT_GT_COMMON are FALSE
//						|
//						|--axi_pcie (axi pcie design)
//							|
//							|--<various>
//		    |--axi_pcie_0_support If either of or both PCIE_EXT_CLK & PCIE_EXT_GT_COMMON are TRUE
//						|
//						|--ext_pipe_clk(external pipe clock)
//						|--ext_gt_common(external gt common)
//						|--axi_pcie_0
//							|
//							|--axi_pcie (axi pcie design)
//								|
//								|--<various>
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ns

module xilinx_axi_pcie_ep  #(
  parameter PL_FAST_TRAIN       = "FALSE", // Simulation Speedup
  parameter PCIE_EXT_CLK        = "FALSE",  // Use External Clocking Module
  parameter EXT_PIPE_SIM        = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.	
  parameter PCIE_EXT_GT_COMMON  = "FALSE",
  parameter REF_CLK_FREQ        = 0,
  parameter C_DATA_WIDTH        = 128, // RX/TX interface data width
  parameter KEEP_WIDTH          = C_DATA_WIDTH / 8,
  
  //INSERT PARAMETERS FOR MIG
  //***************************************************************************
   // Traffic Gen related parameters
   //***************************************************************************
   parameter BEGIN_ADDRESS         = 32'h00000000,
   parameter END_ADDRESS           = 32'h00ffffff,
   parameter PRBS_EADDR_MASK_POS   = 32'hff000000,
   parameter ENFORCE_RD_WR         = 0,
   parameter ENFORCE_RD_WR_CMD     = 8'h11,
   parameter ENFORCE_RD_WR_PATTERN = 3'b000,
   parameter C_EN_WRAP_TRANS       = 0,
   parameter C_AXI_NBURST_TEST     = 0,

   //***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
   parameter CK_WIDTH              = 1,
                                     // # of CK/CK# outputs to memory.
   parameter nCS_PER_RANK          = 1,
                                     // # of unique CS outputs per rank for phy
   parameter CKE_WIDTH             = 1,
                                     // # of CKE outputs to memory.
   parameter DM_WIDTH              = 8,
                                     // # of DM (data mask)
   parameter ODT_WIDTH             = 1,
                                     // # of ODT outputs to memory.
   parameter BANK_WIDTH            = 3,
                                     // # of memory Bank Address bits.
   parameter COL_WIDTH             = 10,
                                     // # of memory Column Address bits.
   parameter CS_WIDTH              = 1,
                                     // # of unique CS outputs to memory.
   parameter DQ_WIDTH              = 64,
                                     // # of DQ (data)
   parameter DQS_WIDTH             = 8,
   parameter DQS_CNT_WIDTH         = 3,
                                     // = ceil(log2(DQS_WIDTH))
   parameter DRAM_WIDTH            = 8,
                                     // # of DQ per DQS
   parameter ECC                   = "OFF",
   parameter ECC_TEST              = "OFF",
   //parameter nBANK_MACHS           = 4,
   parameter nBANK_MACHS           = 4,
   parameter RANKS                 = 1,
                                     // # of Ranks.
   parameter ROW_WIDTH             = 14,
                                     // # of memory Row Address bits.
   parameter ADDR_WIDTH            = 28,
                                     // # = RANK_WIDTH + BANK_WIDTH

                                     //     + ROW_WIDTH + COL_WIDTH;

                                     // Chip Select is always tied to low for
                                     // single rank devices
   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   parameter BURST_MODE            = "8",
                                     // DDR3 SDRAM:
                                     // Burst Length (Mode Register 0).
                                     // # = "8", "4", "OTF".
                                     // DDR2 SDRAM:
                                     // Burst Length (Mode Register).
                                     // # = "8", "4".
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   parameter CLKIN_PERIOD          = 5000,
                                     // Input Clock Period
   parameter CLKFBOUT_MULT         = 4,
                                     // write PLL VCO multiplier
   parameter DIVCLK_DIVIDE         = 1,
                                     // write PLL VCO divisor
   parameter CLKOUT0_PHASE         = 315.0,
                                     // Phase for PLL output clock (CLKOUT0)
   parameter CLKOUT0_DIVIDE        = 1,
                                     // VCO output divisor for PLL output clock (CLKOUT0)
   parameter CLKOUT1_DIVIDE        = 2,
                                     // VCO output divisor for PLL output clock (CLKOUT1)
   parameter CLKOUT2_DIVIDE        = 32,
                                     // VCO output divisor for PLL output clock (CLKOUT2)
   parameter CLKOUT3_DIVIDE        = 8,
                                     // VCO output divisor for PLL output clock (CLKOUT3)
   parameter MMCM_VCO              = 800,
                                     // Max Freq (MHz) of MMCM VCO
   parameter MMCM_MULT_F           = 8,
                                     // write MMCM VCO multiplier
   parameter MMCM_DIVCLK_DIVIDE    = 1,
                                     // write MMCM VCO divisor
   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   parameter SIMULATION            = "FALSE",
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementation
   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter TCQ_MIG                   = 100, //change to TCQ_MIG
   parameter DRAM_TYPE             = "DDR3",
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   parameter nCK_PER_CLK           = 4,
                                     // # of memory CKs per fabric CLK
   //**************************************************************************
   // AXI4 Shim parameters
   //***************************************************************************
   parameter C_S_AXI_ID_WIDTH              = 1,
                                             // Width of all master and slave ID signals.
                                             // # = >= 1.
   parameter C_S_AXI_ADDR_WIDTH            = 30,
                                             // Width of S_AXI_AWADDR, S_AXI_ARADDR, M_AXI_AWADDR and
                                             // M_AXI_ARADDR for all SI/MI slots.
                                             // # = 32.
   parameter C_S_AXI_DATA_WIDTH            = 64,
                                             // Width of WDATA and RDATA on SI slot.
                                             // Must be <= APP_DATA_WIDTH.
                                             // # = 32, 64, 128, 256.
   parameter C_S_AXI_SUPPORTS_NARROW_BURST = 0,
                                             // Indicates whether to instatiate upsizer
                                             // Range: 0, 1
   //***************************************************************************
   // Debug parameters
   //***************************************************************************
   parameter DEBUG_PORT            = "OFF",
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls
   parameter RST_ACT_LOW           = 1
                                     // =1 for active low reset,
                                     // =0 for active high.
) (

  output  [7:0]    pci_exp_txp,
  output  [7:0]    pci_exp_txn,
  input   [7:0]    pci_exp_rxp,
  input   [7:0]    pci_exp_rxn,


    // synthesis translate_off
  //----------------------------------------------------------------------------------------------------------------//
  // PIPE PORTS to TOP Level For PIPE SIMULATION with 3rd Party IP/BFM/Xilinx BFM
  //----------------------------------------------------------------------------------------------------------------//
    input wire   [11:0]  common_commands_in,
    input wire   [24:0]  pipe_rx_0_sigs,
    input wire   [24:0]  pipe_rx_1_sigs,
    input wire   [24:0]  pipe_rx_2_sigs,
    input wire   [24:0]  pipe_rx_3_sigs,
    input wire   [24:0]  pipe_rx_4_sigs,
    input wire   [24:0]  pipe_rx_5_sigs,
    input wire   [24:0]  pipe_rx_6_sigs,
    input wire   [24:0]  pipe_rx_7_sigs,

    output wire  [11:0]  common_commands_out,
    output wire  [24:0]  pipe_tx_0_sigs,
    output wire  [24:0]  pipe_tx_1_sigs,
    output wire  [24:0]  pipe_tx_2_sigs,
    output wire  [24:0]  pipe_tx_3_sigs,
    output wire  [24:0]  pipe_tx_4_sigs,
    output wire  [24:0]  pipe_tx_5_sigs,
    output wire  [24:0]  pipe_tx_6_sigs,
    output wire  [24:0]  pipe_tx_7_sigs,
    // synthesis translate_on


  input                  sys_clk_p,
  input                  sys_clk_n,
  input                  sys_rst_n,
  
  //INSERT INPUTS/OUTPUTS FROM MIG
   // Inouts
   inout [63:0]                         ddr3_dq,
   inout [7:0]                        ddr3_dqs_n,
   inout [7:0]                        ddr3_dqs_p,
   // Outputs
   output [13:0]                       ddr3_addr,
   output [2:0]                      ddr3_ba,
   output                                       ddr3_ras_n,
   output                                       ddr3_cas_n,
   output                                       ddr3_we_n,
   output                                       ddr3_reset_n,
   output [0:0]                        ddr3_ck_p,
   output [0:0]                        ddr3_ck_n,
   output [0:0]                       ddr3_cke,
   output [0:0]           ddr3_cs_n,
   output [7:0]                        ddr3_dm,
   output [0:0]                       ddr3_odt,

   // Inputs
   // Differential system clocks
   input                                        sys_clk_p_mig, //change these
   input                                        sys_clk_n_mig,
   output                                       tg_compare_error,
   output                                       init_calib_complete,

   // System reset - Default polarity of sys_rst pin is Active Low.
   // System reset polarity will change based on the option 
   // selected in GUI.
   input                                        sys_rst,
   
   output [7:0]                                 count_out //insert output from custom counter IP
   
);

//INSERT FUNCTIONS AND LOCALPARAMS FROM MIG FILE
function integer clogb2 (input integer size);
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
  endfunction // clogb2

  function integer STR_TO_INT;
    input [7:0] in;
    begin
      if(in == "8")
        STR_TO_INT = 8;
      else if(in == "4")
        STR_TO_INT = 4;
      else
        STR_TO_INT = 0;
    end
  endfunction

  localparam DATA_WIDTH            = 64;
  localparam RANK_WIDTH = clogb2(RANKS);
  localparam PAYLOAD_WIDTH         = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;
  localparam BURST_LENGTH          = STR_TO_INT(BURST_MODE);
  localparam APP_DATA_WIDTH        = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  localparam APP_MASK_WIDTH        = APP_DATA_WIDTH / 8;
  
  wire                              clk;
  wire                              rst;
  wire                              mmcm_locked;
  reg                               aresetn;
  
  
  

wire user_link_up;
wire axi_aclk_out;
wire axi_ctl_aclk_out;
wire m_axi_awlock;
wire m_axi_awvalid;	
wire m_axi_awready;	
wire m_axi_wlast  ;      
wire m_axi_wvalid ;      
wire m_axi_wready ;      
wire m_axi_bvalid ;      
wire m_axi_bready ;      
wire m_axi_arlock ;      
wire m_axi_arvalid;	
wire m_axi_arready;	
wire m_axi_rlast  ;      
wire m_axi_rvalid ;      
wire m_axi_rready ; 

wire [7 : 0] 	m_axi_awlen;
wire [2 : 0] 	m_axi_awsize;
wire [2 : 0] 	m_axi_awprot;
wire [2 : 0] 	m_axi_arprot;
wire [3 : 0] 	m_axi_awcache;
wire [3 : 0] 	m_axi_arcache;
wire [1 : 0] 	m_axi_awburst;
wire [1 : 0] 	bresp;
wire [1 : 0] 	rresp;
wire [(C_DATA_WIDTH - 1) : 0]	m_axi_wdata;
wire [(C_DATA_WIDTH - 1) : 0]	rdata;
wire [(KEEP_WIDTH -1) : 0]	m_axi_wstrb;
wire [7 : 0] 	m_axi_arlen;
wire [2 : 0] 	m_axi_arsize;
wire [1 : 0] 	m_axi_arburst;

wire [1 : 0] 	m_axi_bresp = bresp[1:0];
wire [1 : 0] 	m_axi_rresp = rresp[1:0];
wire [7 : 0] 	awlen =   m_axi_awlen	[7 : 0] ;
wire [2 : 0] 	awsize= m_axi_awsize	[2 : 0] ;
wire [2 : 0] 	awprot= m_axi_awprot	[2 : 0] ;
wire [2 : 0] 	arprot= m_axi_arprot	[2 : 0] ;
wire [3 : 0] 	awcache= m_axi_awcache	[3 : 0] ;
wire [3 : 0] 	arcache= m_axi_arcache	[3 : 0] ;
wire [1 : 0] 	awburst=m_axi_awburst	[1 : 0] ;
wire [(C_DATA_WIDTH -1) : 0]	wdata=  m_axi_wdata	[(C_DATA_WIDTH -1) : 0];
wire [(C_DATA_WIDTH -1) : 0]	m_axi_rdata=  rdata	[(C_DATA_WIDTH -1) : 0];
wire [(KEEP_WIDTH -1) : 0]	wstrb=  m_axi_wstrb	[(KEEP_WIDTH -1) : 0] ;
wire [7 : 0] 	arlen=  m_axi_arlen	[7 : 0] ;
wire [2 : 0] 	arsize= m_axi_arsize	[2 : 0] ;
wire [1 : 0] 	arburst=m_axi_arburst	[1 : 0] ;

wire [31:0]  m_axi_araddr;
wire [31:0]  m_axi_awaddr;
wire       [14:0]    awaddr = m_axi_awaddr[14:0];
wire       [14:0]    araddr = m_axi_araddr[14:0];
 //-------------------------------------------------------
  // 5. External Channel DRP Interface
  //-------------------------------------------------------
//  wire                                                    ext_ch_gt_drpclk;
  wire        [71:0]  ext_ch_gt_drpaddr;
  wire        [7:0]    ext_ch_gt_drpen;
  wire        [127:0]  ext_ch_gt_drpdi;
  wire        [7:0]    ext_ch_gt_drpwe;
 //--------------------Tie-off's for EXT GT Channel DRP ports----------------------------//
//  assign        ext_ch_gt_drpclk=1'b0;
  assign        ext_ch_gt_drpaddr = 72'd0;
  assign        ext_ch_gt_drpen=8'd0;
  assign        ext_ch_gt_drpdi=128'd0;
  assign        ext_ch_gt_drpwe=8'd0;

  wire  [11:0]  common_commands_in_i;
  wire  [24:0]  pipe_rx_0_sigs_i;
  wire  [24:0]  pipe_rx_1_sigs_i;
  wire  [24:0]  pipe_rx_2_sigs_i;
  wire  [24:0]  pipe_rx_3_sigs_i;
  wire  [24:0]  pipe_rx_4_sigs_i;
  wire  [24:0]  pipe_rx_5_sigs_i;
  wire  [24:0]  pipe_rx_6_sigs_i;
  wire  [24:0]  pipe_rx_7_sigs_i;
  wire  [11:0]  common_commands_out_i;
  wire  [24:0]  pipe_tx_0_sigs_i;
  wire  [24:0]  pipe_tx_1_sigs_i;
  wire  [24:0]  pipe_tx_2_sigs_i;
  wire  [24:0]  pipe_tx_3_sigs_i;
  wire  [24:0]  pipe_tx_4_sigs_i;
  wire  [24:0]  pipe_tx_5_sigs_i;
  wire  [24:0]  pipe_tx_6_sigs_i;
  wire  [24:0]  pipe_tx_7_sigs_i;

// synthesis translate_off
generate if (EXT_PIPE_SIM == "TRUE") 
begin
  assign common_commands_in_i = common_commands_in;  
  assign pipe_rx_0_sigs_i     = pipe_rx_0_sigs;   
  assign pipe_rx_1_sigs_i     = pipe_rx_1_sigs;   
  assign pipe_rx_2_sigs_i     = pipe_rx_2_sigs;   
  assign pipe_rx_3_sigs_i     = pipe_rx_3_sigs;   
  assign pipe_rx_4_sigs_i     = pipe_rx_4_sigs;   
  assign pipe_rx_5_sigs_i     = pipe_rx_5_sigs;   
  assign pipe_rx_6_sigs_i     = pipe_rx_6_sigs;   
  assign pipe_rx_7_sigs_i     = pipe_rx_7_sigs;   
  assign common_commands_out  = common_commands_out_i; 
  assign pipe_tx_0_sigs       = pipe_tx_0_sigs_i;      
  assign pipe_tx_1_sigs       = pipe_tx_1_sigs_i;      
  assign pipe_tx_2_sigs       = pipe_tx_2_sigs_i;      
  assign pipe_tx_3_sigs       = pipe_tx_3_sigs_i;      
  assign pipe_tx_4_sigs       = pipe_tx_4_sigs_i;      
  assign pipe_tx_5_sigs       = pipe_tx_5_sigs_i;      
  assign pipe_tx_6_sigs       = pipe_tx_6_sigs_i;      
  assign pipe_tx_7_sigs       = pipe_tx_7_sigs_i;      
 end
endgenerate
// synthesis translate_on   
  
generate if (EXT_PIPE_SIM == "FALSE") 
begin
  assign common_commands_in_i =  12'h0;  
  assign pipe_rx_0_sigs_i     = 25'h0;
  assign pipe_rx_1_sigs_i     = 25'h0;
  assign pipe_rx_2_sigs_i     = 25'h0;
  assign pipe_rx_3_sigs_i     = 25'h0;
  assign pipe_rx_4_sigs_i     = 25'h0;
  assign pipe_rx_5_sigs_i     = 25'h0;
  assign pipe_rx_6_sigs_i     = 25'h0;
  assign pipe_rx_7_sigs_i     = 25'h0;
 end
endgenerate

  //-------------------------------------------------------
  reg pipe_mmcm_rst_n = 1'b1;


  wire sys_rst_n_c;
  wire sys_clk;

// Local Parameters
  localparam                                  TCQ = 1;

  localparam USER_CLK_FREQ = 3;
  localparam USER_CLK2_DIV2 = "TRUE";
  localparam USERCLK2_FREQ   =  (USER_CLK2_DIV2 == "FALSE") ? USER_CLK_FREQ : 
                                                             (USER_CLK_FREQ == 4) ? 3 :
                                                             (USER_CLK_FREQ == 3) ? 2 :
                                                             (USER_CLK_FREQ == 2) ? 1 :
                                                              USER_CLK_FREQ;


  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));
  IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));

  // Synchronize Reset
  wire mmcm_lock;
  reg axi_aresetn;
(* ASYNC_REG = "TRUE" *)  reg sys_rst_n_reg;
(* ASYNC_REG = "TRUE" *)  reg sys_rst_n_reg2;
  
  always @ (posedge axi_aclk_out or negedge sys_rst_n_c) begin
  
      if (!sys_rst_n_c) begin
      
          sys_rst_n_reg  <= #TCQ 1'b0;
          sys_rst_n_reg2 <= #TCQ 1'b0;
          
      end else begin
      
          sys_rst_n_reg  <= #TCQ 1'b1;
          sys_rst_n_reg2 <= #TCQ sys_rst_n_reg;
          
      end
      
  end
  
  always @ (posedge axi_aclk_out) begin
  
    
      if (sys_rst_n_reg2) begin
      
          axi_aresetn <= #TCQ 1'b1;
          
      end else begin
      
          axi_aresetn <= #TCQ 1'b0;
          
      end
  
  end
  
  //
  // Simulation endpoint without CSL
  //

axi_pcie_7 axi_pcie_7_i
 (
  .user_link_up     (user_link_up),
  .axi_aresetn		(axi_aresetn),
  .axi_aclk_out		(axi_aclk_out),
  .axi_ctl_aclk_out	(axi_ctl_aclk_out),	
  .mmcm_lock		(mmcm_lock),	
  .interrupt_out	(),	
  .INTX_MSI_Request	(1'b0),	
  .INTX_MSI_Grant	(),	
  .MSI_enable		(),	
  .MSI_Vector_Num	(5'b0),	
  .MSI_Vector_Width	(),		
  .s_axi_awid		(4'b0),	
  .s_axi_awaddr		(32'b0),	
  .s_axi_awregion	(4'b0),		
  .s_axi_awlen		(8'b0),	
  .s_axi_awsize		(3'b0),		
  .s_axi_awburst	(2'b0),			
  .s_axi_awvalid	(1'b0),		
  .s_axi_awready	(),		
  .s_axi_wdata		(128'b0),		
  .s_axi_wstrb		(16'b0),			
  .s_axi_wlast		(1'b0),		
  .s_axi_wvalid		(1'b0),		
  .s_axi_wready		(),		
  .s_axi_bid		(),	
  .s_axi_bresp		(),	
  .s_axi_bvalid		(),		
  .s_axi_bready		(1'b0),		
  .s_axi_arid		(4'b0),		
  .s_axi_araddr		(32'b0),		
  .s_axi_arregion	(4'b0),		
  .s_axi_arlen		(8'b0),	
  .s_axi_arsize		(3'b0),		
  .s_axi_arburst	(2'b0),
  .s_axi_arvalid	(1'b0),
  .s_axi_arready	(),
  .s_axi_rid		(),
  .s_axi_rdata		(),	
  .s_axi_rresp		(),
  .s_axi_rlast		(),
  .s_axi_rvalid		(),
  .s_axi_rready		(1'b0),
  .m_axi_awaddr		(m_axi_awaddr),
  .m_axi_awlen		(m_axi_awlen	),
  .m_axi_awsize		(m_axi_awsize	),
  .m_axi_awburst	(m_axi_awburst),
  .m_axi_awprot		(m_axi_awprot	),
  .m_axi_awvalid	(m_axi_awvalid),
  .m_axi_awready	(m_axi_awready),	
  .m_axi_awlock		(m_axi_awlock	),
  .m_axi_awcache	(m_axi_awcache),
  .m_axi_wdata		(m_axi_wdata	),
  .m_axi_wstrb		(m_axi_wstrb	),
  .m_axi_wlast		(m_axi_wlast	),
  .m_axi_wvalid		(m_axi_wvalid	),
  .m_axi_wready		(m_axi_wready	),
  .m_axi_bresp		(m_axi_bresp	),
  .m_axi_bvalid		(m_axi_bvalid	),
  .m_axi_bready		(m_axi_bready	),
  .m_axi_araddr		(m_axi_araddr	),
  .m_axi_arlen		(m_axi_arlen	),
  .m_axi_arsize		(m_axi_arsize	),
  .m_axi_arburst	(m_axi_arburst),
  .m_axi_arprot		(m_axi_arprot	),
  .m_axi_arvalid	(m_axi_arvalid),
  .m_axi_arready	(m_axi_arready),
  .m_axi_arlock		(m_axi_arlock	),
  .m_axi_arcache	(m_axi_arcache),       
  .m_axi_rdata		(m_axi_rdata	),
  .m_axi_rresp		(m_axi_rresp	),
  .m_axi_rlast		(m_axi_rlast	),
  .m_axi_rvalid		(m_axi_rvalid	),
  .m_axi_rready		(m_axi_rready	),
  .pci_exp_txp          ( pci_exp_txp ),
  .pci_exp_txn          ( pci_exp_txn ),
  .pci_exp_rxp          ( pci_exp_rxp ),
  .pci_exp_rxn          ( pci_exp_rxn ),
  .REFCLK		(sys_clk),
  .s_axi_ctl_awaddr	(32'b0),
  .s_axi_ctl_awvalid	(1'b0),
  .s_axi_ctl_awready	(),
  .s_axi_ctl_wdata	(32'b0),
  .s_axi_ctl_wstrb	(4'b0),
  .s_axi_ctl_wvalid	(1'b0),
  .s_axi_ctl_wready	(),
  .s_axi_ctl_bresp	(),
  .s_axi_ctl_bvalid	(),
  .s_axi_ctl_bready	(1'b0),
  .s_axi_ctl_araddr	(32'b0),
  .s_axi_ctl_arvalid	(1'b0),
  .s_axi_ctl_arready	(),
  .s_axi_ctl_rdata	(),
  .s_axi_ctl_rresp	(),
  .s_axi_ctl_rvalid	(),
  .common_commands_in                         ( common_commands_in_i  ), 
  .pipe_rx_0_sigs                             ( pipe_rx_0_sigs_i      ), 
  .pipe_rx_1_sigs                             ( pipe_rx_1_sigs_i      ), 
  .pipe_rx_2_sigs                             ( pipe_rx_2_sigs_i      ), 
  .pipe_rx_3_sigs                             ( pipe_rx_3_sigs_i      ), 
  .pipe_rx_4_sigs                             ( pipe_rx_4_sigs_i      ), 
  .pipe_rx_5_sigs                             ( pipe_rx_5_sigs_i      ), 
  .pipe_rx_6_sigs                             ( pipe_rx_6_sigs_i      ), 
  .pipe_rx_7_sigs                             ( pipe_rx_7_sigs_i      ), 
                                                                   
  .common_commands_out                        ( common_commands_out_i ), 
  .pipe_tx_0_sigs                             ( pipe_tx_0_sigs_i      ), 
  .pipe_tx_1_sigs                             ( pipe_tx_1_sigs_i      ), 
  .pipe_tx_2_sigs                             ( pipe_tx_2_sigs_i      ), 
  .pipe_tx_3_sigs                             ( pipe_tx_3_sigs_i      ), 
  .pipe_tx_4_sigs                             ( pipe_tx_4_sigs_i      ), 
  .pipe_tx_5_sigs                             ( pipe_tx_5_sigs_i      ), 
  .pipe_tx_6_sigs                             ( pipe_tx_6_sigs_i      ), 
  .pipe_tx_7_sigs                             ( pipe_tx_7_sigs_i      ), 

  .s_axi_ctl_rready	(1'b0)

	
);

//INSTANTIATE BLOCK DIAGRAM (MIG and BRAM with Smartconnect)
//INTSANTIATE BLOCK DIAGRAM

always @(posedge clk) begin
     aresetn <= ~rst;
   end

design_1_wrapper DUT(

    .DDR3_0_addr(ddr3_addr), //DDR3 Ports
    .DDR3_0_ba(ddr3_ba),
    .DDR3_0_cas_n(ddr3_cas_n),
    .DDR3_0_ck_n(ddr3_ck_n),
    .DDR3_0_ck_p(ddr3_ck_p),
    .DDR3_0_cke(ddr3_cke),
    .DDR3_0_cs_n(ddr3_cs_n),
    .DDR3_0_dm(ddr3_dm),
    .DDR3_0_dq(ddr3_dq),
    .DDR3_0_dqs_n(ddr3_dqs_n),
    .DDR3_0_dqs_p(ddr3_dqs_p),
    .DDR3_0_odt(ddr3_odt),
    .DDR3_0_ras_n(ddr3_ras_n),
    .DDR3_0_reset_n(ddr3_reset_n),
    .DDR3_0_we_n(ddr3_we_n),
    
    .S00_AXI_0_araddr(m_axi_araddr), //AXI Slave ports
    .S00_AXI_0_arburst(m_axi_arburst),
    .S00_AXI_0_arcache(m_axi_arcache),
    .S00_AXI_0_arlen(m_axi_arlen),
    .S00_AXI_0_arlock(m_axi_arlock),
    .S00_AXI_0_arprot(m_axi_arprot),
    .S00_AXI_0_arqos(4'h0),
    .S00_AXI_0_arready(m_axi_arready),
    .S00_AXI_0_arsize(m_axi_arsize),
    .S00_AXI_0_arvalid(m_axi_arvalid),
    .S00_AXI_0_awaddr(m_axi_awaddr),
    .S00_AXI_0_awburst(m_axi_awburst),
    .S00_AXI_0_awcache(m_axi_awcache),
    .S00_AXI_0_awlen(m_axi_awlen),
    .S00_AXI_0_awlock(m_axi_awlock),
    .S00_AXI_0_awprot(m_axi_awprot),
    .S00_AXI_0_awqos(4'h0),
    .S00_AXI_0_awready(m_axi_awready),
    .S00_AXI_0_awsize(m_axi_awsize),
    .S00_AXI_0_awvalid(m_axi_awvalid),
    .S00_AXI_0_bready(m_axi_bready),
    .S00_AXI_0_bresp(m_axi_bresp),
    .S00_AXI_0_bvalid(m_axi_bvalid),
    .S00_AXI_0_rdata(m_axi_rdata),
    .S00_AXI_0_rlast(m_axi_rlast),
    .S00_AXI_0_rready(m_axi_rready),
    .S00_AXI_0_rresp(m_axi_rresp),
    .S00_AXI_0_rvalid(m_axi_rvalid),
    .S00_AXI_0_wdata(m_axi_wdata),
    .S00_AXI_0_wlast(m_axi_wlast),
    .S00_AXI_0_wready(m_axi_wready),
    .S00_AXI_0_wstrb(m_axi_wstrb),
    .S00_AXI_0_wvalid(m_axi_wvalid),
    
    .aclk_0(axi_aclk_out), //PCIE clock
    .aresetn_0(axi_aresetn), //PCIE aresetn
    .aresetn_1(aresetn), //MIG and BRAM aresetn
    
    .count_out_0(count_out), //count out value for custom DUT
    
    .init_calib_complete_0(init_calib_complete),
    .mmcm_locked_0(mmcm_locked),
    .SYS_CLK_0_clk_n(sys_clk_n_mig),
    .SYS_CLK_0_clk_p(sys_clk_p_mig),//200MHZ system clock for MIG and BRAM
    .sys_rst_0(sys_rst), //Active LOW reset for MIG
    .ui_clk_0(clk), //100MHz clock from MIG 
    .ui_clk_sync_rst_0(rst) //synchronous ACTIVE LOW reset from MIG
);

     
//    //example design BRAM Controller
//    axi_bram_ctrl_0 AXI_BRAM_CTL(
//      .s_axi_aclk 	(axi_aclk_out),
//      .s_axi_aresetn 	(axi_aresetn),
//      .s_axi_awid 	(4'b0),
//      .s_axi_awaddr 	(awaddr),
//      .s_axi_awlen 	(awlen),
//      .s_axi_awsize 	(awsize),
//      .s_axi_awburst 	(awburst),
//      .s_axi_awlock 	(m_axi_awlock),
//      .s_axi_awcache 	(awcache),
//      .s_axi_awprot 	(awprot),
//      .s_axi_awvalid	(m_axi_awvalid),
//      .s_axi_awready 	(m_axi_awready),
//      .s_axi_wdata 	(wdata),
//      .s_axi_wstrb	(wstrb),
//      .s_axi_wlast 	(m_axi_wlast),
//      .s_axi_wvalid 	(m_axi_wvalid),
//      .s_axi_wready 	(m_axi_wready),
//      .s_axi_bid	(),
//      .s_axi_bresp 	(bresp),
//      .s_axi_bvalid	(m_axi_bvalid),
//      .s_axi_bready 	(m_axi_bready),
//      .s_axi_arid 	(4'b0),
//      .s_axi_araddr 	(araddr),
//      .s_axi_arlen      (arlen),
//      .s_axi_arsize	(arsize),
//      .s_axi_arburst 	(arburst),
//      .s_axi_arlock	(m_axi_arlock),
//      .s_axi_arcache 	(arcache),
//      .s_axi_arprot	(arprot),
//      .s_axi_arvalid 	(m_axi_arvalid),
//      .s_axi_arready 	(m_axi_arready),
//      .s_axi_rid	(),
//      .s_axi_rdata      (rdata),
//      .s_axi_rresp      (rresp),
//      .s_axi_rlast      (m_axi_rlast),
//      .s_axi_rvalid	(m_axi_rvalid),
//      .s_axi_rready	(m_axi_rready)
//);



endmodule // BOARD


