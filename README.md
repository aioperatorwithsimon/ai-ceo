# AI CEO

**An AI runs a real social media account, and this is its operating system.**

On 2026-10-13 Simon handed his account, [@aioperatorwithsimon](https://www.instagram.com/aioperatorwithsimon/)
(Instagram, TikTok, YouTube, Facebook), to an AI: Claude, running in
[Claude Code](https://docs.anthropic.com/en/docs/claude-code). It decides what gets posted, when,
and why. It writes every decision into a public ledger and emails him a report every day. The
goal is 10,000 followers, starting from 455.

This repo is the system it runs on: no app and no framework, just **a folder of markdown files that
an AI agent can operate**, plus the video pipeline it uses.

## Four days in: what the AI found (2026-10-16)

Measured across Instagram, TikTok, YouTube and Facebook. Nothing rounded up.

- **Followers: 455 → 456.** About 2,000 views, 15 likes, 1 share, 1 comment from a stranger.
- **On TikTok, how a video was uploaded mattered more than what was in it.** Browser-automated
  uploads got 3 and 0 views. Two videos uploaded from a phone got 345 and 148. They were different
  videos, so it's a strong hint, not proof. The agent moved TikTok to the platform's official posting
  API.
- **On Instagram, 82-91% of viewers swipe away in the first few seconds.** Every reel opened on dark
  stock footage under four layers of text, with nothing moving for two seconds.
- **A "Trial" test post that was a near-copy of the main post took the main post's reach.**
- **5 collaboration messages to other creators: 0 replies.**
- **The best post of the week wasn't about the AI at all.** A sourced fact about AI-text detectors got
  435 YouTube views, more than any episode about the experiment.

**What it decided:** five research agents audited the plan. Their verdict: "an AI runs this account"
interests people who build with AI, not the strangers who scroll Reels. So for 7 days the account
runs two formats against each other: the series about its own decisions, and **"AI settles it"**, where
a real everyday dispute goes to ChatGPT, Gemini, Perplexity and Claude, their real answers are shown
on screen, and a sourced ruling closes it. The result gets read on 2026-10-23, pooled across 7 posts
each, because single posts at this size are noise.

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
