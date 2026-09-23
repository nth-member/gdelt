#!/bin/bash
# One daily GDELT archive -> that day's top source URLs, as JSON.
#
# SOURCEURL is column 58 and exists only in the daily files, 2013-04-01 onward.
# A day resolves to ~19,000 distinct URLs, so a rule is needed, and it is fixed
# here rather than chosen per day:
#
#   rank by NumArticles (col 34), summed per URL
#   keep one URL per domain, and one per path -- wire syndication puts the same
#                                       AP story under several mastheads at the
#                                       identical path; both keys are needed
#   take the top 25
#
# The rule is uniform over every day in the corpus. Nothing is picked because it
# looked relevant to a position: a criterion that selects the data must not also
# be the criterion that evidences it.
set -euo pipefail
f="$1"; out="$2"; b="${f##*/}"; d="${b:0:4}-${b:4:2}-${b:6:2}"
[ -f "$out/$d.json" ] && exit 0

unzip -p "$f" | awk -F'\t' '
  $58 ~ /^https?:\/\// { a[$58] += $34; n++ }
  { rows++ }
  END { for (u in a) printf "%d\t%s\n", a[u], u
        printf "#\t%d\t%d\t%d\n", rows, n, length(a) }
' | sort -rn -k1,1 | awk -v D="$d" -v OUT="$out" '
  $1 == "#" { rows=$2; withurl=$3; distinct=$4; next }
  {
    url = $2
    split(url, p, "/"); dom = p[3]
    sub(/^www\./, "", dom)
    path = url; sub(/^https?:\/\/[^\/]*/, "", path)
    # Two keys. Domain keeps one masthead per outlet; path catches syndication,
    # where a wire story runs under several domains at the identical path --
    # seattlepi.com and chron.com are both Hearst and share it exactly.
    if (dom in seen) next
    if (length(path) > 12 && (path in seenp)) next
    seen[dom] = 1; seenp[path] = 1
    if (++k > 25) next
    n[k] = $1; u[k] = url; g[k] = dom
  }
  END {
    printf "{\"date\":\"%s\",\"rows\":%d,\"rows_with_url\":%d,\"distinct_urls\":%d,\"top\":[",
           D, rows, withurl, distinct > (OUT "/" D ".json")
    for (i = 1; i <= k && i <= 25; i++) {
      gsub(/\\/, "\\\\", u[i]); gsub(/"/, "\\\"", u[i])
      printf "%s{\"n\":%d,\"d\":\"%s\",\"u\":\"%s\"}", (i>1 ? "," : ""), n[i], g[i], u[i] \
             >> (OUT "/" D ".json")
    }
    printf "]}\n" >> (OUT "/" D ".json")
  }
'
