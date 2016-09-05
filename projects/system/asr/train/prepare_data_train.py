#!/usr/bin/env python3
import sqlite3
import re
import sys
import subprocess
import shlex

path_to_wavs = sys.argv[1]

pattern = re.compile('(.*)\s{7}(.*)')
uppercase = re.compile('^[A-Z_]*$')
sentence_boundary = re.compile('[.?]')
file_ids = {}
lexicon = {}

with open("data/local/lang/lexicon.txt", "rt", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip()
        match = pattern.match(line)
        word = match.group(1)
        pron = match.group(2)
        lexicon[word] = pron
        
#import pprint
#pp = pprint.PrettyPrinter(indent = 4)
#pp.pprint(lexicon)
#exit()

import glob
import os
shows = ["'" + os.path.basename(i)[0:-7] + "'" for i in glob.glob(path_to_wavs + '/*.16.wav')]
sql_where = "WHERE show IN (" + ",".join(shows) + ") "

#příliš žluťoučký kůň úpěl ďábelské ódy
trantab = str.maketrans("říšžťčýůňúěďáéóŘÍŠŽŤČÝŮŇÚĚĎÁÉÓ ?-/=","risztcyunuedaeoRISZTCYUNUEDAEO_____")

database = os.environ['DBFILE']
with sqlite3.connect(database) as conn, open("data/train/text", "wt", encoding="utf-8") as text_file,\
open("data/train/segments", "wt", encoding="utf-8") as segments_file, open("data/train/utt2spk", "wt", encoding="utf-8") as utt2spk_file,\
open("data/train/ref.ctm", "wt", encoding="utf-8") as ref_ctm:
    def writeFiles(start, end, show, gender, speaker, turn, sentence_id, sentence):
        if sentence == "":
            return
        #FIXME solve this
        if end - start < 11:
            end += 100

        utt_id = '{}-{}-{}-{}-{}'.format(show,gender,speaker,turn,sentence_id)
        spkr_id = '{}-{}-{}'.format(show,gender,speaker)
        file_id = show
        file_ids[file_id] = None
        text_file.write(utt_id + " " + sentence + "\n")
        segments_file.write('{} {} {} {}\n'.format(utt_id, file_id, start/100, end/100))
        utt2spk_file.write('{} {}\n'.format(utt_id, spkr_id))


    conn.row_factory = sqlite3.Row
    c =  conn.cursor();
    c.execute("select form, show, turn, speaker, gender, cast(start as INTEGER) start, cast(end as INTEGER) end from dialog join speakers on speaker = name " + sql_where + " order by show, cast(turn as INTEGER);")
    row = c.fetchone()
    if row is not None: 
        #print(row.keys())
        form = row["form"]
        show = row["show"]
        speaker = row["speaker"].translate(trantab)
        turn = row["turn"]
        gender = row["gender"]
        start = row["start"]
        end = row["end"]

        last_show = show
        last_speaker = speaker
        last_turn = turn
        sentence = ""
        #a regular word or special symbols where uc()=lc() such as '(.)'
        if(form.upper() in lexicon):
            sentence = " " + form.upper()
        elif(form in lexicon and uppercase.match(lexicon[form])):
            sentence = " " + form
            #else:
            #    print(word)
        sentence_id = 0
        while True:
            row = c.fetchone()
            if row is not None:
                show = row["show"]
                speaker = row["speaker"].translate(trantab)
                turn = row["turn"]
                form = row["form"]
                if sentence == "":
                    #maybe set in a different place, where we remove the [.?]
                    start = row["start"]
                if show == last_show and speaker == last_speaker and last_turn == turn:
                    end = row["end"]
                    if sentence_boundary.match(form):
                        sentence_id += 1
                        writeFiles(start, end, show, gender, speaker, turn, sentence_id, sentence)
                        sentence = ""
                    else:
                        #a regular word or special symbols where uc()=lc() such as '(.)'
                        if(form.upper() in lexicon):
                            sentence += " " + form.upper()
                        elif(form in lexicon and uppercase.match(lexicon[form])):
                            sentence += " " + form
                        #else:
                        #    print(word)
                else:
                    sentence_id += 1
                    writeFiles(start, end, last_show, gender, last_speaker, last_turn, sentence_id, sentence)
                    sentence_id = 0
                    last_show = show
                    last_speaker = speaker
                    last_turn = turn
                    gender = row["gender"]
                    start = row["start"]
                    end = row["end"]
                    sentence = ""
                    #a regular word or special symbols where uc()=lc() such as '(.)'
                    if(form.upper() in lexicon):
                        sentence = " " + form.upper()
                    elif(form in lexicon and uppercase.match(lexicon[form])):
                        sentence = " " + form
                    #else:
                    #    print(word)
            else:
                writeFiles(start, end, show, gender, speaker, turn, sentence_id, sentence)
                break

    for row in c.execute("select show, form, cast(start as integer) start, cast(end as integer) end from dialog " + sql_where + ";"):
        show = row["show"]
        start = row["start"]/100
        duration = row["end"]/100 - start
        word = row["form"]
        if(word.upper() in lexicon):
            word = word.upper()
        elif(word in lexicon and uppercase.match(lexicon[word])):
            pass
        else:
            continue

        ref_ctm.write('{} A {} {:.2f} {}\n'.format(show, start, duration, word))

with open("data/train/wav.scp", "wt", encoding="utf-8") as wav_file, open("data/train/reco2file_and_channel", "wt", encoding="utf-8") as reco2file:
    for file_id in file_ids.keys():
        wav_file.write('{} {}/{}.{}\n'.format(file_id, path_to_wavs, file_id, '16.wav'))
        reco2file.write('{0} {0} A\n'.format(file_id))

subprocess.call(shlex.split('utils/fix_data_dir.sh data/train'))
subprocess.call(shlex.split('sanity_check.sh'))
