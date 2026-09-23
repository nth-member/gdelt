#!/bin/bash
# Search every source URL GDELT recorded, not just the published top 25.
#
#   ./search.sh KEYWORD [FROM] [TO]
#
#   ./search.sh palestin                      the whole URL era, 2013-04-01 on
#   ./search.sh 'german.*election' 2021-09-01 2021-09-30
#   ./search.sh derail 2021-09-26 2021-09-26  one day
#
# KEYWORD is an extended regex, matched case-insensitively against the whole
# URL. That is a real headline search, because the slug carries the headline:
#
#   .../news/article/Israeli-troops-kill-4-Palestinians-in-West-Bank-16488300.php
#
# Why this exists. A day resolves to between 4,000 and 59,000 distinct URLs, and
# the whole era is ~90 million of them, ~13 GB. That cannot be committed or
# served to a browser, so docs/days holds a ranked slice per day. Nothing stops
# the rest being searched, though -- they are on disk, and one day parses in
# 0.19s. This reads them where they lie.
#
# The corpus is never extracted: each archive streams through `unzip -p`.
#
# Output, one line per matching URL, sorted by article count within date:
#
#   DATE  ARTICLES  DOMAIN  URL
set -euo pipefail

[ $# -ge 1 ] || { sed -n '3,8p' "$0" | sed 's/^# \?//'; exit 2; }
KEY="$1"
FROM="${2:-2013-04-01}"
TO="${3:-2099-12-31}"
CORPUS="${CORPUS:-$HOME/gdelt_raw_1979_2026}"
JOBS="${JOBS:-14}"

f="${FROM//-/}"; t="${TO//-/}"
list=$(cd "$CORPUS/files" && ls 20*.export.CSV.zip | awk -v a="$f" -v b="$t" \
        '{d=substr($0,1,8)} d>=a && d<=b')
n=$(printf '%s\n' "$list" | grep -c . || true)
[ "$n" -gt 0 ] || { echo "no archives in $FROM .. $TO" >&2; exit 1; }
echo "searching $n days, $FROM .. $TO, for /$KEY/i" >&2

printf '%s\n' "$list" | (cd "$CORPUS/files" && xargs -P "$JOBS" -n 1 bash -c '
  f="$0"; d="${f:0:4}-${f:4:2}-${f:6:2}"
  unzip -p "$f" | awk -F"\t" -v D="$d" -v K="'"$KEY"'" '"'"'
    $58 ~ /^https?:\/\// && tolower($58) ~ tolower(K) { a[$58] += $34 }
    END { for (u in a) { split(u, p, "/"); dom = p[3]; sub(/^www\./, "", dom)
                         printf "%s\t%d\t%s\t%s\n", D, a[u], dom, u } }
  '"'"'
') | sort -t$'\t' -k1,1 -k2,2nr

echo "done" >&2
