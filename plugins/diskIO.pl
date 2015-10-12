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
			print("dev_name::".$items[0].",,tps::".$items[1].",,kb_readPsec::".$items[2].",,kb_wrtnPsec::".$items[3].",,kb_read::".$items[4].",,kb_wrtn::".$items[5]."\n");
		}
		if ($flag ==0 && $line =~m/Device:/){
			$flag=1;
		}
	}
}

main();
