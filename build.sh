#!/bin/bash
# Build docs/days/ from the GDELT corpus.
#
#   ./build.sh [CORPUS_DIR]      default ~/gdelt_raw_1979_2026
#
# Reads every daily archive from 2013-04-01 and writes one JSON per day holding
# that day's top source URLs. The corpus is read, never extracted: each archive
# streams through `unzip -p`, nothing is written beside the zips, and the 50 GB
# stays compressed.
#
# Resumable and idempotent -- a day whose file already exists is skipped, so an
# interrupted run continues where it stopped. To rebuild, delete docs/days.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CORPUS="${1:-$HOME/gdelt_raw_1979_2026}"
JOBS="${JOBS:-14}"
OUT="$HERE/docs/days"
mkdir -p "$OUT"

n=$(ls "$CORPUS"/files/20*.export.CSV.zip | wc -l)
echo "reading $n daily archives from $CORPUS/files ($JOBS jobs)"
( cd "$CORPUS/files" && ls 20*.export.CSV.zip \
  | xargs -P "$JOBS" -n 1 -I{} "$HERE/extract_one.sh" {} "$OUT" )
echo "days written: $(ls "$OUT" | wc -l)   size: $(du -sh "$OUT" | cut -f1)"
