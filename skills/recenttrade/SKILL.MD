---
name: recenttrade
description: Find and tabulate retail investors' public buy/sell disclosures (positions, tickers, sizes, prices, reasons) posted on X/Twitter, Reddit, Rednote/Xiaohongshu and the open web within a recent time window, defaulting to 7 days. Use when the user asks what people are trading, who bought or sold what, retail buy/sell records, 买卖记录, 实盘记录, portfolio activity, or "what did people post about trading recently".
---

# RecentTrade

Turn social posts into a table of **verifiable retail trade disclosures**.

Output is always a markdown table:

| Date | Author | Stock | Action | Justification | Source | URL |
|---|---|---|---|---|---|---|

- **Date** — post date, `YYYY-MM-DD`
- **Author** — `@handle` on X, `u/name` on Reddit, plain name on rednote
- **Stock** — `TICKER` list, `—` if not named
- **Action** — `BUY` / `SELL` / `BUY/SELL`
- **Justification** — the poster's own reasoning, verbatim-trimmed; `—` if none
- **Source** — platform/subreddit
- **URL** — shortened. `x.com/i/status/<id>`, `reddit.com/comments/<id>`

---

## Prerequisites

Requires the **OpenCLI browser bridge** (opencli ≥1.8.7 + Chrome extension). Check first:

```bash
opencli doctor          # want: Daemon OK, Extension connected, Connectivity OK
```

If any line is not OK, stop and tell the user — do not silently degrade to web-only
search without saying so. Then confirm per-platform login:

```bash
opencli auth status --full | grep -E "twitter|reddit|rednote"
```

`twitter`, `reddit`, and `rednote` are the three that materially matter. `rednote`
(small red book / 小红书) is a separate adapter from `xiaohongshu` — prefer `rednote`,
which exposes `search`/`note`/`comments`. The `xiaohongshu` adapter only has
`login`/`user`/`whoami` and checks `creator.xiaohongshu.com`.

---

## Workflow

### 1. X — use native `since:`, filter hard

```bash
opencli twitter search "<query> since:YYYY-MM-DD" -f yaml --limit 40 > /tmp/x1.yaml
```

Run 3–4 query angles. Effective ones:

- `bought OR sold my position average price shares since:...`
- `portfolio update adding trimming since:...`
- `just bought $ since:...`
- `my portfolio holdings buy sell log since:...`

**Expect ~2/3 noise.** Crypto bots, engagement farmers, and quote-posts about other
people's trades dominate. `--top-by-engagement 15` helps surface real authors.

### 2. Reddit — subreddit feeds, NOT search

```bash
for S in investing stocks StockMarket wallstreetbets options dividendincome; do
  opencli reddit subreddit "$S" --limit 50 -f yaml > "/tmp/rq_$S.yaml"; sleep 2
done
```

> **Critical:** `opencli reddit search` is relevance-ranked and **ignores recency**
> entirely — it will return 2018 crypto posts for a "this week" query. Always
> go through subreddit feeds and filter timestamps client-side.

### 3. rednote (optional, Chinese-language)

```bash
opencli rednote search "美股 买入 卖出 持仓记录" -f yaml > /tmp/rn1.yaml
```

Space calls 2–3s apart. Note reads require the `xsec_token` in the URL — do not
strip it.

### 4. Filter and tabulate

```bash
python3 ~/.config/opencode/skills/recenttrade/scripts/sweep.py \
  --days 7 --markdown /tmp/x*.yaml /tmp/rq_*.yaml /tmp/rn*.yaml
```

The script auto-detects each record's platform by field signature, applies the
recency window, and filters for first-person trade verbs + a real ticker + a
dollar amount. It strips finance jargon (`$ATM`, `$ARR`, `$DCA`, `$IV`) from the
ticker column. Add `--days N` to change the window; omit `--markdown` for a
reviewable plain-text listing.

---

## Agent rules

1. **Verify before publishing.** `sweep.py` is a coarse filter, not a judge. Open
   each surviving post and confirm it is a genuine own-trade disclosure before it
   goes in the table. For Reddit, `opencli reddit read <post-id> -f yaml` returns
   the body and top comments. For X, the search dump already carries the full
   text; `opencli twitter tweets @author -f yaml` gives surrounding context.
   Drop rows that turn out to be thesis discussion, questions, or reference
   trades about someone else.
2. **Never invent a fill.** If size, price, or direction isn't stated, leave the
   column `—`. Do not infer a buy from a "hold" post.
3. **No-trade disclosures count.** "I didn't buy or sell this month, only weekly
   contributions" is a real data point. Keep it, mark Action `NONE`.
4. **Keep the author's own words** in Justification. Summarising is allowed only
   when the post is long; prefer a verbatim trim.
5. **Dedupe** by post id — the same post often appears across several query dumps.
6. **Date-sort** descending, best engagement first within a date.
7. **Report coverage honestly.** End with a one-line note on which platforms were
   live and which were skipped. Never imply full coverage if a platform's login
   failed.
8. **Not investment advice.** These are unverified public posts; many are
   low-quality or promotional. State this briefly.

---

## Quality tiers

Present results in this order, or with a tier column when the list is long:

- **Tier 1** — explicit direction + size/price stated ("bought $1mm of AAOI")
- **Tier 2** — explicit direction, no size ("all in on Google, 100% of portfolio")
- **Tier 3** — position discussion with a named holding but no trade

Tier 1 is usually 3–6 posts per week. Do not pad the table with Tier 3 noise to
make the output look fuller.
