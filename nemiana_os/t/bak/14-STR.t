#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use FileHandle;

plan tests => 7 ;

use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Kernel' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Process' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Transition::STR' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::GDBServer')|| print "Bail out!\n";
diag( "Testing NEMIANA $NEMIANA::VERSION, Perl $], $^X" );
my $profile = {
    target => {
	binary=>'app.elf',
	srec=>'app.srec',
	dir=>"target/sample14",
	entry_addr=>0x20010000
    },
    platform => {
	machine=>"sifive_e",
	isa=>'rv32i',
	regsize=>32,  ## TODO: move to RISCV object
	inst_size=>4, ## TODO: move to RISCV object
	ram=>{start=>0x80000000, end=>0x80003FFF}
    },
    tools => {
	qemu=>'/opt/riscv/qemu/bin/qemu-system-riscv32',
	openocd=>'/usr/bin/JLinkGDBServer',
	writer=>'/usr/bin/JLinkExe',
#	poyov_server=>{
#		dir=>'/home/xilinx/poyov',
#		program=>'python3 serv.py',
#		addr=>'iana.local',
#		port=>'5678'
#	},
	poyov_server=>{
		dir=>'../verilator',
		program=>'cd ../verilator;obj_dir/Vcpu 9001',
		addr=>'localhost',
		port=>'9000'
	},
    },
    syscall => {
	top_dir=>'./file_sys'
    }
};

my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test14"));

my $fh = new FileHandle("res/test11/state_transition/str_1.pl","r");

my $str;

ok($str = NEMIANA::Transition::STR::load($fh));


#print STDERR "result=",Dumper $str,"\n";

close($fh);

my $process;
my $pid = 1;
ok($process = $kernel->load($profile, "res/test11", $pid));

#for(my $i=0;$i<100;$i++){
#    $process->execute(1);
#}

my $gdb_serv;
ok($gdb_serv = new NEMIANA::Stub::GDBServer(1234, $process));
ok($gdb_serv->wait());

ok($process->kill());
