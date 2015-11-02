#!/usr/bin/perl
use strict;
my $ORI_DATA_FILE="/proc/loadavg";

sub main(){
	my $err_flag=0;
	open FH,"<$ORI_DATA_FILE" or $err_flag=1;
	if ($err_flag==1){
		print("ERROR_CODE::CPULOAD000,,SEVERITY::ERROR,,MESSAGE::No load avg file\n");
		exit(0);
	}
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
