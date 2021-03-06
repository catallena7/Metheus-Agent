#!/usr/bin/perl
use strict;

my @PROCESS_KEYWORDS=("\'MAgent.jar\'","\'derbyrun.jar\'");

sub main(){
	my @pids;
	foreach my $keyword (@PROCESS_KEYWORDS){
		push @pids,`pgrep -f $keyword`;
	}
	foreach my $pid (@pids){ 
		my $cmd="ps -w --no-heading -o user,pid,ppid,pcpu,rss,vsz,etime,pri,cmd -p $pid";
		my @ORI_CPU_DATA_FILE=`$cmd`;
		foreach my $line (@ORI_CPU_DATA_FILE){
			my %metrics;
			chomp($line);
			my @items = split /\s+/,$line;
			$metrics{"user_name"}=$items[0];
			$metrics{"pid"}=$items[1];
			$metrics{"ppid"}=$items[2];
			$metrics{"pcpu"}=$items[3];
			$metrics{"rss"}=$items[4];
			$metrics{"vsz"}=$items[5];
			$metrics{"elapsed_time"}=$items[6];
			$metrics{"priority"}=$items[7];
			$metrics{"cmd"}="";
			for (my $j=8;$j<=$#items;$j++){
				$metrics{"cmd"}=$metrics{"cmd"}.$items[$j]." ";
			}
			$metrics{"cmd"}=substr ($metrics{"cmd"},0,100);
			my $pcpu=$metrics{"pcpu"};
			if ($pcpu >10 && $metrics{"elapsed_time"}=~m/\d+\-/){
				my $pid_str=$metrics{"pid"};
				my $cmd_str=$metrics{"cmd"};
				print ("ERROR_CODE::AGENT_CPU000,,SEVERITY::FATAL,,MESSAGE::PID:$pid_str($cmd_str) CPU usage is $pcpu%\n");
			}
			my $rss=$metrics{"rss"};
			if ($rss >1000000 && $metrics{"elapsed_time"}=~m/\d+\-/){
				my $pid_str=$metrics{"pid"};
				my $cmd_str=$metrics{"cmd"};
				print ("ERROR_CODE::AGENT_MEM000,,SEVERITY::WARN,,MESSAGE::PID:$pid_str($cmd_str) MEM usage is $rss KBytes\n");
			}
			my $key;
			my $value;
			my $outStr;
			while (($key,$value) = each %metrics){
				$outStr=$outStr.$key."::".$value.",,";
			}
			$outStr=~s/,,$/\n/g;
			print $outStr;
		}
	}
}

main();
