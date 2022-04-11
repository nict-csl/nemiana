#!/usr/bin/env perl
#

##
## 
##
use strict;
use warnings;
use Carp;

use Data::Dumper;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);

use NEMIANA;
use NEMIANA::OS::Kernel;
use NEMIANA::OS::Process;
use NEMIANA::Stub::GDBServer;


my $profile_filename = "../profile/profile3.pl";
my $exec_step = 100;
my $out_dir   = "res/eval2";

sub get_profile_from_file {
    my ($profile_filename) =@_;
    require $profile_filename;
    return get_profile();
}

my $profile = get_profile_from_file($profile_filename);
my $profile2 = {
    dir=>'../verilator',
    program=>'cd ../verilator;obj_dir/Vcpu 9000 &>aaa.log',
    addr=>'localhost',
    port=>'9000'
};
$profile->{tools}->{poyov_server} = $profile2;

my $kernel =  new NEMIANA::OS::Kernel($out_dir);

my $process1= $kernel->create_process("QEMU", $profile);
my $processor1 = $process1->get_processor();
$process1->execute($exec_step);
my $process1_2= $kernel->create_process("Poyov", $profile);
$process1_2->migrate($process1->get_processor());

$process1->execute($exec_step);
$process1_2->execute($exec_step);
$process1->kill();
$process1_2->kill();


my $process2= $kernel->create_process("Poyov", $profile);
my $processor2 = $process2->get_processor();
$process2->execute($exec_step);
my $process2_1= $kernel->create_process("QEMU", $profile);
$process2_1->migrate($process2->get_processor());

$process2->execute($exec_step);
$process2_1->execute($exec_step);
$process2->kill();
$process2_1->kill();
