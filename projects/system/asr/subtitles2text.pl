#!/usr/bin/perl -CSAD
use strict;
use warnings;
use DBI;

my $extraTime = 0;
my $dbName = shift;
my $db = DBI->connect("dbi:SQLite:$dbName", "", "",
    {RaiseError => 1, AutoCommit => 1, sqlite_unicode => 1});

open(my $fh, "<segments") or die "Could not open file 'segments' $!";;
open(my $text, ">text") or die "Could not open file 'text' $!";;
while(<$fh>){
    my ($uttid, undef, $start_time, $end_time) = split;
    my $start = $start_time - $extraTime;
    my $end = $end_time + $extraTime;
    my $allInRange = $db->selectall_arrayref("SELECT text FROM subtitles where time >= $start and time <= $end;");

    my $trans = "";
    if((scalar @$allInRange) == 0){
        print STDERR "No subtitles in range for $uttid\n";
    }
    foreach my $row (@$allInRange) {
        my ($text) = @$row;
        $trans .= " $text";
    }
    #??numbers
    $trans =~ s/[[:punct:]]//g;
    $trans =~ s/ +/ /g;
    $trans =~ s/^ +//g;
    $trans = uc($trans);
#tee tmp_lex
    print $text "$uttid $trans\n";

}

close $fh;
close $text;

