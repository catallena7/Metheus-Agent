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
	open FHR,"<$OLD_DATA_FILE" or die("ERROR_CODE::NETWORK00,,SEVERITY::ERROR,,MESSAGE::No file $OLD_DATA_FILE\n");
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
	open FH ,"<$ORI_DATA_FILE" or die ("ERROR_CODE::NETWORK1");
	my $line;
	$metrics{"time"}=time();
	my %oldData;
	my $secs;
	if (-e $OLD_DATA_FILE){
		my %oldData=getOldData();
		$secs=$metrics{"time"}-$oldData{"time"};
	}else{
		print("ERROR_CODE::NETWORK00,,SEVERITY::ERROR,,MESSAGE::No file $OLD_DATA_FILE\n");
	}
	while ($line = <FH>){
		if ($line =~m/\s+(eth\d+):/){
			chomp($line);
			my %line_metrics;
			my $devNo=$1;
			my ($left,$right)=split /:/,$line;
			my @items = split /\s+/,$line;

			$metrics{"rx_".$devNo}=$items[0];
			$line_metrics{"rx"}=$items[0];

			$metrics{"rx_packets_".$devNo}=$items[1];
			$line_metrics{"rx_packets"}=$items[1];

			$metrics{"rx_errs_".$devNo}=$items[2];
			$line_metrics{"rx_errs"}=$items[2];

			$metrics{"rx_drop_".$devNo}=$items[3];
			$line_metrics{"rx_drop"}=$items[3];

			$metrics{"frame_".$devNo}=$items[4];
			$line_metrics{"frame"}=$items[4];

			$metrics{"tx_".$devNo}=$items[8];
			$line_metrics{"tx"}=$items[8];

			$metrics{"tx_packets_".$devNo}=$items[9];
			$line_metrics{"tx_packets"}=$items[9];

			$metrics{"tx_errs_".$devNo}=$items[10];
			$line_metrics{"tx_errs"}=$items[10];

			$metrics{"tx_drop_".$devNo}=$items[11];
			$line_metrics{"tx_drop"}=$items[11];

			$metrics{"colls_".$devNo}=$items[12];
			$line_metrics{"colls"}=$items[12];

			my $outStr="dev_name::".$devNo;
			if($secs >0){
				my $key;
				my $value;
				while (($key,$value) = each %line_metrics){
					my $termValue=($line_metrics{$key}-$oldData{$key."_".$devNo})/$secs;
					if ($key =~/[r|t]x_eth/){
						$termValue=$termValue/1024;
					}
					if ($termValue<0){
						$termValue=0;
					}
					$termValue=sprintf("%.2f",$termValue);
					$outStr=$outStr.",,".$key."::".$termValue;
				}
				print("$outStr\n");
			}
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
	array_to_file ($OLD_DATA_FILE,$oldStr);
}

main();
