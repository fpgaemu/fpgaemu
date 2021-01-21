.. _AXI Protocol Overview:

=====================
AXI Protocol Overview
=====================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient! 

.. _AXI Protocol:

The AXI Protocol
----------------

When building your first block diagram or reading the documentation of Xilinx's IP cores, 
you may notice one thing in common -- they all use the AXI protocol. This article will 
provide a brief explanation about what AXI is and how it functions. 

The *Advanced eXtensible Interface*, or **AXI**, protocol is a royalty-free communication 
standard developed by ARM, a prolific system-on-chip (SoC) company, as part of the AMBA 
(Advanced Microcontroller Bus Architecture) standard. You can find more information about 
AMBA and its other protocols (such as AHB or APB) `here <https://developer.arm.com/architectures/system-architectures/amba>`_.

Essentially, the AXI protocol outlines the process by which on-chip components can communicate 
with each other using signals, usually involving a master and slave device. By standardizing 
this protocol, we can ensure every peripheral and IP core present on an FPGA will be able to 
talk to each other, creating a cohesive system (rather than a scattered collection of cores).

There are three types of AXI4 interfaces (defined by AMBA 4.0):

-   Full AXI4 - High-performance communication, using memory-mapped addresses 
    (more `here <https://geeksforgeeks.org/memory-mapped-i-o-and-isolated-i-o/>`_).

-   AXI-Lite - Lightweight and simple memory-mapped interface, used for single transaction communication.

-   AXI4-Stream - 'Direct' device communication, removing the need for addresses and allowing 
    for maximum data transfer.

For the remainder of this article and throughout our projects, we will mainly focus on Full 
AXI4 for the best performance-cost ratio. 

.. _AXI Reads Writes:

AXI Reads and Writes
--------------------

.. sidebar:: Memory Addresses
    :subtitle: *Example of how AXI can control devices using addresses.*

    Both pure data and commands (like toggling an LED) can be sent on the data bus.

    +---------+---------+
    | Address | Purpose |
    +=========+=========+
    | 0x00000 |  Config |
    +---------+---------+
    | 0x10000 |   LED1  |
    +---------+---------+
    | 0x20000 | DDR Reg |
    +---------+---------+

AXI4 allows for multiple data transfers over a single request, allowing for greater data bandwidth in the 
scenario where large amounts of data must be transferred to/from specific addresses. This multi-transfer
request is also known as a *burst*. 

All AXI communication is with respect to memory addresses, which each have a specific purpose defined
by the RTL and top module. 

Three burst types are supported - **FIXED**, **INCR**, and **WRAP**. Each one alters the transfer address in 
a specific way, allowing for optimal transfers in different situations. For example, a FIXED burst sets 
every beat to have the same address, which is useful for memory transfers from the same repeated location.

In general, burst addressing specifies where each read or write should be performed in which addresses. Each
burst type is as follows [1]_:

.. figure:: /images/axi4/AXI_Bursts.svg
    :alt: AXI Bursts 
    :align: center
    :width: 65%

AXI4-Lite has no burst protocol (only sending one piece of data at a time) while AXI4-Stream acts as a 
single unidirectional channel for unlimited data flow between a master and slave, removing the need
for addresses.

.. _AXI Connections Channels:

AXI4 Connections and Channels
-----------------------------

In its most basic configuration, the AXI protocol connects and facilitates communication 
between one master and one slave device. As expected, the master initiates and drives data 
requests, while the slave responds accordingly. This communication, or transactions as we 
will now refer to, occurs over multiple channels, each one dedicated to a specific purpose. 

.. figure:: /images/axi4/AMBA_AXI_Handshake.svg
    :alt: AXI handshake
    :align: right

The sender must always assert a VALID signal before the receiver, and keep it HIGH until the 
handshake is completed. By using handshakes, the speed and regularity of any data transfer 
can be controlled.

There are five channels, each one transmitting a data payload in one direction. Each channel 
implements a handshake mechanism, wherein the sender drives a VALID signal when it has prepared
the payload for delivery and the receiver drives a READY signal in response when it is ready to
receive the data. The data transfer is also known as a *beat*. 

The five AXI4 channels are as follows:

-   Write Address channel (AW): Provides address where data should be written (``AWADDR``)
  * Can also specify burst size (``AWSIZE``), beats per burst (``AWLEN`` + 1), burst type (``AWBURST``), etc.
  * ``AWVALID`` (Master to Slave) and ``AWREADY`` (Slave to Master)

.. figure:: /images/axi4/axi4_channel.jpg
    :alt: AXI Channels
    :align: right

-   Write Data channel (W): The actual data sent (``WDATA``)
  * Can also specify data and beat ID
  * Sender will always assert a finished transfer when done (``WLAST``)
  * ``WVALID`` (Master to Slave) and ``WREADY`` (Slave to Master)

-   Write Response channel (B): Status of write (``BRESP``)
  * ``BVALID`` (Slave to Master) and ``BREADY`` (Master to Slave)

-   Read Address channel (AR): Provides address where data should be read from (``ARADDR``)
  * Can also specify burst size (``ARSIZE``), beats per burst (``ARLEN`` + 1), burst type (``ARBURST``), etc.
  * ``ARVALID`` (Master to Slave) and ``ARREADY`` (Slave to Master)

-   Read Data channel (R): The actual data sent back
  * Can also send back status (``RRESP``), data ID, etc. 
  * Sender will always assert a finished transfer when done (``RLAST``)
  * ``RVALID`` (Slave to Master) and ``RREADY`` (Master to Slave)

Here is an example of a typical read/write AXI transaction. 

-   To write, the master first provides the address (0x0) to write to, as well as the aformentioned 
    data specifications (4 beats of 4 bytes each, data type of INCR). Both the master and slave 
    then exchange a handshake for verification.

-   The master then prepares and writes the actual data payload to send over the channel (0x10, 0x11
    0x12, and 0x13), again using a handshake to verify the transfer. The master will signal the 
    end of the payload to the slave using ``WLAST``. 

-   The slave responds with a status of the write and whether it was successful or a failure (all 
    OKAY in this case) and finishes the entire transaction with another handshake. 

.. figure:: /images/axi4/AXI_write_transaction.svg
    :alt: AXI Write Transaction
    :align: center

    A typical AXI Write transaction

-   To read, the master first provides the first address to read from (0x0), as well as the 
    aformentioned data specifications (4 beats of 4 bytes each, data type of INCR). The usual 
    handshake occurs. 

-   The slave then provides the actual data payload, as well as the status of each beat (all 
    beats are OKAY). The slave will signal the end of the payload to the master using ``RLAST``.
    As we can see, what was written to the specified addresses was the same as what was read back.

.. figure:: /images/axi4/AXI_read_transaction.svg
    :alt: AXI Ready Transaction
    :align: center

    A typical AXI Read transaction

.. _AXI Interconnect SmartConnect:

AXI Interconnect vs. SmartConnect
---------------------------------

Smart

.. _AXI Verification IP:

AXI Verification IP
-------------------

VIP

References
----------

.. [1] AXI example images used from Wikimedia Commons and the `AXI Article <https://en.wikipedia.org/wiki/Advanced_eXtensible_Interface>`_.

