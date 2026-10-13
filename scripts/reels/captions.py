#!/usr/bin/env python3
"""Word-synced burned-in captions: one transparent caption video for a voiced reel.

    python3 captions.py <voice_dir> <starts.txt> <total_seconds> <out.mov> [--lead 0.12] [--skip 1,9]

Called by build_reel.sh when the config sets CAPTIONS=1. Reads vN_words.json (scripts/voice/tts.py)
and the builder's measured beat starts, groups words into short chunks (≤3 words, a new chunk
after any . , ? ! :), and renders one PNG per word-state in ONE browser: the chunk on a single line,
the word being spoken in green. A ProRes-4444 .mov with alpha comes out, overlaid by the builder.

Why: sound-off viewers depend entirely on captions, and ~69% say they watch muted in public
(see README). Placement: band centred at y≈1290, which keeps the bottom 460px keep-out clear.
Cards on a captioned reel must keep their own text above y≈1120 (knowledgebase/ReelCraft.md).
--skip lists beats whose words are already on the card, so they aren't shown twice.
"""
import argparse, json, pathlib, subprocess, tempfile
from playwright.sync_api import sync_playwright

W, H, FPS = 1080, 1920, 30
HTML = """<!doctype html><meta charset="utf-8"><style>
html,body{margin:0;width:1080px;height:1920px;background:transparent}
#c{position:absolute;left:74px;right:74px;top:1225px;height:130px;display:flex;align-items:center;justify-content:center;
 font:800 72px Inter,'Helvetica Neue',Arial,sans-serif;letter-spacing:-.02em;color:#f2f2f7;white-space:nowrap;
 -webkit-text-stroke:10px rgba(11,11,15,.92);paint-order:stroke fill;
 text-shadow:0 4px 18px rgba(11,11,15,.9)}
#c span{margin:0 .16em}
#c .on{color:#38d39f}
</style><div id="c"></div>"""


def chunks(words):
    cur = []
    for w in words:
        cur.append(w)
        if len(cur) == 3 or w["w"][-1] in ".,?!:":
            yield cur; cur = []
    if cur:
        yield cur


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("voice_dir"); ap.add_argument("starts"); ap.add_argument("total", type=float); ap.add_argument("out")
    ap.add_argument("--lead", type=float, default=0.12); ap.add_argument("--skip", default="")
    a = ap.parse_args()
    skip = {int(x) for x in a.skip.split(",") if x.strip()}
    starts = {int(n): float(t) for n, t in (l.split() for l in pathlib.Path(a.starts).read_text().split("\n") if l.strip())}

    # states: (t_start, t_end, chunk_words, active_index)
    states = []
    for n, t0 in sorted(starts.items()):
        f = pathlib.Path(a.voice_dir) / f"v{n}_words.json"
        if n in skip or not f.exists():
            continue
        ws = json.loads(f.read_text())
        for ch in chunks(ws):
            for i, w in enumerate(ch):
                s = t0 + a.lead + w["s"]
                e = t0 + a.lead + (ch[i + 1]["s"] if i + 1 < len(ch) else w["e"] + 0.18)
                states.append((s, e, [x["w"] for x in ch], i))
    # no overlaps, nothing past the end
    for k in range(len(states) - 1):
        s, e, c, i = states[k]
        states[k] = (s, min(e, states[k + 1][0]), c, i)
    states = [(s, min(e, a.total), c, i) for s, e, c, i in states if s < a.total]

    tmp = pathlib.Path(tempfile.mkdtemp(prefix="caps_"))
    with sync_playwright() as pw:
        b = pw.chromium.launch(args=["--force-device-scale-factor=1"])
        pg = b.new_page(viewport={"width": W, "height": H}, device_scale_factor=1)
        pg.set_content(HTML); pg.wait_for_timeout(200)
        pg.screenshot(path=str(tmp / "blank.png"), omit_background=True)
        for k, (s, e, c, i) in enumerate(states):
            pg.evaluate("([ws,i]) => document.getElementById('c').innerHTML = ws.map((w,j)=>`<span class=\"${j===i?'on':''}\">${w}</span>`).join('')", [c, i])
            pg.screenshot(path=str(tmp / f"s{k:04d}.png"), omit_background=True)
        b.close()

    # concat list with exact durations, frame-quantised so the stream never drifts against the voice
    lines, t = [], 0.0
    def add(img, dur):
        nonlocal t
        frames = round((t + dur) * FPS) - round(t * FPS)
        if frames > 0:
            lines.append(f"file '{img}'\nduration {frames / FPS:.6f}")
        t += dur
    for k, (s, e, c, i) in enumerate(states):
        if s > t:
            add(tmp / "blank.png", s - t)
        add(tmp / f"s{k:04d}.png", e - s)
    if a.total > t:
        add(tmp / "blank.png", a.total - t)
    lines.append(f"file '{tmp / 'blank.png'}'")
    (tmp / "list.txt").write_text("\n".join(lines) + "\n")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(tmp / "list.txt"),
                    "-vf", f"fps={FPS},format=yuva444p10le", "-t", f"{a.total:.3f}",
                    "-c:v", "prores_ks", "-profile:v", "4444", a.out], check=True)
    print(f"captions: {len(states)} word-states → {a.out}")


if __name__ == "__main__":
    main()
