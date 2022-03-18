#!/usr/bin/env perl
#
package NEMIANA::OS::Syscall;
use strict;
use warnings;
use Data::Dumper;
use NEMIANA::OS::Kernel;
use NEMIANA::OS::Process;
use FileHandle;
use NEMIANA::Transition::Processor;
use File::Spec;

use FileHandle;
use Socket;
use Cwd;

sub new {
    my ($class, $profile) = @_;

    my $self = {};

    bless $self, $class;
    $self->{top_dir}=File::Spec->rel2abs($profile->{syscall}->{top_dir});
    print STDERR "TOPDIR:",$profile->{syscall}->{top_dir},"res:",$self->{top_dir},"\n";
    $self->{fd_table}=[];

    $self->{fd_table}->[0] = *STDIN;
    $self->{fd_table}->[1] = *STDOUT;
    $self->{fd_table}->[2] = *STDERR;
    $self->{num} = 0;
    return $self;
};


my %call_table = (
    1=>\&sys_open,
    2=>\&sys_read,
    3=>\&sys_write,
    4=>\&sys_socket,
    5=>\&sys_connect,
    6=>\&sys_close,
    7=>\&sys_exit
    );

sub set_top_dir {
    my ($self, $top_dir)=@_;
    $self->{top_dir} = File::Spec->rel2abs($top_dir);
}

sub find_free_fd{
    my ($self) = @_;
    for(my $i=3;$i<$#{$self->{fd_table}};$i++){
	if(!defined $self->{fd_table}->[$i]){
	    return $i;
	}
    }
    return $#{$self->{fd_table}} + 1;
}

sub get_fd{
    my ($self, $fd) = @_;
    return $self->{fd_table}->[$fd];
}

sub set_fd{
    my ($self, $fd, $fh) = @_;
    return $self->{fd_table}->[$fd] = $fh;
}

sub gen_path {
    my ($self, $path) = @_;

    $path =~ s%^/%%;
    $path =~ s%\.\.%%g;

    my $ret_path = $self->{top_dir}. "/$path";

    return $ret_path;
}

sub syscall {
    my ($self, $process) = @_;

    my $reg = $process->get_register_all();

    my $call_num = $reg->{10};
    my @args;
    foreach my $key(qw/11 12 13 14/){
	push @args, $reg->{$key};
    }

    #printf ("syscall %d:%s\n", $call_num, join(',', @args));
    printf STDERR sprintf ("syscall(%d) %d:%s\n", $self->{num}, $call_num, join(',', @args));
    $self->{num}++;
    my $res = -1;
    my $memory;
    if(exists $call_table{$call_num}){
 	($res, $memory) = $call_table{$call_num}->($self, $process, @args);
    }

#    $process->set_register(10, $res);
    
#    foreach my $addr (keys %{$memory}){
#	$process->set_memory($addr, $memory->{$addr});
#    }

    my %reg;
    $reg{10} = $res;
    
    my %result=(
	reg=>\%reg,
	memory=>$memory
	);
    
    return \%result;
}

sub get_str {
    my ($process, $addr) = @_;

    my $str;
    my $d = $process->get_memory($addr);
    while($d != 0){
	$str .= chr($d);
	$addr++;
	$d = $process->get_memory($addr);
    }
    print STDERR "get_str:$str\n";
    return $str;
}

sub get_word {
    my ($process, $addr) = @_;

    my $d=0;
    for(my $i=3;$i>=0;$i--){
	my $val = $process->get_memory($addr+$i) || 0;
	$d = $d * 256 + $process->get_memory($addr+$i);
    }
    
    return $d;
}

sub get_bytes {
    my ($process, $org_addr, $len) = @_;

    my $data="";
    my $end_addr   = $org_addr+$len;

    my $addr = $org_addr;
    while($addr < $end_addr){
	my $d = $process->get_memory($addr);
	if(!defined $d){
	    $d = 0;
	}
	$data .=chr($d);
 	$addr++;
    }
    return $data;
}

sub set_bytes {
    my ($process, $org_addr, $buf) = @_;

    my %memory;

    my $end_addr   = $org_addr + length($buf);

    for(my $addr=$org_addr;$addr<$end_addr;$addr++){
	$memory{$addr} = ord(substr($buf, $addr - $org_addr, 1));
    }

    return \%memory;
}

sub sys_open {
    my ($self,$process, $file_addr, $mode) = @_;

    my $str = get_str($process, $file_addr);
    print STDERR "open($str, $mode);\n";

    my $file_mode;
    if(($mode&1) == 0){
	$file_mode = '<';
    }
    else{
	$file_mode = '>';
    }
    my $fh;

    my $path = $self->gen_path($str);
    print STDERR "open:$path, $mode\n";
    open $fh, $file_mode , $path;
    
    my $fd = $self->find_free_fd();
    $self->set_fd($fd, $fh);
    return ($fd, {});
}

sub sys_read {
    my ($self, $process, $fd, $buf_addr, $count) = @_;

    if(!defined $self->get_fd($fd)){
	print "FD not found:$fd\n";
	$fd = 0;
    }
    my $buf;
    my $fh = $self->get_fd($fd);
    my $res = sysread $fh, $buf, $count;
    print STDERR "sys_read($fd, '$buf', $count),$fh;\n";

    my $memory = set_bytes($process, $buf_addr, $buf);

    return (length($buf), $memory);
}

sub sys_write {
    my ($self, $process, $fd, $buf_addr, $count) = @_;

    my $buf = get_bytes($process, $buf_addr, $count);
    print STDERR "sys_write($fd, '$buf', $count);\n";

    if(!defined  $self->get_fd($fd)){
	print STDERR "FD not found:$fd\n";
	$fd = 0;
    }

    my $fh = $self->get_fd($fd);
    syswrite $fh, $buf, $count;

    return ($count, {});
}

sub sys_socket {
    my ($self, $process, $domain, $type, $protocol) = @_;
    print ("sys_socket($domain, $type, $protocol);\n");

    my $fh;

    socket($fh, PF_INET,SOCK_STREAM, 0);
    my $fd = $self->find_free_fd();
    print STDERR "sys_socket:$fd,$fh\n";
    $self->set_fd($fd, $fh);
    return ($fd, {});
}

sub ntohs
{
    my ($d) = @_;

    return ($d % 256) * 256 + int($d/256);
}

sub sys_connect {
    my ($self, $process, $sockfd, $addr, $addrlen) = @_;
    print STDERR "sys_connect($sockfd, $addr, $addrlen);\n";

    my @ip;
    $ip[0] = get_word($process, $addr);
    $ip[1] = get_word($process, $addr +  4);
    $ip[2] = get_word($process, $addr +  8);
    $ip[3] = get_word($process, $addr + 12);

    print STDERR sprintf("connect ip(%d, %d, %d, %d)\n", @ip);
    
    my $d = $ip[1];
    my $ip_addr=sprintf("%d.%d.%d.%d\n",$d>>24,($d>>16)&0xff,($d>>8)&0xff,$d&0xff);
    my $ip = inet_aton($ip_addr);
    my $con_port = ntohs(int($ip[0] / 0x10000));
    my $sockaddr = pack_sockaddr_in($con_port, $ip);
    my $fh = $self->get_fd($sockfd);
    print STDERR "connect($fh, $fh, $sockaddr), $ip_addr, $con_port\n";
    connect($fh, $sockaddr);
    print STDERR "ip:$ip_addr, $con_port, $ip, $sockaddr\n";   
    return (0, {});
}

sub sys_close {
    my ($self, $process, $fd) = @_;

    if($fd>=2 and defined get_fd($fd)){
	my $fh = $self->get_fd($fd);
	close $fh;
	$self->set_fd($fd, undef);
    }
    return (0, {});
}

sub sys_exit {
    my ($self, $process, $status) = @_;

    my $exit_callback= $self->{exit_callback};
    
    if(defined $exit_callback
       and ref $exit_callback eq 'CODE'){
	$exit_callback->($status)
    }
    return (0, {});
}

1;
