#!/usr/bin/perl -CSAD
use strict;
use warnings;

my $duration = shift @ARGV;

my %speakers;
my @lines;
my $last_end = 0.0;
while(<>){
    chomp;
    my ($id, $words) = split(" ", $_, 2);
    my($show, $quality, $gender, $spkid, $start, $end) = split(/-/,$id,6);
    if($start > $last_end){
        push @lines, sprintf("Tx $last_end: Noise/silence/music for %.2f sec",$start - $last_end); 
    }
    $last_end = $end;
    push @lines, "$spkid: $words";
    $speakers{$spkid} = $gender;
}
if($duration > $last_end){
    push @lines, sprintf("Tx $last_end: Noise/silence/music for %.2f sec", $duration - $last_end); 
}

print join "\n", map {$_ . "_" . $speakers{$_}} sort keys(%speakers);
print "\n" . "#"x30 . "\n";
print join "\n", @lines;
print "\n";
