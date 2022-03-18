#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests =>7;
use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Kernel' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Process' ) || print "Bail out!\n";

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
	ram=>{start=>0x80000000, end=>0x80003FFF},
	device=>'FE310'
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
sub dump_register {
    my ($process) = @_;
    my $processor = $process->get_processor();
    my $register  = $processor->get_register_all();
    print STDERR "Register:";
    foreach my $num(sort keys %{$register}){
	print STDERR sprintf(" %d:%08X\n", $num, $register->{$num});
    }
    print STDERR "\n\n";
}

my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test7"));

my $process;
ok($process= $kernel->create_process("QEMU", $profile));
ok($process->execute(1000) or 1);

ok($process->kill());
