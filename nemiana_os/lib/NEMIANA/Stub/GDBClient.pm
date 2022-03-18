#!/usr/bin/env perl
#
package NEMIANA::Stub::GDBClient;
use strict;
use warnings;
use Data::Dumper;
use NEMIANA::Stub;
use NEMIANA::Stub::GDBRSP;

our @ISA = ('NEMIANA::Stub');
our $qemu_trace_log = "qemu_trace.log";
our $transition_log = "transition.log";

our $DEFAULT_PORT_BASE=3333;
our %used_port_map;

sub init_stub {
    my ($process, $type, $profile) = @_;
    my $self = new NEMIANA::Stub::GDBClient($process);
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
    $self->close();
}

sub alloc_port {
    my ($self) = @_;

    for(my $i=$DEFAULT_PORT_BASE; $i<9999; $i++){
	if(!exists $used_port_map{$i}){
	    $used_port_map{$i} = 1;

	    return $i;
	}
    }
}

sub init_cpu {
}

sub start_cpu {
}

sub open_target{
    my ($self, $profile) = @_;
}
sub connect {
    my ($self) = @_;

    if(!defined $self->{gdbrsp}
       and defined $self->{host}
       and defined $self->{port}){
	$self->{gdbrsp} = new NEMIANA::Stub::GDBRSP($self->{host}, $self->{port});
	print STDERR "connect GDBRSP", $self->{gdbrsp},"\n";
    }
}

sub close {
    my ($self) = @_;
    $self->{gdbrsp}->close() if(defined $self->{gdbrsp});
    delete $self->{gdbrsp};
}

sub set_reg{
    my $self = shift @_;
    return $self->{gdbrsp}->set_reg(@_);
}

sub set_register{
    my $self = shift @_;
    return $self->{gdbrsp}->set_reg(@_);
}

sub set_str{
    my ($self, $str) =@_;
    
    foreach my $num (keys %{$str->{reg}}){
	$self->set_register($num, $str->{reg}->{$num});
    }
    foreach my $addr (keys %{$str->{memory}}){
	$self->set_memory($addr, $str->{memory}->{$addr});
    }
}

# return Hash
sub get_register_all{
    my $self = shift @_;
    return $self->{gdbrsp}->get_register_all(@_);
}

# return Array
sub get_reg{
    my $self = shift @_;
    return $self->{gdbrsp}->get_reg(@_);
}

sub get_memory{
    my $self = shift @_;
    return $self->{gdbrsp}->get_memory(@_);
}

sub set_memory{
    my $self = shift @_;
    return $self->{gdbrsp}->set_memory(@_);
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

sub skip_instruction {
    my ($self, $current_pc) =@_;

    my $next_pc = $current_pc+4;
    $self->set_reg($self->{platform}->{reg_size}, $next_pc);
    return $next_pc;
}


1;
