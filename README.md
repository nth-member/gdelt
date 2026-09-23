# gdelt

**What GDELT was reading on a given day.** One JSON per day, 2013-04-01 onward, holding that day's
top source URLs.

    https://nth-member.github.io/gdelt/?date=2021-09-26

This exists so that a date can be followed up. The companion repo
[`revott`](https://github.com/nth-member/revott) turns a position into a date and reads how much
GDELT recorded there; it answers *how much*, and says nothing about *what*. This answers *what*.

## The rule

A single day resolves to roughly 19,000 distinct URLs, so a selection rule is unavoidable. It is
fixed once and applied to every day in the corpus:

    rank by NumArticles (column 34), summed per URL
    keep one URL per domain
    keep one URL per path
    take the top 25

**Nothing is chosen because it suits a position.** A criterion that selects the data must not also
be the criterion that evidences it, so the rule is uniform, declared in advance, and blind to
anything outside the day it runs on.

Both dedupe keys are needed. Domain alone leaves wire syndication in place: on 2021-09-26 the same
AP story ran under `seattlepi.com` and `chron.com` — different domains, identical path — and would
otherwise have taken two of the twenty-five slots.

## What is and is not here

`SOURCEURL` is column 58 of GDELT's daily export files and **exists only from 2013-04-01**. The
yearly and monthly archives before that date have 57 columns and carry no links at all, so no
amount of work recovers a URL for a 1994 date. 92–98% of the values are real `http` URLs; the
remainder are source names such as `BBC Monitoring`, and those are dropped.

A day with no file is **not** a quiet day. GDELT never published 22 days in this range and two more
are listed in its manifest but absent from its server; the page says so rather than showing an
empty list.

Links are recorded as GDELT published them. Many will have rotted, and the repo makes no attempt to
archive or rehost their contents — it records what was cited, not what it said.

## Layout

    build.sh            corpus -> docs/days, resumable, ~4 min on 14 jobs
    extract_one.sh      one archive -> one day's JSON
    docs/index.html     the page, served by GitHub Pages
    docs/days/*.json    one file per day

The corpus is never committed and never extracted; archives stream through `unzip -p`.

    {"date":"2021-09-26","rows":104784,"rows_with_url":104784,"distinct_urls":18741,
     "top":[{"n":10723,"d":"clickondetroit.com","u":"https://…"}, …]}
