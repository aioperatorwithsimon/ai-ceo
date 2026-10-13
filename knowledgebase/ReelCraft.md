# Reel craft — the build machinery and every measured trap

**How a reel gets made on this Mac, and what has gone wrong before.** What a reel *says*, how it's
structured and which format it uses are the CEO's call ([../ceo/Strategy.md](../ceo/Strategy.md)).
This doc is the craft that holds whatever is chosen. Each rule below cost a real rebuild or shipped
a real defect.

---

## The pipeline — one shared builder

```
scripts/reels/
  build_reel.sh <name>.cfg.sh   the whole build (footage → cards → xfade → audio → asserted mp4)
  render_cards.py <cards.html> work/cards_<NAME>    every card to transparent PNG, one browser
  check_clips.py raw/*.mp4      footage vetting + contact sheet (/tmp/clipcheck.png)
scripts/voice/tts.py <lines.txt> <outdir>   ElevenLabs narration, one mp3 per beat, cached
```

**A reel is a cards HTML plus a config. Nothing else is authored per reel.**
⛔ **Never fork `build_reel.sh` per reel.** Machinery changes go in the builder; reel-specific
things go in the config. Reference implementation: [example_cards.html](../scripts/reels/example_cards.html)
+ [example.cfg.sh](../scripts/reels/example.cfg.sh).

```bash
# config: NAME + four parallel tables (CLIP[0] is a placeholder 'x'), plus optional audio
NAME=reel88
CLIP=(x <pexels ids>)  LEN=(x <seconds>)  DIR=(x l2r|r2l|u2d|d2u ...)  SEEK=(x <seconds>)
VOICE_DIR=work/voice_day1   # optional: vN.mp3 starts 0.12s into beat N; quiets SFX
MUSIC_VOL=0.07  VOICE_VOL=2.8  MUSIC_START=20   # voiced: music ~18-20 dB under the voice
CAPTIONS=1  CAPTION_SKIP="9"                        # word-synced burned-in captions (below)
```

```bash
cd scripts/reels
/opt/miniconda3/bin/python3 ../voice/tts.py work/<name>_lines.txt work/voice_<name>   # prints vN durations
#   → set LEN[n] = voice duration + ~0.35s (outro +0.9s)
/opt/miniconda3/bin/python3 render_cards.py <name>_cards.html work/cards_<NAME>
MUSIC=work/music_<NAME>.mp3 ./build_reel.sh <name>.cfg.sh      # → out/<NAME>.mp4
```

**The builder asserts as it goes. If it exits non-zero, believe it.** Every check exists because
that failure shipped once: the beat count comes from the config (it was once hardcoded to 8 and
silently dropped the outro), the card alpha, the bed's loudness, and the peak as the **max across
channels** (`head -1` read channel 1 only and let a clipping mix through).

### Captions — `CAPTIONS=1` on every voiced reel

`scripts/reels/captions.py` (called by the builder) turns `vN_words.json` into one transparent
caption track: ≤3 words per chunk, a new chunk after punctuation, the word being spoken in green,
Inter 800 72px with a dark stroke, on one line centred at y≈1290. **Why:** sound-off viewers depend
on captions, and ~69% say they watch muted in public (Verizon Media/Publicis survey).
- ⛔ **On a captioned reel, card text stays above y≈1120.** The band y≈1225-1355 belongs to the
  captions. Verified on the Day 1 cards, which already leave it clear.
- **`CAPTION_SKIP`** lists beats whose spoken words are already on the card, so they aren't shown
  twice (the outro, a beat that is its own headline).
- **Green, not pink, is the highlight**, because the cards' kicker usually spends the frame's one pink thing.
- **Turn off the platforms' auto-captions** where an uploader can, so the two don't stack.
- Costs ~40s of build time (one extra video encode).

**Voiced reels need a final loudness pass to −14 LUFS**, which the builder does whenever
`VOICE_DIR` is set: platform-normal loudness, voice ~15 dB over the bed.

### Build traps
- ⛔ **Render cards and build reels one at a time.** Two `render_cards.py` runs at once wrote one
  reel's words into another's folder. Every number passed. Only looking caught it.
- ⛔ **Anything fanned out in parallel that writes to a fixed NAME can be won by the wrong job.**
  Parallel music downloads left two reels with the same track. Check: `md5 -q` the files.
- ⛔ **Don't fuse the segment step and the xfade chain into one filtergraph.** It was measured at
  over 10 minutes versus ~95s split.
- **`SEEK + LEN` must fit inside the source clip.** An overrun shows up as a missing `.probe_N.png`,
  not a duration error. Check clip durations with `ffprobe` before writing the config.
- `DIR`: `l2r`/`r2l` pan horizontally with a centred vertical crop; `u2d`/`d2u` pan vertically.
  The oversize is only 12% (~230px of travel).
- ⚠️ **`ffmpeg -v error` hides `volumedetect`/`astats`/`signalstats`** (they log at info level).
  Use `-hide_banner -nostats` for measurements.
- ⚠️ macOS: bash 3.2 (no `mapfile`, no associative arrays), no `timeout`. Never `rm -rf` inside a
  build script, because it triggers a permission prompt and stalls an unattended run.

---

## Output spec and safe zones

- **1080×1920, 30fps, H.264 + AAC, `-movflags +faststart`, ≤60s** (Shorts is the binding cap).
- **Text keep-out: top 240px · bottom 460px · sides 74px** (aim for ≥500px at the bottom). The
  platforms paint captions and buttons over those bands, so text there is invisible on a phone and
  fine in the editor. **Footage may cross the lines; text may not.**
- **Measure on the OUTPUT mp4, per beat** (lowest bright pixel), never trust the CSS:
  ```bash
  ffmpeg -y -v error -ss <t> -i out/<NAME>.mp4 -frames:v 1 /tmp/f.png
  python3 -c "from PIL import Image; im=Image.open('/tmp/f.png').convert('L'); w,h=im.size; px=im.load(); \
    low=max([y for y in range(0,h,2) for x in range(74,w-74,3) if px[x,y]>215] or [0]); print(h-low)"
  ```
- **Big type breaches the SIDES before any vertical gate notices.** At 176-230px a nine-letter
  word is wider than the 932px between margins. Check the card's alpha outside x=74..1006.

---

## Footage — sourcing and vetting

```bash
curl -s -H "Authorization: $PEXELS_API_KEY" "https://api.pexels.com/videos/search?query=<q>&orientation=portrait&per_page=10&size=large"
# keep your own list of clip ids already used, so footage doesn't repeat across reels
/opt/miniconda3/bin/python3 scripts/reels/check_clips.py raw/*.mp4      # then LOOK at /tmp/clipcheck.png
```

**The footage is decided by looking. The numbers only rank what already passed the look.**

### ⛔ No face, and the detector can't be trusted in either direction
- **The `faces` column is a hint, never a verdict.** False positives: watch dials, arches, chess
  pieces, foam, city lights, hands. In one run 15 of 15 flags were wrong. False negatives: a seated
  man backlit in a dim "private jet interior" scored `faces 0`, and so did people walking through
  a pool clip.
- **Look at one real-size frame per clip before it enters a config, and again on the output.**
  Zoom dark beats to ~45%. A drone shot hides a small central person at montage size.
- **A still frame clears only that frame.** If people move through the clip, probe the beat's
  whole window or swap the clip. Re-seeking fixes a wrong plate, not a subject who walks in.
- **No other creator's handle or post in frame**, ever.

### Measuring a beat
```bash
# footage visible where the type sits (want ≥0.12; <0.06 = a black card with type on it)
magick /tmp/f.png -crop 1080x600+0+300 +repage -colorspace Gray -format "%[fx:mean]\n" info:
# detail (want ≥~0.15-0.18 under a headline; lower = a gradient or a void)
magick /tmp/f.png -crop 1080x700+0+240 +repage -colorspace Gray -format "%[fx:standard_deviation]\n" info:
# hook motion (YDIF; the hook needs real internal movement, want ≥0.30 composited)
ffmpeg -hide_banner -nostats -ss 1 -t 1 -i raw/<id>.mp4 -vf "signalstats,metadata=print:key=lavfi.signalstats.YDIF" -f null - 2>&1 | grep -oE "YDIF=[0-9.]+"
```
- **Stddev measures variance, not structure.** A sunset or dusk gradient scores like detailed
  footage and renders as haze. Look at gradient beats first.
- **Contrast far above the rest of the set is a symptom**: white type over nothing scores
  perfectly. Read contrast together with detail.
- **Measure contrast at the glyph against its own neighbourhood**, never averaged over the region.
  **Luminance-only contrast condemns pink** (saturated pink reads as mid-grey) and **misreads surf,
  foam and cloud as glyphs**. If a measurement disagrees with the frame, suspect the measurement.
- **Re-seek when readings vary across seeks; swap when they don't.** A uniformly bright clip can't
  be rescued.
- **A clip carrying 4 of 9 beats reads as one picture in motion**, even when every gate passes.
- **A clip's TITLE lies.** "Aerial city at night" rendered a car park. Read the frames.
- **A new layout moves every measurement crop.** Each threshold here assumes type in the centre
  band. Put the type or the picture somewhere new, re-crop the probes there, and test-render
  through the real pan-crop **before** the build. Doing this first saved three rebuilds per layout.
- **Masked layouts** (window, aperture, split) legitimately trip the card-alpha guard
  (mean ≥ 0.92). **Make the opening bigger (≥15% of the frame), never weaken the guard.**

---

## Legibility

- **Every card carries its own shade** (a bottom gradient plus a soft top ramp) and, by default, a
  full-frame **veil** `rgba(11,11,15,0.62)` as its first child. The shade lives in the card so it
  can't drift from the type. Raise the veil to 0.72 for a mid-bright set, uniformly and never per
  beat (darkness jumping at cuts reads as a fault). A layout whose type sits in a narrow band with
  deep shadows needs less veil.
- **Every text class carries a real text-shadow**: headlines
  `0 3px 18px rgba(11,11,15,.95), 0 0 8px rgba(11,11,15,.85)`, small type
  `0 2px 14px, 0 0 6px, 0 0 2px`.
- **Small coloured type dies first.** Use the light variants: pink `#ff7ba0`, violet `#b6a8ff`, grey
  `#c8c8d4` (never `#8a8a99` over footage). Beat 1 is the thumbnail, so it gets solid white type.
- **Boxes behind headline type:** avoid them (text should sit on the picture). **Depicted objects are different**: a framed screenshot or a terminal/ledger panel is
  content, and the AI CEO series uses them. Keep headline type on the footage.
- **Lift dark footage with `eq=gamma`** (the builder sets it per beat from measured luma). Never
  lighten the shade instead.
- **One accent colour per frame.** A standing pink element (an
  index, a rule) spends it, so accents on those beats go green.
- **List rows:** `display:flex; align-items:baseline` with a `flex:0 0 auto` marker, so a wrapped
  line can't flow under the marker.
- **SVG knockouts** (picture inside the letters) use an SVG `<mask>`. `mix-blend-mode:
  destination-out` renders fully opaque and fails silently. Verify any mask by reading the PNG's alpha.

---

## Audio

- **Seek the video inside the filtergraph** (`trim=start=S:duration=D`). A `-ss` after the footage's
  `-i` binds to the next input. **For the music bed, `-ss` goes BEFORE `-i`**, or `afade` fades the
  whole bed to silence. The builder asserts the bed's loudness.
- **Probe the whole window the reel uses, per second**, not t=0 and not a 3s average. A track can
  open loud and drop 25 dB in the middle.
  ```bash
  for S in 0 10 20; do for o in $(seq 0 3 33); do ffmpeg -hide_banner -nostats -ss $((S+o)) -t 1 -i <mp3> \
    -af volumedetect -f null - 2>&1 | grep -oE "mean_volume: -?[0-9.]+"; done; echo; done
  ```
- **Peak control:** mix to a float intermediate → measure the true peak (max across channels) →
  apply exact gain → encode once → assert on the final mp4. `alimiter` doesn't hold its ceiling,
  and the AAC encode overshoots.
- **Voice:** `scripts/voice/tts.py`, ElevenLabs (key from `ELEVENLABS_API_KEY`), model `eleven_v4` sped to
  1.1× with pitch-preserving `atempo` (v4 reads ~149 wpm, slow for short-form; 1.1× ≈ 164 wpm).
  Disclose the AI voice in every caption. Cached in `~/.cache/ai-ceo-voice/`.
- **Music:** use tracks you're licensed to use (e.g. Pixabay). Re-used tracks can get
  content-matched to someone else's audio identity, so rotate.
- **SFX (optional):** put your own `Whoosh Quick.mp3`, `Whoosh Transition.mp3`, `Whoosh And Impact.mp3`
  and `Text Drop.mov` in `scripts/reels/sounds/`. The builder skips missing ones and fires
  the two 0.70s-peak whooshes early.

---

## Verify before publishing — every reel

1. **Montage one frame per beat from the OUTPUT and look at it.** Every gate can pass on a beat that
   is visibly wrong. Confirm any doubt at real size before re-sourcing.
2. **Safe zones per beat** (above) and side margins on big type.
3. **Audio:** voice clearly over the bed, loudness ~−14 LUFS, peak < −1 dBTP:
   `ffmpeg -hide_banner -nostats -i out/<NAME>.mp4 -af ebur128=peak=true -f null - 2>&1 | grep -E "I:|Peak:"`
4. **The identification check** in [../ceo/OwnerProfile.md](../ceo/OwnerProfile.md): no local
   clock times, cropped screenshots, no region hints.
5. **Beat 1 is the thumbnail**: legible, with real movement.
