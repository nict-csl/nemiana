###
### 2021/10/22
###


GCC_HEAD=/opt/rv32/bin/riscv32-unknown-elf
OBJDUMP=${GCC_HEAD}-objdump
OBJCOPY=${GCC_HEAD}-objcopy
LD=${GCC_HEAD}-ld
CC=${GCC_HEAD}-gcc

TARGET=app
MACHINE=sifive_e

QEMU=qemu-system-riscv32
TOOLS_ROOT = ../bin
TARGET_DIR = ../hex
HEX_CONVERTER = perl $(TOOLS_ROOT)/split.pl

all: build lst 


build: ${TARGET}.elf ${TARGET}.bin

INCLUDE_ROOT=.
CFLAGS = \
	-g \
	-fno-zero-initialized-in-bss \
	-ffreestanding \
	-fno-builtin \
	-nostdlib \
	-nodefaultlibs \
	-nostartfiles \
	-I$(INCLUDE_ROOT) \
	-march=rv32i \


CRTASM = boot.s
CRTOBJ = boot.o
LDSCRIPT = linker_sifive.ld
LDFLAGS= \
	-static \

GCC_DIR=/opt/rv32
GCC_VERSION=10.2.0
LIBGCC = \
	-L$(GCC_DIR)/lib/gcc/riscv32-unknown-elf/$(GCC_VERSION) \
	-L$(GCC_DIR)/riscv32-unknown-elf/lib \
	-lm \

SRCS = notmain.c
## ライブラリが圧縮命令を使うので，独自にコンパイル
ASMS = div.S muldi3.S
OBJS = $(SRCS:.c=.o)
ASM_OBJS = $(ASMS:.S=.o)

$(CRTOBJ): $(CRTASM)
	$(CC) $(CFLAGS) -o $@ -c $<

%.o: %.c Makefile
	$(CC) $(CFLAGS) -o $@ -c $<

%.o: %.S Makefile
	$(CC) $(CFLAGS) -o $@ -c $<

${TARGET}.elf: $(OBJS) $(CRTOBJ) $(ASM_OBJS)
	$(LD) $(CRTOBJ) $(OBJS)  $(ASM_OBJS) $(LIBC) $(LIBGCC) -T$(LDSCRIPT) $(LDFLAGS) -o ${TARGET}.elf


app.bin code.bin data.bin app.srec app.dump: ${TARGET}.elf
	$(OBJDUMP) -D $< >app.dump
	$(OBJCOPY) -g -S --srec-forceS3 -O srec $< app.srec
	$(OBJCOPY) -g -S -O ihex $< app.hex
	$(OBJCOPY) -j .init -j .text -g -S --srec-forceS3 -O srec $< code.srec
	$(OBJCOPY) -j .rodata -j .eth_frame -j .data -g -S --srec-forceS3 -O srec $< data.srec
	$(OBJCOPY) -j .init -j .text -g -S -O binary $< code.bin
	$(OBJCOPY) -j .rodata -j .eth_frame -j .data -g -S -O binary $< data.bin

code.hex data.hex: ${TARGET}.srec
	${HEX_CONVERTER} <app.srec code.hex data >hex.log

deploy: code.hex data.hex
	cp  *.hex ${TARGET_DIR}

lst:
	${OBJCOPY} -g ${TARGET}.elf ${TARGET}.img
	${OBJDUMP} -D ${TARGET}.img >aaa.lst

qemu:
	${QEMU} -nographic -machine ${MACHINE} -kernel ${TARGET}.elf -singlestep -S -gdb tcp::1234 -d cpu,in_asm

qemu2:
#	qemu-system-riscv32 -monitor stdio -machine ${MACHINE} -kernel ${TARGET}.elf -singlestep -S -gdb tcp::1234 -d cpu,in_asm
	qemu-system-riscv32 -nographic -machine ${MACHINE} -kernel ${TARGET}.elf -singlestep -S -gdb tcp::1234 -d cpu,in_asm
## -monitorはQEMUのモニターをstdioにするためのオプション

gdb:
	$(GCC_HEAD)-gdb -eval-command="target remote localhost:1234" ${TARGET}.elf

gdb_serv:
	JLinkGDBServer -port 1234 -device FE310 -if JTAG -speed 4000 -jtagconf -1,-1 -autoconnect 1

upload:
	${TOOLS_ROOT}/upload.sh --hex app.hex --jlink JLinkExe

clean:
	rm -f *.elf *.hex *.dump *.lst *.img *.bin *.srec *.o
