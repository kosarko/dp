#!/bin/bash
BITS=$(soxi -b $1)
CHAN=$(soxi -c $1)
RATE=$(soxi -r $1)

if ! [ $CHAN -eq 1 -a $RATE -eq 16000 -a $BITS -eq 16 ];then
    echo "Wrong file format" 1>&2;
    soxi $1 1>&2;
    exit 1;
fi

