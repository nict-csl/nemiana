#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 1678;
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
ok($kernel =  new NEMIANA::OS::Kernel("res/test4"));

my $process;
ok($process= $kernel->create_process("QEMU", $profile));

# print STDERR "Transition Test\n";
# dump_register($process);
# $process->execute(1);
# dump_register($process);
# $process->execute(1);
# dump_register($process);
# $process->execute(1);
# dump_register($process);
# print STDERR "Transition Test Done\n";
# ok($process->execute(100) or 1);

my $process2;
ok($process2 = $kernel->fork($process));
ok($process2->execute(100) or 1);

my $processor1 = $process->get_processor();
my $processor2 = $process2->get_processor();
my $register1 = $processor1->get_register_all();
my $register2 = $processor2->get_register_all();
foreach my $num(keys %{$register1}){
    is($register1->{$num}, $register2->{$num});
}
my $memory1 = $processor1->get_memory_all();
my $memory2 = $processor2->get_memory_all();
foreach my $addr (keys %{$memory1}){
    is($memory1->{$addr}, $memory2->{$addr});
}

my $process3;
ok($process3 = $kernel->fork($process));
ok($process3->execute(50) or 1);

my $process4;
ok($process4= $kernel->create_process("OpenOCD", $profile));
ok($process4->migrate($process3->get_processor()));
ok($process4->detach);
diag("Hit Return Key! to restart");
#<STDIN>;
ok($process4->attach);
ok($process4->execute(50) or 1);
diag("Hit Return Key! to end Process");
#<STDIN>;

ok($process->kill());
ok($process4->kill());
