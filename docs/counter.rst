.. _Counter:

=============================
Creating a Custom AXI IP Core
=============================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient! 

.. _Packaging Custom IP:

Packaging Custom IP
-------------------

Xilinx provides a large library of premade IP cores that cover a multitude of applications. However,
sometimes it is best to create and modify our own cores to suit specific needs, such as creating
an emulation environment. Instead of instantiating peripherals in Verilog, we can instead take 
advantage of the plug-and-play nature of the AXI protocol to easily connect them to an AXI master
through a SmartConnect. This article will step through the process of packaging a custom 
peripheral using the IP Integrator. 

.. Note:: If you need a refresher on the AXI protocol, check here: :ref:`AXI Protocol Overview`.

.. _Simple Counter:

A Simple 8-Bit Counter
----------------------

As the FPGA 'Hello World', a simple 8-bit counter is the perfect introductory example for a 
custom IP block without the need for a development board. 

.. figure:: /images/DUT/counter_bd.png
    :alt: Counter block diagram
    :align: center

    Block Diagram of our counter

Our first device under test (DUT) will be an 8-bit counter with five inputs: ``clock``, ``enable``,
``reset``, ``increment/decrement``, and a ``start`` value, as well as one output - the current
count value. The counter will follow these conditions:

-   The ``enable`` flag, when HIGH, will allow the count to change; otherwise, it will keep the same value.
-   When a new start value is entered, the counter will automatically start incrementing or decrementing from
    that new value.
-   There is no default start value, so an initial start value must be given.
-   The ``reset`` flag will reset the count to the given start value.

To create this counter, first create a new RTL project and define its directory. For this example, we
will use the VC707 evaluation board, but other FPGA boards can be used, like the KC705. 

.. figure:: /images/mig7/board_select.png
    :alt: Board select
    :align: center

After the project opens, go to :guilabel:`Add Sources` and select :guilabel:`Add or create design sources`. 
Create a new file, select the desired HDL (we will use SystemVerilog here), and name the file as counter. 
Our new DUT ``counter.sv`` will be created. A pop-up window will appear, prompting to define a module
and specify I/O ports. Customize the counter as so and accept. 

|blank| |pic1| |blank| |pic2|

Make ``counter_out`` a register and add in the counter logic --code here--

.. code-block:: verilog

    //timescale 1ns/1ps

    module myCounter(
        input clk, rstn,
        output reg [7:0] count
    );

        always @(posedge clk) begin
            if (!rstn)
                count <= 0;
            else
                count <= count++;
        end
    endmodule
..

.. topic:: Counter Testbench

    Example testbench

SystemVerilog text here

.. code-block:: SystemVerilog

    //timescale 1ns/1ps

    module myCounter_tb;

        reg clk, rstn;
        reg [7:0] count;
        myCounter c0(.clk(clk), .rstn(rstn), .count(count));

        always 
            #5 clk =~clk;

        initial 
        begin
            clk <= 0;
            rstn <= 0;

            #20 rstn <= 1;
            #50000 rstn<= 0;
            #50 rstn<= 1;
            #20 $finish;
        end
    endmodule
..

.. figure:: /images/DUT/counter_rollover.png
    :alt: Working rollover
    :align: center

    Working Rollover

.. figure:: /images/DUT/counter_reset.png
    :alt: Working reset
    :align: center

    Working Reset

.. |pic1| image:: /images/DUT/counter_new.png
   :alt: New counter

.. |pic2| image:: /images/DUT/counter_ports.png
   :alt: Counter ports

.. |blank| image:: /images/logos/blank.png
   :width: 7%