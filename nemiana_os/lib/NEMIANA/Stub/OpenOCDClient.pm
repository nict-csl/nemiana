#!/usr/bin/env perl
#
package NEMIANA::Stub::OpenOCDClient;
use strict;
use warnings;
use Data::Dumper;
use NEMIANA::Stub;
use NEMIANA::Stub::GDBRSP;
use NEMIANA::Stub::GDBClient;
our @ISA = ('NEMIANA::Stub::GDBClient');

sub init_stub {
    my ($process, $type, $profile) = @_;
    my $self = new NEMIANA::Stub::OpenOCDClient($process);
    NEMIANA::Stub::init_stub_main($self, $process, $type, $profile);
    
    $self->load_program($profile);
    $self->open_target($profile);
    $self->connect();
    return $self;
}

sub new {
    my ($class, $process) = @_;
    my $self  = {};
    bless $self, $class;
    NEMIANA::Stub::init($self, $process);

    return $self;
}

sub kill {
    my ($self) = @_;

    NEMIANA::Stub::GDBClient::kill($self);
    $self->close_openocd();
}

sub open_target{
    my ($self, $profile) = @_;
    $self->open_openocd($profile->{target}->{dir},
			$profile->{target}->{binary},
			$profile->{tools}->{openocd});
}

sub exec_cmd{
    my ($cmd) = @_;

    my $pid = fork();
    if($pid){
	return $pid;
    }
    else{
	exec($cmd);
    }
}

sub open_openocd {
    my ($self,$sample_dir, $target, $openocd) =@_;
    my $port = $self->alloc_port() or die "No free port";
    $self->{host} = "localhost";
    $self->{port} = $port;

#    my $command="|${openocd} -port $port -device FE310 -if JTAG -speed 4000 -jtagconf -1,-1 >/tmp/xxxx$$.out";
    my $command="${openocd} -port $port -device FE310 -if JTAG -speed 4000 -jtagconf -1,-1 >/tmp/xxxx$$.out";
    my $fh;
    print STDERR "command=$command\n";
    #    open $fh , $command;
    #print STDERR "fh=$fh\n";
    #$self->{openocd_fh} = $fh;

    $self->{openocd_pid} =  exec_cmd($command);
}

sub kill_process {
    my ($pid) = @_;

    my $c_pid = `pgrep -P $pid`;

    while($c_pid=~s/(\d+)//){
	kill_process($1);
    }
#    print STDERR "kill $pid\n";
    CORE::kill 'HUP' , $pid;
}

sub close_openocd{
    my ($self) = @_;
    my $pid = $self->{openocd_pid};
    kill_process($pid);
    delete $self->{openocd_pid};
}

sub close_openocd2{
    my ($self) = @_;
    my $fh = $self->{openocd_fh};
    return if(!defined $fh);
    print $fh "exit\n\n\n";
    close $fh if(defined $fh);
    delete $self->{openocd_fh};
}

sub load_program{
    my ($self, $profile) = @_;

    print STDERR "profile=$profile, ",Dumper $profile,"\n";
    my $writer = $profile->{tools}->{writer};
    my $dir = $profile->{target}->{dir};
    my $cmd = "|(cd $dir;${writer} -device FE310 -if JTAG -speed 4000 -jtagconf -1,-1 -autoconnect 1) >/tmp/yyyy$$.out";
    my $fh;
    open $fh , $cmd;
    my $filename = $profile->{target}->{srec};
    print $fh "loadfile $filename\nrnh\nexit\n";
    close $fh;

    print STDERR "load program done!\n";
}
