#!/bin/bash
# Search GDELT's events by who and where, in any era -- including 1979-2013,
# where there are no URLs for search.sh to read.
#
#   ./search_events.sh [-r ROOT] [-c CC] [-n] PATTERN [FROM] [TO]
#
#   ./search_events.sh nigeria 1985-08-20 1985-09-03
#   ./search_events.sh -r '14|18|19' 'lagos|abuja' 1993-06-01 1993-07-31
#   ./search_events.sh -c NGA -n . 1983-12-01 1984-01-31     per-day counts
#
# PATTERN is an extended regex, matched case-insensitively against the two
# actor names and the three place names of each event (Actor1Name, Actor2Name,
# Actor1Geo_FullName, Actor2Geo_FullName, ActionGeo_FullName). Use . for every
# event.
#
#   -r ROOT   CAMEO root code, a regex anchored to the whole code:
#             '14' protest, '18|19' assault or fight, '0[1-5]' cooperation
#   -c CC     actor country, CAMEO ISO-3 (NGA, USA, GBR); either actor matches
#   -n        one line per day, DATE and COUNT, over every day in the range
#
# Why this exists. Before 2013-04-01 GDELT's archives carry the same 57 columns
# as after, minus SOURCEURL, so search.sh -- which reads URLs -- sees nothing
# there. The events themselves are all present: actors, places, CAMEO codes,
# Goldstein, tone, article counts. This reads them where they lie. Defaults to
# that era; pass FROM and TO to search any other.
#
# The day is the one the daily aggregate uses, so a result lines up with the
# field's `z`: before 2013-04-01 it is SQLDATE, the date the event is attributed
# to; from 2013-04-01 it is the archive's own date, the day it was ingested.
# A search spanning 2013-04-01 therefore crosses from one quantity to another.
#
# NULL is never zero. With -n, a day that has no archive reads NULL -- 24 such
# days, all after 2013 -- and a day whose archive holds no match reads 0. In the
# per-event output a NULL day is simply absent, so `cut -f1 | uniq -c` cannot
# tell it from a quiet day; the NULL days in range are listed on stderr.
#
# The corpus is never extracted: each archive streams through `unzip -p`.
#
# Output, one line per event, sorted by article count within date:
#
#   DATE  ROOT  CODE  GOLDSTEIN  ARTICLES  ACTOR1  ACTOR2  PLACE  URL
#
# URL is empty before 2013-04-01.
set -euo pipefail

usage(){ sed -n '4,9p' "$0" | sed 's/^# \?//' >&2; exit 2; }

ROOT_RE="" CC="" PERDAY=0
while getopts "r:c:nh" o; do
  case "$o" in
    r) ROOT_RE="$OPTARG" ;;
    c) CC="${OPTARG^^}" ;;
    n) PERDAY=1 ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -ge 1 ] || usage

KEY="$1"
FROM="${2:-1979-01-01}"
TO="${3:-2013-03-31}"
CORPUS="${CORPUS:-$HOME/gdelt_raw_1979_2026}"
JOBS="${JOBS:-14}"

f="${FROM//-/}"; t="${TO//-/}"
[[ "$f" =~ ^[0-9]{8}$ && "$t" =~ ^[0-9]{8}$ ]] || { echo "dates are YYYY-MM-DD" >&2; exit 2; }

# Which archives can hold a day in range. Yearly and monthly archives are
# partitioned by SQLDATE, so their names bound what they contain; daily ones
# are named for the day they cover.
list=$(cd "$CORPUS/files" && ls | awk -v a="$f" -v b="$t" '
  /^[0-9]{4}\.zip$/           { y = substr($0, 1, 4); if (y >= substr(a, 1, 4) && y <= substr(b, 1, 4)) print; next }
  /^[0-9]{6}\.zip$/           { m = substr($0, 1, 6); if (m >= substr(a, 1, 6) && m <= substr(b, 1, 6)) print; next }
  /^[0-9]{8}\.export\.CSV\.zip$/ { d = substr($0, 1, 8); if (d >= a && d <= b) print }')
n=$(printf '%s\n' "$list" | grep -c . || true)
[ "$n" -gt 0 ] || { echo "no archives in $FROM .. $TO" >&2; exit 1; }

# The days in range with no archive: the daily era's NULLs.
nulls=$(python3 - "$f" "$t" "$CORPUS/files" <<'PY'
import sys
from datetime import date, timedelta
from pathlib import Path
a, b, files = sys.argv[1], sys.argv[2], Path(sys.argv[3])
p = lambda s: date(int(s[:4]), int(s[4:6]), int(s[6:]))
d, end = max(p(a), date(2013, 4, 1)), p(b)
last = max((x.name[:8] for x in files.glob("20*.export.CSV.zip")), default="")
if last:
    end = min(end, p(last))
while d <= end:
    if not (files / f"{d:%Y%m%d}.export.CSV.zip").exists():
        print(d.isoformat())
    d += timedelta(days=1)
PY
)

desc="/$KEY/i"
[ -n "$ROOT_RE" ] && desc+=", root ^($ROOT_RE)\$"
[ -n "$CC" ] && desc+=", actor country $CC"
echo "searching $n archives, $FROM .. $TO, for $desc" >&2
if [ -n "$nulls" ]; then
  echo "NULL, no archive -- never zero: $(printf '%s\n' "$nulls" | wc -l) days in range" >&2
  printf '%s\n' "$nulls" | sed 's/^/  /' >&2
fi

# Passed through the environment, not spliced into the awk program or `-v`:
# both would rewrite the regex's backslashes or break on a quote.
export K="$KEY" R="$ROOT_RE" C="$CC" A="$f" B="$t"

events() {
  printf '%s\n' "$list" | (cd "$CORPUS/files" && xargs -P "$JOBS" -n 1 bash -c '
    fn="$0"
    case "$fn" in
      *.export.CSV.zip) FD="${fn:0:8}" ;;   # daily era: the archive is the day
      *)                FD="" ;;            # yearly/monthly: SQLDATE is the day
    esac
    unzip -p "$fn" | FD="$FD" awk -F"\t" '"'"'
      BEGIN { k = tolower(ENVIRON["K"]); r = ENVIRON["R"]; c = ENVIRON["C"]
              a = ENVIRON["A"]; b = ENVIRON["B"]; fd = ENVIRON["FD"]
              if (r != "") r = "^(" r ")$" }
      {
        d = (fd != "") ? fd : $2
        if (d < a || d > b) next
        if (r != "" && $29 !~ r) next
        if (c != "" && $8 != c && $18 != c) next
        if (k != "." && tolower($7 "\t" $17 "\t" $37 "\t" $44 "\t" $51) !~ k) next
        printf "%s-%s-%s\t%s\t%s\t%s\t%d\t%s\t%s\t%s\t%s\n",
               substr(d, 1, 4), substr(d, 5, 2), substr(d, 7, 2),
               $29, $27, $31, $34, $7, $17, $51, (NF >= 58 ? $58 : "")
      }
    '"'"'
  ')
}

if [ "$PERDAY" -eq 1 ]; then
  # Every day in range, so a quiet day reads 0 and a missing one reads NULL.
  events | cut -f1 | sort | uniq -c | awk '{print $2 "\t" $1}' |
    python3 -c '
import sys
from datetime import date, timedelta
a, b, nulls = sys.argv[1], sys.argv[2], set(sys.argv[3].split())
p = lambda s: date(int(s[:4]), int(s[4:6]), int(s[6:]))
seen = dict(l.rstrip("\n").split("\t") for l in sys.stdin if l.strip())
d, end = p(a), p(b)
last = sys.argv[4]
if last:
    end = min(end, date.fromisoformat(last))
total = 0
while d <= end:
    s = d.isoformat()
    v = "NULL" if s in nulls else seen.get(s, "0")
    total += int(v) if v != "NULL" else 0
    print(f"{s}\t{v}")
    d += timedelta(days=1)
print(f"{total} events", file=sys.stderr)
' "$f" "$t" "$nulls" "$(cd "$CORPUS/files" && ls 20*.export.CSV.zip | tail -1 | sed -E 's/^(....)(..)(..).*/\1-\2-\3/')"
else
  events | sort -t$'\t' -k1,1 -k5,5nr |
    awk '{ print } END { print NR " events" > "/dev/stderr" }'
fi

echo "done" >&2
