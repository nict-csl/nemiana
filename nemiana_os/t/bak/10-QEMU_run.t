#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use FileHandle;

plan tests =>122;
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
	regsize=>32,  ## TODO: move to RISCV object
	inst_size=>4, ## TODO: move to RISCV object
	ram=>{start=>0x80000000, end=>0x80003FFF}
    },
    tools => {
	qemu=>'/opt/riscv/qemu/bin/qemu-system-riscv32',
	openocd=>'/usr/bin/JLinkGDBServer',
	writer=>'/usr/bin/JLinkExe',
#	poyov_server=>{
#		dir=>'/home/xilinx/poyov',
#		program=>'python3 serv.py',
#		addr=>'iana.local',
#		port=>'5678'
#	},
	poyov_server=>{
		dir=>'../verilator',
		program=>'cd ../verilator;obj_dir/Vcpu 9000',
		addr=>'localhost',
		port=>'9000'
	},
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

sub cmp_str {
    my ($pre_str, $str, $inst_attr) = @_;

    foreach my $num (keys %{$pre_str->{reg}}){
	
	if(defined $pre_str->{reg}->{$num}){
	    is($pre_str->{reg}->{$num}, $str->{reg}->{$num});
	    if($pre_str->{reg}->{$num} ne  $str->{reg}->{$num}){
		print STDERR "Diff:\npre:";
		print STDERR Dumper $pre_str;
		print STDERR Dumper $inst_attr;
		print STDERR "\nreal:";
		print STDERR Dumper $str;
	    }
	}
    }

    foreach my $num (keys %{$str->{reg}}){
	if(defined $pre_str->{reg}->{$num}){
	    is($pre_str->{reg}->{$num}, $str->{reg}->{$num});
	    if($pre_str->{reg}->{$num} ne  $str->{reg}->{$num}){
		print STDERR "Diff:\npre:";
		print STDERR Dumper $pre_str;
		print STDERR Dumper $inst_attr;
		print STDERR "\nreal:";
		print STDERR Dumper $str;
	    }
	}
    }
    foreach my $addr (keys %{$str->{memory}}){
	if(defined $pre_str->{memory}->{$addr}){
	    is($pre_str->{memory}->{$addr}, $str->{memory}->{$addr});
	    if($pre_str->{memory}->{$addr} ne  $str->{memory}->{$addr}){
		print STDERR "Diff:\npre:";
		print STDERR Dumper $pre_str;
		print STDERR Dumper $inst_attr;
		print STDERR "\nreal:";
		print STDERR Dumper $str;
	    }
	}
    }
}


my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test13"));

my $process;
ok($process= $kernel->create_process("QEMU", $profile));
$process->execute(1000);
ok($process->kill());
