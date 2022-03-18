#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 9;

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
ok($kernel =  new NEMIANA::OS::Kernel("res/test11"));
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
	    #		program=>"ssh iana.local 'cd /home/xilinx/fpga/;sudo python3 serv.py 5678'",
		program=>"cat",
		addr=>'iana.local',
		port=>'5678'
	},
#	poyov_server=>{
#		dir=>'../verilator',
#		program=>'cd ../verilator;obj_dir/Vcpu 9001',
#		addr=>'localhost',
#		port=>'9000'
#	},
    },
    syscall => {
	top_dir=>'./file_sys'
    }
};
my $process1;
ok($process1= $kernel->create_process("Poyov", $profile));
my $client = $process1->{client};
my $process2;
ok($process2= $kernel->create_process("QEMU", $profile));
my $client2 = $process2->{client};
#for(my $i=0;$i<1000;$i++){
for(my $i=0;$i<1000;$i++){
    $process1->execute(1);
    $process2->execute(1);

    print STDERR "\n\nDump $i\n";

    my $pc1 = $process1->get_next_pc();
    my $pc2 = $process2->get_next_pc();

    print STDERR sprintf("PC:%08X %08X\n", $pc1, $pc2);

    if($pc1 != $pc2){
	print STDERR sprintf("Error in PC!!:%08X %08X\n", $pc1, $pc2);
    }
        
    my @registers1 = $process1->{client}->get_reg();
    my @registers2 = $process2->{client}->get_reg();
    my $regfile1 = $process1->{processor}->{regfile};

    foreach (my $i=1;$i<32;$i++){
#	print STDERR sprintf("  %02d %08X %08X", $i, $registers1[$i], $registers2[$i]);
	#	print STDERR sprintf(" %08X\n", $process1->{processor}->{regfile}->{$i});
	if($registers2[$i] != $regfile1->{$i}){
	    print STDERR sprintf("error!!:  %02d %08X %08X %08X %08X", $i, $pc1, $pc2, $regfile1->{$i}, $registers2[$i]);
	}
    }
    print STDERR "\n\n";
}

ok($process2->kill(),'kill test');
__DATA__
