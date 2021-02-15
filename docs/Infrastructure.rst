.. _Infrastructure Enviroment Overview:

========================
Building the Infrastructure Simulation Environment (PCIE, MIG, and DUT on VC707 board)
========================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient! 

.. _PCIe and MIG Example Designs:

Generating PCIe and MIG Example Designs
-----------------------------

Now that we have experience generating and manipulating the PCIe and MIG example designs, we can work to 
build an infrastructure environment.  This environment will start with the PCIE example design, and then 
we will perform modifications such that we can perform reads and writes to both DDR memory and a replaceable 
 Device Under Test (DUT).  This can be accomplished through the use of an AXI Smartconnect, or sometimes called 
a “NoC” in industry.  We will give the DDR memory and the Device Under Test different offset addresses in 
the AXI memory space, and then we can decide which device the PCIE will read or write to by specifying the 
address of the transaction.

-  First, we will want to create a new Vivado project and select the Xilinx VC707 board as the target. 

   .. Note:: For a refresher on generating the MIG example design or targeting the VC707 board, please see the “MIG 7 Series IP Overview” section.

-  Then, we will go ahead and open up a new block diagram, and under the :guilabel:`Board` tab, select the :guilabel:`DDR3 SDRAM option`.

.. figure:: /images/infrastructure/board_tab.PNG 
   :alt: DDR3 SDRAM
   :align: center

This will insert a MIG into the block diagram, which we can edit by double clicking on the IP.  
Please modify the following fields:  
.. Note:: leave all the rest as default
   -Desired Clock Period → 2500ps (400MHz)-
   -Data Width → 64 bit (default)
   -AXI Data Width → 64 bit
   -Input Clock Period → 5000ps (200MHz)
   -Deselect any Additional Clocks
   -Addressing → Bank/Row/Column
   -System Clock → Differential
   -Reference Clock → Use System Clock
   -Reset → ACTIVE LOW
   -Uncheck the Box for DCI Cascade
   -Select Fixed Pinout, then select Validate for the given pinout
   -In the system signals section:	
      -Leave sys_clk_p and sys_clk_n to their default pins
      -assign sys_rst to AR40 (push button)
      -assign init_calib_complete to AM39 (LED)
   -For more info on the pinout for the VC707 board, see this documentation from Xilinx here: https://www.xilinx.com/support/documentation/boards_and_kits/vc707/ug885_VC707_Eval_Bd.pdf

Once these modifications have been made, we can generate the IP in the block diagram, and then we can 
generate the IP example design by right-clicking on the IP block and selecting :guilabel:`Generate IP example design`.
Just like before, this will open up a project in Vivado with the MIG IP example design, which we can 
set aside for the moment.

-  Now, we will also need to generate the IP example design for the AXI Memory Mapped to PCI Express Core. 
   .. Note:: for a refresher on generating the AXI Memory Mapped to PCI Express example design, please see the “AXI MM to PCIe IP Overview” section.
-  In order to do this, click on the :guilabel:`+` icon to add IP to the block design, then select 
   :guilabel:`AXI Memory Mapped to PCI Express`.
-  Please make the following changes to the core: 
   .. Note:: unless specified, please leave everything as default
   -Reference Clock Frequency → 100MHz
   -Check the box to enable External PIPE Interface (this helps to speed up the simulation time)

.. figure:: /images/infrastructure/pcie_customization_with_pipe.PNG 
   :alt: PCIe Customization Pipe
   :align: center

   -Lane Width → X8
   -Link Speed → 2.5GT/s
   -In the PCIE BARs section, ensure only 1 BAR is enabled and that it is 16KB in size with offset at address 0x00000000.

.. figure:: /images/infrastructure/pcie_customization_bars.PNG 
   :alt: PCIe Customization Bars
   :align: center

-Once this core has been generated, we can go ahead and generate an example design for this IP as well.
-Now that the example designs have been generated for both the MIG and the PCIE IPs, we are ready to move onto the next section

.. _Creating the Block Diagramn:

Creating the Block Diagram
-----------------------------

-  Like we did in the section 2.4 of the AXI MM to PCIe IP Overview, the first step that we are going to want 
   to do is comment out the BRAM instantiation from the top file of the PCIE example design (xilinx_axi_pcie_ep.v)
   However, instead of inserting a MIG into its place, we are instead going to create a new block diagram

-  In the end, this is what we want the block diagram to look like:

.. figure:: /images/infrastructure/vc707_mig_bram_block_diagram.PNG 
   :alt: Block Diagram
   :align: center

In order to create this block diagram, follow these instructions:
      1. Add an AXI Smartconnect IP to the block design with two AXI Master outputs and one AXI Slave input.  
         Make sure that the data width is set to at least 32 bits, and make sure that there are two clock inputs.
      2. Make the S00_AXI, aclk, and aresetn ports external, as these will connect back into our PCIE core.
      3. Add a MIG 7 Series IP to the block design from the “Board” tab, and make sure to customize it in the 
         EXACT SAME way as the MIG you customized in the previous section.  This will ensure that the example 
         design we generated will have the correct parameters associated with it.
      4. Make the ``SYS_CLK``, ``sys_rst``, ``aresetn``, ``DDR3``, ``ui_clk_sync_rst``, ``ui_clk_``, ``mmcm_locked``,
         and ``init_calib_complete`` pins external, as these will be handled by our MIG example design 
         .. Note:: the ``SYS_CLK`` and ``DDR3`` pins should already be external, but in order to keep the same 
            naming conventions as my example, please delete the previous external connections, and then right-click 
            to make them external again.

      5. Add an AXI BRAM controller IP to the block design, and make sure to set the interface type to AXILite 
         and data width to 32 bits.  This BRAM represents the replaceable DUT that we should be able to exchange 
         with a custom design later.
      6. Connect the ``M00_AXI`` port from the Smartconnect to the ``S_AXI`` port on the MIG, and connect the 
         M01_AXI port from the Smartconnect to the S_AXI port on the BRAM controller.
      7. Connect the ``ui_clk`` from the MIG to the ``aclk1`` port on the Smartconnect and the ``s_axi_aclk`` 
         port on the BRAM controller.  This way, the example DUT will be in the same clock domain as the MIG.
      8. Connect the ``s_axi_aresetn`` port on the BRAM controller to the external aresetn signal going into the MIG.  
         This way, the example DUT reset will be synchronous with the MIG reset.
      9. Finally, there should be an option at the top of the screen to :guilabel:`Run Connection Automation`, 
         and doing this should insert the Block Memory Generator, which will be attached to the BRAM controller.


-  Now that the block diagram has been created, we will need to use the address editor to assign the MIG and BRAM 
   locations in the AXI memory space.  Click on the :guilabel:`Address Editor` tab, and edit the offset addresses 
   as follows:
      -MIG: size 8KB, range: 0x0000_0000 to 0x0000_1FFF
      -BRAM: size 8KB, range: 0x2000_3FFF
.. figure:: /images/infrastructure/mig_bram_address_editor.PNG 
   :alt: Addresse Editor
   :align: center

-  If we click on the :guilabel:`Address Map` tab, then we can even see a layout of the memory mapping:
.. figure:: /images/infrastructure/mig_bram_address_map.PNG 
   :alt: Addresse Map
   :align: center

-  Since we configured the PCIe to have a 16KB BAR from address 0x0000_0000 to 0x0000_3FFF, we should now be able 
   to access both of our AXI slaves from within the PCIE memory space

-  Finally, we can go ahead and right-click on our block diagram and select :guilabel:`validate design`.  
   There might be some warnings about the resets not being synchronous, but that is because we haven’t connected 
   the PCIe IP to the design yet, so it is alright to ignore this.

-  Once Validation is successful, we will need to right click on the block design under the :guilabel:`Sources` menu, 
   and select :guilabel:`Create HDL Wrapper`.  Just like before, this will generate an RTL wrapper file for this 
   block diagram, which we can instantiate into our PCIe example design in the next section.

.. _Connecting it all Together:

Connecting it all Together
-----------------------------   

-  Similar to section 2.4. of the AXI MM to PCIe IP Overview, we will now need to instantiate our block diagram into 
   the PCIe example design.  Since this process has several steps involved with it, I will go ahead and include my 
   design top file here, my constraints top file here, and my simulation top file here, and this next section will 
   be a brief overview of the steps needed to combine the PCIe example design, the MIG example design, and the block 
   diagram.

-  First, we will need to correctly instantiate the block design wrapper file into the PCIe example top file. In order 
   to do this, we can locate where we commented out the old BRAM instantiation, and instead instantiate the block design 
   like this:
   .. figure:: /images/infrastructure/DUT_instantiation_part_1.PNG 
   :alt: dut instanc pt1
   :align: center

   .. figure:: /images/infrastructure/DUT_instantiation_part_2.PNG 
   :alt: dut instanc pt2
   :align: center

-  Then, we will need to copy all of the relevant parameters, wires, functions, inputs, and outputs from the MIG example 
   design top file into the PCIe example design top file (INSERT CODE HERE).  
   .. Note:: The following fields had to be changed because of already existing fields in the PCIe example design:
         -Parameters:  TCQ → TCQ_MIG
         -Inputs: sys_clk_n → sys_clk_n_mig
         -Outputs: sys_clk_p → sys_clk_p_mig
-  Also, make sure to copy over the statement that synchronizes the MIG reset:
  .. figure:: /images/infrastructure/mig_reset.PNG 
   :alt: mig reset
   :align: center

-  Then, we will need to copy over the top-level constraints from the MIG example design and paste them into the top-level 
   constraints file for the PCIe example design.  The top level constraints for each project can be found under the :guilabel:`Constraints` 
   tab in the :guilabel:`Sources` menu. This can be seen below:
   .. figure:: /images/infrastructure/constraints_from_mig_example.PNG 
   :alt: mig  constraints
   :align: center

-  Once the top file and the constraints file have been modified, then we can go ahead and run synthesis and implementation 
   to ensure that there are no errors in our design.  If there are any errors with synthesis or implementation, refer to the 
   TCL console for help with debugging, and or cross reference your design top file and constraints top file with the files 
   provided above.
   
-  Once synthesis and implementation are complete, your schematic should look something like this 
         (partial image only, image was too large to fully capture):
  .. figure:: /images/infrastructure/vc707_pcie_mig_bram_schematic.PNG 
   :alt: schematic
   :align: center

-  Once synthesis and implementation are complete, we can now move on to the next section.


.. _Modifying and Running the Simulation:

Modifying and Running the Simulation
-----------------------------  

-  Just like the example in section 2.5 of the AXI MM to PCIE IP Overview, the first step to running our simulation is to import 
   the correct simulation files from the MIG example project (ddr3_model.sv, ddr3_model_parameters.vh, and wiredly.v).  For more 
   information on how to import these files, please reference that section.

-  Now, we will need to edit our simulation top file in order to accommodate the MIG and DDR3 memory model, as well as include our 
   block diagram from earlier.  Because there were a good amount of modifications made, my simulation top file can be downloaded 
   here for individual use.

-  Here are a couple of notes about the modifications made to the PCIe example design top file:
      -Parameters changed:
            -TCQ → TCQ_MIG (duplicate name)
            -ADDR_WIDTH → ADDR_WIDTH_MIG (duplicate name)
            -RESET_PERIOD = 100 (convert to nanoseconds)
      -Wires/Regs changed:
            -sys_rst_n → sys_rst_n_mig (duplicate name)
      -Variables changed:
            -In the memory model instantiation, the variable “i” had to be changed to “s” due to a duplicate name
 .. figure:: /images/infrastructure/change_i_to_s.PNG 
   :alt: change i to s
   :align: center

      -MIG input system and reference clocks:
            -Due to timescale issue (MIG simulation top file is in picoseconds, PCIe simulation top file is in nanoseconds), 
            I was forced to change the system and reference clocks to run at 250MHz instead of 200MHz (4ns period instead of 5ns period).  
            This in turn causes the MIG ui_clk to run at 125MHz instead of 100MHz.  However, everything in the simulation should 
            still run fine.
 .. figure:: /images/infrastructure/vc707_mig_bram_timing_issue.PNG 
   :alt: mig input system and ref clk
   :align: center  
  
      -Instantiations included:
            -Top file from design sources
            -DDR3 memory model
            -Wire delay modules
      -Additional edits:
            -In order to determine when init_calib_complete goes HIGH for the MIG, I added a line to display “MIG Calibration Done” when 
            this event occurs.
.. figure:: /images/infrastructure/check_for_mig_calibration.PNG 
   :alt: Mig Cal Done
   :align: center 

-  All of these modifications can be seen in my simulation top file, which is available for download above.

-  Now, if we were to click :guilabel:`Run Behavioral Simulation`, the standard PCIe example simulation would run, which would simply 
   perform a read and a write to address 0x0000_0010.  For debugging purposes, it may be smart to try and run this simulation to make 
   sure that everything is set up properly.  However, we want to be able to read and write our own data to our own specific addresses.  
   In order to do this, we will need to edit the simulation header file called “sample_tests1.vh”.  This file can be located in the 
   :guilabel:`Verilog Header` folder within :guilabel:`Simulation Sources`, and I will attach my custom sample_tests1.vh file here.  
   Here are some of the changes that were made in order to perform custom reads and writes.
         
         -Under the comment that says “MEM 32 SPACE” in the BAR Testing section, I first included a 60us delay to allow for the MIG to 
          finish calibrating before attempting to read and write from it
         
         -Then, I used the predefined tasks “TSK_TX_BAR_WRITE” and “TSK_TX_BAR_READ” to perform the custom reads and writes. The definitions 
         of these tasks can be found in the “pci_exp_usrapp_tx.v” file contained within the Root Port simulation model
         
         -In order to test the MIG, I sent the data “0xABCD_BEEF” to address 0x0000_0010, which should correspond to address 0x0000_00010 
         on the MIG.  If the read data equals the written data, then the message “MIG Test Passed” will appear in the TCL Console

