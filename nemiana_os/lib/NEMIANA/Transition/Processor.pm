#!/usr/bin/env perl
#
package NEMIANA::Transition::Processor;
use strict;
use warnings;
use Data::Dumper;
use NEMIANA::Transition::STR;

sub new {
    my ($class, $org_memory, $regsize) = @_;
#    print STDERR "Processor::new($class, $org_memory, $regsize)\n";
    my $self = {
	org_memory=>$org_memory,
	step=>0,
	regsize=>$regsize,
	str_list=>[]
    };

    bless $self, $class;
    $self->init();
    return $self;
}

sub clone {
    my ($self)=@_;

    my %org_memory = %{$self->{org_memory}};
    my $regsize    = $self->{regsize};
    my $new_processor= new NEMIANA::Transition::Processor(\%org_memory, $regsize);
    my @str_list = @{$self->{str_list}};
    $new_processor->{str_list} =\@str_list;

    return $new_processor;
}

sub init {
    my ($self)=@_;

    my %regfile;

    for(my $i=0;$i<$self->{regsize};$i++){
	$regfile{$i}=0;
    }
    $self->{regfile}= \%regfile;

    my %current_memory = %{$self->{org_memory}};
    $self->{memory} = \%current_memory;
    
    $self->{step} = 0;
}

sub set_str_list {
    my ($self, $str)=@_;

    $self->{str_list} = $str;
    $self->{step}=0;
}


sub get_regsize{
    my ($self) = @_;

    return $self->{regsize};
}

sub get_org_memory_all {
    my ($self) = @_;
    my %current_memory = %{$self->{org_memory}};

    return \%current_memory;
}

sub get_memory_all{
    my ($self) = @_;
    return $self->{memory};
}

sub get_memory{
    my ($self, $addr) = @_;
    return $self->{memory}->{$addr};
}

sub get_memory_word{
    my ($self, $addr) = @_;
    my $val;

    $val = $self->{memory}->{$addr} +
	($self->{memory}->{$addr+1}<<8) +
	($self->{memory}->{$addr+2}<<16) +
	($self->{memory}->{$addr+3}<<24);
    return $val;
}

sub set_memory{
    my ($self, $addr, $val) = @_;
    $self->{memory}->{$addr} = $val;
}

sub get_register_all{
    my ($self) = @_;

    return $self->{regfile};
}

sub get_registers{
    my ($self) = @_;

    return $self->{regfile};
}

sub set_register {
    my ($self, $num, $val) = @_;
    $self->{regfile}->{$num} = $val;
}


sub next_step {
    my ($self, $str) =@_;

    #    print STDERR "next_step('",Dumper $str,"')\n\n";
    print STDERR "next_step('\n";
    NEMIANA::Transition::STR::dump($str, *STDERR);
    print STDERR "')\n\n";
    
    push @{$self->{str_list}} , $str;
    $self->apply_str($str);
    print STDERR "next_step done\n\n";
}

sub apply_str {
    my ($self, $str) =@_;

    print STDERR "next_step('",Dumper $str,"')\n\n";
    
    push @{$self->{str_list}} , $str;
    my $reg_str = $str->{reg};
    foreach my $num (keys %{$reg_str}){
	$self->{regfile}->{$num} = $reg_str->{$num};
    }
    my $memory_str = $str->{memory};
    foreach my $addr (keys %{$memory_str}){
	$self->{memory}->{$addr} = $memory_str->{$addr};
    }

    print STDERR "Processor::next_step('";

    foreach my $num (sort {$a<=>$b} keys %{$self->{regfile}}){
	print STDERR sprintf("  %02d:%08X\n", $num, $self->{regfile}->{$num});
    }

    print STDERR	"')\n";
    
    return $str;
}

sub get_next_str {
    my ($self) = @_;
    my $str = $self->{str_list}->[$self->{step}];

    return $str;
}

## 
sub step {
    my ($self) = @_;
    print STDERR "step 1\n";
    my $str = $self->get_next_str();
    print STDERR "step 2\n";
    $self->apply_str($str);
    print STDERR "step 3\n";
    $self->{step}++;
    print STDERR "step 4\n";
    return $str;
}

sub migrate {
    my ($self, $org_processor) = @_;

    my $org_reg = $org_processor->get_register_all();
    
    foreach my $num (keys %{$org_reg}){
	$self->set_register($num, $org_reg->{$num});
    }

    my $org_memory = $org_processor->get_memory_all();

    foreach my $addr (keys %{$org_memory}){
	$self->set_memory($addr, $org_memory->{$addr});
    }

    return $self;
}

1;
