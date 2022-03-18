#!/usr/bin/env perl
#
package NEMIANA::Stub::PoyoVStub;
use strict;
use warnings;
use Data::Dumper;
use NEMIANA::Stub;
use NEMIANA::Stub::GDBRSP;
use NEMIANA::Stub::GDBClient;
use LWP::UserAgent;
use NEMIANA::Transition::STR;
use Carp;
our @ISA = ('NEMIANA::Stub');

our $step_execution_mode = 0;


sub init_stub {
    my ($process, $type, $profile) = @_;

    print STDERR "init_stub($process, $type, $profile)\n";

    my $self = new NEMIANA::Stub::PoyoVStub($process);
    NEMIANA::Stub::init_stub_main($self, $process, $type, $profile);
    
    $self->load_program($profile);
    $self->open_target($profile);
    $self->connect();
    return $self;
}

sub new {
    my ($class, $process) = @_;

    print STDERR "new($class, $process)\n";
    
    my $self  = {};
    bless $self, $class;
    NEMIANA::Stub::init($self, $process);

    return $self;
}

sub load_program{
    my ($self) = @_;
}

sub kill{
    my ($self) = @_;

    $self->close_poyov_server();
}

sub open_target{
    my ($self, $profile) = @_;

    $self->open_poyov_server($profile->{tools}->{poyov_server}->{dir},
			     $profile->{tools}->{poyov_server}->{program},
			     $profile->{tools}->{poyov_server}->{addr});
}

sub open_poyov_server {
    my ($self, $poyov_dir, $server_prog, $addr) =@_;
    
    print STDERR "open_poyov_server($self, $poyov_dir, $server_prog, $addr) \n";
    
    $self->{host} = $addr;
    
    my $logfile = File::Spec->rel2abs($self->{trace_filename});
    #    my $command = "|ssh $addr \"cd ${poyov_dir};sudo $server_prog >aaa.log\"";
    my $command = "|$server_prog";
    my $fh;
    print STDERR "command=$command\n";
    open $fh , $command;
    print STDERR "fh==$fh\n";
    $self->{poyov_fh} = $fh;
}

sub close_poyov_server {
    my ($self) = @_;

    $self->exit_cpu();

    my $fh = $self->{poyov_fh};
    return if(!defined $fh);
    print $fh "quit\n";
    close $fh if(defined $fh);
    delete $self->{poyov_fh};
}

sub connect {
    my ($self) = @_;

    print STDERR "connect($self)\n";

    my $profile = $self->{profile};

    my $addr = $profile->{tools}->{poyov_server}->{addr};
    my $port = $profile->{tools}->{poyov_server}->{port};

    $self->{target_url}->{trace}  = "http://${addr}:${port}/trace";
    $self->{target_url}->{write}  = "http://${addr}:${port}/write";
    $self->{target_url}->{resume} = "http://${addr}:${port}/resume";
    $self->{target_url}->{reset}  = "http://${addr}:${port}/reset";
    $self->{target_url}->{init}  = "http://${addr}:${port}/init";
    $self->{target_url}->{'exit'} = "http://${addr}:${port}/exit";
    $self->{target_url}->{state}  = "http://${addr}:${port}/state";

    ## for Verilator version.
    $self->{target_url}->{data}   = "http://${addr}:${port}/data";
    $self->{target_url}->{run}    = "http://${addr}:${port}/run";
    $self->{target_url}->{step}   = "http://${addr}:${port}/step";
    $self->{ua} = LWP::UserAgent->new();
    $self->init_cpu();
}

sub init_cpu {
    my ($self) = @_;

    print STDERR "init_cpu();\n";
    
    $self->{ua}->get($self->{target_url}->{init});
}

sub start_cpu {
    my ($self) = @_;
    $self->{ua}->get($self->{target_url}->{clear});
    if($step_execution_mode){
	$self->{ua}->get($self->{target_url}->{step});
    }
    else{
	$self->{ua}->get($self->{target_url}->{run});
    }
}

sub reset_cpu {
    my ($self) = @_;

    print STDERR "reset_cpu();\n";
    
    my $response = $self->{ua}->get($self->{target_url}->{reset});
    if(!$step_execution_mode){
	$response = $self->{ua}->get($self->{target_url}->{step});
    }
    else{
	$response = $self->{ua}->get($self->{target_url}->{run});
    }

    return $response;
}

sub exit_cpu {
    my ($self) = @_;
    print STDERR "exit_cpu();\n";
    my $response = $self->{ua}->get($self->{target_url}->{exit});

    return $response;
}

sub gen_reg_modify{
    my ($addr, $data)=@_;

    $addr &= 0x0FFFFFFF;
    $addr |= 0x80000000;
    if(!defined $data){
	print STDERR sprintf("data err!:%08X\n", $addr);
    }
    my $str = sprintf("%08X %08X\n", $addr, $data);

    return $str;
}

sub gen_pc_modify{
    my ($data)=@_;

    my $addr = 0x40000000;
    my $str = sprintf("%08X %08X\n", $addr, $data);

    return $str;
}

sub gen_memory_modify{
    my ($addr, $data)=@_;
    if(!defined $data){
	print STDERR sprintf("error in gen_memory_modify(%08X)\n",$addr);
    }

    $addr &= 0x0FFFFFFF;
    $addr |= 0x20000000;


    
    my $str = sprintf("%08X %08X\n", $addr, $data);
    
    return $str;
}

sub gen_code_memory_modify{
    my ($addr, $data)=@_;

    $addr &= 0x0FFFFFFF;
    $addr |= 0x10000000;
    my $str = sprintf("%08X %08X\n", $addr, $data);

    return $str;
}

sub get_memory{
    my ($self, $addr) =  @_;
    # not implimented

    print STDERR sprintf("Poyov::get_memory(%08X);\n", $addr);
    return 0;
}

sub get_reg{
    my ($self) =  @_;

    my @result;
    for(my $i=0;$i<32;$i++){
	my $url =$self->{target_url}->{data} . "/reg/$i";
	my $response = $self->{ua}->get($url);
	
	if($response->is_success){
	    my $content = $response->content;
#	    print STDERR "get_reg($i)=$content\n";
	    if($content =~ /reg\:\d+\s+([\dA-Fa-f]+)/){
		$result[$i] = hex($1);
	    }
	}
    }
    return @result;
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

sub set_reg {
    my ($self, $reg_num, $val)=@_;
    my $str;
    ## RISV-V depend
    #print STDERR sprintf("set_reg(%d, %08X)\n", $reg_num, $val);

    # RISV-V32 depend

    if($reg_num<32){
	$str = gen_reg_modify($reg_num, $val);
    }
    else{
	$str = gen_pc_modify($val);
	print STDERR Carp::longmess sprintf("PC set %08X\n", $val);
    }

    my $req=HTTP::Request->new(POST=>$self->{target_url}->{write});
    $req->content($str);
    my $response = $self->{ua}->request($req);
}

sub set_memory {
    my ($self, $addr, $val)=@_;

    print STDERR sprintf("set_memory(%08X, %08X)\n", $addr, $val);
    
    my 	$str = gen_memory_modify($addr, $val);

    my $req=HTTP::Request->new(POST=>$self->{target_url}->{write});
    $req->content($str);
    my $response = $self->{ua}->request($req);
}

sub set_str {
    my ($self, $str)=@_;

    my $content="";
    
    foreach my $reg_num (keys %{$str->{reg}}){
	## Depend RISC-V 32bit
	if($reg_num<32){
	    $content .= gen_reg_modify($reg_num, $str->{reg}->{$reg_num});
	}
	else{
	    $content .= gen_pc_modify($str->{reg}->{$reg_num});
	    print STDERR Carp::longmess sprintf("PC set %08X\n", $str->{reg}->{$reg_num});
	}
    }

    my %word_val;
    foreach my $addr (keys %{$str->{memory}}){
	my $bit     = $addr & 3;
	my $al_addr = $addr - $bit;
	
	if(!exists $word_val{$al_addr}){
	    $word_val{$al_addr} = 0;
	}
	$word_val{$al_addr} += $str->{memory}->{$addr}<<($bit*8);
    }

    foreach my $addr (keys %word_val){
	if($addr >= 0x80000000){
	    $content .= gen_memory_modify($addr, $word_val{$addr});
	}
    }
    my $req=HTTP::Request->new(POST=>$self->{target_url}->{write});
    $req->content($content);
    my $response = $self->{ua}->request($req);
}


sub cut {
    my ($val, $from, $to) = @_;
    return (($val & ((1<<($from+1))-1))>>$to)
}

sub parse_attr {
    my ($attr) = @_;

    my $src1_attr = {
	reg_num  => cut($attr, 29, 25),
	imm_flag => cut($attr, 30, 30),
	pc_flag  => cut($attr, 31, 31)
    };
    my $src2_attr = {
	reg_num  => cut($attr, 22, 18),
	imm_flag => cut($attr, 23, 23),
	pc_flag  => cut($attr, 24, 24)
    };
    my $dest_attr = cut($attr, 17, 13);
    my $res = {
	src1_attr  => $src1_attr,
	src2_attr  => $src2_attr,
	dest_attr  => $dest_attr,
	jump_flag  => cut($attr, 12, 12),  #1bit
	ex_is_load => cut($attr, 11, 11),  #1bit
	br_taken   => cut($attr, 10, 10),  #1bit
	pc         => cut($attr,  9,  0)  #10bit
    };

    return $res;
}

sub parse_trace_info_line{
    my ($processor, $line) = @_;
    if($line =~ s/^attr2://){
	$line=~s/[xX]/f/g;
	my ($pc, $src, $dest, $attr) = map {hex($_)} split(/,/, $line);

	if($attr == 0xfedcba98 or $pc>=0xf0000000){
	    return;
	}
	if(!defined $processor->get_memory($pc)){
	    print STDERR sprintf("code is not in%08X, $pc\n", $pc);
	}
	my $inst = $processor->get_memory_word($pc);
	print STDERR sprintf("inst:%08X, %08X\n", $pc, $inst);
	#	printf "attr2:$pc, $src, $dest, $attr, $inst\n";
	# printf("attr2:%08X, %08X, %08X, %08X, %08X\n", $pc, $src, $dest, $attr, $inst);
	#	my $inst_attr = IanaDB::Decode::decode($inst);
	#	$inst_attr->{'opcode_str'} = $op_dict{$inst_attr->{'opcode'}};

	my $dest_attr = parse_attr($attr);
	my $trace_info = {
	    attr=>$attr,
	    dest=>$dest,
	    src=>$src,
	    inst=>$inst,
	    #	    inst_attr=>$inst_attr,
	    dest_attr=>$dest_attr,
	    line=>$line
	};
	if(defined $pc){
	    $trace_info->{pc}=$pc;
	}

	return $trace_info;
    }

    return;
}

sub parse_trace{
    my ($self, $trace_text, $count)=(@_, 0);

    my $processor = $self->{processor};
    print STDERR "parse_trace($processor)\n";
    my @trace_info_list;
    while($trace_text =~s/^([^\r\n\f]*)[\r\n\f]+//){
	my $line = $1;
	my $trace_info = parse_trace_info_line($processor, $line);
	if(defined $trace_info){
	    $trace_info->{count} = $count;
	    push @trace_info_list, $trace_info;
	    $count++;
	}
    }

    if($#trace_info_list<0){
	print STDERR "parse_trace():trace_info_list is empty,'$trace_text'\n";
    }

    return \@trace_info_list;
}

sub resume {
    my ($self) = @_;
    print STDERR "resume($self);\n";
    my $response = $self->{ua}->get($self->{target_url}->{resume});
    if($response->is_success){
	my $content = $response->content;
	$content=~s/\r//g;
	print  {$self->{log_fh}} $content;

	if($step_execution_mode){
	    $self->{ua}->get($self->{target_url}->{step});
	}
	else{
	    $self->{ua}->get($self->{target_url}->{run});
	}
	return $content;
    }
    return ;
}

sub get_state{
    my ($self) = @_;
    print STDERR "get_state($self);\n";
    my $response = $self->{ua}->get($self->{target_url}->{state});
    if($response->is_success){
	my $content = $response->content;
	$content=~s/\r//g;
	print  {$self->{log_fh}} $content;
	print  STDERR "content=$content\n";
	if($content=~/GPIO\:\s*([\dA-Fa-f]+)/){
	    my $val = hex($1);
	    print  {$self->{log_fh}} "val=$val\n";

	    my %attr = (
		ecall=>$val & 1,
		stall=>($val >> 2) & 1
	    );
	    print  {$self->{log_fh}} "attr=",Dumper \%attr,"\n";
	    print  STDERR  "attr=",Dumper \%attr,"\n";
	    return \%attr;
	}
	return;
    }

    return;
}

sub get_trace{
    my ($self) = @_;

    my $url = $self->{target_url}->{trace};
    print STDERR "get_trace($self), $url;\n";
    my $response = $self->{ua}->get($url);
    if($response->is_success){
	my $content = $response->content;
	print STDERR "**********\nget_trace=",$content,"****************\n\n\n";
	while($content eq ""){
	    my $attr =$self->get_state();
	    if(defined $attr
	       and $attr->{stall}){
		print STDERR "resume cpu in get_trace()\n";
		$self->resume();
		if($step_execution_mode){
		    $self->{ua}->get($self->{target_url}->{step});
		}
		else{
		    $self->{ua}->get($self->{target_url}->{run});
		}
	    }
	    else{
		print STDERR "not resume cpu in get_trace()\n";
	    }

	    $response = $self->{ua}->get($url);
	    if($response->is_success){
		$content = $response->content;
		print STDERR "retry content is '$content'\n";
	    }
	    else{
		print STDERR "content is '$content'\n";
	    }
	}
	
	if(defined $self->{log_fh}){
	    $content=~s/\r//g;
	    print  {$self->{log_fh}} $content;
	    $self->{log_fh}->flush();
	}
	my $attr =$self->get_state();
	if(defined $attr
	   and $attr->{stall}
	   and !$attr->{ecall}){
	    print STDERR "resume cpu in ";
	    $self->resume();
	}
	return $content;
    }
    else{
	print STDERR "error from server:", $response->status_line, "\n";
	die "error from server". $response->status_line. "\n";
    }
    print STDERR "done\n";
    return;
}

## This function is for testing gen_str_from_trace();
sub gen_str {
    my ($self, $trace_info_list, $count) = (@_, 0);

    my $processor = $self->{processor};
    my $platform = $self->{platform};

    my @str_list;
    foreach my $trace_info (@{$trace_info_list}){
	my $str = $platform->gen_str_from_trace($processor, $trace_info, $count);
	if(defined $str){
	    push @str_list, $str;
	    $count++;
	}
    }

    return \@str_list;
}

sub get_trace_info {
    my ($self, $count) = @_;
    
    while(!defined $self->{trace_info_list} or $#{$self->{trace_info_list}}<0){
	my $trace_text = $self->get_trace();
	print {$self->{trace_fh}} $trace_text;
	my $trace_info_list = $self->parse_trace($trace_text, $count);
	print {$self->{log_fh}} "trace_info_list=",Dumper $trace_info_list,"\n";
	$self->{trace_info_list} = $trace_info_list;
	if($#{$trace_info_list}<0){
	    print STDERR "trace_info_list is empty\n";
	}
    }
    print STDERR "get_trace_info:";
    print STDERR $#{$self->{trace_info_list}},"\n";
    my $trace_info = shift @{$self->{trace_info_list}};

    if(! exists $trace_info->{pc}){
	print STDERR "lastpc undefined2 ",Dumper $self->{trace_info_list},"\n";
    }

    return $trace_info;
}

sub step {
    my ($self) = @_;

    my $processor = $self->{processor};
    my $platform = $self->{platform};

    my $trace_info = $self->get_trace_info();
    print STDERR "trace_info=", Dumper $trace_info, "\n\n";
    print STDERR "org_memory(0x20010100)=",$processor->{org_memory}->{0x20010100},"\n";
    my $str = $platform->gen_str_from_trace($processor, $trace_info, $self->{count});

    if(defined $str){
	print {$self->{log_fh}} "current_str=", Dumper $str, "\n\n";
	#	print STDERR "current_str=", Dumper $str, "\n\n";
	print STDERR "current_str=\n";
	NEMIANA::Transition::STR::dump($str, *STDERR);
	print STDERR "\n\n";
	$self->{count}++;
	return $str;
    }

    return;
}

sub skip_instruction {
    my ($self, $current_pc) =@_;

    print STDERR sprintf("skip_instruction(%08X)\n",$current_pc);
    ## pop attr of ecall instruction
    my $trace_info = shift @{$self->{trace_info_list}};
    
    my $attr =$self->get_state();
    if(defined $attr
       and $attr->{stall}
       and $attr->{ecall}){
	## resume from ecall
	$self->set_reg(32, $current_pc+4);
	$self->resume();
    }
    
    return $current_pc+4;
}

1;
