#!/bin/bash
# build_reel.sh — THE reel builder. Shared by every reel; nothing here is per-reel.
#
#   ./build_reel.sh <config.sh>
#
# The config supplies ONLY: NAME, and the CLIP/LEN/DIR/SEEK tables. Everything else —
# the pan-crop, the shade compositing, the xfade chain, the audio chain and every
# assertion — lives here so a new reel never re-derives it. See reels/README.md.
#
# Shape:
#   per beat: pan-crop the footage over an oversized frame -> card overlay (shade is IN the card)
#   then:     fold segments two at a time with xfade, using MEASURED durations
#   then:     music bed + per-SFX pre-roll, float intermediate, measured peak, encode ONCE
set -euo pipefail
cd "$(dirname "$0")"

W=1080; H=1920; FPS=30
XF=0.08                      # near-hard cut: 0.20 ghosts two headlines mid-dissolve
CFG="${1:?usage: ./build_reel.sh <config.sh>}"
. "./$CFG"                      # supplies NAME + CLIP/LEN/DIR/SEEK
: "${NAME:?config must set NAME}"

# defaults AFTER the config, so they can use $NAME
MUSIC="${MUSIC:-work/music_$NAME.mp3}"
MUSIC_START="${MUSIC_START:-0}"
MUSIC_VOL="${MUSIC_VOL:-0.55}"

RAW=raw; CARDS="work/cards_$NAME"; SEG="work/seg_$NAME"; SFX=sounds
OUT="out/$NAME.mp4"
mkdir -p "$SEG" out

MUSIC_START="${MUSIC_START:-0}"
MUSIC_VOL="${MUSIC_VOL:-0.55}"

dur () { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"; }

# ⚠️ THE BEAT COUNT IS DERIVED FROM THE CONFIG, NEVER HARDCODED.
# Every loop here used to read `for n in 1 2 3 4 5 6 7 8`, which was invisible for seventeen
# reels because every one of them had exactly 8 beats. The first 9-beat reel built CLEANLY and
# silently dropped its 9th beat — the OUTRO, i.e. the brand mark — with no error and no warning:
# the config said 9, the video came out 8, and only the segment listing showed it.
# CLIP[0] is the leading `x` placeholder every config uses, so NBEATS = length - 1.
NBEATS=$(( ${#CLIP[@]} - 1 ))
[ "$NBEATS" -ge 2 ] || { echo "FAIL: need >=2 beats, config gives $NBEATS"; exit 1; }
# The parallel tables must agree, or a beat silently renders with an empty LEN/DIR/SEEK.
for T in LEN DIR SEEK; do
  eval "L=\${#$T[@]}"
  [ "$L" = "${#CLIP[@]}" ] || { echo "FAIL: $T has $((L-1)) entries, CLIP has $NBEATS"; exit 1; }
done
echo "beats: $NBEATS"

# beat -> clip, duration, pan direction
echo "== segments =="
for n in $(seq 1 $NBEATS); do
  SRC="$RAW/${CLIP[$n]}.mp4"; D=${LEN[$n]}; S=${SEEK[$n]}
  OW=$((W*112/100)); OH=$((H*112/100))
  # Lift the FOOTAGE rather than lightening the scrim (gamma opens mid-tones without
  # greying blacks). Chosen from the clip's OWN measured luma, per run — hardcoding one
  # constant is what left five beats black.
  ffmpeg -y -v error -ss "$S" -i "$SRC" -frames:v 1 "$SEG/.probe_$n.png"
  LUMA=$(magick "$SEG/.probe_$n.png" -colorspace Gray -format "%[fx:mean]" info:)
  GAM=$(python3 -c "
l=float('$LUMA')
print(1.55 if l<0.22 else 1.42 if l<0.30 else 1.28 if l<0.40 else 1.12)")
  # ⚠️ d2u was documented as a valid direction but NOT implemented — an unmatched value left
  # XE/YE unset and the beat rendered with a broken/absent pan. Every direction the spec offers
  # must exist here, and an unknown one must fail loudly rather than silently.
  case "${DIR[$n]}" in
    l2r) XE="(iw-ow)*t/$D";     YE="(ih-oh)/2" ;;
    r2l) XE="(iw-ow)*(1-t/$D)"; YE="(ih-oh)/2" ;;
    u2d) XE="(iw-ow)/2";        YE="(ih-oh)*t/$D" ;;
    d2u) XE="(iw-ow)/2";        YE="(ih-oh)*(1-t/$D)" ;;
    *)   echo "FAIL: beat $n has unknown DIR '${DIR[$n]}' (use l2r|r2l|u2d|d2u)"; exit 1 ;;
  esac
  # ── local block: the global gradient CANNOT protect type from a bright moving
  #    object (a lit laptop lid, a sunrise). Beats over bright plates get an extra
  #    block sized to where the GLYPHS render — measured, not guessed:
  #      beat 4 laptop edge  -> 1.91:1 without it
  #      beat 7 sunrise sky  -> 1.33:1 on the CTA line, the reel's most important line
  #    Darken the BAND, not the frame: start ABOVE the first line of type
  #    (protect the TOPMOST line, not the biggest one) and keep fast falloff.

  # The card must be RGBA and must NOT be fully opaque, or the footage never shows.
  # ⚠️ The test is the MEAN, not the minimum: the card now carries its own .shade, so
  # a legitimately-shaded card has NO fully-transparent pixel and a minima test fails
  # it wrongly (that exact check blocked this build once).
  MEANA=$(magick "$CARDS/c$n.png" -alpha extract -format "%[fx:mean]" info:)
  CH=$(magick "$CARDS/c$n.png" -format "%[channels]" info:)
  case "$CH" in *a*) ;; *) echo "FAIL: c$n.png is $CH, not RGBA — it will paint black"; exit 1 ;; esac
  python3 -c "import sys; sys.exit(0 if float('$MEANA') < 0.92 else 1)" \
    || { echo "FAIL: c$n.png mean alpha $MEANA — too opaque, the footage will not show"; exit 1; }

  # The seek is a trim INSIDE the graph: frame-accurate, and it cannot land on the wrong input.
  # (A `-ss`/`-t` on the command line binds to the NEXT `-i` — here the card — so it once
  # left every beat playing its clip from 0s whatever SEEK said.)
  ffmpeg -y -v error -stream_loop -1 -i "$SRC" -an \
    -loop 1 -framerate $FPS -i "$CARDS/c$n.png" \
    -filter_complex "\
[0:v]trim=start=$S:duration=$D,setpts=PTS-STARTPTS,fps=$FPS,\
scale=${OW}:${OH}:force_original_aspect_ratio=increase:flags=lanczos,\
crop=${OW}:${OH},crop=${W}:${H}:x='${XE}':y='${YE}',eq=gamma=${GAM},settb=AVTB[bg];\
[1:v]fps=$FPS,scale=${W}:${H},settb=AVTB[c];\
[bg][c]overlay=0:0:format=auto,format=yuv420p[v]" \
    -map "[v]" -c:v libx264 -preset veryfast -crf 18 -threads 2 \
    -frames:v "$(python3 -c "print(int($D*$FPS))")" "$SEG/s$n.mp4" &
  printf "  s%s  %s  dir=%-3s luma=%.3f gamma=%s\n" "$n" "${CLIP[$n]}" "${DIR[$n]}" "$LUMA" "$GAM"
done
wait                                  # all 8 segment encodes run concurrently

# ── ONE-PASS xfade chain ──────────────────────────────────────────────────
# Folding two clips at a time is RAM-safe for long videos. At ~17-60s that
# caution is backwards: the ladder RE-ENCODES the whole growing file once per
# beat (quadratic — measured 22s for the last fold alone, ~150s for the chain).
# One pass encodes the video exactly once: measured 51.6s, same output duration.
INPUTS=(); FC=""
for n in $(seq 1 $NBEATS); do INPUTS+=(-i "$SEG/s$n.mp4"); done
for n in $(seq 1 $NBEATS); do FC="${FC}[$((n-1)):v]fps=$FPS,settb=AVTB[v$n];"; done
ACC=0; CHAIN="[v1]"
for n in $(seq 2 $NBEATS); do
  D=$(dur "$SEG/s$((n-1)).mp4")
  ACC=$(python3 -c "print(round($ACC + $D - $XF, 3))")   # MEASURED, never assumed
  OUTLBL="[x$n]"; [ "$n" = "$NBEATS" ] && OUTLBL="[vout]"
  FC="${FC}${CHAIN}[v$n]xfade=transition=fade:duration=$XF:offset=$ACC$OUTLBL;"
  CHAIN="$OUTLBL"
done
FC="${FC%;}"
ffmpeg -y -v error "${INPUTS[@]}" -an -filter_complex "$FC" \
  -map "[vout]" -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p "$SEG/chain.mp4"
cp "$SEG/chain.mp4" "$SEG/video_nosound.mp4"

VID="$SEG/video_nosound.mp4"
TOTAL=$(dur "$VID"); echo "video total: $TOTAL"

# ── measured segment starts (after xfade overlap) for SFX placement ──
python3 - "$SEG" "$XF" "$NBEATS" > "$SEG/starts.txt" <<'PY'
import subprocess, sys, pathlib
seg = pathlib.Path(sys.argv[1]); xf = float(sys.argv[2]); nb = int(sys.argv[3])
def d(p):
    return float(subprocess.run(["ffprobe","-v","error","-show_entries","format=duration",
        "-of","csv=p=0", str(p)], capture_output=True, text=True).stdout.strip())
t = 0.0; out = []
for n in range(1, nb + 1):
    out.append(f"{n} {t:.3f}")
    t += d(seg / f"s{n}.mp4") - (xf if n < nb else 0)
print("\n".join(out))
PY

# ── CAPTIONS (optional, voiced reels): config sets CAPTIONS=1 [+ CAPTION_SKIP="1,9"].
#    One transparent word-synced caption track, overlaid once onto the finished video chain.
if [ "${CAPTIONS:-0}" = 1 ] && [ -n "${VOICE_DIR:-}" ]; then
  "${PY:-python3}" captions.py "$VOICE_DIR" "$SEG/starts.txt" "$TOTAL" "$SEG/captions.mov" \
    --lead "${VOICE_LEAD:-0.12}" --skip "${CAPTION_SKIP:-}"
  ffmpeg -y -v error -i "$SEG/chain.mp4" -i "$SEG/captions.mov" \
    -filter_complex "[0:v][1:v]overlay=0:0:format=auto,format=yuv420p[v]" -map "[v]" \
    -c:v libx264 -preset veryfast -crf 18 -an "$SEG/video_capt.mp4"
  VID="$SEG/video_capt.mp4"
fi

# ── audio. -ss BEFORE -i for the AUDIO BED (inverted vs video): after -i keeps
#    absolute timestamps and afade's st= then fades the WHOLE bed to silence.
ffmpeg -y -v error -ss "$MUSIC_START" -i "$MUSIC" -t "$TOTAL" -ac 2 -ar 48000 "$SEG/bed.wav"
BEDMEAN=$(ffmpeg -hide_banner -nostats -i "$SEG/bed.wav" -af volumedetect -f null - 2>&1 \
          | grep -oE "mean_volume: -?[0-9.]+" | awk '{print $2}')
echo "bed mean: ${BEDMEAN} dB"
python3 -c "import sys; sys.exit(0 if float('$BEDMEAN') > -30 else 1)" \
  || { echo "FAIL: bed is silent (${BEDMEAN} dB) — the -ss/-i order is wrong"; exit 1; }

# The mix has NO video input, so the bed is input 0 and the SFX start at 1.
# (an assembler that feeds the video in as input 0 — copying its indices shifts
#  every stream by one and ffmpeg fails with "Invalid file index".)
AMIX="[0:a]volume=${MUSIC_VOL},afade=t=in:st=0:d=0.4,afade=t=out:st=$(python3 -c "print($TOTAL-1.0)"):d=1.0[m];"
IDX=1; INPUTS=(-i "$SEG/bed.wav"); LABELS="[m]"
while read -r n t; do
  case "$n" in
    1)     F="$SFX/Text Drop.mov";        EARLY=0    ;;
    2|4|6) F="$SFX/Whoosh Quick.mp3";     EARLY=0    ;;
    3|5)   F="$SFX/Whoosh Transition.mp3";EARLY=0.70 ;;   # peaks 0.70s in — fire early
    7)     F="$SFX/Whoosh And Impact.mp3";EARLY=0.70 ;;
    8)     F="$SFX/Text Drop.mov";        EARLY=0    ;;
  esac
  DELAY=$(python3 -c "print(int(max(0,($t-$EARLY))*1000))")   # adelay takes MILLISECONDS
  if [ -f "$F" ]; then          # SFX are optional: put your own files in sounds/ to use them
    INPUTS+=(-i "$F")
    # With a voice track the whooshes are texture under speech, not the event.
    SFXVOL=0.8; [ -n "${VOICE_DIR:-}" ] && SFXVOL=0.3
    AMIX="${AMIX}[${IDX}:a]adelay=${DELAY}|${DELAY},volume=${SFXVOL}[s${IDX}];"
    LABELS="${LABELS}[s${IDX}]"
    IDX=$((IDX+1))
  fi
  # VOICE (optional): config sets VOICE_DIR; vN.mp3 starts VOICE_LEAD after beat N starts.
  # Beat lengths come from the measured line durations (scripts/voice/tts.py prints them).
  if [ -n "${VOICE_DIR:-}" ] && [ -f "$VOICE_DIR/v$n.mp3" ]; then
    VD=$(python3 -c "print(int(($t+${VOICE_LEAD:-0.12})*1000))")
    INPUTS+=(-i "$VOICE_DIR/v$n.mp3")
    AMIX="${AMIX}[${IDX}:a]aformat=sample_rates=48000:channel_layouts=stereo,adelay=${VD}|${VD},volume=${VOICE_VOL:-1.0}[s${IDX}];"
    LABELS="${LABELS}[s${IDX}]"
    IDX=$((IDX+1))
  fi
done < "$SEG/starts.txt"
NIN=$IDX      # bed + one SFX per beat (+ one voice line per voiced beat)

# float intermediate: 16-bit CLIPS the sum, so measuring it would lie
ffmpeg -y -v error "${INPUTS[@]}" \
  -filter_complex "${AMIX}${LABELS}amix=inputs=${NIN}:normalize=0:duration=first[a]" \
  -map "[a]" -c:a pcm_f32le "$SEG/mix32.wav"

# ⚠️ MAX across channels, never `head -1`. astats prints one line PER CHANNEL then an Overall line;
# taking the first read only channel 1, so a stereo mix whose RIGHT channel is hotter passed the
# gate while clipping. reel67 shipped at ch1 -1.14 dB / ch2 +0.32 dB on exactly that bug.
PEAK=$(ffmpeg -hide_banner -nostats -i "$SEG/mix32.wav" -af astats=measure_overall=Peak_level \
       -f null - 2>&1 | grep -oE "Peak level dB: -?[0-9.inf]+" | awk '{print $4}' \
       | sort -g | tail -1)
GAIN=$(python3 -c "
p='$PEAK'
pk=0.0 if p in ('inf','-inf','') else float(p)
print(round(-1.0-pk,3))")
echo "mix peak ${PEAK} dB -> applying ${GAIN} dB"
ffmpeg -y -v error -i "$SEG/mix32.wav" -af "volume=${GAIN}dB" -c:a aac -b:a 192k "$SEG/final.m4a"

# ⚡ MUX ONLY — the xfade chain already encoded this video. Re-encoding it here
# was pure waste: measured 121.7s vs 0.53s for a stream copy, byte-identical spec
# (h264 1080x1920 yuv420p 30fps). That single line was HALF the build time.
# The audio is already AAC from the gain stage, so both streams copy.
ffmpeg -y -v error -i "$VID" -i "$SEG/final.m4a" -map 0:v -map 1:a \
  -c:v copy -c:a copy -shortest -movflags +faststart "$OUT"

# Voiced reels: bring the whole mix to platform loudness (−14 LUFS, −1.5 dBTP). The peak-gain
# stage above only prevents clipping; a voice track then sits ~−21 dB, quiet next to other reels.
if [ -n "${VOICE_DIR:-}" ]; then
  ffmpeg -y -v error -i "$OUT" -map 0:v -map 0:a -c:v copy \
    -af "acompressor=threshold=-20dB:ratio=3:attack=5:release=80,loudnorm=I=-14:TP=-1.5:LRA=9" \
    -ar 48000 -c:a aac -b:a 192k -movflags +faststart "$SEG/loud.mp4"
  mv "$SEG/loud.mp4" "$OUT"
  ffmpeg -hide_banner -nostats -i "$OUT" -af ebur128=peak=true -f null - 2>&1 | grep -E "^ +I:|Peak:" | tail -2
fi

# assert the peak on the OUTPUT (alimiter does not hold its ceiling; AAC overshoots)
OPEAK=$(ffmpeg -hide_banner -nostats -i "$OUT" -af astats=measure_overall=Peak_level -f null - 2>&1 \
        | grep -oE "Peak level dB: -?[0-9.inf]+" | awk '{print $4}' | sort -g | tail -1)
echo "output peak: ${OPEAK} dB"
python3 -c "import sys; sys.exit(0 if float('$OPEAK') < -0.1 else 1)" \
  || { echo "FAIL: output clips (${OPEAK} dB)"; exit 1; }

echo "== final =="
ffprobe -v error -show_entries format=duration,size \
  -show_entries stream=width,height,codec_name,r_frame_rate \
  -of default=noprint_wrappers=1 "$OUT"
