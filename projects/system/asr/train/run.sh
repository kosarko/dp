#!/bin/bash
set -o nounset
set -o pipefail

DATA_DIR=$(readlink -e $1)
export WORK=$(readlink -e ${2:-$(mktemp -d)})
if test -z "$DATA_DIR";then
    echo "Usage: $0 <dir-with-wav-files> [optional-work-dir]"
    exit 1;
fi
export SCRIPTDIR=$(dirname $(readlink -e $0))
export DBFILE=$SCRIPTDIR/../../data/dialog.db
. $SCRIPTDIR/../../local_paths
export PATH=$SCRIPTDIR:$PATH
cp $SCRIPTDIR/path.sh $WORK
pushd $WORK
prepare_lang.sh $DATA_DIR && prepare_data_train.py $DATA_DIR && mfcc_cmvn.sh && train_am.sh
popd
