#!/usr/bin/perl
use strict;
my @ORI_MEM_DATA_FILE=`ps -A -w --no-heading -o user,pid,ppid,pcpu,pmem,rss,vsz,time,pri,cmd --sort -rss`;
my $BASE_RSS=10;#This script will display only 10% over memory usage process info 

sub main(){

	my $i=0;
	foreach my $line (@ORI_MEM_DATA_FILE){
		my %mem_metrics;
		chomp($line);
		my @items = split /\s+/,$line;
		$mem_metrics{"user_name"}=$items[0];
		$mem_metrics{"pid"}=$items[1];
		$mem_metrics{"ppid"}=$items[2];
		$mem_metrics{"pcpu"}=$items[3];
		$mem_metrics{"pmem"}=$items[4];
		if ($mem_metrics{"pmem"}<$BASE_RSS){
			last;
		}
		$mem_metrics{"rss"}=$items[5];
		$mem_metrics{"vsz"}=$items[6];
		$mem_metrics{"elapsed_time"}=$items[7];
		$mem_metrics{"priority"}=$items[8];
		$mem_metrics{"cmd"}="";
		for (my $j=9;$j<=$#items;$j++){
			$mem_metrics{"cmd"}=$mem_metrics{"cmd"}.$items[$j]." ";
		}
		$mem_metrics{"cmd"}=substr ($mem_metrics{"cmd"},0,100);
		my $key;
		my $value;
		my $outStr;
		while (($key,$value) = each %mem_metrics){
			$outStr=$outStr.$key."::".$value.",,";
		}
		$outStr=~s/,,$/\n/g;
		print $outStr;
		if ($i>10){
			last;
		}
		$i++;
	}
}

main();
