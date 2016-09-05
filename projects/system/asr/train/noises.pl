#!/usr/bin/perl -CSAD

use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename 'dirname';

my $noises_file = dirname(abs_path($0)) . "/noises";
my %noises = ();
my @regexps = ();
open(my $noises_map, "<$noises_file") or die "Failed to open 'noises' $!";
while(<$noises_map>){
  chomp;
  my($key,$value) = split/\t/;
  #if "regexp" strip the //
  if($key =~ s#.*/(.*)/.*#$1#){
      push @regexps, $1;
  }
  $noises{$key} = $value;
}
close($noises_map);


my $sep = " " x 5;
while(<>){
    chomp;
    if($noises{$_}){
        $_ = "$_ $sep $noises{$_}";
    }else{
        for my $regexp (@regexps){
            if($_ =~ qr/$regexp/u and $noises{$regexp}){
                $_ = "$_ $sep $noises{$regexp}";
                last;
            }
        }
    }
    print "$_\n";
}
