#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 3212;

use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Kernel' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Process' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Memory' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::GDBRSP' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::QEMUClient' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Platform::RISCV' ) || print "Bail out!\n";
diag( "Testing NEMIANA $NEMIANA::VERSION, Perl $], $^X" );
my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test1"));
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
	regsize=>32,
	ram=>{start=>0x80000000, end=>0x80003FFF}
    },
    tools => {
	qemu=>'/opt/riscv/qemu/bin/qemu-system-riscv32',
	openocd=>'/usr/bin/JLinkGDBServer'
    }
};

diag("create process");
ok($process= $kernel->create_process("QEMU", $profile));
diag("create process done $process");
diag("execution test");
my $processor;
$processor = $process->get_processor();
for(my $j=0;$j<100;$j++){
    $process->execute(1);
    my $proc_reg;
    $proc_reg = $processor->get_register_all();
    my $qemu_reg;
    $qemu_reg = $process->{client}->get_register_all();
    for(my $i=1;$i<33;$i++){
	my ($x,$y) = ($proc_reg->{$i}, $qemu_reg->{$i});
	if($x !=$y){
	    my $pc = $qemu_reg->{32};
	    diag(sprintf("%08X: $j, $i:%08X, %08X", $pc, $x, $y));
	}
	is($proc_reg->{$i}, $qemu_reg->{$i});
    }
}

my $inst  = 0x341022f3;
my $decode;
ok($decode = NEMIANA::Platform::RISCV::decode($inst));
print STDERR "decode=", Dumper $decode, "\n";

ok($process->kill());
