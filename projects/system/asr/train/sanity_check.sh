#!/bin/bash
echo "Printinng words from lexicon not present in transcriptions"
awk 'NR==FNR{words[$1]; next;} !($1 in words)' <( cut -d" " -f2- data/train/text | tr ' ' '\n') data/lang/words.txt
