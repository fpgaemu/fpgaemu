.. _Counter:

=================
First IP: Counter
=================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient! 

.. _Packaging Custom IP:

Packaging Custom IP
-------------------

AXI text 

.. _Simple Counter:

Simple 8-Bit Counter
--------------------

Verilog text here

.. code-block:: verilog

    `timescale 1ns/1ps

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

    `timescale 1ns/1ps

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