NEMIANA_LIB_DIR=../nemiana_os/lib
PROFILE1=../profile/profile1.pl

eval1: prep1
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --outdir=res/eval1_1 --platform-from=QEMU  --platform-to=Poyov   >log/eval1_1.log 2>&1

prep1: log
	cd ../target/sample1 && make deploy
	cd ../verilator && make iana_serv

log:
	mkdir log

clean:
	rm -rf log
	mkdir log
