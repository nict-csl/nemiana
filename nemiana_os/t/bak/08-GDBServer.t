#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 7;
use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Kernel' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Process' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::GDBServer' ) || print "Bail out!\n";

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
ok($kernel =  new NEMIANA::OS::Kernel("res/test08"));

my $process;
ok($process= $kernel->create_process("QEMU", $profile));
ok($process->execute(100) or 1);
my $gdb_serv;
ok($gdb_serv = new NEMIANA::Stub::GDBServer(1234, $process));
ok($gdb_serv->wait());
ok($process->kill());
