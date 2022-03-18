#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 18;

require 't/profile.pl';

my $profile = get_profile();

use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Kernel' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Process' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::GDBRSP' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::QEMUClient' ) || print "Bail out!\n";

diag( "Testing NEMIANA $NEMIANA::VERSION, Perl $], $^X" );
my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test2"));
my $process;
ok($process= $kernel->create_process("QEMU", $profile));
diag("create process $process");
my $a = {abc=>1, efg=>2};
ok($process->put_str($a));

my @lines;
while(my $line = <DATA>){
    push @lines, $line;
}
my $res;
ok($res = NEMIANA::Stub::QEMUClient::parse_lines(@lines));
print STDERR "parse_line:", Dumper $res,"\n";

my $qemu;
ok($qemu = $process->{client});
my @val;
ok($qemu->set_reg(1, 0x12345678) or 1);
ok(@val=$qemu->get_reg(1));
print STDERR sprintf("reg:%08X\n",$val[1]);
my $val;
ok($val=$qemu->get_memory(0x80000000));
print STDERR sprintf("memory:%08X\n", $val);
ok($qemu->set_memory(0x80000000, $val));
ok($qemu->set_reg(32, 0x20010000) or 1);
ok($qemu->close());
ok($qemu->close_qemu());

__DATA__
----------------
IN: 
Priv: 3; Virt: 0
0x20010000:  01000093          addi            ra,zero,16

 pc       20010000
 mhartid  00000000
 mstatus  00000000
 mstatush  00000000
 mip      00000000
 mie      00000000
 mideleg  00000000
 medeleg  00000000
 mtvec    00000000
 stvec    00000000
 mepc     00000000
 sepc     00000000
 mcause   00000000
 scause   00000000
 mtval  00000000
 stval  00000000
 x0/zero 00000000 x1/ra 12345678 x2/sp 00000000 x3/gp 00000000
 x4/tp 00000000 x5/t0 00000000 x6/t1 00000000 x7/t2 00000000
 x8/s0 00000000 x9/s1 00000000 x10/a0 00000000 x11/a1 00000000
 x12/a2 00000000 x13/a3 00000000 x14/a4 00000000 x15/a5 00000000
 x16/a6 00000000 x17/a7 00000000 x18/s2 00000000 x19/s3 00000000
 x20/s4 00000000 x21/s5 00000000 x22/s6 00000000 x23/s7 00000000
 x24/s8 00000000 x25/s9 00000000 x26/s10 00000000 x27/s11 00000000
 x28/t3 00000000 x29/t4 00000000 x30/t5 00000000 x31/t6 00000000
----------------
IN: 
Priv: 3; Virt: 0
0x20010004:  02000113          addi            sp,zero,32

 pc       20010004
 mhartid  00000000
 mstatus  00000000
 mstatush  00000000
 mip      00000000
 mie      00000000
 mideleg  00000000
 medeleg  00000000
 mtvec    00000000
 stvec    00000000
 mepc     00000000
 sepc     00000000
 mcause   00000000
 scause   00000000
 mtval  00000000
 stval  00000000
 x0/zero 00000000 x1/ra 00000010 x2/sp 00000000 x3/gp 00000000
 x4/tp 00000000 x5/t0 00000000 x6/t1 00000000 x7/t2 00000000
 x8/s0 00000000 x9/s1 00000000 x10/a0 00000000 x11/a1 00000000
 x12/a2 00000000 x13/a3 00000000 x14/a4 00000000 x15/a5 00000000
 x16/a6 00000000 x17/a7 00000000 x18/s2 00000000 x19/s3 00000000
 x20/s4 00000000 x21/s5 00000000 x22/s6 00000000 x23/s7 00000000
 x24/s8 00000000 x25/s9 00000000 x26/s10 00000000 x27/s11 00000000
 x28/t3 00000000 x29/t4 00000000 x30/t5 00000000 x31/t6 00000000
----------------
