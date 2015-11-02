#!/usr/bin/perl
use strict;
use Cwd;
use File::stat;
use File::Spec;
use Date::Parse;
        
#WARNING:please check file permission before running this script
my @SYSLOG_FILES=("/var/log/messages","/var/log/secure");
my @KEYWORDS=("error","fail");#case insensitive

my @out_content;

sub setIndex($$){
	my $out=$_[0];
	
	open FHW ,"+>$out";
	print FHW $_[1];
	close FHW;
}

sub getOldEpkTime($){
	my $oldData=$_[0];
	my $err_flag=0;
	open FHR,"<$oldData" or $err_flag=1;
	if ($err_flag==1){
		print("ERROR_CODE::SYSLOG00,,SEVERITY::ERROR,,MESSAGE::Can not open $oldData file\n");
	}
	my $line;
	my $value=1;
	while ($line = <FHR>){
		chomp ($line);
		$value=$line;
	}
	close FHR;
	return $value;
}

sub getOldFileName($){
	my $out=$_[0];
	if ($out =~m/\//){
		my @items=split /\//,$out;
		$out=$items[-1];
		if($ENV{"USER"} eq "root"){
			$out="/var/log/$out.dat";
		}else{
			$out="/home/".$ENV{"USER"}."/$out.dat";
		}
	}
	return $out
}

sub getStrDate($){

	my $time = $_[0];
	my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	my ($sec, $min, $hour, $day,$month,$year) = (localtime($time))[0,1,2,3,4,5]; 
	my $strDay=sprintf("%2s",$day);
	my $strDate="$months[$month] $strDay $hour:$min:$sec ";
	return $strDate;
}

sub main(){
	
	foreach my $logFile (@SYSLOG_FILES){
		my @lines;
		my $etime=0;

		my $oldFile=getOldFileName($logFile);
		my $oldEpkTime=getOldEpkTime($oldFile);
		my $epkTimeLogHead=-1;
		my $strDate=getStrDate($oldEpkTime);
		my $err_flag=0;
		open FH,"<$logFile" or $err_flag=1;
		if ($err_flag==1){
			print("ERROR_CODE::SYSLOG01,,SEVERITY::ERROR,,MESSAGE::Can not open $logFile file\n");
			next;
		}
		my $line;
		while ($line=<FH>){
			my $rawLog;
			if ($line =~m/^(.+)\s+(\d)\s+(\d+):(\d+):(\d+)/){
				$epkTimeLogHead=str2time($&);
				if ($epkTimeLogHead>$oldEpkTime){
					#print ("$& : $epkTimeLogHead \n");
					my $match_flag=0;
					foreach my $keyword (@KEYWORDS){
						if ($line=~m/$keyword/i){
							$match_flag=1;
							#print $line;
						}
					}
					if ($match_flag >= 1){
						$line=~s/'/''/g;
						print ("log_epktime::$epkTimeLogHead,,file::$logFile,,contents::".$line);
					}

				}
			}
		}	
		close FH;
		setIndex($oldFile,$epkTimeLogHead);
		#setIndex($oldFile,0); #for test
	}
}

main();
