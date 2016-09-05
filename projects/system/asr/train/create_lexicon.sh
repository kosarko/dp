#!/bin/bash

. path.sh

LEXICON=data/local/lang/lexicon.txt

WAV_DIR=$1

sql_where=$(python3 -c "
import glob
import os
import sys
path_to_wavs = sys.argv[1]
shows = ['\'' + os.path.basename(i)[0:-7] + '\'' for i in glob.glob(path_to_wavs + '/*.16.wav')]
sql_where = 'WHERE show IN (' + ','.join(shows) + ') '
print(sql_where)
" $WAV_DIR )

sqlite3 $DBFILE "select distinct form from dialog $sql_where;" |  
noises.pl > lexicon.tmp 
grep -v " \{7\}" lexicon.tmp | tr -d ")(+,.=?]´" | perl -CSAD -wpe '$_=uc;' | 
  phonetic_transcription_cs.pl | grep -v "^\s*$" > $LEXICON

grep " \{7\}" lexicon.tmp | grep -v "DELETE" >> $LEXICON
  
rm lexicon.tmp

echo "<oov>       <oov>" >> $LEXICON

sort -u $LEXICON -o $LEXICON
