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

`timescale 1ns/1ps //fix this

module xilinx_axi_pcie_ep  #(
  parameter PL_FAST_TRAIN       = "FALSE", // Simulation Speedup
  parameter PCIE_EXT_CLK        = "FALSE",  // Use External Clocking Module
  parameter EXT_PIPE_SIM        = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.	
  parameter PCIE_EXT_GT_COMMON  = "FALSE",
  parameter REF_CLK_FREQ        = 0,
  parameter C_DATA_WIDTH        = 64, // RX/TX interface data width
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
   parameter CK_WIDTH              = 1, // # of CK/CK# outputs to memory.
   parameter nCS_PER_RANK          = 1, // # of unique CS outputs per rank for phy
   parameter CKE_WIDTH             = 1, // # of CKE outputs to memory.
   parameter DM_WIDTH              = 1, // # of DM (data mask)
   parameter ODT_WIDTH             = 1, // # of ODT outputs to memory.
   parameter BANK_WIDTH            = 3, // # of memory Bank Address bits.
   parameter COL_WIDTH             = 10, // # of memory Column Address bits.
   parameter CS_WIDTH              = 1, // # of unique CS outputs to memory.
   parameter DQ_WIDTH              = 8, // # of DQ (data)
   parameter DQS_WIDTH             = 1,
   parameter DQS_CNT_WIDTH         = 1, // = ceil(log2(DQS_WIDTH))
   parameter DRAM_WIDTH            = 8, // # of DQ per DQS
   parameter ECC                   = "OFF",
   parameter ECC_TEST              = "OFF",
   parameter nBANK_MACHS           = 4,
   parameter RANKS                 = 1, // # of Ranks.
   parameter ROW_WIDTH             = 14, // # of memory Row Address bits.
   parameter ADDR_WIDTH            = 28, // # = RANK_WIDTH + BANK_WIDTH + ROW_WIDTH + COL_WIDTH;
                                         // Chip Select is always tied to low for single rank devices
                                         
   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   parameter BURST_MODE            = "8",// DDR3 SDRAM:
                                     // Burst Length (Mode Register 0).
                                     // # = "8", "4", "OTF".

   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   parameter CLKIN_PERIOD          = 5000, // Input Clock Period
   parameter CLKFBOUT_MULT         = 4,// write PLL VCO multiplier
   parameter DIVCLK_DIVIDE         = 1, // write PLL VCO divisor
   parameter CLKOUT0_PHASE         = 315.0,// Phase for PLL output clock (CLKOUT0)
   parameter CLKOUT0_DIVIDE        = 1, // VCO output divisor for PLL output clock (CLKOUT0)
   parameter CLKOUT1_DIVIDE        = 2,// VCO output divisor for PLL output clock (CLKOUT1)
   parameter CLKOUT2_DIVIDE        = 32, // VCO output divisor for PLL output clock (CLKOUT2)
   parameter CLKOUT3_DIVIDE        = 8,// VCO output divisor for PLL output clock (CLKOUT3)
   parameter MMCM_VCO              = 800,// Max Freq (MHz) of MMCM VCO
   parameter MMCM_MULT_F           = 8, // write MMCM VCO multiplier
   parameter MMCM_DIVCLK_DIVIDE    = 1,// write MMCM VCO divisor

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   parameter SIMULATION            = "FALSE",
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementations
                                     
   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   
   
   parameter TCQ_MIG                   = 0.1, //100 ps for MIG
   
   
   parameter DRAM_TYPE             = "DDR3",
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   parameter nCK_PER_CLK           = 4, // # of memory CKs per fabric CLK

   //***************************************************************************
   // AXI4 Shim parameters
   //***************************************************************************
   parameter C_S_AXI_ID_WIDTH              = 4, // Width of all master and slave ID signals. # = >= 1.
   parameter C_S_AXI_ADDR_WIDTH            = 27,// Width of S_AXI_AWADDR, S_AXI_ARADDR, M_AXI_AWADDR and M_AXI_ARADDR for all SI/MI slots. # = 32.
   parameter C_S_AXI_DATA_WIDTH            = 32, // Width of WDATA and RDATA on SI slot. Must be <= APP_DATA_WIDTH. # = 32, 64, 128, 256.
   parameter C_S_AXI_SUPPORTS_NARROW_BURST = 0, // Indicates whether to instatiate upsizer. Range: 0, 1
   
   //***************************************************************************
   // Debug parameters
   //***************************************************************************
   parameter DEBUG_PORT            = "OFF",// # = "ON" Enable debug signals/controls. "OFF" Disable debug signals/controls.
   parameter RST_ACT_LOW           = 0// =1 for active low reset, =0 for active high.

) (

  output  [3:0]    pci_exp_txp,
  output  [3:0]    pci_exp_txn,
  input   [3:0]    pci_exp_rxp,
  input   [3:0]    pci_exp_rxn,




  input                  sys_clk_p,
  input                  sys_clk_n,
  input                  sys_rst_n, //ACTIVE LOW
  
  //INSERT INPUTS/OUTPUTS FOR MIG
  // Inouts

   inout [7:0]                         ddr3_dq,
   inout [0:0]                        ddr3_dqs_n,
   inout [0:0]                        ddr3_dqs_p,
   
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
   output [0:0]                         ddr3_cs_n,
   output [0:0]                        ddr3_dm,
   output [0:0]                       ddr3_odt,

   // Single-ended system clock
   input                                        sys_clk_i,
   output                                       tg_compare_error,
   output                                       init_calib_complete,
   
   // System reset - Default polarity of sys_rst pin is Active Low.
   // System reset polarity will change based on the option 
   // selected in GUI.
   input                                        sys_rst //Active HIGH

);

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
wire       [13:0]    awaddr = m_axi_awaddr[13:0];
wire       [13:0]    araddr = m_axi_araddr[13:0];
 //-------------------------------------------------------
  // 5. External Channel DRP Interface
  //-------------------------------------------------------
//  wire                                                    ext_ch_gt_drpclk;
  wire        [35:0]  ext_ch_gt_drpaddr;
  wire        [3:0]    ext_ch_gt_drpen;
  wire        [63:0]  ext_ch_gt_drpdi;
  wire        [3:0]    ext_ch_gt_drpwe;
 //--------------------Tie-off's for EXT GT Channel DRP ports----------------------------//
//  assign        ext_ch_gt_drpclk=1'b0;
  assign        ext_ch_gt_drpaddr = 36'd0;
  assign        ext_ch_gt_drpen=4'd0;
  assign        ext_ch_gt_drpdi=64'd0;
  assign        ext_ch_gt_drpwe=4'd0;


  //-------------------------------------------------------
  reg pipe_mmcm_rst_n = 1'b1;


  wire sys_rst_n_c;
  wire sys_clk;

// Local Parameters
  localparam                                  TCQ = 1;

  localparam USER_CLK_FREQ = 2;
  localparam USER_CLK2_DIV2 = "FALSE";
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
  
      if (sys_rst_n_reg2 && mmcm_lock) begin
      
          axi_aresetn <= #TCQ 1'b1;
          
      end else begin
      
          axi_aresetn <= #TCQ 1'b0;
          
      end
  
  end
  
  //
  // Simulation endpoint without CSL
  //
  
  //INSERT FUNCTIONS FROM MIG TOP FILE
  
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
  
  //INSERT LOCALPARAMS FROM MIG TOP FILE
  
  localparam DATA_WIDTH            = 8;
  localparam RANK_WIDTH = clogb2(RANKS);
  localparam PAYLOAD_WIDTH         = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;
  localparam BURST_LENGTH          = STR_TO_INT(BURST_MODE);
  localparam APP_DATA_WIDTH        = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  localparam APP_MASK_WIDTH        = APP_DATA_WIDTH / 8;
  //***************************************************************************
  // Traffic Gen related parameters (derived)
  //***************************************************************************
  localparam  TG_ADDR_WIDTH = ((CS_WIDTH == 1) ? 0 : RANK_WIDTH) + BANK_WIDTH + ROW_WIDTH + COL_WIDTH;
  localparam MASK_SIZE             = DATA_WIDTH/8;
  localparam DBG_WR_STS_WIDTH      = 40;
  localparam DBG_RD_STS_WIDTH      = 40;
  
  //INSERT MIG WIRE DECLARATIONS
  
  wire                              clk;
  wire                              rst;
  wire                              mmcm_locked;
  reg                               aresetn;
  wire                              app_sr_active;
  wire                              app_ref_ack;
  wire                              app_zq_ack;
  wire                              app_rd_data_valid;
  wire [APP_DATA_WIDTH-1:0]         app_rd_data;
  wire                              mem_pattern_init_done;
  wire                              cmd_err;
  wire                              data_msmatch_err;
  wire                              write_err;
  wire                              read_err;
  wire                              test_cmptd;
  wire                              write_cmptd;
  wire                              read_cmptd;
  wire                              cmptd_one_wr_rd;
  
  //ADDITIONAL WIRES NEEDED TO ADD
  wire         app_sr_req;

  wire         app_ref_req;

  wire         app_zq_req;

  // Slave Interface Write Address Ports
  wire [C_S_AXI_ID_WIDTH-1:0]       s_axi_awid;
  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr;
  wire [7:0]                        s_axi_awlen;
  wire [2:0]                        s_axi_awsize;
  wire [1:0]                        s_axi_awburst;
  wire [0:0]                        s_axi_awlock;
  wire [3:0]                        s_axi_awcache;
  wire [2:0]                        s_axi_awprot;
  wire                              s_axi_awvalid;
  wire                              s_axi_awready;

  // Slave Interface Write Data Ports
  wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_wdata;
  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]   s_axi_wstrb;
  wire                              s_axi_wlast;
  wire                              s_axi_wvalid;
  wire                              s_axi_wready;

  // Slave Interface Write Response Ports
  wire                              s_axi_bready;
  wire [C_S_AXI_ID_WIDTH-1:0]       s_axi_bid;
  wire [1:0]                        s_axi_bresp;
  wire                              s_axi_bvalid;

  // Slave Interface Read Address Ports
  wire [C_S_AXI_ID_WIDTH-1:0]       s_axi_arid;
  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr;
  wire [7:0]                        s_axi_arlen;
  wire [2:0]                        s_axi_arsize;
  wire [1:0]                        s_axi_arburst;
  wire [0:0]                        s_axi_arlock;
  wire [3:0]                        s_axi_arcache;
  wire [2:0]                        s_axi_arprot;
  wire                              s_axi_arvalid;
  wire                              s_axi_arready;

  // Slave Interface Read Data Ports
  wire                              s_axi_rready;
  wire [C_S_AXI_ID_WIDTH-1:0]       s_axi_rid;
  wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_rdata;
  wire [1:0]                        s_axi_rresp;
  wire                              s_axi_rlast;
  wire                              s_axi_rvalid;
  wire                              cmp_data_valid;
  wire [C_S_AXI_DATA_WIDTH-1:0]      cmp_data;     // Compare data
  wire [C_S_AXI_DATA_WIDTH-1:0]      rdata_cmp;      // Read data
  wire                              dbg_wr_sts_vld;
  wire [DBG_WR_STS_WIDTH-1:0]       dbg_wr_sts;
  wire                              dbg_rd_sts_vld;
  wire [DBG_RD_STS_WIDTH-1:0]       dbg_rd_sts;
  wire [11:0]                           device_temp;

`ifdef SKIP_CALIB // skip calibration wires
  wire                          calib_tap_req;
  reg                           calib_tap_load;
  reg [6:0]                     calib_tap_addr;
  reg [7:0]                     calib_tap_val;
  reg                           calib_tap_load_done;
`endif
 assign tg_compare_error = cmd_err | data_msmatch_err | write_err | read_err;


//INSTANTIATE PCIE CORE (DEFAULT)
axi_pcie_2 axi_pcie_2_i
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
  .s_axi_wdata		(64'b0),		
  .s_axi_wstrb		(8'b0),			
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

  .s_axi_ctl_rready	(1'b0)

);


//INSTANTIATE MIG CORE
mig_7series_5 u_mig_7series_5(

// Memory interface ports
       .ddr3_addr                      (ddr3_addr),
       .ddr3_ba                        (ddr3_ba),
       .ddr3_cas_n                     (ddr3_cas_n),
       .ddr3_ck_n                      (ddr3_ck_n),
       .ddr3_ck_p                      (ddr3_ck_p),
       .ddr3_cke                       (ddr3_cke),
       .ddr3_ras_n                     (ddr3_ras_n),
       .ddr3_we_n                      (ddr3_we_n),
       .ddr3_dq                        (ddr3_dq),
       .ddr3_dqs_n                     (ddr3_dqs_n),
       .ddr3_dqs_p                     (ddr3_dqs_p),
       .ddr3_reset_n                   (ddr3_reset_n),
       .init_calib_complete            (init_calib_complete),
       .ddr3_cs_n                      (ddr3_cs_n),
       .ddr3_dm                        (ddr3_dm),
       .ddr3_odt                       (ddr3_odt),

// Application interface ports
       .ui_clk                         (clk),
       .ui_clk_sync_rst                (rst),
       .mmcm_locked                    (mmcm_locked),
       .aresetn                        (aresetn),
       
       .app_sr_req(app_sr_req),
       .app_ref_req(app_ref_req),  //HAD TO ADD THESE MANUALLY
       .app_zq_req(app_zq_req),
       
       .app_sr_active                  (app_sr_active),
       .app_ref_ack                    (app_ref_ack),
       .app_zq_ack                     (app_zq_ack),

// Slave Interface Write Address Ports
       .s_axi_awid                     (s_axi_awid),
       .s_axi_awaddr                   (s_axi_awaddr),
       .s_axi_awlen                    (s_axi_awlen),
       .s_axi_awsize                   (s_axi_awsize),
       .s_axi_awburst                  (s_axi_awburst),
       .s_axi_awlock                   (s_axi_awlock),
       .s_axi_awcache                  (s_axi_awcache),
       .s_axi_awprot                   (s_axi_awprot),
       .s_axi_awqos                    (4'h0),
       .s_axi_awvalid                  (s_axi_awvalid),
       .s_axi_awready                  (s_axi_awready),

// Slave Interface Write Data Ports
       .s_axi_wdata                    (s_axi_wdata),
       .s_axi_wstrb                    (s_axi_wstrb),
       .s_axi_wlast                    (s_axi_wlast),
       .s_axi_wvalid                   (s_axi_wvalid),
       .s_axi_wready                   (s_axi_wready),

// Slave Interface Write Response Ports
       .s_axi_bid                      (s_axi_bid),
       .s_axi_bresp                    (s_axi_bresp),
       .s_axi_bvalid                   (s_axi_bvalid),
       .s_axi_bready                   (s_axi_bready),

// Slave Interface Read Address Ports
       .s_axi_arid                     (s_axi_arid),
       .s_axi_araddr                   (s_axi_araddr),
       .s_axi_arlen                    (s_axi_arlen),
       .s_axi_arsize                   (s_axi_arsize),
       .s_axi_arburst                  (s_axi_arburst),
       .s_axi_arlock                   (s_axi_arlock),
       .s_axi_arcache                  (s_axi_arcache),
       .s_axi_arprot                   (s_axi_arprot),
       .s_axi_arqos                    (4'h0),
       .s_axi_arvalid                  (s_axi_arvalid),
       .s_axi_arready                  (s_axi_arready),

// Slave Interface Read Data Ports
       .s_axi_rid                      (s_axi_rid),
       .s_axi_rdata                    (s_axi_rdata),
       .s_axi_rresp                    (s_axi_rresp),
       .s_axi_rlast                    (s_axi_rlast),
       .s_axi_rvalid                   (s_axi_rvalid),
       .s_axi_rready                   (s_axi_rready),

// System Clock Ports
       .sys_clk_i                       (sys_clk_i),
       .device_temp            (device_temp),
       `ifdef SKIP_CALIB
       .calib_tap_req                    (calib_tap_req),
       .calib_tap_load                   (calib_tap_load),
       .calib_tap_addr                   (calib_tap_addr),
       .calib_tap_val                    (calib_tap_val),
       .calib_tap_load_done              (calib_tap_load_done),
       `endif
       
       .sys_rst                        (sys_rst)
);

assign s_axi_awid = 4'h0;
assign s_axi_arid = 4'h0;
assign app_sr_req = 1'h0;
assign app_ref_req = 1'h0;
assign app_zq_req = 1'h0;

always @(posedge clk) begin
     aresetn <= ~rst;
   end
   
//INSTANTIATE AXI SMARTCONNECT MODULE
design_1_wrapper u_axi_smartconnect(

    //Master ports going into MIG
    .M00_AXI_0_araddr(s_axi_araddr),
    .M00_AXI_0_arburst(s_axi_arburst),
    .M00_AXI_0_arcache(s_axi_arcache),
    .M00_AXI_0_arlen(s_axi_arlen),
    .M00_AXI_0_arlock(s_axi_arlock),
    .M00_AXI_0_arprot(s_axi_arprot),
    //.M00_AXI_0_arqos(s_axi_arqos),
    .M00_AXI_0_arready(s_axi_arready),
    .M00_AXI_0_arsize(s_axi_arsize),
    .M00_AXI_0_arvalid(s_axi_arvalid),
    .M00_AXI_0_awaddr(s_axi_awaddr),
    .M00_AXI_0_awburst(s_axi_awburst),
    .M00_AXI_0_awcache(s_axi_awcache),
    .M00_AXI_0_awlen(s_axi_awlen),
    .M00_AXI_0_awlock(s_axi_awlock),
    .M00_AXI_0_awprot(s_axi_awprot),
    //.M00_AXI_0_awqos(s_axi_awqos),
    .M00_AXI_0_awready(s_axi_awready),
    .M00_AXI_0_awsize(s_axi_awsize),
    .M00_AXI_0_awvalid(s_axi_awvalid),
    .M00_AXI_0_bready(s_axi_bready),
    .M00_AXI_0_bresp(s_axi_bresp),
    .M00_AXI_0_bvalid(s_axi_bvalid),
    .M00_AXI_0_rdata(s_axi_rdata),
    .M00_AXI_0_rlast(s_axi_rlast),
    .M00_AXI_0_rready(s_axi_rready),
    .M00_AXI_0_rresp(s_axi_rresp),
    .M00_AXI_0_rvalid(s_axi_rvalid),
    .M00_AXI_0_wdata(s_axi_wdata),
    .M00_AXI_0_wlast(s_axi_wlast),
    .M00_AXI_0_wready(s_axi_wready),
    .M00_AXI_0_wstrb(s_axi_wstrb),
    .M00_AXI_0_wvalid(s_axi_wvalid),
    
    //Slave ports coming from the PCIE
    .S00_AXI_0_araddr(m_axi_araddr),
    .S00_AXI_0_arburst(m_axi_arburst),
    .S00_AXI_0_arcache(m_axi_arcache),
    .S00_AXI_0_arlen(m_axi_arlen),
    .S00_AXI_0_arlock(m_axi_arlock),
    .S00_AXI_0_arprot(m_axi_arprot),
    //.S00_AXI_0_arqos(m_axi_arqos),
    .S00_AXI_0_arready(m_axi_arready),
    .S00_AXI_0_arsize(m_axi_arsize),
    .S00_AXI_0_arvalid(m_axi_arvalid),
    .S00_AXI_0_awaddr(m_axi_awaddr),
    .S00_AXI_0_awburst(m_axi_awburst),
    .S00_AXI_0_awcache(m_axi_awcache),
    .S00_AXI_0_awlen(m_axi_awlen),
    .S00_AXI_0_awlock(m_axi_awlock),
    .S00_AXI_0_awprot(m_axi_awprot),
    //.S00_AXI_0_awqos(m_axi_awqos),
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
    
    //Clocks and Resets
    .aclk1_0(clk), //MIG clock (100MHz)
    .aclk_0(axi_aclk_out), //PCIE clock (125MHz)
    .aresetn_0(aresetn) //use MIG reset signal
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

//INSERT REMAINING RTL FROM MIG TOP FILE
   //*****************************************************************
   // Default values are assigned to the debug inputs
   //*****************************************************************
   assign dbg_sel_pi_incdec       = 'b0;
   assign dbg_sel_po_incdec       = 'b0;
   assign dbg_pi_f_inc            = 'b0;
   assign dbg_pi_f_dec            = 'b0;
   assign dbg_po_f_inc            = 'b0;
   assign dbg_po_f_dec            = 'b0;
   assign dbg_po_f_stg23_sel      = 'b0;
   assign po_win_tg_rst           = 'b0;
   assign vio_tg_rst              = 'b0;

`ifdef SKIP_CALIB

  //***************************************************************************
  // Skip calib test logic
  //***************************************************************************
  reg[3*DQS_WIDTH-1:0]        po_coarse_tap;
  reg[6*DQS_WIDTH-1:0]        po_stg3_taps;
  reg[6*DQS_WIDTH-1:0]        po_stg2_taps;
  reg[6*DQS_WIDTH-1:0]        pi_stg2_taps;
  reg[5*DQS_WIDTH-1:0]        idelay_taps;
  reg[11:0]                   cal_device_temp;

  always @(posedge clk) begin
    // tap values from golden run (factory)
    po_coarse_tap   <= #TCQ_MIG 'h2;
    po_stg3_taps    <= #TCQ_MIG 'h0D;
    po_stg2_taps    <= #TCQ_MIG 'h1D;
    pi_stg2_taps    <= #TCQ_MIG 'h1E;
    idelay_taps     <= #TCQ_MIG 'h08;
    cal_device_temp <= #TCQ_MIG 'h000;
  end

  always @(posedge clk) begin
    if (rst)
      calib_tap_load <= #TCQ_MIG 1'b0;
    else if (calib_tap_req)
      calib_tap_load <= #TCQ_MIG 1'b1;
  end

  always @(posedge clk) begin
    if (rst) begin
      calib_tap_addr      <= #TCQ_MIG 'd0;
      calib_tap_val       <= #TCQ_MIG po_coarse_tap[3*calib_tap_addr[6:3]+:3]; //'d1;
      calib_tap_load_done <= #TCQ_MIG 1'b0;
    end else if (calib_tap_load) begin
      case (calib_tap_addr[2:0])
        3'b000: begin
          calib_tap_addr[2:0] <= #TCQ_MIG 3'b001;
          calib_tap_val       <= #TCQ_MIG po_stg3_taps[6*calib_tap_addr[6:3]+:6]; //'d19;
        end
        3'b001: begin
          calib_tap_addr[2:0] <= #TCQ_MIG 3'b010;
          calib_tap_val       <= #TCQ_MIG po_stg2_taps[6*calib_tap_addr[6:3]+:6]; //'d45;
        end

        3'b010: begin
          calib_tap_addr[2:0] <= #TCQ_MIG 3'b011;
          calib_tap_val       <= #TCQ_MIG pi_stg2_taps[6*calib_tap_addr[6:3]+:6]; //'d20;
        end

        3'b011: begin
          calib_tap_addr[2:0] <= #TCQ_MIG 3'b100;
          calib_tap_val       <= #TCQ_MIG idelay_taps[5*calib_tap_addr[6:3]+:5]; //'d1;
        end

        3'b100: begin
          if (calib_tap_addr[6:3] < DQS_WIDTH-1) begin
            calib_tap_addr[2:0] <= #TCQ_MIG 3'b000;
            calib_tap_val       <= #TCQ_MIG po_coarse_tap[3*(calib_tap_addr[6:3]+1)+:3]; //'d1;
            calib_tap_addr[6:3] <= #TCQ_MIG calib_tap_addr[6:3] + 1;
          end else begin
            calib_tap_addr[2:0] <= #TCQ_MIG 3'b110;
            calib_tap_val       <= #TCQ_MIG cal_device_temp[7:0];
            calib_tap_addr[6:3] <= #TCQ_MIG 4'b1111;
          end
        end

        3'b110: begin
            calib_tap_addr[2:0] <= #TCQ_MIG 3'b111;
            calib_tap_val       <= #TCQ_MIG {4'h0,cal_device_temp[11:8]};
            calib_tap_addr[6:3] <= #TCQ_MIG 4'b1111;
        end

        3'b111: begin
            calib_tap_load_done <= #TCQ_MIG 1'b1;
        end
      endcase
    end
  end

//****************skip calib test logic end**********************************

`endif


endmodule // BOARD


