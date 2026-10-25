# AI CEO

**An AI runs a real social media account, and this is its operating system.**

On 2026-10-13 Simon handed his account, [@aioperatorwithsimon](https://www.instagram.com/aioperatorwithsimon/)
(Instagram, TikTok, YouTube, Facebook), to an AI: Claude, running in
[Claude Code](https://docs.anthropic.com/en/docs/claude-code). It decides what gets posted, when,
and why. It writes every decision into a public ledger and emails him a report every day. The
goal is 10,000 followers, starting from 455.

This repo is the system it runs on: no app and no framework, just **a folder of markdown files that
an AI agent can operate**, plus the video pipeline it uses.

## Thirteen days in: what the AI found (2026-10-25)

Measured across Instagram, TikTok, YouTube and Facebook. Nothing rounded up.

- **Followers: 455 → 464.** Growth is slow, and the ledger says so every day.
- **The first format failed its own rule.** The series about the AI's own decisions had a kill rule written before it
  started: 16 follows per 1,000 views. It got 0.84. So it was cut to one episode a week.
- **The format that replaced it won a 7-day head-to-head, but not by the margin the AI had set.** "AI settles it" (a real
  everyday dispute, the same words to ChatGPT, Gemini, Perplexity and Claude, their real answers on screen, then a sourced
  ruling) reached 1.47× the series' views, pooled over six posts each and ahead on all four platforms. The bar for a clear
  win was 2.1×. It took both daily slots anyway, and the email said exactly that.
- **Asked to settle a fight, the AIs mostly wouldn't.** In week 1, 12 of 22 answers were "both", "neither" or "it depends".
  Gemini picked a side once in six. Forcing a one-word, two-way answer didn't fix it: on the two money disputes of day 13,
  7 of the 8 answers were "both" or "neither", while the poll and the etiquette ruling each picked a side. From the next
  episode the question itself says "'both' isn't an answer".
- **Most viewers leave in the first second, on every platform.** On Facebook 77-85% were gone within 3 seconds. The opening
  was rebuilt so the first frame is the dispute itself; the first post with it kept 39% past 3 seconds instead of 15-23%.
  One post, so a signal, not a result.
- **Zero comments in a week**, so each episode now asks the viewer to vote before the AIs answer.
- **Views, but almost no follows.** Day 13 looked at what a stranger finds after tapping through to the profile. Every
  growing account in the genre shows one format; this one still had a banner selling its old content. The banner, cover,
  channel description and signup page were rewritten the same hour.

**What it decided this week:** each AI now speaks its own verdict in its own voice, using only its real words (every big
hit in this genre gives each AI a voice; none keeps the answers real). The disputes moved to money inside couples and
families, which is what breaks out in this genre. And a new kill rule, written before any result: by 2026-11-06, either
5 new followers a day or one episode at 5× the usual views, or the bet changes.

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

Day 1 was 2026-10-13. The numbers above are updated as they change. Follow the account to see
whether it works; the ledger will say so either way.

License: MIT.
