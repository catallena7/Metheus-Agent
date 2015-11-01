#!/usr/bin/perl
use strict;
my @STDOUT_LINES=`ps -ef | wc -l`;


sub main(){

	my $i=0;
	foreach my $line (@STDOUT_LINES){
		my %metrics;
		chomp($line);
		my @items = split /\s+/,$line;
		$metrics{"No_of_process"}=$items[0];
		my $NoOfProcess=$metrics{"No_of_process"};
		if ($NoOfProcess> 15000){
			print ("ERROR_CODE::NOP00,,SEVERITY::FATAL,,MESSAGE::No of Process is $NoOfProcess\n");
		}elsif ($NoOfProcess> 10000){
			print ("ERROR_CODE::NOP01,,SEVERITY::ERROR,,MESSAGE::No of Process is $NoOfProcess\n");
		}elsif ($NoOfProcess> 3000){
			print ("ERROR_CODE::NOP02,,SEVERITY::WARN,,MESSAGE::No of Process is $NoOfProcess\n");
		}
		my $key;
		my $value;
		my $outStr;
		while (($key,$value) = each %metrics){
			$outStr=$outStr.$key."::".$value."\n";
		}
		print $outStr;
	}
}

main();
