#!/bin/bash

. path.sh
. cmd.sh

mfccdir=exp/mfcc

for x in data/train; do
    #[options] <data-dir> <log-dir> <path-to-mfccdir>
    steps/make_mfcc.sh --cmd "$train_cmd" --nj "$njobs" $x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh $x
    #[options] <data-dir> <log-dir> <path-to-cmvn-dir>
    steps/compute_cmvn_stats.sh $x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh $x
done
