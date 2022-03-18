#!/usr/bin/env perl
#
use strict;
use warnings;
use Carp;

use Data::Dumper;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);

use NEMIANA;
use NEMIANA::OS::Kernel;
use NEMIANA::OS::Process;
use NEMIANA::Stub::GDBServer;
sub get_profile_from_file {
    my ($profile_filename) =@_;
    require $profile_filename;
    return get_profile();
}

my $out_dir="res/test1";
my $profile_filename="../profile/profile1.pl";
my $gdb_port_num = 1234;
my $exec_step = 100;
my  $result = GetOptions(
    'outdir|o=s' => \$out_dir,
    'profile|p=s' => \$profile_filename,
    'gdb-port|g=i' => \$gdb_port_num,
    'exec-step|e=i' => \$exec_step
    );

my $profile = get_profile_from_file($profile_filename);
my $profile2 = {
    dir=>'../verilator',
    program=>'cd ../verilator;obj_dir/Vcpu 9000 &>aaa.log',
    addr=>'localhost',
    port=>'9000'
};
$profile->{tools}->{poyov_server} = $profile2;

my $kernel =  new NEMIANA::OS::Kernel($out_dir);
my $process= $kernel->create_process("PoyoV", $profile);
my $processor = $process->get_processor();
$process->execute($exec_step);

my $process2 = $kernel->create_process("QEMU", $profile);
$process2->migrate($process->get_processor());
my $gdb_serv = new NEMIANA::Stub::GDBServer($gdb_port_num, $process2);
print STDERR "server start\n";
$gdb_serv->wait();
print STDERR "server end\n";

$process->kill();
$process2->kill();
