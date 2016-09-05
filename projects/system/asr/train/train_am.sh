#!/bin/bash

. path.sh
. cmd.sh

#utils/subset_data_dir.sh --first data/train 5000 data/train_5k

#steps/train_mono.sh --boost-silence 1.25 --nj "$njobs" --cmd "$train_cmd" data/train_5k data/lang exp/mono_5k
steps/train_mono.sh --boost-silence 1.25 --nj "$njobs" --cmd "$train_cmd" data/train data/lang exp/mono || exit 1;

steps/align_si.sh --boost-silence 1.25 --nj "$njobs" --cmd "$train_cmd" data/train data/lang/ exp/mono exp/mono_ali || exit 1;

steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 data/train data/lang exp/mono_ali exp/tri1 || exit 1;

steps/align_si.sh --nj "$njobs" --cmd "$train_cmd" \
    data/train data/lang exp/tri1 exp/tri1_ali || exit 1;

steps/train_deltas.sh --cmd "$train_cmd" \
    2500 15000 data/train data/lang exp/tri1_ali exp/tri2a || exit 1;

steps/align_si.sh --nj "$njobs" --cmd "$train_cmd" \
    --use-graphs true data/train data/lang exp/tri2a exp/tri2a_ali || exit 1;

steps/train_lda_mllt.sh --cmd "$train_cmd" \
    3500 20000 data/train data/lang exp/tri2a_ali exp/tri3a || exit 1;

steps/align_fmllr.sh --nj "$njobs" --cmd "$train_cmd" \
    data/train data/lang exp/tri3a exp/tri3a_ali || exit 1;

steps/train_sat.sh --cmd "$train_cmd" \
    4200 40000 data/train data/lang exp/tri3a_ali exp/tri4a || exit 1;

steps/align_fmllr.sh --nj "$njobs" --cmd "$train_cmd" \
    data/train data/lang exp/tri4a exp/tri4a_ali || exit 1;
#
#
#
#
#
#
