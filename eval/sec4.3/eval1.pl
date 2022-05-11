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

my $profile_filename = "../profile/profile1.pl";
my $exec_step = 500;
my $out_dir   = "res/eval1";
my $platform1 ="QEMU";
my $platform2 ="Poyov";
my  $result = GetOptions(
    'outdir|o=s' => \$out_dir,
    'profile|p=s' => \$profile_filename,
    'exec-step|e=i' => \$exec_step,
    'platform-from|f=s' => \$platform1,
    'platform-to|t=s' => \$platform2,
    );

sub get_profile_from_file {
    my ($profile_filename) =@_;
    require $profile_filename;
    return get_profile();
}

print "$profile_filename, $exec_step, $out_dir, $platform1, $platform2\n";

my $profile = get_profile_from_file($profile_filename);
my $profile2 = {
    dir=>'../verilator',
    program=>'cd ../verilator;obj_dir/Vcpu 9000 &>aaa.log',
    addr=>'localhost',
    port=>'9000'
};
$profile->{tools}->{poyov_server} = $profile2;

my $kernel =  new NEMIANA::OS::Kernel($out_dir);

my $process1= $kernel->create_process($platform1, $profile);
my $processor1 = $process1->get_processor();
$process1->execute($exec_step);
my $process2= $kernel->create_process($platform2, $profile);
$process2->migrate($process1->get_processor());
my $gdb_serv = new NEMIANA::Stub::GDBServer($gdb_port_num, $process2);
$gdb_serv->wait();

$process->kill();
$process2->kill();
