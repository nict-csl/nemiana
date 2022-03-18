MODULE_DIR=mycore/poyo-v
TOP_FILE=cpu.v
TOP_MODULE=cpu

iana_serv: iana_server.cpp iana_cpu.cpp iana_cpu.h ../target/hex/app.hex
	verilator -CFLAGS -g -y ${MODULE_DIR} -top-module ${TOP_MODULE} -cc ${TOP_FILE} --exe iana_server.cpp iana_cpu.cpp
	make -C obj_dir -f Vcpu.mk

test2:iana_serv
	obj_dir/Vcpu >trace7.log

test3:iana_serv
	obj_dir/Vcpu 9000 >trace7.log 2>1


send_data:
	wget -O -  --post-data="80000004 DEADBEAF 20000004 FFFFDDDD " http://192.168.11.21:8008/writeo

clean:
	rm -rf obj_dir serv
