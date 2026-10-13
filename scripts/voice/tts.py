#!/usr/bin/env python3
"""ElevenLabs voice for the AI narrator: one mp3 + word timings per line, cached.

    /opt/miniconda3/bin/python3 tts.py <lines.txt> <outdir> [--voice River] [--model v4|v2] [--tempo 1.1]

lines.txt holds one spoken line per beat (blank lines skipped). Writes, per line N:
  outdir/vN.mp3          the audio
  outdir/vN_words.json   [{"w": "Hello", "s": 0.12, "e": 0.41}, ...]  (seconds, from the line's start)
and prints `vN <seconds>  <text>`, which the reel config uses for beat lengths. The word files
feed scripts/reels/captions.py.

Models: v4 = eleven_v4 (the default; picked by ear as more natural than v2).
v2 = eleven_multilingual_v2 (faster, flatter, has a speed setting).
v4 has no speed slider and reads River at ~149 wpm, slow for short-form (~160-190), so --tempo
(default 1.1) speeds the finished audio with ffmpeg atempo, which keeps pitch. ~164 wpm. Word
timings are divided by the same factor, so captions stay in sync.

The API key comes from the ELEVENLABS_API_KEY environment variable (or a .env file next to
this repo's root). Never commit it.
Cache: ~/.cache/aicourse-voice/<sha256>.json, so a re-run with identical text costs nothing.
"""
import argparse, base64, hashlib, json, pathlib, subprocess, sys, urllib.request

ENV = pathlib.Path(__file__).resolve().parents[2] / ".env"
CACHE = pathlib.Path.home() / ".cache/ai-ceo-voice"
VOICES = {"River": "SAz9YHcvj6GT2YYXdXww", "Daniel": "onwK4e9ZLuTAKqWW03F9", "Brian": "nPczCjzI2devNBz1zQrb"}
MODELS = {"v2": "eleven_multilingual_v2", "v4": "eleven_v4"}


def key() -> str:
    import os
    if os.environ.get("ELEVENLABS_API_KEY"):
        return os.environ["ELEVENLABS_API_KEY"]
    for line in (ENV.read_text().splitlines() if ENV.exists() else []):
        if line.startswith("ELEVENLABS_API_KEY"):
            return line.split("=", 1)[1].strip().strip("\"'")
    sys.exit("Set ELEVENLABS_API_KEY (environment or .env at the repo root)")


def words(alignment: dict) -> list:
    """Group character timings into words (a word = a run of non-space characters)."""
    out, cur, s = [], "", None
    chars, st, en = alignment["characters"], alignment["character_start_times_seconds"], alignment["character_end_times_seconds"]
    for i, c in enumerate(chars):
        if c.isspace():
            if cur:
                out.append({"w": cur, "s": round(s, 3), "e": round(en[i - 1], 3)})
            cur, s = "", None
            continue
        if not cur:
            s = st[i]
        cur += c
    if cur:
        out.append({"w": cur, "s": round(s, 3), "e": round(en[len(chars) - 1], 3)})
    return out


def duration(p: pathlib.Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                          "-of", "csv=p=0", str(p)], capture_output=True, text=True).stdout
    return float(out.strip())


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("lines"); ap.add_argument("outdir")
    ap.add_argument("--voice", default="River"); ap.add_argument("--model", default="v4", choices=MODELS)
    ap.add_argument("--speed", type=float, default=1.05, help="v2 only")
    ap.add_argument("--tempo", type=float, default=1.1, help="post-speed via atempo (pitch kept)")
    a = ap.parse_args()
    lines = [l.strip() for l in pathlib.Path(a.lines).read_text().splitlines() if l.strip()]
    out = pathlib.Path(a.outdir); out.mkdir(parents=True, exist_ok=True); CACHE.mkdir(parents=True, exist_ok=True)
    vid, model = VOICES.get(a.voice, a.voice), MODELS[a.model]
    settings = {"stability": 0.5, "similarity_boost": 0.75}
    if a.model == "v2":
        settings.update({"style": 0.15, "speed": a.speed})
    chars = 0
    for i, text in enumerate(lines, 1):
        h = hashlib.sha256(json.dumps([vid, model, settings, text]).encode()).hexdigest()
        cached = CACHE / f"{h}.json"
        if not cached.exists():
            req = urllib.request.Request(
                f"https://api.elevenlabs.io/v1/text-to-speech/{vid}/with-timestamps?output_format=mp3_44100_128",
                data=json.dumps({"text": text, "model_id": model, "voice_settings": settings}).encode(),
                headers={"xi-api-key": key(), "Content-Type": "application/json"})
            cached.write_text(urllib.request.urlopen(req, timeout=180).read().decode())
            chars += len(text)
        d = json.loads(cached.read_text())
        mp3 = out / f"v{i}.mp3"
        raw = out / f".raw_v{i}.mp3"
        raw.write_bytes(base64.b64decode(d["audio_base64"]))
        if abs(a.tempo - 1.0) > 1e-3:
            subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(raw), "-af", f"atempo={a.tempo}",
                            "-c:a", "libmp3lame", "-b:a", "192k", str(mp3)], check=True)
            raw.unlink()
        else:
            raw.rename(mp3)
        ws = [{"w": w["w"], "s": round(w["s"] / a.tempo, 3), "e": round(w["e"] / a.tempo, 3)} for w in words(d["alignment"])]
        (out / f"v{i}_words.json").write_text(json.dumps(ws))
        print(f"v{i} {duration(mp3):.2f}  {text}")
    print(f"CHARS_BILLED {chars}  MODEL {model}  TEMPO {a.tempo}")


if __name__ == "__main__":
    main()
