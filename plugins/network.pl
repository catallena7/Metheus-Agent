#!/usr/bin/perl
use strict;
my $ORI_DATA_FILE="/proc/net/dev";
my $OLD_DATA_FILE="/home/".$ENV{"USER"}."/network.ini";


my @out_content;

sub array_to_file{
	my @tarray=@_;
	my $out_fn=shift @tarray;
	unlink $out_fn;
	open FH ,"+>>$out_fn";
	foreach (@tarray){
		print FH "$_";
	}
	close FH;
}

sub getOldData{
	open FHR,"<$OLD_DATA_FILE" or die ("ERROR_CODE:NETWORK2");
	my $line;
	my %oldMetrics;
	while ($line = <FHR>){
		chomp ($line);
		my @items=split /,,/,$line;
		foreach my $content (@items){
			my ($key,$value)= split /::/,$content;
			$oldMetrics{$key}=$value;
		}
	}
	close FHR;
	return %oldMetrics;
}

sub main(){
	my %metrics;
	open FH ,"<$ORI_DATA_FILE" or die ("ERROR_CODE:NETWORK1");
	my $line;
	$metrics{"time"}=time();
	while ($line = <FH>){
		if ($line =~m/\s+(eth\d+):/){
			chomp($line);
			my $devNo=$1;
			my ($left,$right)=split /:/,$line;
			my @items = split /\s+/,$line;
			$metrics{"rx_".$devNo}=$items[0];
			$metrics{"rx_packets_".$devNo}=$items[1];
			$metrics{"rx_errs_".$devNo}=$items[2];
			$metrics{"rx_drop_".$devNo}=$items[3];
			$metrics{"frame_".$devNo}=$items[4];
			$metrics{"tx_".$devNo}=$items[8];
			$metrics{"tx_packets_".$devNo}=$items[9];
			$metrics{"tx_errs_".$devNo}=$items[10];
			$metrics{"tx_drop_".$devNo}=$items[11];
			$metrics{"colls_".$devNo}=$items[12];
		}
	}
	close FH;
	my $key;
	my $value;
	my $outStr="";
	my $oldStr="";
	while (($key,$value) = each %metrics){
		$oldStr=$oldStr.$key."::".$value.",,";
	}
	$oldStr=~s/,,$/\n/g;
	if (-e $OLD_DATA_FILE){
		my %oldData=getOldData();
		my $secs=$metrics{"time"}-$oldData{"time"};
		#print "sec=$secs\n";
		while (($key,$value) = each %metrics){
			if ($key eq "time"){
				next;
			}
			if ($secs <=0){
				next;
			}
			my $termValue=($metrics{$key}-$oldData{$key})/$secs;
			if ($key =~/[r|t]x_eth/){
				$termValue=$termValue/1024;
			}
			if ($termValue<0){
				$termValue=0;
			}

			$termValue=sprintf("%.2f",$termValue);
			$outStr=$outStr.$key."::".$termValue.",,";
		}
	}
	$outStr=~s/,,$/\n/g;
	print $outStr;
	array_to_file ($OLD_DATA_FILE,$oldStr);
}

main();
