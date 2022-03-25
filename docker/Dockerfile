FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y build-essential libwww-perl git autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev qemu-system-misc verilator
RUN cd /root && git clone https://github.com/riscv/riscv-gnu-toolchain
RUN cd /root/riscv-gnu-toolchain && ./configure --prefix=/opt/rv32 --enable-multilib --with-arch=rv32i --with-abi=ilp32
RUN cd /root/riscv-gnu-toolchain && make
RUN rm -rf /root/riscv-gnu-toolchain
