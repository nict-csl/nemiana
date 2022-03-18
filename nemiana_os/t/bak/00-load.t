#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 28;
#grep -h -r -e '^use' lib/*|sort |uniq |perl -n -e '/use ([\w\:]+)/&&print "use_ok(\"$1\");\n"'
use_ok("Carp");
use_ok("Cwd");
use_ok("Data::Dumper");
use_ok("Exporter");
use_ok("File::Path");
use_ok("File::Path");
use_ok("File::Spec");
use_ok("FileHandle");
use_ok("IO::Socket");
use_ok("LWP::UserAgent");
use_ok("Socket");
use_ok("Time::HiRes");
use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Kernel' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Process' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Syscall' ) || print "Bail out!\n";
use_ok( 'NEMIANA::OS::Memory' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::GDBRSP' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::GDBServer' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::GDBClient' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::QEMUClient' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::OpenOCDClient' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Stub::PoyoVStub' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Platform::RISCV' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Transition::Processor' ) || print "Bail out!\n";
use_ok( 'NEMIANA::Transition::STR' ) || print "Bail out!\n";

diag( "Testing NEMIANA $NEMIANA::VERSION, Perl $], $^X" );
