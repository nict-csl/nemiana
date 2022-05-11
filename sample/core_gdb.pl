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

my $out_dir="res/test5";
my $profile_filename="../profile/profile1.pl";
my $gdb_port_num = 1234;
my $exec_step = 100;
#my $platform="PoyoV";
my $platform="QEMU";
my $target_dir = "../target/sample1";
my $verilator_dir="../verilator";
my $infile;
my  $result = GetOptions(
    'outdir|o=s' => \$out_dir,
    'profile|p=s' => \$profile_filename,
    'gdb-port|g=i' => \$gdb_port_num,
    'exec-step|e=i' => \$exec_step,
    'platform=s' => \$platform,
    'target_dir=s' => \$target_dir,
    'verilator_dir=s' => \$verilator_dir,
    'infile=s'=>\$infile,
    );

print "****\nparam:$profile_filename, $exec_step, $out_dir, $target_dir\n";

my $profile = get_profile_from_file($profile_filename);
my $profile2 = {
    dir=>'../verilator',
    program=>"cd $verilator_dir;obj_dir/Vcpu 9000 &>aaa.log",
    addr=>'localhost',
    port=>'9000'
};
$profile->{tools}->{poyov_server} = $profile2;
$profile->{target}->{dir}=$target_dir;

my $kernel =  new NEMIANA::OS::Kernel($out_dir);
my $process= $kernel->create_process($platform, $profile);
my $processor = $process->get_processor();

my $fh;
if($infile){
    print "open $infile\n";
    $fh = new FileHandle($infile, "r") or die "$infile is not found\n";
    $process->set_fd(0, $fh);
}

#$process->execute($exec_step);
$process->execute(1000);

#my $process2 = $kernel->fork($process);
#my $gdb_serv = new NEMIANA::Stub::GDBServer($gdb_port_num, $process2);
if(1){
my $gdb_serv = new NEMIANA::Stub::GDBServer($gdb_port_num, $process);
print STDERR "server start\n";
$gdb_serv->wait();
print STDERR "server end\n";
}
$process->kill();
#$process2->kill();
