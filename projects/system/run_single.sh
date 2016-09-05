#!/bin/bash
set -o nounset
set -o pipefail

function error_exit
{
        echo -e "$0: ${1:-"Unknown Error"}" 1>&2
        exit 1
}

#FIXME setting the vars like this might cause trouble on cluster
SCRIPTDIR=$(dirname $(readlink -e $0))
WAVFILE=$(readlink -e $1)
SUBFILE=$(readlink -e $2)
export WORK=$(readlink -e ${3:-$(mktemp -d)})
#to resume after error $SEQ is the last OK
SEQ=${4:-0}

. $SCRIPTDIR/local_paths

pushd $WORK

#TODO maybe use s5/path.sh
if [ ! -x fstcompile ]; then
  export PATH=$PWD/utils:$(ls -d $KALDI_DIR/src/*bin $KALDI_DIR/tools/openfst/bin | paste -s -d":"):$PATH
fi
if (( $SEQ < 1 ));then
ln -s $KALDI_DIR/egs/wsj/s5/steps
ln -s $KALDI_DIR/egs/wsj/s5/utils
fi

if (( $SEQ < 2 ));then
cp -R $MODEL $WORK/model/ || error_exit "Error on line $LINENO.\nCheck $WORK for details/cleanup."
fi
export LOCDICT=$WORK/model/local/lang/


if (( $SEQ < 3 ));then
$SCRIPTDIR/checks/input_checks/soxi_check.sh $WAVFILE || error_exit "Error on line $LINENO.\nCheck $WORK for details/cleanup."
fi

if (( $SEQ < 4 ));then
#create wav.scp, segments, utt2spk, spk2utt in cwd
$SCRIPTDIR/diarization/diarize.sh $WAVFILE || error_exit "Error on line $LINENO.\nCheck $WORK for details/cleanup."
fi


if (( $SEQ < 5 ));then
#create text in cwd from SUBFILE
cat $SUBFILE | $SCRIPTDIR/input_conversions/sub_clear.pl > text || error_exit "Error on line $LINENO.\nCheck $WORK for details/cleanup."
fi

if (( $SEQ < 6 ));then
$SCRIPTDIR/asr/align.sh || error_exit "Error on line $LINENO.\nCheck $WORK for details/cleanup."
fi

popd
echo $WORK
