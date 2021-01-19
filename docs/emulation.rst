.. _Emulation:

==================================
FPGA Review and Emulation Overview
==================================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient! 

.. _FPGA Summary:

What's Inside an FPGA?
----------------------

.. _Emulation Summary:

What is hardware emulation?
---------------------------

.. _Definitions Acronyms:

Quick Definitions and Acronyms
------------------------------

-   IC - Integrated Circuit
  * Collection of electronic components on a single unit, typically made from silicon, also known as a chip.
-   FPGA - Field Programmable Gate Array
  * ICs designed to be configurable by engineer after manufacturing.
-   ASIC - Application Specific Integrated Circuit
  * Highly specialized ICs dedicated to one specific application.
-   SoC - System on a Chip
  * IC that hosts an entire computer system by itself.
-   P&R - Place and Route
  * Process by which logic components are placed onto an FPGA and connected/routed together. 
-   DUT - Device Under Test
  * Any electronic part currently being tested, through emulation in our case.
-   IP - Intellectual Property
  * Commonly used electronic parts abstracted as logic blocks, provided by external companies (not the same as a patent).
-   AXI - Advanced eXtensible Interface
  * Communication standard that allows chip components to send signals to each other. 
-   MIG - Memory Interface Generator
  * Xilinx IP that allows an FPGA to read/write into DDR memory.
-   DDR SDRAM - Double Data Rate Synchronous Dynamic Random-Access Memory
  * Volatile memory IC typically used to store information that is lost when power is lost, common interfaces are DDR3 and DDR4. 
-   PCIe - Peripheral Component Interconnect Express
  * Communication network that allows an FPGA to control peripherals/communicate with a host PC.
-   TLP - Transaction Layer Packets
  * Data payloads that peripherals send through the PCIe bus.
-   DMA - Direct Memory Access
  * Xilinx IP that allows AXI peripherals to directly access memory without the help of the processor.
-   ROM - Read Only Memory
  * Flash memory that cannot be modified afterwards. 
