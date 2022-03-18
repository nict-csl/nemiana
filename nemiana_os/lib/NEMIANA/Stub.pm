#!/usr/bin/env perl
#
package NEMIANA::Stub;

use NEMIANA::Stub::QEMUClient;
use NEMIANA::Stub::OpenOCDClient;
use NEMIANA::Stub::PoyoVStub;;
use NEMIANA::Platform::RISCV;

sub init {
    my ($self, $process) = @_;

    $self->{log_fh}    = $process->get_log_handle();
    $self->{trace_fh}  = $process->get_trace_log_handle();
    $self->{process}   = $process;
    $self->{count}     = 0;

    return $self;
}

sub init_process {
    my ($process, $type, $profile) = @_;

    if($type eq "QEMU"){
	return NEMIANA::Stub::QEMUClient::init_stub($process, $type, $profile);
    }
    elsif($type eq "OpenOCD"){
	return NEMIANA::Stub::OpenOCDClient::init_stub($process, $type, $profile);
    }
    elsif($type eq "Poyov"){
	return NEMIANA::Stub::PoyoVStub::init_stub($process, $type, $profile);
    }
    else{
	return undef;
    }
}

sub init_stub_main {
    my ($self, $process, $type, $profile) = @_;
    $self->{processor}= $process->get_processor();
    my $binary = $self->{processor}->get_org_memory_all();
    $self->{platform} = new NEMIANA::Platform::RISCV($binary,$profile);
    $self->{last_pc} = $profile->{target}->{entry_addr};
    $self->{profile} = $profile;
    return $self;
}

sub get_platform {
    my ($self) = @_;

    return $self->{platform};
}

sub migrate {
    my ($self, $org_processor) = @_;

    my $org_reg = $org_processor->get_register_all();
    
    foreach my $num (keys %{$org_reg}){
	$self->set_register($num, $org_reg->{$num});
    }
    $self->{last_pc} = $self->{platform}->get_pc($org_reg);

    my $org_memory = $org_processor->get_memory_all();

    my %memory ;
    foreach my $addr (keys %{$org_memory}){
	if ($self->{platform}->is_writable($addr)){
	    my $value = $org_memory->{$addr};
	    my $offset = $addr & 0x3;
	    my $w_addr = $addr - $offset;
	    if(! exists $memory{$w_addr}){
		$memory{$w_addr} = 0;
	    }
	    $memory{$w_addr} += $value << ($offset * 8);
	}
    }
#    print STDERR "migrate memory:\n";
#    foreach my $addr (keys %memory){
#	print STDERR sprintf(" %08X:%08X\n",$addr, $memory{$addr});
#	$self->set_memory($addr, $memory{$addr});
#    }
    return $self;
}

1;
