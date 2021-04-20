.. _Basic Environment Overview:

===============================================
Building a Basic Simulation Environment (VC707)
===============================================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient! 

.. _BASIC PCIe and MIG Example Designs:

Generating PCIe and MIG Example Designs
---------------------------------------

Now that we have experience generating and manipulating the PCIe and MIG example designs, we can start putting 
the pieces together - that is, building the basic infrastructure behind our FPGA emulation environment.
The infrastructure will begin modifying Xilinx's PCIe example design, as this will allow us to perform 
reads and writes to both DDR memory and a replaceable Device Under Test (DUT), as well as other on-board
peripherals. This can be accomplished through the use of an AXI SmartConnect, or what is known as a
a "NoC" in industry. You can read more about the SmartConnect IP and the AXI protocol :ref:`here <AXI Interconnect SmartConnect>`. 
We will give the DDR memory and the Device Under Test different offset addresses in the AXI memory space, and then 
we can decide which device the PCIe will read or write to by specifying the address of the transaction.

.. Note:: For a refresher on generating the MIG example design or targeting the VC707 board, please see this :ref:`MIG overview <MIG IP Overview>`.

First, we will want to create a new Vivado project and select your preferred FPGA or board. For this article, we 
will be using the Xilinx VC707 board as our target. Then, open up a new block diagram. Under the :guilabel:`Board` tab, 
select the :guilabel:`DDR3 SDRAM` option.

.. figure:: /images/infrastructure/board_tab.PNG 
   :alt: DDR3 SDRAM
   :align: center

This will insert a MIG into the block diagram, which we can edit by double clicking on the IP. If you are not using a board,
generate a MIG 7 Series or equivalent IP using Xilinx's IP integrator. For the MIG 7 Series, modify the following fields:  

.. Important:: Unless mentioned otherwise, leave all values default.

-  Desired Clock Period → 2500ps (400MHz)
-  Data Width → 64 bit (default)
-  AXI Data Width → 64 bit
-  Input Clock Period → 5000ps (200MHz)
-  Deselect any Additional Clocks
-  Addressing → Bank/Row/Column
-  System Clock → Differential
-  Reference Clock → Use System Clock
-  Reset → ACTIVE LOW
-  Uncheck the Box for DCI Cascade
-  Select Fixed Pinout, then select Validate for the given pinout
-  In the System Signals section:

   -  Leave ``sys_clk_p`` and ``sys_clk_n`` to their default pins
   -  Assign ``sys_rst`` to *AR40* (push button)
   -  Assign ``init_calib_complete`` to *AM39* (LED)

Of course, the pinout will differ depending on the board or FPGA chosen. For more infomation on the VC707 
board pinout, see this documentation from Xilinx here: `UG885`_. 

Once these modifications have been made, the MIG IP will regenerate. Then, generate the IP example design by 
right-clicking on the IP block and selecting :guilabel:`Generate IP Example Design`. As before, this will open up a project 
in Vivado with the MIG IP example design, which we can set aside for the moment.

Now, we will also need to generate the IP example design for the AXI Memory Mapped to PCI Express core. 

.. Note:: For a refresher on generating the AXI Memory Mapped to PCI Express example design, please see this :ref:`PCIe overview <AXI PCIe Overview>`.

Click on the :guilabel:`+` icon to add IP to the block design, then select :guilabel:`AXI Memory Mapped to PCI Express`. 
Make the following changes to the core: 

.. Important:: Unless specified, please leave everything as default.

-  Reference Clock Frequency → 100MHz
-  Check the box to enable External PIPE Interface (this helps to speed up the simulation time)

.. figure:: /images/infrastructure/pcie_customization_with_pipe.PNG 
   :alt: PCIe Customization Pipe
   :align: center

   PCIE:Basics Customization

-  Lane Width → X8
-  Link Speed → 2.5GT/s
-  In the PCIE BARs section, ensure only 1 BAR is enabled and that it is 16KB in size with offset at address 0x00000000.

.. figure:: /images/infrastructure/pcie_customization_bars.PNG 
   :alt: PCIe Customization Bars
   :align: center

   PCIE:BARS Customization

Once this core has been generated, generate an example design for this IP as well. Now that the example 
designs have been generated for both the MIG and the PCIE IPs, we are ready to move onto the next section.

.. _BASIC PCIe MIG Block Diagram:

Creating the Block Diagram
--------------------------

Like we did in the :ref:`section 2.4 <AXI MM PCIe MIG Replacement Design>` of the AXI MM to PCIe IP Overview, 
the first step that we will do is comment out the BRAM instantiation from the top file of the PCIE example design 
(``xilinx_axi_pcie_ep.v``). However, instead of inserting a MIG into its place, we are instead going to create 
a new block diagram. In the end, this is what we want the block diagram to look like:

.. figure:: /images/infrastructure/vc707_mig_bram_block_diagram.PNG 
   :alt: MIG BRAM Block Diagram
   :align: center

   Combined block diagram

In order to create this block diagram, follow these instructions:

   1. Add an AXI Smartconnect IP to the block design with two AXI Master outputs and one AXI Slave input.  
      Make sure that the data width is set to at least 32 bits, and make sure that there are two clock inputs.

   2. Make the S00_AXI, aclk, and aresetn ports external, as these will connect back into our PCIe core.
      
   3. Add a MIG 7 Series IP to the block design from the **Board** tab, and make sure to customize it in the 
      EXACT SAME way as the MIG you customized in the previous section.  This will ensure that the example 
      design we generated will have the correct parameters associated with it.
   
   4. Make the ``SYS_CLK``, ``sys_rst``, ``aresetn``, ``DDR3``, ``ui_clk_sync_rst``, ``ui_clk_``, ``mmcm_locked``,
      and ``init_calib_complete`` pins external, as these will be handled by our MIG example design. The ``SYS_CLK`` 
      and ``DDR3`` pins should already be external, but to keep the same naming convention, delete the previous 
      external connections, and then right-click to make them external again.

   5. Add an AXI BRAM controller IP to the block design, and make sure to set the interface type to AXILite 
      and Data Width to 32 bits.  This BRAM represents the replaceable DUT that we should be able to exchange 
      with a custom design later.

   6. Connect the ``M00_AXI`` port from the Smartconnect to the ``S_AXI`` port on the MIG, and connect the 
      M01_AXI port from the Smartconnect to the S_AXI port on the BRAM controller.

   7. Connect the ``ui_clk`` from the MIG to the ``aclk1`` port on the Smartconnect and the ``s_axi_aclk`` 
      port on the BRAM controller.  This way, the example DUT will be in the same clock domain as the MIG.

   8. Connect the ``s_axi_aresetn`` port on the BRAM controller to the external aresetn signal going into the MIG.  
      This way, the example DUT reset will be synchronous with the MIG reset.

   9. Finally, there should be an option at the top of the screen to :guilabel:`Run Connection Automation`, 
      and doing this should insert the Block Memory Generator, which will be attached to the BRAM controller.


Now that the block diagram has been created, we will need to use the address editor to assign the MIG and BRAM 
locations in the AXI memory space.  Click on the :guilabel:`Address Editor` tab, and edit the offset addresses 
as follows:

-  MIG: size 8KB, range: 0x0000_0000 to 0x0000_1FFF
-  BRAM: size 8KB, range: 0x2000_3FFF

.. figure:: /images/infrastructure/mig_bram_address_editor.PNG 
   :alt: BRAM Address Editor
   :align: center

   Address Editor for MIG and BRAM

If we click on the :guilabel:`Address Map` tab, then we can even see a layout of the memory mapping:

.. figure:: /images/infrastructure/mig_bram_address_map.PNG 
   :alt: Address Map
   :align: center

   Address Map for MIG and BRAM

Since we configured the PCIe to have a 16KB BAR from address 0x0000_0000 to 0x0000_3FFF, we should now be able to access 
both of our AXI slaves from within the PCIE memory space. 

Finally, we can go ahead and right-click on our block diagram and select :guilabel:`validate design`. There might be a warning that
the resets are not synchronous - this is because we have not connected the PCIe IP to the design yet, so we can ignore this for now.
Once Validation is successful, we will need to right-click on the block design under the :guilabel:`Sources` menu, 
and select :guilabel:`Create HDL Wrapper`.  Just like before, this will generate an RTL wrapper file for this 
block diagram, which we can instantiate into our PCIe example design in the next section.

.. _BASIC Connecting MIG PCIe BRAM:

Connecting it All Together
--------------------------   

Similar to :ref:`section 2.4 <AXI MM PCIe MIG Replacement Design>`, we will now need to instantiate our block diagram into 
the PCIe example design.  Since this process has several steps involved with it, we will include the design, 
constraints, and simulation top file here. This next section will be a brief overview of the steps needed to combine the 
PCIe example design, the MIG example design, and the block diagram.

First, we will need to correctly instantiate the block design wrapper file into the PCIe example top file. In order 
to do this, we can locate where we commented out the old BRAM instantiation, and instead instantiate the block design.

.. figure:: /images/infrastructure/DUT_instantiation_part_1.PNG 
   :alt: DUT instantiation part 1
   :align: center

   Instantiating the BD [replace with code]

.. figure:: /images/infrastructure/DUT_instantiation_part_2.PNG 
   :alt: dut instance pt2
   :align: center

   [code here]

Then, we will need to copy all of the relevant parameters, wires, functions, inputs, and outputs from the MIG example 
design top file into the PCIe example design top file [INSERT CODE HERE].  

.. Note:: The following fields had to be changed because of already existing fields in the PCIe example design.

-  Parameters: ``TCQ`` → ``TCQ_MIG``
-  Inputs: ``sys_clk_n`` → ``sys_clk_n_mig``
-  Outputs: ``sys_clk_p`` → ``sys_clk_p_mig``

Make sure to copy over the statement that synchronizes the MIG reset:

.. figure:: /images/infrastructure/mig_reset.PNG 
   :alt: mig reset
   :align: center
   
   [replace with code]

Then, we will need to copy over the top-level constraints from the MIG example design and paste them into the top-level 
constraints file for the PCIe example design.  The top level constraints for each project can be found under the 
:guilabel:`Constraints` tab in the :guilabel:`Sources` menu.

.. figure:: /images/infrastructure/constraints_from_mig_example.PNG 
   :alt: mig constraints
   :align: center

   [replace with code]

Once the top file and the constraints file have been modified, then we can run synthesis and implementation 
to ensure that there are no errors in our design. Refer to the TCL console and the Xilinx forums for help with debugging, 
as every board/FPGA has different parameters, or cross reference your design and constraints top file with the provided 
example files above.
   
Once synthesis and implementation are complete, your schematic should look something like this. Once synthesis and 
implementation are complete, we can now move on to the next section.

.. figure:: /images/infrastructure/vc707_pcie_mig_bram_schematic.PNG 
   :alt: MIG BRAM schematic
   :align: center

   Example schematic of infrastructure BD

.. _BASIC Modifying Simulation:

Modifying and Running the Simulation
------------------------------------

Just like the example in :ref:`section 2.5 <Simulating AXI MM PCIe MIG>` of the AXI MM to PCIE IP Overview, the first step 
to running our simulation is to import the correct simulation files from the MIG example project (``ddr3_model.sv``, 
``ddr3_model_parameters.vh``, and ``wiredly.v``).  For more information on how to import these files, please reference that section.

Now, we will need to edit our simulation top file to accommodate the MIG and DDR3 memory model, as well as include our 
block diagram from earlier. 

.. Important:: You can download the top file :download:`here </examplefile.v>` [upload top here].

Some notes about the modifications made to the PCIe example design top file:

-  Parameters changed:

   -  ``TCQ`` → ``TCQ_MIG`` (duplicate name)
   -  ``ADDR_WIDTH`` → ``ADDR_WIDTH_MIG`` (duplicate name)
   -  ``RESET_PERIOD`` = 100 (convert to nanoseconds)

-  Wires/Regs changed:

   -  ``sys_rst_n`` → ``sys_rst_n_mig`` (duplicate name)

-  Variables changed:

   -  In the memory model instantiation, the variable *i* had to be changed to *s* due to a duplicate name

 .. figure:: /images/infrastructure/change_i_to_s.PNG 
   :alt: Changing i to s
   :align: center

   [change to code]

-  MIG input system and reference clocks:
   -  Due to timescale issue (MIG simulation top file is in picoseconds, PCIe simulation top file is in nanoseconds), 
      We were forced to change the system and reference clocks to run at 250MHz instead of 200MHz (4ns period instead of 5ns period).  
      This in turn causes the MIG ui_clk to run at 125MHz instead of 100MHz. However, everything in the simulation should 
      still run fine.

 .. figure:: /images/infrastructure/vc707_mig_bram_timing_issue.PNG 
   :alt: mig input system and ref clk
   :align: center 

   [replace with code] 
  
-  Instantiations included:

   -  Top file from design sources
   -  DDR3 memory model
   -  Wire delay modules

-  In order to determine when init_calib_complete goes HIGH for the MIG, a simple check that displays “MIG Calibration Done” when 
   this event occurs was added.

.. figure:: /images/infrastructure/check_for_mig_calibration.PNG 
   :alt: MIG Calibration Done
   :align: center 

   Finished MIG calibration [replace with code]

Now, if we were to click :guilabel:`Run Behavioral Simulation`, the standard PCIe example simulation would run, which would simply 
perform a read and a write to address ``0x0000_0010``. For debugging purposes, it may be smart to try and run this simulation to make 
sure that everything is set up properly.  However, we want to be able to read and write our own data to our own specific addresses.  
In order to do this, we will need to edit the simulation header file called ``sample_tests1.vh``.  This file can be located in the 
:guilabel:`Verilog Header` folder within :guilabel:`Simulation Sources`.

.. Important:: You can download the custom header file :download:`here </examplefile.v>` [upload header here].
         
Under the comment that says “MEM 32 SPACE” in the BAR Testing section, a 60us delay is included to allow for the MIG to 
finish calibrating before attempting to read and write from it. The predefined tasks ``TSK_TX_BAR_WRITE`` and ``TSK_TX_BAR_READ``
perform the custom reads and writes. The definitions of these tasks can be found in the ``pci_exp_usrapp_tx.v`` file contained within 
the Root Port simulation model.
         
To test the MIG, the sample data *0xABCD_BEEF* was written to address ``0x0000_0010``, which corresponds to address ``0x0000_00010``
on the MIG.  If the read data equals the written data, then the message *MIG Test Passed* will appear in the TCL console.

.. figure:: /images/infrastructure/custom_mig_test.PNG 
   :alt: MIG Test Passed
   :align: center 

   MIG Test Passed [replace with code]

In order to test the BRAM controller (aka the DUT), I sent the data ``0x1234_4321`` to address 0x0000_2000, which should correspond 
to address ``0x0000_0000`` on the BRAM controller.  If the read data equals the written data, then the message “BRAM Test Passed” will 
appear in the TCL Console.

.. figure:: /images/infrastructure/bram_custom_test.PNG 
   :alt: BRAM custom test
   :align: center 

   BRAM Custom Test [replace with code]

Now that we have built our simulation environment, we can go ahead and Run Behavioral Simulation.  

.. Note::  If the simulation fails to launch, the TCL console will direct you to the location of a log file that will provide more 
specific error-related information for debugging.

The simulation should automatically pause itself after 1 nanosecond, and this is a good time to add the desired waveform signals 
into the simulation window.  This can be done by navigating to the :guilabel:`Scope` window, right clicking on the signals you 
would like to see, and then clicking :guilabel:`Add to Wave Window`.  I would personally recommend adding the signals from the 
:guilabel:`XILINX_AXIPCIE_EP` file, the :guilabel:`axi_bram_ctrl_0` file, and the :guilabel:`mig_7series_0` file as shown in the image below.

.. figure:: /images/infrastructure/vc707_mig_bram_scope.PNG 
   :alt: BRAM Scope
   :align: center 

   BRAM Scope

Once we’ve added the correct signals, we can click on the green play button at the top left corner of the screen to resume the simulation.

.. Note::If the simulation stops early (before 100us) due to a timeout error from one of the PCIE root port files, we can go ahead and just 
click the green play button to force the simulation to resume anyways.  If this becomes bothersome, we can comment out the timeout error 
from occurring like this:
.. figure:: /images/infrastructure/Inkedcomment_out_simulation_timeout_LI.PNG 
   :alt: Comment out timeout error
   :align: center 

   Comment out timeout error

Finally, the simulation should conclude around 110 us, and if you see the following messages in the TCL console, then the simulation was a success!
.. figure:: /images/infrastructure/mig_test_passed.PNG 
   :alt: MIG test Passed
   :align: center 

   MIG Test Passed

.. figure:: /images/infrastructure/bram_test_passed.PNG 
   :alt: BRAM Test Passed
   :align: center 

   BRAM Test Passed

Additionally, we can view the AXI transactions in the simulation window.  One important thing to notice is that the PCIE sent a write transaction 
to address ``0x0000_2000`` for the BRAM test, but because of the address offset that we specified for the BRAM controller back in the block diagram 
stage, the BRAM received this write request at address ``0x0000_0000``.  This is how we will be able to use the PCIE to read and write to multiple 
slave devices simultaneously.

.. figure:: /images/infrastructure/vc707_bram_mig_waveform.PNG 
   :alt: BRAM MIG Waveform
   :align: center 

   BRAM MIG Waveform

.. _BASIC Timing Power IO:

Checking Timing, Viewing Power Reports, Monitoring I/O Placement:
-----------------------------------------------------------------
After running through synthesis and implementation, Vivado provides us with several tools that we can use to monitor important factors of our 
design such as timing, power, and I/O placement.

The first category that we can take a look at is the Timing section.  In this Design Timing Summary, we can see several aspects of our timing 
report, such as the total number of endpoints, worst negative slack, and most importantly, whether our device meets timing or not.  
In this example, we can see that our device successfully meets all of the timing requirements as shown in the figure below.

.. figure:: /images/infrastructure/timing_constraints_met.PNG 
   :alt: Timing Summary Met
   :align: center 

   Timing Summary Met

If we click on the :guilabel:`Check Timing` tab on the left side of the screen, it will show us a more detailed layout of the timing summary

.. figure:: /images/infrastructure/check_timing_summary.PNG 
   :alt: Check Timing Summary
   :align: center 

   Check Timing Summary

In this case, we can see that there are 4 total errors with our timing:  2 ``no_input_delays`` and 2 ``no_output_delays``.  If we click on 
those respective sections on the left side of the screen, we can see which exact ports are afflicted by these errors.  However, since all 
of the timing constraints are still met within the design, it is alright to ignore these errors.

This is also the place where we would see if any clocks were not properly constrained.  If this were the case, we would usually see a large 
amount of errors under the no_clock category.

If any of these errors were preventing our design from meeting timing, we can use the :guilabel:`Vivado Timing Constraints Wizard` to help us 
write clock constraints to fix these errors.  In order to access the wizard, open up the implemented design, click on the :guilabel:`Tools` menu 
at the very top of the screen, and then click on ``Timing`` → ``Constraints Wizard``.  

.. Note:: If you do decide to use the timing constraints wizard, it will automatically write the constraints for you based on the clocks you need 
to define, and it will **OVERWRITE** any constraints that you already have in your target constraints file.  Personally, I would recommend copying 
and pasting the text from your target constraints file somewhere safe before running the wizard.

To check the :guilabel:`Vivado Power Report` for our design, click on the ``Power`` tab within the implemented design.

From here, we can see additional information relevant to the on-chip power required for implementation, as well as the power distribution for each 
FPGA primitive used in order to build the design (clocks, PLLs, I/O, BRAM, etc.)

.. figure:: /images/infrastructure/power_summary.PNG 
   :alt: Power Summary
   :align: center 

   Check Power Summary

In this case, we can see that the total on-chip power required is 4.512 Watts, which is broken down into the individual FPGA components in the 
diagram to the right.

One other very handy tool that Vivado provides for us is the ability to view and modify the I/O planning of the design.  In order to access the 
I/O planning page, open up the implemented design, select the :guilabel:`Layout` menu at the very top of the screen, and then select :guilabel:`I/O Planning`.

This should open up a new tab on the Implemented design called ``I/O Ports``, and navigating through this tab allows you to view all of the pin 
locations defined within your constraints, as well as their respective location within the FPGA

.. figure:: /images/infrastructure/io_pin_planning.PNG 
   :alt: IO Pin Planning
   :align: center 

   IO Pin Planning

Similar to the :guilabel:`Timing Constraints Wizard`, we can manually assign the input/output ports of our designs to any respective package 
pin port, and the Vivado tool will write the constraints for us.  However, it will also overwrite any previously written constraints, so always 
make sure to copy and paste your top level constraints somewhere safe before saving any edits.

Other things that we can do within this window include setting the I/O Std type and enabling/disabling pullup resistors.


.. all links 

.. _UG885: https://www.xilinx.com/support/documentation/boards_and_kits/vc707/ug885_VC707_Eval_Bd.pdf