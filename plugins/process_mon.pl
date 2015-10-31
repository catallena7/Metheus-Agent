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
			for (my $j=7;$j<=$#items;$j++){
				$metrics{"cmd"}=$metrics{"cmd"}.$items[$j]." ";
			}
			$metrics{"cmd"}=substr ($metrics{"cmd"},0,100);
			my $pcpu=$metrics{"pcpu"};
			if ($pcpu >20 && $metrics{"elapsed_time"}=~m/\d+\-/){
				print ("ERROR_CODE:AGENT_CPU0,SEVERITY:FATAL,MESSAGE:$pid Process CPU usage is $pcpu%\n");
			}
			my $rss=$metrics{"rss"};
			if ($rss >2000000) && $metrics{"elapsed_time"}=~m/\d+\-/){
				print ("ERROR_CODE:AGENT_MEM0,SEVERITY:WARN,MESSAGE:$pid Process MEM usage is $rss Bytes\n");
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
