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
	dir=>"target/sample13",
	entry_addr=>0x20010000
    },
    platform => {
	machine=>"sifive_e",
	isa=>'rv32i',
	regsize=>32,
	ram=>{start=>0x80000000, end=>0x80003FFF},
	device=>'FE310'
    },
    tools => {
	qemu=>'/opt/riscv/qemu/bin/qemu-system-riscv32',
	openocd=>'/usr/bin/JLinkGDBServer',
	writer=>'/usr/bin/JLinkExe'
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

my $kernel;
ok($kernel =  new NEMIANA::OS::Kernel("res/test8"));

my $process;
ok($process= $kernel->create_process("QEMU", $profile));
my $platform = $process->{client}->{platform};

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


my $num=100;
my $i=0;
my @pre_str_list;
my @str_list;
while($i<$num){
    $i++;
    ## Run on Real Processor
    my ($pre_str, $inst_attr) = $platform->get_next_str($process->{processor}, $i);
    push @pre_str_list, $pre_str;
    my $str = $process->{client}->step();
    push @str_list, $str;
    cmp_str($pre_str, $str, $inst_attr);
    $process->{processor}->next_step($str);
}

my $fh1 = new FileHandle("res/test8/pre_str.log", "w");
print $fh1 Dumper \@pre_str_list;
close $fh1;

my $fh2 = new FileHandle("res/test8/str.log", "w");
print $fh2 Dumper \@str_list;
close $fh2;
ok($process->kill());

my $UART0BASE=0x10013000;

my $event = {
    cond=>sub {
	my ($processor, $pre_str)=@_;

	foreach my $addr (keys %{$pre_str->{memory}}){
	    if($addr >=0x10013000
	       and $addr <0x10014000){
		return 1;
	    }
	}
	foreach my $addr (keys %{$pre_str->{load_memory}}){
	    if($addr >=0x10013000
	       and $addr <0x10014000){
		return 1;
	    }
	}
	return undef;
    },
    invoke=>sub {
	my ($process, $processor, $pre_str)=@_;
	print STDERR "event inoketed\n";
#	print STDERR Dumper $pre_str;

	if($pre_str->{type} eq 'store'){
	    print STDERR "periferal:\n";
#	    foreach my $addr (keys %{$pre_str->{memory}}){
#		print STDERR sprintf("%08X:%08X\n", $addr, $pre_str->{memory}->{$addr});
	    #	    }

	    if(defined $pre_str->{memory}->{$UART0BASE+0x00}){
		print STDERR "UART'".chr($pre_str->{memory}->{$UART0BASE+0x00});
		print STDERR "'\n";
	    }
	    
	}
	else{
	    foreach my $num (keys %{$pre_str->{reg}}){
		if($num >0 and $num < 32){
		    my $d = ord('H');
#		    print STDERR sprintf("load Periferal :%08X\n", $d);
		    $pre_str->{reg}->{$num} = $d;
		}
	    }
	}
	return (1, $pre_str);
    }
};

my $process2;
ok($process2= $kernel->create_process("QEMU", $profile));
ok($process2->add_pre_callback($event));
$process2->execute(1000);
$process2->kill();
