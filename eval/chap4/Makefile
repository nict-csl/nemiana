NEMIANA_LIB_DIR=../../nemiana_os/lib
PROFILE1=../../profile/profile1.pl
TARGET_DIR=../../target
VERILATOR_DIR=../../verilator
CLIENT_DATA=client_data0.txt

eval1_1: prep1
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --target_dir=${TARGET_DIR}/sample1  --verilator_dir=${VERILATOR_DIR} --outdir=res/eval1_1 --platform-from=QEMU  --platform-to=Poyov   >log/eval1_1.log 2>&1

eval1_2: prep1
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --target_dir=${TARGET_DIR}/sample1  --verilator_dir=${VERILATOR_DIR}  --outdir=res/eval1_2 --platform-from=Poyov  --platform-to=QEMU   >log/eval1_2.log 2>&1

prep1: log
	cd ${TARGET_DIR}/sample1 && make deploy
	cd ${VERILATOR_DIR} && make iana_serv

eval2_1: prep2
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --target_dir=${TARGET_DIR}/sample2  --verilator_dir=${VERILATOR_DIR} --outdir=res/eval2_1 --platform-from=QEMU  --platform-to=Poyov   >log/eval2_1.log 2>&1

eval2_2: prep2
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --target_dir=../../target/sample2 --verilator_dir=${VERILATOR_DIR} --outdir=res/eval2_2 --platform-from=Poyov  --platform-to=QEMU   >log/eval2_2.log 2>&1

prep2: log
	cd ${TARGET_DIR}/sample2 && make deploy
	cd ${VERILATOR_DIR}  && make iana_serv

eval3_1: prep3
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --target_dir=../../target/sample3 --verilator_dir=${VERILATOR_DIR} --infile=${CLIENT_DATA} --outdir=res/eval3_1 --platform-from=QEMU  --platform-to=Poyov   >log/eval3_1.log 2>&1

eval3_2: prep3
	perl -I ${NEMIANA_LIB_DIR} eval1.pl --profile=${PROFILE1} --target_dir=../../target/sample3 --verilator_dir=${VERILATOR_DIR}  --infile=${CLIENT_DATA} --outdir=res/eval3_2 --platform-from=Poyov  --platform-to=QEMU   >log/eval3_2.log 2>&1

prep3: log
	cd ${TARGET_DIR}/sample3 && make deploy
	cd ${VERILATOR_DIR}  && make iana_serv


log:
	mkdir log

clean:
	rm -rf log
	mkdir log
