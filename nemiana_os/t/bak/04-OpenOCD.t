#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 3208;

use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Kernel' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Process' ) || print "Bail out!\n";

diag( "Testing NEMIANA $NEMIANA::VERSION, Perl $], $^X" );
my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test2"));
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
	openocd=>'/usr/bin/JLinkGDBServer',
	writer=>'/usr/bin/JLinkExe'
    },
    syscall => {
	top_dir=>'./file_sys'
    }
};
diag("check pgrep command installed 'pgrep -P $$'");
ok(system("pgrep -P $$")>=0);
diag("load program");
ok(NEMIANA::Stub::OpenOCDClient::load_program({},$profile));

diag("create process");
ok($process= $kernel->create_process("OpenOCD", $profile));
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
diag("kill Process");
ok($process->kill());
diag("kill Process Done");
