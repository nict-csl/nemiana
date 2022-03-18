#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 19;

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

my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test3"));
diag("create process");
my $process;
ok($process= $kernel->create_process("QEMU", $profile));
ok($process->execute(10) or 1);
my $process2;
ok($process2= $kernel->create_process("QEMU", $profile));
ok($process2->migrate($process->get_processor()));
ok($process->detach);
ok($process2->detach);
diag("Hit Return Key!");
#<STDIN>;
ok($process2->attach());

my @reg;
@reg = $process2->{client}->get_reg();
diag("reg:".join(",", @reg));

ok($process2->execute(5) or 1);
diag("Hit Return Key! to end process2");
ok($process2->detach);
#<STDIN>;

my $process3;
ok($process3= $kernel->create_process("OpenOCD", $profile));
ok($process3->migrate($process->get_processor()));
ok($process3->detach);
diag("Hit Return Key! to end Process3");
#<STDIN>;

ok($process->kill());
ok($process2->kill());
ok($process3->kill());
