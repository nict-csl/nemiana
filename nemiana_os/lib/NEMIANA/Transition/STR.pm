#!/usr/bin/env perl
#
package NEMIANA::Transition::STR;
use strict;
use warnings;
use Data::Dumper;

our $VAR1;
our $VAR2;

sub load {
    my ($fh) = @_;
    my @str_list;


    my $lines ="";

    while(my $line = <$fh>){
	$lines .= $line;

	if($line =~ /^[\r\n\f\s]*$/){
#	    print STDERR "eval $lines\n";
	    eval($lines);
	    push @str_list, $VAR1;
	    $lines = "";
	}
    }

    return \@str_list
}

sub dump {
    my ($self, $fh)=@_;

    print {$fh} "{",$self->{count} ,"\n";
    print {$fh} "  count=",$self->{count} ,"\n";
    print {$fh} "  type=",$self->{type} ,"\n";
    if(defined $self->{reg}){
	print {$fh} "  ,reg {\n";
	foreach my $num (sort {$a <=>$b} (keys %{$self->{reg}})){
	    print {$fh} sprintf("    %02d => %08X\n", $num, $self->{reg}->{$num});
	}
	print {$fh} "  }\n";
    }
    if(defined $self->{memory}){
	my %data;
	foreach my $addr (keys %{$self->{memory}}){
	    my $offset = $addr % 4;
	    my $addr4  = $addr - $offset;

	    if(exists $data{$addr4}){
		$data{$addr4} += $self->{memory}->{$addr}<<($offset * 8);
	    }else{
		$data{$addr4}  = $self->{memory}->{$addr}<<($offset * 8);
	    }
	}
	print {$fh} "  ,memory{\n";
	foreach my $addr (sort {$a <=>$b} (keys %data)){
	    print {$fh} sprintf("    %08X => %08X\n", $addr, $data{$addr});
	}
	print {$fh} "  }\n";
    }
    print {$fh} "}\n\n";
}

1;
