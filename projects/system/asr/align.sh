#!/bin/bash
set -o verbose
set -o xtrace
set -o nounset
set -o errexit
set -o pipefail

#FIXME . path
export LC_ALL=C

njobs=1

BINDIR=$(dirname $(readlink -e $0))

mkdir -p data/{lang,local/lang,alignme}
cp segments reco2file_and_channel wav.scp utt2spk spk2utt data/alignme

mkdir -p conf
cat >conf/mfcc.conf <<EOF
--use-energy=true
--sample-frequency=16000
EOF

mfccdir=mfcc
if [ ! -d $mfccdir ]; then
for x in data/alignme; do
    steps/make_mfcc.sh --cmd "run.pl" --nj $njobs $x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh $x
    steps/compute_cmvn_stats.sh $x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh $x
done
fi

cp $BINDIR/train/path.sh .
LEXICON=./data/local/lang/lexicon.txt
for i in nonsilence_phones.txt silence_phones.txt optional_silence.txt lexicon.txt; do
    cp $LOCDICT/$i ./data/local/lang/
done
sed -e 's/ /\n/g' text | $BINDIR/train/phonetic_transcription_cs.pl | sed -e 's/sil/<oov>/g' | grep -v "^\s*$" >> $LEXICON
#cut -d" " -f2- data/alignme/text | sed -e 's/ /\n/g' | perl -CSAD -pe 'if(/./){chomp; $_ .= " "x7 . "<oov>\n"}' | grep -v "^\s*$"  >> $LEXICON
rm -f data/local/lang/lexiconp.txt
 
sort -u $LEXICON -o $LEXICON
utils/prepare_lang.sh --position-dependent-phones false  data/local/lang "<oov>" data/local/lang_tmp data/lang

#do some scoring if one of these shows
if grep -F -f <(echo -e "PLOVAR34\nPLOVAR3\nPLOVAR4\nZTRAT45\nPLOVAR38") wav.scp; then
    for ORDER in 5 7 9 15;do
        LM=lm$ORDER
        mkdir -p data/local/lm
        ngram-count -interpolate -wbdiscount -order $ORDER -text <(paste -s text | sed -e 's#\s\+# #g') -lm data/local/lm/$LM -vocab $LEXICON -write-vocab data/local/lm/vocab

        $BINDIR/create_G.sh data/lang "$LM" data/local/lm data/local/lang/lexicon.txt || exit 1

        MODTYPE=$(basename $MODEL)
        mkdir -p exp/$MODTYPE
        cp -r $MODEL/* exp/$MODTYPE
        if (echo $MODTYPE | grep "mono"); then
            utils/mkgraph.sh --mono data/lang_$LM $WORK/model exp/$MODTYPE/graph_$LM || exit 1
            DECODE="steps/decode.sh --nj $njobs --cmd \"run.pl\" --skip_scoring true exp/$MODTYPE/graph_$LM data/alignme exp/$MODTYPE/decode_$LM"
        elif (echo $MODTYPE | grep "tri[12]"); then
            utils/mkgraph.sh data/lang_$LM $WORK/model exp/$MODTYPE/graph_$LM || exit 1
            DECODE="steps/decode.sh --nj $njobs --cmd \"run.pl\" --skip_scoring true exp/$MODTYPE/graph_$LM data/alignme exp/$MODTYPE/decode_$LM"
        elif (echo $MODTYPE | grep "tri[34]"); then
            utils/mkgraph.sh data/lang_$LM $WORK/model exp/$MODTYPE/graph_$LM || exit 1
            DECODE="steps/decode_fmllr.sh --nj $njobs --cmd \"run.pl\" --skip_scoring true exp/$MODTYPE/graph_$LM data/alignme exp/$MODTYPE/decode_$LM"
        fi
        if [ ! -d exp/$MODTYPE/decode_$LM ]; then 
            $DECODE
        fi
        SHOW=$(head -n1 wav.scp | cut -d" " -f1)
        SHOW=${SHOW%.16}
        for i in $(seq 9 16);do
            TRANS=trans_lmw${i}_n_${ORDER}.txt
            lattice-best-path --lm-scale=$i "ark:gunzip -c exp/$MODTYPE/decode_$LM/lat.*.gz|" ark,t:- | utils/int2sym.pl -f 2- data/lang/words.txt > $TRANS

            i=${i}_n_${ORDER}
            OUT=output_lmw${i}.txt

            DURATION=$(soxi -D $(head -n1 wav.scp | cut -d" " -f2))
            sort -s -t"-" -k1,1 -k5,5n $TRANS | $BINDIR/format_output.pl $DURATION > $OUT 
            for sfx in ref cleared_hyp;do
                HYP_NAME=${SHOW}_lmw${i}_$sfx 
                sed -ne '/###/,$p' $OUT | tail -n +2 | grep -v "^Tx" | cut -d":" -f2- | paste -s | sed -e 's/^\s\+//' -e 's/\s\+/ /g' | perl -CSAD -pe '$_ = lc($_)'  > $HYP_NAME; sed -i -e "s/$/ ($SHOW)/" $HYP_NAME
                sclite -e utf-8 -i spu_id -r $BINDIR/../data/eval_sub/${SHOW}.$sfx -h $HYP_NAME -O . -o sum dtl
            done;
            HYP_NAME=${SHOW}_lmw${i}_cleared_ref 
            sed -ne '/###/,$p' $OUT | tail -n +2 | grep -v "^Tx" | cut -d":" -f2- | paste -s | sed -e 's/^\s\+//' -e 's/\s\+/ /g' | perl -CSAD -pe '$_ = lc($_)' | tr ' ' '\n' | $BINDIR/train/noises.pl   | grep -v "       " | paste -s -d " "  > $HYP_NAME; sed -i -e "s/$/ ($SHOW)/" $HYP_NAME
            sclite -e utf-8 -i spu_id -r $BINDIR/../data/eval_sub/${SHOW}.cleared_ref -h $HYP_NAME -O . -o sum dtl
        done;
    done;
else
    #TODO add correct order and lmw and check model
    ORDER=15
    LM=lm$ORDER
    mkdir -p data/local/lm
    ngram-count -interpolate -wbdiscount -order $ORDER -text <(paste -s text | sed -e 's#\s\+# #g') -lm data/local/lm/$LM -vocab $LEXICON -write-vocab data/local/lm/vocab

    $BINDIR/create_G.sh data/lang "$LM" data/local/lm data/local/lang/lexicon.txt || exit 1

    MODTYPE=$(basename $MODEL)
    mkdir -p exp/$MODTYPE
    cp -r $MODEL/* exp/$MODTYPE

    utils/mkgraph.sh data/lang_$LM $WORK/model exp/$MODTYPE/graph_$LM || exit 1

    steps/decode_fmllr.sh --nj $njobs --cmd "run.pl" --skip_scoring true exp/$MODTYPE/graph_$LM data/alignme exp/$MODTYPE/decode_$LM

    lattice-best-path --lm-scale=16 "ark:gunzip -c exp/$MODTYPE/decode_$LM/lat.*.gz|" ark,t:- | utils/int2sym.pl -f 2- data/lang/words.txt > trans.txt

    DURATION=$(soxi -D $(head -n1 wav.scp | cut -d" " -f2))
    sort -s -t"-" -k1,1 -k5,5n trans.txt | $BINDIR/format_output.pl $DURATION > output.txt 
fi
