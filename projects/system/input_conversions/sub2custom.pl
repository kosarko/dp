#!/usr/bin/perl -CSAD
use strict;
use warnings;
use List::MoreUtils 'first_index';

{
    #use empty line as record separator
    local $/ = "\n\n";
    while(<>){
        my @fields = split/\n/;
        my $index = first_index { /([0-9]{2}:){2}[0-9]{2}/ } @fields;
        print time2sec(split(/:/,$fields[$index])) . ";";
        for my $field (@fields[$index+1 .. $#fields]){
            $field =~ s/.*>(.*)<.*/$1/;
            #get rid of punctuation so it's not getting in the way in later stages
            $field =~ s/[[:punct:]]//g;
            $field =~ s/ +/ /g;
            $field =~ s/^ +//g;
            print $field;
            print " "; 
        }
        print "\n";
    }
}

sub time2sec {
    my ($hours, $minutes, $seconds) = @_;
    return $hours*60**2 + $minutes*60 + $seconds;
}

