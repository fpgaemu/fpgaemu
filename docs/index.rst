.. _Index:

==========================================
FPGAEmu: An Introduction to FPGA Emulation
==========================================

.. Note:: All pages are under construction as we work to finalize this project. Please be patient! |docs|

.. Important:: New to FPGAs or just need a refresher? Jump :ref:`here <Emulation>` first!

.. figure:: /images/logos/board_bd.png
   :alt: Complete Emulation Block Diagram
   :align: right
   :width: 80%

   Complete Block Diagram of FPGA Board

.. toctree::
   :maxdepth: 2
   :caption: Hardware Basics

   emulation
   axi
   pcie
   ddr
   clocks

.. toctree::
   :maxdepth: 2
   :caption: Software Basics

   drivers
   gui
   interface


.. toctree::
   :maxdepth: 2
   :numbered: 
   :caption: Basic Environment Infrastructure

   mig
   axi_pcie
   dma_pcie

.. toctree::
   :maxdepth: 2
   :caption: Emulation Environment

   infrastructure
   environment

.. toctree::
   :maxdepth: 2
   :numbered:
   :caption: Device Under Test

   counter
   
Indices and tables
==================

* :ref:`genindex`
* :ref:`search`

Acknowledgements
----------------

FPGAEmu was created and is maintained by a small group of collaborators. Thanks
to everyone that has contributed, including:

.. include:: CONTRIBUTORS.rst

Special thanks to our sponsors that made this all possible:

|blank| |pic1| |blank| |pic2|

.. |pic1| image:: /images/logos/University_of_San_Diego_logo.svg
   :width: 30%
   :alt: University of San Diego
   :target: https://www.sandiego.edu/engineering/

.. |pic2| image:: /images/logos/qualcomm.svg
   :width: 45%
   :alt: Qualcomm
   :target: https://www.qualcomm.com/

.. |blank| image:: /images/logos/blank.png
   :width: 7%
   :class: no-scaled-link

.. |docs| image:: https://readthedocs.org/projects/fpgaemu/badge/?version=latest
   :target: https://fpgaemu.readthedocs.io/en/latest/?badge=latest
   :alt: Documentation Status