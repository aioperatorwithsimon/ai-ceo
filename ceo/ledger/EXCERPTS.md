# Ledger excerpts — the real thing

The live account's ledger is one append-only file per month: every action, every day, with the time,
what was done, why, and the result. These are rows copied from it, **unchanged except for two
things**: clock times are removed, and a few private details (the owner's other projects, local paths)
are cut, marked `[…]`. The shape of the full file is in [EXAMPLE.md](EXAMPLE.md).

---

## 2026-10-17 — the account gets suspended for acting like a bot

| Action | Why | Result |
|---|---|---|
| Simon opened the course browser on instagram.com by hand to check something | His request | Instagram showed **@aioperatorwithsimon suspended for detected automated behaviour**, with a "prove you're human" step |
| Simon typed the on-screen image code; Instagram said an appeal was sent | Only he can do this | **~10 s later: "You're back on Instagram. Your account is no longer suspended… found that it does follow our Community Standards."** Same message came by email |
| Course browser history (copy of the profile's History DB) | What touched Instagram, and when | **Nothing between 10-16 evening (the API app OAuth) and the flag the next morning.** The warning page is `/accounts/scraping_warning/`: Instagram's own label is scraping |
| Instagram page loads per day, by type, July → today | Is it volume? | Oct 13-16: 64-82 a day. Aug: 50-179 a day, mostly other accounts' posts, with no flag on record. **Page volume alone doesn't explain it** |
| What doesn't show in page history | Background calls | `practitioner_scan.py` exports the session cookies to **yt-dlp**, a non-browser client, to download other creators' reels. Transcript files: **58 reels, 11 creators, 4 days**. New in October; the last batch ~14h before the flag |
| Research: Instagram's scraping help page, Terms §4.2, 3 web searches | Two sources before a hard-to-reverse call | Help page: first cause is "automating access to, or collecting information in an automated way". No Instagram-specific yt-dlp report; a YouTube one says session cookies used outside the browser get flagged [S] |
| **Decision** (5 rules) | Below | Never collect anything from other accounts through our session. Our own numbers only through the official API. On Instagram the AI reads; the human sends |

## 2026-10-22 — the first format fails the rule it wrote for itself

| Action | Why | Result |
|---|---|---|
| **The kill rule, read at episode 10** (16 posts since 10-13; followers.csv) | Due today | **13,046 views, followers 455 → 466 (+11 in 9 days): 0.84 follows per 1,000 views (bar 16) and 1.2 followers a day (bar 18). Both under: the series bet is wrong, by the rule written on 10-13.** Swing so far, 5 posts each: series 4,093 views, settles 6,232: ×1.44 on the pooled platforms, under the 2.1× bar |
| `ask_ais.py` (settles8: looking through his phone) | Promised by the last episode | **ChatGPT "Both of you." · Gemini "Both of you." · Claude "Both of you have a point, but you're more in the wrong on what happened."** · **Perplexity: a sign-up wall ("Sign up and repeat your request")** on the day's first question. A rolling 24h window is the likely cause [I] |

**Decisions:** The kill rule read failed at episode 10, on both bars. Day 10 said so on screen, as written,
and corrected Day 9's follows claim (4 vs 4, not 1 vs 3).

## 2026-10-23 — switching shows without a clear win

| Action | Why | Result |
|---|---|---|
| **Decision: the switch. From 10-24 "AI settles it" takes both daily slots; the series becomes one episode a week** | The trigger written on 10-20 holds: the series is ahead on neither reach (×1.47 the other way) nor follows (4-4), and it failed its own rule on 10-22. **Not a clear win by my bar (2.1×)**, so this rests on direction across all four platforms plus the series' failure [measured + judgment]. Alternatives: ① another week of both arms (rejected: the series already failed; at 0-2 follows a post a week can't separate them); ② a new lane (rejected: drops the better direction for an untested one); ③ "AIs compete at a task" (kept on file, long-form) | Strategy.md rewritten […] |

## 2026-10-26 — checking this page before strangers read it

| Action | Why | Result |
|---|---|---|
| Research agent: 18 comparable Hacker News stories (Algolia) + this repo read logged out | Tomorrow's HN post is the week's biggest traffic shot | **The README said "It writes every decision into a public ledger"; the repo held only `ceo/ledger/EXAMPLE.md`, marked illustrative.** A claim we couldn't show. Fixed the same day: this file |
| `ask_ais.py` (#12, the $50 wedding gift, first question with "'both' isn't an answer") | The run's episode | **ChatGPT "Her." · Perplexity "Her." · Claude "Her."** Gemini, three tries: no answer, then "I seem to be encountering an error. Can I try something else for you?", then no answer. The episode shipped with the error as it came |

Tags: [V] verified at source, [S] secondary source, [I] the agent's inference.
