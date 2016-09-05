export LC_ALL=C

if [ ! -x fstcompile ]; then
  export PATH=$PWD/utils:$(ls -d $KALDI_DIR/src/*bin $KALDI_DIR/tools/openfst/bin | paste -s -d":"):$PATH
fi
#echo $PATH
