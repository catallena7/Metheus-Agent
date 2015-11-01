#!/usr/bin/perl
use strict;
my @ORI_CPU_DATA_FILE=`ps a -w --no-heading -o user,pid,ppid,pcpu,rss,vsz,time,pri,cmd --sort -pcpu`;



sub main(){

	my $i=0;
	foreach my $line (@ORI_CPU_DATA_FILE){
		my %cpu_metrics;
		chomp($line);
		my @items = split /\s+/,$line;
		$cpu_metrics{"user_name"}=$items[0];
		$cpu_metrics{"pid"}=$items[1];
		$cpu_metrics{"ppid"}=$items[2];
		$cpu_metrics{"pcpu"}=$items[3];
		$cpu_metrics{"rss"}=$items[4];
		$cpu_metrics{"vsz"}=$items[5];
		$cpu_metrics{"elapsed_time"}=$items[6];
		$cpu_metrics{"priority"}=$items[7];
		$cpu_metrics{"cmd"}="";
		for (my $j=8;$j<=$#items;$j++){
			$cpu_metrics{"cmd"}=$cpu_metrics{"cmd"}.$items[$j]." ";
		}
		$cpu_metrics{"cmd"}=substr ($cpu_metrics{"cmd"},0,100);
		my $key;
		my $value;
		my $outStr;
		while (($key,$value) = each %cpu_metrics){
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
