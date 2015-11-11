#!/usr/bin/perl
use strict;
my @DIRS=("/opt/db-derby-10.11.1.1-bin","/home/metheus");

sub main(){
	my %metrics;
	my $i=0;
	foreach my $dir (@DIRS){
		if (-e $dir && -d $dir){
			my @lines=`du -skx $dir`;
			foreach my $line (@lines){		
				my ($kbytes,$dir)=split /\s+/,$line;
				print ("dir::$dir,,kbytes::$kbytes\n");
			}
		}
	}
}

main();
