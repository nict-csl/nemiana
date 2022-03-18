#!/usr/bin/env perl
#
package NEMIANA::OS::Kernel;
use strict;
use warnings;
use Data::Dumper;
use File::Path 'mkpath';
use NEMIANA::OS::Process;

###
use NEMIANA::Stub;

my $log_head="log";
my $str_dir = "state_transition";
my $str_head = "str";

sub new {
    my ($class, $log_path) = @_;

    my $self = {};

    bless $self, $class;

    $self->{log_path} = $log_path;
    $self->{pid} = 1;
    $self->{process_table} = {};

    return $self;
}

sub init_process {
    my ($self, $profile) = @_;

    my $log_path = $self->{log_path}."/$log_head".$self->{pid};
    my $process = new NEMIANA::OS::Process($self, $self->{pid}, $log_path, $profile);
    $self->{process_table}->{$self->{pid}} = $process;
    $self->{pid}++;

    return $process;
}

sub create_process {
    my ($self, $type, $profile) = @_;

    my $process = $self->init_process($profile);
    $process->create_processor();
    if(defined $type){
	$process->{client} = NEMIANA::Stub::init_process($process, $type, $profile);
#	print STDERR "create process DONE!!!!\n";
    }
    $process->init_cpu($profile);
    return $process;
}

sub fork {
    my ($self, $org_process) = @_;

    my %profile = %{$org_process->{profile}};
    my $process = $self->init_process($self, \%profile);
    $process->fork($org_process);
    $process->init_cpu(\%profile);
}

sub gen_str_filename{
    my ($self, $pid, $log_path) = @_;
    my $dirname;
    if(!defined $log_path){
	$dirname = $self->{log_path} . "/$str_dir";
	if(! -d $dirname){
	    mkpath $dirname;
	}
    }
    else{
	$dirname = $log_path . "/$str_dir";
    }

    my $filename = "$dirname/${str_head}_${pid}.pl";

    return $filename;
}

sub load {
    my ($self, $profile, $pid_or_logdir, $id) = @_;

    my $process = $self->init_process($profile);
    my $filename;
    if($pid_or_logdir =~ /^\d+$/){
	$filename = $self->gen_str_filename($pid_or_logdir);
    }
    else {
	print STDERR "load($self, $profile, $pid_or_logdir, $id)\n";
	$filename = $self->gen_str_filename($id, $pid_or_logdir);
    }
	
    my $fh = new FileHandle($filename, "r") or die "can not open $filename";
    my $str = NEMIANA::Transition::STR::load($fh);
    $process->load($str);
    $process->init_cpu($profile);

    close $fh;
    
    return $process;
}
sub get_str_handle {
    my ($self, $process) = @_;
    my $pid = $process->get_pid();
    my $filename = $self->gen_str_filename($pid);
    my $fh = new FileHandle($filename, "w") or die "can not open $filename";
    return $fh;
}

sub get_process {
    my ($self, $pid) = @_;

    return $self->{process_table}->{$pid};
}

sub handle_system_call {
    my ($self, $process, $processor) = @_;

    print STDERR sprintf("handle_system_call($self, $process, $processor);\n");

    my $platform = $process->get_platform();

    return if(! defined $platform);

    my $inst_code = $platform->get_current_inst_code($processor);
    if($platform->is_system_call($inst_code)){
	my $regfile = $processor->get_register_all();
	print STDERR sprintf("ECALL Invoke!!%08X,%d\n", $regfile->{32}, $process->{syscall}->{num});
	print {$process->{log_fh}} sprintf("ECALL Invoke!!%08X,%d\n", $regfile->{32}, $process->{syscall}->{num});

	my $res = $process->{syscall}->syscall($process);

	print {$process->{log_fh}} "ECALL result",Dumper $res,"\n";

	###
	### 目的のレジスタだけを書き戻すと他のレジスタがおかしくなるらしい．
	###
	my %new_regfile = %{$process->get_register_all()};
	foreach my $num(keys %{$res->{reg}}){
	    $new_regfile{$num}=$res->{reg}->{$num};
	}
	$res->{reg} = \%new_regfile;

	print {$process->{log_fh}} "new ECALL result",Dumper $res,"\n";
	print STDERR "new ECALL result",Dumper $res,"\n";
	$process->set_str($res);

	return (1, $res);
    }
    return (0, {});
}

sub pre_process {
    my ($self, $process, $processor) = @_;
    
    my ($skip, $str) = handle_system_call(@_);
    if($skip){
	return ($skip, $str);
    }

    ($skip, $str) = $process->handle_pre_callback($processor);
    if($skip){
	return ($skip, $str);
    }
}

sub post_process {
    my ($self, $process, $processor, $str) = @_;

    my ($skip, $new_str) = $process->handle_post_callback($processor, $str);
    return ($skip, $new_str);
}
