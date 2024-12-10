package Project::Lite;
use strict;
use warnings;
use File::Path;

use base qw(Exporter);

our @EXPORT=qw(%month $Diary_dir $backup_dir);

our   %month=('1'=>'Jan','2'=>'Feb','3'=>'Mar','4'=>'Apr','5'=>'May','6'=>'Jun','7'=>'Jul','8'=>'Aug','9'=>'Sep','10'=>'Oct','11'=>'Nov','12'=>'Dec');


our $Diary_dir="$ENV{'HOME'}/.Diary/";
our $backup_dir="$ENV{'HOME'}/.Backup_d/";
#$backup_dir=~ s|Diary|Backup_d|;

sub new(){
    my $class=shift;
    my $self={};
    bless $self,$class;
    
}
=pod

Validate date to check the context.

=cut
sub get_and_validate()
{
    my $date=$_[1];
        if($_[0]->isvalid_date($date)){
                $date=~ s/\/(.*?)\//"_".$month{$1}."_"/e;
                chomp($date);
                my $req_filename=$Diary_dir.$date.".txt";
                if(-f $req_filename){
                        print STDOUT ("Filename: $req_filename\n");
                        system("vim $req_filename");
                }

        }
}


sub isvalid_date(){
    ($_[1]=~ /^(([0-9]|[0-2][0-9]|3[0-1])\/0?(1|3|5|7|8|10|12)|([0-9]|[0-2][0-9]|30)\/0?(4|6|9|11)|([0-9]|[0-2][0-9]\/0?2))\/20[1-3][0-9]$/)? (return 1) :  (return 0);
}

=pod

Add Text in your diary  

=cut

sub add_text(){
    my $text=$_[1];
    my ($month,$day,$time, $year)=`date` =~ /\s(.*?)\s+?(\d+)\s*?(\d+\:\d+\:\d+).*?(\d+)$/;
    my $todays_file="$Diary_dir/".$day."_".$month."_".$year.".txt";
    mkpath($Diary_dir);mkpath($backup_dir);
    my $linkfile="$backup_dir/".$day."_".$month."_".$year.".txt";
    open(FH,">>$todays_file") or die "Could not open file!";
    if(! -e $linkfile){        
        `ln $todays_file  $linkfile`;
    }
    print FH "TIME:: $time\n$text\n\n";
    close(FH);
}



package Project::Index;


use strict;
use Data::Dumper;
use Time::Local;


sub new(){
    my $class=shift;
    my $self={};
    bless $self,$class;

}

sub combine_files(){
    my ($self,$filename)=@_;
    chdir("$Project::Lite::Diary_dir");
        my @all_files;
        eval{   @all_files=`ls -l * | awk -F " " '{print \$9};'`;};
        if($@){print STDOUT "No Files till date\n";}
    my %all_files_trimmed=map{ $_=>&remove_whitespace($_) } @all_files;
          my %manipulated_files=map{ my $val=$_;$_=>&mymanipulate($val) } %all_files_trimmed;
    if(-e $filename){
        die "File aleady Exists";
    }
    print STDOUT ("saved as $filename\n");
    my @dates=values %manipulated_files;
    my @sort_dates=&sort_dates(@dates);
    
    foreach my $date(@sort_dates){
        while (my ($key,$value)= each %manipulated_files){
            next if($date ne $value);
            open(FH,"<$key") or die "$!";
            open(CH,">>$filename") or die "$!";
            print CH "DATE:  ".$value."\n\n";
            while(<FH>){
                print CH $_;
            }
            close(CH);
            close(FH);
        }
    }
    system("unix2dos $filename");
    sub remove_whitespace(){
        $_[0]=~ s/\n//g;
        $_[0]=~ s/^\s+|\s+$//g;
        return $_[0];
    }

}


sub show_index(){
    chdir("$Project::Lite::Diary_dir");
    my @all_files;
    eval{    @all_files=`ls -l * | awk -F " " '{print \$NF};'`;};

    if($@){print STDOUT "No Files till date\n";}
    my @manipulated_files=map(&mymanipulate($_),@all_files);
    my @new_all_files=&sort_dates(@manipulated_files);
    my $value;    
    for(@new_all_files){
        my $val=$_;
        $_=~ s/\//_/g;$_=~ s/\_(\d+)\_/\_$month{$1}\_/;$_=~ s/$/.txt/;    
        my $headlines=&capture_headlines($_);
        ($value)? ($value=$value."\n".$val."\n".$headlines) : ($value=$val."\n".$headlines);

    }
    print  STDERR $value."\n";
}

sub sort_dates(){
        my (@arr)=@_;
    no warnings;
        my (%so,@so,@sorted_dates);
        %so=map{ &settime($_)=> $_} @arr;
        @so=sort{ $a <=> $b } keys %so;
        @sorted_dates=map($so{$_},@so);
        sub settime(){
                my $time_arg=shift;
                $time_arg=~ m/\/.*?\//i;
                my ($date,$month,$year)=($`,$&,$');
                $month=~ s/\///g;
                $month--;
                my $time;
                  eval{
                        $time = timelocal(0,0,0,$date,$month,$year);
                };
                return $time;
        }
        return @sorted_dates;
}




sub mymanipulate($){
    my $file=$Diary_dir.$_[0];
    $_[0]=~ s/^(\n|\s)|(\s|\n)$//g;
    return if($_[0]!~ /^\d+\_[A-Z,a-z]{3,4}\_\d{4}\.txt$/);
    $_[0]=~ s/_/\//g;
    my %key_list_by_value;
    while(my ($key,$value)= each %month ){
        push @{$key_list_by_value{$value}}, $key;
    }
    $_[0]=~ s/.txt//;
    $_[0]=~ s/([A-Z,a-z]{3,4})/$key_list_by_value{"$1"}[0]/e;
    my $value=$_[0];
    return $value;
}

sub capture_headlines(){
    my $file=shift;
    open(FH,$file);
    my @headlines;
    while(<FH>){chomp($_);
        if($_=~ /^#/){
            push(@headlines,$_);
        }    
    }
    @headlines=map(&format($_),@headlines);
    my $headlines=join("\n",@headlines);
    sub format(){
        $_[0]=~ s/\#\s*|\s+$//;
        return '-'.$_[0];
    }
    return $headlines;
}


1;
