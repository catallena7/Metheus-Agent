#!/usr/bin/perl
use strict;
my $ORI_DATA_FILE="/proc/loadavg";
#df -l -P
# iostat -d -k:
#proc/net/dev

sub main(){
	open FH,"<$ORI_DATA_FILE" or print("ERROR_CODE:CPULOAD1,SERRITY:ERROR,MESSAGE:No file\n");
	my $line;
	my %metrics;
	my $retStr="";
	while ($line=<FH>){
		my @items=split / /,$line;
		$metrics{"load1"}=$items[0];
		$metrics{"load5"}=$items[1];
		$metrics{"load15"}=$items[2];
		my $key;
		my $value;
		my $sum=0;
		while (($key,$value) = each %metrics){
			$retStr=$retStr.",,".$key."::".$value;
		}
	
	}	
	close FH;
	$retStr=~s/^,,//;
	print $retStr."\n";    
}

main();
