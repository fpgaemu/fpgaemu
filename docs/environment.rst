.. _Environment Overview:

===================================================
Building an Emulation Environment (without a Board)
===================================================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient!

.. Important:: This guide uses Vivado 2020.2, so while the software and IPs will change in the future, underlying principles will remain the same.

Create a new project and select your project device. For this article, we will assume that no pre-existing board 
files will be useed, except for the MIG's UCF constraint file. For example, we will use the Virtex-7 690T FPGA for
this design (similar to the NetFPGA-SUME development board from Digilent which both has DDR3 SoDIMM memory and 
8x Gen.3 PCIe) which at the moment does not have prepackaged board files in a standard Vivado installation. This 
design should also work with Vivado's WebPACK version (eg. you can use the Kintex-7 XCKU025 which is compatible
with all IPs), given you have access or are willing to write UCF and XDC constraints.

As such, we will not include any source files within this article. We encourage you to step through and generate the design
yourself, as parameters will vary between FPGAs.  

.. _Environment Block Diagram:

Creating the Block Diagram
--------------------------

