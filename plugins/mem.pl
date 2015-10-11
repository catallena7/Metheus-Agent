#!/usr/bin/perl
use strict;
my $ORI_DATA_FILE="/proc/meminfo";


sub main(){

	open FH,"<$ORI_DATA_FILE" or die("ERROR_CODE_MEM1");
	my $line;
	my %metrics;
	while ($line=<FH>){
		if ($line =~/MemTotal:\s+(\d+)\s+kB/){
			$metrics{"MemTotal"}=$1;
		}
		if ($line =~/MemFree:\s+(\d+)\s+kB/){
			$metrics{"MemFree"}=$1;
		}
		if ($line =~/SwapTotal:\s+(\d+)\s+kB/){
			$metrics{"SwapTotal"}=$1;
		}
		if ($line =~/SwapFree:\s+(\d+)\s+kB/){
			$metrics{"SwapFree"}=$1;
		}
		if ($line =~/Buffers:\s+(\d+)\s+kB/){
			$metrics{"Buffers"}=$1;
		}
		if ($line =~/Cached:\s+(\d+)\s+kB/){
			$metrics{"Cached"}=$1;
		}
	}
	my $usedSwapP=sprintf ("%.2f",100-$metrics{"SwapFree"}/$metrics{"SwapTotal"}*100);
	if ($usedSwapP>=60){
		print ("ERROR_CODE:MEM00,SEVERITY:WARN,MESSAGE:Swap space used $usedSwapP%\n");
	}elsif ($usedSwapP>=95){
		print ("ERROR_CODE:MEM00,SEVERITY:ERROR,MESSAGE:Swap space used $usedSwapP%\n");
	}elsif ($usedSwapP>=99){
		print ("ERROR_CODE:MEM00,SEVERITY:FATAL,MESSAGE:Swap space used $usedSwapP%\n");
	}
	my $key;
	my $value;
	my $outStr;
	my $result;

	while (($key,$value) = each %metrics){
		$outStr=$outStr.$key."::".$value.",,";
	}
	$outStr=~s/,,$/\n/g;
	print $outStr;
	close FH;    
}

main();
