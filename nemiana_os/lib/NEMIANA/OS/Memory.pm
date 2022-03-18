#!/usr/bin/env perl
#
package NEMIANA::OS::Memory;
use strict;
use warnings;
use Data::Dumper;

use strict;
use warnings;
use Data::Dumper;
use FileHandle;
$Data::Dumper::Sortkeys=1;

sub read_data_byte{
    my ($fh) = @_;
    my %result;
    print STDERR "read_data_byte:$fh\n";
    while (my $line= <$fh>){
	chop $line;
	if($line =~ s/^S3(\w{2})(\w{8})(\w+)(\w{2})//){
	    my ($len, $start_addr, $data, $csum) = ($1, hex($2), $3, $4);
	    $data =~ tr/A-Z/a-z/;
	    my $addr = $start_addr+0;
	    while($data=~ s/^(\w\w)//){
		$result{$addr} = hex($1);
		$addr++;
	    }
	}
    }
    return (\%result);
}

sub read_data_word{
    my ($fh) = @_;
    my %result;
    
    while (my $line= <$fh>){
	chop $line;
	if($line =~ s/^S3(\w{2})(\w{8})(\w+)(\w{2})//){
	    my ($len, $start_addr, $data, $csum) = ($1, hex($2), $3, $4);
	    my @data;
	    $data =~ tr/A-Z/a-z/;
	    while($data=~ s/^(\w\w)//){
		push @data, hex($1);
	    }
	    push @data, 0;
	    push @data, 0;
	    push @data, 0;
#	    print "$len, $start_addr, data=[", join(', ', @data), "] $csum\n";

	    my $addr=$start_addr;
	    for(my $i=0;$i<=$#data-3;$i+=4){
		my $d=0;
		my $j=0;
		while($j<4){
		    $d = $d * 256 + $data[$i+3-$j];
		    $j++;
		}
		$result{$addr+$i}=$d;
	    }
	}
    }
    return (\%result);
}





