#!/bin/bash

. path.sh

init_dirs.sh

create_lexicon.sh $1

create_phones_lists.sh

#usage: utils/prepare_lang.sh <dict-src-dir> <oov-dict-entry> <tmp-dir> <lang-dir>
utils/prepare_lang.sh --position-dependent-phones false data/local/lang "<oov>" data/local/lang_tmp data/lang

rm -r data/local/lang_tmp
