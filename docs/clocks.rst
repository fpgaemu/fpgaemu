.. _Clocks:

===================================
Clocks, Clocking Wizard, and Timing
===================================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient! 

Clocks and Clock Conversion
---------------------------

Square wave with 50% duty cycle, can be 0 or 1
Determines how fast the design will run, drives all sequential logic (flip-flops, RAMs, FIFOs)
Can have multiple clock domains in a single FPGA

Clock Tree
----------
A dedicated input pin is used for clock signal, dedicated routing, logic used to minimize skew

Skew is difference in time between when it arrives at one FF to when it arrives at another FF, skew should be as small as possible

Clock tree network distributes the clock via dedicated routing signals to all FFs within the design

Multiple Clocks in an FPGA
--------------------------
Best to avoid multiple clocks for beginners

Usually only need different clocks if interfacing to some external component that requires it
Ex. SDRAM, camera, special sensors
Can use phase-locked loop (PLL), takes in reference clock to branch off into a different frequency

Typically use only one clock and Clock Enable signal 
Ex. UART has 19200 baud rate but don’t need dedicated 19.2 kHz clock, just run a 50 MHz clock in intervals with counter

Never drive the clock of a FF off the output of another FF 
Use one central clock and parse through data with Clock Enable pulses
Ex. input clock of 40 MHz, ADC runs of 10 Mhz, divide input signal by 4 and pulse once during output


Propagation Delay
-----------------
Amount of time it takes for a signal to travel from a source to a destination
Rule of thumb: signals can travel one foot of wire in one nanosecond
Physical length of wires on board can be over a foot long, meaning that every portion of logic will take some finite delay time
Propagation delay directly relates to sequential logic driven by a clock

Amount of time it takes from the output of one FF to travel to the second FF is the propagation delay
The further apart or the more logic between the two FFs, the longer the delay, and the slower the clock is able to run
Both FFs use the same clock, output of first FF at clock edge 1 should drive the second at clock edge 2
2 FFs that are 10 ns apart, a 50 MHz clock (20 ns period) will be fine while a 200 MHz clock (5 ns period) is not

FPGA timing analyzer will spot any timing errors
Fix high propagation delay 
Slow down clock frequency
Break up logic into stages through pipelining 

Breaking up the logic between 3 FFs allows only half of the logic to be done between 2 FFs at a time
Tools will have almost twice as much time to execute in a single clock cycle, also known as pipelining


Setup and Hold FF Time
----------------------

Setup time - amount of time required for the input to a FF to be stable before a clock edge
Hold time - minimum amount of time required for the input to a FF to be stable after a clock edge

Setup time, hold time, and propagation delay all affect FPGA design timing
Minimum period of FPGA clock (and frequency where F = 1/T) can be calculated through tclk (min) = tsu + th + tp
Generally, setup and hold time are fixed for FFs, so propagation delay is variable
The more logic, the longer the propagation delay will be and the higher the clock period will be, leading to a slower frequency

If there are setup or hold time violations, the FF output is not guaranteed to be stable (could be 0, 1, or something else), also known as metastability
Can check for metastability through placing and routing and timing analysis


Metastability Prevention
------------------------

Clock Domain Crossing (CDC)
---------------------------
