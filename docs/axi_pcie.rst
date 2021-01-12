.. _AXI_PCIe:

==========================
AXI MM to PCIe IP Overview
==========================

The AXI Memory Mapped to PCI Express IP is a useful core that is compatible with only some FPGAs, 
offering a different implementation than that offered by the 7 Series Integrated Block for 
PCIe IP. More information can be found in the IP's documentation (`PG055`_).

Customizing the IP
------------------

Create a new block diagram (BD) and use the IP catalog to add a new IP to the BD - in this case, the 
"AXI Memory Mapped to PCIe" core. We can customize it by double clicking it. 

.. Important:: Unless mentioned otherwise, leave all values default.

-   In the PCIE:Basics tab, set the Reference Clock frequency to 100 MHz.

-   Make sure we are customizing the device as an Endpoint. 

-   Depending on the application, in the PCIE: Link Config tab, change the Land Width. Most boards
    support at least X4, although newer boards will support X8. In addition, select the highest possible 
    Link Speed for maximum performance.

-   Again, depending on the application, you may change the Vendor ID and Class Code to something else.
    For example, if you plan to use this IP in conjunction with a soft CPU like Microblaze, you would
    change the Class Code to 0x060400 accordingly. If not, leave the entire tab default. 

-   In the PCIE:BARs tab, set BAR 0 at a size of 64 kB at offset address 0x00000000 and BAR 1 at 
    size 64 kB at address 0x40000000.

-   Every other tab can be left default.

Simulating the Example Design
-----------------------------

After customizing, right click the IP block and open the IP Example Design. 

The Example Design consists of the AXI MM to PCIe IP block connected to both a Block RAM (BRAM) 
Controller through the PCIe's AXI Master port and a Root Complex simulation on the PCIe's physical
serial ports. Essentially, the example design simulates a host PC generating and sending traffic
into the FPGA through the PCIe interface. The AXI MM to PCIe IP processes the incoming traffic 
and writes into BRAM using the AXI protocol. 

.. image:: /images/pcie/example_bd.png

.. Note:: If you need a refresher on the PCIe protocol or want to learn more about the IP, check here: :ref:`PCIe`.

Like the MIG design, the PCIe example design must first spend 175 us calibrating and initializing
its serial ports. It then performs a simple write to address 0x10 in BRAM and subsequently reads
it back, verifying that the read data matches what was written. 

The PCIe serial ports take much longer to initialize than the MIG's. If you run a Behavioral Simulation,
do not be surprised if nothing happens at first. The simulation may stall after returning the message
*Built simulation snapshot board_behav*. Since, by default, the simulation only runs for less
than 1 us, simply use the command ``run -all`` in the TCL console to allow the serial lines to start
toggling and the simulation to fully complete. 

After around 30 minutes to 1 hour, you should receive a message in the console stating that the testbench
has timed out. If the simulation is successful, the TCL console will also show that the test passed.

.. Note:: The simulation will only work for one registered BAR in the IP. If you customized your IP to have multiple BARs, like we did, you will receive a message that the second BAR was disabled for this simulation.

.. code-block:: TCL
    :emphasize-lines: 6, 8

    [   207869316] : TSK_PARSE_FRAME on Receive
    [   209749220] : Transmitting TLPs to Memory 32 Space BAR 0
    [   209767229] : TSK_PARSE_FRAME on Transmit
    [   209805308] : TSK_PARSE_FRAME on Transmit
    [   212125269] : TSK_PARSE_FRAME on Receive
    [   213797220] : Test PASSED --- Write Data: 01020304 successfully received
    [   213837220] : Finished transmission of PCI-Express TLPs
    Test Completed Successfully
    $finish called at time 213837220 ps : File "..."
..

Example IP Block Diagram
------------------------

After running Block and Connection Automation, the AXI MM to PCIe IP example BD will look
similar to this:

.. image:: /images/pcie/example_ip_bd.png

-   The PCIe Reference Clock (``REFCLK``) at 100 MHz will go through an IBUFDSGTE Utility Buffer.

-   The physical ``PERST`` (PCIe reset) pin is connected to a Processor System Reset IP, 
    with the output going into the ``axi_aresetn`` port.

-   The ``INTX_MSI_Request`` port is connected to a Constant block tied active LOW (0) to prevent 
    unwanted MSI interrupts.

-   The ``M_AXI`` port feeds into an AXI SmartConnect, where our AXI Slave devices are connected. 
    The other AXI slave at this moment is a basic AXI Verification IP (VIP).

-   The ``S_AXI_CTL`` port can be used as an AXI Slave port to perform reads and writes to the PCIe
    Configuration Space.

-   The ``axi_aclk_out`` port outputs a clock frequency of 125 MHz, which is the frequency that the 
    AXI MM to PCIe Core operates at. It is currently clocking the SmartConnect and AXI VIP, which 
    is typically not recommended (should use a Clocking Wizard for all other peripherals).

-   The ``pcie_7x_mgt`` ports are all external ports that connect to the physical PCIe port. They control
    the serial transactions between the root complex and PCIe endpoint.

To ensure that our customized BARs are accurately reflected in our AXI Slave devices, we must assign 
the correct addresses using the Address Editor. Map the ``S_AXI_CTL`` slave to address 0x00000000 and 
the AXI VIP slave to address 0x40000000. 

.. image:: /images/pcie/bd_address_editor.png

Replacing the BRAM with DDR MIG in Example Design
-------------------------------------------------

Similar to the previous MIG example design :ref:`MIG IP Overview`, we will remove the instantiation of the 
BRAM Controller in the PCIe top file.

..
   comment all links

.. _PG055: https://www.xilinx.com/support/documentation/ip_documentation/axi_pcie/v2_8/pg055-axi-bridge-pcie.pdf