#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

CSV=$1
DB=$2
sqlite3 << SQL
create table subtitles (time integer, text text);
.separator ";"
.import $CSV subtitles
create index MyIndex on subtitles(time);
.save $DB
SQL
