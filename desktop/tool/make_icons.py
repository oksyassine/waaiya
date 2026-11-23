"""Waaiya's icon (the ع of واعية drawn as an ear, white on #0D6B5E; source /srv/build/waaiya-logo, ain-ear) rendered for
Windows: the Store package's tiles (desktop/windows/msix/Assets) and the app icon (runner/resources/app_icon.ico, also
the icon next to the clock).

Small sizes keep the ear (the inner arc): a mark under about 40 px is drawn larger in its square with thinner strokes,
so that the gap between the arc and the letter stays at least a pixel wide (with the full strokes it closed up at
16-32 px and only the letter was seen). Every size of the .ico is drawn at its own size, not scaled down from 256.

    uvx --with resvg-py --with pillow python desktop/tool/make_icons.py desktop/windows/msix/Assets
    uvx --with resvg-py --with pillow python desktop/tool/make_icons.py --site   (the website's tab icons, favicon.svg)
    (or --with cairosvg, where the cairo library is installed)
"""
import io
import os
import sys

LETTER = "M80.2 22.15 A14.5 14.5 0 1 0 74.67 44.33 A31 31 0 1 0 89.43 86.01"
INNER = "M66.01 60.2 A13 13 0 1 0 66.01 84.64"


def render(svg_text):
    try:
        import resvg_py
        return bytes(resvg_py.svg_to_bytes(svg_string=svg_text))
    except ImportError:
        import cairosvg
        return cairosvg.svg2png(bytestring=svg_text.encode())


def small_form(px):
    """(glyph size factor, letter stroke, arc stroke) for a mark [px] high; None: the full form."""
    if px <= 22:
        return 1.57, 9.5, 8.5  # 16-20 px icons: the mark fills its plate
    if px < 40:
        return 1.5, 10, 9
    return None


def svg(w, h, glyph_frac, bg=True, radius_frac=0.0, color="#FFFFFF"):
    g = min(w, h) * glyph_frac          # mark box (120 units)
    st = f'fill="none" stroke="{color}" stroke-linecap="round" stroke-linejoin="round"'
    small = small_form(g)
    letter, inner = 12, 8
    if small:
        k, letter, inner = small
        g = min(min(w, h) * 1.1, g * k)
    s = g / 120.0
    tx, ty = (w - g) / 2, (h - g) / 2
    rect = f'<rect width="{w}" height="{h}" rx="{min(w,h)*radius_frac}" fill="#0D6B5E"/>' if bg else ""
    body = f'<path {st} stroke-width="{letter}" d="{LETTER}"/><path {st} stroke-width="{inner}" d="{INNER}"/>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{rect}'
            f'<g transform="translate({tx},{ty}) scale({s})">{body}</g></svg>')


def png(path, w, h, **k):
    with open(path, "wb") as f:
        f.write(render(svg(w, h, **k)))


ICO_SIZES = (16, 20, 24, 32, 40, 48, 64, 256)


def ico_frames():
    from PIL import Image
    return [Image.open(io.BytesIO(render(svg(t, t, glyph_frac=.72, radius_frac=.22)))).convert("RGBA")
            for t in ICO_SIZES]


def site_icons(root):
    """The website's tab icons (site/build.py icons()) and docs/brand/favicon.svg, in the small form that keeps the ear."""
    for t in (16, 32, 48):
        png(os.path.join(root, "site", "assets", f"favicon-{t}.png"), t, t, glyph_frac=.72, radius_frac=.22)
    fav = svg(120, 120, glyph_frac=.72, radius_frac=.2).replace("<svg ", '<svg role="img" ', 1)
    fav = fav.replace(' width="120" height="120"', "", 1).replace(">", "><title>واعية</title>", 1)
    with open(os.path.join(root, "docs", "brand", "favicon.svg"), "w", encoding="utf-8") as f:
        f.write(fav + "\n")


if __name__ == "__main__":
    if sys.argv[1] == "--site":
        site_icons(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
        sys.exit()
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
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
    # the app icon (rounded plate), each size drawn at its size, and a 300 px logo for the Store listing
    frames = ico_frames()
    ico = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "windows", "runner", "resources", "app_icon.ico")
    frames[-1].save(ico, sizes=[f.size for f in frames], append_images=frames[:-1])
    png(os.path.join(out, "..", "store_logo_300.png"), 300, 300, glyph_frac=.55)
