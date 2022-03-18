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
ok($kernel =  new NEMIANA::OS::Kernel("res/test12_5"));
my $process;
require 't/profile.pl';

my $profile = get_profile();

my $profile2 = {
    dir=>'../verilator',
    program=>'cd ../verilator;obj_dir/Vcpu 9000 &>aaa.log',
    addr=>'localhost',
    port=>'9000'
};

$profile->{tools}->{poyov_server} = $profile2;
#ok($process= $kernel->create_process("QEMU", $profile));
ok($process= $kernel->create_process("Poyov", $profile));
diag("create process done $process");
#my $gdb_serv;
#use NEMIANA::Stub::GDBServer;
#ok($gdb_serv = new NEMIANA::Stub::GDBServer(1234, $process));
#ok($gdb_serv->wait());
ok($process->execute(1000));

ok($process->{client}->kill());
