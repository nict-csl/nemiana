#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 12;

my $TARGET='app.elf';
my $MACHINE="sifive_e";
my $TARGET_DIR="target/sample14";
my $QEMU='/opt/riscv/qemu/bin/qemu-system-riscv32';

use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Kernel' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Process' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::PoyoVStub' ) || print "Bail out!\n";

diag( "Testing NEMIANA $NEMIANA::VERSION, Perl $], $^X" );
my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test12_2"));
my $process;
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
	poyov_server=>{
	    dir=>'/home/xilinx/fpga',
	    program=>"ssh iana.local 'cd /home/xilinx/fpga;sudo python3 serv.py>aaa.log'",
	    addr=>'iana.local',
	    port=>'5678'
	},
    },
    syscall => {
	top_dir=>'./file_sys'
    }
};

my $profile2 = {
    'dir'=>'../verilator',
    'program'=>'cd ../verilator;obj_dir/Vcpu 9000',
    addr=>'localhost',
    port=>'9000'
};

$profile->{tools}->{poyov_server} = $profile2;

ok($process= $kernel->create_process("Poyov", $profile));
diag("create process done $process");
my $client = $process->{client};
diag("client=$client\n");
sleep 10;
my $res;
my $addr = $profile->{tools}->{poyov_server}->{addr};
my $port = $profile->{tools}->{poyov_server}->{port};
#ok($res=`curl http://$addr:$port/state`);
#diag("state=$res");
my $content;
ok($content = $client->get_trace());
diag("state=$content");
my $trace_info_list;
ok($trace_info_list= $client->parse_trace($content));
#diag("*******\ntarce_info_list=\n",Dumper $trace_info_list, "\n\n\n");
my $str_list;
ok($str_list=$client->gen_str($trace_info_list));
#diag("*******\nstr_list=\n",Dumper $str_list, "\n\n\n");
ok($client->reset_cpu());
sleep 1;
ok($process->execute(1000));
ok($client->kill());

my $process2;

$profile->{tools}->{poyov_server} = $profile2;
ok($process2= $kernel->create_process("Poyov", $profile));
diag("create process2 done $process");
my $client2 = $process2->{client};
diag("client2=$client2\n");
ok($process2->execute(1000));
ok($client2->kill());
__DATA__
