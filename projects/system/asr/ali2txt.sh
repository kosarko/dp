#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail
set -o xtrace

#TODO try other commands
#Convert model-level alignments to phone-sequences (in integer, not text, form)
#Usage:  ali-to-phones  [options] <model> <alignments-rspecifier> <phone-transcript-wspecifier|ctm-wxfilename>
#
#Display alignments in human-readable form
#Usage:  show-alignments  [options] <phone-syms> <model> <alignments-rspecifier>
#
#
#Convert lattices so that the arcs in the CompactLattice format correspond with
#phones.  The output symbols are still words, unless you specify --replace-output-symbols=true
#Usage: lattice-align-phones [options] <model> <lattice-rspecifier> <lattice-wspecifier>
#e.g.: lattice-align-phones final.mdl ark:1.lats ark:phone_aligned.lats
#See also: lattice-to-phone-lattice, lattice-align-words, lattice-align-words-lexicon
#Note: if you just want the phone alignment from a lattice, the easiest path is
#lattice-1best | nbest-to-linear [keeping only alignment] | ali-to-phones
#If you want the words and phones jointly (i.e. pronunciations of words, with word
#alignment), try
#lattice-1best | nbest-to-prons

while getopts ":a:m:s:p:o:" opt; do
    case "$opt" in
        a)
            #FIXME Does not work with ~other
            ALI_PAT="${OPTARG/#\~/$HOME}"
            ;;
        m)
            MDL=$(readlink -e $OPTARG)
            ;;
        s)
            SEGMENTS=$(readlink -e $OPTARG)
            ;;
        p)
            PHONES=$(readlink -e $OPTARG)
            ;;
        o)
            OUT_DIR=$(readlink -e $OPTARG)
        :|\?)
            echo "Unknown option -$OPTARG or missing argument" >&2
            exit 1
            ;;
    esac
done


for i in $ALI_PAT; do
    ali-to-phones --ctm-output $MDL ark:"gunzip -c $i|" -> $OUT_DIR/$(basename ${i%.gz}.ctm);
done;

pushd $OUT_DIR
cat *.ctm > alignment.int
cat alignment.int | utils/int2sym.pl -f 5- $PHONES > alignment.txt

if [ -z "$SEGMENTS" ]; then
    awk 'NR==FNR{segment_starts[$1]=$3; utt2show[$1]=$2; next;} ($1 in segment_starts){print $1,$2,$3 + segment_starts[$1], $4, $5 > utt2show[$1] ".ali"} !($1 in segment_starts){print "ERROR: $0" > "/dev/stderr"}' $SEGMENTS alignment.txt
else
    cp alignment.txt alignment.ali
fi

for i in *.ali; do
    sort -t"-" -n -s -k4,4 -o $i $i
done
popd
