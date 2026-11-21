"""Waaiya's icon (the ع of واعية drawn as an ear, white on #0D6B5E; source /srv/build/waaiya-logo, ain-ear) rendered for
Windows: the Store package's tiles (desktop/windows/msix/Assets) and the app icon (runner/resources/app_icon.ico).
Below 40 px the small form is used (no inner arc, heavier stroke) so the letter stays clear.

    uvx --with cairosvg --with pillow python desktop/tool/make_icons.py desktop/windows/msix/Assets
"""
import sys, cairosvg
LETTER = "M80.2 22.15 A14.5 14.5 0 1 0 74.67 44.33 A31 31 0 1 0 89.43 86.01"
INNER = "M66.01 60.2 A13 13 0 1 0 66.01 84.64"
MINI = "M79.68 23.3 A15 15 0 1 0 73.96 46.23 A29.5 29.5 0 1 0 88.01 85.9"
def svg(w, h, glyph_frac, bg=True, radius_frac=0.0, color="#FFFFFF"):
    g = min(w, h) * glyph_frac          # mark box (120 units)
    s = g / 120.0
    tx, ty = (w - g) / 2, (h - g) / 2
    rect = f'<rect width="{w}" height="{h}" rx="{min(w,h)*radius_frac}" fill="#0D6B5E"/>' if bg else ""
    st = f'fill="none" stroke="{color}" stroke-linecap="round" stroke-linejoin="round"'
    if g < 40:
        body = f'<path {st} stroke-width="16" d="{MINI}"/>'
    else:
        body = f'<path {st} stroke-width="12" d="{LETTER}"/><path {st} stroke-width="8" d="{INNER}"/>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{rect}'
            f'<g transform="translate({tx},{ty}) scale({s})">{body}</g></svg>')
def png(path, w, h, **k):
    cairosvg.svg2png(bytestring=svg(w, h, **k).encode(), write_to=path)
if __name__ == "__main__":
    out = sys.argv[1]
    import os; os.makedirs(out, exist_ok=True)
    # MSIX tiles: plate colour fills the tile; glyph about 60 % (Windows guidance: 66 % safe area)
    for name, w, h, frac in [("Square150x150Logo", 150, 150, .5), ("Square44x44Logo", 44, 44, .7),
                             ("StoreLogo", 50, 50, .62), ("Wide310x150Logo", 310, 150, .5)]:
        for scale in (100, 200):
            png(f"{out}/{name}.scale-{scale}.png", w * scale // 100, h * scale // 100, glyph_frac=frac)
    # taskbar and Start list sizes; "unplated" ones (no tile behind them) keep a rounded plate: a white glyph alone
    # would vanish on the light theme
    for t in (16, 24, 32, 48, 256):
        png(f"{out}/Square44x44Logo.targetsize-{t}.png", t, t, glyph_frac=.7)
        png(f"{out}/Square44x44Logo.targetsize-{t}_altform-unplated.png", t, t, glyph_frac=.86, radius_frac=.2)
    # the app icon (rounded plate), and a 300 px logo for the Store listing
    import io, os.path
    from PIL import Image
    big = io.BytesIO(cairosvg.svg2png(bytestring=svg(256, 256, glyph_frac=.72, radius_frac=.22).encode()))
    ico = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "windows", "runner", "resources", "app_icon.ico")
    Image.open(big).convert("RGBA").save(ico, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (256, 256)])
    png(os.path.join(out, "..", "store_logo_300.png"), 300, 300, glyph_frac=.55)
