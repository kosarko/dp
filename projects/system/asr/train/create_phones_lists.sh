#!/bin/bash

. path.sh

locdict=data/local/lang/
LEXICON=$locdict/lexicon.txt

egrep -v "[A-Z]$|<oov>" $LEXICON | cut -d ' ' -f 2- | sed -e 's/ /\n/g' | grep -v "^\s*$" | sort -u > $locdict/nonsilence_phones.txt
echo "SIL" | cat - $LEXICON | egrep "[A-Z]$|<oov>" | awk '{print $NF}' | sort -u > $locdict/silence_phones.txt
echo "SIL" > $locdict/optional_silence.txt
#> $locdict/extra_questions.txt
