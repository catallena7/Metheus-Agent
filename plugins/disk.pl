#!/usr/bin/perl
use strict;
my @ORI_DATA_FILE=`df -l -P`;


sub main(){
	my %metrics;
	my $i=0;
	foreach my $line (@ORI_DATA_FILE){
		chomp($line);

		my @items = split /\s+/,$line;
		if( $items[0] =~m/^\/dev\/(\w+)/){
			my $dev=$1;
			my $total=$items[2]+$items[3];
			$items[4]=~s/%//g;
			print ("dev_name::".$dev.",,used_kbytes::".$items[2].",,total_kbytes::".$total.",,Capacity::".$items[4]."\n");
		}
	}
}

main();
