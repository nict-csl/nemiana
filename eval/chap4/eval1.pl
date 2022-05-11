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
use FileHandle;

use NEMIANA;
use NEMIANA::OS::Kernel;
use NEMIANA::OS::Process;
use NEMIANA::Stub::GDBServer;

my $profile_filename = "../profile/profile1.pl";
my $exec_step = 100;
my $out_dir   = "res/eval1";
my $platform1 ="QEMU";
my $platform2 ="Poyov";
my $target_dir = "../target/sample1";
my $verilator_dir="../verilator";
my $infile;
my  $result = GetOptions(
    'outdir|o=s' => \$out_dir,
    'profile|p=s' => \$profile_filename,
    'exec-step|e=i' => \$exec_step,
    'platform-from|f=s' => \$platform1,
    'platform-to|t=s' => \$platform2,
    'target_dir=s' => \$target_dir,
    'verilator_dir=s' => \$verilator_dir,
    'infile=s'=>\$infile
    );

sub get_profile_from_file {
    my ($profile_filename) =@_;
    require $profile_filename;
    return get_profile();
}


print "infile=$infile\n";
print "$profile_filename, $exec_step, $out_dir, $platform1, $platform2, $target_dir\n";
print "\n";


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

my $process1= $kernel->create_process($platform1, $profile);
my $processor1 = $process1->get_processor();


my $fh;
if($infile){
    print "open $infile\n";
    $fh = new FileHandle($infile, "r") or die "$infile is not found\n";
    $process1->set_fd(0, $fh);
}

print STDERR "--------------------------------------------\nexecute 1:\n";

$process1->execute($exec_step);
print STDERR "--------------------------------------------\n\n";
print STDERR "migrattion 1:\n";
my $process2= $kernel->create_process($platform2, $profile);
$process2->migrate($process1->get_processor());
if($infile){
    $process2->set_fd(0, $fh);
}
else{
    ## infileからは一つのプロセスしか読み込めない
    $process1->execute($exec_step);
}
$process2->execute($exec_step);
$process1->kill();
$process2->kill();
