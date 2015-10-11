#!/usr/bin/perl
use strict;
my @ORI_DATA_FILE=`iostat -d -k`;

sub main(){
	my %metrics;
	my $i=0;
	my $flag=0;
	foreach my $line (@ORI_DATA_FILE){
		

		if ($flag >0 && $line =~m/^\w/){#extract
			chomp($line);
			my @items = split /\s+/,$line;			
			$metrics{"dev_".$i}=$items[0];
			$metrics{"kb_read_sec_".$i}=$items[2];
			$metrics{"kb_wrtn_sec_".$i}=$items[3];
			$i++;
		}
		if ($flag ==0 && $line =~m/Device:/){
			$flag=1;
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
