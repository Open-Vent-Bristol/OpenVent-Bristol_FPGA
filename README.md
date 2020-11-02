# OpenVent-Bristol FPGA Project
This repository contains the code associated with the OpenVent-Bristol FPGA. 

## Prerequisites
GOWIN 1.9.7\
Tcl >= 8.6\
Currently we use Vivado 2019.1 for simulations. You must install the Xilinx tools to _C:\Xilinx_ or _\Xilinx_.

## Simulations
_cd scripts_\
_tclsh sim.tcl <module_name>_\
_run 100 ms_\
The simulation uses a fatal error to end, and the way Xilinx handles this is strange. Send the tcl command line simulation task (the one with the progress bar) to the background, and close (X out) the two Unable to Open File error dialogues. Vivado will then open the file that ends the simulation in a new tab (tb_h.vhd), and you can look at waveforms in the other tab.
