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

clean:
	rm -rf res log/*.log


