#!/usr/bin/env perl
#
package NEMIANA::Stub::QEMUClient;
use strict;
use warnings;
use Data::Dumper;
use IO::Socket;
use NEMIANA::Stub;
use NEMIANA::Stub::GDBClient;
use File::Spec;
use NEMIANA::Stub::GDBRSP;


our @ISA = ('NEMIANA::Stub::GDBClient');
our $qemu_trace_log = "qemu_trace.log";
our $transition_log = "transition.log";

sub init_stub {
    my ($process, $type, $profile) = @_;
    my $self = new NEMIANA::Stub::QEMUClient($process);
    NEMIANA::Stub::init_stub_main($self, $process, $type, $profile);
    
    $self->open_target($profile);
    $self->connect();
    return $self;
}

sub new {
    my ($class, $process) = @_;
    my $self  = {};
    bless $self, $class;
    NEMIANA::Stub::init($self, $process);
    $self->{trace_filename} =  $process->get_tmp_file($qemu_trace_log);

    return $self;
}

sub kill {
    my ($self) = @_;
    NEMIANA::Stub::GDBClient::kill($self);
    $self->close_qemu();
}

sub open_target{
    my ($self, $profile) = @_;
    $self->open_qemu($profile->{target}->{dir},
		     $profile->{target}->{binary},
		     $profile->{tools}->{qemu},
		     $profile->{platform}->{machine});
}

sub open_qemu {
    my ($self,$sample_dir, $target, $qemu, $machine) =@_;
    my $port = $self->alloc_port() or die "No free port";
    $self->{host} = "localhost";
    $self->{port} = $port;
    my $logfile = File::Spec->rel2abs($self->{trace_filename});

    my $command="|(cd $sample_dir;${qemu} -display none -monitor stdio -machine ${machine} -kernel ${target} -singlestep -S -gdb tcp::$port -D ${logfile} -d cpu,in_asm >/tmp/xxxx$$.out)";
    
    my $fh;
    print STDERR "command=$command\n";
    open $fh , $command;
    print STDERR "fh=$fh\n";
    $self->{qemu_fh} = $fh;
}

sub close_qemu{
    my ($self) = @_;
    my $fh = $self->{qemu_fh};
    return if(!defined $fh);
    print $fh "quit\n";
    close $fh if(defined $fh);
    delete $self->{qemu_fh};
}

sub connect {
    my ($self) = @_;
    NEMIANA::Stub::GDBClient::connect($self);
    if(!defined $self->{qemu_trace_fh}){
	$self->{qemu_trace_fh} = new FileHandle($self->{trace_filename}, "r");
    }
}

sub close {
    my ($self) = @_;
    NEMIANA::Stub::GDBClient::close($self);
    close $self->{qemu_trace_fh} if(defined $self->{qemu_trace_fh});
    delete $self->{qemu_trace_fh};
}

sub parse_lines {
    my (@lines) = @_;
    my $pc;
    my $inst;
    my @reg_data;

    foreach my $line (@lines){
	if($line=~/^0x([\d+a-f]+)\:\s*([\d+a-f]+)/){
	    $pc = hex($1);
	    $inst = hex($2);
	}
	elsif($line=~m%^\s+x(\d+)/[\w\d]+\s([\da-f]+)%){
	    my $tmp= $line;
	    while($tmp =~s%^\s+x(\d+)/[\w\d]+\s([\da-f]+)%%g){
		my $regnum = $1;
		my $regval = hex($2);
		$reg_data[$regnum] = $regval;
	    }
	}
    }
    return {
	pc=>$pc,
	inst=>$inst,
	reg_data=>\@reg_data
    };
}

sub step {
    my ($self) = @_;

    $self->{gdbrsp}->execute_step();

    if(defined $self->{platform}){
	
	my @next_reg  = $self->get_reg();

	print {$self->{trace_fh}} "next_reg:\n";
	for(my $i = 0; $i<=$#next_reg;$i++){
	    print {$self->{trace_fh}} sprintf("  %02d:%08X\n", $i, $next_reg[$i]);
	}
	print {$self->{trace_fh}} "\n";

    
	my ($str, $next_pc) = $self->{platform}->convert_str($self->{last_pc}, \@next_reg, $self->{count});
	print {$self->{trace_fh}} sprintf("next_pc:%08X\n", $next_pc);

	$self->{count}++;
	$self->{last_pc} = $next_pc;
	print {$self->{log_fh}} "current_str=", Dumper $str, "\n\n";

	return $str;
    }
    else{
	die "no decoder\n";
#	return $self->step2();
    }
}
1;
__DATA__
sub read_trace_one_line {
    my ($self, $lines, $count, $last_info) =@_;
    
    my $trace_info;
    my $current_lines = join('', @{$lines});
    $trace_info = parse_lines(@{$lines});

    print {$self->{log_fh}} "trace_info=", Dumper $trace_info, "lines:", join("", @{$lines}), "\n";
    
    if(defined $trace_info){
	if(defined $last_info){
	    my $next_reg = $trace_info->{reg_data};
	    my $next_pc  = $trace_info->{pc};
	    my $last_inst_code = $last_info->{inst};
	    my $last_pc = $last_info->{pc};
	    my $inst = NEMIANA::Transition::Decode::RISCV::read_trace_one_line_sub($last_pc, $last_inst_code,
										   $next_reg, $next_pc, $count, 32);
	    return ($trace_info, $inst);
	}
	return ($trace_info);
    }
    return;
}


sub step2 {
    my ($self) = @_;

    $self->{gdbrsp}->execute_step();

    my $num = 0;
    my $fh =$self->{qemu_trace_fh};
    my @lines;
    while($num < 1000){
    	my $line = <$fh>;
	if(defined $line){
#	    print STDERR ("line:$line");
	    print {$self->{log_fh}} $line;
	    print {$self->{trace_fh}} $line;
	    push @lines, $line;
	}
	else {
	    my($current_trace_info, $current_str) = $self->read_trace_one_line(\@lines, $self->{count}, $self->{last_trace_info});
	    print {$self->{log_fh}}  "current_trace_info", Dumper $current_trace_info, "\n";
	    print {$self->{log_fh}}  "current_inst:$current_str\n";
	    if(defined $current_str){
		print {$self->{log_fh}} "current_str=", Dumper $current_str, "\n\n";
	    }
	    $self->{last_trace_info} = $current_trace_info;
	    $self->{count}++;
	    return $current_str;
	}
	$num++;
    }
}

1;
