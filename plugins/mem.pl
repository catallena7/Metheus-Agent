#!/usr/bin/perl
use strict;
my $ORI_DATA_FILE="/proc/meminfo";


sub main(){
	my $err_flag=0;
	open FH,"<$ORI_DATA_FILE" or $err_flag=1;
	if ($err_flag==1){
		print("ERROR_CODE::MEM000,,SEVERITY::ERROR,,MESSAGE::No proc mem info\n");
		exit(0);
	}
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
		print ("ERROR_CODE::MEM001,,SEVERITY::WARN,,MESSAGE::Swap space used $usedSwapP%\n");
	}elsif ($usedSwapP>=95){
		print ("ERROR_CODE::MEM002,,SEVERITY::ERROR,,MESSAGE::Swap space used $usedSwapP%\n");
	}elsif ($usedSwapP>=99){
		print ("ERROR_CODE::MEM003,,SEVERITY::FATAL,,MESSAGE::Swap space used $usedSwapP%\n");
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
