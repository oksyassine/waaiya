"""Waaiya's icon (the Android adaptive icon: Material "music off" glyph, Apache-2.0, white on #0D6B5E) rendered for
Windows: the Store package's tiles (desktop/windows/msix/Assets) and the app icon (runner/resources/app_icon.ico).

    uvx --with cairosvg --with pillow python desktop/tool/make_icons.py desktop/windows/msix/Assets
"""
import sys, cairosvg
P = "M4.27,3L3,4.27l9,9v0.28c-0.59,-0.34 -1.27,-0.55 -2,-0.55 -2.21,0 -4,1.79 -4,4s1.79,4 4,4 4,-1.79 4,-4v-1.73L19.73,21 21,19.73 4.27,3zM14,7h4V3h-6v5.18l2,2z"
def svg(w, h, glyph_frac, bg=True, radius_frac=0.0, color="#FFFFFF"):
    g = min(w, h) * glyph_frac          # glyph box (24 units)
    s = g / 24.0
    tx, ty = (w - g) / 2, (h - g) / 2
    rect = f'<rect width="{w}" height="{h}" rx="{min(w,h)*radius_frac}" fill="#0D6B5E"/>' if bg else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{rect}'
            f'<g transform="translate({tx},{ty}) scale({s})"><path fill="{color}" d="{P}"/></g></svg>')
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
