#!/usr/bin/perl -w

my $PWD=`pwd`;
chomp($PWD);
use lib "$ENV{'HOME'}/software";

use strict;
use warnings;

use Project::Lite;
use Data::Dumper;
use File::Path;
use Switch;

my $object=Project::Lite->new();
if(!-e $Diary_dir){
	print STDOUT "New Machine!!\n";
	mkpath($Diary_dir);
	mkpath($backup_dir);
}
chdir($Diary_dir);
my $lat_diary_dir;
my %display;
my @diaries=`ls -l | grep "^d" | awk -F " " '{print \$NF}'`;
#print Dumper @diaries;exit;
if($#diaries==-1) { 
	print STDOUT "No indexed Diary right now\nPlease enter your Diary Name\n";
	my $diary_name=<STDIN>;
	chomp($diary_name);
	if($diary_name){
		$lat_diary_dir="$Diary_dir".$diary_name;
		print($lat_diary_dir);
		mkpath($lat_diary_dir);
	}
}
else{
	my $i=1;
	%display=map {$i++ => &mychomp($_)} @diaries;
	$display{$i}="Start new diary";
	my $statement="";
	$statement=$statement.$_.".".$display{$_}."\n" for sort keys %display;
	print STDOUT "Choose the following options\n$statement";
	my $dopt=<STDIN>;
	chomp($dopt);
	if(defined $display{$dopt} && $display{$dopt} ne "Start new diary"){
		$lat_diary_dir=$Diary_dir.$display{$dopt};
		print STDOUT "You have selected '".$display{$dopt}."'.\n";
	}
	elsif(defined $display{$dopt} && $display{$dopt} eq "Start new diary"){
		print STDOUT "Please enter your Diary Name\n";
	        my $diary_name=<STDIN>;
        	chomp($diary_name);
	        if($diary_name){
        	        $lat_diary_dir="$Diary_dir".$diary_name;
	                mkpath($lat_diary_dir);
        	}

	}
	else{
		print STDOUT "Sorry! You have entered wrong options\n";
	}
};
$Project::Lite::Diary_dir=$lat_diary_dir."/";
my $temp=$Project::Lite::Diary_dir;
$temp=~ s/.Diary/.Backup_d/;
$Project::Lite::backup_dir=$temp;

MAIN:
print STDOUT "Enter Your options\n1.Enter into your Diary\n2.Show my Diary\n3.Save my diary\n4.Exit\n";
my $opt=<STDIN>;

if($opt == '1'){
	system("clear");
	print STDOUT "Please Enter Text to add up in your Diary(Recommended: Start with headlines initiated with '#')\n";
	my $text="";
	while(<STDIN>){
		last if /^q$/;
		$text .= $_;
	}
	chomp($text);
	$object->add_text($text);
	goto MAIN;
}
elsif($opt == '2'){
	system("clear");
	print STDOUT "Here is the index of your Diary\n";
	my $index=Project::Index->new();
	$index->show_index();
	print STDOUT "Please Enter date to be shown in your Diary\n";
	my $date=<STDIN>;
	$object->get_and_validate($date);
	goto MAIN;
}
elsif($opt == '3'){
	print STDOUT "Enter Name of the file\n";
	my $filename=<STDIN>;
	chomp($filename);
	my $index=Project::Index->new();
        $filename=$PWD."/".$filename;
	$index->combine_files("$filename");
	goto MAIN;
}
elsif($opt == '4'){exit;}
else{

	goto MAIN;

}
sub mychomp($){$_[0]=~ s/^(\n|\s)|(\s|\n)$//g;return $_[0];}

