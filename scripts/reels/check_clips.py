#!/usr/bin/env python3
"""Vet candidate B-roll BEFORE building. Prints a per-clip verdict + a contact sheet.

Why: two full rebuilds were once lost to things visible in a single frame: a clip with a
FACE in it (the account never shows faces) and a plate too bright under the type band. Both are 5-second checks here and 90-second rebuilds later.

    python3 check_clips.py raw/*.mp4
    open /tmp/clipcheck.png        # then LOOK at it — the face check is your eyes

Reports per clip:
  - overall luma            (very dark <0.12 = type is safe but footage may vanish)
  - luma under the TYPE BAND(>0.45 = white text will fight it; needs a local block)
  - a face-detection hint   (OpenCV if available; otherwise says so — never silently passes)
"""
import subprocess
import sys
import pathlib

BAND = (0, 850, 1080, 360)   # x, y, w, h — where load-bearing copy renders


def sh(*a):
    return subprocess.run(a, capture_output=True, text=True).stdout.strip()


def main(paths):
    if not paths:
        sys.exit(__doc__)

    try:
        import cv2
        cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
        have_cv = True
    except Exception:
        have_cv = False

    frames = []
    print(f"{'clip':>14}  {'luma':>6} {'band':>6}  faces  verdict")
    for p in paths:
        p = pathlib.Path(p)
        f = f"/tmp/cc_{p.stem}.png"
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-ss", "2", "-i", str(p),
                        "-frames:v", "1", f], check=True)
        frames.append(f)

        luma = float(sh("magick", f, "-colorspace", "Gray", "-format", "%[fx:mean]", "info:"))
        band = float(sh("magick", f, "-crop", f"{BAND[2]}x{BAND[3]}+{BAND[0]}+{BAND[1]}",
                        "+repage", "-colorspace", "Gray", "-format", "%[fx:mean]", "info:"))

        faces = "?"
        if have_cv:
            img = cv2.imread(f)
            g = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            n = len(cascade.detectMultiScale(g, 1.1, 5, minSize=(60, 60)))
            faces = str(n)

        flags = []
        if faces not in ("0", "?"):
            flags.append("FACE — REJECT (hard rule)")
        if band > 0.45:
            flags.append("bright under type — needs a local block")
        if luma < 0.10:
            flags.append("very dark — footage may read as black")
        print(f"{p.stem:>14}  {luma:6.3f} {band:6.3f}  {faces:>5}  "
              + ("; ".join(flags) if flags else "ok"))

    if not have_cv:
        print("\n⚠️  OpenCV not installed — the face column is NOT checked. "
              "LOOK at the contact sheet yourself.")

    if frames:
        small = []
        for f in frames:
            s = f.replace("cc_", "ccs_")
            subprocess.run(["magick", f, "-resize", "200x", s], check=True)
            small.append(s)
        subprocess.run(["magick"] + small + ["+append", "/tmp/clipcheck.png"], check=True)
        print("\ncontact sheet -> /tmp/clipcheck.png   ← LOOK AT IT (faces, handles, framing)")


if __name__ == "__main__":
    main(sys.argv[1:])
