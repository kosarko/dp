#!/bin/bash

. path.sh

ln -s $KALDI_DIR/egs/wsj/s5/steps
ln -s $KALDI_DIR/egs/wsj/s5/utils

rm -rf ./exp ./data

for i in "exp conf data data/train data/lang data/local data/local/lang"; do
    mkdir $i;
done

cat >conf/mfcc.conf <<EOF
--use-energy=true
--sample-frequency=16000
EOF
