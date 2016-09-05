#!/bin/bash
INPUT=$(readlink -e $1)
OUTPUT=${INPUT%.*}.srt

ccextractor -nobom -lf $INPUT -o $OUTPUT
