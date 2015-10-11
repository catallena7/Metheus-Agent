#!/usr/bin/perl
use strict;
my $ORI_DATA_FILE="/proc/stat";

sub main(){

	open FH,"<$ORI_DATA_FILE" or die("ERROR_CODE:CPU1");
	my $line;
	my %metrics;
	while ($line=<FH>){
		if ($line =~/^cpu\s+/){

			my @items=split / /,$line;
			$metrics{"cpu_user"}=$items[2];
			$metrics{"cpu_nice"}=$items[3];
			$metrics{"cpu_system"}=$items[4];
			$metrics{"cpu_idle"}=$items[5];
			$metrics{"cpu_iowait"}=$items[6];
			$metrics{"cpu_irq"}=$items[7];
			$metrics{"cpu_softirq"}=$items[8];
			my $key;
			my $value;
			my $sum=0;
			while (($key,$value) = each %metrics){
				#print "$key,$value,$sum\n";
				$sum=$sum+$value;
			}
			my $outStr="";
			while (($key,$value) = each %metrics){
				my $result=sprintf("%.2f",($value*100/$sum));
				#print $key.":".$value."/".$sum."\n";
				$outStr=$outStr.$key."::".$result.",,";
			}
			$outStr=~s/,,$/\n/g;
			print $outStr;
		}
	}	
	close FH;    
}

main();
