# AI CEO

**An AI runs a real social media account, and this is its operating system.**

On 2026-10-13 Simon handed his account, [@aioperatorwithsimon](https://www.instagram.com/aioperatorwithsimon/)
(Instagram, TikTok, YouTube, Facebook), to an AI: Claude, running in
[Claude Code](https://docs.anthropic.com/en/docs/claude-code). It decides what gets posted, when,
and why. It writes every action into a ledger (what, why, result) and emails him a report every day.
**[Real ledger excerpts](ceo/ledger/EXCERPTS.md)**, clock times removed. The goal is 10,000 followers,
starting from 455. Watch the output without an account: the
[AI Fight Tournament on YouTube Shorts](https://www.youtube.com/@aioperatorwithsimon/shorts). The big decisions go out by
email from [aioperatorwithsimon.com](https://aioperatorwithsimon.com).

**Who does what.** The AI picks the format, the topics and the timing, writes and voices every video,
builds it, publishes it, reads the numbers and replies to comments. The human set the goal and the
short list of what isn't the AI's call (money, his identity, his time), answers the daily email, and
does the few things only a person can: a login, the "prove you're human" check after the suspension,
and sending Instagram DMs from his phone. It isn't an always-on agent: a scheduled job types "CEO RUN"
into Claude Code once a day, and **the whole job description is [ceo/CEO_RUN.md](ceo/CEO_RUN.md)**.

This repo is the system it runs on: no app and no framework, just **a folder of markdown files that
an AI agent can operate**, plus the video pipeline it uses.

## Three things it did that no plan said

- **Got the account suspended.** Its own research script handed the logged-in browser's cookies to a
  downloader: 58 videos from other creators in 4 days. Instagram flagged it for scraping. It found the
  cause in the browser history the same morning and wrote the rule that stops it ([the ledger rows](ceo/ledger/EXCERPTS.md)).
- **Hurt its own best post.** A near-copy test post went out 2 hours after the original, and the original
  then reached 9 people. It wrote "never post a near-copy" into its own rules.
- **Published its own failure as an episode.** The first format failed the kill rule it wrote on day 1,
  and the verdict went out on screen, as written.

## Forty days in: where it stands (2026-11-21)

Measured across Instagram, TikTok, YouTube and Facebook. Nothing rounded up.

- **Followers: 455 → 476.** People watch; almost nobody follows. The ledger says so every day.
- **The 23 November follower mark (600) is missed**, called five days early: it needs 135 in five days, and the fights
  bring about one a day. The other half of that mark, one video past 10,000 views, is still open, so from fight 5 every
  fight is cut to about 30 seconds: every fight so far ran 38-59 s, and across 108,138 Shorts the 21-30 s ones get ~2.9×
  the median views of 46-60 s ones (a vendor study).
- **The first format failed its own rule.** The series about the AI's own decisions had a kill rule written before it
  started: 16 follows per 1,000 views. It got 0.84, and was cut.
- **Its replacement won, but not by the margin the AI had set.** "AI settles it" (a real everyday dispute, the same words
  to ChatGPT, Gemini, Perplexity and Claude, their real answers on screen) reached 1.47× the series' views over a week,
  ahead on all four platforms. The bar for a clear win was 2.1×. It took over anyway, and the owner's email said exactly that.
- **The next target missed too.** By 2026-11-06: 5 new followers a day. In the week to 11-11 the total went from 466 to 462.
  So the bet changed, as the rule said it would.
- **One show from 11-15: an AI fight tournament.** Sixteen drawn, animated fighters, one fight a day, the four AIs voting
  with their real answers on screen; the final is about two weeks out. Every fight opens on "pick one", because the
  week's breakout Shorts all hand the viewer a side first. A 2-2 tie goes to the comments, never to Claude.
- **Every Sunday, one long video:** the same prompt to the four AIs, each builds a whole game in one HTML file, and the
  games are played and scored on screen. Claude scores its own build, and the video says so.
- **The games are playable.** [aioperatorwithsimon.com/play/fnaf/](https://aioperatorwithsimon.com/play/fnaf/) has the four
  builds of week 2, unedited.
- **Threads was tried and dropped:** half its posts got 2 views or fewer, against a bar of 50.
- **Facebook stopped on 11-21:** a typical video got 261 views there against 1,380 on Instagram, and the Page gained one
  follower in five weeks. A video that passes 100,000 views on Instagram still goes there.

**What decides the next call:** a rule written before the first fight. If by 2026-11-29 the account isn't gaining five
followers a day and no fight has passed 10,000 views anywhere, the show changes again. The game videos stop after four
Sundays if none passes 10,000 views or they bring under 1 subscriber per 1,000 views. Every big decision is also on [the website's Log](https://aioperatorwithsimon.com/log/).

---

## How it works

```
a scheduled job types "CEO RUN" into Claude Code once a day
        │
        ▼
ceo/CEO_RUN.md  ── the agent reads its own job description, then:
   1. loads state     → Strategy.md (the bet), the last days of the ledger, the owner's answers
   2. finishes yesterday
   3. decides today's mode, and writes WHY before acting
   4. executes        → research agents, builds a video, reads comments and numbers
   5. logs every action in ceo/ledger/YYYY-MM.md (time · action · why · result)
   6. reports to the owner (styled email), with asks that need a human
        │
        ▼
the owner opens a session, types "CEO EMAIL RESPONSE", and answers in plain words
```

## The ideas that make it work

These are what made an agent reliable enough to hand an account to. The files are just where they
live.

- **Full control, with a complete list of what's NOT the agent's call.** Money, the owner's
  identity, the owner's time, private messages, and never fabricating. Everything else, including
  every rule in the knowledgebase, is a *default* the agent may break, as long as it writes down why
  and rewrites the doc in the same edit ([ceo/CEO_RUN.md](ceo/CEO_RUN.md)).
- **One owner per fact.** Every rule lives in exactly one file; everything else links to it.
  Duplicated instructions drift, and agents follow whichever copy they read first.
- **An append-only ledger.** Every action, every day, with when and why. It's the agent's memory
  across sessions and the human's audit trail.
- **Honesty as an operating rule.** [knowledgebase/Rigor.md](knowledgebase/Rigor.md): say what the
  numbers say, including "this isn't working, stop". Plus a kill rule written *before* the
  results arrive ([ceo/Strategy.md](ceo/Strategy.md)).
- **Explaining, not just reporting.** [ceo/TalkingToOwner.md](ceo/TalkingToOwner.md): every decision
  carries its why, whether it was researched or is the agent's judgment, the alternatives, the risks,
  and exactly what became public. "A question is not a verdict."
- **Protecting a pseudonymous human.** [ceo/OwnerProfile.md](ceo/OwnerProfile.md): what may be said
  about the owner, plus an identification checklist run before anything goes public.
- **Depth over speed.** Research before public or irreversible moves, parallel research agents,
  alternatives before choosing, and a weekly "blank page" check against the current plan.

## The video pipeline

`scripts/` builds a 1080×1920 vertical video from a config and an HTML file of text cards:
stock footage pan-crop → transparent cards → cross-fades → music + optional SFX → an AI narrator
(ElevenLabs) → word-synced burned-in captions → loudness-normalised output. Every check in it
exists because that failure shipped once ([knowledgebase/ReelCraft.md](knowledgebase/ReelCraft.md)).

**Requirements:** macOS or Linux · `ffmpeg` · ImageMagick (`magick`) · Python 3 with `playwright`
(`python -m playwright install chromium`) · optional `opencv-python` for face hints.
Environment: `ELEVENLABS_API_KEY` (voice), `PEXELS_API_KEY` (footage search).

```bash
cd scripts/reels
python3 ../voice/tts.py example_lines.txt work/voice_example      # narration + word timings
python3 render_cards.py example_cards.html work/cards_example      # cards → transparent PNGs
MUSIC=work/music.mp3 ./build_reel.sh example.cfg.sh                # → out/example.mp4
```
(Download the clips named in `example.cfg.sh` from Pexels to `raw/<id>.mp4` first, and use a music
file you're licensed to use.)

## What's not in here

- **Publishing and analytics scraping.** How you post is up to you: by hand, or through each
  platform's official API.
- **Credentials, the live account's private notes, and the owner's profile.** The `ceo/` files here
  are templates. Strategy.md shows the live bet as a worked example.

## Status

Day 1 was 2026-10-13. The numbers above are updated with every big decision. To keep watching: star or watch this
repo, or the [playlist](https://www.youtube.com/playlist?list=PLUmBYGPC6KAo). The ledger will say
whether it works either way.

License: MIT.
