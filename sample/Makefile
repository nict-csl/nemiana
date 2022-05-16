FLAGS=-I../nemiana_os/lib/

setup:
	mkdir log

qemu_gdb:
	perl ${FLAGS} qemu_gdb.pl &> log/log1.log

verilator_gdb:
	perl ${FLAGS} verilator_gdb.pl >log/log2.log 2>&1

migration1:
	perl ${FLAGS} migration_qemu_verilator.pl >log/log3.log 2>&1

migration2:
	perl ${FLAGS} migration_verilator_qemu.pl >log/log4.log 2>&1

core1:
	perl ${FLAGS} core_gdb.pl --outdir=res/test5 --target_dir=../target/sample3 --verilator_dir=../verilator --infile=client_data0.txt --platform=QEMU    >log/log5.log 2>&1

core2:
	perl ${FLAGS} core_gdb.pl --outdir=res/test5 --target_dir=../target/sample3 --verilator_dir=../verilator --infile=client_data0.txt --platform=Poyov    >log/log5.log 2>&1


filesys:
	ln -s ../eval/chap4/filesys .

xilinx_gdb: filesys
	perl ${FLAGS} fpga_gdb.pl >log/log6.log 2>&1

clean:
	rm -rf res log/*.log


