#!/usr/bin/env python3
"""Render every .card in a cards HTML to transparent 1080x1920 PNGs — ONE browser.

Why this exists: the old shell loop launched `Google Chrome --headless --screenshot`
once PER CARD. Cold start dominates that (~40s per launch, measured), so 7 cards cost
~4.7 MINUTES of a ~6-minute build for what is static text on a transparent background.

Playwright keeps ONE browser open and screenshots each card in the same page, which
turns the whole step into a couple of seconds.

    python3 render_cards.py rules5_cards.html work/cards

Guarantees kept from the shell version (each one caught a real bug):
  - native 1080x1920 (a 2x render composites as its top-left quadrant)
  - omit_background so the PNG is genuinely RGBA (an opaque "empty" overlay paints
    the footage black — that shipped once)
  - fail on an unbalanced HTML comment (an inner --> ends the outer one and the rest
    of the file paints as visible text)

Steps (optional, for text that appears one piece at a time inside a card): mark elements
with data-step="1".."N". Besides the full cN.png, such a card also renders
  cN_s1.png  the card with only step-1 elements shown (shade, brand and all unmarked content
             included) — the base layer
  cN_sK.png  for K >= 2: ONLY the step-K elements, on transparency — a delta layer
Hidden steps keep their layout (visibility, not display), so every layer lines up with the
full card. A delta carries no shade, so stacking layers never darkens the footage twice.
The builder overlays the base, then fades each delta in at its time. Cards without data-step
render exactly as before.
"""
import re
import sys
import pathlib
from playwright.sync_api import sync_playwright

W, H = 1080, 1920


def main(src: str, outdir: str) -> None:
    html = pathlib.Path(src).read_text()

    stripped = re.sub(r"<!--.*?-->", "", html, flags=re.S)
    if "<!--" in stripped or "-->" in stripped:
        sys.exit("FAIL: unbalanced HTML comment — it would paint as visible text")

    ids = re.findall(r'class="card"\s+id="(c\d+)"', html)
    if not ids:
        sys.exit("FAIL: no .card elements found")

    out = pathlib.Path(outdir)
    out.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as pw:
        browser = pw.chromium.launch(args=["--force-device-scale-factor=1"])
        page = browser.new_page(viewport={"width": W, "height": H},
                                device_scale_factor=1)
        page.goto(pathlib.Path(src).resolve().as_uri())
        page.wait_for_timeout(250)          # let webfonts settle once, not per card

        for cid in ids:
            page.eval_on_selector_all(".card", "els => els.forEach(e => e.classList.remove('on'))")
            page.eval_on_selector(f"#{cid}", "el => el.classList.add('on')")
            path = out / f"{cid}.png"
            page.screenshot(path=str(path), omit_background=True)
            print(f"  {cid} -> {path}")

            # step layers: clear this card's old ones first, so a card that lost its steps
            # never leaves a stale layer for the builder to pick up
            for old in out.glob(f"{cid}_s*.png"):
                old.unlink()
            steps = page.eval_on_selector(
                f"#{cid}", "el => [...el.querySelectorAll('[data-step]')].map(e => +e.dataset.step)")
            for k in range(1, max(steps, default=0) + 1):
                page.eval_on_selector(f"#{cid}", """(el, k) => {
                    el.style.visibility = k === 1 ? '' : 'hidden';
                    for (const e of el.querySelectorAll('[data-step]')) {
                      const s = +e.dataset.step;
                      e.style.visibility = (k === 1 ? s <= 1 : s === k) ? 'visible' : 'hidden';
                    }
                  }""", k)
                spath = out / f"{cid}_s{k}.png"
                page.screenshot(path=str(spath), omit_background=True)
                print(f"  {cid} step {k} -> {spath}")
            page.eval_on_selector(f"#{cid}", """el => {
                el.style.visibility = '';
                for (const e of el.querySelectorAll('[data-step]')) e.style.visibility = '';
              }""")

        browser.close()


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
