#!/usr/bin/env perl
#
package NEMIANA::Stub::GDBServer;
use strict;
use warnings;
use Data::Dumper;
use IO::Socket;
use NEMIANA::Stub::GDBRSP;

our @ISA = ('NEMIANA::Stub::GDBRSP');

sub new {
    my ($class, $port, $process) = @_;
    my $self = {};
    bless $self, $class;
    my $host = "localhost";
    $self->init($host, $port, $process);
}

sub init{
    my ($self, $host, $port, $process) = @_;
    print STDERR "init: $host, $port\n";
    $self->{socket} = new IO::Socket::INET(
	Listen=>5,
	LocalAddr=>$host,
	LocalPort=>$port,
	Proto=>'tcp',
	Reuse=>1) or die "can not create sock";
    
    print "end: ", $self->{socket}, "\n";
    $self->{process}= $process;
    $self->{break_point} = {};
    return $self;
}

sub set_break_point{
    my ($self, $addr) = @_;

    $self->{break_point}->{$addr} = 1;

    return "OK";
}

sub clear_break_point{
    my ($self, $addr) = @_;

    delete $self->{break_point}->{$addr};

    return "OK";
}

sub handle{
    my ($self, $msg) = @_;
    $msg=~s/[\r\n\f]*$//;
    $msg=~s/^\+\$//;
    $msg=~s/^\$//;
    $msg=~s/\#[\da-fA-F]{2}$//;
    if($msg =~ /^qSupported/){
	return 'PacketSize=1000;qXfer:features:read+;vContSupported+;multiprocess+';
    }
    elsif($msg =~ /^vMustReplyEmpty/){
	return "";
    }
    elsif($msg =~ /^Hg/){
	return "OK";
    }
    elsif($msg =~ /^Hc/){
	return "OK";
    }
    elsif($msg =~ /^qfThreadInfo/){
	return "mp01.01";
    }
    elsif($msg =~ /^qsThreadInfo/){
	return "l";
    }
    elsif($msg =~ /^qOffsets/){
	return "";
    }
    elsif($msg =~ /^qSymbol/){
	return "";
    }
    elsif($msg =~ /^\?/){
	return "T05thread:p01.01;";
    }
    elsif(index($msg,'qXfer:features:read:target.xml')==0){
	return $self->get_target_xml();
    }
    elsif($msg =~ /^qXfer\:features\:read\:riscv-32bit-cpu.xml/){
	return $self->get_riscv_32bit_cpu();
    }
    elsif($msg =~ /^qXfer\:features\:read\:riscv-32bit-csr.xml\:([\da-z]+),([\da-z]+)/){
	return $self->get_riscv_32bit_csr(hex($1), hex($2));
    }
    elsif($msg =~ /^qXfer\:features\:read\:riscv-32bit-virtual.xml/){
	return $self->get_riscv_32bit_virtual();
    }
    elsif(index($msg,'qTStatus')==0){
	return "";
    }
    elsif(index($msg,'qAttached:1')==0){
	return "1";
    }
    elsif($msg=~/^p([\da-f]+)/){
	my $val;

	if($1 eq '7d'){
	    $val = '05111040';
	}
	else{
	    my $num = hex($1);
	    my $registers = $self->{process}->get_register_all();
	    $val = NEMIANA::Stub::GDBRSP::get_hex($registers->{$num});
	}
	return $val;
    }
    elsif($msg=~/^m([\da-f]+)\,([\da-f]+)/){
	my $addr = hex($1);
	my $len  = hex($2);
	return $self->get_cpu_memory($addr, $len);
    }
    elsif($msg=~/^z0\,([\da-f]+)\,([\da-f]+)/){
	my $addr = hex($1);
	return $self->clear_break_point($addr);
    }
    elsif($msg=~/^Z0\,([\da-f]+)\,([\da-f]+)/){
	my $addr = hex($1);
	return $self->set_break_point($addr);
    }
    elsif($msg =~ /^g/){
	my $data="";
	my $registers = $self->{process}->get_register_all();
	for(my $i=0;$i<=32;$i++){
	    $data .= NEMIANA::Stub::GDBRSP::get_hex($registers->{$i});
	}
	return $data;
    }
    elsif(index($msg,'vCont?')==0){
	return "vCont;c;C;s;S";
    }
    elsif(index($msg,'vCont;c:p1.-1')==0){
	print STDERR "continue\n";
	$self->server_cont();
	print STDERR "continue done!\n";
	return "T05thread:p01.01;";
    }
    elsif(index($msg,'vCont;s:p1.1')==0){
	print STDERR "next_step\n";
	$self->server_step();
	print STDERR "next_step done!\n";
	return "T05thread:p01.01;";
    }
    else{
	return "";
    }
}


sub server_step {
    my ($self) = @_;
    print STDERR "server step1\n";
    $self->{process}->execute(1);
    print STDERR "server step2\n";
    my $reg = $self->{process}->get_register_all();
    print STDERR "server step3\n";
    print STDERR "registers:\n";
    for(my $i=0;$i<32;$i++){
	print STDERR sprintf("%d:%08X\n", $i, $reg->{$i});
    }
    print STDERR "server step4\n";
    print STDERR "done\n";
}

sub server_cont {
    my ($self) = @_;
    print STDERR "server cont1\n";

    while(1){
	$self->{process}->execute(1);
	my $current_pc = $self->{process}->get_next_pc();
	if(exists $self->{break_point}->{$current_pc}){
	    print STDERR sprintf("server break at %08X\n", $current_pc);
	    last;
	}
	else{
	    print STDERR sprintf("server execute at %08X\n", $current_pc);
	}
    }
    my $reg = $self->{process}->get_register_all();
    print STDERR "server cont3\n";
    print STDERR "registers:\n";
    for(my $i=0;$i<32;$i++){
	print STDERR sprintf("%d:%08X\n", $i, $reg->{$i});
    }
    print STDERR "server cont4\n";
    print STDERR "done\n";
}

sub wait {
    my ($self) = @_;

    while(my $sock = $self->{socket}->accept()){
	$self->{fd}=$sock;
	while(1){
	    my $buf;
	    $sock->recv( $buf, 10000);
	    my $read_bytes = length($buf);
	    print STDERR "read:$read_bytes:'$buf'\n";
	    last if ($read_bytes == 0);
	    my $msg = $self->handle($buf);
	    if(defined $msg){
		print STDERR "send:'$msg'\n";
		$self->reply_msg($msg);
	    }
	}
    }
    print STDERR "done\n";
}

sub get_cpu_memory{
    my ($self, $addr , $len) = @_;

    my $res="";

    for(my $i=0;$i<$len;$i++){
	my $a =$addr + $i;
	my $data = $self->{process}->get_memory($a);
	$res .= sprintf("%02x", $data);
    }

    return $res;
}

sub get_target_xml{
#    my $data ='l<?xml version="1.0"?><!DOCTYPE target SYSTEM "gdb-target.dtd"><target><xi:include href="riscv-32bit-cpu.xml"/><xi:include href="riscv-32bit-csr.xml"/><xi:include href="riscv-32bit-virtual.xml"/></target>';

    my $data ='l<?xml version="1.0"?><!DOCTYPE target SYSTEM "gdb-target.dtd"><target><architecture>riscv:rv32</architecture><xi:include href="riscv-32bit-cpu.xml"/><xi:include href="riscv-32bit-virtual.xml"/><xi:include href="riscv-csr.xml"/></target>';
#    my $data ='l<?xml version="1.0"?><!DOCTYPE target SYSTEM "gdb-target.dtd"><target><xi:include href="riscv-32bit-cpu.xml"/></target>';
    return $data;
}

sub get_riscv_32bit_cpu{
    my $data ='l<?xml version="1.0"?>
<!-- Copyright (C) 2018-2019 Free Software Foundation, Inc.

     Copying and distribution of this file, with or without modification,
     are permitted in any medium without royalty provided the copyright
     notice and this notice are preserved.  -->

<!-- Register numbers are hard-coded in order to maintain backward
     compatibility with older versions of tools that didn\'t use xml
     register descriptions.  -->

<!DOCTYPE feature SYSTEM "gdb-target.dtd">
<feature name="org.gnu.gdb.riscv.cpu">
  <reg name="zero" bitsize="32" type="int" regnum="0"/>
  <reg name="ra" bitsize="32" type="code_ptr"/>
  <reg name="sp" bitsize="32" type="data_ptr"/>
  <reg name="gp" bitsize="32" type="data_ptr"/>
  <reg name="tp" bitsize="32" type="data_ptr"/>
  <reg name="t0" bitsize="32" type="int"/>
  <reg name="t1" bitsize="32" type="int"/>
  <reg name="t2" bitsize="32" type="int"/>
  <reg name="fp" bitsize="32" type="data_ptr"/>
  <reg name="s1" bitsize="32" type="int"/>
  <reg name="a0" bitsize="32" type="int"/>
  <reg name="a1" bitsize="32" type="int"/>
  <reg name="a2" bitsize="32" type="int"/>
  <reg name="a3" bitsize="32" type="int"/>
  <reg name="a4" bitsize="32" type="int"/>
  <reg name="a5" bitsize="32" type="int"/>
  <reg name="a6" bitsize="32" type="int"/>
  <reg name="a7" bitsize="32" type="int"/>
  <reg name="s2" bitsize="32" type="int"/>
  <reg name="s3" bitsize="32" type="int"/>
  <reg name="s4" bitsize="32" type="int"/>
  <reg name="s5" bitsize="32" type="int"/>
  <reg name="s6" bitsize="32" type="int"/>
  <reg name="s7" bitsize="32" type="int"/>
  <reg name="s8" bitsize="32" type="int"/>
  <reg name="s9" bitsize="32" type="int"/>
  <reg name="s10" bitsize="32" type="int"/>
  <reg name="s11" bitsize="32" type="int"/>
  <reg name="t3" bitsize="32" type="int"/>
  <reg name="t4" bitsize="32" type="int"/>
  <reg name="t5" bitsize="32" type="int"/>
  <reg name="t6" bitsize="32" type="int"/>
  <reg name="pc" bitsize="32" type="code_ptr"/>
</feature>
';

    ;
    return $data;
}

sub get_riscv_32bit_csr{
    my ($self, $start, $len)=@_;
    my $data ='<?xml version="1.0"?>
<!-- Copyright (C) 2018-2019 Free Software Foundation, Inc.

     Copying and distribution of this file, with or without modification,
     are permitted in any medium without royalty provided the copyright
     notice and this notice are preserved.  -->

<!DOCTYPE feature SYSTEM "gdb-target.dtd">
<feature name="org.gnu.gdb.riscv.csr">
  <reg name="ustatus" bitsize="32"/>
  <reg name="uie" bitsize="32"/>
  <reg name="utvec" bitsize="32"/>
  <reg name="uscratch" bitsize="32"/>
  <reg name="uepc" bitsize="32"/>
  <reg name="ucause" bitsize="32"/>
  <reg name="utval" bitsize="32"/>
  <reg name="uip" bitsize="32"/>
  <reg name="fflags" bitsize="32"/>
  <reg name="frm" bitsize="32"/>
  <reg name="fcsr" bitsize="32"/>
  <reg name="cycle" bitsize="32"/>
  <reg name="time" bitsize="32"/>
  <reg name="instret" bitsize="32"/>
  <reg name="hpmcounter3" bitsize="32"/>
  <reg name="hpmcounter4" bitsize="32"/>
  <reg name="hpmcounter5" bitsize="32"/>
  <reg name="hpmcounter6" bitsize="32"/>
  <reg name="hpmcounter7" bitsize="32"/>
  <reg name="hpmcounter8" bitsize="32"/>
  <reg name="hpmcounter9" bitsize="32"/>
  <reg name="hpmcounter10" bitsize="32"/>
  <reg name="hpmcounter11" bitsize="32"/>
  <reg name="hpmcounter12" bitsize="32"/>
  <reg name="hpmcounter13" bitsize="32"/>
  <reg name="hpmcounter14" bitsize="32"/>
  <reg name="hpmcounter15" bitsize="32"/>
  <reg name="hpmcounter16" bitsize="32"/>
  <reg name="hpmcounter17" bitsize="32"/>
  <reg name="hpmcounter18" bitsize="32"/>
  <reg name="hpmcounter19" bitsize="32"/>
  <reg name="hpmcounter20" bitsize="32"/>
  <reg name="hpmcounter21" bitsize="32"/>
  <reg name="hpmcounter22" bitsize="32"/>
  <reg name="hpmcounter23" bitsize="32"/>
  <reg name="hpmcounter24" bitsize="32"/>
  <reg name="hpmcounter25" bitsize="32"/>
  <reg name="hpmcounter26" bitsize="32"/>
  <reg name="hpmcounter27" bitsize="32"/>
  <reg name="hpmcounter28" bitsize="32"/>
  <reg name="hpmcounter29" bitsize="32"/>
  <reg name="hpmcounter30" bitsize="32"/>
  <reg name="hpmcounter31" bitsize="32"/>
  <reg name="cycleh" bitsize="32"/>
  <reg name="timeh" bitsize="32"/>
  <reg name="instreth" bitsize="32"/>
  <reg name="hpmcounter3h" bitsize="32"/>
  <reg name="hpmcounter4h" bitsize="32"/>
  <reg name="hpmcounter5h" bitsize="32"/>
  <reg name="hpmcounter6h" bitsize="32"/>
  <reg name="hpmcounter7h" bitsize="32"/>
  <reg name="hpmcounter8h" bitsize="32"/>
  <reg name="hpmcounter9h" bitsize="32"/>
  <reg name="hpmcounter10h" bitsize="32"/>
  <reg name="hpmcounter11h" bitsize="32"/>
  <reg name="hpmcounter12h" bitsize="32"/>
  <reg name="hpmcounter13h" bitsize="32"/>
  <reg name="hpmcounter14h" bitsize="32"/>
  <reg name="hpmcounter15h" bitsize="32"/>
  <reg name="hpmcounter16h" bitsize="32"/>
  <reg name="hpmcounter17h" bitsize="32"/>
  <reg name="hpmcounter18h" bitsize="32"/>
  <reg name="hpmcounter19h" bitsize="32"/>
  <reg name="hpmcounter20h" bitsize="32"/>
  <reg name="hpmcounter21h" bitsize="32"/>
  <reg name="hpmcounter22h" bitsize="32"/>
  <reg name="hpmcounter23h" bitsize="32"/>
  <reg name="hpmcounter24h" bitsize="32"/>
  <reg name="hpmcounter25h" bitsize="32"/>
  <reg name="hpmcounter26h" bitsize="32"/>
  <reg name="hpmcounter27h" bitsize="32"/>
  <reg name="hpmcounter28h" bitsize="32"/>
  <reg name="hpmcounter29h" bitsize="32"/>
  <reg name="hpmcounter30h" bitsize="32"/>
  <reg name="hpmcounter31h" bitsize="32"/>
  <reg name="sstatus" bitsize="32"/>
  <reg name="sedeleg" bitsize="32"/>
  <reg name="sideleg" bitsize="32"/>
  <reg name="sie" bitsize="32"/>
  <reg name="stvec" bitsize="32"/>
  <reg name="scounteren" bitsize="32"/>
  <reg name="sscratch" bitsize="32"/>
  <reg name="sepc" bitsize="32"/>
  <reg name="scause" bitsize="32"/>
  <reg name="stval" bitsize="32"/>
  <reg name="sip" bitsize="32"/>
  <reg name="satp" bitsize="32"/>
  <reg name="mvendorid" bitsize="32"/>
  <reg name="marchid" bitsize="32"/>
  <reg name="mimpid" bitsize="32"/>
  <reg name="mhartid" bitsize="32"/>
  <reg name="mstatus" bitsize="32"/>
  <reg name="misa" bitsize="32"/>
  <reg name="medeleg" bitsize="32"/>
  <reg name="mideleg" bitsize="32"/>
  <reg name="mie" bitsize="32"/>
  <reg name="mtvec" bitsize="32"/>
  <reg name="mcounteren" bitsize="32"/>
  <reg name="mscratch" bitsize="32"/>
  <reg name="mepc" bitsize="32"/>
  <reg name="mcause" bitsize="32"/>
  <reg name="mtval" bitsize="32"/>
  <reg name="mip" bitsize="32"/>
  <reg name="pmpcfg0" bitsize="32"/>
  <reg name="pmpcfg1" bitsize="32"/>
  <reg name="pmpcfg2" bitsize="32"/>
  <reg name="pmpcfg3" bitsize="32"/>
  <reg name="pmpaddr0" bitsize="32"/>
  <reg name="pmpaddr1" bitsize="32"/>
  <reg name="pmpaddr2" bitsize="32"/>
  <reg name="pmpaddr3" bitsize="32"/>
  <reg name="pmpaddr4" bitsize="32"/>
  <reg name="pmpaddr5" bitsize="32"/>
  <reg name="pmpaddr6" bitsize="32"/>
  <reg name="pmpaddr7" bitsize="32"/>
  <reg name="pmpaddr8" bitsize="32"/>
  <reg name="pmpaddr9" bitsize="32"/>
  <reg name="pmpaddr10" bitsize="32"/>
  <reg name="pmpaddr11" bitsize="32"/>
  <reg name="pmpaddr12" bitsize="32"/>
  <reg name="pmpaddr13" bitsize="32"/>
  <reg name="pmpaddr14" bitsize="32"/>
  <reg name="pmpaddr15" bitsize="32"/>
  <reg name="mcycle" bitsize="32"/>
  <reg name="minstret" bitsize="32"/>
  <reg name="mhpmcounter3" bitsize="32"/>
  <reg name="mhpmcounter4" bitsize="32"/>
  <reg name="mhpmcounter5" bitsize="32"/>
  <reg name="mhpmcounter6" bitsize="32"/>
  <reg name="mhpmcounter7" bitsize="32"/>
  <reg name="mhpmcounter8" bitsize="32"/>
  <reg name="mhpmcounter9" bitsize="32"/>
  <reg name="mhpmcounter10" bitsize="32"/>
  <reg name="mhpmcounter11" bitsize="32"/>
  <reg name="mhpmcounter12" bitsize="32"/>
  <reg name="mhpmcounter13" bitsize="32"/>
  <reg name="mhpmcounter14" bitsize="32"/>
  <reg name="mhpmcounter15" bitsize="32"/>
  <reg name="mhpmcounter16" bitsize="32"/>
  <reg name="mhpmcounter17" bitsize="32"/>
  <reg name="mhpmcounter18" bitsize="32"/>
  <reg name="mhpmcounter19" bitsize="32"/>
  <reg name="mhpmcounter20" bitsize="32"/>
  <reg name="mhpmcounter21" bitsize="32"/>
  <reg name="mhpmcounter22" bitsize="32"/>
  <reg name="mhpmcounter23" bitsize="32"/>
  <reg name="mhpmcounter24" bitsize="32"/>
  <reg name="mhpmcounter25" bitsize="32"/>
  <reg name="mhpmcounter26" bitsize="32"/>
  <reg name="mhpmcounter27" bitsize="32"/>
  <reg name="mhpmcounter28" bitsize="32"/>
  <reg name="mhpmcounter29" bitsize="32"/>
  <reg name="mhpmcounter30" bitsize="32"/>
  <reg name="mhpmcounter31" bitsize="32"/>
  <reg name="mcycleh" bitsize="32"/>
  <reg name="minstreth" bitsize="32"/>
  <reg name="mhpmcounter3h" bitsize="32"/>
  <reg name="mhpmcounter4h" bitsize="32"/>
  <reg name="mhpmcounter5h" bitsize="32"/>
  <reg name="mhpmcounter6h" bitsize="32"/>
  <reg name="mhpmcounter7h" bitsize="32"/>
  <reg name="mhpmcounter8h" bitsize="32"/>
  <reg name="mhpmcounter9h" bitsize="32"/>
  <reg name="mhpmcounter10h" bitsize="32"/>
  <reg name="mhpmcounter11h" bitsize="32"/>
  <reg name="mhpmcounter12h" bitsize="32"/>
  <reg name="mhpmcounter13h" bitsize="32"/>
  <reg name="mhpmcounter14h" bitsize="32"/>
  <reg name="mhpmcounter15h" bitsize="32"/>
  <reg name="mhpmcounter16h" bitsize="32"/>
  <reg name="mhpmcounter17h" bitsize="32"/>
  <reg name="mhpmcounter18h" bitsize="32"/>
  <reg name="mhpmcounter19h" bitsize="32"/>
  <reg name="mhpmcounter20h" bitsize="32"/>
  <reg name="mhpmcounter21h" bitsize="32"/>
  <reg name="mhpmcounter22h" bitsize="32"/>
  <reg name="mhpmcounter23h" bitsize="32"/>
  <reg name="mhpmcounter24h" bitsize="32"/>
  <reg name="mhpmcounter25h" bitsize="32"/>
  <reg name="mhpmcounter26h" bitsize="32"/>
  <reg name="mhpmcounter27h" bitsize="32"/>
  <reg name="mhpmcounter28h" bitsize="32"/>
  <reg name="mhpmcounter29h" bitsize="32"/>
  <reg name="mhpmcounter30h" bitsize="32"/>
  <reg name="mhpmcounter31h" bitsize="32"/>
  <reg name="mhpmevent3" bitsize="32"/>
  <reg name="mhpmevent4" bitsize="32"/>
  <reg name="mhpmevent5" bitsize="32"/>
  <reg name="mhpmevent6" bitsize="32"/>
  <reg name="mhpmevent7" bitsize="32"/>
  <reg name="mhpmevent8" bitsize="32"/>
  <reg name="mhpmevent9" bitsize="32"/>
  <reg name="mhpmevent10" bitsize="32"/>
  <reg name="mhpmevent11" bitsize="32"/>
  <reg name="mhpmevent12" bitsize="32"/>
  <reg name="mhpmevent13" bitsize="32"/>
  <reg name="mhpmevent14" bitsize="32"/>
  <reg name="mhpmevent15" bitsize="32"/>
  <reg name="mhpmevent16" bitsize="32"/>
  <reg name="mhpmevent17" bitsize="32"/>
  <reg name="mhpmevent18" bitsize="32"/>
  <reg name="mhpmevent19" bitsize="32"/>
  <reg name="mhpmevent20" bitsize="32"/>
  <reg name="mhpmevent21" bitsize="32"/>
  <reg name="mhpmevent22" bitsize="32"/>
  <reg name="mhpmevent23" bitsize="32"/>
  <reg name="mhpmevent24" bitsize="32"/>
  <reg name="mhpmevent25" bitsize="32"/>
  <reg name="mhpmevent26" bitsize="32"/>
  <reg name="mhpmevent27" bitsize="32"/>
  <reg name="mhpmevent28" bitsize="32"/>
  <reg name="mhpmevent29" bitsize="32"/>
  <reg name="mhpmevent30" bitsize="32"/>
  <reg name="mhpmevent31" bitsize="32"/>
  <reg name="tselect" bitsize="32"/>
  <reg name="tdata1" bitsize="32"/>
  <reg name="tdata2" bitsize="32"/>
  <reg name="tdata3" bitsize="32"/>
  <reg name="dcsr" bitsize="32"/>
  <reg name="dpc" bitsize="32"/>
  <reg name="dscratch" bitsize="32"/>
  <reg name="hstatus" bitsize="32"/>
  <reg name="hedeleg" bitsize="32"/>
  <reg name="hideleg" bitsize="32"/>
  <reg name="hie" bitsize="32"/>
  <reg name="htvec" bitsize="32"/>
  <reg name="hscratch" bitsize="32"/>
  <reg name="hepc" bitsize="32"/>
  <reg name="hcause" bitsize="32"/>
  <reg name="hbadaddr" bitsize="32"/>
  <reg name="hip" bitsize="32"/>
  <reg name="mbase" bitsize="32"/>
  <reg name="mbound" bitsize="32"/>
  <reg name="mibase" bitsize="32"/>
  <reg name="mibound" bitsize="32"/>
  <reg name="mdbase" bitsize="32"/>
  <reg name="mdbound" bitsize="32"/>
  <reg name="mucounteren" bitsize="32"/>
  <reg name="mscounteren" bitsize="32"/>
  <reg name="mhcounteren" bitsize="32"/>
</feature>
';
    if(defined $start and defined $len){
	my $l = length($data);
	print STDERR "start:$start, $len, $l\n";
	if($start+$len>$l){
	    if($start>0){
		return 'l'.substr($data, $start);
	    }else{
		return 'l'.$data;
	    }
	}
	else{
	    return 'm'.substr($data, $start, $len);
	}
    }
    return $data;
}

sub get_riscv_32bit_virtual{
    my $data = '<?xml version="1.0"?>
<!-- Copyright (C) 2018-2019 Free Software Foundation, Inc.

     Copying and distribution of this file, with or without modification,
     are permitted in any medium without royalty provided the copyright
     notice and this notice are preserved.  -->

<!DOCTYPE feature SYSTEM "gdb-target.dtd">
<feature name="org.gnu.gdb.riscv.virtual">
  <reg name="priv" bitsize="64"/>
</feature>';

   return "l$data";  
}

1;

__DATA__
$vCont;s:p1.1;c:p1.-1
$vCont;c:p1.-1

00000A77  70 31 2e 2d 31 23 66 37                            
