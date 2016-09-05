#!/bin/bash
#USAGE:

train_cmd=run.pl
njobs=8

#wav_scp=$1
#dir=$(dirname $wav_scp)
#MODEL_DIR=$2

dir=$(pwd)
MODEL_DIR=$dir/model/

MDL=`ls $MODEL_DIR/*.mdl`
MAT=`ls $MODEL_DIR/*.mat`
HCLG=`ls $MODEL_DIR/*.fst`
WORDS=$MODEL_DIR/words.txt
CONF=$MODEL_DIR/mfcc.conf

#WORK=/tmp/tmp.deMq7Jr1IM
MFCC_SCP=$WORK/mfcc.scp
LAT=$WORK/lattice.gz
TRA=$WORK/transcription
TXT=$WORK/transcription.txt

#create mfccs
#TODO consider using make_mfcc and decode.sh

#[options] <data-dir> <log-dir> <path-to-mfccdir>
#data-dir contains segments, wav.scp, utt2spk
#log-dir
steps/make_mfcc.sh --cmd "$train_cmd" --nj $njobs --mfcc-config $CONF\
    $dir $WORK/logdir $WORK/mfccdir

#"Usage: $0 [options] <data-dir> <log-dir> <path-to-cmvn-dir>"
#TODO maybe --fake?
steps/compute_cmvn_stats.sh $dir $WORK/logdir $WORK/mfccdir

#Usage: steps/decode.sh [options] <graph-dir> <data-dir> <decode-dir>"
# graph-dir contains HCLG.fst, words.txt ..
# data-dri contains feats.scp from make_mfcc.sh
# decode-dir should be subdir of modeldir
steps/decode.sh --nj $njobs --cmd "$train_cmd"\
    $MODEL_DIR $dir $MODEL_DIR/decode

lattice-best-path "ark:gunzip -c $MODEL_DIR/decode/lat.*.gz|" ark,t:- | utils/int2sym.pl -f 2- $WORDS > $TXT


#compute-mfcc-feats [options...] <wav-rspecifier> <feats-wspecifier>
#compute-mfcc-feats --config=$CONF scp:$wav_scp \
#    ark,scp:$WORK/mfcc.ark,$MFCC_SCP || exit 1;
#if [ ! -f $MAT ];then
#    feats="ark,s,cs:copy-feats scp:$MFCC_SCP ark:- | add-deltas ark:- ark:- |"
#else
#    #XXX splice context depends on the model used
#    feats="ark,s,cs:copy-feats scp:$MFCC_SCP ark:- | splice-feats --right-context=3 --left-context=3 ark:- ark:- | transform-feats $MAT ark:- ark:- |"
#fi
#
#echo "feats=$feats"
#
#gmm-latgen-faster $MDL $HCLG "$feats" "ark:|gzip -c > $LAT" || exit 1
#
#lattice-best-path "ark:gunzip -c $LAT|" ark,t:$TRA || exit 1
#
#cat $TRA | utils/int2sym.pl -f 2- $WORDS > $TXT || exit 1
