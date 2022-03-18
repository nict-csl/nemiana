#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 12;

use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Kernel' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Process' ) || print "Bail out!\n";

diag( "Testing NEMIANA $NEMIANA::VERSION, Perl $], $^X" );

my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test1"));
my $process;
ok($process= $kernel->create_process());
my $str_handle;

my $log_fh;
ok($log_fh = $process->get_log_handle());
ok(print $log_fh "test1\n");

my $str_log_fh;
ok($str_log_fh = $process->get_trace_log_handle());
ok(print $str_log_fh "test1\n");

my $pid;
ok($pid = $process->get_pid());
is($pid, 1, "process id is 1");
my $a = {abc=>1, efg=>2};
ok($process->put_str($a));
