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

.. Note:: If you need a refresher on the AXI protocol, check :ref:`here <AXI Protocol Overview>`.

.. _Simple Counter:

A Simple 8-Bit Counter
----------------------

As the FPGA 'Hello World', a simple 8-bit counter is the perfect introductory example for a 
custom IP block without the need for a development board. 

.. figure:: /images/DUT/counter_bd.jpg
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

.. |pic1| image:: /images/DUT/counter_new.png
   :alt: New counter
   :width: 20%

.. |pic2| image:: /images/DUT/counter_ports.png
   :alt: Counter ports
   :width: 30%

.. |blank| image:: /images/logos/blank.png
   :width: 15%
   :class: no-scaled-link

Make ``counter_out`` a register and add in the counter logic.

.. code-block:: verilog

    //timescale 1ns/1ps

    module counter( 
    input aclk,
    input enable, //will enable or disable count
    input aresetn, //will reset count back to start value
    input inc_dec, //will indicate wheather increment count or decrement count. inc count is 0, dec count is 1
    input [7:0] start_value, //value to start counting from
    output reg [7:0] count_out //count value
    );
  
  //local registers  
    reg [7:0] count_next; //next count value
    reg [7:0]prev_start_value=start_value;
    
    always @(posedge aclk)
        begin
        if(aresetn ==0 || prev_start_value!=start_value) //reset mode or new start value
            begin
                count_out =start_value; //reset count out to start value
                prev_start_value=start_value; //set prev start value to start value
            end 
        else //reset=1, no reset
            begin
            if(enable==1) //enable is high a
                begin
                if(inc_dec==0) begin//and incdec is low
                    count_next=count_out+1; //increment next value
                end 
                else begin //inc_dec is high
                    count_next=count_out-1; // decrement next value
                end
                    count_out=count_next; // set output equal to next value
            end
            else count_out=count_out; //same value if no enable
            end
        end                
    endmodule
..

.. topic:: Counter Testbench

    Now that we have instantiated our design, we will simulate it using a simple testbench. 

After the project opens, go to :guilabel:`Add Sources` and select :guilabel:`Add or create simulation sources`. 
Create a new file, select the desired HDL (we will use SystemVerilog here), and name the file as counter_tb. 
Our new testbench ``counter_tb.sv`` will be created. Add testbench logic --code here--

.. code-block:: SystemVerilog

        //timescale 1ns/1ps

    module counter_tb();
        //create necessary variables
        reg aclk; 
        reg enable;
        reg aresetn;
        reg inc_dec;
        reg [7:0]start_value;
        wire[7:0] count_out;

        //create DUT
        counter DUT(
            .aclk(aclk),
            .enable(enable),
            .aresetn(aresetn),
            .inc_dec(inc_dec),
            .start_value (start_value),
            .count_out(count_out)
        );

        //define clk
        always begin
            #5 //delay 5ns
            aclk=~aclk;//should be a 100MHz clk
        end

        initial begin
        //will turn in after 100ns and start inc from af for 100ns
        //then reset and new start value at c0 will increment for 50
        //disbale for 50ns
        //enable again and then decrement
            aresetn=0;//turn on reset
            enable=0;//not enabled
            aclk=0;
            start_value=8'haf;//set a start value
            inc_dec=0;//will increment
            
            #100 //100ns delay
            aresetn=1;//turn off reset
            #20
            enable=1;//turn on enable
            
            #100
            aresetn=0;
            start_value=8'hc0;//new start value
            aresetn=1; //lift the reset
            #50
            enable=0;
            #50ns
            enable=1;
            inc_dec=1;
        end
    endmodule

..

.. figure:: /images/DUT/behav_sim_diagram.jpg
    :alt: Working rollover
    :align: center

    Working Start Value, Increment, Decrement, and Enable

.. figure:: /images/DUT/counter_reset.png
    :alt: Working reset
    :align: center

    Working Reset