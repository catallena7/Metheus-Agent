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
			$metrics{"dev_".$i}=$1;
			$metrics{"used_".$i}=$items[2];
			$metrics{"avail_".$i}=$items[3];
			$items[4]=~s/%//g;
			$metrics{"usedP_".$i}=$items[4];
		$i++;
		}
	
	}
	my $key;
	my $value;
	my $outStr;
	while (($key,$value) = each %metrics){
		$outStr=$outStr.$key."::".$value.",,";
	}
	$outStr=~s/,,$/\n/g;
	print $outStr;
}

main();
