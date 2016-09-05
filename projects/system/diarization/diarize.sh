#!/bin/bash

WAVFILE=$(readlink -e $1)
SHOWNAME=$(basename ${1%.wav} | sed -e 's/-/./g')
SCRIPTDIR=$(dirname $0)

. $SCRIPTDIR/../local_paths

#TODO try CEClustering and saveallstep
#don't use --sOutputFormat ctl it doesn't write .seg files correctly, improper closing of java writer/stream
spkdiarization --doCEClustering --saveAllStep --fInputMask=$WAVFILE --sOutputMask=${SHOWNAME}.seg $SHOWNAME

#====================================
###FIXME data preparation  begins here
#sorting for kaldi requires this
export LC_ALL=C
LC_ALL=C

#wav scp
#<recording-id> <extended-filename>
#sw02001-A /path/to/file.wav
echo "$SHOWNAME $WAVFILE" | sort > wav.scp
echo "$SHOWNAME $SHOWNAME A" | sort > reco2file_and_channel

#seg file
#comements start with ;;
#show_name channel start_feats length_feats gender bandwidth environment cluster_name segment_info(opt)
#;; cluster S7 [ score:FS = -32.397526385694974 ] [ score:FT = -33.88143385053143 ] [ score:MS = -33.40692602613287 ] [ score:MT = -34.15508970684635 ] 
#DJ2 1 4412 582 F S U S7
#DJ2 1 5021 546 F S U S7
#DJ2 1 5573 346 F S U S7
#DJ2 1 5951 437 F S U S7
#DJ2 1 6390 243 F S U S7
#DJ2 1 6641 1137 F S U S7
#DJ2 1 7788 503 F S U S7
#DJ2 1 8314 435 F S U S7

#prepare files for kaldi
grep -v '^;;' ${SHOWNAME}.seg | awk '
    #the default rate for spkd is 100
    BEGIN{rate=100}
    {
        show=$1; bandwidth=$6; gender=$5; cluster=$8; start_sec=$3/rate; end_sec=($3+$4)/rate;
        printf "%1$s-%2$s-%3$s-%4$s-%5$.2f-%6$.2f %1$s %5$.2f %6$.2f\n", show, bandwidth, gender, cluster, start_sec, end_sec
    }
     ' | sort |
#segments file    
tee segments |
#utt2spk
perl -we '
    use strict;
    while(<>){
        chomp;
        #print "$utt_show-$bandwidth-$gender-$cluster-$start-$end $utt_show $start $end\n";
        my ($utt_id, undef, undef, undef) = split/ /;
        my($utt_show, $bandwidth, $gender, $cluster, $start, $end) = split("-", $utt_id);
        print "$utt_id $utt_show-$bandwidth-$gender-$cluster\n";
    }
' | sort > utt2spk

utils/utt2spk_to_spk2utt.pl utt2spk > spk2utt

#text
#utt_id WORD1 WORD2 ...
#merge segments with transcriptions
