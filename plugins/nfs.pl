#!/usr/bin/perl
use strict;
my $ORI_DATA_FILE="/proc/self/mountstats";
my $TEMP_DATA_FILE="/home/".$ENV{"USER"}."/nfs_tmp.dat";
my %OLD_DATA;
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

sub getOldDataInMem($){
	my $fileName=$_[0];
	my %OLD_DATA=();
	if (!(-e $fileName)){
		return %OLD_DATA;
	}
	my $err_flag=0;
	open FHD,"<$fileName" or $err_flag=1;
	if ($err_flag==1){
		print("ERROR_CODE::NFS00,,SEVERITY::ERROR,,MESSAGE::Can not Open $ORI_DATA_FILE file\n");
		exit(0);
	}
	my $line;
	while ($line=<FHD>){
		my ($key,$value)=split /,,/,$line;
		$OLD_DATA{$key}=$value;
	}
	close FHD;
	return %OLD_DATA;
}
sub getOldData($){
	my $key=$_[0];
	if (exists $OLD_DATA{$key}){
		print ("old:".$key.":".$OLD_DATA{$key}."\n");
		return $OLD_DATA{$key};
	}
	return 0;
}

sub main(){
	my %OldData;
	if (-e $TEMP_DATA_FILE){
		%OldData=getOldDataInMem($TEMP_DATA_FILE);
	}else{
		print("ERROR_CODE::NFS01,,SEVERITY::ERROR,,MESSAGE::No temp file $TEMP_DATA_FILE\n");
	}
	my $err_flag=0;
	open FH,"<$ORI_DATA_FILE"  or $err_flag=1;
	if ($err_flag==1){
		print("ERROR_CODE::NFS02,,SEVERITY::ERROR,,MESSAGE::No $ORI_DATA_FILE file\n");
		exit(0);
	}
	my $line;
	my $line_cnt=0;
	my $filer="";
	my $user="";
	my $readOps=0;
	my $writeOps=0;
	my $cmdOps=0;
	my $readBytes=0;
	my $writeBytes=0;
	my $age=0;
	my @curData;
	while ($line=<FH>){
		if ($line =~/device/ && $line=~/:/ && $line =~/nfs/){
			my @items=split /\s+/,$line;
			my $filerInfo=$items[1];
	
			if ($filerInfo =~/:/){
				my ($left,$right) = split /:/,$filerInfo;
				$filer=$left;
				my @volDirs=split /\//,$right;
				$user=$volDirs[-1];
				chomp $user;
			}
		}
		if ($line =~/^\s+(age:)\s+(\d+)/){
			$age=$2;
		}
		if ($line =~/^\s+(GETATTR:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}
		if ($line =~/^\s+(LOOKUP:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}
		if ($line =~/^\s+(ACCESS:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}
		if ($line =~/^\s+(READLINK:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}
		if ($line =~/^\s+(READ:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}
		if ($line =~/^\s+(READDIR:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}
		if ($line =~/^\s+(READDIRPLUS:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}
		if ($line =~/^\s+(FSSTAT:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}
		if ($line =~/^\s+(FSINFO:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}	
		if ($line =~/^\s+(PATHCONF:)\s+(\d+)/){
			$readOps=$readOps+$2;
		}	
		#WRITE
		if ($line =~/^\s+(SETATTR:)\s+(\d+)/){
			$writeOps=$writeOps+$2;
		}	
		if ($line =~/^\s+(WRITE:)\s+(\d+)/){
			$writeOps=$writeOps+$2;
		}	
		if ($line =~/^\s+(CREATE:)\s+(\d+)/){
			$writeOps=$writeOps+$2;
		}	
		if ($line =~/^\s+(MKDIR:)\s+(\d+)/){
			$writeOps=$writeOps+$2;
		}	
		if ($line =~/^\s+(MKNOD:)\s+(\d+)/){
			$writeOps=$writeOps+$2;
		}	
		if ($line =~/^\s+(RENAME:)\s+(\d+)/){
			$writeOps=$writeOps+$2;
		}	
		if ($line =~/^\s+(READDIR:)\s+(\d+)/){
			$writeOps=$writeOps+$2;
		}	
		#CMD
		if ($line =~/^\s+(SYMLINK:)\s+(\d+)/){
			$cmdOps=$cmdOps+$2;
		}	
		if ($line =~/^\s+(REMOVE:)\s+(\d+)/){
			$cmdOps=$cmdOps+$2;
		}	

		if ($line =~/^\s+(RMDIR:)\s+(\d+)/){
			$cmdOps=$cmdOps+$2;
		}	
		#BYTES
		if ($line =~/^\s+(bytes:)\s+(\d+)/){
			my @KBitems=split /\s+/,$line;
			$readBytes=$KBitems[6];
			$writeBytes=$KBitems[7];
		}
		if ($line =~/^\s+(REMOVE:)\s+(\d+)/){
			$cmdOps=$cmdOps+$2;
		}
		if ($line =~/^\s+(READDIR:)\s+(\d+)/){
			if ($readOps !=0 && $age>0){ #by account
				my $readOpsP=sprintf("%.2f",($readOps-getOldData($filer."::".$user."::readOps"))/$age);
				my $writeOpsP=sprintf("%.2f",($writeOps-getOldData($filer."::".$user."::writeOps"))/$age);
				my $cmdOpsP=sprintf("%.2f",($cmdOps-getOldData($filer."::".$user."::cmdOps"))/$age);
				my $readBytes=sprintf("%.1f",$readBytes/1024);
				my $writeBytes=sprintf("%.1f",$writeBytes/1024);
				print "user_id::".$user.",,Filer_name::".$filer.",,Data_type::readOpsP,,value::",$readOpsP."\n";
				print "user_id::".$user.",,Filer_name::".$filer.",,Data_type::writeOpsP,,value::",$writeOpsP."\n";
				print "user_id::".$user.",,Filer_name::".$filer.",,Data_type::cmdOpsP,,value::",$cmdOpsP."\n";
				print "user_id::".$user.",,Filer_name::".$filer.",,Data_type::readBytes,,value::",$readBytes."\n";
				print "user_id::".$user.",,Filer_name::".$filer.",,Data_type::writeBytes,,value::",$readOpsP."\n";
			}
			push @curData,$filer."::".$user."::readOps,,".$readOps."\n";
			push @curData,$filer."::".$user."::writeOps,,".$writeOps."\n";
			push @curData,$filer."::".$user."::cmdOps,,".$cmdOps."\n";
			$readOps=0;
			$writeOps=0;
			$cmdOps=0;
			$readBytes=0;
			$writeBytes=0;
			$filer="";
			$user="";
			$age=0;
		}
	}

		
	close FH;
	array_to_file($TEMP_DATA_FILE,@curData);   
}

main();
