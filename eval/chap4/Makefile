NEMIANA_LIB_DIR=../nemiana_os/lib
PROFILE1=../profile/profile1.pl

eval1_1: prep1
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --outdir=res/eval1_1 --platform-from=QEMU  --platform-to=Poyov   >log/eval1_1.log 2>&1

eval1_2: prep1
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --outdir=res/eval1_2 --platform-from=Poyov  --platform-to=QEMU   >log/eval1_2.log 2>&1

prep1: log
	cd ../target/sample1 && make deploy
	cd ../verilator && make iana_serv

eval2_1: prep2
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --outdir=res/eval2_1 --platform-from=QEMU  --platform-to=Poyov   >log/eval2_1.log 2>&1

eval2_2: prep2
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --outdir=res/eval2_2 --platform-from=Poyov  --platform-to=QEMU   >log/eval2_2.log 2>&1

prep2: log
	cd ../target/sample2 && make deploy
	cd ../verilator && make iana_serv

log:
	mkdir log

clean:
	rm -rf log
	mkdir log
