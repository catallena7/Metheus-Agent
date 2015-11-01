#!/usr/bin/perl
use strict;
my $Threshold=95;
my @dirs=("/home" );


sub main(){
	my %metrics;
	for my $dir (@dirs){
		my @ORI_DATA_FILE=`df -l -P $dir`;
		foreach my $line (@ORI_DATA_FILE){
			if ($line=~/^Filesystem/ || $line !~/^\//){
				next;
			}
			chomp($line);
			my @items = split /\s+/,$line;
			$metrics{"usedP"}=$items[4];
			$metrics{"usedP"}=~s/%//g;
			if ($metrics{"usedP"}  > $Threshold){
				print("ERROR_CODE::DISKFull00,,SEVERITY::FATAL,,MESSAGE::$dir Disk usedP is $items[4]. limit $Threshold%\n");
			}
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
