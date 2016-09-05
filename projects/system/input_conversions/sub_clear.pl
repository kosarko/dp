#!/usr/bin/perl -CSAD

use strict;
use warnings;
use utf8;

while(<>){
    chomp;
    if(/([0-9]{2}:){2}[0-9]{2}/ or /^$/ or /^[0-9]+$/){
        next;
    }
    my $text = $_;
    $text =~ s/.*>(.*)<.*/$1/;
    while($text!~m/(.*[.?!]$)|(titulky.*:)/s){
        my $line = <>;
        last if not $line;
        chomp($line);
        if($line =~m /([0-9]{2}:){2}[0-9]{2}/ or $line =~m /^$/ or $line =~m/^[0-9]+$/){
            next;
        }
        $line =~ s/.*>(.*)<.*/$1/;
        $text .= " $line"; 
    }

    $text =~s/^\s+//;
    $text =~ s/\s+/ /g;
    #get rid of punctuation so it's not getting in the way in later stages
    $text =~ s/[[:punct:]]//g;
    $text = uc($text);
    print "$text\n";
}
