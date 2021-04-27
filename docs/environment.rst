.. _Environment Overview:

===================================================
Building an Emulation Environment (without a Board)
===================================================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient!

.. Important:: This guide uses Vivado 2020.2, so while the software and IPs will change in the future, underlying principles will remain the same.

Create a new project and select your project device. For this article, we will assume that no pre-existing board 
files will be used, except for the MIG's UCF constraint file. For example, we will use the Virtex-7 2000T FPGA for
this design (similar to the HTG-700 development board from HTG which both has DDR3 SoDIMM memory and 
8x Gen.3 PCIe) which at the moment does not have prepackaged board files in a standard Vivado installation. This 
design should also work with Vivado's WebPACK version (eg. you can use the Kintex-7 XCKU025 which is compatible
with all IPs), given you have access or are willing to write UCF and XDC constraints.

As such, we will not include any source files within this article, except our example AXI counter. 
We encourage you to step through and generate the design yourself, as parameters will vary between FPGAs.  

Here is a companion video with the Virtex-7 2000T that can be used alongside this article for further clarification.

.. raw:: html

    <iframe width="560" height="315" src="https://www.youtube.com/embed/gzKnDeXDbJw" 
    frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; 
    gyroscope; picture-in-picture" allowfullscreen></iframe>
    
.. _Environment Block Diagram:

Creating the Block Diagram
--------------------------

