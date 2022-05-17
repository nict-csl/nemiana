# NEMIANA(Cross-Platform Execution Migration for Debugging)

**This document is an automatic translation of Readme_jp.md in Japanese.**

## Summary

NEMIANA was able to analyze software across platforms
This support platform has the following features.

1. Obtain trace information from the CPU and restore the state at any point in time.

2. Write the restored state on another platform and resume execution.
Graying).

These two functions enable detailed analysis back to the point of failure occurrence.
It supports debugging software for embedded devices.


The NEMIANA is largely composed of two components.

1. NEMIANA-CPU : Executes a program, collects transition information, and writes state.

2. NEMIANA-OS : To reproduce a state at an arbitrary point in time from transition information and to execute migration.


NEMIANA provides migration between CPUs with the same ISA.
There is an alternative implementation of ISA called NEMIANA CPU.
In this repository, the RISC-V 32-bit basic instruction set is paired with the RISC-V 32-bit instruction set.
The following implementations are provided for the ISA platform of the elephant.

1. Implementation of software emulation by QEMU

2. Real machine mounting by evaluation board SiFive

3. FPGA implementation with Xilinx FPGA board ZCU104

4. Implementation by simulation of FPGA with Verilog simulator Verilator

Note : 3 and 4 use a CPU core implemented by the same Verilog source.

Note that in order to test 2 and 3, we need each (expensive) evaluation board.
You will also need to know about these boards. If you want to use the NEMIANA as a trial, you need to know how to use it.
A QEMU platform that allows you to run and migrate only with your hardware
It's a good idea to start with the Verifier platform.


The current NEMIANA OS is a collection of Perl libraries and small test programs.
A sophisticated front-end, like a common operating system or tool.
(shell, UI) is not provided yet, so to use the desired functionality
You will need to code in Perl, but for most of the features.
Provides test programs, so you can use them as they are or modify them.
By doing so, we can use the functions of NEMIANA.

This manual describes how to set up and use NEMIANA.
To use NEMIANA, you need to have the following knowledge.

1. Knowledge of Perl programming

2. Bare Metal Programming with RISC-V C and Assembler and GNU
Knowledge of Compile Collection (including gcc and gdb)

3. Knowledge of each platform

In particular, for 3, bare metal programming on the platform
For example, an evaluation board
In the actual implementation by SiFive, gcc and gdb for RISC-V integration are prepared by itself.
It is necessary to connect it with a USB cable and prepare an environment for JTAG debugging.
Xilinx FPGA development to try an FPGA implementation with Xilinx FPGA board ZCU104
NEMIANA has already been developed on each platform.
Because it is a system to support engineers who are debugging, it can be used on the platform.
The development and debugging environment will not be described in detail.
See the more detailed documentation provided in the form.

NEMIANA has confirmed that it works on Ubuntu 20.04 LTS.
Assuming you are running on Ubuntu 20.04 LTS. NEMIANA - Configure the OS
Perl libraries and programs are implemented in an OS independent manner so that they can be run on other operating systems.
However, I think it can be executed, but development and debugging environments for each platform are available.
I think it's hard to do.

## Contents of this repository

Source code and data necessary for execution contained in this repository are written in the paper.
We've refactored a lot of the code we implemented.
As a result, the number of bugs is drastically reduced compared to the time when the paper was written, and the operation is stable.
However, at the time of writing this paper
Operation is different. Some functions are not yet implemented. Sequential implementation is followed.
I would like to join you, so please wait patiently.

Below is a description of the directory directly under the repository.


- docker : for building docker images to make NEMIANA easier
Contains Dockerfiles.

- eval : Contains the program used to evaluate the paper.
- fpga : Contains the files used by the FPGA platform.
- nemiana _ os : Contains the NEMIANA Perl library.
- sample : Contains sample programs.
- target : Contains the RISC-V program to be debugged.
- verialtor : Includes a software simulation version of the FPGA platform with the Verilog simulator Verilator. You can experience the FPGA version without an FPGA board.


## Pre-Preparation


To use the NEMIANA, you need to make the following preparations :


STEP1. Installing Packages and Perl Libraries

STEP2. Target ISA (RISC-V) Compile Environment Deployment

STEP3. Run the target platform and prepare the debug environment

Note : In NEMIANA, the common binary compiled in 2 can be used for different platforms.
US> Migration.


Create a Docker image with these pre-requisites built into Ubuntu20.04 LTS
We have a DockerFile, which should be easy to use.

### STEP1. Installing Packages and Perl Libraries

Install the packages required for execution with the following command :

````
apt install build-essential
apt install libwww-perl
````

### STEP2. Target ISA (RISC-V) Compile Environment Deployment

Target binaries can be compiled and debugged using GCC (GNU Compile
Collection). On the Internet, for pre-built RISC-V
GCC is available, but with various options at build time.
The ISA used in NEMIANA is a RISC-V 32-bit basic instruction set.
You need a GCC that can output a binary consisting only of (RV32I). Note in particular :
I need your will.

- do not contain compression instructions (16 bit instruction set).
- must not contain floating-point instructions.
- Do not include atomic processing instructions.
- Do not include multiplication, division, or remainder operations.

Some GCC distributions on the Internet include RV32imac (32 bit basic instruction set
Atomic instruction + compressed instruction set).
However, it is not possible to use the binary compiled by this method in NEMIANA (at present).
Hmm.

We get the source from the official repository of the RISC-V community.
Here is how to do it.


````
apt install git autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
git clone https://github.com/riscv/riscv-gnu-toolchain
./configure --prefix=/opt/rv32 --enable-multilib --with-arch=rv32i --with-abi=ilp32
make
````

Making takes a few hours even on a fairly fast machine.

After you finish making, compile the sample programs in this repository to make sure they are installed correctly.


### STEP3. Preparation of Execution and Debug Environment for Each Implementation

For each implementation type, an execution and debugging environment is prepared. In NEMIANA, basically
It is intended to support debugging of binaries executed by baremetal.
Compile and run baremetal binaries in the environment you installed before using NEMIANA.
Make sure you can debug it.

Here, execution and debugging in the following implementation forms supported by this repository
This section explains the minimum information about the environment.

1. Implementation of software emulation by QEMU

2. Implementation by simulation of FPGA by Verilog simulator Verilator

3. FPGA implementation with Xilinx FPGA board ZCU104

4. Real circuit board with evaluation board SiFive-Rev-B


For execution by the evaluation boards SiFive and Xilinx FPGA board ZCU104, there are two types of FPGA boards :
Expensive) The target board and its own development environment are required.
I recommend that you try it with QEMU and Verifier.


#### Platform: Software emulation implementation by QEMU

Installation of QEMU
````
apt install qemu-system-misc
````


#### Platform :  Implementation by simulation of FPGA with Verilog simulator Verilator



To install the Verifier, do the following :
````
sudo apt install verilator
````

The Verifier is installed by default in Ubuntu20.04.
Use 4.028. In the latest 4.219, the interface has been changed.
We are making sure that we do not make it.

#### Platform:Xilinx FPGA board ZCU104, FPGA implementation

In the FPGA implementation, a RISC-V core is implemented on a Xilinx FPGA board.
https://www.xilinx.com/products/boards-and-kits/zcu104.html

To run on ZCU104, you need Pynq, a Linux distribution running on an FPGA.
http://www.pynq.io/

The preparation procedure is as follows.


1. Download the SD card image from the Pynq page, write it on the SD card and start it.

2. Change the hostname to "iana".

3. Write all files contained in the fpga directory of this repository into the home directory.

````
scp -r fpga iana.local:/home/xilinx
````

Before running the example program, log into iana. NEMIANA and run the fpga version of Local-Bridge-Server.


````
ssh iana.local
cd fpga
sudo python3 serv.py design_1_sample1.bit >aaa.log
````

To execute the second target program dhystone, specify design _ 1 _ sample2. bit, and to execute the third target program dhystone, specify design _ 1 _ sample3. bit as the first argument.



#### Platform: Real circuit board with evaluation board SiFive HiFive-Rev-B

HiFive1 Rev B board from SiFive is used for the actual circuit board.
https://www.sifive.com/boards/hifive1-rev-b

To use NEMIANA for HiFive1 Rev B, use the J-Link GDB Server to connect to the core using the GDB protocol.

https://www.segger.com/products/debug-probes/j-link/tools/j-link-gdb-server/about-j-lin\
k-gdb-server/

Download it from the above page and install it.

Connect the HiFive1 Rev B board to the USB port and run it as follows.
````
cd sample
make hifive_gdb &
cd ../target/sample1
make gdb
````

## Try NEMIANA


How to use the NEMIANA is as follows.

1. Build the test target source

2. NEMIANA - Running the OS

3. Connect and debug the GDB.

4. Migrate and connect to the destination via GDB.

To try it out, you can find it in the "sample" directory.
You can use the sample program.

This is explained in the following order.


### Running the QEMU Edition

````
cd sample
make qemu_gdb &
pushd ~/target/sample1
make gdb
````
Starts gdb and returns the CPU state to the
You can access it with gdb.


### Running the Verifier
````
cd sample
make qemu_verilator &
pushd ~/target/sample1
make gdb
````
Starts gdb and returns the CPU state to the
You can access it with gdb.

### Running the Migration
cd sample
````
cd sample
make make migration1 &
pushd ~/target/sample1
make gdb
````
Starts gdb and puts it in the migrated CPU state
You can access it with gdb.
A bug caused an infinite loop in the step command.
Since no response is returned, the si command
Please execute it.
cd sample
````
cd sample
make migration2 &
pushd ~/target/sample1
make gdb
````
## Using the Docker Image

## Using the Docker Image
Change the repository to the cloned path.
Here is an example of how to run an evaluation program : "/ home/foo/this _ repository"
Change the repository to the cloned path.
cd /home/foo/this_repository/docker
````
cd /home/foo/this_repository/docker
Generate docker image from make #Dockerfile, takes quite a while.
docker run -it -v /home/foo/this_repository:/root/src nemiana_example
Cd / root/src/eval #docker Run in a shell inside a container
Make eval1 _ 1 # Run an evaluation program in a docker container
````

