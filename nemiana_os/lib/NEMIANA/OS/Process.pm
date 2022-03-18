#!/usr/bin/env perl
#
package NEMIANA::OS::Process;
use strict;
use warnings;
use Data::Dumper;
use NEMIANA::OS::Kernel;
use File::Path qw/mkpath/;
use FileHandle;
use NEMIANA::OS::Memory;
use NEMIANA::Transition::Processor;
use NEMIANA::OS::Syscall;
sub new {
    my ($class, $kernel, $pid, $log_path, $profile)= @_;

    my $self = {};
    bless $self, $class;

    $self->{kernel} = $kernel;
    $self->{pid} = $pid;
    $self->{log_path}=$log_path;
    if(! -d $log_path){
	mkpath $log_path;
    }
    $self->{profile}= $profile;
    my $fh = $kernel->get_str_handle($self);
    $self->{str_fh} = $fh;
    $self->{str_fh}->autoflush(1);

    $self->{syscall} = new NEMIANA::OS::Syscall($profile);
    
    $self->{pre_callback}=[];
    $self->{post_callback}=[];

    if(defined $self->{profile}->{target}->{dir}
       and defined $self->{profile}->{target}->{srec}){
	my $code_filename = $self->{profile}->{target}->{dir} .
	    "/" . $self->{profile}->{target}->{srec};
    
	my $fh = new FileHandle($code_filename, "r");
	if(defined $fh){
	    $self->{org_memory} = NEMIANA::OS::Memory::read_data_byte($fh);
	    close $fh;
	}
    }
    
    return $self;
}

sub get_org_memory{
    my ($self) =@_;
    return $self->{org_memory};
}

sub create_processor{
    my ($self) =@_;
#    print STDERR "create_processor(",Dumper $self,")\n";
    my $regsize = $self->{profile}->{platform}->{regsize};
    my $processor = new NEMIANA::Transition::Processor($self->get_org_memory(), $regsize);

    $self->{processor} = $processor;
    return $processor;
}

sub load {
    my ($self, $str_list) =@_;

    $self->create_processor();
    $self->{processor}->set_str_list($str_list);

#    print STDERR "load($self, $str_list)\n";
#    print STDERR Dumper $self->{processor};
#    print STDERR "\n\n";
    
    return $self;
}

sub fork {
    my ($self, $org_process) =@_;

    $self->{processor} = ($org_process->get_processor())->clone();

    return $self;
}

sub get_processor {
    my ($self) =@_;

    return $self->{processor};
}

sub set_client{
    my ($self, $client) =@_;
    $self->{client} = $client;
}

sub get_pid{
    my ($self) = @_;

    return $self->{pid};
}

sub get_tmp_file {
    my ($self, $filename) = @_;
    my $path = $self->{log_path} . "/${filename}";

    return $path;
}


sub get_log_handle {
    my ($self) = @_;
    my $log_path = $self->get_tmp_file("full.log");
    my $fh = new FileHandle("$log_path", "w");
    $self->{log_fh} = $fh;
    
    return $fh;
}

sub get_trace_log_handle {
    my ($self) = @_;
    my $log_path = $self->get_tmp_file("trace.txt");
    my $fh = new FileHandle("$log_path", "w");
    $self->{trace_fh} = $fh;

    return $fh;
}

sub put_str {
    my ($self, $str) = @_;

    print {$self->{str_fh}} Dumper $str;
    print {$self->{str_fh}} "\n";
    return $self;
}

sub load_program {
    my ($self, $profile) = @_;

    my $memory  =$self->get_org_memory();

    my %str = (
	memory=>$memory,
	reg=>{}
	);
    
    if(defined $self->{client}){

	## set_str()だと動作がおかしい．
	if(0){
	    $self->{client}->set_str(\%str);
	}
	else{
	my %data;
	foreach my $addr (keys %{$memory}){
	    if($addr >0x80000000){
		my $offset = $addr & 3;
		if(!exists $data{$addr-$offset}){
		    $data{$addr-$offset} = 0;
		}
		$data{$addr-$offset} += $memory->{$addr}<<($offset*8);
	    }
	}
	foreach my $addr (keys %data){
	    $self->{client}->set_memory($addr, $data{$addr});
	    print STDERR sprintf("load_program:set_memory(%08X, %08X)\n", $addr, $data{$addr});
	}
	}
    }
    if(defined $self->{processor}){
	foreach my $addr (keys %{$memory}){
	    if($addr >0x80000000){
		$self->{processor}->set_memory($addr, $memory->{$addr});
	    }
	}
    }
}

sub init_cpu {
    my ($self, $profile) = @_;

    my $addr = $profile->{target}->{entry_addr};
    if(defined $self->{client}){
	$self->{client}->init_cpu();
    }

    if(defined $self->{client}){
	for(my $i=0;$i<$profile->{platform}->{regsize};$i++){
	    $self->{client}->set_reg($i, 0);
	}
	$self->{client}->set_reg($profile->{platform}->{regsize}, $addr);
    }
    if(defined $self->{processor}){
	for(my $i=0;$i<$profile->{platform}->{regsize};$i++){
	    $self->{processor}->set_register($i, 0);
	}
	$self->{processor}->set_register($profile->{platform}->{regsize}, $addr);
    }

    $self->load_program($profile);
    
    if(defined $self->{client}){
	$self->{client}->start_cpu();
    }
    return $self;
}

### Platformオブジェクトと連携させる
sub set_next_pc {
    my ($self, $addr) = @_;

    print {$self->{log_fh}} sprintf("set_next_pc(%08X);\n", $addr);
    
    if(defined $self->{client}){
	$self->{client}->set_reg($self->{profile}->{platform}->{regsize}, $addr);
    }
    if(defined $self->{processor}){
	$self->{processor}->set_register($self->{profile}->{platform}->{regsize}, $addr);
    }
}

sub get_next_pc {
    my ($self, $addr) = @_;
    my $pc;
    if(defined $self->{processor}){
	my $regfile = $self->{processor}->get_register_all();
	$pc =  $regfile->{$self->{profile}->{platform}->{regsize}};

    }
    elsif(defined $self->{client}){
	my $regfile = $self->{client}->get_register_all();
	$pc =  $regfile->{$self->{profile}->{platform}->{regsize}};
    }

    return $pc;
}


sub skip_instruction {
    my ($self) = @_;

    my $current_pc = $self->get_next_pc();
    my $next_pc = $current_pc + $self->{profile}->{platform}->{inst_size};

    if(defined $self->{client}){
	$next_pc = $self->{client}->skip_instruction($current_pc);
    }
    if(defined $self->{processor}){
	$self->{processor}->set_register($self->{profile}->{platform}->{regsize}, $next_pc);
    }

    return $next_pc;
}

sub set_register {
    my ($self, $num, $val) = @_;
    if(defined $self->{client}){
	$self->{client}->set_reg($num, $val);
    }
    if(defined $self->{processor}){
	$self->{processor}->set_register($num, $val);
    }
}

sub get_register_all {
    my ($self) = @_;
    my $regfile;
    if(defined $self->{processor}){
	$regfile = $self->{processor}->get_register_all();
    }
    elsif(defined $self->{client}){
	$regfile = $self->{client}->get_register_all();
    }

    return $regfile;
}

sub set_memory {
    my ($self, $addr, $val) = @_;
    if(defined $self->{client}){
	$self->{client}->set_memory($addr, $val);
    }
    if(defined $self->{processor}){
	$self->{processor}->set_memory($addr, $val);
    }
}

sub get_memory {
    my ($self, $addr) = @_;
    my $val;
    if(defined $self->{processor}){
	$val = $self->{processor}->get_memory($addr);
    }
    if(!defined $val and defined $self->{client}){
	$val = $self->{client}->get_memory($addr);
    }

    return $val;
}

sub set_str {
    my ($self, $str) = @_;

    if(defined $self->{client}){
	$self->{client}->set_str($str);
    }
    
    if(defined $self->{processor}){
	foreach my $num (keys %{$str->{reg}}){
	    $self->{processor}->set_register($num, $str->{reg}->{$num});
	}
	foreach my $addr (keys %{$str->{memory}}){
	    $self->{processor}->set_memory($addr, $str->{memory}->{$addr});
	}
    }
}



sub pre_process {
    my ($self) = @_;

#    print STDERR "pre_process($self, ",$self->{kernel}, ")\n";
    my ($skip , $res) = $self->{kernel}->pre_process($self, $self->{processor});
#    my ($skip , $res) = NEMIANA::OS::Kernel::pre_process($self->{kernel}, $self, $self->{processor});
    if($skip){
	return ($skip , $res);
    }
    foreach my $callback (@{$self->{pre_callbak}}){
	($skip , $res) = $callback->($self, $self->{processor}, $res);
	if($skip){
	    return ($skip , $res);
	}
    }

    return (0 , {});
}


sub post_process {
    my ($self, $str) = @_;

    my ($skip, $res) = $self->{kernel}->post_process($self, $self->{processor}, $str);
    if($skip){
	return ($skip , $res);
    }
    
    foreach my $callback (@{$self->{post_callbak}}){
	($skip, $res)  = $callback->($self, $self->{processor}, $res, $str);
	if($skip){
	    return ($skip , $res);
	}
    }

    return (0, $res);
}


sub execute {
    my ($self, $num) = @_;

    my $i=0;

    while(!defined $num or $i<$num){
	$i++;

	if(defined $self->{client}){
	    my ($skip , $str) = $self->pre_process();
	    if($skip){
		my $next_pc =$self->skip_instruction();
		$str->{reg}->{$self->{profile}->{platform}->{regsize}} = $next_pc; ## TO fix using Platform Object
	    }
	    else{
		## Run on Real Processor
		$str = $self->{client}->step();
		$self->{processor}->next_step($str);
		($skip , $str) = $self->post_process($str);
	    }
	    $self->put_str($str);
	}
	else {
	    ## Run on Transition Processor
	    my $str = $self->{processor}->step();
	    $self->put_str($str);
	}
    }

    return 1;
}

sub attach {
    my ($self) = @_;
    if(defined $self->{client}){
	$self->{client}->connect();
    }

    return $self;
}

sub detach {
    my ($self) = @_;
    if(defined $self->{client}){
	$self->{client}->close();
    }

    return $self;
}

sub kill {
    my ($self) = @_;
    if(defined $self->{client}){
	$self->{client}->kill();
    }
    close $self->{log_fh};
    close $self->{trace_fh};

    return $self;
}

sub migrate {
    my ($self, $org_processor) = @_;
    
    if(defined $self->{client}){
	$self->{client}->migrate($org_processor);
    }
    if(defined $self->{processor}){
	$self->{processor}->migrate($org_processor);
    }
    return $self;
}

sub get_platform{
    my ($self) = @_;

    if(defined $self->{client}){
	return $self->{client}->get_platform();
    }
    else{
	return;
    }
}

sub add_pre_callback{
    my ($self, $callback) = @_;

    push @{$self->{pre_callback}}, $callback;
    return $self->{pre_callback};
}

sub add_post_callback{
    my ($self, $callback) = @_;

    push @{$self->{post_callback}}, $callback;

    return $self->{post_callback};
}

sub handle_pre_callback {
    my ($self, $processor) = @_;

    my $total_str = {reg=>{}, memory=>{}};
    if(defined $self->{client}){
	my $pre_str = $self->get_platform()->get_next_str($processor, 0);

	foreach my $event (@{$self->{pre_callback}}){
	    if($event->{cond}->($processor, $pre_str)){
		my ($skip, $str) = $event->{invoke}->($self, $processor, $pre_str);
		if($skip){
		    return ($skip, $total_str);
		}
	    }
	}
    }
    return (0, $total_str);
}

sub handle_post_callback {
    my ($self, $processor,$str) = @_;
    foreach my $event (@{$self->{post_callback}}){
	if($event->{cond}->($processor, $str)){
	    my ($skip, $str) = $event->{invoke}->($self, $processor, $str);
	    if($skip){
		return ($skip, $str);
	    }
	}
    }
    return (0, $str);
}

1;

