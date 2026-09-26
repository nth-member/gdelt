#!/usr/bin/env python3
"""Turn search_events.sh's raw rows into something to read.

    search_events.sh ... | events_report.py [--summary] [--top N]

Reads the full tab-separated rows (search_events.sh -t) on stdin and writes:

  default      one entry per distinct event -- rows GDELT recorded more than once
               (same day, actors, action and place) are merged, their articles,
               sources and mentions summed. Each reads as a sentence:

                 2008-08-08  MIKHEIL SAAKASHVILI (government, Georgia) → RUSSIA
                             criticize or denounce [111 · verbal conflict]
                             at Moscow, Moskva, Russia (55.75, 37.62)
                             38 articles · 4 sources · 47 mentions · tone +5.2 · Goldstein -2.0 · recorded 2×

  --summary    the whole range at once: volume and tone; the four quad classes;
               the event types, actors, actor pairs and places that carried the most
               articles; the busiest days with each one's leading events.

CAMEO codes are read in words from GDELT's own lookup tables in cameo/.
"""
import argparse
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent


def lookup(name):
    out = {}
    for i, line in enumerate((HERE / "cameo" / name).read_text(encoding="utf-8", errors="replace").splitlines()):
        if i == 0 or "\t" not in line:
            continue
        k, v = line.split("\t", 1)
        out[k.strip()] = v.strip()
    return out


EVENT = lookup("CAMEO.eventcodes.txt")
TYPE = lookup("CAMEO.type.txt")
COUNTRY = lookup("CAMEO.country.txt")
COUNTRY.setdefault("SSD", "South Sudan")
COUNTRY.setdefault("ROU", "Romania")
QUAD = {"1": "verbal cooperation", "2": "material cooperation", "3": "verbal conflict", "4": "material conflict"}
F = ["day", "sqldate", "root", "code", "quad", "goldstein", "mentions", "sources", "articles", "tone",
     "a1code", "a1name", "a1country", "a1type", "a2code", "a2name", "a2country", "a2type",
     "place", "geocountry", "lat", "lon", "url"]


def num(x, cast=float):
    try:
        return cast(x)
    except (TypeError, ValueError):
        return cast(0)


def action(code):
    return EVENT.get(code, "").lower() or f"CAMEO {code}"


def actor(name, country, typ, code):
    if not name and not code:
        return "—"
    extra = [e for e in (TYPE.get(typ, "").lower(), COUNTRY.get(country, "") if country and country.lower() not in name.lower() else "") if e]
    return (name or code) + (f" ({', '.join(extra)})" if extra else "")


def read():
    rows = []
    for line in sys.stdin:
        c = line.rstrip("\n").split("\t")
        if len(c) < len(F):
            c += [""] * (len(F) - len(c))
        rows.append(dict(zip(F, c)))
    return rows


def merge(rows):
    """One entry per distinct event: same day, actors, action and place."""
    g = {}
    for r in rows:
        k = (r["day"], r["a1code"], r["a1name"], r["a2code"], r["a2name"], r["code"], r["place"])
        e = g.get(k)
        if e is None:
            e = g[k] = dict(r, n=0, articles=0, sources=0, mentions=0, tone_w=0.0, urls=[])
        a = num(r["articles"], int)
        e["n"] += 1
        e["articles"] += a
        e["sources"] += num(r["sources"], int)
        e["mentions"] += num(r["mentions"], int)
        e["tone_w"] += num(r["tone"]) * max(a, 1)
        if r["url"].startswith("http") and r["url"] not in e["urls"]:
            e["urls"].append(r["url"])
    for e in g.values():
        e["tone"] = e["tone_w"] / max(e["articles"], e["n"])
    return sorted(g.values(), key=lambda e: (e["day"], -e["articles"]))


def sentence(e, indent="            "):
    where = e["place"] or "place unknown"
    # GDELT writes 0, 0 where its geocoder failed -- not a place in the Gulf of Guinea.
    if e["lat"] and e["lon"] and (num(e["lat"]), num(e["lon"])) != (0.0, 0.0):
        where += f" ({num(e['lat']):.2f}, {num(e['lon']):.2f})"
    lines = [f"{e['day']}  {actor(e['a1name'], e['a1country'], e['a1type'], e['a1code'])} → "
             f"{actor(e['a2name'], e['a2country'], e['a2type'], e['a2code'])}",
             f"{indent}{action(e['code'])} [{e['code']} · {QUAD.get(e['quad'], '?')}]",
             f"{indent}at {where}",
             f"{indent}{e['articles']} articles · {e['sources']} sources · {e['mentions']} mentions · "
             f"tone {e['tone']:+.1f} · Goldstein {num(e['goldstein']):+.1f}"
             + (f" · recorded {e['n']}×" if e["n"] > 1 else "")]
    lines += [f"{indent}{u}" for u in e["urls"][:2]]
    if e["sqldate"] and e["sqldate"].replace("-", "") != e["day"].replace("-", ""):
        lines.insert(1, f"{indent}(reported this day; GDELT dates the event itself {e['sqldate']})")
    return "\n".join(lines)


def summary(rows, events, top):
    arts = sum(e["articles"] for e in events) or 1
    days = sorted({e["day"] for e in events})
    out = [f"{len(rows):,} rows → {len(events):,} distinct events over {len(days)} days "
           f"({days[0]} … {days[-1]})" if days else "no events",
           f"{arts:,} articles · mean tone {sum(e['tone'] * e['articles'] for e in events) / arts:+.2f} · "
           f"mean Goldstein {sum(num(e['goldstein']) * e['articles'] for e in events) / arts:+.2f}  (article-weighted)", ""]

    def table(title, counter, fmt=lambda k: k):
        out.append(title)
        tot = sum(counter.values()) or 1
        for k, v in counter.most_common(top):
            out.append(f"  {v:>9,}  {100 * v / tot:5.1f}%  {fmt(k)}")
        out.append("")

    q, ev, a, pair, pl = Counter(), Counter(), Counter(), Counter(), Counter()
    for e in events:
        w = e["articles"]
        q[e["quad"]] += w
        ev[e["code"]] += w
        pl[e["place"] or "—"] += w
        n1 = actor(e["a1name"], e["a1country"], e["a1type"], e["a1code"])
        n2 = actor(e["a2name"], e["a2country"], e["a2type"], e["a2code"])
        for n in {n1, n2} - {"—"}:
            a[n] += w
        if n1 != "—" and n2 != "—":
            pair[f"{n1} → {n2}"] += w
    table("By quad class (articles)", q, lambda k: QUAD.get(k, k))
    table("Event types that carried the most articles", ev, lambda k: f"{action(k)} [{k}]")
    table("Actors", a)
    table("Actor pairs (who → whom)", pair)
    table("Places", pl)

    byday = defaultdict(list)
    for e in events:
        byday[e["day"]].append(e)
    out.append("Busiest days, with their leading events")
    for d, es in sorted(byday.items(), key=lambda kv: -sum(e["articles"] for e in kv[1]))[:min(top, 8)]:
        out.append(f"  {d}  {sum(e['articles'] for e in es):,} articles, {len(es):,} events")
        for e in sorted(es, key=lambda e: -e["articles"])[:3]:
            out.append(f"      {e['articles']:>6,}  {actor(e['a1name'], e['a1country'], e['a1type'], e['a1code'])} → "
                       f"{actor(e['a2name'], e['a2country'], e['a2type'], e['a2code'])}: {action(e['code'])}"
                       f" — {e['place'] or 'place unknown'}")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--summary", action="store_true")
    ap.add_argument("--top", type=int, default=12)
    args = ap.parse_args()
    rows = read()
    events = merge(rows)
    try:
        if args.summary:
            print(summary(rows, events, args.top))
        else:
            for e in events:
                print(sentence(e))
                print()
        print(f"{len(rows):,} rows, {len(events):,} distinct events", file=sys.stderr)
    except BrokenPipeError:
        pass


if __name__ == "__main__":
    main()
