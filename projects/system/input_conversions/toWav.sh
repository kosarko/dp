#!/bin/bash
INPUT=$(readlink -e $1)
OUTPUT=${INPUT%.*}.wav

avconv -i $INPUT -ac 1 -ar 16k $OUTPUT
