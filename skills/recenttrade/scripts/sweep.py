#!/usr/bin/env python3
"""Filter opencli X / Reddit / rednote YAML dumps into recenttrade table rows.

Usage:
    python3 sweep.py --days 7 x1.yaml rq_investing.yaml rq_stocks.yaml
    python3 sweep.py --days 7 --markdown *.yaml

Platform is auto-detected per record by its field signature, so you can throw
every dump from every platform at one invocation.

Conservative by design: the output should be a short table of real disclosed
fills, not a firehose of market chatter.
"""

import argparse
import datetime as dt
import re
import sys

try:
    import yaml
except ImportError:
    sys.exit("PyYAML required: pip install pyyaml")

# ---------------------------------------------------------------- patterns

MONEY = re.compile(r"\$\s?\d[\d,.]*\s?[kKmM]?\b|\$\d")

# First-person trade verbs only. Passive/quoting uses ("Pelosi bought in May")
# are intentionally excluded so reference trades don't masquerade as own trades.
ACT = re.compile(
    r"\b(i|i've|i have|we|my)\s+"
    r"(bought|sold|added|trimmed|exited|closed|shorted|loading up|"
    r"scaling in|scaling out|averaging down|averaging up|added to|bought the dip)\b"
    r"|\b(bought|sold)\s+(the\s+)?dip\b"
    r"|\bmy\s+(avg|average)\b|\bcost basis\b|\bfull port\b"
    r"|\bwent all[- ]in\b|\b100% of (my )?portfolio\b",
    re.I,
)

TICKER_CASED = re.compile(r"\$([A-Z]{1,5})\b")
TICKER_BARE = re.compile(r"\b([A-Z]{2,5})\b")

# Finance jargon, acronyms and common English words that the $-ticker regex
# picks up but that are not instruments: "$ATM offering", "$ARR", "$DCA", "$IV".
NOT_TICKER = {
    # market structure / jargon
    "ATM", "ARR", "IV", "IVR", "IVOL", "GEX", "RSI", "MACD", "EPS", "ROE",
    "ROIC", "NAV", "AUM", "PNL", "DTE", "OTM", "ITM", "FOMC", "CPI", "PPI",
    "GDP", "EBITDA", "OI", "IVOL", "VIX", "VIX", "DCA", "LTV", "APY", "TWR",
    "PT", "YT", "MA", "EO", "TA", "PM", "AG", "EPS",
    # english / filler
    "USD", "ETF", "IPO", "CEO", "ATH", "YTD", "ROI", "THE", "AND", "FOR",
    "YOU", "ARE", "NOT", "ALL", "NEW", "NOW", "OUT", "GET", "HOW", "WHY",
    "USA", "API", "SEC", "EVERY", "FYI", "IMO", "TBH", "BTW", "NEVER", "SO",
    "JUST", "LIKE", "THIS", "THAT", "WITH", "FROM", "HAVE", "WILL", "BEEN",
    "P/L", "AUM", "TLDR", "IMHO", "FOMO", "HODL", "DD", "TA",
}

NOISE = re.compile(
    r"\b(president|senator|congress|congressional|insider trading alert|"
    r"central bank|fomc|treasury yield|pelosi|trump)\b",
    re.I,
)

CRYPTO_NOISE = re.compile(
    r"\b(bitcoin|btc\b|ethereum|eth price|solana|memecoin|memecoin|mev bot|"
    r"sniper wallet|airdrop|presale|token launch|perp|perps|dex\b)\b",
    re.I,
)


# --------------------------------------------------------------- helpers


def parse_x_date(s):
    if not s:
        return None
    for fmt in ("%a %b %d %H:%M:%S %z %Y", "%Y-%m-%dT%H:%M:%S%z"):
        try:
            d = dt.datetime.strptime(s, fmt)
            return d if d.tzinfo else d.replace(tzinfo=dt.timezone.utc)
        except ValueError:
            continue
    return None


def parse_plain_date(s):
    try:
        return dt.datetime.strptime(str(s)[:10], "%Y-%m-%d").replace(
            tzinfo=dt.timezone.utc
        )
    except (ValueError, TypeError):
        return None


def detect(post):
    if "published_at" in post:
        return "rednote"
    if "subreddit" in post:
        return "reddit"
    if "created_at" in post:
        return "x"
    return None


def post_text(post):
    if "text" in post:
        return post["text"] or ""
    if "title" in post:
        return (post.get("title") or "") + "\n" + (post.get("selftext") or "")
    return ""


def shorten_x(p):
    i = p.get("id")
    return f"https://x.com/i/status/{i}" if i else ""


def shorten_reddit(p):
    i = p.get("id")
    return f"https://reddit.com/comments/{i}" if i else ""


def shorten_rednote(url):
    """Drop analytics params but KEEP xsec_token — rednote note reads require it."""
    if not url:
        return ""
    base, _, query = url.partition("?")
    keep = [kv for kv in query.split("&") if kv.startswith(("xsec_token=", "xsec_source="))]
    return base + ("?" + "&".join(keep[:2]) if keep else "")


def extract_tickers(text, max_n=4):
    found, seen = [], set()
    for rx, weight in ((TICKER_CASED, 0), (TICKER_BARE, 1)):
        for m in rx.finditer(text):
            t = m.group(1)
            if t in seen or (weight and t in NOT_TICKER):
                continue
            seen.add(t)
            found.append(t)
            if len(found) >= max_n:
                return found
    return found


def snippet(text, n=170):
    text = re.sub(r"https?://\S+", "", text or "")
    text = re.sub(r"\s+", " ", text).strip()
    return (text[:n] + "…") if len(text) > n else text


def act_kind(text):
    t = text.lower()
    sell = len(re.findall(r"\b(i |we |my )?(sold|selling|exited|closed out|trimmed)\b", t))
    buy = len(re.findall(r"\b(i |we |my )?(bought|added|adding|loading up)\b", t))
    if sell > buy:
        return "SELL"
    if buy > sell:
        return "BUY"
    return "BUY/SELL"


# ------------------------------------------------------------------ core


def qualify(text):
    if len(text) < 80:
        return False
    if not ACT.search(text):
        return False
    tickers = extract_tickers(text)
    # Require at least one ticker: genuine disclosures name the instrument.
    if not tickers:
        return False
    if not MONEY.search(text):
        return False
    if NOISE.search(text) and not ACT.search(text):
        return False
    if CRYPTO_NOISE.search(text):
        return False
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--days", type=int, default=7)
    ap.add_argument("--markdown", action="store_true")
    args = ap.parse_args()

    cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=args.days)
    rows, scanned, rejected = [], 0, 0

    for path in args.files:
        try:
            data = yaml.safe_load(open(path, encoding="utf-8"))
        except Exception as e:
            print(f"! skip {path}: {e}", file=sys.stderr)
            continue
        if not isinstance(data, list):
            continue

        for p in data:
            if not isinstance(p, dict):
                continue
            kind = detect(p)
            if kind is None:
                continue
            scanned += 1

            if kind == "x":
                ts = parse_x_date(p.get("created_at"))
            elif kind == "reddit":
                ts = (
                    dt.datetime.fromtimestamp(p["created_utc"], dt.timezone.utc)
                    if p.get("created_utc")
                    else None
                )
            else:
                ts = parse_plain_date(p.get("published_at"))

            if not ts or ts < cutoff:
                continue

            text = post_text(p)
            if kind == "rednote":
                if len(text) < 8:
                    continue
                author, src, url = p.get("author", "?"), "rednote", shorten_rednote(p.get("url"))
                tickers, action, eng = extract_tickers(text, 3), "post", p.get("likes")
            elif kind == "reddit":
                if not qualify(text):
                    rejected += 1
                    continue
                sub = str(p.get("subreddit", "?")).lstrip("r/").strip("/")
                author = "u/" + str(p.get("author", "?"))
                src, url = "r/" + sub, shorten_reddit(p)
                tickers, action = extract_tickers(text), act_kind(text)
                eng = p.get("score") or p.get("upvotes")
            else:
                if not qualify(text):
                    rejected += 1
                    continue
                author = "@" + str(p.get("author", "?"))
                src, url = "X", shorten_x(p)
                tickers, action = extract_tickers(text), act_kind(text)
                eng = p.get("likes")

            rows.append(
                dict(
                    date=ts.strftime("%Y-%m-%d"),
                    author=author,
                    tickers=tickers,
                    action=action,
                    source=src,
                    engagement=eng,
                    just=snippet(text),
                    url=url,
                )
            )

    def _eng(v):
        try:
            return int(v)
        except (TypeError, ValueError):
            return 0

    rows.sort(key=lambda r: (r["date"], _eng(r["engagement"])), reverse=True)

    if not args.markdown:
        print(f"{len(rows)} kept / {scanned} scanned / {rejected} failed filters")
        print(f"window: since {cutoff:%Y-%m-%d}\n")
        for r in rows:
            tick = ", ".join(f"${t}" for t in r["tickers"]) or "-"
            print(f"{r['date']} | {r['source']} | {r['author']} | {tick} | {r['action']}")
            print(f"   {r['url']}")
            print(f"   {r['just'][:130]}\n")
        return

    print("| Date | Author | Stock | Action | Justification | Source | URL |")
    print("|---|---|---|---|---|---|---|")
    for r in rows:
        tick = ", ".join(f"${t}" for t in r["tickers"]) or "—"
        just = r["just"].replace("|", "\\|")
        print(f"| {r['date']} | {r['author']} | {tick} | {r['action']} | {just} | {r['source']} | {r['url']} |")


if __name__ == "__main__":
    main()
