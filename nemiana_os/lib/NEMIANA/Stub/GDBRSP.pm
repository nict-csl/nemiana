#!/usr/bin/env perl
#
package NEMIANA::Stub::GDBRSP;
use strict;
use warnings;
use Data::Dumper;
use IO::Socket;
use Time::HiRes;

my @start_msg =(
    'qSupported:multiprocess+;swbreak+;hwbreak+;qRelocInsn+;fork-events+;vfork-events+;exec-events+;vContSupported+;QThreadEvents+;no-resumed+',
    'vMustReplyEmpty',
#    'Hgp0.0',
#    'qTStatus',
#    '?',
#    'qsThreadInfo',
#    'qAttached:1',
#    'Hc-1',
#    'qOffsets',
#    'g',
#    'l',
    );
sub new {
    my ($class, $host, $port) =@_;
    my $client = {};
    print "start $host, $port\n";
    if(!defined $host){
	$host="localhost";
    }
    if(!defined $port){
	$port=2345;
    }
    my $fd;
    my $count=0;
    while(!defined $fd and $count<100){
	$fd = new IO::Socket::INET(
	    PeerAddr=>$host,
	    PeerPort=>$port,
	    Proto=>'tcp');
	Time::HiRes::sleep(0.01);
	$count++;
    }

    if(!defined $fd){
	die "can not create sock, $host, $port";
    }
    $client->{fd} = $fd;

    print "end: ", $client->{fd}, "\n";
    foreach my $msg (@start_msg){
	my $buf;
	my $rep = send_msg($client, $msg);
	print "GDB:'$msg':'$rep'\n\n";
    }
    bless $client, $class;
    return $client;
}

sub write_state {
    my ($client, $code_memory, $registers, $memory) = @_;
    
    for my $num (keys %{$registers}){
	if($num eq 'pc'){
#	    print STDERR sprintf("REG %08X: %08X\n", 32, $registers->{$num});
	    $client->set_register(32, $registers->{pc});
	}else{
#	    print STDERR sprintf("REG %08X: %08X\n", $num, $registers->{$num});
	    $client->set_register($num, $registers->{$num});
	}
    }
    print STDERR "write memories\n";
    ### RAM上のデータ初期化を実機ではしていないため
    for my $addr (keys %{$code_memory}){
	$client->set_memory($addr, $code_memory->{$addr});
    }
    for my $addr (keys %{$memory}){
	$client->set_memory($client, $addr, $memory->{$addr});
    }
}

sub gen_msg {
    my ($data) = @_;
    my $len = length($data);
    my $chksum = 0;
    for(my $i=0;$i<$len;$i++){
	my $c = substr($data, $i, 1);
	$chksum += ord($c);
    }

    my $msg = sprintf("\$%s#%02X", $data,$chksum % 256);

    return $msg;
}

sub reply_msg {
    my ($server,$data) = @_;
    $server->{fd}->send("+");
    my $msg = gen_msg($data);
    $server->{fd}->send($msg);

    my $buf;
    $server->{fd}->recv( $buf, 1);
    return $buf;
}

sub send_msg {
    my ($server,$data) = @_;

    $server->{fd}->send("+");
    my $msg = gen_msg($data);
    $server->{fd}->send($msg);
    my $res="";
    my $buf;
    $server->{fd}->recv( $buf, 1000);
    my $read_bytes = length($buf);
    while($read_bytes>0){
	$res .= $buf;
	last if(index($res,"#")>0);
	$server->{fd}->recv( $buf, 1000);
	$read_bytes = length($buf);
    }
    
    return ($res);
}

sub send_ack {
    my ($server,$data) = @_;
    $server->{fd}->send("+");
}

sub parse_msg {
    my ($line) = @_;
    if($line !~ s/^\+//){
	return undef;
    }
    if($line !~ s/\#([\da-fA-F]{2})$//){
	return undef;
    }
    my $chksum = hex($1);

    return $line;
}

sub close {
    my ($client) = @_;
    close $client->{fd};
}

sub get_hex{
    my ($val)=@_;
    my @val;
    for(my $i=0;$i<4;$i++){
	$val[$i] = sprintf("%02x", ($val>>($i*8)) & 255);
    }
    my $hex_val = join('',@val);
    return $hex_val;
}

sub set_reg2{
    my ($client, $reg_num, $val) =  @_;
    my $hex_val = get_hex($val);
    my $msg=sprintf("P%x=%08s",$reg_num, $hex_val);
    #    my $msg=sprintf("G%x=%08x",$reg_num, $val);

    for(my $i=0;$i<10;$i++){
	my $rep = send_msg($client, $msg);
	print "set_reg2: $msg, $rep\n";
	last if($rep ne '+$#00');
    }
}

sub set_reg_all {
    my ($client, @reg_value) =  @_;
    my $msg="G";
    for(my $i=0;$i<=32;$i++){
	if(defined $reg_value[$i]){
	    $msg .= get_hex($reg_value[$i]);
	}
	else{
	    $msg .= get_hex(0xffeeddcc);
	}
    }
    for(my $i=0;$i<10;$i++){
	my $rep = send_msg($client, $msg);
	print "set_reg_all: $msg, $rep\n";
	last if($rep ne '+$#00');
    }
}

sub set_reg{
    my ($client, $reg_num, $val) =  @_;
    my @reg_val = get_reg($client);
    $reg_val[$reg_num] = $val;
    set_reg_all($client, @reg_val);
}

sub set_reg3{
    my ($client, $reg_num, $val) =  @_;

    my $msg="G";
    for(my $i=0;$i<32;$i++){
	#	$msg .= sprintf("%08x",$i*16);
	$msg .= get_hex($i*16);
    }
    $msg .= get_hex(0xFC);
    for(my $i=0;$i<10;$i++){
	my $rep = send_msg($client, $msg);
	print "set_reg_all: $msg, $rep\n";
	last if($rep ne '+$#00');
    }
}

sub get_reg{
    my ($client) =  @_;
    my $msg="g";
    my $result;
    for(my $i=0;$i<10;$i++){
	my $rep = send_msg($client, $msg);
	print "get_reg: $msg, $rep\n";
	if($rep ne '$#00'){
	    send_ack($client);
	    $result = $rep;
	    last;
	}
    }
    my @result;
    if(defined $result){
	while($result=~s/([\w\d]{8})//){
	    my $line=$1;
	    my $value=0;
	    for(my $i=0;$i<4;$i++){
		$value+=hex(substr($line, $i*2, 2))<<($i*8);
	    }
	    push @result, $value;
	}
    }

    return @result;
}

sub get_memory{
    my ($client, $addr) =  @_;
    my $msg=sprintf("m%08x,4",$addr);
    my  $rep = send_msg($client, $msg);
    print "REP: $rep\n";

    $rep=~s/^\+\$//;
    $rep=~s/^\+//;
    $rep=~s/\#..$//;
    my $val = hex(get_hex(hex($rep)));

    return $val;
}

sub set_memory{
    my ($client, $addr, $val) =  @_;
    my $msg=sprintf("M%08x,4:%s",$addr, get_hex($val));
    my  $rep = send_msg($client, $msg);
    print "REP: $rep\n";
}

sub set_break_point{
    my ($client, $point) =  @_;
    my $msg=sprintf("Z0,%08x,4",$point);
    my  $rep = send_msg($client, $msg);
    print "set_break_point:$msg\n";
    print "REP: $rep\n";
}

sub execute_step{
    my ($client) =  @_;
    #    my $msg=sprintf("vCont;s");
    my $msg=sprintf("s");
    my  $rep = send_msg($client, $msg);
    print "execute_step:$msg\n";
    print "REP: $rep\n";
}

sub execute_cont{
    my ($client) =  @_;
#    my $msg=sprintf("vCont;c");
    my $msg=sprintf("c");
    my  $rep = send_msg($client, $msg);
    print "execute_step:$msg\n";
    print "REP: $rep\n";
}

sub get_register_all(){
    my ($client) =@_;

    my @result = $client->get_reg();

    my %result;

    for(my $i=0;$i<33;$i++){
	$result{$i} = $result[$i];
    }

    return \%result;
}

sub set_register{
    my ($client, $num, $val) = @_;

    $client->set_reg($num, $val);
}



1;

