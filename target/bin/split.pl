#!/usr/bin/env perl
#

use strict;
use warnings;
use Data::Dumper;
use FileHandle;
$Data::Dumper::Sortkeys=1;

my %code_mem;
my %data_mem;

#my $code_mem_from = 0x00000000;
#my $code_mem_to   = 0x00010000;
#my $data_mem_from = 0x00010000;
#my $data_mem_to   = 0x00020000;

#my $code_mem_from = 0x08000000;
#my $code_mem_to   = 0x10000000;
#my $data_mem_from = 0x20000000;
#my $data_mem_to   = 0x30000000;
my $code_mem_from = 0x20010000;
my $code_mem_to   = 0x20020000;
my $data_mem_from = 0x80000000;
my $data_mem_to   = 0x80008000;

sub is_code_mem {
    return (($_[0]>=$code_mem_from) && ($_[0]<$code_mem_to));
}
sub is_data_mem {
    return (($_[0]>=$data_mem_from) && ($_[0]<$data_mem_to));
}

sub read_data {
    my ($fh, $code_mem, $data_mem) = @_;

    my $max_code_addr= 0;
    my $max_data_addr= 0;
    
    while (my $line= <$fh>){
	chop $line;
	if($line =~ s/^S3(\w{2})(\w{8})(\w+)(\w{2})//){
	    my ($len, $start_addr, $data, $csum) = ($1, hex($2), $3, $4);
	    my @data;
	    $data =~ tr/A-Z/a-z/;
	    while($data=~ s/^(\w\w)//){
		push @data, $1;
	    }
#	    print "$len, $start_addr, data=[", join(', ', @data), "] $csum\n";

	    my $addr=$start_addr;
	    foreach my $d (@data){
		if(is_code_mem($addr)){
		    $code_mem->{$addr}= $d;
		    if($max_code_addr<$addr){
			$max_code_addr = $addr;
		    }
		}
		elsif(is_data_mem($addr)){
		    $data_mem->{$addr}= $d;
		    if($max_data_addr<$addr){
			$max_data_addr = $addr;
		    }
		}
		$addr+=1;
	    }
	}
    }
    return ($max_code_addr, $max_data_addr);
}

sub print_code_mem{
    my ($fh, $code_mem, $max_addr) = @_;
    for(my $i=$code_mem_from;$i<$max_addr;$i+=4){
	my $d0 = exists $code_mem{$i  } ? $code_mem{$i  } : '00';
	my $d1 = exists $code_mem{$i+1} ? $code_mem{$i+1} : '00';
	my $d2 = exists $code_mem{$i+2} ? $code_mem{$i+2} : '00';
	my $d3 = exists $code_mem{$i+3} ? $code_mem{$i+3} : '00';
#	print $fh "$d3$d2$d1$d0 //",sprintf("%08X", $i),"\n"
	print $fh "$d3$d2$d1$d0\n"
    }
}

sub print_data_mem{
    my ($fh0, $fh1, $fh2, $fh3, $data_mem, $max_addr) = @_;
    for(my $i=$data_mem_from;$i<$max_addr;$i+=4){
	my $d0 = exists $data_mem{$i  } ? $data_mem{$i  } : '00';
	my $d1 = exists $data_mem{$i+1} ? $data_mem{$i+1} : '00';
	my $d2 = exists $data_mem{$i+2} ? $data_mem{$i+2} : '00';
	my $d3 = exists $data_mem{$i+3} ? $data_mem{$i+3} : '00';
	#print "$d0$d1$d2$d3 //",sprintf("%08X", $i),"\n";
	    ##	print "$d0$d1$d2$d3\n";
	print $fh0 "$d0\n";
	print $fh1 "$d1\n";
	print $fh2 "$d2\n";
	print $fh3 "$d3\n";
    }
}

my($code_addr, $data_addr) = read_data(*STDIN, \%code_mem, \%data_mem);

my $fh = new FileHandle(shift @ARGV, "w") or die;
#print $fh "###code mem\n";
print_code_mem($fh, \%code_mem, $code_addr);
close $fh;

my @fh;
my $filehead = shift @ARGV;
for(my $i=0;$i<4;$i++){
    $fh[$i] = new FileHandle("${filehead}${i}.hex", "w") or die;
}
#print "###data mem\n";
print_data_mem(@fh, \%data_mem, $data_addr);



