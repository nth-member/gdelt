# gdelt

**What GDELT was reading on a given day.** One JSON per day, 2013-04-01 onward, holding that day's
top source URLs — 250 of them, filterable in the page.

    https://nth-member.github.io/gdelt/?date=2021-09-26

This exists so that a date can be followed up. The companion repo
[`revott`](https://github.com/nth-member/revott) turns a position into a date and reads how much
GDELT recorded there; it answers *how much*, and says nothing about *what*. This answers *what*.

## The rule

A single day resolves to between 4,000 and 59,000 distinct URLs, so a selection rule is unavoidable. It is
fixed once and applied to every day in the corpus:

    rank by NumArticles (column 34), summed per URL
    keep one URL per domain
    keep one URL per path
    take the top 250

**Nothing is chosen because it suits a position.** A criterion that selects the data must not also
be the criterion that evidences it, so the rule is uniform, declared in advance, and blind to
anything outside the day it runs on.

Both dedupe keys are needed. Domain alone leaves wire syndication in place: on 2021-09-26 the same
AP story ran under `seattlepi.com` and `chron.com` — different domains, identical path — and would
otherwise have taken two of the 250 slots.

## Searching past the 250

The published slice is 250 a day out of up to 59,000 — about 183 MB across the corpus. All of them,
roughly 90 million URLs, come to ~13 GB, which cannot be committed or served to a browser. They are
not lost, though: they sit in the archives, and one day parses in 0.19 seconds.

    ./search.sh palestin                        the whole URL era
    ./search.sh 'german.*election' 2021-09-01 2021-09-30
    ./search.sh derail 2021-09-26 2021-09-26

An extended regex, matched case-insensitively against the whole URL — which is a headline search in
practice, because the slug carries the headline. A full year takes about 8 seconds on 14 jobs; the
whole era, under two minutes. Nothing is stored and nothing is extracted.

The page has its own filter, which sees only the 250 that day shipped; when nothing matches it says
so and points at the rest rather than implying the day held nothing.

## Searching before 2013

Before 2013-04-01 there are no URLs, but the events themselves are all there: the yearly and monthly
archives carry the same first 57 columns as the daily ones — actors, places, CAMEO codes,
Goldstein, tone, article counts. `search_events.sh` reads them.

    ./search_events.sh nigeria 1985-08-20 1985-09-03            the events, readable
    ./search_events.sh -s -c GEO . 2008-08-01 2008-08-31        the range summarised
    ./search_events.sh -r '14|18|19' 'lagos|abuja' 1993-06-01 1993-07-31
    ./search_events.sh -c NGA -n . 1983-12-01 1984-01-31        per-day counts

The pattern is matched case-insensitively against the two actor names and the three place names.
`-r` filters on the CAMEO root code (`14` protest, `18|19` assault or fight), `-c` on either actor's
country (CAMEO ISO-3, read from the actor code as well as the country field, which GDELT fills
unevenly).

By default each distinct event is written out in words. GDELT often records one event several
times; those records are merged, with their articles, sources and mentions summed. Each entry reads
as who did what to whom, and where, with its weight:

    2008-08-08  MIKHEIL SAAKASHVILI (government, Georgia) → RUSSIA
                criticize or denounce [111 · verbal conflict]
                at Moscow, Moskva, Russia (55.75, 37.62)
                38 articles · 4 sources · 47 mentions · tone +5.2 · Goldstein -2.0 · recorded 2×

The words come from GDELT's own lookup tables in `cameo/`. `-s` summarises the whole range:
- volume and article-weighted tone;
- the four quad classes;
- the event types, actors, actor pairs and places carrying the most articles;
- the busiest days, with their leading events.

`-n` prints one line per day over every day in the range: `0` where the archive holds no match,
`NULL` where there is no archive. `-t` prints the raw rows, every field tab-separated, for `cut`, `sort`
and `awk`.

Every code, and where GDELT's own lookup is wrong about them, is in [`CAMEO_CODES.md`](CAMEO_CODES.md).

It defaults to 1979-01-01 .. 2013-03-31 and takes any range. The whole pre-2013 era takes about 45
seconds on 14 jobs. The day is the one `revott`'s daily aggregate uses, so a result lines up with its
field: before 2013-04-01 the date an event is attributed to, from 2013-04-01 the day its archive was
ingested. A range spanning that date crosses from one quantity to the other.

## What is and is not here

`SOURCEURL` is column 58 of GDELT's daily export files and **exists only from 2013-04-01**. The
yearly and monthly archives before that date have 57 columns and carry no links at all, so no
amount of work recovers a URL for a 1994 date. The events are there even so; see
[Searching before 2013](#searching-before-2013). 92–98% of the values are real `http` URLs; the
remainder are source names such as `BBC Monitoring`, and those are dropped.

A day with no file is **not** a quiet day. GDELT never published 22 days in this range and two more
are listed in its manifest but absent from its server; the page says so rather than showing an
empty list.

Links are recorded as GDELT published them. Many will have rotted, and the repo makes no attempt to
archive or rehost their contents — it records what was cited, not what it said.

## Layout

    build.sh            corpus -> docs/days, resumable, ~4 min on 14 jobs
    extract_one.sh      one archive -> one day's JSON;  TOP=n sets the depth
    search.sh           keyword -> every matching URL, read from the corpus
    search_events.sh    actor / place / CAMEO -> matching events, any era
    events_report.py    those events in words, merged, or summarised (-s)
    cameo/              GDELT's CAMEO lookup tables: event codes, actor types, countries
    CAMEO_CODES.md      the -r and -c codes, checked against the corpus
    docs/index.html     the page, served by GitHub Pages
    docs/days/*.json    one file per day

The corpus is never committed and never extracted; archives stream through `unzip -p`.

    {"date":"2021-09-26","rows":104784,"rows_with_url":104784,"distinct_urls":18741,
     "top":[{"n":10723,"d":"clickondetroit.com","u":"https://…"}, …]}
